using System;
using Toolbelt.String.Unicode;

namespace Toolbelt.String.EditDistance
{
    internal static class JaroKernel
    {
        public sealed class Answer
        {
            public double? Similarity;
            public int Error;
            public long PlannedWork, VisitedWork;
            public int Matches, Mismatches, Prefix;
        }

        // Prognose aller Fensterplätze unabhängig von Inhalt/Frühmatch.
        public static long PlannedWindowWork(int n,int m)
        {
            if(n>m) {int swap=n;n=m;m=swap;}
            int d=Math.Max(0,m/2-1); long work=0;
            for(int i=0;i<n;i++)
                work=checked(work+Math.Max(0,Math.Min(m-1,i+d)-Math.Max(0,i-d)+1));
            return work;
        }

        public static Answer Evaluate(string left,string right,string profile)
        {
            Answer result=new Answer();
            if(left==null || right==null) return result;
            if(profile!="standard" && profile!="large") {result.Error=1;return result;}
            bool large=profile=="large";
            if(left.Length>(large?65536:2048) || right.Length>(large?65536:2048))
            {result.Error=3;return result;}
            int n,m;
            try {n=UnicodeScalar.CountStrict(left);m=UnicodeScalar.CountStrict(right);}
            catch(ArgumentException) {result.Error=4;return result;}
            if(n>(large?32768:1024) || m>(large?32768:1024)) {result.Error=5;return result;}
            result.PlannedWork=PlannedWindowWork(n,m);
            if(result.PlannedWork>(large?16777216L:1048576L)) {result.Error=6;return result;}
            if(n==0 || m==0) {result.Similarity=n==m?1.0:0.0;return result;}
            int[] a=UnicodeScalar.DecodeValidated(left,n),b=UnicodeScalar.DecodeValidated(right,m);
            // Kanonische Orientierung: Länge, dann numerische Scalarlexikographie.
            bool exchange=n>m;
            if(n==m)
            {
                for(int i=0;i<n;i++)
                    if(a[i]!=b[i]) {exchange=a[i]>b[i];break;}
            }
            if(exchange) {int[] swap=a;a=b;b=swap;int length=n;n=m;m=length;}
            int d=Math.Max(0,m/2-1);
            int[] matchIndex=new int[n]; bool[] used=new bool[m];
            for(int i=0;i<n;i++) matchIndex[i]=-1;
            int c=0;
            for(int i=0;i<n;i++)
            {
                for(int j=Math.Max(0,i-d),hi=Math.Min(m-1,i+d);j<=hi;j++)
                {
                    result.VisitedWork++;
                    if(!used[j] && a[i]==b[j]) {matchIndex[i]=j;used[j]=true;c++;break;}
                }
            }
            if(result.VisitedWork>result.PlannedWork) throw new InvalidOperationException("TBX_JARO_WORK");
            result.Matches=c;
            if(c==0) {result.Similarity=0.0;return result;}
            int h=0,k=0;
            for(int i=0;i<n;i++)
            {
                if(matchIndex[i]<0) continue;
                while(!used[k]) k++;
                if(a[i]!=b[k]) h++;
                k++;
            }
            int prefix=0;
            while(prefix<Math.Min(4,n) && a[prefix]==b[prefix]) prefix++;
            result.Mismatches=h; result.Prefix=prefix;
            double jaro=((double)c/n+(double)c/m+(c-h/2.0)/c)/3.0;
            // Unter den Profilcaps sind numerator*10 und denominator*7 Int64-sicher.
            // Rationaler Test verhindert einen Floatbonus bei exakt 7/10.
            long numerator=checked(2L*c*c*(n+m)+(2L*c-h)*n*m);
            long denominator=checked(6L*c*n*m);
            result.Similarity=checked(10L*numerator)>checked(7L*denominator)
                ?jaro+(prefix/10.0)*(1.0-jaro):jaro;
            return result;
        }
    }
}

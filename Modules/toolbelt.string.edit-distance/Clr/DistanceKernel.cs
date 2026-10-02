using System;



// Gemeinsamer begrenzter Scalar-/DP-Kern ohne SQL-, Datei- oder Netzwerkzugriff.
internal static class DistanceKernel
{
    public sealed class Answer
    {
        public int? Distance; public bool? Exceeds; public int Error;
        public long Cells, PredictedCells, IntBufferBytes, InitializationWrites, BoundaryWrites;
    }


    private static int ScalarCount(string text)
    {
        int count = 0;
        for (int i=0; i<text.Length; i++,count++)
        {
            char ch=text[i];
            if (Char.IsHighSurrogate(ch))
            {
                if (i+1==text.Length || !Char.IsLowSurrogate(text[i+1])) throw new ArgumentException("UTF16");
                i++;
            }
            else if (Char.IsLowSurrogate(ch)) throw new ArgumentException("UTF16");
        }
        return count;
    }
    private static int[] Decode(string text,int count)
    {
        int[] values=new int[count]; int j=0;
        for(int i=0;i<text.Length;i++)
        {
            values[j++]=Char.ConvertToUtf32(text,i);
            if(Char.IsHighSurrogate(text[i])) i++;
        }
        return values;
    }
    public static long PlannedCells(int n,int m,int? threshold)
    {
        if(!threshold.HasValue) return checked((long)n*m);
        int k=Math.Min(threshold.Value,Math.Max(n,m));long total=0;
        for(int i=1;i<=n;i++) total=checked(total+Math.Max(0,Math.Min(m,i+k)-Math.Max(1,i-k)+1));
        return total;
    }
    public static Answer Evaluate(string left,string right,int? threshold,string profile,bool osa)
    {
        Answer result=new Answer();
        if(left==null || right==null) return result;
        if(profile!="standard" && profile!="large") {result.Error=1;return result;}
        if(threshold.HasValue && threshold.Value<0) {result.Error=2;return result;}
        bool large=profile=="large";int units=large?65536:2048,limit=large?32768:1024;
        long work=large?16777216L:1048576L;
        if(left.Length>units || right.Length>units) {result.Error=3;return result;}
        int n,m;
        try {n=ScalarCount(left);m=ScalarCount(right);} catch(ArgumentException) {result.Error=4;return result;}
        if(n>limit || m>limit) {result.Error=5;return result;}
        if(threshold.HasValue && Math.Abs(n-m)>threshold.Value) {result.Exceeds=true;return result;}
        result.PredictedCells=PlannedCells(n,m,threshold);
        if(result.PredictedCells>work) {result.Error=6;return result;}
        if(n==0 || m==0) {result.Distance=Math.Max(n,m);result.Exceeds=false;return result;}
        int[] a=Decode(left,n),b=Decode(right,m);
        int k=threshold.HasValue?Math.Min(threshold.Value,Math.Max(n,m)):Math.Max(n,m);
        int inf=Math.Max(n,m)+1;
        int[] previous=new int[m+1],current=new int[m+1],older=osa?new int[m+1]:null;
        result.IntBufferBytes=checked(4L*(n+m+(osa?3L:2L)*(m+1)));
        // Einmalige Initialisierung statt vollstaendiges Array.Clear pro Bandzeile.
        for(int j=0;j<=m;j++)
        {
            previous[j]=j<=k?j:inf;
            current[j]=inf;
            if(osa) older[j]=inf;
            result.InitializationWrites+=osa?3:2;
        }
        for(int i=1;i<=n;i++)
        {
            int lo=Math.Max(1,i-k),hi=Math.Min(m,i+k);
            current[0]=i<=k?i:inf;result.BoundaryWrites++;
            if(lo>1) {current[lo-1]=inf;result.BoundaryWrites++;}
            if(hi<m) {current[hi+1]=inf;result.BoundaryWrites++;}
            for(int j=lo;j<=hi;j++)
            {
                int value=Math.Min(previous[j]+1,Math.Min(current[j-1]+1,previous[j-1]+(a[i-1]==b[j-1]?0:1)));
                if(osa && i>1 && j>1 && a[i-1]==b[j-2] && a[i-2]==b[j-1]) value=Math.Min(value,older[j-2]+1);
                current[j]=Math.Min(inf,value);result.Cells++;
            }
            int[] recycle=osa?older:previous;
            if(osa) older=previous;
            previous=current;current=recycle;
        }
        if (result.Cells != result.PredictedCells) throw new InvalidOperationException("TBX_DISTANCE_WORK_MISMATCH");
        if(threshold.HasValue && previous[m]>threshold.Value) result.Exceeds=true;
        else {result.Distance=previous[m];result.Exceeds=false;}
        return result;
    }
}

using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.String.EditDistance
{
    public static class JaroProvider
    {
        [SqlFunction(IsDeterministic=true,IsPrecise=false,DataAccess=DataAccessKind.None,
            SystemDataAccess=SystemDataAccessKind.None,FillRowMethodName="FillRow",
            TableDefinition="Similarity float, ErrorCode int")]
        public static IEnumerable Evaluate(SqlChars left,SqlChars right,SqlChars profile)
        {
            JaroKernel.Answer answer=new JaroKernel.Answer();
            if(left.IsNull || right.IsNull) return new[] {answer};
            string selected=null;
            if(!profile.IsNull && (profile.Length==8 || profile.Length==5)) selected=Copy(profile);
            if(selected!="standard" && selected!="large") {answer.Error=1;return new[] {answer};}
            int units=selected=="large"?65536:2048;
            if(left.Length>units || right.Length>units) {answer.Error=3;return new[] {answer};}
            return new[] {JaroKernel.Evaluate(Copy(left),Copy(right),selected)};
        }

        private static string Copy(SqlChars value)
        {
            int length=checked((int)value.Length);char[] data=new char[length];long position=0;
            while(position<length)
            {
                long read=value.Read(position,data,checked((int)position),length-checked((int)position));
                if(read<=0 || read>length-position) throw new InvalidOperationException("TBX_JARO_TRANSPORT");
                position=checked(position+read);
            }
            return new string(data);
        }

        public static void FillRow(object row,out SqlDouble similarity,out SqlInt32 errorCode)
        {
            JaroKernel.Answer answer=row as JaroKernel.Answer;
            if(answer==null) throw new InvalidOperationException("TBX_JARO_TRANSPORT");
            similarity=answer.Similarity.HasValue?new SqlDouble(answer.Similarity.Value):SqlDouble.Null;
            errorCode=new SqlInt32(answer.Error);
        }
    }
}

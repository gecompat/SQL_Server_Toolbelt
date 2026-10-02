using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.String.EditDistance
{
    // SqlChars-Längenprüfung vor eigenen Textkopien; nur der freigegebene Kern rechnet.
    public static class DistanceProvider
    {
        [SqlFunction(IsDeterministic=true, IsPrecise=true, DataAccess=DataAccessKind.None,
            SystemDataAccess=SystemDataAccessKind.None, FillRowMethodName="FillRow",
            TableDefinition="Distance int, ExceedsMaxDistance bit, ErrorCode int")]
        public static IEnumerable Levenshtein(SqlChars left, SqlChars right, SqlInt32 threshold, SqlChars profile)
        { return Invoke(left, right, threshold, profile, false); }

        [SqlFunction(IsDeterministic=true, IsPrecise=true, DataAccess=DataAccessKind.None,
            SystemDataAccess=SystemDataAccessKind.None, FillRowMethodName="FillRow",
            TableDefinition="Distance int, ExceedsMaxDistance bit, ErrorCode int")]
        public static IEnumerable Osa(SqlChars left, SqlChars right, SqlInt32 threshold, SqlChars profile)
        { return Invoke(left, right, threshold, profile, true); }

        private static IEnumerable Invoke(SqlChars left, SqlChars right, SqlInt32 threshold, SqlChars profile, bool osa)
        {
            DistanceKernel.Answer answer = new DistanceKernel.Answer();
            if (left.IsNull || right.IsNull) return new[] { answer };
            string selected = null;
            if (!profile.IsNull && (profile.Length == 8 || profile.Length == 5)) selected = Copy(profile);
            if (selected != "standard" && selected != "large") { answer.Error=1; return new[] { answer }; }
            if (!threshold.IsNull && threshold.Value < 0) { answer.Error=2; return new[] { answer }; }
            int units=selected=="large" ? 65536 : 2048;
            if (left.Length > units || right.Length > units) { answer.Error=3; return new[] { answer }; }
            answer=DistanceKernel.Evaluate(Copy(left), Copy(right), threshold.IsNull ? (int?)null : threshold.Value, selected, osa);
            return new[] { answer };
        }

        private static string Copy(SqlChars value)
        {
            int length=checked((int)value.Length);
            char[] data=new char[length];
            long position=0;
            while(position<length)
            {
                long read=value.Read(position, data, checked((int)position), length-checked((int)position));
                if(read<=0) throw new InvalidOperationException("TBX_DISTANCE_TRANSPORT");
                position=checked(position+read);
            }
            return new string(data);
        }

        public static void FillRow(object row, out SqlInt32 distance, out SqlBoolean exceeds, out SqlInt32 errorCode)
        {
            DistanceKernel.Answer answer=row as DistanceKernel.Answer;
            if(answer==null) throw new InvalidOperationException("TBX_DISTANCE_TRANSPORT");
            distance=answer.Distance.HasValue ? new SqlInt32(answer.Distance.Value) : SqlInt32.Null;
            exceeds=answer.Exceeds.HasValue ? new SqlBoolean(answer.Exceeds.Value) : SqlBoolean.Null;
            errorCode=new SqlInt32(answer.Error);
        }
    }
}

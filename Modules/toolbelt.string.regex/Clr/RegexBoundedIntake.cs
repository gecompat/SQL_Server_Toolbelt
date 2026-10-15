using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.String.Regex
{
    public static partial class RegexProvider
    {
        // SQL bindet ausschließlich diese SqlChars-Einstiege. Length wird vor
        // Read/Value geprüft; managed Kompatibilitätsaufrufe teilen die Fachkerne.
        private static SqlString Intake(SqlChars value, int limit, string code, TransformationContext context = null)
        {
            if (value == null || value.IsNull) return SqlString.Null;
            if (value.Length > limit) throw Error(code, "Die vorhandene UTF-16-Grenze wurde überschritten.");
            char[] copy = new char[(int)value.Length];
            int offset = 0;
            while (offset < copy.Length)
            {
                if (context != null) context.Remaining();
                long read = value.Read(offset, copy, offset, Math.Min(4096, copy.Length-offset));
                if (read <= 0) throw Error("TBX_REGEX_INVALID_ARGUMENT", "Der begrenzte Intake ist unvollständig.");
                offset += (int)read;
            }
            if (context != null) context.Remaining();
            return new SqlString(new string(copy));
        }
        private static TransformationContext IntakeContext(SqlChars profile, SqlChars flags, out SqlString selected, out SqlString options)
        {
            selected=Intake(profile,8,"TBX_REGEX_INVALID_ARGUMENT");
            var context=new TransformationContext(selected);
            options=Intake(flags,4,"TBX_REGEX_INVALID_FLAGS",context);
            context.ValidateFlags(options);
            return context;
        }
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,IsDeterministic=false,IsPrecise=true)]
        public static SqlBoolean RegexIsMatchBounded(SqlChars input,SqlChars pattern,SqlChars flags)
        {
            if(input.IsNull||pattern.IsNull)return SqlBoolean.Null;
            return RegexIsMatch(Intake(input,MaxInputCodeUnits,"TBX_REGEX_INPUT_TOO_LARGE"),Intake(pattern,MaxPatternBytes/2,"TBX_REGEX_PATTERN_TOO_LARGE"),Intake(flags,4,"TBX_REGEX_INVALID_FLAGS"));
        }
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,IsDeterministic=false,IsPrecise=true)]
        public static SqlInt32 RegexCountBounded(SqlChars input,SqlChars pattern,SqlInt32 start,SqlChars flags)
        {
            if(input.IsNull||pattern.IsNull)return SqlInt32.Null;
            if(start.IsNull||start.Value<1)throw Error("TBX_REGEX_INVALID_ARGUMENT","Start muss mindestens 1 sein.");
            SqlString value=Intake(input,MaxInputCodeUnits,"TBX_REGEX_INPUT_TOO_LARGE");
            if(start.Value>value.Value.Length+1)return new SqlInt32(0);
            return RegexCount(value,Intake(pattern,MaxPatternBytes/2,"TBX_REGEX_PATTERN_TOO_LARGE"),start,Intake(flags,4,"TBX_REGEX_INVALID_FLAGS"));
        }
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,IsDeterministic=false,IsPrecise=true)]
        public static SqlInt32 RegexInstrBounded(SqlChars input,SqlChars pattern,SqlInt32 start,SqlInt32 occurrence,SqlInt32 returnOption,SqlChars flags)
        {
            if(input.IsNull||pattern.IsNull)return SqlInt32.Null;
            if(start.IsNull||start.Value<1||occurrence.IsNull||occurrence.Value<1||returnOption.IsNull||(returnOption.Value!=0&&returnOption.Value!=1))throw Error("TBX_REGEX_INVALID_ARGUMENT","Start, Occurrence oder ReturnOption ist ungültig.");
            SqlString value=Intake(input,MaxInputCodeUnits,"TBX_REGEX_INPUT_TOO_LARGE");
            if(start.Value>value.Value.Length+1)return new SqlInt32(0);
            return RegexInstr(value,Intake(pattern,MaxPatternBytes/2,"TBX_REGEX_PATTERN_TOO_LARGE"),start,occurrence,returnOption,Intake(flags,4,"TBX_REGEX_INVALID_FLAGS"));
        }
        private static SqlString TransformBounded(SqlChars input,SqlChars pattern,SqlChars replacement,SqlInt32 start,SqlInt32 occurrence,SqlChars flags,SqlChars profile,int mode)
        {
            if(input.IsNull||pattern.IsNull||(mode!=0&&replacement.IsNull))return SqlString.Null;
            SqlString selected=Intake(profile,8,"TBX_REGEX_INVALID_ARGUMENT");
            var context=new TransformationContext(selected);
            ValidateTransformationArguments(start,occurrence,mode!=0);
            SqlString options=Intake(flags,4,"TBX_REGEX_INVALID_FLAGS",context);context.ValidateFlags(options);
            SqlString value=Intake(input,context.Limit,"TBX_REGEX_INPUT_TOO_LARGE",context);
            SqlString literal=mode==0?SqlString.Null:Intake(replacement,context.Limit,"TBX_REGEX_REPLACEMENT_TOO_LARGE",context);
            SqlString expression=Intake(pattern,R2PatternCodeUnits,"TBX_REGEX_PATTERN_TOO_LARGE",context);
            if(mode==0)return RegexSubstringInternal(value,expression,start,occurrence,options,selected,context);
            if(mode==1)return RegexReplaceInternal(value,expression,literal,start,occurrence,options,selected,context);
            return RegexReplaceGroupsInternal(value,expression,literal,start,occurrence,options,selected,context);
        }
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,IsDeterministic=false,IsPrecise=true)]
        public static SqlString RegexSubstringBounded(SqlChars input,SqlChars pattern,SqlInt32 start,SqlInt32 occurrence,SqlChars flags,SqlChars profile){return TransformBounded(input,pattern,SqlChars.Null,start,occurrence,flags,profile,0);}
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,IsDeterministic=false,IsPrecise=true)]
        public static SqlString RegexReplaceBounded(SqlChars input,SqlChars pattern,SqlChars replacement,SqlInt32 start,SqlInt32 occurrence,SqlChars flags,SqlChars profile){return TransformBounded(input,pattern,replacement,start,occurrence,flags,profile,1);}
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,IsDeterministic=false,IsPrecise=true)]
        public static SqlString RegexReplaceGroupsBounded(SqlChars input,SqlChars pattern,SqlChars replacement,SqlInt32 start,SqlInt32 occurrence,SqlChars flags,SqlChars profile){return TransformBounded(input,pattern,replacement,start,occurrence,flags,profile,2);}
        private static IEnumerable RelationsBounded(SqlChars input,SqlChars pattern,SqlInt32 start,SqlChars flags,SqlChars profile,SqlInt32 maxRows,int mode)
        {
            if(input.IsNull||pattern.IsNull)return new object[0];
            SqlString selected=Intake(profile,8,"TBX_REGEX_INVALID_ARGUMENT");var context=new TransformationContext(selected);
            if(start.IsNull||start.Value<1||maxRows.IsNull||maxRows.Value<1||maxRows.Value>100000)throw Error("TBX_REGEX_INVALID_ARGUMENT","Start oder MaxRows ist ungültig.");
            SqlString options=Intake(flags,4,"TBX_REGEX_INVALID_FLAGS",context);context.ValidateFlags(options);
            SqlString value=Intake(input,context.Limit,"TBX_REGEX_INPUT_TOO_LARGE",context);
            SqlString expression=Intake(pattern,R2PatternCodeUnits,"TBX_REGEX_PATTERN_TOO_LARGE",context);
            if(mode==2)return RegexCapturesInternal(value,expression,start,options,selected,maxRows,context);
            return BuildRelation(value,expression,start,options,selected,maxRows,mode==1,context);
        }
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,FillRowMethodName="FillRelationRow",TableDefinition="Ordinal bigint, StartPosition bigint, Length bigint, Value nvarchar(max)",IsDeterministic=false,IsPrecise=true)]
        public static IEnumerable RegexMatchesBounded(SqlChars input,SqlChars pattern,SqlInt32 start,SqlChars flags,SqlChars profile,SqlInt32 maxRows){return RelationsBounded(input,pattern,start,flags,profile,maxRows,0);}
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,FillRowMethodName="FillRelationRow",TableDefinition="Ordinal bigint, StartPosition bigint, Length bigint, Value nvarchar(max)",IsDeterministic=false,IsPrecise=true)]
        public static IEnumerable RegexSplitBounded(SqlChars input,SqlChars pattern,SqlChars flags,SqlChars profile,SqlInt32 maxRows){return RelationsBounded(input,pattern,1,flags,profile,maxRows,1);}
        [SqlFunction(DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,FillRowMethodName="FillCaptureRow",TableDefinition="MatchOrdinal bigint, GroupOrdinal int, CaptureOrdinal bigint, GroupName nvarchar(128), Matched bit, StartPosition bigint, Length bigint, Value nvarchar(max)",IsDeterministic=false,IsPrecise=true)]
        public static IEnumerable RegexCapturesBounded(SqlChars input,SqlChars pattern,SqlInt32 start,SqlChars flags,SqlChars profile,SqlInt32 maxRows){return RelationsBounded(input,pattern,start,flags,profile,maxRows,2);}
    }
}

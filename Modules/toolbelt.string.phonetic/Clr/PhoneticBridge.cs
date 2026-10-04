using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.String.Phonetic
{
    public static class PhoneticBridge
    {
        private sealed class CologneRow
        {
            internal readonly string Code;
            internal readonly int Error;
            internal readonly bool NullInput;
            internal CologneRow(string code, int error, bool nullInput) { Code = code; Error = error; NullInput = nullInput; }
        }
        private sealed class DoubleRow
        {
            internal readonly string Primary;
            internal readonly string Alternate;
            internal readonly int Error;
            internal readonly bool NullInput;
            internal DoubleRow(string primary, string alternate, int error, bool nullInput) { Primary = primary; Alternate = alternate; Error = error; NullInput = nullInput; }
        }

        [SqlFunction(IsDeterministic = true, IsPrecise = true, DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None, FillRowMethodName = "FillCologneRow",
            TableDefinition = "PhoneticCode nvarchar(max), ErrorCode int")]
        public static IEnumerable EvaluateCologne(SqlChars text)
        {
            bool nullInput = text.IsNull;
            int error; string prepared, code = null;
            try
            {
                error = PhoneticInput.Prepare(text, true, out prepared);
                if (error == 0 && !nullInput) code = CologneKernel.Encode(prepared);
            }
            catch (PhoneticQuotaException) { error = 2; }
            CologneRow row = new CologneRow(code, error, nullInput);
            Validate(row);
            // Kein Enumerator mit später Facharbeit: gesamte feste Zeile ist fertig.
            return new CologneRow[] { row };
        }

        [SqlFunction(IsDeterministic = true, IsPrecise = true, DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None, FillRowMethodName = "FillDoubleMetaphoneRow",
            TableDefinition = "PrimaryCode nvarchar(max), AlternateCode nvarchar(max), ErrorCode int")]
        public static IEnumerable EvaluateDoubleMetaphone(SqlChars text)
        {
            bool nullInput = text.IsNull;
            int error; string prepared, primary = null, alternate = null;
            try
            {
                error = PhoneticInput.Prepare(text, false, out prepared);
                if (error == 0 && !nullInput)
                {
                    DoubleMetaphoneKernel.DoubleMetaphoneResult result = DoubleMetaphoneKernel.Encode(prepared);
                    primary = result.Primary; alternate = result.Alternate;
                    if (checked(primary.Length + alternate.Length) > PhoneticInput.MaximumCodePair) throw new PhoneticQuotaException();
                }
            }
            catch (PhoneticQuotaException) { error = 2; primary = null; alternate = null; }
            DoubleRow row = new DoubleRow(primary, alternate, error, nullInput);
            Validate(row);
            return new DoubleRow[] { row };
        }

        public static void FillCologneRow(object value, out SqlString phoneticCode, out SqlInt32 errorCode)
        {
            CologneRow row = value as CologneRow;
            if (row == null) throw new InvalidOperationException("PHONETIC_COLOGNE_ROW_TYPE");
            Validate(row);
            phoneticCode = row.Code == null ? SqlString.Null : new SqlString(row.Code);
            errorCode = new SqlInt32(row.Error);
        }
        public static void FillDoubleMetaphoneRow(object value, out SqlString primaryCode, out SqlString alternateCode, out SqlInt32 errorCode)
        {
            DoubleRow row = value as DoubleRow;
            if (row == null) throw new InvalidOperationException("PHONETIC_DOUBLE_ROW_TYPE");
            Validate(row);
            primaryCode = row.Primary == null ? SqlString.Null : new SqlString(row.Primary);
            alternateCode = row.Alternate == null ? SqlString.Null : new SqlString(row.Alternate);
            errorCode = new SqlInt32(row.Error);
        }
        private static void Validate(CologneRow row)
        {
            if (row.Error < 0 || row.Error > 3 || row.NullInput && row.Error != 0 ||
                ((row.Error != 0 || row.NullInput) != (row.Code == null))) throw new InvalidOperationException("PHONETIC_COLOGNE_ROW_SHAPE");
            if (row.Code != null) PhoneticInput.ValidateCode(row.Code);
        }
        private static void Validate(DoubleRow row)
        {
            bool empty = row.Error != 0 || row.NullInput;
            if (row.Error < 0 || row.Error > 3 || row.NullInput && row.Error != 0 ||
                empty != (row.Primary == null) || empty != (row.Alternate == null)) throw new InvalidOperationException("PHONETIC_DOUBLE_ROW_SHAPE");
            if (!empty)
            {
                PhoneticInput.ValidateCode(row.Primary); PhoneticInput.ValidateCode(row.Alternate);
                if (checked(row.Primary.Length + row.Alternate.Length) > PhoneticInput.MaximumCodePair) throw new InvalidOperationException("PHONETIC_DOUBLE_ROW_PAIR");
            }
        }
    }
}

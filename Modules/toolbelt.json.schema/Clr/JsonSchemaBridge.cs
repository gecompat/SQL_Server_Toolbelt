using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.JsonSchema
{
    /// <summary>Ein interner read-only CLR-TVF-Slot; kein SQL-Kontextzugriff.</summary>
    public static class JsonSchemaBridge
    {
        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true, IsPrecise = true, FillRowMethodName = "FillRow",
            TableDefinition = "RowKind nvarchar(8), ErrorOrdinal int, Status nvarchar(24), Profile nvarchar(32), IsValid bit, DocumentPointer nvarchar(max), SchemaPointer nvarchar(max), Keyword nvarchar(128), ErrorCode nvarchar(32), ErrorsTruncated bit")]
        public static IEnumerable Validate(SqlChars json, SqlChars schema, SqlString profile,
            SqlInt64 maxDocumentBytes, SqlInt64 maxSchemaBytes, SqlInt32 maxDepth,
            SqlInt64 maxEvaluationSteps, SqlInt32 maxErrors)
        {
            if (profile.IsNull || maxDocumentBytes.IsNull || maxSchemaBytes.IsNull || maxDepth.IsNull ||
                maxEvaluationSteps.IsNull || maxErrors.IsNull) throw new ArgumentException("SCHEMA_ARGUMENT");
            return (IEnumerable)SchemaValidator.ValidateInputs(new SchemaInput(json), new SchemaInput(schema),
                profile.Value, maxDocumentBytes.Value, maxSchemaBytes.Value, maxDepth.Value,
                maxEvaluationSteps.Value, maxErrors.Value);
        }

        public static void FillRow(object value, out SqlString rowKind, out SqlInt32 errorOrdinal,
            out SqlString status, out SqlString profile, out SqlBoolean isValid,
            out SqlChars documentPointer, out SqlChars schemaPointer, out SqlString keyword,
            out SqlString errorCode, out SqlBoolean errorsTruncated)
        {
            var row = (SchemaResultRow)value;
            rowKind = new SqlString(row.RowKind); errorOrdinal = new SqlInt32(row.ErrorOrdinal);
            status = new SqlString(row.Status); profile = new SqlString(row.Profile);
            isValid = row.IsValid.HasValue ? new SqlBoolean(row.IsValid.Value) : SqlBoolean.Null;
            documentPointer = row.DocumentPointer == null ? SqlChars.Null : new SqlChars(row.DocumentPointer);
            schemaPointer = row.SchemaPointer == null ? SqlChars.Null : new SqlChars(row.SchemaPointer);
            keyword = row.Keyword == null ? SqlString.Null : new SqlString(row.Keyword);
            errorCode = row.ErrorCode == null ? SqlString.Null : new SqlString(row.ErrorCode);
            errorsTruncated = new SqlBoolean(row.ErrorsTruncated);
        }
    }
}

using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using Toolbelt.JsonConstructors;
using Toolbelt.JsonCore;

namespace Toolbelt.JsonSchema
{
    public sealed class SchemaResultRow
    {
        public string RowKind { get; internal set; }
        public int ErrorOrdinal { get; internal set; }
        public string Status { get; internal set; }
        public string Profile { get; internal set; }
        public bool? IsValid { get; internal set; }
        public string DocumentPointer { get; internal set; }
        public string SchemaPointer { get; internal set; }
        public string Keyword { get; internal set; }
        public string ErrorCode { get; internal set; }
        public bool ErrorsTruncated { get; internal set; }
    }

    /// <summary>Begrenztes Profil; nur vollständige Evaluation ergibt ein Boolurteil.</summary>
    public static class SchemaValidator
    {
        public const string ProfileName = "toolbelt-2020-12-v1";

        public static IReadOnlyList<SchemaResultRow> Validate(string json, string schema,
            string profile, long maxDocumentBytes, long maxSchemaBytes, int maxDepth,
            long maxEvaluationSteps, int maxErrors)
        {
            return ValidateInputs(new SchemaInput(json), new SchemaInput(schema), profile,
                maxDocumentBytes, maxSchemaBytes, maxDepth, maxEvaluationSteps, maxErrors);
        }

        internal static IReadOnlyList<SchemaResultRow> ValidateInputs(SchemaInput json, SchemaInput schema,
            string profile, long maxDocumentBytes, long maxSchemaBytes, int maxDepth,
            long maxEvaluationSteps, int maxErrors)
        {
            if (profile != ProfileName || maxDocumentBytes < 1 || maxDocumentBytes > 16777216 ||
                maxSchemaBytes < 1 || maxSchemaBytes > 1048576 || maxDepth < 1 || maxDepth > 128 ||
                maxEvaluationSteps < 1 || maxEvaluationSteps > 1000000 || maxErrors < 0 || maxErrors > 100)
                throw new ArgumentException("SCHEMA_ARGUMENT");
            // Höchstens 101 feste Transportzeilen und der terminale SUMMARY sind
            // Kontrollhülle. Variable Diagnosen/Pointer werden vorab belastet.
            var rows = new List<SchemaResultRow>(maxErrors + 1);
            var summary = new SchemaResultRow { RowKind = "SUMMARY", Profile = ProfileName };
            rows.Add(summary);
            if (json.IsNull || schema.IsNull) { Finish(rows, "SQL_NULL", null, "SQL_NULL", false); return rows.AsReadOnly(); }
            var work = new JsonWorkBudget(maxEvaluationSteps);
            SchemaEvaluation evaluation = null;
            bool documentStage = false;
            try
            {
                if (2L * schema.Length > maxSchemaBytes) throw new SchemaFailure("LIMIT", "SCHEMA_BYTES", null, null);
                var schemaTree = Parse(schema.Read(work), "INVALID_SCHEMA", maxDepth, work);
                var preflight = new SchemaPreflight(schemaTree);
                preflight.Run();
                documentStage = true;
                if (2L * json.Length > maxDocumentBytes) throw new SchemaFailure("LIMIT", "DOCUMENT_BYTES", null, null);
                var document = Parse(json.Read(work), "INVALID_JSON", maxDepth, work);
                evaluation = new SchemaEvaluation(preflight, document, rows, maxErrors);
                evaluation.Run();
                Finish(rows, evaluation.Invalid ? "INVALID_INSTANCE" : "VALID", !evaluation.Invalid,
                    evaluation.Invalid ? "INSTANCE_VIOLATION" : null, evaluation.Truncated);
            }
            catch (JsonWorkLimitException)
            {
                Finish(rows, "LIMIT", null, "EVALUATION_LIMIT", evaluation != null && evaluation.Truncated);
            }
            catch (SchemaFailure failure)
            {
                summary.SchemaPointer = documentStage ? null : failure.Path;
                summary.DocumentPointer = documentStage ? failure.Path : null;
                summary.Keyword = failure.Keyword;
                bool truncated = maxErrors == 0;
                if (maxErrors > 0)
                    rows.Add(new SchemaResultRow { RowKind = "ERROR", ErrorOrdinal = 1,
                        SchemaPointer = summary.SchemaPointer, DocumentPointer = summary.DocumentPointer,
                        Keyword = failure.Keyword, ErrorCode = failure.Code });
                Finish(rows, failure.Status, null, failure.Code, truncated);
            }
            return rows.AsReadOnly();
        }

        private static SchemaTree Parse(string input, string invalid, int depth, JsonWorkBudget work)
        {
            JsonTokenDocument tokens = JsonCanonicalCore.ScanTokens(input, depth, work);
            if (tokens.Syntax.Status == 2) throw new SchemaFailure("LIMIT", "DEPTH_LIMIT", null, null);
            if (tokens.Syntax.Status != 0) throw new SchemaFailure(invalid, "JSON_SYNTAX", null, null);
            if (!tokens.DecodeStrings()) throw new SchemaFailure("UNSUPPORTED", "UNPAIRED_SURROGATE", null, null);
            int duplicate;
            var tree = new SchemaTree(tokens, work);
            if (!tokens.CheckDuplicateKeys(out duplicate)) tree.Fail(invalid, "DUPLICATE_KEY", duplicate, null);
            return tree;
        }

        private static void Finish(List<SchemaResultRow> rows, string status, bool? valid, string code, bool truncated)
        {
            rows[0].ErrorCode = code;
            foreach (SchemaResultRow row in rows)
            {
                row.Status = status; row.Profile = ProfileName;
                row.IsValid = valid; row.ErrorsTruncated = truncated;
            }
        }
    }

    /// <summary>Die Dokumentkopie beginnt erst nach abgeschlossenem Schema-Preflight.</summary>
    internal sealed class SchemaInput
    {
        private readonly string text;
        private readonly SqlChars sql;
        internal SchemaInput(string text) { this.text = text; }
        internal SchemaInput(SqlChars sql) { this.sql = sql; }
        internal bool IsNull { get { return sql == null ? text == null : sql.IsNull; } }
        internal long Length { get { return sql == null ? text.Length : sql.Length; } }
        internal string Read(JsonWorkBudget work)
        {
            work.Spend(checked(2L * Length));
            return sql == null ? text : new String(sql.Value);
        }
    }

    internal sealed class SchemaEvaluation
    {
        private readonly SchemaPreflight schema;
        private readonly SchemaTree document;
        private readonly JsonWorkBudget work;
        private readonly List<SchemaResultRow> rows;
        private readonly int maxErrors;
        private readonly List<EvaluationFrame> tasks;
        private readonly Dictionary<int, ExactJsonNumber> numbers;
        internal bool Invalid, Truncated;
        private struct EvaluationFrame { internal int Schema, Document, Step; }

        internal SchemaEvaluation(SchemaPreflight schema, SchemaTree document,
            List<SchemaResultRow> rows, int maxErrors)
        {
            this.schema = schema; this.document = document; this.rows = rows; this.maxErrors = maxErrors;
            work = document.Work;
            work.Spend(document.Document.Count + 3L);
            tasks = new List<EvaluationFrame>();
            numbers = new Dictionary<int, ExactJsonNumber>(document.Document.Count);
        }

        private void Push(int schemaId, int documentId, int step)
        {
            if (tasks.Count == tasks.Capacity)
            {
                int capacity = tasks.Capacity == 0 ? 4 : checked(tasks.Capacity * 2);
                work.Spend((long)capacity + tasks.Count); tasks.Capacity = capacity;
            }
            work.Spend(1); tasks.Add(new EvaluationFrame { Schema = schemaId, Document = documentId, Step = step });
        }

        internal void Run()
        {
            Push(0, 0, 0);
            while (tasks.Count > 0)
            {
                work.Spend(1);
                EvaluationFrame task = tasks[tasks.Count - 1]; tasks.RemoveAt(tasks.Count - 1);
                SchemaNode node = schema.Nodes[task.Schema];
                JsonToken value = document.Document.Get(task.Document);
                if (task.Step == -1)
                {
                    Violation(task.Document, node.Id, "additionalProperties", "ADDITIONAL_PROPERTY"); continue;
                }
                if (task.Step >= 18) continue;
                if (node.IsBoolean)
                {
                    if (!node.BooleanValue) Violation(task.Document, node.Id, null, "FALSE_SCHEMA");
                    continue;
                }
                Push(node.Id, task.Document, task.Step + 1);
                if (task.Step == 0)
                {
                    if (node.Reference >= 0) Push(node.Reference, task.Document, 0);
                    continue;
                }
                if (task.Step == 1) continue;
                string keyword = Keyword(task.Step);
                int location;
                if (!node.Keywords.TryGetValue(keyword, out location)) continue;
                switch (task.Step)
                {
                    case 2:
                        int mask = 1 << (int)value.Kind;
                        if (value.Kind == JsonValueKind.Number && Number(task.Document).IsInteger(work)) mask |= 64;
                        if ((node.TypeMask & mask) == 0) Violation(task.Document, location, keyword, "TYPE");
                        break;
                    case 3: case 4:
                        if (value.Kind == JsonValueKind.Object) Count(node, task.Document, location, keyword, document.Children(task.Document, false).Count, task.Step == 3, "MIN_PROPERTIES", "MAX_PROPERTIES");
                        break;
                    case 5:
                        if (value.Kind == JsonValueKind.Object)
                            foreach (int required in schema.Tree.Children(location, false))
                                if (document.Member(task.Document, schema.Tree.Document.Get(required).StringValue) < 0)
                                    Violation(task.Document, required, keyword, "REQUIRED");
                        break;
                    case 6: case 7:
                        if (value.Kind == JsonValueKind.Object) ObjectChildren(node, task.Document, location, task.Step == 7);
                        break;
                    case 8: case 9:
                        if (value.Kind == JsonValueKind.Array) Count(node, task.Document, location, keyword, document.Children(task.Document, false).Count, task.Step == 8, "MIN_ITEMS", "MAX_ITEMS");
                        break;
                    case 10: case 11:
                        if (value.Kind == JsonValueKind.Array) ArrayChildren(node, task.Document, location, task.Step == 11);
                        break;
                    case 12: case 13:
                        if (value.Kind == JsonValueKind.String) Count(node, task.Document, location, keyword, value.ScalarLength, task.Step == 12, "MIN_LENGTH", "MAX_LENGTH");
                        break;
                    default:
                        if (value.Kind == JsonValueKind.Number)
                        {
                            int comparison = Number(task.Document).Compare(node.Bounds[keyword], work);
                            bool failed = task.Step == 14 ? comparison < 0 : task.Step == 15 ? comparison > 0 :
                                task.Step == 16 ? comparison <= 0 : comparison >= 0;
                            if (failed) Violation(task.Document, location, keyword,
                                task.Step == 14 ? "MINIMUM" : task.Step == 15 ? "MAXIMUM" :
                                task.Step == 16 ? "EXCLUSIVE_MINIMUM" : "EXCLUSIVE_MAXIMUM");
                        }
                        break;
                }
            }
        }

        private ExactJsonNumber Number(int id)
        {
            work.Spend(1);
            ExactJsonNumber result;
            if (!numbers.TryGetValue(id, out result))
            {
                result = ExactJsonNumber.FromToken(document.Document, id, work); numbers.Add(id, result);
            }
            return result;
        }

        private void Count(SchemaNode node, int id, int location, string keyword, int count,
            bool minimum, string minCode, string maxCode)
        {
            int comparison = ExactJsonNumber.FromCount(count, work).Compare(node.Bounds[keyword], work);
            if (minimum ? comparison < 0 : comparison > 0) Violation(id, location, keyword, minimum ? minCode : maxCode);
        }

        private void ObjectChildren(SchemaNode node, int id, int location, bool additional)
        {
            List<int> children = document.Children(id, true);
            int properties;
            bool hasProperties = node.Keywords.TryGetValue("properties", out properties);
            for (int index = children.Count - 1; index >= 0; index--)
            {
                int child = children[index];
                int target = hasProperties ? schema.Tree.Member(properties, document.Document.Get(child).Key) : -1;
                if (!additional && target >= 0) Push(target, child, 0);
                else if (additional && target < 0)
                {
                    SchemaNode extra = schema.Nodes[location];
                    if (!extra.IsBoolean) Push(location, child, 0);
                    else if (!extra.BooleanValue) Push(location, child, -1);
                }
            }
        }

        private void ArrayChildren(SchemaNode node, int id, int location, bool items)
        {
            List<int> children = document.Children(id, false);
            int prefix;
            List<int> schemas = null;
            if (node.Keywords.TryGetValue("prefixItems", out prefix)) schemas = schema.Tree.Children(prefix, false);
            int count = schemas == null ? 0 : schemas.Count;
            for (int index = children.Count - 1; index >= 0; index--)
            {
                work.Spend(1);
                if (items && index >= count) Push(location, children[index], 0);
                else if (!items && index < count) Push(schemas[index], children[index], 0);
            }
        }

        private void Violation(int documentId, int schemaId, string keyword, string code)
        {
            work.Spend(1);
            Invalid = true;
            if (rows.Count - 1 == maxErrors) { Truncated = true; return; }
            work.Spend(2); // Diagnose plus bereits bezahlte terminale Statusübernahme.
            string documentPath = document.Path(documentId), schemaPath = schema.Tree.Path(schemaId);
            rows.Add(new SchemaResultRow { RowKind = "ERROR", ErrorOrdinal = rows.Count,
                DocumentPointer = documentPath, SchemaPointer = schemaPath, Keyword = keyword, ErrorCode = code });
        }

        private static string Keyword(int step)
        {
            switch (step)
            {
                case 2: return "type"; case 3: return "minProperties"; case 4: return "maxProperties";
                case 5: return "required"; case 6: return "properties"; case 7: return "additionalProperties";
                case 8: return "minItems"; case 9: return "maxItems"; case 10: return "prefixItems";
                case 11: return "items"; case 12: return "minLength"; case 13: return "maxLength";
                case 14: return "minimum"; case 15: return "maximum";
                case 16: return "exclusiveMinimum"; case 17: return "exclusiveMaximum";
                default: throw new InvalidOperationException("EVALUATION_STEP");
            }
        }
    }
}

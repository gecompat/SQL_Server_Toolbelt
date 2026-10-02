using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Reflection;
using System.Globalization;
using Microsoft.SqlServer.Server;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace Toolbelt.Tsql.ScriptParser
{
    public static class ScriptParserProvider
    {
        private const int DefaultMaxNestingDepth = 100;

        #region Public CLR TVF Entry Points

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true,
            IsPrecise = true,
            FillRowMethodName = "FillNodeRow",
            TableDefinition =
                "NodeId int, " +
                "ParentNodeId int, " +
                "Depth int, " +
                "SiblingOrdinal int, " +
                "PropertyName nvarchar(128), " +
                "PropertyIndex int, " +
                "NodeType nvarchar(128), " +
                "StartOffset int, " +
                "StartLine int, " +
                "StartColumn int, " +
                "FragmentLength int, " +
                "FirstTokenIndex int, " +
                "LastTokenIndex int")]
        public static IEnumerable ParseScriptNodes(
            SqlChars sqlText,
            SqlInt32 tSqlVersion,
            SqlBoolean quotedIdentifiers,
            SqlInt32 maxInputBytes,
            SqlInt32 maxNestingDepth)
        {
            return BuildResult(sqlText, tSqlVersion, quotedIdentifiers, maxInputBytes, maxNestingDepth, OutputKind.Nodes);
        }

        public static void FillNodeRow(
            object value,
            out SqlInt32 nodeId,
            out SqlInt32 parentNodeId,
            out SqlInt32 depth,
            out SqlInt32 siblingOrdinal,
            out SqlString propertyName,
            out SqlInt32 propertyIndex,
            out SqlString nodeType,
            out SqlInt32 startOffset,
            out SqlInt32 startLine,
            out SqlInt32 startColumn,
            out SqlInt32 fragmentLength,
            out SqlInt32 firstTokenIndex,
            out SqlInt32 lastTokenIndex)
        {
            AstNodeRow row = (AstNodeRow)value;
            nodeId = new SqlInt32(row.NodeId);
            parentNodeId = row.ParentNodeId.HasValue ? new SqlInt32(row.ParentNodeId.Value) : SqlInt32.Null;
            depth = new SqlInt32(row.Depth);
            siblingOrdinal = new SqlInt32(row.SiblingOrdinal);
            propertyName = row.PropertyName != null ? new SqlString(row.PropertyName) : SqlString.Null;
            propertyIndex = row.PropertyIndex.HasValue ? new SqlInt32(row.PropertyIndex.Value) : SqlInt32.Null;
            nodeType = new SqlString(row.NodeType);
            startOffset = new SqlInt32(row.StartOffset);
            startLine = new SqlInt32(row.StartLine);
            startColumn = new SqlInt32(row.StartColumn);
            fragmentLength = new SqlInt32(row.FragmentLength);
            firstTokenIndex = new SqlInt32(row.FirstTokenIndex);
            lastTokenIndex = new SqlInt32(row.LastTokenIndex);
        }

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true,
            IsPrecise = true,
            FillRowMethodName = "FillPropertyRow",
            TableDefinition =
                "NodeId int, " +
                "PropertyName nvarchar(128), " +
                "PropertyKind nvarchar(32), " +
                "PropertyValue nvarchar(max)")]
        public static IEnumerable ParseScriptNodeProperties(
            SqlChars sqlText,
            SqlInt32 tSqlVersion,
            SqlBoolean quotedIdentifiers,
            SqlInt32 maxInputBytes,
            SqlInt32 maxNestingDepth)
        {
            return BuildResult(sqlText, tSqlVersion, quotedIdentifiers, maxInputBytes, maxNestingDepth, OutputKind.Properties);
        }

        public static void FillPropertyRow(
            object value,
            out SqlInt32 nodeId,
            out SqlString propertyName,
            out SqlString propertyKind,
            out SqlString propertyValue)
        {
            AstPropertyRow row = (AstPropertyRow)value;
            nodeId = new SqlInt32(row.NodeId);
            propertyName = new SqlString(row.PropertyName);
            propertyKind = new SqlString(row.PropertyKind);
            propertyValue = row.PropertyValue != null ? new SqlString(row.PropertyValue) : SqlString.Null;
        }

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true,
            IsPrecise = true,
            FillRowMethodName = "FillTokenRow",
            TableDefinition =
                "TokenIndex int, " +
                "TokenType nvarchar(64), " +
                "TokenText nvarchar(max), " +
                "StartOffset int, " +
                "StartLine int, " +
                "StartColumn int")]
        public static IEnumerable TokenizeScript(
            SqlChars sqlText,
            SqlInt32 tSqlVersion,
            SqlBoolean quotedIdentifiers,
            SqlInt32 maxInputBytes,
            SqlInt32 maxNestingDepth)
        {
            return BuildResult(sqlText, tSqlVersion, quotedIdentifiers, maxInputBytes, maxNestingDepth, OutputKind.Tokens);
        }

        public static void FillTokenRow(
            object value,
            out SqlInt32 tokenIndex,
            out SqlString tokenType,
            out SqlString tokenText,
            out SqlInt32 startOffset,
            out SqlInt32 startLine,
            out SqlInt32 startColumn)
        {
            ScriptTokenRow row = (ScriptTokenRow)value;
            tokenIndex = new SqlInt32(row.TokenIndex);
            tokenType = new SqlString(row.TokenType);
            tokenText = new SqlString(row.TokenText);
            startOffset = new SqlInt32(row.StartOffset);
            startLine = new SqlInt32(row.StartLine);
            startColumn = new SqlInt32(row.StartColumn);
        }

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true,
            IsPrecise = true,
            FillRowMethodName = "FillErrorRow",
            TableDefinition =
                "ErrorOrdinal int, " +
                "Number int, " +
                "Message nvarchar(4000), " +
                "StartOffset int, " +
                "StartLine int, " +
                "StartColumn int")]
        public static IEnumerable ParseScriptErrors(
            SqlChars sqlText,
            SqlInt32 tSqlVersion,
            SqlBoolean quotedIdentifiers,
            SqlInt32 maxInputBytes,
            SqlInt32 maxNestingDepth)
        {
            return BuildResult(sqlText, tSqlVersion, quotedIdentifiers, maxInputBytes, maxNestingDepth, OutputKind.Errors);
        }

        public static void FillErrorRow(
            object value,
            out SqlInt32 errorOrdinal,
            out SqlInt32 number,
            out SqlString message,
            out SqlInt32 startOffset,
            out SqlInt32 startLine,
            out SqlInt32 startColumn)
        {
            ScriptErrorRow row = (ScriptErrorRow)value;
            errorOrdinal = new SqlInt32(row.ErrorOrdinal);
            number = new SqlInt32(row.Number);
            message = new SqlString(row.Message);
            startOffset = new SqlInt32(row.StartOffset);
            startLine = new SqlInt32(row.StartLine);
            startColumn = new SqlInt32(row.StartColumn);
        }

        #endregion

        #region AST Traversal and Helpers

        private enum OutputKind { Nodes, Properties, Tokens, Errors }

        // A call returns its list only after all validation and accounting succeeds.
        private static IEnumerable BuildResult(SqlChars input, SqlInt32 versionArg, SqlBoolean quotedArg,
            SqlInt32 bytesArg, SqlInt32 depthArg, OutputKind kind)
        {
            var rows = new List<object>();
            if (input.IsNull) return rows;
            int version = versionArg.IsNull ? 160 : versionArg.Value;
            if (version != 80 && version != 90 && version != 100 && version != 110 && version != 120 &&
                version != 130 && version != 140 && version != 150 && version != 160 && version != 170)
                throw new ArgumentException("TBX_TSQLPARSE_INVALID_VERSION");
            int bytes = bytesArg.IsNull ? 2097152 : bytesArg.Value;
            if (bytes < 1 || bytes > 2097152) throw new ArgumentException("TBX_TSQLPARSE_INVALID_MAX_BYTES");
            int depth = depthArg.IsNull ? DefaultMaxNestingDepth : depthArg.Value;
            if (depth < 1 || depth > 256) throw new ArgumentException("TBX_TSQLPARSE_INVALID_MAX_DEPTH");
            if (checked(input.Length * 2L) > bytes) throw new InvalidOperationException("TBX_TSQLPARSE_INPUT_TOO_LARGE");
            string sql = input.ToSqlString().Value;
            int atoms, structure, comments;
            string guard = PreparseGuard.Guard(sql, depth, out atoms, out structure, out comments);
            if (guard != "ACCEPT") throw new InvalidOperationException(guard);
            TSqlParser parser = CreateParser(version, quotedArg.IsNull || quotedArg.Value);
            IList<ParseError> errors;
            IList<TSqlParserToken> tokens;
            using (var reader = new StringReader(sql)) tokens = parser.GetTokenStream(reader, out errors);
            if (tokens.Count > 8192) throw new InvalidOperationException("TBX_TSQLPARSE_OUTPUT_LIMIT");
            var budget = new OutputBudget(kind == OutputKind.Nodes ? 32768 : kind == OutputKind.Properties ? 131072 : kind == OutputKind.Tokens ? 8192 : 256, 16777216);
            if (errors.Count != 0) { if (kind == OutputKind.Errors) AddErrors(errors, rows, budget); return rows; }
            if (kind == OutputKind.Tokens)
            {
                int index = 0;
                foreach (var token in tokens)
                {
                    string type = token.TokenType.ToString(), value = token.Text ?? string.Empty;
                    CheckWidth(type, 64); budget.Add(type, value);
                    rows.Add(new ScriptTokenRow(index++, type, value, token.Offset, token.Line, token.Column));
                }
                return rows;
            }
            TSqlFragment fragment = parser.Parse(tokens, out errors);
            if (errors.Count != 0) { if (kind == OutputKind.Errors) AddErrors(errors, rows, budget); return rows; }
            if (fragment != null) Walk(fragment, depth, kind, rows, budget);
            return rows;
        }

        private static void AddErrors(IList<ParseError> errors, List<object> rows, OutputBudget budget)
        {
            int ordinal = 1;
            foreach (var error in errors)
            {
                string message = error.Message ?? string.Empty;
                CheckWidth(message, 4000); budget.Add(message);
                rows.Add(new ScriptErrorRow(ordinal++, error.Number, message, error.Offset, error.Line, error.Column));
            }
        }

        private static void CheckWidth(string value, int width)
        {
            if (value != null && value.Length > width) throw new InvalidOperationException("TBX_TSQLPARSE_OUTPUT_LIMIT");
        }

        private sealed class OutputBudget
        {
            private readonly int rowLimit;
            private readonly long byteLimit;
            private int rows;
            private long bytes;
            internal OutputBudget(int rowLimit, long byteLimit) { this.rowLimit = rowLimit; this.byteLimit = byteLimit; }
            internal void Add(params string[] values)
            {
                long next = checked(bytes + 128L);
                foreach (string value in values) if (value != null) next = checked(next + value.Length * 2L);
                if (rows >= rowLimit || next > byteLimit) throw new InvalidOperationException("TBX_TSQLPARSE_OUTPUT_LIMIT");
                rows++; bytes = next;
            }
        }

        private sealed class WorkItem
        {
            internal TSqlFragment Fragment;
            internal int? Parent, Index;
            internal int Depth, Sibling;
            internal string Property;
        }

        // Both outputs use the same deterministic preorder, sorted by ordinal property name.
        private static void Walk(TSqlFragment root, int maxDepth, OutputKind kind, List<object> rows, OutputBudget budget)
        {
            var pending = new Stack<WorkItem>();
            pending.Push(new WorkItem { Fragment = root });
            int id = 0;
            while (pending.Count > 0)
            {
                WorkItem item = pending.Pop();
                if (item.Depth > maxDepth) throw new InvalidOperationException("TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED");
                int currentId = checked(++id);
                TSqlFragment fragment = item.Fragment;
                if (kind == OutputKind.Nodes)
                {
                    string type = fragment.GetType().Name;
                    CheckWidth(type, 128); CheckWidth(item.Property, 128); budget.Add(type, item.Property);
                    rows.Add(new AstNodeRow(currentId, item.Parent, item.Depth, item.Sibling, item.Property, item.Index,
                        type, fragment.StartOffset, fragment.StartLine, fragment.StartColumn, fragment.FragmentLength,
                        fragment.FirstTokenIndex, fragment.LastTokenIndex));
                }
                var children = new List<WorkItem>();
                PropertyInfo[] properties = fragment.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
                Array.Sort(properties, (a, b) => StringComparer.Ordinal.Compare(a.Name, b.Name));
                foreach (var property in properties)
                {
                    if (property.GetIndexParameters().Length != 0 || property.Name == "ScriptTokenStream" ||
                        property.Name == "FirstTokenIndex" || property.Name == "LastTokenIndex" || property.Name == "StartOffset" ||
                        property.Name == "FragmentLength" || property.Name == "StartLine" || property.Name == "StartColumn") continue;
                    object value = property.GetValue(fragment, null);
                    if (value == null) continue;
                    if (typeof(TSqlFragment).IsAssignableFrom(property.PropertyType))
                    {
                        children.Add(new WorkItem { Fragment = (TSqlFragment)value, Parent = currentId, Depth = item.Depth + 1,
                            Sibling = children.Count, Property = property.Name });
                    }
                    else if (typeof(IEnumerable).IsAssignableFrom(property.PropertyType) && property.PropertyType != typeof(string))
                    {
                        int index = 0;
                        foreach (object child in (IEnumerable)value)
                        {
                            var childFragment = child as TSqlFragment;
                            if (childFragment != null) children.Add(new WorkItem { Fragment = childFragment, Parent = currentId,
                                Depth = item.Depth + 1, Sibling = children.Count, Property = property.Name, Index = index });
                            index++;
                        }
                    }
                    else if (kind == OutputKind.Properties)
                    {
                        string propertyKind = property.PropertyType.IsEnum ? "Enum" : property.PropertyType == typeof(bool) ? "Boolean" :
                            property.PropertyType == typeof(string) ? "String" : property.PropertyType.IsPrimitive ? "Number" : "Value";
                        string formatted = value is IFormattable ? ((IFormattable)value).ToString(null, CultureInfo.InvariantCulture) : value.ToString();
                        CheckWidth(property.Name, 128); CheckWidth(propertyKind, 32); budget.Add(property.Name, propertyKind, formatted);
                        rows.Add(new AstPropertyRow(currentId, property.Name, propertyKind, formatted));
                    }
                }
                for (int i = children.Count - 1; i >= 0; i--) pending.Push(children[i]);
            }
        }

        private static TSqlParser CreateParser(int version, bool quotedIdentifiers)
        {
            switch (version)
            {
                case 80:
                    return new TSql80Parser(quotedIdentifiers);
                case 90:
                    return new TSql90Parser(quotedIdentifiers);
                case 100:
                    return new TSql100Parser(quotedIdentifiers);
                case 110:
                    return new TSql110Parser(quotedIdentifiers);
                case 120:
                    return new TSql120Parser(quotedIdentifiers);
                case 130:
                    return new TSql130Parser(quotedIdentifiers);
                case 140:
                    return new TSql140Parser(quotedIdentifiers);
                case 150:
                    return new TSql150Parser(quotedIdentifiers);
                case 160:
                    return new TSql160Parser(quotedIdentifiers);
                case 170:
                    return new TSql170Parser(quotedIdentifiers);
                default:
                    throw new ArgumentException("TBX_TSQLPARSE_INVALID_VERSION");
            }
        }

        #endregion

        #region Internal Row Types

        private sealed class AstNodeRow
        {
            public int NodeId { get; }
            public int? ParentNodeId { get; }
            public int Depth { get; }
            public int SiblingOrdinal { get; }
            public string PropertyName { get; }
            public int? PropertyIndex { get; }
            public string NodeType { get; }
            public int StartOffset { get; }
            public int StartLine { get; }
            public int StartColumn { get; }
            public int FragmentLength { get; }
            public int FirstTokenIndex { get; }
            public int LastTokenIndex { get; }

            public AstNodeRow(
                int nodeId, int? parentNodeId, int depth, int siblingOrdinal,
                string propertyName, int? propertyIndex, string nodeType,
                int startOffset, int startLine, int startColumn, int fragmentLength,
                int firstTokenIndex, int lastTokenIndex)
            {
                NodeId = nodeId;
                ParentNodeId = parentNodeId;
                Depth = depth;
                SiblingOrdinal = siblingOrdinal;
                PropertyName = propertyName;
                PropertyIndex = propertyIndex;
                NodeType = nodeType;
                StartOffset = startOffset;
                StartLine = startLine;
                StartColumn = startColumn;
                FragmentLength = fragmentLength;
                FirstTokenIndex = firstTokenIndex;
                LastTokenIndex = lastTokenIndex;
            }
        }

        private sealed class AstPropertyRow
        {
            public int NodeId { get; }
            public string PropertyName { get; }
            public string PropertyKind { get; }
            public string PropertyValue { get; }

            public AstPropertyRow(int nodeId, string propertyName, string propertyKind, string propertyValue)
            {
                NodeId = nodeId;
                PropertyName = propertyName;
                PropertyKind = propertyKind;
                PropertyValue = propertyValue;
            }
        }

        private sealed class ScriptTokenRow
        {
            public int TokenIndex { get; }
            public string TokenType { get; }
            public string TokenText { get; }
            public int StartOffset { get; }
            public int StartLine { get; }
            public int StartColumn { get; }

            public ScriptTokenRow(int tokenIndex, string tokenType, string tokenText, int startOffset, int startLine, int startColumn)
            {
                TokenIndex = tokenIndex;
                TokenType = tokenType;
                TokenText = tokenText;
                StartOffset = startOffset;
                StartLine = startLine;
                StartColumn = startColumn;
            }
        }

        private sealed class ScriptErrorRow
        {
            public int ErrorOrdinal { get; }
            public int Number { get; }
            public string Message { get; }
            public int StartOffset { get; }
            public int StartLine { get; }
            public int StartColumn { get; }

            public ScriptErrorRow(int errorOrdinal, int number, string message, int startOffset, int startLine, int startColumn)
            {
                ErrorOrdinal = errorOrdinal;
                Number = number;
                Message = message;
                StartOffset = startOffset;
                StartLine = startLine;
                StartColumn = startColumn;
            }
        }

        #endregion
    }
}

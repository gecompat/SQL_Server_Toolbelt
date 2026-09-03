using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Reflection;
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
            if (sqlText.IsNull) yield break;

            string sql = ValidateAndGetString(sqlText, maxInputBytes);
            int version = tSqlVersion.IsNull ? 160 : tSqlVersion.Value;
            bool quoted = quotedIdentifiers.IsNull || quotedIdentifiers.Value;
            int maxDepth = maxNestingDepth.IsNull ? DefaultMaxNestingDepth : maxNestingDepth.Value;

            TSqlParser parser = CreateParser(version, quoted);
            IList<ParseError> errors;
            TSqlFragment fragment;
            using (StringReader reader = new StringReader(sql))
            {
                fragment = parser.Parse(reader, out errors);
            }

            if (fragment == null) yield break;

            int nodeIdCounter = 0;
            List<AstNodeRow> rows = new List<AstNodeRow>();
            TraverseAst(fragment, null, 0, 0, null, null, ref nodeIdCounter, maxDepth, rows);

            foreach (AstNodeRow row in rows)
            {
                yield return row;
            }
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
            if (sqlText.IsNull) yield break;

            string sql = ValidateAndGetString(sqlText, maxInputBytes);
            int version = tSqlVersion.IsNull ? 160 : tSqlVersion.Value;
            bool quoted = quotedIdentifiers.IsNull || quotedIdentifiers.Value;
            int maxDepth = maxNestingDepth.IsNull ? DefaultMaxNestingDepth : maxNestingDepth.Value;

            TSqlParser parser = CreateParser(version, quoted);
            IList<ParseError> errors;
            TSqlFragment fragment;
            using (StringReader reader = new StringReader(sql))
            {
                fragment = parser.Parse(reader, out errors);
            }

            if (fragment == null) yield break;

            int nodeIdCounter = 0;
            List<AstPropertyRow> propertyRows = new List<AstPropertyRow>();
            TraverseProperties(fragment, ref nodeIdCounter, maxDepth, 0, propertyRows);

            foreach (AstPropertyRow row in propertyRows)
            {
                yield return row;
            }
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
            if (sqlText.IsNull) yield break;

            string sql = ValidateAndGetString(sqlText, maxInputBytes);
            int version = tSqlVersion.IsNull ? 160 : tSqlVersion.Value;
            bool quoted = quotedIdentifiers.IsNull || quotedIdentifiers.Value;

            TSqlParser parser = CreateParser(version, quoted);
            IList<ParseError> errors;
            TSqlFragment fragment;
            using (StringReader reader = new StringReader(sql))
            {
                fragment = parser.Parse(reader, out errors);
            }

            if (fragment?.ScriptTokenStream != null)
            {
                int index = 0;
                foreach (TSqlParserToken token in fragment.ScriptTokenStream)
                {
                    yield return new ScriptTokenRow(
                        index++,
                        token.TokenType.ToString(),
                        token.Text ?? string.Empty,
                        token.Offset,
                        token.Line,
                        token.Column);
                }
            }
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
            if (sqlText.IsNull) yield break;

            string sql = ValidateAndGetString(sqlText, maxInputBytes);
            int version = tSqlVersion.IsNull ? 160 : tSqlVersion.Value;
            bool quoted = quotedIdentifiers.IsNull || quotedIdentifiers.Value;

            TSqlParser parser = CreateParser(version, quoted);
            IList<ParseError> errors;
            using (StringReader reader = new StringReader(sql))
            {
                parser.Parse(reader, out errors);
            }

            if (errors != null)
            {
                int ordinal = 1;
                foreach (ParseError err in errors)
                {
                    yield return new ScriptErrorRow(
                        ordinal++,
                        err.Number,
                        err.Message ?? string.Empty,
                        err.Offset,
                        err.Line,
                        err.Column);
                }
            }
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

        private static string ValidateAndGetString(SqlChars sqlText, SqlInt32 maxInputBytes)
        {
            if (!maxInputBytes.IsNull)
            {
                int maxBytes = maxInputBytes.Value;
                if (maxBytes <= 0)
                {
                    throw new ArgumentException("TBX_TSQLPARSE_INVALID_MAX_BYTES: MaxInputBytes muss größer als 0 sein.");
                }

                long byteCount = sqlText.Length * sizeof(char);
                if (byteCount > maxBytes)
                {
                    throw new InvalidOperationException(
                        string.Format("TBX_TSQLPARSE_INPUT_TOO_LARGE: Eingabe überschreitet das Limit von {0} Bytes.", maxBytes));
                }
            }

            return sqlText.ToSqlString().Value;
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
                    return new TSql160Parser(quotedIdentifiers);
            }
        }

        private static void TraverseAst(
            TSqlFragment fragment,
            int? parentId,
            int depth,
            int siblingOrdinal,
            string propertyName,
            int? propertyIndex,
            ref int nodeIdCounter,
            int maxDepth,
            List<AstNodeRow> rows)
        {
            if (fragment == null) return;
            if (depth > maxDepth)
            {
                throw new InvalidOperationException(
                    string.Format("TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED: Schachtelungstiefe überschreitet {0}.", maxDepth));
            }

            int currentId = ++nodeIdCounter;
            rows.Add(new AstNodeRow(
                currentId,
                parentId,
                depth,
                siblingOrdinal,
                propertyName,
                propertyIndex,
                fragment.GetType().Name,
                fragment.StartOffset,
                fragment.StartLine,
                fragment.StartColumn,
                fragment.FragmentLength,
                fragment.FirstTokenIndex,
                fragment.LastTokenIndex));

            PropertyInfo[] props = fragment.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
            int childSibling = 0;
            foreach (PropertyInfo prop in props)
            {
                if (prop.GetIndexParameters().Length > 0)
                {
                    continue;
                }

                if (prop.Name == "ScriptTokenStream" || prop.Name == "FirstTokenIndex" || prop.Name == "LastTokenIndex" ||
                    prop.Name == "StartOffset" || prop.Name == "FragmentLength" || prop.Name == "StartLine" || prop.Name == "StartColumn")
                {
                    continue;
                }

                if (typeof(TSqlFragment).IsAssignableFrom(prop.PropertyType))
                {
                    TSqlFragment child = prop.GetValue(fragment, null) as TSqlFragment;
                    if (child != null)
                    {
                        TraverseAst(child, currentId, depth + 1, childSibling++, prop.Name, null, ref nodeIdCounter, maxDepth, rows);
                    }
                }
                else if (typeof(IEnumerable).IsAssignableFrom(prop.PropertyType) && prop.PropertyType != typeof(string))
                {
                    IEnumerable list = prop.GetValue(fragment, null) as IEnumerable;
                    if (list != null)
                    {
                        int listIndex = 0;
                        foreach (object item in list)
                        {
                            TSqlFragment childItem = item as TSqlFragment;
                            if (childItem != null)
                            {
                                TraverseAst(childItem, currentId, depth + 1, childSibling++, prop.Name, listIndex, ref nodeIdCounter, maxDepth, rows);
                            }
                            listIndex++;
                        }
                    }
                }
            }
        }

        private static void TraverseProperties(
            TSqlFragment fragment,
            ref int nodeIdCounter,
            int maxDepth,
            int depth,
            List<AstPropertyRow> propertyRows)
        {
            if (fragment == null) return;
            if (depth > maxDepth)
            {
                throw new InvalidOperationException("TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED");
            }

            int currentId = ++nodeIdCounter;

            PropertyInfo[] props = fragment.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
            List<TSqlFragment> childFragments = new List<TSqlFragment>();

            foreach (PropertyInfo prop in props)
            {
                if (prop.GetIndexParameters().Length > 0)
                {
                    continue;
                }

                if (prop.Name == "ScriptTokenStream" || prop.Name == "FirstTokenIndex" || prop.Name == "LastTokenIndex" ||
                    prop.Name == "StartOffset" || prop.Name == "FragmentLength" || prop.Name == "StartLine" || prop.Name == "StartColumn")
                {
                    continue;
                }

                if (typeof(TSqlFragment).IsAssignableFrom(prop.PropertyType))
                {
                    TSqlFragment child = prop.GetValue(fragment, null) as TSqlFragment;
                    if (child != null) childFragments.Add(child);
                }
                else if (typeof(IEnumerable).IsAssignableFrom(prop.PropertyType) && prop.PropertyType != typeof(string))
                {
                    IEnumerable list = prop.GetValue(fragment, null) as IEnumerable;
                    if (list != null)
                    {
                        foreach (object item in list)
                        {
                            if (item is TSqlFragment childItem) childFragments.Add(childItem);
                        }
                    }
                }
                else
                {
                    object val = prop.GetValue(fragment, null);
                    if (val != null)
                    {
                        string kind = prop.PropertyType.IsEnum ? "Enum" :
                                      prop.PropertyType == typeof(bool) ? "Boolean" :
                                      prop.PropertyType == typeof(string) ? "String" :
                                      prop.PropertyType.IsPrimitive ? "Number" : "Value";

                        propertyRows.Add(new AstPropertyRow(currentId, prop.Name, kind, val.ToString()));
                    }
                }
            }

            foreach (TSqlFragment child in childFragments)
            {
                TraverseProperties(child, ref nodeIdCounter, maxDepth, depth + 1, propertyRows);
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

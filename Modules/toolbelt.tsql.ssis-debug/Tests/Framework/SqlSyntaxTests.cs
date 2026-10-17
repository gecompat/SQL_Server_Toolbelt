using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading;
using Microsoft.SqlServer.TransactSql.ScriptDom;
internal static class SqlSyntaxTests
{
    internal static int Main(string[] args)
    {
        bool success = false;
        var worker = new Thread(() => {
            try {
                string sql = File.ReadAllText(args[0]); if (sql.Length > 16777216) return;
                sql = Regex.Replace(sql, "(?m)^:On Error exit\\s*$", "");
                sql = sql.Replace("$(DeploymentMode)", "local");
                sql = Regex.Replace(sql, "0x[0-9A-Fa-f]{2048,}", "0x0102");
                if (sql.Contains("$(") || Regex.IsMatch(sql, "(?m)^:")) return;
                int version = Int32.Parse(args[1]); TSqlParser parser = version == 150 ? (TSqlParser)new TSql150Parser(true) : version == 160 ? (TSqlParser)new TSql160Parser(true) : new TSql170Parser(true);
                IList<ParseError> errors; using (var reader = new StringReader(sql)) parser.Parse(reader, out errors);
                if (errors.Count != 0) { foreach (var e in errors) Console.Error.WriteLine("SQL_SYNTAX_ERROR " + e.Number + " LINE " + e.Line + " COLUMN " + e.Column); return; }
                success = true;
            } catch { Console.Error.WriteLine("SQL_SYNTAX_FAILURE"); }
        }, 262144);
        worker.Start(); worker.Join(); if (success) Console.WriteLine("SQL_SYNTAX_PASS"); return success ? 0 : 1;
    }
}

using System;
using System.Collections.Generic;
using System.Linq;

namespace Toolbelt.Tsql.SsisDebug
{
    // Paketmetadaten sind eine Entwurfssicht, kein Nachweis des SQL-Zielzustands.
    // Dieser Provider hat absichtlich weder Connection noch SQL-Adapter.
    internal sealed class PackageCatalog : ICatalog
    {
        internal PackageCatalog(Package p, Options o, Budget b) { }
        public string Collation(string database) { return "Latin1_General_100_BIN2"; }
        public bool IsCollation(string name) { return name == "Latin1_General_100_BIN2" || name == "Latin1_General_100_BIN2_UTF8"; }
        public int CodePage(string name) { if (!IsCollation(name)) throw new DebugFault("missing_context", "Collation ist ohne Katalog nicht bekannt."); return name.EndsWith("_UTF8", StringComparison.Ordinal) ? 65001 : 1252; }
        public string BindIdentifier(string database, IEnumerable<string> candidates, string name)
        {
            var names = candidates.Where(n => String.Equals(n, name, StringComparison.Ordinal)).ToList();
            if (names.Count > 1) throw new DebugFault("unresolved_binding", "Paketmetadaten enthalten mehrdeutige Spaltennamen.");
            return names.SingleOrDefault();
        }
        public BoundObject Resolve(string database, string schema, string name) { return null; }
        internal static void MarkUnverified(Artifacts artifacts)
        {
            foreach (var row in artifacts.Rows)
            {
                if (row.Safety == "passed") { row.Safety = "not_checked"; row.Evidence = "pragmatic"; }
                if (row.Kind.EndsWith("Sql", StringComparison.Ordinal) || row.Kind == "DebugScript" || row.Kind == "ProcedureDefinition")
                {
                    if (row.Safety != "blocked") { row.Evidence = "pragmatic"; row.Safety = "not_checked"; }
                    row.Executable = false;
                    // Einzelartefakte behalten ihre gehashten Bytes. Nur das
                    // zusammengesetzte, nicht separat gehashte Script ergaenzen.
                    if (row.Kind == "DebugScript" && row.Complete)
                        artifacts.ReplaceContent(row, "-- Paketbasierter Debugentwurf: Zielobjekte, RLS, Collation und Serveridentität nicht kataloggeprüft.\n" + row.Content);
                }
            }
            artifacts.Diagnostic("package_metadata_only", null, "SQL aus DTSX-Metadaten erzeugt, ohne Quellkatalogzugriff. Objektart, Typen, RLS und Collation nicht am Ziel geprüft. Ordinale Namensbindung und BIN2/1252 beziehungsweise explizite UTF8-Paketcodepage sind Entwurfsannahmen. IsExecutable bleibt deshalb false; manuelle Ausführung nach Prüfung möglich.");
        }
    }
}

# Begrenzte native JSON-Closure-Qualifikation

Stand2026-10-05, Codex. Die konkrete Schema-/Kern-/Constructorwelle ist
funktionsbezogen freigegeben; die fortgeltende
[Trustautorität](../../toolbelt.json.core/Documentation/TRUST_OPT_IN_PROPOSAL.md)
verlangt keine erneuten Schemahashfragen. Ausgeführt wurde der öffentliche
`Tests/CI/run-json-schema-lab.ps1` gegen frisch schema-validierte ausdrücklich
ausgewählte bereite Labziele, mit vorhandenen Rechten und strict security1.

| Scope | Linux/SQL2019/latest CL150 | Windows/SQL2025/CU8 CL170 |
|---|---|---|
| Core/Schema local/central | bestanden | bestanden |
| Constructors1.3 vier ausgewählte Fixtures | lokal bestanden | lokal/zentral bestanden |
| Genuine bekannte1.2→1.3 local/central, dieselben vier aktuellen Fixtures | bestanden | bestanden |
| Frischer read-only Core-/Schema-Dispositionaudit | bestanden | bestanden |
| Frischer read-only Migrations-Dispositionaudit | bestanden | bestanden |

Alle abschließenden Adapter hatten tatsächlichen Exit0, vollständige
stdout-/stderr-Capture, leeres stderr, unveränderte eingefrorene Inputs und
`COMPLETE` mit verifizierter eigener DB-/Trustdisposition. Es erfolgten keine
Konfigurations-, Rechte-, Owner- oder Lab-Infrastrukturänderungen. Private
Journale, konkrete Vorzustände und Runtimekanäle bleiben unversioniert.

## Tatsächlicher fachlicher Umfang

Core/Schema:26 Fälle aus `Contract.Tests.sql`, `Safety.Tests.sql` und ein
direkter Clientreader mit genau einem Resultset, zehn öffentlichen Typen/
Ordinals, SUMMARY/ERROR-Reihenfolge und einheitlichem Urteil. Geprüft wurden
unter anderem Scalars, SQL-NULL-Priorität, ungültige Syntax/Unicode/Duplikate,
exakte riesige Zahlen, nicht unterstützte unbenutzte Schemaorte, Referenzzyklen,
lokale Referenzen, Budget1, Tiefe129 und `MaxErrors`0/1. Helpfirst,
Argument-/Namensraumfehler, ResultTable-Replace/Append und committabler
Callerrollback sind im Safety-Scope enthalten. Die erweiterte abschließende
Safety-Fixture bestand außerdem echte CHECK-Constraintfehler nach Routing:
Ownrollback, Savepoint-Erhalt vorheriger Caller-Arbeit und doomeder Caller
bleiben korrekt; die aufrufende Fixture rollt ihren eigenen doomen Caller zurück.
Ein voriger55691/state10-Fixturefehllauf bleibt fehlgeschlagen; Transaktions-
und Tabellenorakel werden im korrigierten Test getrennt ausgeführt.
Erst-/Repeat-Install,
Core-Consumer-Reject, Schema-SQL-Consumer-Reject und Uninstall/Repeat
einschließlich unveränderter Coreidentität nach Schema-DROP bestanden.

Constructors: `JsonAggregates.Contract.sql`, `JsonConstructors.Contract.sql`,
`JsonGroups.Contract.sql`, `InstalledMetadata.Contract.sql`. Die vollständige
Constructor-Fixture enthält unverändert16-MiB-Ausgabe und100000 Einträge;
die vorigen20-/60-Sekunden-Timeouts sind keine erfolgreichen Gesamtläufe.
Ein endliches300-Sekunden-Commandbudget innerhalb des endlichen Gesamtbudgets
ermöglichte die vollständige Prüfung. Progresswitnesses enthalten nur feste
synthetische Phasenbezeichner, keine Payloads.

## Genuine Migration und Enginegrenze

Der historische1.2-Installer und die DLL wurden aus unveränderten Git-Blobs
des Commit46b2f078662a3203a8da67bfe331b33607962082 gebaut. Die DLL stimmt
exakt mit der unveränderten historischen Known-Artifact-Zeile überein.
Kein imitierter Versionsmarker oder neu erzeugter angeblicher1.2-Stand.
Historische AGF-/Gruppenfixturen bestanden vor dem Übergang. Schema weist
den vorhandenen1.2-Consumer mit55633/state1 ab.

Der erste echte `ALTER ASSEMBLY` scheiterte bereinigt mit6282/state1: Die
referenzierten Assemblies dürfen dabei nicht geändert werden.
[Microsofts Fehlervertrag](https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors-6000-to-6999)
bestätigt die Enginegrenze. Der korrigierte atomare Pfad ersetzt ausschließlich
die drei eigenen CLR-Slots und eigene Assembly. Fünf Procedureidentitäten,
effektive Owner und der vorhandene Berechtigungskatalog bleiben erhalten.
Verlustgefährdete direkte CLR-/Assemblyrechte, explizite CLR-Owner oder
Zusatzmetadaten werden vor dem Austausch abgewiesen; keine GRANT-Reparatur.

In beiden Modi beider Ziele bestand die gezielte Exception nach eigenem
DROP mit exakter Rückkehr zu1.2-ObjectIds/Assemblybytes/Markern. Eine zusätzliche
Assemblyannotation wurde unverändert abgewiesen und nur die eigene Annotation
anschließend entfernt. Nach normaler Migration und neuer Verbindung bestand
die Identitäts-/Owner-/Berechtigungsprüfung, die neue Core-Referenz und die
Schema-26-Fall-Fixture. Dies beweist keine Erhaltung beliebiger direkter
CLR-Grants; dieser Installer weist solche Zustände ab. Nichtleere zusätzliche
Procedure-Grants und tatsächliche Lowpriv-Caller wurden nicht erzeugt/geprüft.

## Frische Disposition und offene Reichweite

`Tests/CI/Test-JsonSchemaLabDisposition.ps1` führte nach Ende der jeweiligen
Testverbraucher einen neuen ausschließlich lesenden Audit aus. Das exakte
abgeschlossene Journal und die ursprünglichen externen Labvertrag-/Schema-/
Promptbytes sind hashgebunden. Eigene Datenbanken sind frisch abwesend;
eigene Truständerungen sind frisch restauriert, vorhandene Trusttupel exakt
unverändert. Alte Journale ohne persistierte externe FrozenInputs erfüllen
diese neue Auditvoraussetzung nicht. Daher wurde der Core-/Schema-Scope
mit dem finalen hashgebundenen Driver erneut ausgeführt und frisch auditiert;
die früheren erfolgreichen Runs bleiben historische separate Evidenz.

SQL2022, Linux2025, Windows2019/2022, weitere Compatibility Levels,
CrossDB-Consumer, vollständige Marker-/Owner-/Lock-/Visibility-/Fremdslotmatrix,
Maximalinput-/Heap-/Spill-/Parallelitätskapazität und tatsächliche Minimalrechte
bleiben offen. Die bestehende gekoppelte GitHub-CI ist noch nicht am neuen
Produkt-PR-Head ausgeführt. Diese Teilqualifikation ist kein Release.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1`
- Scope: Linux2019/latest CL150 und Windows2025/CU8 CL170 jeweils local/central:26 Contractfälle, Safety/Help/ResultTable/Callerrollback, direkte Clientmetadaten, Repeat, Consumer-Abweisungen, Uninstall/Repeat und eigenes DB-/Trustcleanup bestanden. Beide Ziele local/central nach genuine Constructor1.2→1.3 zusätzlich26 Contractfälle bestanden. Frische hashgebundene Dispositionaudits beider aktueller Core-/Schema-/Migrationsscopes bestanden. Vollständige Lifecycle-/Zielmatrix, CrossDB und minimale Rechte offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

# JSON Pointer Resolution

`toolbelt.json.pointer` 1.0.0 enthält genau eine lesende native T-SQL-MSTVF:
`toolbelt_json.TVF_ResolveJsonPointer`. Sie löst die Stringform nach RFC6901
auf, vergleicht decodierte Keys exakt und prüft das vollständige Dokument
auf Syntax, Tiefe und ungepaarte Unicode-Surrogate.
Der freigegebene vorgelagerte Strukturguard weist beobachtete Tiefe über128
als DEPTH_LIMIT ab, auch bei sonst ungültiger Syntax; bis128 hat vollständige
Syntax Vorrang vor einem abgesenkten caller-seitigen Tiefenlimit.
Der [kanonische Vertrag](../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
beschreibt die ausdrücklich freigegebene Oberfläche und Fehlerpriorität.

Genau eine Zeile liefert `Status`, `JsonType`, `Value`, `ErrorCode`.
FOUND enthält den Wert, JSON_NULL bezeichnet terminales JSON-null, MISSING
eine fehlende Adresse und SQL_NULL ein SQL-NULL-Argument. INVALID trägt
einen stabilen Code. Zahlen bleiben Literale, Strings werden decodiert.

```sql
SELECT resolved.Status,resolved.JsonType,resolved.Value,resolved.ErrorCode
FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"a/b":[null,"example"]}',N'/a~1b/1',DEFAULT,DEFAULT) resolved;
```

Json/Pointer sind nvarchar(max). Das Inputbudget bigint=16777216 und
Tiefenbudget int=128 dürfen nur positiv abgesenkt werden; Pointer besitzt
eine feste Grenze von4000 UTF16-Einheiten. Alle Ausgabespalten verwenden
Latin1_General_100_BIN2. Keine Normalisierung und kein URIfragment-/Patchpfad.

SQL Server2019/2022/2025 Windows/Linux mit kompatiblem CL150+ sind Zielplattformen.
Local und central verwenden dieselbe TF; zentrale Caller benötigen ebenfalls
CL150+. SQLCMD-Deployment verwendet `DeploymentMode=local|central`, zentraler
Uninstall `ConfirmNoExternalConsumers=1`. Vorhandene Rechte werden verwendet;
kein CLR, Servertrust, Konfigurationswechsel oder abhängiges Modul.

[Objektvertrag](Documentation/TVF_ResolveJsonPointer.md),
[Beispiele](Examples/JsonPointer.sql), [Testmatrix](Tests/JSON_POINTER_TEST_MATRIX.md)
und [Ausführungsnachweise](Tests/README.md) sind getrennt verlinkt.
Wiederholtes Fragmentparsing kann Arbeit proportional zu Input mal Tiefe
benötigen. Keine allgemeine Heap-, Durchsatz-, Laufzeit- oder APPLY-Zusage.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope full`
- Scope: Nach ausdrücklicher128er-Prioritätsänderungsfreigabe finaler identischer eingefrorener Source-/Deployment-/Fixture-/Adapterstand auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 bestanden: jeweils local/central/Consumer,3072 feste Contract-/Safety-APPLY-Oracles,15 echte direkte Statusclientreader, installierte Baseline, Clean/Repeat/Uninstall/Repeat und42 gezielte Caller-/Lock-/Rollback-/TypedMarker-/Fremdslot-/Dependency-/Confirm0-Fälle. Je tatsächlicherExit0, vollständige Kanäle und leeresStderr. Neue unabhängige Verbindungen bestätigen COMPLETE42, drei eigeneDBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit je zwei Abweisungen und sämtlicheInputpins unverändert. Nullscope Konfiguration/Rechte/Trust. Beide früheren Gesamtfehlläufe und separate Lifecycle-Scope-Erfolge bleiben getrennt; weitere physische Ziele, Minimalrechte,16MiB-Maximalworkload/Heap und exakteHead-CI separat offen. Teilweise validiert und unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

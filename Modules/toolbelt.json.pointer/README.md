# JSON Pointer Resolution

Aktuelle [Callerrechte](../../Releases/1.0.0/POINTER-CALLER-QUALIFICATION.md): getrennte Objektrechte auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral. Weitere Funktions-, Client-, Lifecycle- und Ressourcengates sowie Modulstatus bleiben separat.

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
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope full`
- Scope: Aktuelle physische Windows-/Linux-Matrix SQL2019 CL150, SQL2022 CL150/160, SQL2025 CL150/160/170: zwölf vollständige local/central/Consumer-Adapter erfolgreich, je 3072 feste Contract-/Safety-APPLY-Oracles, 15 direkte Clientreader und 42 Lifecyclefälle. Alle Exit0, vollständige Kanäle, leeres Stderr. Zwölf frische read-only Kontrollverbindungen bestätigten tatsächliche Version/Plattform, unveränderte Input-/Sourcepins vor dem Evidenznachtrag, je zwei exakt restaurierte Marker-/Fremdslot-/Dependencyfixtures mit je zwei Abweisungen und alle 36 eigenen DBs abwesend. Keine Konfigurations-/Rechte-/Truständerungen. Functional mit erforderlicher Verschlüsselung und explizitem Lab-Trustwert; authentifizierte TLS-Abnahme separat. Aktueller Source einschließlich freigegebener SC-006-Härtung gebunden; deren separate Security.Contract.sql gehört nicht zum physischen full-Adapter. Keine neue Last-, Minimalrechte-, Heap-/Parallel-, Host-Recovery- oder Releasequalifikation; aktuelle Head-CI separat. Weiterhin teilweise validiert und unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

SC-006: Vor jedem OPENJSON wird die konkrete Inputbytezahl kumulativ gegen64 MiB geprüft. Bei Überschreitung: Status INVALID, ErrorCode WORK_LIMIT, kein Value. Bestehende Input-/Depth-/NULL-/Duplikatverträge bleiben.

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).

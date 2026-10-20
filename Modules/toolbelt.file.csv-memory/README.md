# CSV im Speicher

`toolbelt.file.csv-memory` 1.0.0 stellt genau zwei öffentliche USPs bereit:
[`USP_ParseCsv`](Documentation/USP_ParseCsv.md) liest Unicode-CSV als rechteckige
Zellen; [`USP_WriteCsv`](Documentation/USP_WriteCsv.md) schreibt einen typgenauen
caller-lokalen Zellsnapshot als CSV. Keine Datei-, Netzwerk-, Encoding- oder
Spreadsheet-Formelinterpretation.

Der [kanonische Vertrag](../../Documentation/Architecture/CSV_MEMORY_CONTRACT.md)
definiert Dialekt, NULL-Token, Header, Grenzen und Fehler. Der eigene SAFE-Kern
auf .NET Framework 4.8 benötigt ausschließlich System und System.Data. Ein
vollständiger Syntax-/Budgetpreflight und private Ergebnisse gehen jedem
öffentlichen Resultset beziehungsweise jeder ResultTable-Mutation voraus.

## Grenzen und Verwendung

Defaults sind 100000 DATA-Records, 1024 Spalten, 1000000 HEADER+DATA-Zellen und
16 MiB UTF16-Textbytes. Budgets dürfen nur abgesenkt werden. Das Textbudget ist
keine Heap- oder Produktionskapazitätszusage. Quoted CR/LF, NUL und ungepaarte
UTF16-Surrogate in Werten bleiben erhalten. Ungültige Quotes, Breiten oder
Ordinals werden abgewiesen. Ein optionales unquoted DATA-NullToken bezeichnet
SQL-NULL; quoted Token bleibt Text. Ohne Token weist der Writer SQL-NULL zurück.

Beide USPs erfüllen den Standardtail und `@Hilfe=1`. ResultTable-Routing nutzt
das vorhandene Modul `toolbelt.core.result-table >=1.0.0` in derselben Datenbank.
Lokale und zentrale Installation verwenden dieselben Quellen. Fremde
Callertransaktionen werden niemals vollständig committed oder zurückgerollt;
ein uncommittable Zustand nach einem technischen Fehler bleibt sichtbar.

## Build und Lifecycle

`Clr/Toolbelt.File.CsvMemory.csproj` baut die .NET48-Assembly.
`Scripts/New-ClrReleaseArtifacts.ps1` konsumiert anschließend deren exakte
SHA256-geprüfte Bytes und erzeugt Binary, Hashmanifest und SQLCMD-Deployment.
Das Binary wird nicht versioniert.
Exakten SHA2-512-Trust bei Bedarf mit `Deployment/Add-TrustedAssembly.sql`
separat autorisieren; `Deploy.sql` installiert keine Dependencies oder Rechte.
`clr strict security` bleibt aktiv. `TRUSTWORTHY ON` ist kein Installationsweg.
`DeploymentMode=local|central`; zentraler Uninstall verlangt die ausdrückliche
Bestätigung `ConfirmNoExternalConsumers=1`. Uninstall entfernt keinen Servertrust.

Interne Transporte: `TVF_InternalParseCsv` (fünf nullable CLR-Felder einschließlich
privatem ErrorCode), `SVF_InternalMeasureCsvCell` und `SVF_InternalQuoteCsvCell`.
Die beiden Skalare verwenden denselben Quotingkern. Messung der gesamten Ausgabe
erfolgt vor Fragmentallokation, Quoting erst nach erfolgreichem globalem Budget.

[Beispiele](Examples/Csv.sql), [Testmatrix](Tests/CSV_TEST_MATRIX.md) und
[Evidenz](Tests/README.md) trennen vorhandenen Testcode von ausgeführten Nachweisen.

## Quellen

Eigene Implementierung ohne Drittanbieter-Code. [RFC 4180](https://www.rfc-editor.org/info/rfc4180/)
ist Quotingreferenz; konfigurierbarer Separator, LF, UTF16 und NULL-Token bilden
den ausdrücklich dokumentierten Toolbelt-Dialekt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-20`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope binding-drift; Test-LifecycleGuardControls.ps1`
- Scope: Linux2019/latest CL150 und Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 jeweils local/central im ersten nativen Versuch PASS. Acht einzelne Änderungen an den drei internen CLR-Funktionen: zwei NULL-Aufrufoptionen, vier Textlängen, ein Parametername und ein Resultatspaltenname. Je Deploy/Uninstall SQL55324/state5/7: 16 Abweisungen pro Modus, 32 je Ziel; konkreter Katalogwitness, unveränderter erfasster Mutationszustand und neutrale Sitzung, exakte Baseline nach kanonischem ALTER unter unveränderter Objektidentität. Clean/Repeat, Uninstall/Repeat, Exit0, vollständige Kanäle, leeres Stderr; je frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration und Runtimeinputs unverändert. 235 synthetische Offlinekontrollen, PowerShell-AST und SQL150-Grammatik aller 32 expandierten ALTER-/Identitäts-/Witness-Batches PASS. Produkt-/Deployment-/CLR-Quellen und gemeinsame Snapshot-/Abweisungshelper unverändert; keine Rechte-/Owner-/Infrastrukturänderung oder Statusaufwertung. Kein neuer Default-/API-/Client-/Minimalrechte-/Heap-/authentifizierter TLS-/Release- oder vollständiger Binding-/Driftmatrixnachweis.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

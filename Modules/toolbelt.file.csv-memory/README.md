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
- Datum: `2026-10-21`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope select-unicode-null`
- Scope: Direkte öffentliche SELECT-Ausgaben ohne ResultTable über System.Data.SqlClient. Erste Familie:4194303 gültige UTF16-Surrogatpaare mit CRLF. Zweite Familie: unquotierter NullToken als SQL-NULL, quotierter identischer Token als literaler Text und großer BMP-Wert in drei Spalten. Vollständiger Input/Output genau16777216 Bytes, kleinstes Darüber16777218 Bytes. Client prüft vollständige ordinale Strings, DBNull getrennt vom literalen NULL-Text, Zeilen-/Spaltenreihenfolge, Feldnamen und SQL-/CLR-Typen; Writerwerte separat gesetzt und globale Wertcharge unter16MiB. Vier Übergrenzfälle je Modus ausschließlich SQL55303/state1 ohne vorherige Resultsetmetadaten oder Zeilen; vollständiger Quellerhalt. Keine Aussage über ungepaarte Surrogate oder andere Clients. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt. 1036 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur System.Data.SqlClient im bestehenden PowerShell-Labadapter und die expliziten synthetischen Fälle: keine SMO-/ODBC-/JDBC-/sonstige Clientmatrix, neue Default-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme oder unabhängig erfolgreiche MaxValueBytes-Vollgrenze. Status weiterhin partially validated, unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

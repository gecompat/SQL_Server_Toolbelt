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
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope binding-execution; binding-drift/defaults-Regressionen`
- Scope: Ausführung am2026-10-20/21: Linux2019/latest CL150 und Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 jeweils erster binding-execution-Versuch local/central PASS. Drei interne CLR-Funktionen einzeln mit EXECUTE AS OWNER als Fixturemetadatum; konkreter execute_as_principal_id=-2-Witness, je Deploy/Uninstall SQL55324/state5, sechs Abweisungen pro Modus und zwölf je Ziel. Witness unmittelbar vor/nach jeder Operation und vor Restaurierung, gleiche Objekt-/Erstellungsidentität, typisierte Ownership und CLR-Bindung, erfasster Zustand erhalten und Caller-Baseline exakt restauriert. Funktionen im geänderten Kontext nicht ausgeführt. Separate Regressionen bisheriger Metadatenfamilie Linux32 und Defaultfamilie Windows20 Abweisungen local/central PASS. Alle vier Läufe Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; frischer unabhängiger Audit je zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. 384Offlinekontrollen einschließlich Witnessdrift vor zweiter Operation,64SQL150-Batches aller drei Familien und AST/Static PASS. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen unverändert; keine Rechtevergabe oder Objektowneränderung, keine neue Default-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/authentifizierte TLS-/Releaseabnahme.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

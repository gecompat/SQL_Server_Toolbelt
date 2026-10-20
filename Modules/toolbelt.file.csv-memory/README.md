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
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope named-consumers; finaler Korrekturlauf`
- Scope: Finaler vierter nativer Lauf dieser Welle Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 im zweiten Versuch local/central PASS: fünf nacheinander angelegte Consumer mit explizitem eigenem SameDB-Namen, je Deploy/Uninstall SQL55325/state3,20 Abweisungen. Exakte Zielnamen/eigene DB, zulässige lokale ID- oder Namensbindung und Fingerprint sämtlicher erfasster Dependencyzeilen; Erhalt unmittelbar vor/nach jeder Abweisung und vor geschütztem Fixture-Drop, Gesamtsnapshot und Baseline erhalten. Typisierte OwnDB-/Fixturemarker und Objekt-/Erstellungsidentitäten geprüft. Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Vorheriger zweiter Linuxlauf und erster Windowslauf bestanden je20 Abweisungen ohne zusätzliche unmittelbare Vorabprüfung der zweiten Operation; enger datiert. Erster Linuxfehllauf bleibt FAILED und bereinigt. 301Offlinekontrollen einschließlich Dependencydrift ausschließlich vor der zweiten Operation,40SQL150-Batches,AST/Static und Docvalidator samt16Impactselftests PASS. Produkt-/Deployment-/CLR-/gemeinsame Helper unverändert. Kein isolierter NULL-ID-Preflightzweig, Consumer-APIausführung oder neuer Default-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/TLS-/Release-Nachweis.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

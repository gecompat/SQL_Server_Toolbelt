# XLSX Binary Memory Reader

Release 1.2.0 ergänzt [TVF_FormatXlsxCell](Documentation/TVF_FormatXlsxCell.md)
mit acht Inputs, zehn Literalformaten, drei expliziten Kulturen und zwei Outputs.
Raw- und Typquellen bleiben bytegleich. Exakte SqlDecimal-Rundung, 1900/1904,
Cache-Komposition und Temporalübertrag sind im
[Anzeigevertrag](../../Documentation/Architecture/XLSX_CELL_DISPLAY_CONTRACT.md) festgelegt.
Begrenzte aktuelle Offline- und lokale Nativequalifikation vom 2026-10-04 bestanden; zentrale1.2-Nutzung, vollständige Matrix, Minimalrechte und aktuelle Head-CI bleiben offen. Teilweise validiert,
unveröffentlicht. Die folgenden 1.0-/1.1-Nachweise sind historisch.

Am 2026-10-04 bestand ein privater Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils ausschließlich lokal: Clean1.2 und genuine installierte1.1→1.2 mit frischer Session, drei→vier CLR-Bindings und sieben→neun Slots am identischen aktuellen Binary. Je Ziel bestanden zwölf SQL-Fixtures, sechs Display-Clientprüfungen und zwei Raw→Type-/Raw→Type→Display-Kompositionen, Repeat sowie Uninstall/Repeat. Zwei eigene Datenbanken wurden entfernt und drei exakte Trust-Vorzustände wiederhergestellt; frische unabhängige Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte- oder Owneränderungen.

Dies ist ein begrenzter privater Adapternachweis, kein vollständiger öffentlicher Labadapter- oder Produkt-PASS. Zentrale1.2-Nutzung, genuine1.0→1.2, weitere CL/Ziele, vollständige Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und aktuelle exakte Head-CI bleiben offen. Status bleibt `partially validated`, `unreleased`.

Release1.1 ergänzt die einzeln freigegebene
[TVF_InterpretXlsxCell](Documentation/TVF_InterpretXlsxCell.md). Der vorhandene
Raw-Kern und seine fünf SQL-Sources bleiben bytegleich. Neuer Zellkern:
Offline-Frameworktests drei Kulturen /19311 Assertions bestanden; die
ausgewählte native 1.1-Qualifikation ist erfolgreich. Öffentlicher
Adapterport ist erfolgreich; aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft; siehe
[genauen Nachweisscope](Tests/README.md) und
[konkreten Vertrag](../../Documentation/Architecture/XLSX_CELL_TYPE_CONTRACT.md).

Historische 1.0-Evidenz: `local: Tests/Runtime/Invoke-LabContract.ps1`, 2026-10-02, Linux 2019/latest und Windows 2025/CU8; damaliger begrenzter synthetischer vollständiger Raw-Adapter erfolgreich, offene Matrixfälle bleiben offen. Keine Übertragung auf 1.1.

Release 1.0.0 stellt zwei ausdrücklich freigegebene öffentliche USPs bereit:

- `toolbelt_file.USP_ListXlsxWorksheets`: Worksheet-Reihenfolge, Name, Visibility und Date1904.
- `toolbelt_file.USP_ReadXlsxWorksheetCells`: vorhandene Zellen eines ausdrücklich gewählten Sheets, sortiert nach Zeile und Spalte; Rohwert, aufgelöster Stringtext, Formeltext und gespeicherter Cache bleiben getrennt.

Das Modul liest ausschließlich ein übergebenes `varbinary(max)`. Es führt weder Formeln noch Workbook-Inhalte aus und besitzt keinen Datei-, Netzwerk-, SDK- oder Workerprovider. Die kanonische ZIP-Assembly wird referenziert, nicht kopiert. Die technische iTVF-Ausnahme ist begründet: XML-/ZIP-Parsing und atomare Fehlerrückgabe sind CLR-Aufgaben; die USPs bilden Help, Routing und Mutationsscope ab, nicht einen angeblich schnelleren iTVF-Wrapper.

## Vertrag und Grenzen

NULL-Binary liefert ein leeres typisiertes Resultset oder lässt ein gesetztes ResultTable vollständig unverändert. Sheet-, Limit-, Dependency- und Zielprüfung werden dabei nicht durchgeführt. Help hat Vorrang. Nicht-NULL-Binary wird vollständig für das gewählte Ergebnis geprüft, bevor ein Ziel geändert oder eine Zeile ausgegeben wird.

Die Worksheetliste validiert Paketmetadaten und Relationships, nicht jeden ungelesenen Zellpart. Der Zellreader ist sparse: keine Rechteckauffüllung, Headererkennung, Shared-Formula-Rekonstruktion, Styles-/Culture-/Datums-/Anzeigeformat- oder Typinferenz. Fehlende und vorhandene leere Werte bleiben verschieden. Typ-/Anzeigeverarbeitung wurde separat freigegeben; sie ist ein nachfolgender eigenständiger Vertrag, kein stiller Umbau dieses Raw-Readers.

Nur Transitional SpreadsheetML mit kanonischen Partnamen und expliziten Content-Type-Overrides für Workbook/Worksheet/Shared Strings ist unterstützt. ZIP64, Multi-Disk, Verschlüsselung, externe Relationships, Makros/ActiveX/Connections, Strict Open XML und prozentkodierte Part-/Targetnamen werden abgelehnt; kein impliziter Fallback.

Zeilen und Zellen benötigen explizite gültige Koordinaten. Fehlende Koordinaten werden nicht inferiert. Die ausgewählten Inhaltsstrukturen werden geprüft; eine vollständige XSD-Konformitätsvalidierung des gesamten Workbooks wird nicht zugesagt.

## Reduzierbare Ressourcenparameter

| Parameter | Default und Ceiling |
|---|---:|
| MaxArchiveBytes / MaxPartBytes | jeweils 16 MiB |
| MaxTotalUncompressedBytes | 64 MiB |
| MaxParts / MaxSheets | 256 / 32 |
| MaxCells / MaxSharedStrings | 100000 / 50000 |
| MaxSharedStringBytes | 8 MiB dekodierter UTF-16-Text |
| MaxXmlDepth / MaxCompressionRatio | 64 / 200 |
| BudgetMilliseconds | 5000 ms |

Alle Limits sind strikt positiv, NULL ist bei nicht-NULL-Binary ungültig, höhere Werte sind ausgeschlossen. Das interne zusätzliche 128-MiB-Chargebudget zählt konservative implementierte Allokationsanteile und ist keine Messung des gesamten Peaks. Jedes ausgewählte String-Ausgabefeld wird vor der SQL-Ausgabe zusätzlich mit vier Bytes je UTF-16-Codeeinheit belastet: StoredType, RawValue, TextValue, FormulaText, FormulaKind und CacheValue beziehungsweise SheetName und Visibility. Wiederholte Shared-Stringreferenzen und identischer Raw-/Cachetext zählen je Ausgabe erneut. Damit kann auch ein Workbook innerhalb der Einzelcaps wegen kumulativer Outputexpansion mit `TBX_XLSX_COUNTED_ALLOCATION_LIMIT` atomar scheitern. Die Grenze darf nicht erhöht werden; kein unabhängiger öffentlicher Allocation-Parameter entsteht.

Inputmaterialisierung, ZIP-Payload-/ToArray-Kopien, XML-/String-/Resultlisten, TVF-Marshalling, T-SQL-Snapshot und Tempdb können gleichzeitig RAM beanspruchen. Kein Streaming, copy-free oder SQL-Memory-Grant wird zugesagt.

Das Zeitbudget ist kooperativ über ZIP-Index, Dekompression, CRC, XML und eigene Ergebnisaufbereitung. Einzelne Frameworkoperationen sowie SQL-Marshalling/-Materialisierung sind nicht unterbrechbar; für diese wird keine 5-Sekunden- oder harte Wallclock-Garantie behauptet. Der Testharness und dessen 15-Sekunden-Watchdog sind keine Runtime-API.

## Installation und Lifecycle

Deploy und Uninstall benötigen einen eigenen Transaktionsscope. Ein vorhandener Caller-Scope wird vor jeder SET- oder DDL-Anweisung mit RAISERROR 50000 und dem Präfix `TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:` abgelehnt. Der Guard verändert weder Caller-Arbeit noch XACT_ABORT und lässt die Transaktion auch bei XACT_ABORT ON committable. SQLCMD beendet den Lauf über `:On Error exit` mit einem Fehlerstatus.

Dependencies sind die kompatible Major-1-Linie von `toolbelt.archive.zip-memory` ab 1.4.0 und `toolbelt.core.result-table` ab 1.0.0, in derselben Installationsdatenbank. Eine zukünftige Majorversion wird nicht automatisch als kompatibel akzeptiert. Die XLSX-Assembly referenziert die kanonische ZIP-Assembly; ZIP kann bei vorhandenem XLSX-Consumer nicht deinstalliert werden.

Build: `Scripts/New-ClrReleaseArtifacts.ps1` mit vorhandener Framework-4.8-Toolchain. Exakter SHA2-512-Trust ist separates administratives Opt-in; Deployment verändert keine Instanzoption, Rechte, strict security oder TRUSTWORTHY. SQLCMD-Deployment verwendet DeploymentMode local/central. Zentraler Uninstall benötigt ConfirmNoExternalConsumers=1. Eigene Objekt-/Releasezuordnung wird geprüft; fremde Consumer blockieren. Trust und Dependencies bleiben erhalten. Nach konkreter Benutzerfreigabe vom 2026-10-02 verlangen beide Lifecycle-Skripte vorhandenes Datenbank-VIEW DEFINITION und SELECT auf sys.sql_expression_dependencies vor Mutation und erneut unter AppLock; 0/NULL/unklar blockiert 51535/State 2.

## ResultTable und Fehler

Die letzten Parameter sind ResultTable, KeepData, Debug, Hilfe nach USP-Vertrag. KeepData=0 ersetzt, 1 hängt an; NULL-Standardparameter werden normalisiert. Reservierte `#tbx_`-Zielnamen und bereits vorhandene private XLSX-Temptabellen werden vor der separaten Compilergrenze abgefangen. Aufrufer dürfen interne USPs/TVFs nicht als zusätzliche öffentliche APIs behandeln.

Erwartete Input-/XML-/Container-/Feature-/Ressourcenfehler liefern intern eine Statuszeile und öffentlich THROW 51520 mit begrenzter Kategorie ohne Workbookinhalt. Provider-/Dependencyinkonsistenz ist 51529. Unerwartete CLR-/Enginefehler bleiben Originalfehler; keine SQL6522-Textparser. Mutationen beginnen erst nach Parserpreflight; eigene Transaktion oder Caller-Savepoint, niemals vollständiger Callerrollback. Ein doomed Caller benötigt Callerrollback.

## Nachweise

Der aktuelle qualifizierte Scope steht in [Tests/README.md](Tests/README.md) und [Testmatrix](Tests/XLSX_CONTRACT_TEST_MATRIX.md). NoIO-Evidenz besteht aus adversarialem begrenztem Framework-Sandboxlauf, positiver IL/API-Allowlist und tatsächlichem SAFE-Hostlauf, nicht aus einer behaupteten vollständigen OS-Syscall-Beobachtung. Produktionsworkbooks, vollständige Peakmessung und nicht ausgeführte Matrixfälle bleiben offen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-xlsx-types-lab.ps1 -QualificationScope DisplayCentralLifecycle`
- Scope: Linux2019/latest zentral CL150: vier postDROP/preCOMMIT-Rollbackfälle und zwei AppLock-Abweisungen; separate positive aktuelle1.2-Installation, neun Slots/vier CLR-Bindings/SAFE-Binaryhash/Modus/CL und vollständiger vorhandener Lifecycle-Snapshot vor/nach, neutraler Sitzungszustand zwischen Statements, bestätigter Uninstall. Eigener äußerer Prozesswatchdog, Exit0 und vollständige private Kanäle; frischer unabhängiger Audit bestätigt eine OwnDB/zwei OwnTrust-Hashes abwesend, keine Konfigurations-/Rechteänderungen. Früherer gemischter Setup-Prüflauf bleibt FAILED_CLEANED; gezielter Read-only-Probe begründet getrennte Transaktionsprüfung. API/Consumer/Upgrade nicht wiederholt; weitere Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und Ziele offen; partially validated/unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

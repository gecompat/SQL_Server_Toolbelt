# Contract-Testmatrix: ZIP Memory CLR Inspection

## Aktueller portabler Build

Die Abnahme umfasst den markerfreien Create-only-Installer mit
`tlblt_Archive_ZipMemory` als `SAFE` und exakter SHA2-512-Bindung.
Je Engine gelten SQL Server 2019 mit CL150, 2022 mit CL150/160 und 2025 mit
CL150/160/170. Geprüft werden lokale Installation und direkte zentrale
Aufrufe aus einer getrennten Caller-Datenbank.

| Prüfung | Windows-Lab | Linux-CI |
|---|---|---|
| Writer, Listing, Extraktion in ResultTables, exakte Groß-/Kleinschreibung und Ergebniserhalt bei Ablehnung | 48 Assertions in zwölf Kontexten auf SQL 2019/CU32, 2022/CU26, 2025/CU8; drei frische Audits bestanden | Dieselben 48 Assertions auf SQL 2019/2022/2025 in separaten, anschließend entfernten CI-Containern |
| Reader bei 128 MiB komprimiert und 64 MiB entpackt, jeweils an der Grenze und ein Byte darüber | SQL 2025/CU8 CL170, acht Assertions lokal/zentral | SQL 2019 CL150, acht Assertions lokal/zentral |
| Stored-Writer bei 32 MiB pro Entry, 128 MiB Gesamtpayload, 1.024 Entries und 2.048 UTF-16-Codeeinheiten im Namen, jeweils mit isolierter Überschreitung | SQL 2025/CU8 CL170, zwölf Assertions lokal/zentral; frischer gemeinsamer Grenzfall-Audit bestanden | SQL 2019 CL150, zwölf Assertions lokal/zentral |

Linux-Nachweis und Wiederholungsprüfung laufen im
[ZIP-Memory-Workflow](../../../.github/workflows/zip-memory-runtime.yml).
Die Linux-Labverbindungen waren für diese Welle nicht verfügbar. Die
SQL-Grenzproben verwenden synthetische Daten am unveränderten Produktlimit.
Die Reader-Fixtures werden unabhängig dekodiert und ihr erwarteter Payload-Hash
wird im SQL-Aufruf abgeglichen. Der Writer prüft Größe, Struktur und Inhalt
direkt an den ZIP-Bytes, da die öffentliche Reader-Namensgrenze bei
1.024 UTF-16-Codeeinheiten liegt.

Die unveränderten Archivgrößen- und Entryanzahlgrenzen sowie die öffentlichen
Objektrechte verwenden die unten verlinkten vorhandenen Nachweise. Die
native Wiederholungsprüfung des Readers betrifft den geänderten
Dekompressionspfad. Historische Upgrade- und Uninstallfälle gehören zum
damaligen Installer. Die synthetischen Tests begründen keine allgemeine
Produktionskapazität oder Zusage für unbekannte ZIP-Formate.

## Historischer Nachweisabgleich vom 6. November 2026

Die spätere [Entryanzahl-Qualifikation](../../../Releases/1.0.0/ZIP-ENTRY-COUNT-QUALIFICATION.md)
belegt Listing mit10000 Einträgen, die Abweisung von10001 sowie des zu großen
MaxEntries-Parameters auf zwölf Ziel-/CL-Paaren lokal/direkt zentral. Die
ursprüngliche offene Entry-Count-Zeile ist in der Tabelle durch diesen Nachweis
ersetzt.
Dies belegt für sich weder Archiv256MiB noch komprimierten Extraktionsinput128MiB.
Die spätere [native Archivbyte-Prüfung](../../../Releases/1.0.0/ZIP-ARCHIVE-BYTE-QUALIFICATION.md)
schließt separat exakt256MiB und ein Byte darüber für öffentliche Listing- und
Extraktionsaufrufe auf Windows2025/CU8 CL170 und Linux2019/latest CL150 jeweils
lokal/direkt zentral: acht positive und acht strikte Fehlerproben, beide
Gesamtläufe und frischen Abschlussaudits bestanden. Die große Füllpayload ist
nicht zur Extraktion ausgewählt; komprimierte Entry- und Ausgabegrenzen sowie
weitere Ziel-/CL-Kombinationen bleiben davon unberührt. Historische Tabellen
werden nicht nachträglich als neue Ausführungen umetikettiert.
Die getrennte [native Entry-Byteprüfung](../../../Releases/1.0.0/ZIP-ENTRY-BYTE-QUALIFICATION.md)
belegt auf denselben zwei Ziel-/CL-Paaren lokal/direkt zentral die tatsächlichen
128-MiB-Komprimat- und64-MiB-Ausgabegrenzen sowie jeweils ein Byte darüber:
acht positive/acht strikte Fehlerproben, zwei Gesamtläufe/zwei frische Audits.
Gültige DEFLATE-/Stored-Inputs und der öffentliche ResultTable-Weg isolieren
die Grenzen; keine Quotenänderung oder Wiederholung der grünen Archiv-/Entryanzahl-
Proben. Weitere Zielkontexte und vollständige Modulabnahme bleiben separat.
Die [Caller-Metadatenpflege](../../../Releases/1.0.0/ZIP-METADATA-UPDATE.md)
bindet außerdem die bereits berichteten Rechteprofile an deren Paketstand;
sie ist keine neue native Ausführung oder vollständige Modulqualifikation.

Der ergänzende Callerrechte-Nachweis umfasst ausschließlich die drei
bestehenden öffentlichen Listing-, Extraktions- und Writer-USPs mit festen
synthetischen ZIPs: [ZIP-Callerprofil](../../../Releases/1.0.0/ZIP-CALLER-PROFILE.md).
Er verändert keine historische Matrix und erweitert keine Produkt- oder
Plattformzusage.

Release 1.4, 2026-10-02: `local: Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Invoke-LabContract.ps1` auf Linux 2019/latest und Windows 2025/CU8 erfolgreich; echte ZIP-1.3-Assemblyhash-Upgradefixture, bestehender Writer-SQL-Vertrag, SAFE local/central und nichtdoomende Lifecycle-Callerablehnung OFF/ON. Kein Ersatznachweis für offene Kapazitäts-/Plattformfälle.

## Writer 1.3.0: Zusatzscope

| Scope | Oracle | Stand |
|---|---|---|
| Stored, Deflate, leere Payloads, Unicode, nachgestellte Leerzeichen, CRC und Header | unabhängiger Framework-ZipArchive plus bitweiser CRC | lokal PASS |
| 32 MiB je Entry, 128 MiB Gesamtpayload, 1024 Entries und 2048 Name-Codeeinheiten | tatsächlich erzeugte und gelesene synthetische ZIPs | lokal PASS |
| Konfiguration: 136 MiB Envelope und 144 MiB Output | unabhängige Budgetcaps, maximaler gültiger Input kleiner | keine exakte Auslastungszusage |
| Vier parallele synthetische Aufrufe | Framework | lokal PASS, keine Serverkapazitätszusage |
| Input, Limits, Help, Append, Transaktionen, Ratio, 16-MiB-Payloads sowie local/central | Writer.Contract.sql | SQL 2019 Linux / 150 und SQL 2025 Windows / 150, 160, 170: PASS |
| Tatsächliche SQLClient-Metadaten und keine zusätzliche SELECT-Ausgabe | Writer.Metadata.ps1 | dieselben lokalen und zentralen Lab-Scopes: PASS |
| Echtes 1.2.0-Binaryupgrade, drei neue Namenskollisionen, historischer Erhalt und Uninstall | Adapter plus Hash-Oracle | dieselben Lab-Scopes: PASS |

Datierte Endstand-Evidence: 2026-10-01. Die vorhandenen encrypted-NULL-Regressionen und unveränderten Readergrenzen bestanden ebenfalls. SQL-Live-Ceilings oberhalb der 16-MiB-Standardpayload, Produktionsarchive und globale Kapazitäts-/Parallelitätszusagen bleiben ausdrücklich offen; `partially validated` bleibt erhalten. Keine privaten Host-, Build-, Ressourcen- oder Runtime-Logs werden gespeichert.

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; reale Archive, echte Extremgrößen, historische Upgrades und Interoperabilität bleiben offen. Der Modulstatus bleibt `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Pflichtfall | Status |
|---|---|---|
| Build | .NET Framework 4.8; reproduzierbare Release-Artefakte | `success` |
| Dependencies | direkte Assemblyreferenzen nur `System` und `System.Data` | `success` |
| Trust | exakter SHA2-512-Hash; getrenntes administratives Opt-in | `success` |
| Security | `SAFE`; kein Dateisystem, Netzwerk, Prozess, `TRUSTWORTHY`, `EXTERNAL_ACCESS` oder `UNSAFE` | `success` |
| API | öffentliche Procedure behält Parameter, Reihenfolge und Resultset | `success` |
| Listing API | Metadaten-Procedure behält Parameter, Reihenfolge und Resultset | `success` |
| Intern | CLR-Tabellefunktion und Assembly bleiben interne Providerartefakte | `success` |
| Help | vollständiger Help-Vertrag bei `@Hilfe = 1` | `success` |
| Stored | gültiger Method-0-Entry wird extrahiert und CRC-geprüft | `success` |
| Deflate | gültiger Method-8-Entry wird dekomprimiert und CRC-geprüft | `success` |
| Data Descriptor | Method 8 mit Flag 3 und nachgelagertem Descriptor | `success` |
| UTF-8 | Flag 11 dekodiert UTF-8-Namen korrekt | `success` |
| CP437 | Name ohne Flag 11 verwendet CP437 | `success` |
| Namensvergleich | ordinal, case-sensitive, unbekannter Name liefert `51322` | `success` |
| Duplicate Name | doppelter exakter Name liefert `51323` | `success` |
| Verschlüsselt | `@FailIfEncrypted = 1` liefert `51324` | `success` |
| Encrypted Status | `@FailIfEncrypted = 0` liefert `IsEncrypted = 1` ohne Payload | `success` |
| Archivlimit | hartes Limit `268435456` Bytes | [native Grenzprüfung](../../../Releases/1.0.0/ZIP-ARCHIVE-BYTE-QUALIFICATION.md) |
| Entry-Count | hartes Limit `10000` Entries | [native Grenzprüfung](../../../Releases/1.0.0/ZIP-ENTRY-COUNT-QUALIFICATION.md) |
| Compressed Limit | hartes Limit `134217728` Bytes | [Reader-Grenzprüfung im aktuellen Build](#aktueller-portabler-build) |
| Output-Limit | `@MaxEntryBytes` vor und während Dekomprimierung | `success` |
| Ratio-Limit | deklarierte und tatsächliche Compression Ratio | `success` |
| Method | unbekannte Method und Deflate64 liefern `51327` | `success` |
| ZIP64 | Sentinel oder ZIP64-Strukturen liefern `51327` | `success` |
| Multi-Disk | Diskfelder außerhalb Single-Disk liefern `51327` | `success` |
| Header | Local-/Central-Name, Method und relevante Flags müssen übereinstimmen | `success` |
| Größenintegrität | tatsächliche Ausgabe entspricht deklarierter Größe | `success` |
| CRC | CRC32 wird über den tatsächlichen Payload neu berechnet | `success` |
| Leeres ZIP | gültiges leeres ZIP liefert leeres Resultset und Returncode 0 | `success` |
| Listing | Central-Directory-Reihenfolge und deklarierte Metadaten | `success` |
| Listing Status | unbekannte Methode und Verschlüsselung werden markiert, nicht abgelehnt | `success` |
| Listing Names | ordinal/case-sensitive DuplicateCount; UTF-8 und CP437 | `success` |
| Listing Paths | Directory, safe, absolute, drive-qualified, traversal und noncanonical | `success` |
| Listing Time | gültige DOS-Zeit; ungültiger Wert wird NULL | `success` |
| Bounded Read | Deflate darf keine Bytes außerhalb des Entry-Payloads konsumieren | `success` |
| ResultTable | Replace und Append über `@ResultTable`/`@KeepData` | `success` |
| Wiederholung | Deployment derselben Assembly ist idempotent | `success` |
| Upgrade | Upgrade von bekanntem Modulstand `1.1.0` auf `1.2.0` | `partially validated` |
| Central | Aufruf aus Consumer-Datenbank gegen zentrale Toolbelt-Datenbank | `success` |
| Uninstall | Procedure, CLR-TVF und Assembly entfernt; Trust bleibt bestehen | `success` |
| SQL 2019 Linux | physische Engine, Compatibility 150 | `success` |
| SQL 2022 Linux | physische Engine, Compatibility 160 | `success` |
| SQL 2025 Linux | Compatibility 150, 160 und 170 | `success` |
| Windows Build | .NET-Framework-Build und Release-Manifest | `success` |
| Windows Runtime | SQL Server unter Windows | [aktuelle Windows-Matrix](#aktueller-portabler-build) |

`not executed` wird erst durch reproduzierbare CI- oder gezielte Release-Evidenz
ersetzt. `partially validated` beim Upgrade bezeichnet den erfolgreichen
synthetischen Versionsmarker-Pfad ohne vollständiges vorheriges 1.1.0-Deployment.
Der Versionsmarker-Pfad bleibt historische Evidenz. Der aktuelle
Create-only-Installer unterstützt keinen Upgrade- oder Uninstallpfad.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-22`
- Nachweis: `.github/workflows/zip-memory-runtime.yml; ZIP_MEMORY_CONTRACT_TEST_MATRIX.md#aktueller-portabler-build`
- Scope: Markerfreier Portable-Installer und SAFE-Assembly auf Windows-Lab und Linux-CI, 2019 CL150, 2022 CL150/160, 2025 CL150/160/170, je lokal und direkt zentral. Native Reader- und Writer-Grenzfälle auf Windows 2025/CU8 CL170 und Linux 2019 CL150, je lokal und zentral. Windows-Abschlussaudits und Linux-Container-Cleanup; historischer Lifecycle bleibt separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

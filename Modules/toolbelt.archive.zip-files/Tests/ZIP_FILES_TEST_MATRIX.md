# ZIP-Dateifassaden – Testmatrix

## Vollständige Archivextraktion V1

[PR #635](https://github.com/gecompat/SQL_Server_Toolbelt/pull/635) dokumentiert
den am 2026-11-21 integrierten Stand für
`toolbelt_archive.USP_ExtractZipArchiveToDirectory`. Die SQL-Abnahme mit
[`ZipFiles.Directory.sql`](Runtime/ZipFiles.Directory.sql) auf Windows SQL Server
2025/CU8, CL170, lokal unter Windows-Anmeldung bestand fünf Prüfungen zu
Dateiinhalt, Verzeichnisanlage und Ergebnisweitergabe, Preflight-Teilstatus,
Transaktionsablehnung und verweigertem Überschreiben ohne Root-Freigabe.
Der frische Cleanup-Audit für eigene Datenbank, Verzeichnis und Trust bestand.

Der lokale NTFS-Frameworklauf belegt erfolgreiches exklusives Überschreiben,
konkurrierende Zielanlage, CRC-bedingten Abbruch, die Ablehnung einer zu
breiten DACL und die gemeinsame Rootsperre. Hinzu kommen 14 Reader-Fälle,
16 Pfad- und Ablaufgegenproben, vier offline geprüfte Installerprofile und
der unabhängige Sicherheitsreview. Die [Main-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/44950763237)
bezieht sich auf Merge `19cebb79`.

Der separate native Lauf vom 2026-11-21 prüfte mit
[`ZipFiles.ExclusiveOverwrite.sql`](Runtime/ZipFiles.ExclusiveOverwrite.sql)
das positive SQL-Überschreiben auf Windows SQL Server 2025/CU8, CL170, lokal
mit NTLM. Ein eigener NTFS-Root mit geschützter DACL für den Windows-Aufrufer
war über `AllowZipOverwrite = 1` freigegeben. Fünf Prüfungen bestätigten
Windows-Anmeldung, beide ResultTable-Zeilen und den jeweiligen Byte-Readback.
Der Aufruf mit `@OverwriteExistingFiles = 1` ersetzte die drei Ausgangsbytes
durch zwei neue Bytes. Der frische Gast-/SQL-Audit bestätigte die Entfernung
von Testverzeichnis und Testdatenbank sowie den Trust-Vorzustand. Der
Installationssatz und die Produktbinaries aus PR #635 wurden verwendet.
Dieser Lauf belegt den Caller-Modus auf dem ausgewählten SQL-Ziel.

Der ergänzende ServiceAccount-Lauf am 2026-11-21 nutzte
[`ZipFiles.ExclusiveOverwrite.ServiceAccount.sql`](Runtime/ZipFiles.ExclusiveOverwrite.ServiceAccount.sql)
mit demselben Installationssatz auf Windows SQL Server 2025/CU8, CL170, lokal.
Der autorisierte Benutzer ohne Login in der eigenen Testdatenbank rief die
öffentliche Prozedur mit `@ExecutionIdentity = N'ServiceAccount'` auf. Der
eigene Root hatte `AllowServiceAccount = 1`, `AllowZipOverwrite = 1` und eine
geschützte DACL für die gebundene SQL-Dienstidentität und Administratoren.
Die fünf SQL-Prüfungen bestanden. Sie bestätigen die Rollenprüfung, beide
ResultTable-Zeilen und den jeweiligen Byte-Readback von drei Ausgangsbytes und
zwei Ersatzbytes. Der Windows-SQL-Ausführungsbeleg bindet die geprüfte Fixture.

Ein zusätzlicher Gast-Metadatencheck scheiterte nach der SQL-Prüfung. Der
Gesamtkoordinator bleibt `FAILED_CLEANED`. Der separate frische Gast-/SQL-Audit
bestand für die Abwesenheit von Testverzeichnis und Testdatenbank und für den
wiederhergestellten Trust-Vorzustand.

Die ursprüngliche Gastprüfung verlangte versehentlich zwei Treffer für
`replace.bin`. Die korrigierte
[Gast-Metadatenfixture](Runtime/ZipFiles.ServiceAccount.GuestMetadata.ps1)
prüft genau eine reguläre, zwei Byte lange Ersatzdatei, genau eine
Besitzmarkierung und weiterhin zwei ACEs in der geschützten DACL. Der separate
native Gastlauf auf demselben ausgewählten Windows-Ziel bestand. Er prüfte
auch die Ablehnung einer fehlenden Ersatzdatei, einer falschen Dateilänge
und einer abweichenden DACL. Der eigene synthetische NTFS-Root verwendete die
Gast-Testidentität und die Administratorengruppe. Ein neuer unabhängiger
Gast-Audit bestätigte die Abwesenheit des Roots.

Der Gesamtnachweis für exklusives Überschreiben im ServiceAccount-Modus auf
Windows SQL Server 2025/CU8, CL170, lokal ist damit durch die fünf bestehenden
SQL-Prüfungen mit der gebundenen SQL-Dienstidentität, den korrigierten separaten
Gastcheck und beide Abschlussaudits abgedeckt. Der SQL-Fall wurde wiederverwendet.

Der zusätzliche native Teilabbruchfall vom 2026-11-21 mit
[`ZipFiles.Directory.Partial.sql`](Runtime/ZipFiles.Directory.Partial.sql)
lief lokal mit Windows-Anmeldung auf SQL Server 2025/CU8, CL170.
Der [Fixture-Generator](Runtime/Build-ZipDirectoryPartialFixture.py) erzeugt
drei lesbare Einträge im ZIP-Verzeichnis und eine Prüfsummenabweichung im zweiten
Dateiinhalt. Vier SQL-Prüfungen bestätigten die ResultTable-Zeilen
`completed`, `failed` mit `CRC_MISMATCH` und `not_attempted` in
Archivreihenfolge sowie den Byte-Readback der ersten Datei. Der separate
Gastcheck bestätigte, dass außer der Besitzmarkierung nur diese Datei im
Testroot verblieb. Der frische Abschlussaudit bestätigte die Abwesenheit
von Testroot und Testdatenbank sowie den ursprünglichen Trustzustand.
Die Produktbinaries und der Installationssatz aus der V1-Abnahme wurden
wiederverwendet.

Der ergänzende
[`ServiceAccount`-Teilabbruchfall](Runtime/ZipFiles.Directory.Partial.ServiceAccount.sql)
verwendete dasselbe ZIP auf Windows SQL Server 2025/CU8, CL170, lokal.
Die fünf nativen SQL-Prüfungen bestätigten die Rollenmitgliedschaft des
temporären Datenbankbenutzers, alle drei ResultTable-Status einschließlich
`CRC_MISMATCH` und den vollständigen Readback des ersten Eintrags im
`ServiceAccount`-Modus. Der Gastcheck bestätigte die geschützte DACL für
die tatsächlich gebundene SQL-Dienstidentität und die Administratorengruppe
sowie genau eine extrahierte Datei mit drei Bytes. Der frische Audit
bestätigte, dass Testdatenbank samt Testbenutzer und Rechten und der eigene
Testroot entfernt waren und der Trust-Vorzustand wiederhergestellt war.

Der native [Ressourcenlimit-Fall](Runtime/ZipFiles.Directory.ResourceLimits.sql)
auf Windows SQL Server 2025/CU8, CL170, lokal im Caller-Modus prüfte ein
[synthetisches ZIP mit zwei gespeicherten Dateien](Runtime/Build-ZipDirectoryLimitsFixture.py).
Fünf Aufrufe knapp unter dem jeweils benötigten Budget bestätigten die
Ablehnung für Archivgröße, Eintragszahl, Einzeldateigröße, Gesamtgröße und
Pfadlänge. Die ersten beiden Fälle lieferten SQL-Fehler, die übrigen
`failed` und `not_attempted` mit den erwarteten Fehlercodes und ohne
geschriebene Bytes. Der sechste Aufruf setzte alle Budgets genau auf den
Bedarf und extrahierte beide Dateien in denselben Root bei deaktiviertem
Überschreiben. Der Gastcheck bestätigte die beiden exakten Dateiinhalte.
Der frische Audit bestätigte die Abwesenheit von Testdatenbank und Testroot
sowie den Trust-Vorzustand. Die Prüfung verwendet kleine Nutzdaten und
belegt die caller-seitigen Grenzen am Fixturebedarf.

Der native [Maximalwerte-Fall](Runtime/ZipFiles.Directory.TechnicalCeilings.sql)
verwendete dasselbe ZIP auf Windows SQL Server 2025/CU8, CL170, lokal im
Caller-Modus. Die öffentliche API akzeptierte die sechs Maximalwerte in
einem Aufruf und extrahierte beide Dateien. Die Gegenproben überschritten
jeweils genau einen Maximalwert:

| Aufrufparameter | Akzeptierter Maximalwert | Abgelehnter Wert |
|---|---:|---:|
| `@MaxArchiveBytes` | 268435456 | 268435457 |
| `@MaxEntries` | 10000 | 10001 |
| `@MaxEntryBytes` | 67108864 | 67108865 |
| `@MaxPathLength` | 1024 | 1025 |
| `@MaxTotalExpandedBytes` (`bigint`) | 9223372036854775807 | 9223372036854775808 |
| `@MaxCompressionRatio` (`decimal(9,2)`) | 9999999.99 | 10000000.00 |

Die vier CLR-Fehler nannten Parameter und Maximum. Die letzten beiden
Werte scheiterten bereits bei der SQL-Typkonvertierung. Die Ablehnungen
lieferten keine Ergebniszeilen. Danach waren beide Ziele bei deaktiviertem
Überschreiben publizierbar, und der Gastcheck bestätigte ihre exakten Bytes.
Der frische Audit bestätigte die Abwesenheit von Testdatenbank und Testroot
sowie den Trust-Vorzustand. Das sind Prüfungen der Parametergrenzen mit
kleinen Nutzdaten. Physische Maximallast war kein Bestandteil des Falls.
Der erste Lauf bleibt wegen des zu engen Testorakels für SQL-Fehler 8114
`FAILED_CLEANED`; sein separater Abschlussaudit bestand.

### Physische Grenzfälle

Der [native Lasttest](Runtime/ZipFiles.Directory.PhysicalCeilings.sql)
auf Windows SQL Server 2025/CU8, CL170, lokal im Caller-Modus prüfte echte
ZIP-Daten am Maximum und jeweils eine Einheit darüber:

| Dimension | Vollständig extrahiert | Abgelehnt |
|---|---:|---:|
| Archivgröße | 268.435.456 Bytes | 268.435.457 Bytes mit `ZIP_ARCHIVE_LIMIT` |
| Expandierte Größe je Eintrag | 67.108.864 Bytes | 67.108.865 Bytes mit `ENTRY_SIZE_LIMIT` |
| Dateien je Archiv | 10.000 | 10.001 mit `ZIP_ENTRY_COUNT_LIMIT` |
| Pfadlänge des Eintrags | 1.024 UTF-16-Einheiten | 1.025 mit `ENTRY_NAME_LIMIT` |
| Komprimierte Größe je Eintrag | 134.217.728 Bytes | 134.217.729 Bytes mit `ENTRY_SIZE_LIMIT` |

Der Gastcheck bestätigte 10.005 publizierte Dateien und ihre Sollgrößen,
einschließlich des langen Pfads. Der
[Fixture-Generator](Runtime/Build-ZipDirectoryPhysicalFixtures.py) erzeugt
kleine Eingaben für den Lab-Transport. SQL Server setzt daraus die
vollständigen großen Archive zusammen.

Die interne Grenze für komprimierte Nutzdaten wurde mit einer separaten
[DEFLATE-Fixture](Runtime/ZipFiles.Directory.CompressedCeiling.sql) auf
demselben Ziel geprüft. Der Gastcheck bestätigte das eine erwartete
Ausgabebyte. Beide frischen Audits bestätigten die Entfernung der jeweiligen
Testdatenbank und des Testroots sowie den ursprünglichen Trustzustand.

Die SQL-Typmaxima für Gesamtgröße und Ratio sind durch gültige
V1-Nutzdaten nicht erreichbar. 10.000 Einträge zu je höchstens 64 MiB
begrenzen die Gesamtexpansion bereits auf höchstens 625 GiB. Stored expandiert
mit Faktor 1. DEFLATE kann pro codierter Rückreferenz höchstens 258 Bytes
ausgeben und benötigt dafür Eingabebits, sodass der SQL-Maximalfaktor
9.999.999,99 außer Reichweite liegt. Für diese beiden Werte gilt der
Parametergrenznachweis oben. [DEFLATE-Spezifikation](https://www.rfc-editor.org/rfc/rfc1951#section-3.2.5)

## Historische Abnahme der Einzel-Entry- und Writer-Fassaden

Sourceprüfungen sind keine SQL-/Windows-/NTFS-Evidenz. Die nativen Teilnachweise
vom 2026-10-04 gelten ausschließlich für Windows SQL Server 2025/CU8, CL170,
local: elf frühere erfolgreiche Fälle und zwei später gezielt erfolgreiche
AppLock-Aliasfälle mit identischen Produktbytes. Kein gemeinsamer 13-Fälle-
Erfolgslauf; keine breitere Provider- oder vollständige Modulqualifikation.

| Scope | Konkretes Orakel / Fixture | Status |
|---|---|---|
| Statisch | zwei Signaturen/Defaults, fünf-/sieben-/vierfeldrige Stages, statische EXECs, Help-/TX-/Publish-Reihenfolge, Brückenschutz, eigener später SQL-TX, zwei Lifecycle-P-Slots | Sourceprüfung separat |
| Help | Help.Contract.sql: beide 12-Feld-Helps, 17/12 Parameter, vier Results; Help vor TX/Dependencies/ResultTable, ignoriert Debug | begrenzter nativer Teilnachweis erfolgreich |
| Metadaten | InstalledMetadata.Contract.sql: exakte P-Slots/29 Parameter/3 statische Providerconsumer; echte Reader-Typen/EOF separat im Nativeplan | begrenzter nativer Teilnachweis erfolgreich |
| API | ZipFiles.Contract.sql: Create, Extract, Readback, KeepData Append/Replace, empty Entry/Archive | begrenzter nativer Teilnachweis erfolgreich |
| Sicherheitspriorität | ZipFiles.Safety.sql: Caller-TX, schemafremde eigene Brückenkollision erhalten, Input-/Output-Identität abgewiesen, geerbtes NULL-Writerlimit vor Publish | begrenzter nativer Teilnachweis erfolgreich |
| Später SQL-Fehler | ZipFiles.Atomicity.sql: Error547, vorherige SQL-Zeile erhalten, veröffentlichte Datei vorhanden | begrenzter nativer Teilnachweis erfolgreich |
| Output | beide direkte SELECT-/ResultTable-Wege und alle vier KeepData-Schema/Data-Kombinationen; EOF/noNext | Contract-Teilnachweise vorhanden; vollständige Ausgabe-/KeepData-Matrix offen |
| ZIP-Negative | encrypted51324, CRC51327, Name/Duplicate/ratio/resource/budget; vorhandenes Target bytegleich, keine neue Datei | not executed |
| Caller-TX | active/doomed vor Arbeit; Help weiterhin rein; keine Caller-Rollbackübernahme | aktive TX-Abweisung in Safety erfolgreich; doomedTX weiter offen |
| NTFS/Identität | Windows-Callerpositive, SQLauthnegative, explizit ServiceAccount; Root/deny/reparse/fehlendesDir | Windows-Caller/SQLauth-Ablehnung erfolgreich; übrige NTFS-/ServiceAccount-Fälle offen |
| Publish | NoOverwrite/Overwrite, Stagecleanup, echte Konkurrenz; bestehendes Target bleibt bei Fehler erhalten | not executed |
| Lifecycle | clean/repeat/uninstall/repeat, fehlende Dependencies, partial/future marker, fremde P/PC und kollationgleiche abweichende Namen (Lifecycle.AliasCollision.Setup.sql + originale First-GO-Probes 54634/state1 und vollständiger Snapshot), Consumerblockade, AppLock/Rollback | Repeat/Uninstall-Repeat und vier Aliasprüfungen erfolgreich; weitere Negativ-/Consumer-/Rollbackfälle offen |
| Plattform | Windows2019/2022/2025 CL150/160/170 jeweils tatsächlich ausgewählte Kombination; Ceiling/Minimalrechte/CI separat | Windows2025/CU8 CL170 local teilweise validiert; übrige Kombinationen und CI offen |
| Linux/Central | vorhandener Windows-only/local_required Filesystemvertrag | not applicable |

## Sichere spätere Durchführung

Nur schema-validiertes ausdrücklich ausgewähltes READY-Ziel, private eigene
GUID-DB/Root-/Dateituples/Trust-Vorzustände mit Wiederherstellungsjournal.
Root-Alias der synthetischen Fixtures: ContosoZipFiles; eigenes existierendes
Testverzeichnis, keine realen Daten/Roots. Root koordiniert tatsächliche SQL-
und NTFS-Ausführung; keine implizite Rechte-/Config-/Providerfreigabe.
Dateinamen sind endlich: contract.zip, hello.txt, empty.txt, empty.zip und
published-before-sql-error.zip. Vorzustand/Ownmarker prüfen, eigene Dateien
nur nach frischer Identitätsprüfung entfernen. ACLtests ausschließlich eigene
Fixtures, jede eigene Änderung wiederherstellen. Kein Runtimepayload ins Repo.
Nativeplan bindet auch vorhandenen ZIP-/Filesystem-/ResultTablecode/Artefakte;
ein Sourcefixture allein beweist keinen sauberen Host-/Gastabschluss.

Dependency-Interop: vier feste RequireObjectMarkers-Rollen (Writer/Core1, Legacyreader/FS0), DB-Version/P-Slot weiter verpflichtend; ZIP/Core-DBMode und Core-ObjMode unverändert. Positive native Legacyreader-Nutzung und unveränderte negative Writer-Markerfixture im begrenzten Lauf erfolgreich; weitere Dependency-Negative bleiben offen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater begrenzter Windows-local-Lauf und gezielte AppLock-Probes`
- Scope: SQL Server 2025/CU8 Windows, CL170, local: elf Fälle in früheren Teilabläufen erfolgreich, danach zwei gezielte Aliasprüfungen unter AppLock erfolgreich, mit identischen Produktbytes. Zusammen 13 Fallnachweise, kein gemeinsamer 13-Fälle-Erfolgslauf. Fünf SQL-Fixtures, Windows-Caller/SQLauth-Ablehnung, Deploy-/Uninstall-Repeat und Alias-First-GO-/AppLock-Schutz; eigene DB/Root abwesend, zwei Trustzustände wiederhergestellt und frische Prüfung erfolgreich, keine Konfigurations-/Rechte-/Owneränderung. Historische fehlgeschlagene Abläufe bleiben fehlgeschlagen; unveränderte Provider wiederverwendet, keine vollständige ZIP-/NTFS-/Zielmatrix-, Central-/Linux-, Minimalrechte- oder aktuelle Head-CI-Qualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

# toolbelt_archive.USP_CreateZipFileFromEntries

## Zweck

Vollständiges ZIP aus vorhandener Entry-#Temp
über den bestehenden Windowsprovider schreiben. Source 1.0.0 implementiert;
Runtime nicht ausgeführt; unveröffentlicht.
[Vertrag](../../../Documentation/Architecture/ZIP_FILES_CONTRACT.md).

## Parameter

| Position | Parameter | SQL-Typ | Default | Bedeutung |
|---:|---|---|---|---|
| 1 | `@EntryTable` | `sysname` | `NULL` | Vorhandene lokale Entrytabelle: Ordinal int, EntryName nvarchar(max), Payload varbinary(max). |
| 2 | `@RootAlias` | `sysname` | `NULL` | Vorhandener freigegebener Filesystem-Root-Alias. |
| 3 | `@RelativePath` | `nvarchar(4000)` | `NULL` | Expliziter relativer Zielpfad; Zielverzeichnis muss bestehen. |
| 4 | `@CompressionMethod` | `varchar(max)` | `'Stored'` | Stored oder Deflate; kanonischer Writervertrag. |
| 5 | `@MaxEntries` | `int` | `256` | Positiv, höchstens 1024 Entries. |
| 6 | `@MaxEntryNameCodeUnits` | `int` | `1024` | Positiv, höchstens 2048 UTF-16-Codeeinheiten; Reader bleibt bei 1024. |
| 7 | `@MaxEntryBytes` | `bigint` | `16777216` | Positiv, höchstens 33554432 Payloadbytes je Entry. |
| 8 | `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Positiv, höchstens 134217728 Payloadbytes insgesamt. |
| 9 | `@MaxArchiveBytes` | `bigint` | `71303168` | Positiv, höchstens 150994944 Archivbytes. |
| 10 | `@MaxEnvelopeBytes` | `bigint` | `71303168` | Positiv, höchstens 142606336 Envelopebytes. |
| 11 | `@WriterBudgetMilliseconds` | `int` | `30000` | 1 bis 60000; kooperatives Writerbudget, keine harte Gesamtfrist. |
| 12 | `@Overwrite` | `bit` | `0` | Unverändert an WriteBinaryFile; Default lehnt vorhandenes Ziel ab. |
| 13 | `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Caller: Windows-Authentifizierung; ServiceAccount nur explizit, kein Fallback. |
| 14 | `@ResultTable` | `sysname` | `NULL` | NULL: ein SELECT; sonst vorhandene lokale Caller-Temp, ohne Resultset. |
| 15 | `@KeepData` | `bit` | `0` | 0 Replace, 1 Append; SQL-Publikation erst nach Dateipublikation. |
| 16 | `@Debug` | `tinyint` | `0` | Nur Messages ohne Pfade, Entrynamen oder Payloads. |
| 17 | `@Hilfe` | `bit` | `0` | 1 ignoriert alle anderen Parameter, Dependencies und Transaktionen. |

## Ergebnis

| Position | Spalte | SQL-Typ | NULL |
|---:|---|---|---|
| 1 | BytesWritten | bigint | nein |
| 2 | RootAlias | nvarchar(128) | nein |
| 3 | RelativePath | nvarchar(4000) | nein |
| 4 | State | varchar(16) | nein |

Eine Zeile, State unverändert completed, RETURN 0. ResultTable=NULL:
ein SELECT; vorhandene lokale Temp: kein fachliches SELECT, KeepData
Replace/Append. Keine aktive Caller-TX. Hilfe ignoriert alle anderen
Parameter/Transaktionen/Dependencies; Debug ausschließlich Messages.

## Rechte, Plattform und Dependencies

Windows-only/local SQL Server 2019/2022/2025. ZIP Memory >=1.4.0,
Windows Filesystem/ResultTable >=1.0.0 in derselben DB. Vorhandene EXECUTE-/
Ownershipchain-, Alias- und NTFS-Rechte, Caller Windows-authentifiziert.
ServiceAccount nur ausdrücklich, keine GRANTs/Provideränderung.

## Fehler, Performance und Einschränkungen

54620-54624 State1 TBX_ZIP_FILE_; bestehende ZIP-/Filesystem-/Helper-/
Enginefehler erhalten. Vollständige begrenzte Materialisierung, keine harte
Gesamtfrist oder Kapazitätszusage. Leerer unverschlüsselter Entry:
0-Byte-Datei; NULL/encrypted wird nicht zu leer. Kein List, recursive
Extract, mkdir, absoluter/UNC-Pfad oder Identitätsfallback.

Datei und SQL-Ausgabe nicht gemeinsam atomar: Nach Publish kann
ResultTable/Clientausgabe scheitern; Datei bleibt. Zielzustand vor Retry
prüfen, kein kompensierender Delete. Drei eigene kollisionsgeprüfte
Brücken-Temps sind die enge Namingausnahme; sonst #tbx_.

## Beispiele

```sql
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
```

Fachliche synthetische Beispiele im Help setzen einen zugelassenen Root-Alias
und vorhandenes Zielverzeichnis voraus. [Runtime offen](../Tests/README.md).

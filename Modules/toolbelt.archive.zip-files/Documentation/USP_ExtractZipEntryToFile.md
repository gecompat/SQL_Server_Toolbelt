# toolbelt_archive.USP_ExtractZipEntryToFile

## Zweck

Vollständiges Entry-Binary aus einem ZIP
über den bestehenden Windowsprovider schreiben. Source 1.0.0 implementiert;
Runtime nicht ausgeführt; unveröffentlicht.
[Vertrag](../../../Documentation/Architecture/ZIP_FILES_CONTRACT.md).

## Parameter

| Position | Parameter | SQL-Typ | Default | Bedeutung |
|---:|---|---|---|---|
| 1 | `@ZipArchive` | `varbinary(max)` | `NULL` | ZIP-Binary; harte Readergrenze 268435456 Bytes. |
| 2 | `@EntryName` | `nvarchar(1024)` | `NULL` | Exakter ordinaler Entryname; kein abgeleiteter Dateipfad. |
| 3 | `@RootAlias` | `sysname` | `NULL` | Vorhandener freigegebener Filesystem-Root-Alias. |
| 4 | `@RelativePath` | `nvarchar(4000)` | `NULL` | Expliziter relativer Zielpfad; Zielverzeichnis muss bestehen. |
| 5 | `@MaxEntryBytes` | `bigint` | `104857600` | 1 bis 2147483647 unkomprimierte Entrybytes; geerbte Obergrenze, kein Kapazitätsnachweis. |
| 6 | `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Mindestens 1; kanonische deklarierte und tatsächliche Readerprüfung. |
| 7 | `@Overwrite` | `bit` | `0` | Unverändert an WriteBinaryFile; kein Direct-Write-Fallback. |
| 8 | `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Caller als Default; ServiceAccount nur explizit gewählt. |
| 9 | `@ResultTable` | `sysname` | `NULL` | NULL: ein SELECT; sonst vorhandene lokale Caller-Temp, ohne Resultset. |
| 10 | `@KeepData` | `bit` | `0` | 0 Replace, 1 Append; SQL-Publikation erst nach Dateipublikation. |
| 11 | `@Debug` | `tinyint` | `0` | Nur Messages ohne Pfade, Entrynamen oder Payloads. |
| 12 | `@Hilfe` | `bit` | `0` | 1 ignoriert alle anderen Parameter, Dependencies und Transaktionen. |

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
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @Hilfe=1;
```

Fachliche synthetische Beispiele im Help setzen einen zugelassenen Root-Alias
und vorhandenes Zielverzeichnis voraus. [Runtime offen](../Tests/README.md).

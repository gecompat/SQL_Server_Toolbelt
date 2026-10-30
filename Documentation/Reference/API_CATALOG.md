# SQL Server Toolbelt Beispielkatalog

<!-- Generiert mit Tests/Documentation/generate_api_catalog.py --write; nicht direkt bearbeiten. -->

168 öffentliche Schnittstellen aus 44 Modulen. Dieser Katalog ergänzt die verbindlichen Objektverträge mit kurzen Erklärungen, Source-Signaturen und synthetischen Beispielaufrufen.

Jedes Beispiel separat verwenden. Funktionen verlangen positionsbezogene Argumente; `DEFAULT` verwendet einen deklarierten Default, `NULL` kann davon abweichen. Prozeduren verwenden benannte Parameter. Vorlagen mit Handlern, Claims, Dateien oder Plan-Hashes erfordern die beschriebenen Voraussetzungen. Eine Syntaxvorlage ist kein Runtime-Nachweis.

Pflege und Generierung: [README](README.md).

## toolbelt_archive.USP_CreateZipFileFromEntries

Modul `toolbelt.archive.zip-files` · Version `1.0.0` · `USP`

Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.

Vertrag und Quelle: [USP_CreateZipFileFromEntries.sql](../../Modules/toolbelt.archive.zip-files/Source/USP_CreateZipFileFromEntries.sql), [USP_CreateZipFileFromEntries.md](../../Modules/toolbelt.archive.zip-files/Documentation/USP_CreateZipFileFromEntries.md).

<!-- Source/Vertrag SHA256: 8195440ba10148a32d370b9d45ff42b992fb203af4fffa0b756e1f4f5c6f9de6 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene lokale Entrytabelle: Ordinal int, EntryName nvarchar(max), Payload varbinary(max). |
| `@RootAlias` | `sysname` | `NULL` | Input | Vorhandener freigegebener Filesystem-Root-Alias. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Expliziter relativer Zielpfad; Zielverzeichnis muss bestehen. |
| `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Stored oder Deflate; kanonischer Writervertrag. |
| `@MaxEntries` | `int` | `256` | Input | Positiv, höchstens 1024 Entries. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Positiv, höchstens 2048 UTF-16-Codeeinheiten; Reader bleibt bei 1024. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Positiv, höchstens 33554432 Payloadbytes je Entry. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Positiv, höchstens 134217728 Payloadbytes insgesamt. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Positiv, höchstens 150994944 Archivbytes. |
| `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Positiv, höchstens 142606336 Envelopebytes. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | 1 bis 60000; kooperatives Writerbudget, keine harte Gesamtfrist. |
| `@Overwrite` | `bit` | `0` | Input | Unverändert an WriteBinaryFile; Default lehnt vorhandenes Ziel ab. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller: Windows-Authentifizierung; ServiceAccount nur explizit, kein Fallback. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: ein SELECT; sonst vorhandene lokale Caller-Temp, ohne Resultset. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append; SQL-Publikation erst nach Dateipublikation. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Pfade, Entrynamen oder Payloads. |
| `@Hilfe` | `bit` | `0` | Input | 1 ignoriert alle anderen Parameter, Dependencies und Transaktionen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max)); INSERT #Entries VALUES(1,N'hello.txt',0x4869); EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',@RootAlias=N'ContosoOutput',@RelativePath=N'hello.zip';
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
```

## toolbelt_archive.USP_ExtractZipEntryToFile

Modul `toolbelt.archive.zip-files` · Version `1.0.0` · `USP`

Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.

Vertrag und Quelle: [USP_ExtractZipEntryToFile.sql](../../Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipEntryToFile.sql), [USP_ExtractZipEntryToFile.md](../../Modules/toolbelt.archive.zip-files/Documentation/USP_ExtractZipEntryToFile.md).

<!-- Source/Vertrag SHA256: 560ff105cebcdcbdbb84bd366992a42281dd1950c0bdd20ed60243833b0c83a4 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | ZIP-Binary; harte Readergrenze 268435456 Bytes. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter ordinaler Entryname; kein abgeleiteter Dateipfad. |
| `@RootAlias` | `sysname` | `NULL` | Input | Vorhandener freigegebener Filesystem-Root-Alias. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Expliziter relativer Zielpfad; Zielverzeichnis muss bestehen. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Default16777216, höchstens67108864 unkomprimierte Entrybytes; deklarierte und tatsächliche Größe vor Ausgabe prüfen. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | Mindestens 1; kanonische deklarierte und tatsächliche Readerprüfung. |
| `@Overwrite` | `bit` | `0` | Input | Unverändert an WriteBinaryFile; kein Direct-Write-Fallback. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller als Default; ServiceAccount nur explizit gewählt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: ein SELECT; sonst vorhandene lokale Caller-Temp, ohne Resultset. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append; SQL-Publikation erst nach Dateipublikation. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Pfade, Entrynamen oder Payloads. |
| `@Hilfe` | `bit` | `0` | Input | 1 ignoriert alle anderen Parameter, Dependencies und Transaktionen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=0x504B03041400000000000000210000000000000000000000000009000000656D7074792E747874504B0102140014000000000000002100000000000000000000000000090000000000000000000000000000000000656D7074792E747874504B0506000000000100010037000000270000000000,@EntryName=N'empty.txt',@RootAlias=N'ContosoOutput',@RelativePath=N'empty.txt';
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @Hilfe=1;
```

## toolbelt_archive.USP_CreateZipFromEntries

Modul `toolbelt.archive.zip-memory` · Version `1.4.0` · `USP`

Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.

Vertrag und Quelle: [USP_CreateZipFromEntries.sql](../../Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql), [USP_CreateZipFromEntries.md](../../Modules/toolbelt.archive.zip-memory/Documentation/USP_CreateZipFromEntries.md).

<!-- Source/Vertrag SHA256: 47fcec037ddc136914bbbc709b4bdee36500a10f0b1eeafb565ed8394f5aef00 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene lokale Temp-Tabelle, kein freies SQL. |
| `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Exakt Stored oder Deflate; Default Stored. |
| `@MaxEntries` | `int` | `256` | Input | Positiv, höchstens 1024 Entries. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Positiv, höchstens 2048 UTF-16-Codeeinheiten; Reader bleibt 1024. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Positiv, höchstens 33554432 Payloadbytes je Entry. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Positiv, höchstens 134217728 Payloadbytes insgesamt. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Positiv, höchstens 150994944 Outputbytes inklusive ZIP-Header. |
| `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Positiv, höchstens 142606336 Transportbytes inklusive Namen/Framing. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | 1 bis 60000, kooperatives CLR-Budget; keine SQL-End-to-End-Frist. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: SELECT, sonst vorhandene lokale Temp-Tabelle; nicht identisch zum Input. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace; 1 Append nach USP-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Payloads oder Entrynamen. |
| `@Hilfe` | `bit` | `0` | Input | 1: ausschließlich diese Hilfe, keine fachlichen Prüfungen/Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #ZipInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); INSERT #ZipInput VALUES(1,N'hello.txt',0x4869); EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput';
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
```

## toolbelt_archive.USP_ExtractZipEntryFromBinary

Modul `toolbelt.archive.zip-memory` · Version `1.4.0` · `USP`

Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.

Vertrag und Quelle: [USP_ExtractZipEntryFromBinary.sql](../../Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql), [USP_ExtractZipEntryFromBinary.md](../../Modules/toolbelt.archive.zip-memory/Documentation/USP_ExtractZipEntryFromBinary.md).

<!-- Source/Vertrag SHA256: 3b058bc5a3c01faeb727eddd404888e6a453e679872aa259b3016e0c408b8b7e -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | ZIP-Container als In-memory-BLOB. Das harte Providerlimit beträgt 268435456 Bytes. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter Entry-Name. Der CLR-Provider vergleicht ordinal und case-sensitive. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Obere Grenze für die tatsächlich ausgegebene unkomprimierte Entry-Größe. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | Obere Grenze für tatsächliche und deklarierte UncompressedBytes/CompressedBytes. |
| `@FailIfEncrypted` | `bit` | `1` | Input | 1 lehnt verschlüsselte Entries ab. 0 liefert IsEncrypted=1 und keinen Payload. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale bestehende lokale Temp-Tabelle für den USP-ResultTable-Pfad. |
| `@KeepData` | `bit` | `0` | Input | Gilt nur mit @ResultTable und wird an USP_PrepareResultTable weitergegeben. |
| `@Debug` | `tinyint` | `0` | Input | Standardisierter USP-Debugparameter. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Vollständiges synthetisches ZIP mit hello.txt und dem Text Hi.
DECLARE @ZipArchive varbinary(max)=0x504B0304140000000000000021580E0E174D02000000020000000900000068656C6C6F2E7478744869504B01021400140000000000000021580E0E174D020000000200000009000000000000000000000080010000000068656C6C6F2E747874504B0506000000000100010037000000290000000000;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@ZipArchive, @EntryName=N'hello.txt';
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;
```

## toolbelt_archive.USP_ListZipEntriesFromBinary

Modul `toolbelt.archive.zip-memory` · Version `1.4.0` · `USP`

Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren.

Vertrag und Quelle: [USP_ListZipEntriesFromBinary.sql](../../Modules/toolbelt.archive.zip-memory/Source/USP_ListZipEntriesFromBinary.sql), [USP_ListZipEntriesFromBinary.md](../../Modules/toolbelt.archive.zip-memory/Documentation/USP_ListZipEntriesFromBinary.md).

<!-- Source/Vertrag SHA256: 8467d6fa605f0adeeb7a21daf0f64545773fa65a9e630be4cdda21c7c000bdd2 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Nicht leerer ZIP-Container im Speicher; hartes Limit 268435456 Bytes. |
| `@MaxEntries` | `int` | `10000` | Input | Zulässige Zahl der Entries zwischen 1 und dem harten Limit 10000. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale bestehende lokale Temp-Tabelle für den ResultTable-Pfad. |
| `@KeepData` | `bit` | `0` | Input | Gilt nur mit @ResultTable und steuert Replace oder Append. |
| `@Debug` | `tinyint` | `0` | Input | Standardisierter USP-Debugparameter. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Vollständiges synthetisches ZIP mit hello.txt und dem Text Hi.
DECLARE @ZipArchive varbinary(max)=0x504B0304140000000000000021580E0E174D02000000020000000900000068656C6C6F2E7478744869504B01021400140000000000000021580E0E174D020000000200000009000000000000000000000080010000000068656C6C6F2E747874504B0506000000000100010037000000290000000000;
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@ZipArchive;
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @Hilfe=1;
```

## toolbelt_binary.TVF_LeftShiftBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Verschiebt die Bits eines bigint-Werts nach links.

Vertrag und Quelle: [TVF_LeftShiftBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_LeftShiftBigInt.sql), [TVF_LeftShiftBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_LeftShiftBigInt.md).

<!-- Source/Vertrag SHA256: 3c4b0d0e9c650771cd95345c12acdbfdedb916522e53fd8cc3bd2822d6222113 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Anzahl der Bitpositionen der Verschiebung. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_binary.TVF_LeftShiftBigInt(255, 2);
```

## toolbelt_binary.TVF_RightShiftBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Verschiebt die Bits eines bigint-Werts logisch nach rechts.

Vertrag und Quelle: [TVF_RightShiftBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_RightShiftBigInt.sql), [TVF_RightShiftBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_RightShiftBigInt.md).

<!-- Source/Vertrag SHA256: baaf0314da34a430fdfa8112f74ae04bb23d4d58f171241055ceb42dd8a6a461 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Anzahl der Bitpositionen der Verschiebung. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_binary.TVF_RightShiftBigInt(255, 2);
```

## toolbelt_binary.TVF_BitCountBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Zählt gesetzte Bits im bigint-Wert.

Vertrag und Quelle: [TVF_BitCountBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_BitCountBigInt.sql), [TVF_BitCountBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_BitCountBigInt.md).

<!-- Source/Vertrag SHA256: 8c5647810d2121f62f8d0cddf11cbbd2978c35976bb2e408ee4ebdb04df5750c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_binary.TVF_BitCountBigInt(255);
```

## toolbelt_binary.TVF_GetBitBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Liest das Bit an einer nullbasierten Position.

Vertrag und Quelle: [TVF_GetBitBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_GetBitBigInt.sql), [TVF_GetBitBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_GetBitBigInt.md).

<!-- Source/Vertrag SHA256: 36683ad94050818c579d9074920959d68020a855a07cd95fcc5fc0f2d0975d4b -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Nullbasierte Bitposition 0–63. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_binary.TVF_GetBitBigInt(255, 3);
```

## toolbelt_binary.TVF_SetBitBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Setzt oder löscht ein Bit an einer nullbasierten Position.

Vertrag und Quelle: [TVF_SetBitBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_SetBitBigInt.sql), [TVF_SetBitBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_SetBitBigInt.md).

<!-- Source/Vertrag SHA256: c5b57190201fd3853a81267ab16276df6eaced4e5ff0dda8c355b8a0951e70b1 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Nullbasierte Bitposition 0–63. |
| `@BitValue` | `int` | `1` | Input | 0 löscht, 1 setzt das Bit. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_binary.TVF_SetBitBigInt(255, 3, 1);
```

## toolbelt_conversion.TVF_Base64Encode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Codiert Binärdaten als Base64 oder Base64URL.

Vertrag und Quelle: [TVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql), [TVF_Base64Encode.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64Encode.md).

<!-- Source/Vertrag SHA256: 76b6d7a81555541cf6a46f40521695a8f0ec9c60ad3df4281e502a02f3e08bfc -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@UrlSafe` | `bit` | `0` | Input | 0 = Standard-Base64; 1 = Base64URL beim Encoding. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64Encode(0x4869, 0);
```

## toolbelt_conversion.TVF_Base64Decode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Decodiert Base64-Text zu Binärdaten.

Vertrag und Quelle: [TVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql), [TVF_Base64Decode.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64Decode.md).

<!-- Source/Vertrag SHA256: 3ffd5d849799d4f71ae8252d7dd21a6814fe05498b8aeda5ea20806ff871c7cf -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64Decode(N'SGk=');
```

## toolbelt_conversion.SVF_Base64Encode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `SVF`

Codiert Binärdaten als Base64 oder Base64URL.

Vertrag und Quelle: [SVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql), [SVF_Base64Encode.md](../../Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Encode.md).

<!-- Source/Vertrag SHA256: 63a3dea612b52a8ffc15520cbe60a556692f4a720119f86267eb735859873d1e -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Zu codierende Bytes; keine Zeichenkodierung. |
| `@UrlSafe` | `bit` | `0` | Input | 0 = Standard-Base64; 1 = Base64URL beim Encoding. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_Base64Encode(0x4869, 0) AS ResultValue;
```

## toolbelt_conversion.SVF_Base64Decode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `SVF`

Decodiert Base64-Text zu Binärdaten.

Vertrag und Quelle: [SVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql), [SVF_Base64Decode.md](../../Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Decode.md).

<!-- Source/Vertrag SHA256: 4a3fae3d9fc8e3072854fc49315aaac8f8d4480576cebf790ad7c1696abd1492 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Base64- oder Base64URL-Text; keine implizite Zeichenkodierung des decodierten Ergebnisses. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_Base64Decode(N'SGk=') AS ResultValue;
```

## toolbelt_conversion.TVF_Base64EncodeStatus

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Genau eine Zeile. OK enthält den Wert; LIMIT und SQL_NULL enthalten NULL. Der kanonische MSTVF-Kern prüft vor XML. Die bisherige TVF/SVF delegiert und liefert bei Überschreitung NULL.

Vertrag und Quelle: [TVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql), [TVF_Base64EncodeStatus.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64EncodeStatus.md).

<!-- Source/Vertrag SHA256: 96a56d63efc4acff94dd4112ac79cf600d518a83e556d1b48027109038440dfb -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | varbinary(max); NULL ergibt SQL_NULL; höchstens 16777216 Bytes vor XML. |
| `@UrlSafe` | `bit` | `0` | Input | bit=0; 1 erzeugt Base64URL ohne Padding; NULL entspricht 0. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFE,0);
```

## toolbelt_conversion.TVF_Base64DecodeStatus

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL.

Vertrag und Quelle: [TVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql), [TVF_Base64DecodeStatus.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64DecodeStatus.md).

<!-- Source/Vertrag SHA256: afb145803a45f7103659086177d659dd8849d589bef3f9127b4ff58ade2acc1a -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | varchar(max); höchstens 25165824 Rohtextbytes einschließlich Whitespace und 16777216 Ergebnisbytes. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('YWJj');
```

## toolbelt_conversion.TVF_IntegerToBase

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `TVF`

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Vertrag und Quelle: [TVF_IntegerToBase.sql](../../Modules/toolbelt.conversion.integer-base/Source/TVF_IntegerToBase.sql), [TVF_IntegerToBase.md](../../Modules/toolbelt.conversion.integer-base/Documentation/TVF_IntegerToBase.md).

<!-- Source/Vertrag SHA256: 7eab9275067bf155c7aeab3b15e46c51f036f7f0583e10a3c17f49621220df38 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2–93 binär eindeutige ASCII-Zeichen; Minus ist für das Vorzeichen reserviert. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_IntegerToBase(255, '0123456789ABCDEF');
```

## toolbelt_conversion.TVF_TryBaseToInteger

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `TVF`

Decodiert einen Text anhand des angegebenen Alphabets in bigint.

Vertrag und Quelle: [TVF_TryBaseToInteger.sql](../../Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql), [TVF_TryBaseToInteger.md](../../Modules/toolbelt.conversion.integer-base/Documentation/TVF_TryBaseToInteger.md).

<!-- Source/Vertrag SHA256: 9759b1a0486165135e9a789ebd39a953a6984c00bf06e99ccbfe179f6e44ae0d -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext im gewählten Alphabet. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2–93 binär eindeutige ASCII-Zeichen; Minus ist für das Vorzeichen reserviert. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryBaseToInteger('FF', '0123456789ABCDEF');
```

## toolbelt_conversion.SVF_IntegerToBase

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `SVF`

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Vertrag und Quelle: [SVF_IntegerToBase.sql](../../Modules/toolbelt.conversion.integer-base/Source/SVF_IntegerToBase.sql), [SVF_IntegerToBase.md](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_IntegerToBase.md).

<!-- Source/Vertrag SHA256: 2c57c79e1da23c009ab5b581700de630089a1c3b7f78cbc297c12eed65877a02 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2–93 binär eindeutige ASCII-Zeichen; Minus ist für das Vorzeichen reserviert. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_IntegerToBase(255, '0123456789ABCDEF') AS ResultValue;
```

## toolbelt_conversion.SVF_TryBaseToInteger

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `SVF`

Decodiert einen Text anhand des angegebenen Alphabets in bigint.

Vertrag und Quelle: [SVF_TryBaseToInteger.sql](../../Modules/toolbelt.conversion.integer-base/Source/SVF_TryBaseToInteger.sql), [SVF_TryBaseToInteger.md](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_TryBaseToInteger.md).

<!-- Source/Vertrag SHA256: 5f043733b76bf45f525013cebad5df9448b646227095c1bfe707907e919cb638 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext im gewählten Alphabet. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2–93 binär eindeutige ASCII-Zeichen; Minus ist für das Vorzeichen reserviert. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_TryBaseToInteger('FF', '0123456789ABCDEF') AS ResultValue;
```

## toolbelt_conversion.TVF_TryCastBigInt

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft ASCII-Ganzzahltext und den exakten bigint-Bereich; liefert Value, Status und ErrorCode.

Vertrag und Quelle: [TVF_TryCastBigInt.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBigInt.sql), [TVF_TryCastBigInt.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBigInt.md).

<!-- Source/Vertrag SHA256: 280cfcde7a568a7d81f7922ec88aa10b922ac82079e0926d3b3395837fc97438 -->

Voraussetzung: Vorhandenes SELECT; genau eine Zeile, keine Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Optionales ASCII-Vorzeichen und Ziffern; keine Leerzeichen oder Localeformate. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives UTF16-Bytebudget bis8192; SQL_NULL hat Vorrang. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastBigInt(N'-9223372036854775808', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastDecimal

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft exakten decimal(38,18)-Bereich vor Skalenverlust; rundet niemals still.

Vertrag und Quelle: [TVF_TryCastDecimal.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDecimal.sql), [TVF_TryCastDecimal.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDecimal.md).

<!-- Source/Vertrag SHA256: b19a0bfd9fe51f11716bc1f090b8df0864eb050a14055bc684ce5fbc7982fe8e -->

Voraussetzung: Vorhandenes SELECT; Bereichsüberschreitung ist OUT_OF_RANGE, sonst nichtnull Fractionrest LOSSY.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Zahl mit optionalem Vorzeichen und optional Punkt/Ziffern; überzählige Nullstellen sind exakt entfernbar. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives UTF16-Bytebudget bis8192; keine dynamische Precision oder Scale. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastDecimal(N'99999999999999999999.9999999999999999991', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastDate

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft exakt YYYY-MM-DD und den date-Kalenderbereich unabhängig von Sprache und DATEFORMAT.

Vertrag und Quelle: [TVF_TryCastDate.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDate.sql), [TVF_TryCastDate.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDate.md).

<!-- Source/Vertrag SHA256: 7a28c1116699781ff435877c44253ec8810aa6b1ed50291f413aa97020ed717f -->

Voraussetzung: Vorhandenes SELECT; keine Zeit- oder Localeinterpretation.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau zehn ASCII-Codeeinheiten; Kalenderfehler sind OUT_OF_RANGE. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives UTF16-Bytebudget bis8192. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastDate(N'2024-02-29', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastDateTime2

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust.

Vertrag und Quelle: [TVF_TryCastDateTime2.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDateTime2.sql), [TVF_TryCastDateTime2.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDateTime2.md).

<!-- Source/Vertrag SHA256: 442614402a863871fd530885bf90ecef39386b233470603c8ca1674cdb429057 -->

Voraussetzung: Vorhandenes SELECT; datetime2(7), keine Offset-/Zeitzoneninterpretation.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | YYYY-MM-DDTHH:mm:ss, optional Punkt mit1..7 ASCII-Ziffern. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives UTF16-Bytebudget bis8192. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastDateTime2(N'2024-02-29T23:59:59.1234567', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastBit

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Akzeptiert ausschließlich den Text0 oder1; native permissive Bitkonversion bleibt ausgeschlossen.

Vertrag und Quelle: [TVF_TryCastBit.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBit.sql), [TVF_TryCastBit.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBit.md).

<!-- Source/Vertrag SHA256: 9d0fd4917a1158656a6f64c9bba96a1db0d07d5d71e2ccf64b01dc8de3a79d90 -->

Voraussetzung: Vorhandenes SELECT; Bit2 und TRUE sind INVALID_FORMAT.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Exakt eine ASCII-Ziffer0/1; kein Vorzeichen oder Trim. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives UTF16-Bytebudget bis8192. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastBit(N'2', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastUniqueIdentifier

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft vollständige GUID-Lexik im8-4-4-4-12-Muster vor Konversion; keine Suffixtrunkierung.

Vertrag und Quelle: [TVF_TryCastUniqueIdentifier.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastUniqueIdentifier.sql), [TVF_TryCastUniqueIdentifier.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastUniqueIdentifier.md).

<!-- Source/Vertrag SHA256: 8ab7f018f255ab9c469a0a6ae779cdf74a4f28c8d3c0588924af5df665df8c05 -->

Voraussetzung: Vorhandenes SELECT; Hexbuchstaben upper/lower zulässig, keine Braces.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau36 ASCII-Hex-/Bindestrich-Codeeinheiten. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives UTF16-Bytebudget bis8192. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastUniqueIdentifier(N'00112233-4455-6677-8899-aabbccddeeff', DEFAULT);
```

## toolbelt_conversion.TVF_UriComponentEncode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Codiert eine URI-Komponente mit UTF-8 und Prozent-Escapes nach RFC 3986.

Vertrag und Quelle: [TVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql), [TVF_UriComponentEncode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncode.md).

<!-- Source/Vertrag SHA256: f369cc98b7bceb91e703bae7c05452bf5755038ed813b2c6497e6c67dea75805 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncode(N'a b/ä');
```

## toolbelt_conversion.TVF_UriComponentDecode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

Vertrag und Quelle: [TVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql), [TVF_UriComponentDecode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentDecode.md).

<!-- Source/Vertrag SHA256: 02e330b82b223e72e9b9bee65cbfee1ac51d62d6081365271b7e81baed7d475f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecode(N'a%20b%2F%C3%A4');
```

## toolbelt_conversion.SVF_UriComponentEncode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `SVF`

Codiert eine URI-Komponente mit UTF-8 und Prozent-Escapes nach RFC 3986.

Vertrag und Quelle: [SVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentEncode.sql), [SVF_UriComponentEncode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/SVF_UriComponentEncode.md).

<!-- Source/Vertrag SHA256: 3f8f79d80647dc9d99cf2038a8bf8e9189787fb6dcf82b9fed1190c32645cda7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_UriComponentEncode(N'a b/ä') AS ResultValue;
```

## toolbelt_conversion.SVF_UriComponentDecode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `SVF`

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

Vertrag und Quelle: [SVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentDecode.sql), [SVF_UriComponentDecode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/SVF_UriComponentDecode.md).

<!-- Source/Vertrag SHA256: 54d4e133f63a47702fb5d8106aab83cdd72bdff636795742124944fafb3f28c1 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'a%20b%2F%C3%A4') AS ResultValue;
```

## toolbelt_conversion.TVF_UriComponentEncodeStatus

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL oder LIMIT. Eingang vor UTF-8-Konvertierung/Series prüfen. Aus höchstens 32768 Codeeinheiten entstehen selbst bei drei UTF-8-Bytes und drei Escapezeichen je Byte höchstens 589824 UTF-16-Ausgabebytes; die 1-MiB-Grenze ist damit schon vor Aggregation abgesichert. Altfassaden liefern bei LIMIT NULL.

Vertrag und Quelle: [TVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql), [TVF_UriComponentEncodeStatus.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncodeStatus.md).

<!-- Source/Vertrag SHA256: 516ad8ff8e0ed59efd8422c3910415de41ab1ff527ec0b248fb739c222ca537f -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); höchstens 65536 UTF-16-Bytes. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'Contoso €');
```

## toolbelt_conversion.TVF_UriComponentDecodeStatus

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL.

Vertrag und Quelle: [TVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql), [TVF_UriComponentDecodeStatus.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentDecodeStatus.md).

<!-- Source/Vertrag SHA256: d69f95fa61f0cd590b6763d2e70541bd189313727166cd794dc89af378ad62af -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); höchstens 65536 UTF-16-Bytes. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%E2%82%AC');
```

## toolbelt_core.USP_WriteConsoleMessage

Modul `toolbelt.core.console-message` · Version `1.0.0` · `USP`

Gibt einen langen Unicode-Text vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.

Vertrag und Quelle: [USP_WriteConsoleMessage.sql](../../Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql), [USP_WriteConsoleMessage.md](../../Modules/toolbelt.core.console-message/Documentation/USP_WriteConsoleMessage.md).

<!-- Source/Vertrag SHA256: dfe62269f7ea143fdaf4d132b57e0a8dc4119364d0d94df1b0db18e07adc837e -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Message` | `nvarchar(max)` | `NULL` | Input | Auszugebender Text. NULL und Leertext erzeugen keine Ausgabe. Vorhandene Zeilenumbrüche bleiben innerhalb der Message-Frames erhalten. |
| `@Immediate` | `bit` | `0` | Input | 0 verwendet PRINT in Chunks bis 4.000 UTF-16-Codeunits. 1 verwendet RAISERROR mit Severity 0, konservativen 2.000-Codeunit-Chunks und WITH NOWAIT. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter des USP-Vertrags. Version 1 erzeugt bewusst keine zusätzlichen Debug-Messages, damit der Payload unverändert bleibt. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Schritt 1 abgeschlossen.'
    , @Immediate = 1;
```

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Gepufferte Ausgabe'
    , @Immediate = 0;

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Fortschritt: 100 %'
    , @Immediate = 1;

EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe = 1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe=1;
```

## toolbelt_core.USP_CaptureErrorEnvelope

Modul `toolbelt.core.error-envelope` · Version `1.0.0` · `USP`

Erzeugt aus explizit im aufrufenden CATCH gelesenen ERROR_*-Werten genau eine standardisierte Fehlerzeile. Die Procedure führt keinen Rethrow aus; der Aufrufer verwendet anschließend THROW; im ursprünglichen CATCH.

Vertrag und Quelle: [USP_CaptureErrorEnvelope.sql](../../Modules/toolbelt.core.error-envelope/Source/USP_CaptureErrorEnvelope.sql), [USP_CaptureErrorEnvelope.md](../../Modules/toolbelt.core.error-envelope/Documentation/USP_CaptureErrorEnvelope.md).

<!-- Source/Vertrag SHA256: 1c403653cc481409f82c4d9fbe036b2e9befde8e4f863db36433ee337cc1d9c3 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ErrorNumber` | `int` | `NULL` | Input | ERROR_NUMBER() aus dem aufrufenden CATCH. |
| `@ErrorSeverity` | `int` | `NULL` | Input | ERROR_SEVERITY() aus dem aufrufenden CATCH. |
| `@ErrorState` | `int` | `NULL` | Input | ERROR_STATE() aus dem aufrufenden CATCH. |
| `@ErrorProcedure` | `nvarchar(776)` | `NULL` | Input | ERROR_PROCEDURE() aus dem aufrufenden CATCH. |
| `@ErrorLine` | `int` | `NULL` | Input | ERROR_LINE() aus dem aufrufenden CATCH. |
| `@ErrorMessage` | `nvarchar(4000)` | `NULL` | Input | ERROR_MESSAGE() aus dem aufrufenden CATCH. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Optionale Execution-ID; NULL liest den aktiven Toolbelt Execution Context. |
| `@AdditionalContext` | `nvarchar(4000)` | `NULL` | Input | Optionale synthetische oder bereits bereinigte Zusatzinformation. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für das Ergebnis. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
BEGIN TRY
    THROW 50000,N'Synthetischer Beispielfehler',1;
END TRY
BEGIN CATCH
    DECLARE @Number int=ERROR_NUMBER(), @Severity int=ERROR_SEVERITY(),
            @State int=ERROR_STATE(), @Line int=ERROR_LINE(),
            @Procedure nvarchar(128)=ERROR_PROCEDURE(),
            @Message nvarchar(4000)=ERROR_MESSAGE();
    EXEC toolbelt_core.USP_CaptureErrorEnvelope
      @ErrorNumber=@Number, @ErrorSeverity=@Severity, @ErrorState=@State,
      @ErrorProcedure=@Procedure, @ErrorLine=@Line, @ErrorMessage=@Message;
END CATCH;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
```

## toolbelt_core.VW_Events

Modul `toolbelt.core.event-log` · Version `1.0.0` · `VIEW`

Zeigt protokollierte Toolbelt-Events.

Vertrag und Quelle: [VW_Events.sql](../../Modules/toolbelt.core.event-log/Source/VW_Events.sql), [VW_Events.md](../../Modules/toolbelt.core.event-log/Documentation/VW_Events.md).

<!-- Source/Vertrag SHA256: 0f4fba0000354b008bbbc321a1f60f98fe7430988103f87aa1aa47bf6f503245 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_Events;
```

## toolbelt_core.USP_WriteEvent

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.

Vertrag und Quelle: [USP_WriteEvent.sql](../../Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql), [USP_WriteEvent.md](../../Modules/toolbelt.core.event-log/Documentation/USP_WriteEvent.md).

<!-- Source/Vertrag SHA256: 0ed899d66ed0665b8540b5f139dcd10694e5422bae9cc4cb34b321272d5b00d1 -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EventName` | `varchar(128)` | `NULL` | Input | Kanonischer Eventname in lowercase ASCII. |
| `@EventLevel` | `varchar(16)` | `'INFO'` | Input | TRACE, DEBUG, INFO, WARNING, ERROR oder CRITICAL. |
| `@Category` | `varchar(128)` | `NULL` | Input | Optionale Eventkategorie. |
| `@Message` | `nvarchar(4000)` | `NULL` | Input | Begrenzte menschenlesbare Meldung; keine ungeprüften Secrets persistieren. |
| `@DataJson` | `nvarchar(max)` | `NULL` | Input | Begrenztes JSON-Objekt bis 32 KiB UTF-16-Speicher. |
| `@OccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlicher Ereigniszeitpunkt in UTC. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Korrelations-ID für zusammengehörige Ausführungen/Events. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Actor-Kennung des Ausführungskontexts. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Tenant-Kennung des Ausführungskontexts. |
| `@SourceDatabaseName` | `sysname` | `NULL` | Input | Optionale Datenbankkennzeichnung des Events. |
| `@SourceSchemaName` | `sysname` | `NULL` | Input | Optionale Schemakennzeichnung des Events. |
| `@SourceObjectName` | `sysname` | `NULL` | Input | Optionale Objektkennzeichnung des Events. |
| `@ErrorNumber` | `int` | `NULL` | Input | Nummer des ursprünglichen SQL-Fehlers. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Severity des ursprünglichen SQL-Fehlers. |
| `@ErrorState` | `int` | `NULL` | Input | State des ursprünglichen SQL-Fehlers. |
| `@ErrorProcedure` | `sysname` | `NULL` | Input | Procedure des ursprünglichen SQL-Fehlers. |
| `@ErrorLine` | `int` | `NULL` | Input | Zeilennummer des ursprünglichen SQL-Fehlers. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_WriteEvent @EventName='demo.completed', @Message=N'Synthetic example';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
```

## toolbelt_core.USP_DeleteEventsBefore

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.

Vertrag und Quelle: [USP_DeleteEventsBefore.sql](../../Modules/toolbelt.core.event-log/Source/USP_DeleteEventsBefore.sql), [USP_DeleteEventsBefore.md](../../Modules/toolbelt.core.event-log/Documentation/USP_DeleteEventsBefore.md).

<!-- Source/Vertrag SHA256: b49a763ccc06f87a130a84ce7107ae3d3579645493ef8f8c57028c47f06798f8 -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeOccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Nur Events mit älterem OccurredAtUtc werden gelöscht. |
| `@BatchSize` | `int` | `1000` | Input | 1 bis 10000 Zeilen je Batch. |
| `@MaxBatches` | `int` | `1` | Input | 1 bis 100 Batches je Aufruf. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | OUTPUT: Anzahl der gelöschten Eventzeilen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2026-01-01', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
```

## toolbelt_core.USP_DeleteRecordedEventsBefore

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Nur ausdrücklich aufgerufene Retention nach RecordedAtUtc mit Index (RecordedAtUtc,EventId), deterministischen begrenzten Batches und bestehender Caller-Transaktions-/Savepointsemantik. Kein Job, keine Deploymentlöschung. Die OccurredAtUtc-Retention bleibt unverändert. Erfordert vorhandenes EXECUTE; erteilt keine Berechtigungen. Fehler 51710–51714 wie im bestehenden Retentionvertrag.

Vertrag und Quelle: [USP_DeleteRecordedEventsBefore.sql](../../Modules/toolbelt.core.event-log/Source/USP_DeleteRecordedEventsBefore.sql), [USP_DeleteRecordedEventsBefore.md](../../Modules/toolbelt.core.event-log/Documentation/USP_DeleteRecordedEventsBefore.md).

<!-- Source/Vertrag SHA256: e2caa429185e86e811804188a37f05454eef1befa9e75611fecc0c05d96621b9 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeRecordedAtUtc` | `datetime2(7)` | `NULL` | Input | datetime2(7), erforderlich; exklusiver Cutoff für serverseitiges RecordedAtUtc. |
| `@BatchSize` | `int` | `1000` | Input | int=1000; 1 bis 10000. |
| `@MaxBatches` | `int` | `1` | Input | int=1; 1 bis 100. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT=NULL; initial 0, Anzahl dieses Aufrufs. |
| `@Debug` | `tinyint` | `0` | Input | tinyint=0; feste Fortschrittsmeldung ohne Eventinhalt. |
| `@Hilfe` | `bit` | `0` | Input | bit=0; 1 liefert ausschließlich Hilfe. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2026-01-01',@BatchSize=1000,@MaxBatches=1,@DeletedRows=@n OUTPUT;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @Hilfe=1;
```

## toolbelt_core.TVF_ExecutionCancellationStatus

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `TVF`

Liest den registrierten kooperativen Abbruchstatus einer Ausführung.

Vertrag und Quelle: [TVF_ExecutionCancellationStatus.sql](../../Modules/toolbelt.core.execution-cancel/Source/TVF_ExecutionCancellationStatus.sql), [TVF_ExecutionCancellationStatus.md](../../Modules/toolbelt.core.execution-cancel/Documentation/TVF_ExecutionCancellationStatus.md).

<!-- Source/Vertrag SHA256: 6d17ea219423906e6f0edd7014251d25e58b3c59fbff09026b24d3061acb9163 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
```

## toolbelt_core.SVF_IsCancellationRequested

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `SVF`

Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.

Vertrag und Quelle: [SVF_IsCancellationRequested.sql](../../Modules/toolbelt.core.execution-cancel/Source/SVF_IsCancellationRequested.sql), [SVF_IsCancellationRequested.md](../../Modules/toolbelt.core.execution-cancel/Documentation/SVF_IsCancellationRequested.md).

<!-- Source/Vertrag SHA256: 9b0af2deaf7b083da7fd6ae6acd7e2fa6edff48de3b65070a029da16d9bbbccc -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS ResultValue;
```

## toolbelt_core.USP_RequestExecutionCancellation

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `USP`

Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.

Vertrag und Quelle: [USP_RequestExecutionCancellation.sql](../../Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql), [USP_RequestExecutionCancellation.md](../../Modules/toolbelt.core.execution-cancel/Documentation/USP_RequestExecutionCancellation.md).

<!-- Source/Vertrag SHA256: b4605c01ffd6d7c73d134a53ca8e21c5f9051c0eea79ad3273c7ae727e44b150 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Zielausführung; ohne Wert wird die aktuelle sessiongebundene ExecutionId verwendet. |
| `@CancellationReason` | `nvarchar(512)` | `NULL` | Input | Optionaler, nicht sensibler Grund. Nur die erste Anforderung speichert ihn. |
| `@Debug` | `tinyint` | `0` | Input | Gibt eine Fortschrittsmeldung aus. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N'planned maintenance';
```

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation
    @CancellationReason = N'planned maintenance';

SELECT *
FROM toolbelt_core.TVF_ExecutionCancellationStatus
    (toolbelt_core.SVF_CurrentExecutionId());
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
```

## toolbelt_core.TVF_CurrentExecutionContext

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `TVF`

Liest den Toolbelt-Ausführungskontext der aktuellen Session.

Vertrag und Quelle: [TVF_CurrentExecutionContext.sql](../../Modules/toolbelt.core.execution-context/Source/TVF_CurrentExecutionContext.sql), [TVF_CurrentExecutionContext.md](../../Modules/toolbelt.core.execution-context/Documentation/TVF_CurrentExecutionContext.md).

<!-- Source/Vertrag SHA256: f7227c7c2559ad214dd16cfb05b5d0c5aa0767cf963801d34c33c8c03414ee05 -->

Keine Eingabeparameter.

```sql
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
```

## toolbelt_core.SVF_CurrentExecutionId

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `SVF`

Liest die Execution-ID der aktuellen Session.

Vertrag und Quelle: [SVF_CurrentExecutionId.sql](../../Modules/toolbelt.core.execution-context/Source/SVF_CurrentExecutionId.sql), [SVF_CurrentExecutionId.md](../../Modules/toolbelt.core.execution-context/Documentation/SVF_CurrentExecutionId.md).

<!-- Source/Vertrag SHA256: 5dda2c27f31858f4a58996891844f3c9e3941381ea45ff964101b12104206824 -->

Keine Eingabeparameter.

```sql
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ResultValue;
```

## toolbelt_core.USP_BeginExecution

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `USP`

Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.

Vertrag und Quelle: [USP_BeginExecution.sql](../../Modules/toolbelt.core.execution-context/Source/USP_BeginExecution.sql), [USP_BeginExecution.md](../../Modules/toolbelt.core.execution-context/Documentation/USP_BeginExecution.md).

<!-- Source/Vertrag SHA256: dbe3b2f3bd2d95999a6d6758a3d69ff5d0ff65da045a94e353727b5395105fec -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | OUTPUT | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Korrelations-ID für zusammengehörige Ausführungen/Events. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Actor-Kennung des Ausführungskontexts. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Tenant-Kennung des Ausführungskontexts. |
| `@AllowNested` | `bit` | `1` | Input | 1 erlaubt verschachtelte Execution Contexts; 0 lehnt sie ab. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_BeginExecution @Hilfe=1;
```

## toolbelt_core.USP_SetExecutionContext

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `USP`

Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand.

Vertrag und Quelle: [USP_SetExecutionContext.sql](../../Modules/toolbelt.core.execution-context/Source/USP_SetExecutionContext.sql), [USP_SetExecutionContext.md](../../Modules/toolbelt.core.execution-context/Documentation/USP_SetExecutionContext.md).

<!-- Source/Vertrag SHA256: 9460106aa794b738f396edb41d4b255d6ff5f9d25dce0865a86b34c002785953 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | Muss der aktiven Execution-ID entsprechen. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Korrelations-ID für zusammengehörige Ausführungen/Events. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Actor-Kennung des Ausführungskontexts. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Tenant-Kennung des Ausführungskontexts. |
| `@ClearActor` | `bit` | `0` | Input | 1 löscht den Actor; nicht zugleich mit @Actor verwenden. |
| `@ClearTenant` | `bit` | `0` | Input | 1 löscht den Tenant; nicht zugleich mit @Tenant verwenden. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: in derselben Session zuvor USP_BeginExecution aufrufen.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id, @Actor=N'Contoso example', @Tenant=N'Fabrikam';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=NULL, @Hilfe=1;
```

## toolbelt_core.USP_EndExecution

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `USP`

Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte.

Vertrag und Quelle: [USP_EndExecution.sql](../../Modules/toolbelt.core.execution-context/Source/USP_EndExecution.sql), [USP_EndExecution.md](../../Modules/toolbelt.core.execution-context/Documentation/USP_EndExecution.md).

<!-- Source/Vertrag SHA256: 536ac75a7f7abf1bacc2b9ec320ea542af05a53e2d4281ee765535747b617204 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | Muss der aktiven Execution-ID entsprechen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: aktiver Context in derselben Session.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL, @Hilfe=1;
```

## toolbelt_core.TVF_GenerateSeriesBigInt

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert.

Vertrag und Quelle: [TVF_GenerateSeriesBigInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql), [TVF_GenerateSeriesBigInt.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigInt.md).

<!-- Source/Vertrag SHA256: c920a5c60f9396ac5cda020902218e31f9e58c5b1c01d96081fb0c099f2172ad -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster bigint-Wert der Reihe. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive bigint-Ober- oder Untergrenze, sofern erreichbar. |
| `@Step` | `bigint` | `NULL` | Input | Schrittweite; NULL beziehungsweise DEFAULT löst die Richtung automatisch auf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigInt(1, 5, 1);
```

## toolbelt_core.TVF_GenerateSeriesInt

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Erzeugt eine Folge von int-Werten einschließlich erreichbarem Endwert.

Vertrag und Quelle: [TVF_GenerateSeriesInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql), [TVF_GenerateSeriesInt.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesInt.md).

<!-- Source/Vertrag SHA256: 0b8cc7fa02b629bd5e07dfadc8e83a4718e1231df0cfa6b7c839783573890b1f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `int` | `kein Default` | Input | Erster int-Wert der Reihe. |
| `@Stop` | `int` | `kein Default` | Input | Inklusive int-Ober- oder Untergrenze, sofern erreichbar. |
| `@Step` | `int` | `NULL` | Input | Schrittweite; NULL beziehungsweise DEFAULT löst die Richtung automatisch auf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1);
```

## toolbelt_core.TVF_GenerateSeriesBigIntStatus

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen.

Vertrag und Quelle: [TVF_GenerateSeriesBigInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql), [TVF_GenerateSeriesBigIntStatus.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigIntStatus.md).

<!-- Source/Vertrag SHA256: 041ee4a697cd471bda28010f0f966f6781774bf97b00d90f152a89d258a8cb28 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | bigint; inklusiver Start. |
| `@Stop` | `bigint` | `kein Default` | Input | bigint; inklusives Ende bei erreichbarem Schritt. |
| `@Step` | `bigint` | `NULL` | Input | bigint=NULL; Richtung automatisch; 0 ergibt INVALID. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,DEFAULT);
```

## toolbelt_core.USP_PrepareResultTable

Modul `toolbelt.core.result-table` · Version `1.0.0` · `USP`

Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein.

Vertrag und Quelle: [USP_PrepareResultTable.sql](../../Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql), [USP_PrepareResultTable.md](../../Modules/toolbelt.core.result-table/Documentation/USP_PrepareResultTable.md).

<!-- Source/Vertrag SHA256: 124a3b0954b91c8b4f8bede3b542229175d073a2fbc0550ca2e80e8ea2e21fb7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ResultTableToAlter` | `sysname` | `NULL` | Input | Vorhandene lokale Ziel-Temp-Tabelle. Der Name beginnt mit genau einem #, ist höchstens 116 Zeichen lang und verwendet nicht den reservierten Präfix #tbx_. |
| `@LikeTable` | `nvarchar(776)` | `NULL` | Input | Referenztabelle in der Form #LocalTemplate, Schema.Table oder Database.Schema.Table. Ziel- und Referenztabelle dürfen nicht identisch sein. Views, Synonyme, globale Temp-Tabellen und vierteilige Namen sind nicht unterstützt. |
| `@KeepData` | `bit` | `0` | Input | 0 verwendet Replace-Semantik. 1 erhält vorhandene Daten nur bei bereits passendem Schema; andernfalls wird vor jeder Mutation mit Fehler 51025 abgebrochen. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages. Die Stufen 1 bis 3 liefern zunehmend Details; 255 ist der maximale interne Trace. Debug erzeugt kein Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Result (Dummy int NULL);
CREATE TABLE #ResultShape (ItemOrdinal bigint NOT NULL, ItemValue varchar(100) NULL);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#Result'
    , @LikeTable          = N'#ResultShape'
    , @KeepData           = 0;
DROP TABLE #Result, #ResultShape;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;
```

## toolbelt_core.VW_SecondSessionProviders

Modul `toolbelt.core.second-session` · Version `1.1.0` · `VIEW`

Zeigt konfigurierte Second-Session-Provider.

Vertrag und Quelle: [VW_SecondSessionProviders.sql](../../Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql), [VW_SecondSessionProviders.md](../../Modules/toolbelt.core.second-session/Documentation/VW_SecondSessionProviders.md).

<!-- Source/Vertrag SHA256: cca16be523dec147f9ea7200424cd5752168335875adddb1b6d2090812257f8b -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_SecondSessionProviders;
```

## toolbelt_core.USP_ConfigureSecondSessionLoopback

Modul `toolbelt.core.second-session` · Version `1.1.0` · `USP`

Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.

Vertrag und Quelle: [USP_ConfigureSecondSessionLoopback.sql](../../Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql), [USP_ConfigureSecondSessionLoopback.md](../../Modules/toolbelt.core.second-session/Documentation/USP_ConfigureSecondSessionLoopback.md).

<!-- Source/Vertrag SHA256: c089453d7d12969519c4c9c010659032e78e9c56dbdf53b03284b30a20e9152b -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Vorhandener Linked Server mit rpc out und deaktivierter Remote-Transaction-Promotion. |
| `@Enabled` | `bit` | `1` | Input | Aktiviert oder deaktiviert den Provider. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionale Optimistic-Concurrency-Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Konfigurationszeile. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'TBX_LOOPBACK';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
```

## toolbelt_core.USP_ExecuteWorkTypeInNewSession

Modul `toolbelt.core.second-session` · Version `1.1.0` · `USP`

Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.

Vertrag und Quelle: [USP_ExecuteWorkTypeInNewSession.sql](../../Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql), [USP_ExecuteWorkTypeInNewSession.md](../../Modules/toolbelt.core.second-session/Documentation/USP_ExecuteWorkTypeInNewSession.md).

<!-- Source/Vertrag SHA256: 216f1d85d19a6231c4211dea38fa39127e4099a978ba162db94e16b6ff20db94 -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer Name aus toolbelt.core.work-type. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | JSON-Objekt nur für Work Types mit ParameterMode JSON_PAYLOAD. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Explizite Execution-ID; sonst aktiver Context oder neue ID. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Explizite Correlation-ID; sonst aktiver Context oder Execution-ID. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Expliziter Actor; sonst aktiver Context oder ORIGINAL_LOGIN(). |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Tenant-Kontext. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle; in uncommittable Transaktionen nicht zulässig. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@SuppressResult` | `bit` | `0` | Input | Bei 1 wird nach erfolgreicher Ausführung kein Infrastruktur-Resultset ausgegeben; nicht mit @ResultTable kombinierbar. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='demo.noop';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
```

## toolbelt_core.VW_WorkQueue

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `VIEW`

Zeigt Queue-Status und Auditmetadaten ohne Payload und ClaimToken.

Vertrag und Quelle: [VW_WorkQueue.sql](../../Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql), [VW_WorkQueue.md](../../Modules/toolbelt.core.work-queue/Documentation/VW_WorkQueue.md).

<!-- Source/Vertrag SHA256: f936074f3931121afa41fd41e8410c60b47684b513bb35e42985d8549d4da8a1 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueue;
```

## toolbelt_core.VW_WorkQueueBarrierBlockers

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `VIEW`

Zeigt aktive Claim-Generationen, die eine Gruppenbarriere blockieren.

Vertrag und Quelle: [VW_WorkQueueBarrierBlockers.sql](../../Modules/toolbelt.core.work-queue/Source/VW_WorkQueueBarrierBlockers.sql), [VW_WorkQueueBarrierBlockers.md](../../Modules/toolbelt.core.work-queue/Documentation/VW_WorkQueueBarrierBlockers.md).

<!-- Source/Vertrag SHA256: 6f51fca971382f904242d71469dd76d04651fe5bd67fa821837c170ad25cea8f -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;
```

## toolbelt_core.USP_EnqueueWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

Vertrag und Quelle: [USP_EnqueueWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql), [USP_EnqueueWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueWork.md).

<!-- Source/Vertrag SHA256: fd66c04ec8076cbf6bc949ddb7d34ba74be0e937cd7cd9063aed14b647a6264a -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer Name eines aktiven Work Types. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei JSON_PAYLOAD ein JSON-Objekt mit höchstens 64 KiB; bei NONE ausschließlich NULL. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Statuszeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='demo.json', @PayloadJson=N'{"value":1}';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;
```

## toolbelt_core.USP_EnqueueWorkWithPolicy

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.

Vertrag und Quelle: [USP_EnqueueWorkWithPolicy.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql), [USP_EnqueueWorkWithPolicy.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueWorkWithPolicy.md).

<!-- Source/Vertrag SHA256: a01b8d42fe30f4bfdc5776958d890d598d5976b960ce0aedb440da27b1d538ce -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | JSON-Objekt-Payload gemäß dem registrierten Handlervertrag. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler binär verglichener Schlüssel, je Work Type eindeutig solange das Item existiert. |
| `@Priority` | `tinyint` | `0` | Input | 0–255; höhere Priorität wird zuerst berücksichtigt. |
| `@ExecutionGroup` | `varchar(128)` | `'default'` | Input | Binär verglichene Queuegruppe; Barriers beziehen sich auf diese Gruppe. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Maximale Versuchszahl der gespeicherten Retrypolicy. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Basis des exponentiellen Retry-Backoffs. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Obergrenze des Retry-Backoffs. |
| `@ExecutionMode` | `varchar(16)` | `'SHARED'` | Input | SHARED oder DRAIN_BARRIER gemäß Queuevertrag. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: aktiver, ausführbarer Work Type demo.noop.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @IdempotencyKey=N'example-1',
 @Priority=10, @ExecutionGroup=N'example-group', @MaxAttempts=3,
 @RetryBaseDelaySeconds=60, @RetryMaxDelaySeconds=3600, @ExecutionMode='SHARED';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;
```

## toolbelt_core.USP_EnqueueBarrierWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht DRAIN_BARRIER-Arbeit ein, die vor ihrem exklusiven Claim die relevanten aktiven Claims derselben ExecutionGroup abwartet; Retry-Policy und optionaler Idempotency Key bleiben gebunden.

Vertrag und Quelle: [USP_EnqueueBarrierWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueBarrierWork.sql), [USP_EnqueueBarrierWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueBarrierWork.md).

<!-- Source/Vertrag SHA256: 441b6f7c5fcafcb503da820073dfc2cf25841efc3dd05b21f9255d6db54323f0 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | JSON-Objekt-Payload gemäß dem registrierten Handlervertrag. |
| `@ExecutionGroup` | `varchar(128)` | `NULL` | Input | Binär verglichene Queuegruppe; Barriers beziehen sich auf diese Gruppe. |
| `@Priority` | `tinyint` | `NULL` | Input | 0–255; höhere Priorität wird zuerst berücksichtigt. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler binär verglichener Schlüssel, je Work Type eindeutig solange das Item existiert. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Maximale Versuchszahl der gespeicherten Retrypolicy. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Basis des exponentiellen Retry-Backoffs. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Obergrenze des Retry-Backoffs. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: registrierter passender Handler; Barrier hat Seiteneffekte auf Claims.
EXEC toolbelt_core.USP_EnqueueBarrierWork
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @ExecutionGroup=N'example-group', @Priority=10;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnqueueBarrierWork @Hilfe=1;
```

## toolbelt_core.USP_ClaimWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.

Vertrag und Quelle: [USP_ClaimWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_ClaimWork.sql), [USP_ClaimWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_ClaimWork.md).

<!-- Source/Vertrag SHA256: 62a8590a781103bd7d55784c63bf468de4541af8474cde8d6cf7ba1f3a2963ab -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeaseDurationSeconds` | `int` | `300` | Input | Lease-Dauer von 5 bis 86400 Sekunden. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Claim-Zeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;
```

## toolbelt_core.USP_RenewWorkLease

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.

Vertrag und Quelle: [USP_RenewWorkLease.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RenewWorkLease.sql), [USP_RenewWorkLease.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_RenewWorkLease.md).

<!-- Source/Vertrag SHA256: 65e4d3e7fdbfceda19e89b96ad774d7741a062be02750141570b14fbfc74efaa -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eindeutige Queue-ID. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Geheimes Ownership-Token des aktiven Claims. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Lease-Zeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken='00000000-0000-0000-0000-000000000001';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;
```

## toolbelt_core.USP_RecoverExpiredWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.

Vertrag und Quelle: [USP_RecoverExpiredWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RecoverExpiredWork.sql), [USP_RecoverExpiredWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_RecoverExpiredWork.md).

<!-- Source/Vertrag SHA256: 61ce358eb73574e5809d97d2e2e99157ba6d9a22dffcf966fb22b6575c9ee04d -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MaxItems` | `int` | `100` | Input | Batchgrenze von 1 bis 1000. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für recoverte Items. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;
```

## toolbelt_core.USP_CompleteWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert.

Vertrag und Quelle: [USP_CompleteWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_CompleteWork.sql), [USP_CompleteWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_CompleteWork.md).

<!-- Source/Vertrag SHA256: 8ea9b5d9e419d227e7a264f79ee21731aeacfba18ea04b00834fdfd3f72cab14 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eindeutige Queue-ID. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Vom erfolgreichen Claim zurückgegebenes Ownership-Token. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Statuszeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1, @ClaimToken='00000000-0000-0000-0000-000000000001';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;
```

## toolbelt_core.USP_FailWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Schließt genau ein CLAIMED Work Item mit passendem ClaimToken als FAILED ab. Gespeichert werden nur ein stabiler Code und eine optionale bereinigte Kurzmeldung.

Vertrag und Quelle: [USP_FailWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_FailWork.sql), [USP_FailWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_FailWork.md).

<!-- Source/Vertrag SHA256: 73b4e6a2f792eac322ec1f55c68e36aaffdacc28ad2f1f7ef0a4e683ece37ef5 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eindeutige Queue-ID. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Vom Claim zurückgegebenes Ownership-Token. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Case-sensitiver ASCII-Code aus Buchstaben, Ziffern, Punkt, Unterstrich und Bindestrich. |
| `@FailureMessage` | `nvarchar(max)` | `NULL` | Input | Vom Aufrufer bereinigte Meldung mit höchstens 1000 Unicode-Codeeinheiten; keine Logs oder Stack Traces. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Statuszeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_FailWork @WorkItemId=1,@ClaimToken='00000000-0000-0000-0000-000000000001',@FailureCode='DEMO.ERROR';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_FailWork @Hilfe=1;
```

## toolbelt_core.USP_ScheduleWorkRetry

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Plant einen tokengebundenen Retry oder verschiebt nach Dead Letter.

Vertrag und Quelle: [USP_ScheduleWorkRetry.sql](../../Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetry.sql), [USP_ScheduleWorkRetry.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_ScheduleWorkRetry.md).

<!-- Source/Vertrag SHA256: 30938ccfab83ea56056c30358a566fbe76b99858e6511df2f2ca4f04d8eb123d -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | ID des tatsächlich angelegten Work Items. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Das tatsächlich vom Claim zurückgelieferte Token; kein frei erfundenes Token. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Stabiler ASCII-Fehlercode des Workers. |
| `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Bereinigter Worker-Fehlertext, höchstens 1000 Unicode-Codeeinheiten. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- ID und Token stammen aus dem eigenen aktuellen Claim.
DECLARE @WorkItemId bigint=NULL, @ClaimToken uniqueidentifier=NULL; -- tatsächliche Claimwerte einsetzen
EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@WorkItemId, @ClaimToken=@ClaimToken,
 @FailureCode='EXAMPLE_RETRY', @FailureMessage=N'Synthetischer Testfehler';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;
```

## toolbelt_core.USP_RequeueDeadLetter

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.

Vertrag und Quelle: [USP_RequeueDeadLetter.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql), [USP_RequeueDeadLetter.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_RequeueDeadLetter.md).

<!-- Source/Vertrag SHA256: 69923ae79c2bd33665efa27f6d444d7b7b9065199d0928f3fa93f8825f0f0574 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | ID des tatsächlich angelegten Work Items. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Erwartete rowversion zur optimistischen Konkurrenzprüfung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Grund für den neuen Retryzyklus eines DEAD_LETTER-Items. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Eine tatsächliche eigene DEAD_LETTER-ID einsetzen.
DECLARE @WorkItemId bigint=NULL;
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@WorkItemId, @RequeueReason=N'Synthetischer Wiederholungsversuch';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;
```

## toolbelt_core.USP_GetWorkStatus

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt.

Vertrag und Quelle: [USP_GetWorkStatus.sql](../../Modules/toolbelt.core.work-queue/Source/USP_GetWorkStatus.sql), [USP_GetWorkStatus.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_GetWorkStatus.md).

<!-- Source/Vertrag SHA256: 293b2e8bdd764159f9d1775c3c7dec6a0738534403cd6d3b91ee7196ca56272d -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eindeutige Queue-ID. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Statuszeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;
```

## toolbelt_core.USP_SetWorkTypePermission

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal.

Vertrag und Quelle: [USP_SetWorkTypePermission.sql](../../Modules/toolbelt.core.work-type/Source/USP_SetWorkTypePermission.sql), [USP_SetWorkTypePermission.md](../../Modules/toolbelt.core.work-type/Documentation/USP_SetWorkTypePermission.md).

<!-- Source/Vertrag SHA256: 36bcbad73e616561effd40af4f54986f38f5aff552a3725002d4cc3de8e1853e -->

Voraussetzung: Work-Type-Katalog 1.2.0, vorhandener Work Type und vorhandener Datenbankprincipal.

Voraussetzung: EXECUTE sowie CONTROL auf toolbelt_core.WorkTypePermission; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Vorhandener kanonischer Work Type. |
| `@Principal` | `sysname` | `NULL` | Input | Vorhandener Datenbankbenutzer oder Datenbankrolle. |
| `@PermissionName` | `varchar(32)` | `NULL` | Input | ENQUEUE, CLAIM oder EXECUTE_NEW_SESSION. |
| `@PermissionState` | `varchar(8)` | `'ALLOW'` | Input | ALLOW, DENY oder REMOVE; gültiges DENY hat Vorrang. |
| `@Debug` | `tinyint` | `0` | Input | Optionale Fortschrittsmeldung ohne fachliches Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Nur Help ohne Seiteneffekt. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='demo.noop', @Principal=N'ContosoProducer', @PermissionName='ENQUEUE', @PermissionState='ALLOW';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
```

## toolbelt_core.VW_WorkTypes

Modul `toolbelt.core.work-type` · Version `1.2.0` · `VIEW`

Zeigt registrierte Work Types und deren Konfiguration.

Vertrag und Quelle: [VW_WorkTypes.sql](../../Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql), [VW_WorkTypes.md](../../Modules/toolbelt.core.work-type/Documentation/VW_WorkTypes.md).

<!-- Source/Vertrag SHA256: e8836468eb2ce2565c1e3861168680b87128b0aa4b23e80cb3e795da6090da51 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkTypes;
```

## toolbelt_core.USP_RegisterWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.

Vertrag und Quelle: [USP_RegisterWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_RegisterWorkType.sql), [USP_RegisterWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_RegisterWorkType.md).

<!-- Source/Vertrag SHA256: 780ffc1fdd14dd35364f87f5f72b77b299c8dac875dbd887cf216962068bd5e7 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer kleingeschriebener Work-Type-Name. |
| `@HandlerSchema` | `sysname` | `NULL` | Input | Schema der vorhandenen Zielprocedure in derselben Datenbank. |
| `@HandlerProcedure` | `sysname` | `NULL` | Input | Name der vorhandenen Zielprocedure. |
| `@ParameterMode` | `varchar(16)` | `'NONE'` | Input | NONE oder JSON_PAYLOAD. |
| `@PayloadContractJson` | `nvarchar(4000)` | `NULL` | Input | JSON-Objekt mit deklarativem Payloadvertrag; wird nicht als Code ausgeführt. |
| `@DefaultTimeoutSeconds` | `int` | `300` | Input | Standardtimeout des registrierten Work Types. |
| `@IsIdempotent` | `bit` | `0` | Input | Deklarative Handlerkennzeichnung; ersetzt keine fachliche Idempotenzimplementierung. |
| `@Description` | `nvarchar(1000)` | `NULL` | Input | Beschreibung des registrierten Work Types. |
| `@AllowUpdate` | `bit` | `0` | Input | Erlaubt eine Änderung einer vorhandenen Registrierung. |
| `@Reactivate` | `bit` | `0` | Input | Reaktiviert einen deaktivierten Work Type. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionale Optimistic-Concurrency-Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Ergebniszeile. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='demo.noop', @HandlerSchema=N'dbo', @HandlerProcedure=N'USP_DemoNoop';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
```

## toolbelt_core.USP_DisableWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.

Vertrag und Quelle: [USP_DisableWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_DisableWorkType.sql), [USP_DisableWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_DisableWorkType.md).

<!-- Source/Vertrag SHA256: 2632d8e6b556e1bf984cae24e69b412e5ae6cd07020290a24c63a0aa574c6639 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@DisabledReason` | `nvarchar(1000)` | `NULL` | Input | Grund für die Deaktivierung. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Erwartete rowversion zur optimistischen Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='demo.noop';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DisableWorkType @Hilfe=1;
```

## toolbelt_core.USP_RemoveWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.

Vertrag und Quelle: [USP_RemoveWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_RemoveWorkType.sql), [USP_RemoveWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_RemoveWorkType.md).

<!-- Source/Vertrag SHA256: 74b42c3075ece6b9d1f228d0ed3a544754e4d44f4014003efee8ea9dd2715c4a -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer Name des zu entfernenden Work Types. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionale Optimistic-Concurrency-Prüfung. |
| `@AllowDelete` | `bit` | `0` | Input | Muss für die irreversible Entfernung ausdrücklich 1 sein. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die entfernte Katalogzeile. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='demo.noop', @AllowDelete=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RemoveWorkType @Hilfe=1;
```

## toolbelt_core.USP_ResolveWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.

Vertrag und Quelle: [USP_ResolveWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_ResolveWorkType.sql), [USP_ResolveWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_ResolveWorkType.md).

<!-- Source/Vertrag SHA256: 5bb07f5a026eb5758489cd84f65836a64962547c48447407b4a5dacf5a5bbe46 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@RequireEnabled` | `bit` | `1` | Input | 1 verlangt einen aktiven Work Type. |
| `@RequireExecutableByCaller` | `bit` | `1` | Input | 1 prüft die vorhandene Ausführbarkeit des Handlers. |
| `@RequiredPermission` | `varchar(32)` | `NULL` | Input | Optionale Work-Type-Policyaktion; NULL prüft keine zusätzliche Policy. |
| `@SuppressResult` | `bit` | `0` | Input | 1 prüft ohne Fachresultset; nicht mit ResultTable kombinieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='demo.noop';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ResolveWorkType @Hilfe=1;
```

## toolbelt_core.VW_WorkerStatus

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `VIEW`

Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads.

Vertrag und Quelle: [VW_WorkerStatus.sql](../../Modules/toolbelt.core.worker-control/Source/VW_WorkerStatus.sql), [VW_WorkerStatus.md](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerStatus.md).

<!-- Source/Vertrag SHA256: fce2ae24f2a6fec3ebcb40157964e668b05c701c0ec84a303291b3664a30095d -->

Voraussetzung: Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkerStatus;
```

## toolbelt_core.VW_WorkerExecutionStatus

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `VIEW`

Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads.

Vertrag und Quelle: [VW_WorkerExecutionStatus.sql](../../Modules/toolbelt.core.worker-control/Source/VW_WorkerExecutionStatus.sql), [VW_WorkerExecutionStatus.md](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerExecutionStatus.md).

<!-- Source/Vertrag SHA256: ed123f96edbd5483200d3ce09f8e242c21c8e7a9dec71166536a36b9acdf7fd3 -->

Voraussetzung: Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkerExecutionStatus;
```

## toolbelt_core.USP_ClaimWorkerWork

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Fachliche Fassade der privaten atomaren Managed-Admission.

Vertrag und Quelle: [USP_ClaimWorkerWork.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ClaimWorkerWork.sql), [USP_ClaimWorkerWork.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ClaimWorkerWork.md).

<!-- Source/Vertrag SHA256: 000f8b6a5a22030a7547820aba841a7b3282057d06b45d85989995acee334551 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Privates Token aus derselben Registrierung; nicht protokollieren oder veröffentlichen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;
```

## toolbelt_core.USP_CloseWorker

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Schließt ausschließlich eine Generation ohne belegte oder ungeklärte Reservations.

Vertrag und Quelle: [USP_CloseWorker.sql](../../Modules/toolbelt.core.worker-control/Source/USP_CloseWorker.sql), [USP_CloseWorker.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_CloseWorker.md).

<!-- Source/Vertrag SHA256: fdce9effcbb12ca47a4ac063d02d81ad8bd0eac4d4c5a5b93ce3ae8a7491c27a -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Privates Token aus derselben Registrierung; nicht protokollieren oder veröffentlichen. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_CloseWorker @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_CloseWorker @Hilfe=1;
```

## toolbelt_core.USP_DisableManagedWorkers

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Wechselt Managedbetrieb versionsgebunden nur ohne Claims, Reservations oder ungeklärte Holds.

Vertrag und Quelle: [USP_DisableManagedWorkers.sql](../../Modules/toolbelt.core.worker-control/Source/USP_DisableManagedWorkers.sql), [USP_DisableManagedWorkers.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_DisableManagedWorkers.md).

<!-- Source/Vertrag SHA256: 4a3e25e680f9288d5ee815146f8f6751f6bc8a81c1f6f2280164a58f3b3f8e2d -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Konfigurationsversion; veraltete Werte blockieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_DisableManagedWorkers @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DisableManagedWorkers @Hilfe=1;
```

## toolbelt_core.USP_EnableManagedWorkers

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Wechselt Managedbetrieb versionsgebunden nur ohne Claims, Reservations oder ungeklärte Holds.

Vertrag und Quelle: [USP_EnableManagedWorkers.sql](../../Modules/toolbelt.core.worker-control/Source/USP_EnableManagedWorkers.sql), [USP_EnableManagedWorkers.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_EnableManagedWorkers.md).

<!-- Source/Vertrag SHA256: 38333095be280155cba2f9fcb7bff4efaffbc904e3ef669774feb45e7658a432 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Konfigurationsversion; veraltete Werte blockieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_EnableManagedWorkers @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnableManagedWorkers @Hilfe=1;
```

## toolbelt_core.USP_HeartbeatWorker

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Erneuert ausschließlich die aktuelle lebende Workergeneration ohne Claims zu übernehmen.

Vertrag und Quelle: [USP_HeartbeatWorker.sql](../../Modules/toolbelt.core.worker-control/Source/USP_HeartbeatWorker.sql), [USP_HeartbeatWorker.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_HeartbeatWorker.md).

<!-- Source/Vertrag SHA256: af9433a305ba1e5f6ef6a31b77fa42abac5226d227ae7d594ef4612a454582ca -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Privates Token aus derselben Registrierung; nicht protokollieren oder veröffentlichen. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
```

## toolbelt_core.USP_ReconcileWorkerExecution

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.

Vertrag und Quelle: [USP_ReconcileWorkerExecution.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ReconcileWorkerExecution.sql), [USP_ReconcileWorkerExecution.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ReconcileWorkerExecution.md).

<!-- Source/Vertrag SHA256: 6de4d325cc766beda9f917fefbfb7fd8882392799589013286f002b926fbf544 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | Exakte eigene Reservation; niemals eine Sessionnummer. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Holdversion; keine Übertragung auf Folgeclaims. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;
```

## toolbelt_core.USP_RegisterWorker

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Registriert eine neue principal- und generationgebundene Workeridentität; übernimmt keine alten Reservations.

Vertrag und Quelle: [USP_RegisterWorker.sql](../../Modules/toolbelt.core.worker-control/Source/USP_RegisterWorker.sql), [USP_RegisterWorker.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_RegisterWorker.md).

<!-- Source/Vertrag SHA256: 32044981d0549a36894e90739d5969bb59507f3673d31dc681368b002571b1f8 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@Capacity` | `int` | `NULL` | Input | Lokales positives int-Budget, zur Laufzeit steuerbar; keine Kapazitätszusage. |
| `@RunMode` | `varchar(16)` | `'BOUNDED'` | Input | BOUNDED oder ausdrücklich CONTINUOUS; Default BOUNDED. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;
```

## toolbelt_core.USP_ReleaseHeldWork

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Beginnt ausschließlich nach bewiesenem Rollback eine explizite neue Retryphase; UNKNOWN und COMPLETED bleiben gesperrt.

Vertrag und Quelle: [USP_ReleaseHeldWork.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ReleaseHeldWork.sql), [USP_ReleaseHeldWork.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ReleaseHeldWork.md).

<!-- Source/Vertrag SHA256: 119121a3e56e564c511348d99f5fc745612e6983ef8d740ffce8e5dcd60337fc -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eigene gehaltene Queuezeile; Wiederholung bleibt ausdrücklich gesteuert. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Holdversion; keine Übertragung auf Folgeclaims. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerCapacity

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Ändert die Live-Capacity einer exakten Workergeneration ohne Übernahme oder Abbruch laufender Arbeit.

Vertrag und Quelle: [USP_SetWorkerCapacity.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerCapacity.sql), [USP_SetWorkerCapacity.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerCapacity.md).

<!-- Source/Vertrag SHA256: 9898ea96bcd0cda99cb883b9fdf9dedb641b38dae12af431f1715dc3eb814bf8 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@Capacity` | `int` | `NULL` | Input | Lokales positives int-Budget, zur Laufzeit steuerbar; keine Kapazitätszusage. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Konfigurationsversion; veraltete Werte blockieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_SetWorkerCapacity @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerCapacity @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerConcurrency

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Ändert das globale Live-Admissionbudget versionsgebunden ohne laufende Arbeit abzubrechen.

Vertrag und Quelle: [USP_SetWorkerConcurrency.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerConcurrency.sql), [USP_SetWorkerConcurrency.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerConcurrency.md).

<!-- Source/Vertrag SHA256: c97f6dde0df4784b3d07b01162b381cdf9ff4b4c2302cd98229231e96b324239 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MaxConcurrentExecutions` | `int` | `NULL` | Input | Globales int-Budget 0 bis 2147483647; 0 pausiert neue Admission. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Konfigurationsversion; veraltete Werte blockieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerIntervals

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Ändert Intervalldefaults ausschließlich für künftig registrierte Generationen.

Vertrag und Quelle: [USP_SetWorkerIntervals.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerIntervals.sql), [USP_SetWorkerIntervals.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerIntervals.md).

<!-- Source/Vertrag SHA256: 8ecfca63578a24713d9cb7bfdcdde8b15f18a9242df7426ac7f79c6375f8ec4e -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@HeartbeatSeconds` | `int` | `NULL` | Input | 1 bis 3600 Sekunden; Default 15. Änderungen gelten für neue Generationen. |
| `@UnreachableSeconds` | `int` | `NULL` | Input | 3 bis 86400 Sekunden, mindestens dreimal HeartbeatSeconds; Default 60. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Konfigurationsversion; veraltete Werte blockieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerState

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Steuert ACTIVE, PAUSED oder DRAINING einer exakten lebenden Workergeneration.

Vertrag und Quelle: [USP_SetWorkerState.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerState.sql), [USP_SetWorkerState.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerState.md).

<!-- Source/Vertrag SHA256: 052ca61b5f8204e02a8284db191910d57a129647b52b6ea098dffd2515d7f31c -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@RequestedState` | `varchar(16)` | `NULL` | Input | Expliziter administrativer Übergang gemäß Worker-Control-Zustandsvertrag. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Konfigurationsversion; veraltete Werte blockieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;
```

## toolbelt_core.USP_StopWorkerExecution

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Persistiert generationgebunden Stop und Hold vor Providerabbruch; Completiongewinner bleibt committed.

Vertrag und Quelle: [USP_StopWorkerExecution.sql](../../Modules/toolbelt.core.worker-control/Source/USP_StopWorkerExecution.sql), [USP_StopWorkerExecution.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_StopWorkerExecution.md).

<!-- Source/Vertrag SHA256: 4e578eed57f0e23fb616638f29500148adfa9c74b4ed16c1eef53f5b135d9b84 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | Exakte eigene Reservation; niemals eine Sessionnummer. |
| `@ExpectedClaimGeneration` | `bigint` | `NULL` | Input | Exakte Claim-Generation der ausgewählten Verarbeitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;
```

## toolbelt_core.USP_StopWorkers

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen.

Vertrag und Quelle: [USP_StopWorkers.sql](../../Modules/toolbelt.core.worker-control/Source/USP_StopWorkers.sql), [USP_StopWorkers.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_StopWorkers.md).

<!-- Source/Vertrag SHA256: 8aa2c4a78c8857128813517f7a51945ad6e1f2a222673381bcd5ddced97687e3 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Input | Vorhandene lokale Temp-Tabelle mit WorkerId uniqueidentifier NOT NULL und WorkerGeneration bigint NOT NULL. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
```

## toolbelt_datetime.TVF_DateBucketDate

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen date-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDate.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDate.sql), [TVF_DateBucketDate.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDate.md).

<!-- Source/Vertrag SHA256: 3f43365d6804138e415d1aadb3781c44e79c7f07b0ab1b0399c2002c833950b0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Width` | `int` | `kein Default` | Input | Positive ganzzahlige Bucketbreite. |
| `@Value` | `date` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Origin` | `date` | `'19000101'` | Input | Zeitlicher Referenzpunkt für die Bucket-Grenzen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDate('day', 7, CONVERT(date,'2024-07-19'), CONVERT(date,'2024-01-01'));
```

## toolbelt_datetime.TVF_DateBucketDateTime2

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen datetime2-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDateTime2.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTime2.sql), [TVF_DateBucketDateTime2.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTime2.md).

<!-- Source/Vertrag SHA256: 0f197a59f21956550da7164918228419d13b567916973d2acddfd5e9327a8fd9 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Width` | `int` | `kein Default` | Input | Positive ganzzahlige Bucketbreite. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Origin` | `datetime2(7)` | `'19000101'` | Input | Zeitlicher Referenzpunkt für die Bucket-Grenzen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTime2('day', 7, CONVERT(datetime2(7),'2024-07-19T14:35:42'), CONVERT(datetime2(7),'2024-01-01'));
```

## toolbelt_datetime.TVF_DateBucketDateTimeOffset

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDateTimeOffset.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTimeOffset.sql), [TVF_DateBucketDateTimeOffset.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTimeOffset.md).

<!-- Source/Vertrag SHA256: b8b56f08d0fcc0d9e4b229b005f95b10b79ff8e3c25a8242442c9f27662dfb5d -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Width` | `int` | `kein Default` | Input | Positive ganzzahlige Bucketbreite. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Origin` | `datetimeoffset(7)` | `'1900-01-01 00:00:00 +00:00'` | Input | Zeitlicher Referenzpunkt für die Bucket-Grenzen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset('day', 7, CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'), CONVERT(datetimeoffset(7),'2024-01-01'));
```

## toolbelt_datetime.TVF_CalendarDifference

Modul `toolbelt.datetime.calendar-difference` · Version `1.0.0` · `TVF`

Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage.

Vertrag und Quelle: [TVF_CalendarDifference.sql](../../Modules/toolbelt.datetime.calendar-difference/Source/TVF_CalendarDifference.sql), [TVF_CalendarDifference.md](../../Modules/toolbelt.datetime.calendar-difference/Documentation/TVF_CalendarDifference.md).

<!-- Source/Vertrag SHA256: cb9eea5da871f4d3ccf877944b71dc6ddef036eadcd940dc1f04526794553a10 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StartDate` | `date` | `kein Default` | Input | Startdatum des Intervalls. |
| `@EndDate` | `date` | `kein Default` | Input | Enddatum des Intervalls. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_CalendarDifference(CONVERT(date,'2024-01-31'), CONVERT(date,'2025-03-02'));
```

## toolbelt_datetime.TVF_DateSpineDay

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle Tage, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineDay.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineDay.sql), [TVF_DateSpineDay.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineDay.md).

<!-- Source/Vertrag SHA256: 2ba00fa0c93cf98c2e8476a042ffcf28d69f3ac670084f7d812486ba8ffb85af -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | Einschließliche untere Intervallgrenze. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | Ausschließliche obere Intervallgrenze. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateSpineDay(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
```

## toolbelt_datetime.TVF_DateSpineIsoWeek

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle ISO-Wochen, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineIsoWeek.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineIsoWeek.sql), [TVF_DateSpineIsoWeek.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineIsoWeek.md).

<!-- Source/Vertrag SHA256: 71bc6913525c785d157b9044e51c627c50df460e3ae23c82453ae72cf4b65645 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | Einschließliche untere Intervallgrenze. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | Ausschließliche obere Intervallgrenze. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateSpineIsoWeek(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
```

## toolbelt_datetime.TVF_DateSpineMonth

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle Monate, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineMonth.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineMonth.sql), [TVF_DateSpineMonth.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineMonth.md).

<!-- Source/Vertrag SHA256: 3afa16be72cd69bdf2e500965971160239db6f9785f61f674c54a00fd25f87a4 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | Einschließliche untere Intervallgrenze. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | Ausschließliche obere Intervallgrenze. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateSpineMonth(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
```

## toolbelt_datetime.TVF_TruncateDate

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen date-Wert auf den Beginn der ausgewählten Kalenderperiode.

Vertrag und Quelle: [TVF_TruncateDate.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDate.sql), [TVF_TruncateDate.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDate.md).

<!-- Source/Vertrag SHA256: 42dcd11813baad7020af0ac4c42078b10ebcd74682e55043b19b1ac2333ac730 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Value` | `date` | `kein Default` | Input | Eingabedatum im SQL-Typ date. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDate('day', CONVERT(date,'2024-07-19'));
```

## toolbelt_datetime.TVF_TruncateDateTime2

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen datetime2-Wert auf den Beginn der gewählten Zeiteinheit.

Vertrag und Quelle: [TVF_TruncateDateTime2.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTime2.sql), [TVF_TruncateDateTime2.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTime2.md).

<!-- Source/Vertrag SHA256: dd6175063c316949926535d5a8546267a7c8553c97ca85c8d897e370f50b4abf -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTime2('day', CONVERT(datetime2(7),'2024-07-19T14:35:42'));
```

## toolbelt_datetime.TVF_TruncateDateTimeOffset

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset.

Vertrag und Quelle: [TVF_TruncateDateTimeOffset.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTimeOffset.sql), [TVF_TruncateDateTimeOffset.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTimeOffset.md).

<!-- Source/Vertrag SHA256: 54983d9419b54b1516ceb49b805a217431d173fc51ab9e32dea13f058dceca9b -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTimeOffset('day', CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'));
```

## toolbelt_file.USP_LoadBinaryFile

Modul `toolbelt.file.content` · Version `1.0.0` · `USP`

Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.

Vertrag und Quelle: [USP_LoadBinaryFile.sql](../../Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql), [USP_LoadBinaryFile.md](../../Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md).

<!-- Source/Vertrag SHA256: aa548b1de2ba444172c777977900ecd55859a8ffb6b868c86bae64bad21220eb -->

Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Pfad zur Datei. UNC-Pfade sind erlaubt. Relative Pfade, ..-Segmente und Pfade außerhalb der Allowlist werden abgelehnt. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionales Limit. Wenn die gelesene Datei mehr Bytes enthält, wird ein Validierungsfehler zurückgegeben, der Inhalt bleibt jedoch NULL. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionaler Name einer lokalen Temp-Tabelle für die Ergebniszeile. Erfordert toolbelt.core.result-table ab Version 1.0.0. |
| `@KeepData` | `bit` | `0` | Input | Wirkt mit @ResultTable: 1 erhält vorhandene Zeilen; 0 ersetzt Inhalt und Shape gemäß ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Diagnosemeldungen des ResultTable-Helpers beim Routing; erzeugt keine zusätzlichen fachlichen Resultsets. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus und ignoriert die übrigen Parameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: passende Allowlist und eigene synthetische Datei.
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=N'C:\ExampleRoot\sample.bin', @MaxBytes=1048576;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_LoadBinaryFile @Hilfe=1;
```

## toolbelt_file.USP_LoadTextFile

Modul `toolbelt.file.content` · Version `1.0.0` · `USP`

Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen.

Vertrag und Quelle: [USP_LoadTextFile.sql](../../Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql), [USP_LoadTextFile.md](../../Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md).

<!-- Source/Vertrag SHA256: b339d9b2c364edb69b3aeb4c18215fb4e624d17c0efbb045fdbb0802dbb93eab -->

Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Pfad zur Datei. UNC-Pfade sind erlaubt. Relative Pfade, ..-Segmente und Pfade außerhalb der Allowlist werden abgelehnt. |
| `@FallbackEncoding` | `nvarchar(128)` | `N'Windows-1252'` | Input | Codepage für Dateien ohne BOM. Unterstützt werden Windows-1252 und SQL_Latin1_General_CP1_CI_AS äquivalente 8-Bit-Codepages. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionales Limit. Wenn die gelesene Datei mehr Bytes enthält, wird ein Validierungsfehler zurückgegeben, der Inhalt bleibt jedoch NULL. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionaler Name einer lokalen Temp-Tabelle für die Ergebniszeile. Erfordert toolbelt.core.result-table ab Version 1.0.0. |
| `@KeepData` | `bit` | `0` | Input | Wirkt mit @ResultTable: 1 erhält vorhandene Zeilen; 0 ersetzt Inhalt und Shape gemäß ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Diagnosemeldungen des ResultTable-Helpers beim Routing; erzeugt keine zusätzlichen fachlichen Resultsets. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus und ignoriert die übrigen Parameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: passende Allowlist und eigene synthetische Datei.
EXEC toolbelt_file.USP_LoadTextFile @FilePath=N'C:\ExampleRoot\sample.txt', @MaxBytes=1048576;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_LoadTextFile @Hilfe=1;
```

## toolbelt_file.USP_ParseCsv

Modul `toolbelt.file.csv-memory` · Version `1.0.0` · `USP`

Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle.

Vertrag und Quelle: [USP_ParseCsv.sql](../../Modules/toolbelt.file.csv-memory/Source/USP_ParseCsv.sql), [USP_ParseCsv.md](../../Modules/toolbelt.file.csv-memory/Documentation/USP_ParseCsv.md).

<!-- Source/Vertrag SHA256: dd515d3b5904687bbdc559eef4c9923022877249d0cea30a242e9e8e39f7144a -->

Voraussetzung: Vorhandener SAFE-Provider und bei Routing sameDB-ResultTable-Helper.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `NULL` | Input | Vollständiger Unicode-Text; SQL-NULL ist Argumentfehler, leer ergibt keine Zellen. |
| `@Separator` | `nvarchar(2)` | `N','` | Input | Exakt eine UTF16-Einheit außer Quote, CR, LF, NUL und Surrogate. |
| `@HasHeader` | `bit` | `0` | Input | 0 ohne Header; 1 genau ein Headerrecord; NULL ist Argumentfehler. |
| `@NullToken` | `nvarchar(128)` | `NULL` | Input | Optional: exakt unquoted DATA-Token ergibt SQL-NULL; quoted Token bleibt Text. |
| `@MaxRows` | `bigint` | `100000` | Input | Positive absenkbare Grenze höchstens100000 DATA-Records. |
| `@MaxColumns` | `int` | `1024` | Input | Positive absenkbare Grenze höchstens1024 Spalten pro Record. |
| `@MaxCells` | `bigint` | `1000000` | Input | Positive absenkbare Grenze höchstens1000000 HEADER+DATA-Zellen. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | UTF16-Textbytes einschließlich Header, Quotes und Separatoren; höchstens16777216. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL gibt genau ein Resultset aus, sonst vorhandene caller-lokale Temp-Tabelle ohne Resultset. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append nach dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages; keine zusätzlichen Resultsets oder Payloads. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich Standardhilfe aus und umgeht sämtliche fachlichen Prüfungen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_file.USP_ParseCsv @Text=N'a,b',@NullToken=N'NULL';
```

Hilfe:

```sql
EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
```

## toolbelt_file.USP_WriteCsv

Modul `toolbelt.file.csv-memory` · Version `1.0.0` · `USP`

Schreibt einen read-only Snapshot vier typgenauer caller-lokaler Temp-Spalten als vollständig budgetiertes CSV.

Vertrag und Quelle: [USP_WriteCsv.sql](../../Modules/toolbelt.file.csv-memory/Source/USP_WriteCsv.sql), [USP_WriteCsv.md](../../Modules/toolbelt.file.csv-memory/Documentation/USP_WriteCsv.md).

<!-- Source/Vertrag SHA256: d9bd52950f9c6d5c214e9dad59d45a3f4d09f8611120085a2e981d4bfe3302a8 -->

Voraussetzung: Vorhandener SAFE-Provider; Quelle ist keine ResultTable und bleibt unverändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@CellsTable` | `sysname` | `NULL` | Input | Genau RowKind varchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max), eingebaute Typen. |
| `@Separator` | `nvarchar(2)` | `N','` | Input | Exakt eine UTF16-Einheit außer Quote, CR, LF, NUL und Surrogate. |
| `@HasHeader` | `bit` | `0` | Input | 0 ohne Header; 1 genau ein Headerrecord; NULL ist Argumentfehler. |
| `@NullToken` | `nvarchar(128)` | `NULL` | Input | Ohne Token ist SQL-NULL nicht schreibbar; Header-NULL ist immer Fehler. |
| `@LineEnding` | `varchar(4)` | `'CRLF'` | Input | Exakt CRLF oder LF; jeder Ausgaberecord einschließlich des letzten erhält einen Abschluss. |
| `@MaxRows` | `bigint` | `100000` | Input | Positive absenkbare Grenze höchstens100000 DATA-Records. |
| `@MaxColumns` | `int` | `1024` | Input | Positive absenkbare Grenze höchstens1024 Spalten pro Record. |
| `@MaxCells` | `bigint` | `1000000` | Input | Positive absenkbare Grenze höchstens1000000 HEADER+DATA-Zellen. |
| `@MaxValueBytes` | `bigint` | `16777216` | Input | Summe aller UTF16-Snapshotwerte, NULL zählt0; höchstens16777216. |
| `@MaxOutputBytes` | `bigint` | `16777216` | Input | Vollständige Ausgabe einschließlich Quoting, Separatoren und finalem Recordabschluss; höchstens16777216. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL gibt genau ein Resultset aus, sonst vorhandene caller-lokale Temp-Tabelle ohne Resultset. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append nach dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages; keine zusätzlichen Resultsets oder Payloads. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich Standardhilfe aus und umgeht sämtliche fachlichen Prüfungen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #CsvCells(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,Value nvarchar(max)); INSERT #CsvCells VALUES('DATA',1,1,N'Contoso'); EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCells'; DROP TABLE #CsvCells;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_WriteCsv @Hilfe=1;
```

## toolbelt_file.USP_ListXlsxWorksheets

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `USP`

Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.

Vertrag und Quelle: [USP_ListXlsxWorksheets.sql](../../Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql), [USP_ListXlsxWorksheets.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md).

<!-- Source/Vertrag SHA256: 3bec41c78e9dceb2a491f87765d62db31f50255a90b96562ff6cd6ef59b6af56 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | NULL liefert keine Zeilen und verändert kein ResultTable. |
| `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Containerbytes, höchstens 16 MiB. |
| `@MaxPartBytes` | `bigint` | `16777216` | Input | Unkomprimierte Bytes je Part, höchstens 16 MiB. |
| `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Deklarierte Gesamtbytes, höchstens 64 MiB. |
| `@MaxParts` | `int` | `256` | Input | ZIP-Parts, höchstens 256. |
| `@MaxSheets` | `int` | `32` | Input | Worksheets, höchstens 32. |
| `@MaxCells` | `int` | `100000` | Input | Vorhandene Zellen im gewählten Sheet, höchstens 100000. |
| `@MaxSharedStrings` | `int` | `50000` | Input | Shared Strings, höchstens 50000. |
| `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Dekodierter Shared-String-UTF16-Text, höchstens 8 MiB. |
| `@MaxXmlDepth` | `int` | `64` | Input | XML-Tiefe, höchstens 64. |
| `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | Maximales deklarierter Ratio, höchstens 200. |
| `@BudgetMilliseconds` | `int` | `5000` | Input | Kooperatives Gesamtbudget, höchstens 5000 ms; keine harte Wallclockzusage. |
| `@ResultTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale Temp-Tabelle, sonst SELECT. |
| `@KeepData` | `bit` | `0` | Input | Replace 0 oder Append 1; NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Workbookinhalte. |
| `@Hilfe` | `bit` | `0` | Input | Ausschließlich standardisierte Hilfe. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe = 1;
-- @SyntheticWorkbook stammt ausschließlich aus einem synthetischen Testfixture.
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary = @SyntheticWorkbook;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;
```

## toolbelt_file.USP_ReadXlsxWorksheetCells

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `USP`

Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.

Vertrag und Quelle: [USP_ReadXlsxWorksheetCells.sql](../../Modules/toolbelt.file.xlsx-memory/Source/USP_ReadXlsxWorksheetCells.sql), [USP_ReadXlsxWorksheetCells.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md).

<!-- Source/Vertrag SHA256: 29c053712ebac25845b3b8f0cdb2a2cd04f38eb26b8d64aecc67f033e8a872c0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | NULL liefert keine Zeilen und verändert kein ResultTable. |
| `@SheetOrdinal` | `int` | `NULL` | Input | Positive Worksheetposition aus ListXlsxWorksheets. |
| `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Containerbytes, höchstens 16 MiB. |
| `@MaxPartBytes` | `bigint` | `16777216` | Input | Unkomprimierte Bytes je Part, höchstens 16 MiB. |
| `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Deklarierte Gesamtbytes, höchstens 64 MiB. |
| `@MaxParts` | `int` | `256` | Input | ZIP-Parts, höchstens 256. |
| `@MaxSheets` | `int` | `32` | Input | Worksheets, höchstens 32. |
| `@MaxCells` | `int` | `100000` | Input | Vorhandene Zellen im gewählten Sheet, höchstens 100000. |
| `@MaxSharedStrings` | `int` | `50000` | Input | Shared Strings, höchstens 50000. |
| `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Dekodierter Shared-String-UTF16-Text, höchstens 8 MiB. |
| `@MaxXmlDepth` | `int` | `64` | Input | XML-Tiefe, höchstens 64. |
| `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | Maximales deklarierter Ratio, höchstens 200. |
| `@BudgetMilliseconds` | `int` | `5000` | Input | Kooperatives Gesamtbudget, höchstens 5000 ms; keine harte Wallclockzusage. |
| `@ResultTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale Temp-Tabelle, sonst SELECT. |
| `@KeepData` | `bit` | `0` | Input | Replace 0 oder Append 1; NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Workbookinhalte. |
| `@Hilfe` | `bit` | `0` | Input | Ausschließlich standardisierte Hilfe. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe = 1;
-- @SyntheticWorkbook stammt ausschließlich aus einem synthetischen Testfixture.
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary = @SyntheticWorkbook, @SheetOrdinal = 1;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
```

## toolbelt_file.TVF_InterpretXlsxCell

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `TVF`

Interpretiert den zuvor gelesenen Rohwert einer XLSX-Zelle als begrenzten, typisierten Wert.

Vertrag und Quelle: [TVF_InterpretXlsxCell.sql](../../Modules/toolbelt.file.xlsx-memory/Source/TVF_InterpretXlsxCell.sql), [TVF_InterpretXlsxCell.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/TVF_InterpretXlsxCell.md).

<!-- Source/Vertrag SHA256: b32d7da4f18eba796707d11018fcbf73aa03b4ef9acc968b9cb9a5c26ce88d89 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | XLSX-Raw-Zelltyp, z. B. n, s, inlineStr, b, e oder d. |
| `@ValuePresent` | `bit` | `NULL` | Input | Kennzeichnet, ob der XLSX-Rohwert tatsächlich vorhanden ist. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Rohwert aus der XLSX-Raw-Reader-Ausgabe. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster XLSX-Textwert. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Gewünschte XLSX-Interpretation, z. B. number, text oder date; siehe endlichen Vertrag. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Expliziter unterstützter XLSX-Literalformatcode; siehe endlichen Objektvertrag. |
| `@Date1904` | `bit` | `NULL` | Input | 0 = Excel-Datumssystem 1900; 1 = 1904. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(N'n', 1, N'1.235', NULL, N'number', N'0.00', 0);
```

## toolbelt_file.TVF_FormatXlsxCell

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `TVF`

Formatiert eine XLSX-Einzelzelle mit den unterstützten Literalformaten und Kulturen.

Vertrag und Quelle: [TVF_FormatXlsxCell.sql](../../Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql), [TVF_FormatXlsxCell.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/TVF_FormatXlsxCell.md).

<!-- Source/Vertrag SHA256: a9c47af47704beef0559c0a0e5c8de65f271c4f166c67846da0140cb67daff92 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | XLSX-Raw-Zelltyp, z. B. n, s, inlineStr, b, e oder d. |
| `@ValuePresent` | `bit` | `NULL` | Input | Kennzeichnet, ob der XLSX-Rohwert tatsächlich vorhanden ist. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Rohwert aus der XLSX-Raw-Reader-Ausgabe. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster XLSX-Textwert. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Gewünschte XLSX-Interpretation, z. B. number, text oder date; siehe endlichen Vertrag. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Expliziter unterstützter XLSX-Literalformatcode; siehe endlichen Objektvertrag. |
| `@Date1904` | `bit` | `NULL` | Input | 0 = Excel-Datumssystem 1900; 1 = 1904. |
| `@CultureName` | `nvarchar(max)` | `NULL` | Input | en-US, de-DE oder tr-TR. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(N'n', 1, N'1.235', NULL, N'number', N'0.00', 0, N'de-DE');
```

## toolbelt_filesystem.USP_ReadBinaryFileChunk

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_ReadBinaryFileChunk.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_ReadBinaryFileChunk.md).

<!-- Source/Vertrag SHA256: 70800bb6d0e3c4972613f6d4b637914a04ab8a0fec4fc36a2bd5c35cee77c313 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@ByteOffset` | `bigint` | `0` | Input | Byteoffset für den zu lesenden Chunk. |
| `@MaxBytes` | `int` | `1048576` | Input | Maximale Bytes des einzelnen Leseaufrufs. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.bin', @ByteOffset=0, @MaxBytes=1024, @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe=1;
```

## toolbelt_filesystem.USP_ReadTextFileChunk

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Liest einen begrenzten Text-Chunk mit expliziter Codepage und liefert die nächste Byte-Position.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_ReadTextFileChunk.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_ReadTextFileChunk.md).

<!-- Source/Vertrag SHA256: f69668667fe7a3518334cf22c0a658a7c044954b0ad81122e8d0a52db7a035f7 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@ByteOffset` | `bigint` | `0` | Input | Byteoffset für den zu lesenden Chunk. |
| `@MaxBytes` | `int` | `1048576` | Input | Maximale Bytes des einzelnen Leseaufrufs. |
| `@EncodingName` | `nvarchar(128)` | `NULL` | Input | Encoding gemäß Providervertrag, z. B. utf-8. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadTextFileChunk
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.txt', @ByteOffset=0, @MaxBytes=1024, @EncodingName=N'utf-8', @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @Hilfe=1;
```

## toolbelt_filesystem.USP_WriteBinaryFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Schreibt Binärdaten gestreamt in eine atomar veröffentlichte Zieldatei.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_WriteBinaryFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_WriteBinaryFile.md).

<!-- Source/Vertrag SHA256: fd0f255a349a9b9690db1af073c41326b177fc9b47af4a4c7a5ac4cc7d0b86e7 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@Content` | `varbinary(max)` | `NULL` | Input | Zu schreibender Binary- oder Textinhalt. |
| `@Overwrite` | `bit` | `0` | Input | 0 verweigert Überschreiben vorhandener Dateien; 1 erlaubt es. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteBinaryFile
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.bin', @Content=0x4869, @Overwrite=0, @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_WriteBinaryFile @Hilfe=1;
```

## toolbelt_filesystem.USP_WriteTextFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Schreibt Text gestreamt mit expliziter Codepage und optionalem BOM.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_WriteTextFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_WriteTextFile.md).

<!-- Source/Vertrag SHA256: 93c18cd0fbd80228f3a83349956ca8d7be23b16ae34612d3c3d6b529a755c3ef -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@Content` | `nvarchar(max)` | `NULL` | Input | Zu schreibender Binary- oder Textinhalt. |
| `@EncodingName` | `nvarchar(128)` | `NULL` | Input | Encoding gemäß Providervertrag, z. B. utf-8. |
| `@WriteBom` | `bit` | `0` | Input | 1 schreibt einen BOM soweit das Encoding dies vorsieht; 0 unterdrückt ihn. |
| `@Overwrite` | `bit` | `0` | Input | 0 verweigert Überschreiben vorhandener Dateien; 1 erlaubt es. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteTextFile
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.txt', @Content=N'Contoso', @EncodingName=N'utf-8', @WriteBom=0, @Overwrite=0, @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_WriteTextFile @Hilfe=1;
```

## toolbelt_filesystem.USP_TranscodeTextFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_TranscodeTextFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_TranscodeTextFile.md).

<!-- Source/Vertrag SHA256: 205a6cb4d009f459982c742342688269e49475f49392cd7783a47d9efbd8eaad -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceRootAlias` | `sysname` | `NULL` | Input | Konfigurierter Root-Alias der Quelldatei. |
| `@SourceRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad der Quelldatei. |
| `@SourceEncodingName` | `nvarchar(128)` | `NULL` | Input | Encoding der Quelldatei. |
| `@TargetRootAlias` | `sysname` | `NULL` | Input | Konfigurierter Root-Alias der Zieldatei. |
| `@TargetRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad der Zieldatei. |
| `@TargetEncodingName` | `nvarchar(128)` | `NULL` | Input | Encoding der Zieldatei. |
| `@WriteBom` | `bit` | `0` | Input | 1 schreibt einen BOM soweit das Encoding dies vorsieht; 0 unterdrückt ihn. |
| `@Overwrite` | `bit` | `0` | Input | 0 verweigert Überschreiben vorhandener Dateien; 1 erlaubt es. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_TranscodeTextFile
 @SourceRootAlias=N'ExampleRoot', @SourceRelativePath=N'input.txt', @SourceEncodingName=N'utf-8', @TargetRootAlias=N'ExampleRoot', @TargetRelativePath=N'output.txt', @TargetEncodingName=N'utf-16', @Overwrite=0, @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe=1;
```

## toolbelt_filesystem.USP_ListDirectory

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Listet Verzeichniseinträge unter einem freigegebenen Root mit harten Grenzen.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_ListDirectory.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_ListDirectory.md).

<!-- Source/Vertrag SHA256: c40c008c1dfac0d8d8db774049623e2a6765a8ca9fb6efe2e98f9d06a2ff7a18 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `N''` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@Recursive` | `bit` | `0` | Input | 1 arbeitet rekursiv, 0 nur im gewählten Verzeichnis. |
| `@MaxDepth` | `int` | `32` | Input | Maximale rekursive Verzeichnistiefe. |
| `@MaxEntries` | `int` | `10000` | Input | Maximale Anzahl zu bearbeitender Einträge. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ListDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'', @Recursive=0, @MaxEntries=100, @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe=1;
```

## toolbelt_filesystem.USP_CreateDirectory

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Erstellt ein Verzeichnis unter einem freigegebenen Root.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_CreateDirectory.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_CreateDirectory.md).

<!-- Source/Vertrag SHA256: 950b1313bfa526d9f16e9887e333631dee38f11bf80cfcbe79ba50ee7be37c7f -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_CreateDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'example-dir', @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_CreateDirectory @Hilfe=1;
```

## toolbelt_filesystem.USP_RemoveFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Entfernt eine Datei unter einem freigegebenen Root.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_RemoveFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_RemoveFile.md).

<!-- Source/Vertrag SHA256: 4ecbf5d6c46534da8eb129dc707cc3b357a10ce2630728311e5b207622561d9d -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveFile
 @RootAlias=N'ExampleRoot', @RelativePath=N'own-example.bin', @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_RemoveFile @Hilfe=1;
```

## toolbelt_filesystem.USP_RemoveDirectory

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Entfernt ein Verzeichnis; rekursives Entfernen ist explizit und begrenzt.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_RemoveDirectory.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_RemoveDirectory.md).

<!-- Source/Vertrag SHA256: b3d7a69da415e3fdaa1088235420a63e55555cd7f0a63d300d8795ab5313a45d -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@Recursive` | `bit` | `0` | Input | 1 arbeitet rekursiv, 0 nur im gewählten Verzeichnis. |
| `@MaxDepth` | `int` | `32` | Input | Maximale rekursive Verzeichnistiefe. |
| `@MaxEntries` | `int` | `10000` | Input | Maximale Anzahl zu bearbeitender Einträge. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'own-example-dir', @Recursive=0, @ExecutionIdentity=N'Caller';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe=1;
```

## toolbelt_json.USP_JsonArray

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Array aus Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonArray.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonArray.sql), [USP_JsonArray.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonArray.md).

<!-- Source/Vertrag SHA256: 5c0c8c75d62d83d422f4266a139e30dd4b590b2d054ecae3a1e00826edc6a55c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Bestehende caller-lokale #Temp, exakte erforderliche Typen, zusätzliche Spalten ignoriert. |
| `@MaxEntries` | `int` | `10000` | Input | Positive Grenze bis 100000; Ordinals positiv/eindeutig, Lücken erlaubt. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Summe DATALENGTH(Value), SQL-NULL zählt 0; höchstens 16777216. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Exakte UTF-16-Ergebnisbytes einschließlich Escapes/Keys/Syntax; höchstens 16777216. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: SELECT; sonst bestehende lokale Temp-Tabelle, nicht Eingabeobjekt. |
| `@KeepData` | `bit` | `0` | Input | Replace=0, Append=1; NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Payloadinhalte; NULL entspricht 0. |
| `@Hilfe` | `bit` | `0` | Input | Help zuerst; ignoriert sämtliche anderen Parameter ohne Seiteneffekte. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Entries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,N'string',N'Contoso'),(2,N'number',N'42');
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#Entries';
DROP TABLE #Entries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonArray @Hilfe=1;
```

## toolbelt_json.USP_JsonObject

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Object aus Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonObject.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonObject.sql), [USP_JsonObject.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonObject.md).

<!-- Source/Vertrag SHA256: fce75155b94c9477db414538eb5b76fdce2ae1aeee7be9e79e21f2732a785d14 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Bestehende caller-lokale #Temp, exakte erforderliche Typen, zusätzliche Spalten ignoriert. |
| `@MaxEntries` | `int` | `10000` | Input | Positive Grenze bis 100000; Ordinals positiv/eindeutig, Lücken erlaubt. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Summe DATALENGTH(Value), SQL-NULL zählt 0; höchstens 16777216. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Exakte UTF-16-Ergebnisbytes einschließlich Escapes/Keys/Syntax; höchstens 16777216. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: SELECT; sonst bestehende lokale Temp-Tabelle, nicht Eingabeobjekt. |
| `@KeepData` | `bit` | `0` | Input | Replace=0, Append=1; NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Payloadinhalte; NULL entspricht 0. |
| `@Hilfe` | `bit` | `0` | Input | Help zuerst; ignoriert sämtliche anderen Parameter ohne Seiteneffekte. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Entries(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,N'name',N'string',N'Contoso'),(2,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#Entries';
DROP TABLE #Entries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
```

## toolbelt_json.USP_JsonArraysByGroup

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Array aus GroupOrdinal/Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonArraysByGroup.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonArraysByGroup.sql), [USP_JsonArraysByGroup.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonArraysByGroup.md).

<!-- Source/Vertrag SHA256: 9cdad28a51095c9d9284c346ecaae335c8ff85a7a336de9231eac274643273a3 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Bestehende caller-lokale #Temp, exakte erforderliche Typen, zusätzliche Spalten ignoriert. |
| `@MaxEntries` | `int` | `10000` | Input | Positive Grenze bis 100000; GroupOrdinal positiv; (GroupOrdinal,Ordinal) eindeutig; globale Grenze. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Summe DATALENGTH(Value), SQL-NULL zählt 0; höchstens 16777216. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Exakte UTF-16-Ergebnisbytes einschließlich Escapes/Keys/Syntax; höchstens 16777216. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: SELECT; sonst bestehende lokale Temp-Tabelle, nicht Eingabeobjekt. |
| `@KeepData` | `bit` | `0` | Input | Replace=0, Append=1; NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Payloadinhalte; NULL entspricht 0. |
| `@Hilfe` | `bit` | `0` | Input | Help zuerst; ignoriert sämtliche anderen Parameter ohne Seiteneffekte. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'string',N'Contoso'),(2,1,N'number',N'42');
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#Entries';
DROP TABLE #Entries;
```

```sql
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'string',N'Contoso'),(2,1,N'number',N'42');
EXEC toolbelt_json.USP_JsonArraysByGroup
 @EntriesTable = N'#Entries', @MaxEntries = 10000,
 @MaxTotalValueBytes = 2097152, @MaxResultBytes = 2097152,
 @ResultTable = NULL, @KeepData = 0, @Debug = 0, @Hilfe = 0;
DROP TABLE #Entries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonArraysByGroup @Hilfe=1;
```

## toolbelt_json.USP_JsonObjectsByGroup

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Object aus GroupOrdinal/Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonObjectsByGroup.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonObjectsByGroup.sql), [USP_JsonObjectsByGroup.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonObjectsByGroup.md).

<!-- Source/Vertrag SHA256: a7409119bc30a8bf2483542b69545db069db73bbb0688c84762ec630aa41776b -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Bestehende caller-lokale #Temp, exakte erforderliche Typen, zusätzliche Spalten ignoriert. |
| `@MaxEntries` | `int` | `10000` | Input | Positive Grenze bis 100000; GroupOrdinal positiv; (GroupOrdinal,Ordinal) eindeutig; globale Grenze. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Summe DATALENGTH(Value), SQL-NULL zählt 0; höchstens 16777216. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Exakte UTF-16-Ergebnisbytes einschließlich Escapes/Keys/Syntax; höchstens 16777216. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: SELECT; sonst bestehende lokale Temp-Tabelle, nicht Eingabeobjekt. |
| `@KeepData` | `bit` | `0` | Input | Replace=0, Append=1; NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Payloadinhalte; NULL entspricht 0. |
| `@Hilfe` | `bit` | `0` | Input | Help zuerst; ignoriert sämtliche anderen Parameter ohne Seiteneffekte. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'name',N'string',N'Contoso'),(2,1,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#Entries';
DROP TABLE #Entries;
```

```sql
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'name',N'string',N'Contoso'),(2,1,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObjectsByGroup
 @EntriesTable = N'#Entries', @MaxEntries = 10000,
 @MaxTotalValueBytes = 2097152, @MaxResultBytes = 2097152,
 @ResultTable = NULL, @KeepData = 0, @Debug = 0, @Hilfe = 0;
DROP TABLE #Entries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonObjectsByGroup @Hilfe=1;
```

## toolbelt_json.AGF_JsonArray

Modul `toolbelt.json.constructors` · Version `1.3.0` · `CLR_AGGREGATE`

Aggregiert typisierte JSON-Einträge in Ordinal-Reihenfolge zu einem JSON-Array.

Vertrag und Quelle: [JsonAggregates.sql](../../Modules/toolbelt.json.constructors/Source/JsonAggregates.sql), [AGF_JsonArray.md](../../Modules/toolbelt.json.constructors/Documentation/AGF_JsonArray.md).

<!-- Source/Vertrag SHA256: 9bf0183ecefdf83c4cb8dc46a0a51478d16c68ad302396fee0247117a1676e37 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Positives, innerhalb der Gruppe eindeutiges int-Ordinal. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | string, number, boolean, null, array oder object. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Profile` | `tinyint` | `kein Default` | Input | JSON-Aggregate: 1 oder 2, innerhalb jeder Gruppe identisch. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
DECLARE @Entries TABLE(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(2,N'number',N'2',1),(1,N'string',N'Contoso',1);
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## toolbelt_json.AGF_JsonObject

Modul `toolbelt.json.constructors` · Version `1.3.0` · `CLR_AGGREGATE`

Aggregiert typisierte Einträge mit eindeutigen Schlüsseln zu einem JSON-Objekt.

Vertrag und Quelle: [JsonAggregates.sql](../../Modules/toolbelt.json.constructors/Source/JsonAggregates.sql), [AGF_JsonObject.md](../../Modules/toolbelt.json.constructors/Documentation/AGF_JsonObject.md).

<!-- Source/Vertrag SHA256: b7253184c8514bf9fb56afedad670f58d53e285fa2200d6b86b30cd2dc2c5014 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Positives, innerhalb der Gruppe eindeutiges int-Ordinal. |
| `@Key` | `nvarchar(max)` | `kein Default` | Input | JSON-Objektschlüssel, je Gruppe eindeutige längensensitive UTF-16-Identität. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | string, number, boolean, null, array oder object. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Profile` | `tinyint` | `kein Default` | Input | JSON-Aggregate: 1 oder 2, innerhalb jeder Gruppe identisch. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
DECLARE @Entries TABLE(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(1,N'name',N'string',N'Contoso',1),(2,N'count',N'number',N'2',1);
SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## toolbelt_json.TVF_JsonPathExists

Modul `toolbelt.json.path-exists` · Version `1.0.0` · `TVF`

Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert.

Vertrag und Quelle: [TVF_JsonPathExists.sql](../../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql), [TVF_JsonPathExists.md](../../Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExists.md).

<!-- Source/Vertrag SHA256: f99996d40641d684a2faafc6fe0bc754c9911dfe288459d14531d37c0671704f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Zu prüfendes JSON-Dokument; SQL-NULL in Json oder Path liefert PathExists=NULL, ungültiges JSON liefert0. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | Begrenzter JSON-Pfad mit $, Schlüsseln, nullbasierten Array-Indizes oder Wildcards; maximal4000 UTF-16-Codeeinheiten. Keine Ranges, Indexlisten oder last. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExists(N'{"items":[1,2]}', N'$.items[0]');
```

## toolbelt_json.TVF_JsonPathExistsStatus

Modul `toolbelt.json.path-exists` · Version `1.0.0` · `TVF`

Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING.

Vertrag und Quelle: [TVF_JsonPathExists.sql](../../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql), [TVF_JsonPathExistsStatus.md](../../Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExistsStatus.md).

<!-- Source/Vertrag SHA256: e655b0148731ed3f66f6038c928295c70481f4c2e9bd075c7bcee4bcfa1f7be2 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); höchstens 16 MiB UTF-16, vor nativer Validierung lexikalische Containertiefe höchstens 128. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); bestehender 4000-Codeeinheitenvertrag und höchstens 128 Segmente. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":null}',N'$.a');
```

## toolbelt_json.TVF_ResolveJsonPointer

Modul `toolbelt.json.pointer` · Version `1.0.0` · `TVF`

Löst einen RFC6901-Pointer mit exakten Keys und unterscheidet FOUND, MISSING, JSON_NULL, SQL_NULL und INVALID. Der freigegebene feste128er-Guard gibt darüber DEPTH_LIMIT vor JSON_SYNTAX zurück.

Vertrag und Quelle: [TVF_ResolveJsonPointer.sql](../../Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql), [TVF_ResolveJsonPointer.md](../../Modules/toolbelt.json.pointer/Documentation/TVF_ResolveJsonPointer.md).

<!-- Source/Vertrag SHA256: ce9772dabbc9bc16a3a0e78d202e8efb88bd7943cfe7ae6a2746bc7826d8ee32 -->

Voraussetzung: Vorhandenes SELECT; SQL Server2019+ und CL150+ auch beim zentralen Caller; lesende MSTVF ohne CLR. Freigegebener struktureller128er-Guard: darüber DEPTH_LIMIT vor JSON_SYNTAX; kein Release.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiges JSON einschließlich Scalarroot; vollständige Unicode-/Tiefenpolicy. |
| `@Pointer` | `nvarchar(max)` | `kein Default` | Input | Stringform, leer für Root; ~0/~1 einmal decodieren, höchstens4000 UTF16-Einheiten. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | Positives bigint-Bytebudget bis16777216, nur absenkbar. |
| `@MaxDepth` | `int` | `128` | Input | Positives int-Tiefenbudget bis128, nur absenkbar; Containerroot1, Scalarroot0. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT Status,JsonType,Value,ErrorCode FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"items":[null,"example"]}',N'/items/1',DEFAULT,DEFAULT);
```

## toolbelt_json.USP_ValidateJsonSchema

Modul `toolbelt.json.schema` · Version `1.0.1` · `USP`

Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen.

Vertrag und Quelle: [USP_ValidateJsonSchema.sql](../../Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql), [USP_ValidateJsonSchema.md](../../Modules/toolbelt.json.schema/Documentation/USP_ValidateJsonSchema.md).

<!-- Source/Vertrag SHA256: 2f09582977f8402af0c80421c24f43e62faac406858c33fc0a96fc6e62d6feae -->

Voraussetzung: SQL Server2019+ und CL150+, bekannte SAFE-Core-/Schema-Assemblies in derselben Datenbank, ResultTable >=1.0.0, vorhandene Aufrufrechte. Nur Teilqualifikation, unreleased.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `NULL` | Input | Instanz als vollständiges JSON; SQL NULL liefert SQL_NULL nach Parameterprüfung. |
| `@Schema` | `nvarchar(max)` | `NULL` | Input | Schema vollständig prüfen, einschließlich ungenutzter Definitionen; keine externe oder rekursive Referenz. |
| `@Profile` | `varchar(32)` | `'toolbelt-2020-12-v1'` | Input | Exakt toolbelt-2020-12-v1; kein volles Draft2020-12. |
| `@MaxDocumentBytes` | `bigint` | `16777216` | Input | Positiv, höchstens16777216 UTF16-Bytes. |
| `@MaxSchemaBytes` | `bigint` | `1048576` | Input | Positiv, höchstens1048576 UTF16-Bytes. |
| `@MaxDepth` | `int` | `128` | Input | 1 bis128; Containerroot1, Scalarroot0. |
| `@MaxEvaluationSteps` | `bigint` | `1000000` | Input | 1 bis1000000 globale abstrakte Arbeitseinheiten; LIMIT liefert kein Boolurteil. |
| `@MaxErrors` | `int` | `100` | Input | 0 bis100; begrenzt nur Diagnosen, niemals die vollständige Evaluation. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL für SELECT; sonst vorhandene caller-lokale TempTable nach Helpervertrag. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace,1 Append; NULL entspricht0. |
| `@Debug` | `tinyint` | `0` | Input | Payloadfreie Messages; NULL entspricht0. |
| `@Hilfe` | `bit` | `0` | Input | Help zuerst ohne fachliche Argument-/Dependencyprüfung; NULL entspricht0. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{"quantity":3}', @Schema=N'{"properties":{"quantity":{"type":"integer","minimum":1}}}';
```

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
```

## toolbelt_metadata.VW_ModuleCapabilities

Modul `toolbelt.metadata.capability-catalog` · Version `1.0.0` · `VW`

Zeigt installierte Modulversionen und Deployment-Modi und kennzeichnet unvollständige oder ungültige Modulmarker.

Vertrag und Quelle: [VW_ModuleCapabilities.sql](../../Modules/toolbelt.metadata.capability-catalog/Source/VW_ModuleCapabilities.sql), [VW_ModuleCapabilities.md](../../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ModuleCapabilities.md).

<!-- Source/Vertrag SHA256: e29c304c4acc89189ba924ca6e562853aa568642aa6d696df59df0a12a9937a4 -->

Keine Eingabeparameter.

```sql
SELECT ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;
```

## toolbelt_metadata.TVF_ParseMultipartName

Modul `toolbelt.metadata.identifier` · Version `1.0.0` · `TVF`

Zerlegt und validiert ein- bis vierteilige SQL-Identifier.

Vertrag und Quelle: [TVF_ParseMultipartName.sql](../../Modules/toolbelt.metadata.identifier/Source/TVF_ParseMultipartName.sql), [TVF_ParseMultipartName.md](../../Modules/toolbelt.metadata.identifier/Documentation/TVF_ParseMultipartName.md).

<!-- Source/Vertrag SHA256: 61e09cf201db0b87d91a41e275a663498fef1eaa84ea86e4a291b245ed6166f2 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Name mit unterstützter Quote-Syntax. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'dbo.[Order Items]');
```

## toolbelt_metadata.SVF_QuoteMultipartName

Modul `toolbelt.metadata.identifier` · Version `1.0.0` · `SVF`

Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten.

Vertrag und Quelle: [SVF_QuoteMultipartName.sql](../../Modules/toolbelt.metadata.identifier/Source/SVF_QuoteMultipartName.sql), [SVF_QuoteMultipartName.md](../../Modules/toolbelt.metadata.identifier/Documentation/SVF_QuoteMultipartName.md).

<!-- Source/Vertrag SHA256: 008ad792c26c3730b61a7951c4cffbdeb83073a18ff8ed5cde07c963e43443ed -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Name mit unterstützter Quote-Syntax. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.[Order Items]') AS ResultValue;
```

## toolbelt_metadata.USP_ScriptTableClone

Modul `toolbelt.metadata.table-clone` · Version `4.1.1` · `USP`

Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.

Vertrag und Quelle: [USP_ScriptTableClone.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql), [USP_ScriptTableClone.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md).

<!-- Source/Vertrag SHA256: 216bd0869836bd6b575da996fc5d11172b229c4f53efc5a5e69ebe580eec4777 -->

Voraussetzung: Vorhandene synthetische Quelltabelle und sichtbares Zielschema; Zielname darf noch nicht existieren. IncludeTriggers=1 verlangt Windows und den separat installierten Parser 2.0.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Explizites Schema in Installationsdatenbank, 1-128 UTF-16-Codeeinheiten. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Explizite reguläre diskbasierte Tabelle; VIEW DEFINITION erforderlich. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Bestehendes sichtbares Schema derselben Datenbank. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Noch nicht existierender Zielname; keine automatische Namenswahl. |
| `@IncludeIdentity` | `bit` | `0` | Input | 1 übernimmt Seed/Increment; 0 entfernt Identity-Eigenschaft ausdrücklich, niemals aktuellen Zähler. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | 1 plant unterstützte Properties typgetreu; 0 lehnt relevante Properties ab. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL ist W1-Einzelmodus; sonst fünfspaltige lokale Map mit 1-64 eindeutigen positiven MapOrdinals und vier nvarchar(max) NOT NULL-Identifiern. |
| `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Byteexakt REJECT oder KEEP; KEEP nur im Mapmodus für sichtbare externe Referenzziele. |
| `@IncludeTriggers` | `bit` | `0` | Input | 0: Trigger bleiben ein Abbruchgrund. 1: begrenzte DML-Trigger-Preview auf Windows mit separat installiertem Parser 2.0; manuelle Prüfung der DDL erforderlich. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert SELECT; sonst bestehende caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append; NULL entspricht0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages; keine persistierte Quellmetadaten-Ausgabe. |
| `@Hilfe` | `bit` | `0` | Input | 1 umgeht sämtliche Prüfungen und Seiteneffekte. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',@TargetSchema=N'dbo',@TargetTable=N'SyntheticClone';
```

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',@TargetSchema=N'dbo',@TargetTable=N'SyntheticClone',@IncludeTriggers=1;
```

Hilfe:

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
```

## toolbelt_metadata.USP_ExecuteTableClone

Modul `toolbelt.metadata.table-clone` · Version `4.1.1` · `USP`

Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie.

Vertrag und Quelle: [USP_ExecuteTableClone.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_ExecuteTableClone.sql), [USP_ExecuteTableClone.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ExecuteTableClone.md).

<!-- Source/Vertrag SHA256: d65320e67f6f49bf6e084bbaec64e45203edd75d1b3ae63171cb28846f89a527 -->

Voraussetzung: Erzeugt neue Tabellen. @CalculatedPlanHash ist ein notwendiger Platzhalter für die externe kanonische Hashberechnung; der Beispielaufruf ist bis dahin nicht ausführbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | V3-Einzelquelle; im Mapmodus NULL. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | V3-Einzelquelle; im Mapmodus NULL. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Bestehendes Installationsdatenbankschema; im Mapmodus NULL. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Neuer Zielname; im Mapmodus NULL. |
| `@IncludeIdentity` | `bit` | `0` | Input | Unveränderte V3-Identityoption. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | Unveränderte V3-Propertyoption. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL bewahrt Einzelmodus; sonst einmaliger Snapshot der fünfspaltigen V3-Map, 1..64 Zeilen. |
| `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Byteexakt REJECT oder im Mapmodus KEEP. |
| `@ExpectedPlanHash` | `varbinary(max)` | `NULL` | Input | Exakt 32 Bytes des dokumentierten Hashlayouts v1, alle Planzeilen und Installationsdatenbank gebunden. |
| `@ForeignKeyMode` | `varchar(16)` | `'CREATE'` | Input | Byteexakt CREATE oder DEFER; DEFER lässt nur FOREIGN_KEY und FOREIGN_KEY_STATE aus, beide bleiben gehasht. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert eine Erfolgszeile; sonst caller-lokale ResultTable. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append; NULL entspricht0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages, keine Zusatzresultsets. |
| `@Hilfe` | `bit` | `0` | Input | Help vor sämtlichen Fachprüfungen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: eigene Quelltabelle und neues Ziel in vorhandenen Schemas.
-- Den Vorschauplan mit identischen Optionen erzeugen und seinen Hash
-- nach dem kanonischen Client-Framing berechnen; keine Konstante erfinden.
DECLARE @CalculatedPlanHash varbinary(max)=NULL; -- berechneten 32-Byte-Hash einsetzen
EXEC toolbelt_metadata.USP_ExecuteTableClone
 @SourceSchema=N'dbo', @SourceTable=N'SyntheticSource',
 @TargetSchema=N'dbo', @TargetTable=N'SyntheticClone',
 @ExpectedPlanHash=@CalculatedPlanHash, @ForeignKeyMode='CREATE';
```

Hilfe:

```sql
EXEC toolbelt_metadata.USP_ExecuteTableClone @Hilfe=1;
```

## toolbelt_metadata.USP_CopyTableCloneData

Modul `toolbelt.metadata.table-clone` · Version `4.1.1` · `USP`

Kopiert einen begrenzten SameDB-Tabellenverbund atomar in bereits vorhandene leere formgleiche Ziele; keine Strukturkopie oder Rechtevergabe.

Vertrag und Quelle: [USP_CopyTableCloneData.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_CopyTableCloneData.sql), [USP_CopyTableCloneData.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_CopyTableCloneData.md).

<!-- Source/Vertrag SHA256: 4b8235025f608d51dc4cb4bda18cd0efc7916186c7d19b34ac761a61efc4b432 -->

Voraussetzung: Vorhandene reguläre SameDB-Quellen und leere formgleiche Ziele, keine aktive Callertransaktion. SERIALIZABLE hält Quellsperren; SNAPSHOT benötigt eine bereits aktivierte Datenbankoption.

Voraussetzung: Vorhandene DB-Metadatensicht und Source-/Target-Rechte; fehlende FKs verlangen zusätzlich Server-DDL-Sicht und DDL-Rechte. KEEP benötigt vorhandenes Identity-ALTER. Aktive Targettrigger, RLS und nicht tabellenlokale Ausführung blockieren.

Voraussetzung: Verändert Zielinhalte und kann fehlende gemappte FKs erzeugen. Identity-Zähler können trotz Rollback fortgeschritten bleiben; kein RESEED oder Identitätszuordnungsversprechen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@TableMap` | `sysname` | `NULL` | Input | Fachlich erforderliche bestehende lokale fünfspaltige Map: 1..64 positive eindeutige MapOrdinals und vier nvarchar(max) NOT NULL-Identifier. |
| `@IdentityMode` | `varchar(16)` | `NULL` | Input | Fachlich erforderlich, byteexakt KEEP oder REGENERATE; REGENERATE bei identityabhängigen Beziehungen ausgeschlossen. |
| `@ConsistencyMode` | `varchar(16)` | `NULL` | Input | Fachlich erforderlich, byteexakt SNAPSHOT oder SERIALIZABLE; keine automatische Konfiguration. |
| `@RowLimit` | `bigint` | `100000` | Input | Positives globales Zeilenbudget, höchstens 100000; nur absenkbar. |
| `@PayloadByteLimit` | `bigint` | `16777216` | Input | Positives globales DATALENGTH-Budget der transportierten SQL-Werte, höchstens 16777216 Bytes; nur absenkbar. NULL zählt0. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert eine fünfspaltige Erfolgszeile; sonst bestehende lokale Ausgabe-Temp-Tabelle ohne fachliches SELECT. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append; NULL entspricht0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages, keine Zusatzresultsets. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich Hilfe und umgeht fachliche Pflichtparameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #CopyMap
(
 MapOrdinal int NOT NULL,
 SourceSchema nvarchar(max) NOT NULL, SourceTable nvarchar(max) NOT NULL,
 TargetSchema nvarchar(max) NOT NULL, TargetTable nvarchar(max) NOT NULL
);
-- Eigene synthetische Tabellen bestehen bereits; SyntheticClone ist leer und formgleich.
INSERT #CopyMap VALUES (1,N'dbo',N'SyntheticSource',N'dbo',N'SyntheticClone');
EXEC toolbelt_metadata.USP_CopyTableCloneData
 @TableMap=N'#CopyMap', @IdentityMode='KEEP', @ConsistencyMode='SERIALIZABLE';
DROP TABLE #CopyMap;
```

Hilfe:

```sql
EXEC toolbelt_metadata.USP_CopyTableCloneData @Hilfe=1;
```

## toolbelt_pseudonymization.TVF_DeterministicGeoJitter

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius.

Vertrag und Quelle: [DeterministicGeoJitter.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicGeoJitter.sql), [TVF_DeterministicGeoJitter.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicGeoJitter.md).

<!-- Source/Vertrag SHA256: efb384fc7f32a52a3cddb5aa74253ca6d03a6e04709813b11658961e1e2e3caf -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `geography` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Vom Caller kanonisierte Binärbytes; 1–8000 Byte für den Range-Kern. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive int-Kontextversion der deterministischen Abbildung. |
| `@Seed` | `bigint` | `0` | Input | Nicht-NULL bigint-Seed; Default 0. Beispiel: 42. |
| `@RadiusMeters` | `int` | `100` | Input | Ganzzahlig 1–10000 Meter; nur synthetische 2D-Points/SRID 4326. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(48.2,16.3,4326), 0x01020304, 1, 42, 25);
```

## toolbelt_pseudonymization.TVF_DeterministicTranslate

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung.

Vertrag und Quelle: [DeterministicTranslate.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicTranslate.sql), [TVF_DeterministicTranslate.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicTranslate.md).

<!-- Source/Vertrag SHA256: a0765f3903b6971b86cebd553e7f3e2f9c1240a5411188cb636c54a4e11cab69 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive int-Kontextversion der deterministischen Abbildung. |
| `@Seed` | `bigint` | `0` | Input | Nicht-NULL bigint-Seed; Default 0. Beispiel: 42. |
| `@AllowedSeparators` | `nvarchar(max)` | `N''` | Input | Separatorzeichen, die bei der Übersetzung unverändert bleiben. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'  Contoso-123  ', 1, 42, N'- ', N'standard');
```

## toolbelt_pseudonymization.TVF_DeterministicRange

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu.

Vertrag und Quelle: [TVF_DeterministicRange.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRange.sql), [TVF_DeterministicRange.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicRange.md).

<!-- Source/Vertrag SHA256: b4ea68509ba7ddf1beff9789a9d0a351e010f0dd6ff5eddf80c5fd5c30ecbc1e -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Key` | `varbinary(max)` | `kein Default` | Input | Vom Caller kanonisierte Binärbytes; 1–8000 Byte für den Range-Kern. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive int-Kontextversion der deterministischen Abbildung. |
| `@Seed` | `bigint` | `0` | Input | Nicht-NULL bigint-Seed; Default 0. Beispiel: 42. |
| `@Min` | `bigint` | `kein Default` | Input | Inklusive untere bigint-Bereichsgrenze. |
| `@Max` | `bigint` | `kein Default` | Input | Inklusive obere bigint-Bereichsgrenze. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x01020304, 1, 42, 1, 100);
```

## toolbelt_pseudonymization.TVF_DeterministicDateShift

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage.

Vertrag und Quelle: [TVF_DeterministicDateShift.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicDateShift.sql), [TVF_DeterministicDateShift.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicDateShift.md).

<!-- Source/Vertrag SHA256: 222a132cf9522def964d3b4e6482006d628afa8d410b1ec9b1977cbd4454277f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `datetime2(7)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Vom Caller kanonisierte Binärbytes; 1–8000 Byte für den Range-Kern. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive int-Kontextversion der deterministischen Abbildung. |
| `@Seed` | `bigint` | `0` | Input | Nicht-NULL bigint-Seed; Default 0. Beispiel: 42. |
| `@MaxDays` | `int` | `365` | Input | Maximale absolute Datumsverschiebung in Tagen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2024-07-19T14:35:42'), 0x01020304, 1, 42, 7);
```

## toolbelt_pseudonymization.USP_DeterministicLookup

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `USP`

Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.

Vertrag und Quelle: [USP_DeterministicLookup.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookup.sql), [USP_DeterministicLookup.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/USP_DeterministicLookup.md).

<!-- Source/Vertrag SHA256: c2a2cd8e305833cd80642c5b956ccd398b9e2d88ab72c83c99585044de7492a9 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@InputTable` | `sysname` | `NULL` | Input | Caller-lokale #Temp: Ordinal bigint, Key varbinary(max). |
| `@LookupTable` | `sysname` | `NULL` | Input | Caller-lokale #Temp: Ordinal bigint, Value nvarchar(max); Pool nach Ordinal. |
| `@MappingVersion` | `int` | `NULL` | Input | Positive Mapping-Kontextversion. |
| `@Seed` | `bigint` | `0` | Input | Öffentlicher Varianten-Seed, kein Secret. |
| `@LookupVersion` | `bigint` | `NULL` | Input | Positive, ausdrücklich gewählte Poolversion; bei Pooländerung ändern. |
| `@MaxInputRows` | `int` | `10000` | Input | Positive Grenze bis 100000 Eingaben. |
| `@MaxLookupRows` | `int` | `10000` | Input | Positive Grenze bis 100000 Poolzeilen. |
| `@MaxLookupTextBytes` | `bigint` | `2097152` | Input | Positive Gesamttextbytegrenze bis 16777216. |
| `@MaxResultBytes` | `bigint` | `16777216` | Input | Positive Gesamt-Ergebnistextbytegrenze bis 16777216. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL: genau ein SELECT; sonst vorhandene lokale ResultTable. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append; NULL wie 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Phasen-/Metadaten-Messages, keine Keys, Werte, Seeds oder Hashes. |
| `@Hilfe` | `bit` | `0` | Input | Help zuerst, ohne fachliche Prüfung/Mutation/Messages. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Input(Ordinal bigint, [Key] varbinary(max)); CREATE TABLE #Pool(Ordinal bigint, [Value] nvarchar(max)); INSERT #Input VALUES(10,0x010203); INSERT #Pool VALUES(20,N'synthetic'); EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1;
DROP TABLE #Input, #Pool;
```

Hilfe:

```sql
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
```

## toolbelt_string.TVF_TrimDirectionalNvarchar

Modul `toolbelt.string.directional-trim` · Version `1.0.0` · `TVF`

Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text.

Vertrag und Quelle: [TVF_TrimDirectionalNvarchar.sql](../../Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalNvarchar.sql), [TVF_TrimDirectionalNvarchar.md](../../Modules/toolbelt.string.directional-trim/Documentation/TVF_TrimDirectionalNvarchar.md).

<!-- Source/Vertrag SHA256: 5fb14d3f1183dc313ed0b9098e52c142e30f457d6df0a97536b231426eae3ffa -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Characters` | `nvarchar(4000)` | `N' '` | Input | Menge der zu entfernenden Zeichen. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | LEADING, TRAILING oder BOTH. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'  Contoso-123  ', N' ', 'BOTH');
```

## toolbelt_string.TVF_TrimDirectionalVarchar

Modul `toolbelt.string.directional-trim` · Version `1.0.0` · `TVF`

Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem varchar-Text.

Vertrag und Quelle: [TVF_TrimDirectionalVarchar.sql](../../Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalVarchar.sql), [TVF_TrimDirectionalVarchar.md](../../Modules/toolbelt.string.directional-trim/Documentation/TVF_TrimDirectionalVarchar.md).

<!-- Source/Vertrag SHA256: d33102b756da67db692a2662e96581a51d40164ba9cbf9526dda54f9cca0b789 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Characters` | `varchar(8000)` | `' '` | Input | Menge der zu entfernenden Zeichen. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | LEADING, TRAILING oder BOTH. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalVarchar('  Contoso  ', N' ', 'BOTH');
```

## toolbelt_string.TVF_JaroWinklerSimilarity

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Berechnet einen Jaro-Winkler-Ähnlichkeitsscore zwischen 0 und 1 über Unicode Scalars.

Vertrag und Quelle: [JaroWinkler.sql](../../Modules/toolbelt.string.edit-distance/Source/JaroWinkler.sql), [TVF_JaroWinklerSimilarity.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_JaroWinklerSimilarity.md).

<!-- Source/Vertrag SHA256: d3d8a47824bb7bc7a2f0cc0ca7cfdb2cb6d9c62b50d05270f6cfd795844a1275 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Linker Unicode-Vergleichstext. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Rechter Unicode-Vergleichstext. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'kitten', N'sitting', N'standard');
```

## toolbelt_string.TVF_LevenshteinDistance

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Berechnet die begrenzte Levenshtein-Editierdistanz zweier Unicode-Texte.

Vertrag und Quelle: [EditDistance.sql](../../Modules/toolbelt.string.edit-distance/Source/EditDistance.sql), [TVF_LevenshteinDistance.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_LevenshteinDistance.md).

<!-- Source/Vertrag SHA256: 57bc8231014d883d6a75f582ce21850d616447bf44864227f1bceaeacfcc68fe -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Linker Unicode-Vergleichstext. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Rechter Unicode-Vergleichstext. |
| `@MaxDistance` | `int` | `NULL` | Input | NULL = ohne fachliche Distanzgrenze; sonst nichtnegative Maximaldistanz. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten', N'sitting', NULL, N'standard');
```

## toolbelt_string.TVF_OsaDistance

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Berechnet die begrenzte Optimal-String-Alignment-Distanz mit benachbarten Transpositionen.

Vertrag und Quelle: [EditDistance.sql](../../Modules/toolbelt.string.edit-distance/Source/EditDistance.sql), [TVF_OsaDistance.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_OsaDistance.md).

<!-- Source/Vertrag SHA256: 44eeabc5acad91e637ef3ab276d8c1db81401004eafb902bb3a2f83709fc6254 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Linker Unicode-Vergleichstext. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Rechter Unicode-Vergleichstext. |
| `@MaxDistance` | `int` | `NULL` | Input | NULL = ohne fachliche Distanzgrenze; sonst nichtnegative Maximaldistanz. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'kitten', N'sitting', NULL, N'standard');
```

## toolbelt_string.TVF_ColognePhonetic

Modul `toolbelt.string.phonetic` · Version `1.0.0` · `TVF`

Berechnet den vollständigen begrenzten Kölner Phonetikcode.

Vertrag und Quelle: [TVF_ColognePhonetic.sql](../../Modules/toolbelt.string.phonetic/Source/TVF_ColognePhonetic.sql), [TVF_ColognePhonetic.md](../../Modules/toolbelt.string.phonetic/Documentation/TVF_ColognePhonetic.md).

<!-- Source/Vertrag SHA256: bebb834aa52e88ff253caba9741dbad75fb871db2f33b0c5f12fbb7f97b14ed6 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text für die Phonetikberechnung. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'Contoso');
```

## toolbelt_string.TVF_DoubleMetaphone

Modul `toolbelt.string.phonetic` · Version `1.0.0` · `TVF`

Berechnet den primären und alternativen Double-Metaphone-Code.

Vertrag und Quelle: [TVF_DoubleMetaphone.sql](../../Modules/toolbelt.string.phonetic/Source/TVF_DoubleMetaphone.sql), [TVF_DoubleMetaphone.md](../../Modules/toolbelt.string.phonetic/Documentation/TVF_DoubleMetaphone.md).

<!-- Source/Vertrag SHA256: 91c9ab5876807635c004e4dbefbb4664104dd254b0a4803bcc065d97f88eb00f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text für die Phonetikberechnung. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'Contoso');
```

## toolbelt_string.TVF_RegexCaptures

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Liefert Gruppen-Captures einschließlich wiederholter Captures.

Vertrag und Quelle: [RegexCaptures.sql](../../Modules/toolbelt.string.regex/Source/RegexCaptures.sql), [TVF_RegexCaptures.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexCaptures.md).

<!-- Source/Vertrag SHA256: 1c3ccb5f9ff3cf3a35dc1e476683fed11ad3bd7f55a4650634daeeca6fe69ea0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Start` | `int` | `1` | Input | Regex: positive 1-basierte UTF-16-Startposition. Serie: erster Wert. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |
| `@MaxRows` | `int` | `10000` | Input | Grenze der vollständig zu materialisierenden Regex-Ausgabezeilen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_RegexCaptures(N'abc123 def456', N'[0-9]+', 1, N'c', N'standard', 1000);
```

## toolbelt_string.SVF_RegexReplaceGroups

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Ersetzt Regex-Treffer mit dem getrennten Gruppen-Ersatzvertrag.

Vertrag und Quelle: [RegexCaptures.sql](../../Modules/toolbelt.string.regex/Source/RegexCaptures.sql), [SVF_RegexReplaceGroups.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexReplaceGroups.md).

<!-- Source/Vertrag SHA256: 259a59ea30947091f74a31b020c231b501bd025c8a302056b42cdad2116a0132 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Gruppen-Replace: $1, ${Name}, $$; keine Gruppe 0. Literal-Replace expandiert keine Gruppen. |
| `@Start` | `int` | `1` | Input | Regex: positive 1-basierte UTF-16-Startposition. Serie: erster Wert. |
| `@Occurrence` | `int` | `0` | Input | 1-basierte Treffernummer; Replace erlaubt 0 für alle Treffer. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_string.SVF_RegexReplaceGroups(N'abc123 def456', N'(?<Digits>[0-9]+)', N'[${Digits}]', 1, 0, N'c', N'standard') AS ResultValue;
```

## toolbelt_string.TVF_RegexMatches

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Liefert vollständige Regex-Treffer mit Ordinals und Positionen.

Vertrag und Quelle: [RegexRelations.sql](../../Modules/toolbelt.string.regex/Source/RegexRelations.sql), [TVF_RegexMatches.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexMatches.md).

<!-- Source/Vertrag SHA256: 09e913673871885f4b93d1aba5618ba6d93bb157244b0c12112d139a36a76b51 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Start` | `int` | `1` | Input | Regex: positive 1-basierte UTF-16-Startposition. Serie: erster Wert. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |
| `@MaxRows` | `int` | `10000` | Input | Grenze der vollständig zu materialisierenden Regex-Ausgabezeilen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_RegexMatches(N'abc123 def456', N'[0-9]+', 1, N'c', N'standard', 1000);
```

## toolbelt_string.TVF_RegexSplit

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Zerlegt einen Text an Regex-Treffern.

Vertrag und Quelle: [RegexRelations.sql](../../Modules/toolbelt.string.regex/Source/RegexRelations.sql), [TVF_RegexSplit.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexSplit.md).

<!-- Source/Vertrag SHA256: 7e9bff8b3b8550279be782236f58b49dd59f071e7ad3408aea7500ece23ca80d -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |
| `@MaxRows` | `int` | `10000` | Input | Grenze der vollständig zu materialisierenden Regex-Ausgabezeilen. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_RegexSplit(N'a,b;;c', N'[0-9]+', N'c', N'standard', 1000);
```

## toolbelt_string.SVF_RegexIsMatch

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Prüft, ob ein regulärer Ausdruck im Text trifft.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexIsMatch.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexIsMatch.md).

<!-- Source/Vertrag SHA256: f0d3d11869f128cd14e59ea4224566681a2cfd3d5d6299f6760ddb1872bf8f53 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_string.SVF_RegexIsMatch(N'abc123 def456', N'[0-9]+', N'c') AS ResultValue;
```

## toolbelt_string.SVF_RegexInstr

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Liefert eine UTF-16-Position eines ausgewählten Regex-Treffers.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexInstr.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexInstr.md).

<!-- Source/Vertrag SHA256: 5b1f081e3b4ad6f80f6430cfeeb597f3eb21cd6bdc029906510970ef18676534 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Start` | `int` | `1` | Input | Regex: positive 1-basierte UTF-16-Startposition. Serie: erster Wert. |
| `@Occurrence` | `int` | `1` | Input | 1-basierte Treffernummer; Replace erlaubt 0 für alle Treffer. |
| `@ReturnOption` | `int` | `0` | Input | 0 = Trefferbeginn, 1 = Ende exklusiv, jeweils 1-basiert. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_string.SVF_RegexInstr(N'abc123 def456', N'[0-9]+', 1, 1, 0, N'c') AS ResultValue;
```

## toolbelt_string.SVF_RegexCount

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Zählt Regex-Treffer ab der angegebenen Startposition.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexCount.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexCount.md).

<!-- Source/Vertrag SHA256: 8bf87bc60e5745088ab3e41e42cdf557de1f3ce1ca982b028a2cb4a500d7a1a5 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Start` | `int` | `1` | Input | Regex: positive 1-basierte UTF-16-Startposition. Serie: erster Wert. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_string.SVF_RegexCount(N'abc123 def456', N'[0-9]+', 1, N'c') AS ResultValue;
```

## toolbelt_string.SVF_RegexReplace

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Ersetzt ganze Regex-Treffer durch einen literalen Ersatztext.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexReplace.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexReplace.md).

<!-- Source/Vertrag SHA256: d62486c77e4f1efcd9a6473686bea991273abaf9afa7eb2be0d1406739d379c0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Unicode-Text; NULL in Input, Pattern oder Replacement liefert sofortNULL. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Literaler Unicode-Ersatztext; $1 und Backslash-Gruppenreferenzen werden nicht expandiert. |
| `@Start` | `int` | `1` | Input | Positive 1-basierte UTF-16-Startposition. |
| `@Occurrence` | `int` | `0` | Input | 0 ersetzt alle Treffer, ein positiver Wert nur den n-ten Treffer ab Start. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_string.SVF_RegexReplace(N'abc123 def456', N'[0-9]+', N'X', 1, 1, N'c', N'standard') AS ResultValue;
```

## toolbelt_string.SVF_RegexSubstring

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Liefert den ausgewählten vollständigen Regex-Treffer.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexSubstring.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexSubstring.md).

<!-- Source/Vertrag SHA256: d8af06972794379f71b1829aa353d4bb61803e3db9674f3c82653b0eab5e3431 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; NULL in Input oder Pattern liefert sofortNULL. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Start` | `int` | `1` | Input | Positive 1-basierte UTF-16-Startposition. |
| `@Occurrence` | `int` | `1` | Input | Positive 1-basierte Treffernummer ab Start; liefert den vollständigen Treffer, keine Capture-Gruppe. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_string.SVF_RegexSubstring(N'abc123 def456', N'[0-9]+', 1, 1, N'c', N'standard') AS ResultValue;
```

## toolbelt_string.TVF_SplitAdvanced

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `TVF`

Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht.

Vertrag und Quelle: [TVF_SplitAdvanced.sql](../../Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql), [TVF_SplitAdvanced.md](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md).

<!-- Source/Vertrag SHA256: 10853c7f1a0517f5d745fcdbf3ac8cbb63bf4f9d9ab7725750500e79774cfac3 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@SeparatorsJson` | `nvarchar(max)` | `kein Default` | Input | JSON-Array literal interpretierter Separatorstrings. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Quote-Zeichen des Splits; Originaltokens bleiben quotiert. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Escape-Zeichen des Splitvertrags; Default Backslash. |
| `@KeepEmpty` | `bit` | `1` | Input | 1 erhält leere Tokens; 0 verwirft sie. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N'a,b;;c', N'[",",";"]', N'"', N'\', 1);
```

## toolbelt_string.TVF_UnquoteToken

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `TVF`

Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes.

Vertrag und Quelle: [TVF_UnquoteToken.sql](../../Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql), [TVF_UnquoteToken.md](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_UnquoteToken.md).

<!-- Source/Vertrag SHA256: 62739eaadfa289038fb25a13e5db703aea45d528ea7a44278ea11dd2787b292c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Qualifier` | `nvarchar(max)` | `NULL` | Input | NULL = Autoerkennung; leer = deaktiviert; sonst einzelnes Quote-Zeichen. |
| `@ClosingQualifier` | `nvarchar(max)` | `NULL` | Input | Explizites schließendes Quote-Zeichen; NULL wählt das Standardpaar. |
| `@BackslashEscape` | `bit` | `0` | Input | 1 aktiviert die begrenzten Backslash-Escapes; 0 deaktiviert sie. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_UnquoteToken(N'[a]]b]', NULL, NULL, 0);
```

## toolbelt_string.USP_SplitAdvanced

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `USP`

Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.

Vertrag und Quelle: [USP_SplitAdvanced.sql](../../Modules/toolbelt.string.split-advanced/Source/USP_SplitAdvanced.sql), [USP_SplitAdvanced.md](../../Modules/toolbelt.string.split-advanced/Documentation/USP_SplitAdvanced.md).

<!-- Source/Vertrag SHA256: e5b71ef792982b10c001d2e18d41073f51381d2e1531af52f20dfad6ba30924e -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `NULL` | Input | NULL ist früher No-op; sonst unveränderte S2-Tokenisierung. |
| `@SeparatorsJson` | `nvarchar(max)` | `NULL` | Input | Nichtleeres JSON-Array von Separatorstrings bei nicht-NULL Input. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Quote-Zeichen; leer deaktiviert, NULL ungültig. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Allgemeines S2-Escape; Originaltoken bleibt erhalten. |
| `@KeepEmpty` | `bit` | `1` | Input | NULL entspricht 1; nur leere Tokens filtern. |
| `@ResultTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale Temp-Tabelle; NULL liefert SELECT. |
| `@KeepData` | `bit` | `0` | Input | Replace=0, Append=1; NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | Nur Messages ohne Input-/Tokeninhalte. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich standardisiertes Help. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b', @SeparatorsJson=N'[";"]', @Quote=N'', @Escape=N'';
```

```sql
EXEC toolbelt_string.USP_SplitAdvanced
    @Input=N'a;"b;c";d', @SeparatorsJson=N'[";"]';
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
```

## toolbelt_string.TVF_SplitByCharacters

Modul `toolbelt.string.split-characters` · Version `1.0.0` · `TVF`

Zerlegt einen Text an jedem Zeichen der angegebenen Separatormenge.

Vertrag und Quelle: [TVF_SplitByCharacters.sql](../../Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql), [TVF_SplitByCharacters.md](../../Modules/toolbelt.string.split-characters/Documentation/TVF_SplitByCharacters.md).

<!-- Source/Vertrag SHA256: d894e13cf3ccfaef5ac346d5dd7590757085913a0c0b8e79cd417716c7f32878 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Literal interpretierte Menge einzelner Separatorzeichen. |
| `@KeepEmpty` | `bit` | `1` | Input | 1 erhält leere Tokens; 0 verwirft sie. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,b;;c', N',;', 1);
```

## toolbelt_string.TVF_SplitByCharactersStatus

Modul `toolbelt.string.split-characters` · Version `1.0.0` · `TVF`

Erst vollständige Spanprüfung, danach höchstens 10000 OK-Tokenzeilen. LIMIT, INVALID, SQL_NULL und EMPTY liefern genau eine Kontrollzeile ohne Value/Ordinal. Keine Tokenpräfixe. Die bisherige TVF filtert ausschließlich OK; bei Grenzüberschreitung liefert sie keine Zeilen. Positionen und Separatorvergleich zählen BIN2-Codeeinheiten.

Vertrag und Quelle: [TVF_SplitByCharacters.sql](../../Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql), [TVF_SplitByCharactersStatus.md](../../Modules/toolbelt.string.split-characters/Documentation/TVF_SplitByCharactersStatus.md).

<!-- Source/Vertrag SHA256: ccc2429b4df56d53f0b8dcdff342d5240611e0bb50f0adcbb5ddde634a2bc91d -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | nvarchar(max); höchstens 65536 UTF-16-Bytes. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | nvarchar(4000); höchstens 64 unterschiedliche UTF-16-Codeeinheiten; Duplikate zählen einmal; NUL ist ungültig. |
| `@KeepEmpty` | `bit` | `1` | Input | bit=1; NULL entspricht 1; 0 verwirft leere Tokens. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a,b',N',',1) ORDER BY Ordinal;
```

## toolbelt_string.USP_CompareTextPairs

Modul `toolbelt.string.text-pairs` · Version `1.0.0` · `USP`

Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.

Vertrag und Quelle: [USP_CompareTextPairs.sql](../../Modules/toolbelt.string.text-pairs/Source/USP_CompareTextPairs.sql), [USP_CompareTextPairs.md](../../Modules/toolbelt.string.text-pairs/Documentation/USP_CompareTextPairs.md).

<!-- Source/Vertrag SHA256: 6d707d72323feb38ca671fa4581ab766977842175ca3b77577fde89ae1eb083e -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PairsTable` | `sysname` | `NULL` | Input | Lokale #Temp mit PairOrdinal bigint, LeftText und RightText nvarchar(max). Ordinals nicht NULL und eindeutig, inklusive negativer Werte. |
| `@Algorithm` | `nvarchar(max)` | `NULL` | Input | Bytegenau levenshtein, osa oder jaro-winkler; global für alle Paare. |
| `@MaxDistance` | `int` | `NULL` | Input | Unveränderte Distanzschwelle; bei Jaro ausschließlich NULL. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |
| `@MaxPairs` | `int` | `10000` | Input | 1..100000, alle Inputzeilen zählen. |
| `@MaxTotalTextBytes` | `bigint` | `2097152` | Input | 1..16777216, beide DATALENGTH-Textseiten auch bei NULL-Gegenseite. |
| `@MaxTotalWork` | `bigint` | `16777216` | Input | 1..67108864 konservative UTF16-Produktcharge mit kanonischem Paircap; keine tatsächliche CPU-Zählung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert sortierten SELECT; vorhandene lokale #Temp empfängt atomaren Helper+Insert. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append nach ResultTable-Vertrag. NULL bedeutet 0. |
| `@Debug` | `tinyint` | `0` | Input | Messages ohne Textpayload; NULL bedeutet 0. |
| `@Hilfe` | `bit` | `0` | Input | 1 ausschließlich Help, ohne Tabellen-/Dependency-/Transaktionsprüfung. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max)); INSERT #Pairs VALUES(1,N'kitten',N'sitting'); EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'levenshtein';
```

Hilfe:

```sql
EXEC toolbelt_string.USP_CompareTextPairs @Hilfe=1;
```

## toolbelt_tsql.TVF_ParseScriptNodes

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert die AST-Knoten eines begrenzten T-SQL-Skripts.

Vertrag und Quelle: [TVF_ParseScriptNodes.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptNodes.sql), [TVF_ParseScriptNodes.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptNodes.md).

<!-- Source/Vertrag SHA256: 9657b4943511c46cf494135bdd3140481c7b15f76292eda7793b35ca7b90da8a -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | T-SQL-Quelltext; wird analysiert, nicht ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Exakt 80,90,100,110,120,130,140,150,160 oder 170; NULL = 160. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | 1 parst mit QUOTED_IDENTIFIER ON, 0 mit OFF. |
| `@MaxInputBytes` | `int` | `2097152` | Input | ScriptParser: 1–2097152 Eingabebytes. |
| `@MaxNestingDepth` | `int` | `100` | Input | ScriptParser: 1–256; NULL entspricht dem Default 100. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.TVF_ParseScriptNodeProperties

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Eigenschaften der geparsten T-SQL-AST-Knoten.

Vertrag und Quelle: [TVF_ParseScriptNodeProperties.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptNodeProperties.sql), [TVF_ParseScriptNodeProperties.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptNodeProperties.md).

<!-- Source/Vertrag SHA256: 2bd1dc0a82d98a120f5a22a04cccfaa27259ef80b172a4a89e929bb57a533f5f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | T-SQL-Quelltext; wird analysiert, nicht ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Exakt 80,90,100,110,120,130,140,150,160 oder 170; NULL = 160. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | 1 parst mit QUOTED_IDENTIFIER ON, 0 mit OFF. |
| `@MaxInputBytes` | `int` | `2097152` | Input | ScriptParser: 1–2097152 Eingabebytes. |
| `@MaxNestingDepth` | `int` | `100` | Input | ScriptParser: 1–256; NULL entspricht dem Default 100. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.TVF_TokenizeScript

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Tokens eines T-SQL-Skripts.

Vertrag und Quelle: [TVF_TokenizeScript.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_TokenizeScript.sql), [TVF_TokenizeScript.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_TokenizeScript.md).

<!-- Source/Vertrag SHA256: 68dba98db17d7b97481e884e7a58d3dac9e94921524ee90de8bada096edd2c98 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | T-SQL-Quelltext; wird analysiert, nicht ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Exakt 80,90,100,110,120,130,140,150,160 oder 170; NULL = 160. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | 1 parst mit QUOTED_IDENTIFIER ON, 0 mit OFF. |
| `@MaxInputBytes` | `int` | `2097152` | Input | ScriptParser: 1–2097152 Eingabebytes. |
| `@MaxNestingDepth` | `int` | `100` | Input | ScriptParser: 1–256; NULL entspricht dem Default 100. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.TVF_ParseScriptErrors

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Parserfehler eines T-SQL-Skripts, ohne das Skript auszuführen.

Vertrag und Quelle: [TVF_ParseScriptErrors.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptErrors.sql), [TVF_ParseScriptErrors.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptErrors.md).

<!-- Source/Vertrag SHA256: 524a775ff2f9e5e89fd3b92fc924b90a12370dc17c16942a5f26c9579c0c96b5 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | T-SQL-Quelltext; wird analysiert, nicht ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Exakt 80,90,100,110,120,130,140,150,160 oder 170; NULL = 160. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | 1 parst mit QUOTED_IDENTIFIER ON, 0 mit OFF. |
| `@MaxInputBytes` | `int` | `2097152` | Input | ScriptParser: 1–2097152 Eingabebytes. |
| `@MaxNestingDepth` | `int` | `100` | Input | ScriptParser: 1–256; NULL entspricht dem Default 100. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.USP_ExplainSsisDataFlow

Modul `toolbelt.tsql.ssis-debug` · Version `1.0.0` · `USP`

Aktuelle DTSX-Debuganalyse ohne Profil-Opt-in; editierbare typisierte JSON-Vorlage mit Entwurfswerten und Herkunft, vollständiger Strukturpfad und geordnete DebugScript-Batches für auflösbare Ziele. Ressourcen über benannte SQL-Parameter; keine SSIS-/Quell-SQL-Ausführung während der Analyse. Teilweise validiert und unveröffentlicht.

Vertrag und Quelle: [USP_ExplainSsisDataFlow.sql](../../Modules/toolbelt.tsql.ssis-debug/Source/USP_ExplainSsisDataFlow.sql), [USP_ExplainSsisDataFlow.md](../../Modules/toolbelt.tsql.ssis-debug/Documentation/USP_ExplainSsisDataFlow.md).

<!-- Source/Vertrag SHA256: fe174f8f264c9c4e179cb91f63a3657bf60fe6e876715c0d6f36d702e604fbf8 -->

Voraussetzung: Windows SQL Server 2019/2022/2025, separate UNSAFE-Assembly, exakter Parser 2.0.1/ScriptDom-Pin und Result Table 1.0.0. Aktuelle Liefer- und Prüfgrenzen gemäß CurrentInstallation.md; historische Nachweise bleiben getrennt.

Voraussetzung: DTSX als Bytes übergeben. Für explain explizite Same-instance-Datenbank-/Connection-Allowlist und vorhandene vollständige Metadatensicht; keine Credentials im JSON. Nur values der vollständigen Bindings-Vorlage bearbeiten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PackageBytes` | `varbinary(max)` | `NULL` | Input | Genau ein unterstütztes DTSX-Paket als UTF-8-/UTF-16-Binärwert. Die Standardgrenze beträgt128MiB und ist mit @MaxPackageBytes konfigurierbar. Kein Dateizugriff. |
| `@Operation` | `varchar(32)` | `N'explain'` | Input | Exakt bindings-template oder explain; NULL ungültig. |
| `@ProjectContext` | `nvarchar(max)` | `NULL` | Input | Optionaler Projektparameter-/Connection-Kontext als JSON-Schema2; keine Credentials und keine Ressourcenoptionen. |
| `@Bindings` | `nvarchar(max)` | `NULL` | Input | Zurückgegebene Schema-2-Vorlage; values bearbeiten, Herkunftsmetadaten unverändert zurückgeben. Im Template-Modus NULL. |
| `@CatalogBindings` | `nvarchar(max)` | `NULL` | Input | Explizite Same-instance-Allowlist mit defaultDatabase, databases und connections; Template verlangt NULL. |
| `@TargetFlow` | `varchar(64)` | `NULL` | Input | Ausgegebene Zielfluss-ID; NULL berücksichtigt alle Ziele getrennt. |
| `@InspectStage` | `varchar(64)` | `NULL` | Input | NULL liefert Zielskript und Verzeichnis; all alle Stufen; konkrete ID verlangt TargetFlow. |
| `@LookupPolicies` | `nvarchar(max)` | `NULL` | Input | Optionale gebundene Auswahlordnung je Lookup. Standard beliebige, einmal materialisierte Auswahl. |
| `@ComparisonCollation` | `sysname` | `NULL` | Input | Bekannte explizite Vergleichscollation; NULL verwendet die zugeordnete Defaultdatenbank. |
| `@TSqlVersion` | `smallint` | `150` | Input | Exakt150,160 oder170; kein automatischer Dialektwechsel. |
| `@MaxPackageBytes` | `bigint` | `134217728` | Input | Maximale Paketgröße in Bytes; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxXmlCharacters` | `bigint` | `134217728` | Input | Maximale XML-Zeichen; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxXmlNodes` | `bigint` | `1048576` | Input | Maximale XML-Knoten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxModelNodes` | `bigint` | `262144` | Input | Maximale Modellknoten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxModelEdges` | `bigint` | `1048576` | Input | Maximale Modellkanten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxComponents` | `bigint` | `4096` | Input | Maximale Komponenten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxPaths` | `bigint` | `8192` | Input | Maximale Datenflusskanten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxColumns` | `bigint` | `65536` | Input | Maximale Spaltenmetadaten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxInputs` | `bigint` | `8192` | Input | Maximale gebundene Eingaben; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxJsonDocumentBytes` | `bigint` | `4194304` | Input | Maximale UTF-16-Bytes je Eingabe-JSON; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxAllJsonBytes` | `bigint` | `8388608` | Input | Maximale UTF-16-Bytes aller Eingabe-JSONs; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxJsonNodes` | `bigint` | `131072` | Input | Maximale JSON-Knoten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxExpressionBytes` | `bigint` | `4194304` | Input | Maximale UTF-16-Bytes je SSIS-Ausdruck; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxExpressionTokens` | `bigint` | `262144` | Input | Maximale Ausdruckstokens; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxExpressionNodes` | `bigint` | `131072` | Input | Maximale Ausdrucksknoten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxPlanUnits` | `bigint` | `8192` | Input | Maximale geprüfte Debugplaneinheiten; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxCatalogObjects` | `bigint` | `4096` | Input | Maximale Katalogobjekte; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxCatalogQueries` | `bigint` | `4096` | Input | Maximale Katalogabfragen; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxParserCalls` | `bigint` | `32768` | Input | Maximale SQL-Parseraufrufe; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxArtifacts` | `bigint` | `65536` | Input | Maximale Ergebnisartefakte; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxDiagnostics` | `bigint` | `16384` | Input | Maximale Diagnosen; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxSqlArtifactBytes` | `bigint` | `2097152` | Input | Maximale UTF-16-Bytes je SQL-Artefakt; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxTotalOutputBytes` | `bigint` | `134217728` | Input | Maximale UTF-16-Bytes der Gesamtausgabe; 0 unbegrenzt, NULL oder negativ ungültig. |
| `@MaxAnalysisMilliseconds` | `bigint` | `0` | Input | Analysezeitbudget in Millisekunden; Standard 0 = unbegrenzt, NULL oder negativ ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein Resultset; sonst vorhandene lokale Temp-Tabelle nach Standardvertrag. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt,1 hängt an; NULL entspricht0. Kanonischer ResultTable-Helper. |
| `@Debug` | `tinyint` | `0` | Input | Nur redigierte Messages mit Ablauf/Zählern, keine Secretwerte oder zusätzlichen Resultsets. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich standardisierte Hilfe, ignoriert alle Fach-/ResultTable-/Debugparameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;
```

```sql
-- @PackageBytes vom Client übergeben.
DECLARE @PackageBytes varbinary(max)=NULL;
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@Operation='bindings-template';
```

```sql
-- @PackageBytes vom Client übergeben; konfigurierbare Zähler direkt als SQL-Parameter.
DECLARE @PackageBytes varbinary(max)=NULL;
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@Operation='bindings-template',@MaxComponents=0,@MaxPackageBytes=0;
```

Hilfe:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;
```

## toolbelt_validation.TVF_ParseSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Prüft und zerlegt eine Version nach SemVer 2.0.0.

Vertrag und Quelle: [TVF_ParseSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_ParseSemanticVersion.sql), [TVF_ParseSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_ParseSemanticVersion.md).

<!-- Source/Vertrag SHA256: c85f7eb55e9b3181be227d07182f66933efab6f54ad6a55b315f28229ad26682 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | Strikte SemVer-2.0.0-Version, z. B. 1.2.3-alpha.1+build.7. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_validation.TVF_ParseSemanticVersion(N'1.2.3-alpha.1+build.7');
```

## toolbelt_validation.TVF_CompareSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Vergleicht zwei SemVer-Versionen; Build-Metadaten ändern die fachliche Rangfolge nicht.

Vertrag und Quelle: [TVF_CompareSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_CompareSemanticVersion.sql), [TVF_CompareSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_CompareSemanticVersion.md).

<!-- Source/Vertrag SHA256: de3a0f6cdbd8b2c9915372e0e81316d2f840318dbafe857e7afd981a1d22679a -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | Linke SemVer-Version. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | Rechte SemVer-Version. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion(N'1.2.3', N'2.0.0');
```

## toolbelt_validation.TVF_SemanticVersionSortKey

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version.

Vertrag und Quelle: [TVF_SemanticVersionSortKey.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_SemanticVersionSortKey.sql), [TVF_SemanticVersionSortKey.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_SemanticVersionSortKey.md).

<!-- Source/Vertrag SHA256: a96bf8d4b1bd3837a9d39d2bd4bc254f7aa380b6f0e72f3b64728c35059a280c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | Strikte SemVer-2.0.0-Version, z. B. 1.2.3-alpha.1+build.7. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_validation.TVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7');
```

## toolbelt_validation.SVF_CompareSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `SVF`

Vergleicht zwei SemVer-Versionen; Build-Metadaten ändern die fachliche Rangfolge nicht.

Vertrag und Quelle: [SVF_CompareSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/SVF_CompareSemanticVersion.sql), [SVF_CompareSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_CompareSemanticVersion.md).

<!-- Source/Vertrag SHA256: f2064e8a38c4581c4e40cc0872ae225d833fed280306baaf7cce8b46b054f843 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | Linke SemVer-Version. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | Rechte SemVer-Version. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_validation.SVF_CompareSemanticVersion(N'1.2.3', N'2.0.0') AS ResultValue;
```

## toolbelt_validation.SVF_SemanticVersionSortKey

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `SVF`

Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version.

Vertrag und Quelle: [SVF_SemanticVersionSortKey.sql](../../Modules/toolbelt.validation.semantic-version/Source/SVF_SemanticVersionSortKey.sql), [SVF_SemanticVersionSortKey.md](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_SemanticVersionSortKey.md).

<!-- Source/Vertrag SHA256: 247a7bb895f06d7566adbacbbab32f78b16e7569e62780da1c1a68f5b93287fa -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | Strikte SemVer-2.0.0-Version, z. B. 1.2.3-alpha.1+build.7. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_validation.SVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7') AS ResultValue;
```

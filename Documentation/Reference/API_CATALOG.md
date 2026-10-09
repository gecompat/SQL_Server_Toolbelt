# SQL Server Toolbelt Beispielkatalog

<!-- Generiert mit Tests/Documentation/generate_api_catalog.py --write; nicht direkt bearbeiten. -->

158 öffentliche Schnittstellen aus 43 Modulen. Dieser Katalog ergänzt die verbindlichen Objektverträge mit kurzen Erklärungen, Source-Signaturen und synthetischen Beispielaufrufen.

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

<!-- Source/Vertrag SHA256: 7f5bd962372b2375e53b259ce493c6f07383caffa2a6777451d8f8d4f6b65237 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | ZIP-Binary; harte Readergrenze 268435456 Bytes. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter ordinaler Entryname; kein abgeleiteter Dateipfad. |
| `@RootAlias` | `sysname` | `NULL` | Input | Vorhandener freigegebener Filesystem-Root-Alias. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Expliziter relativer Zielpfad; Zielverzeichnis muss bestehen. |
| `@MaxEntryBytes` | `bigint` | `104857600` | Input | 1 bis 2147483647 unkomprimierte Entrybytes; geerbte Obergrenze, kein Kapazitätsnachweis. |
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

<!-- Source/Vertrag SHA256: 7748c659d851d66b3787d02f2486b3ed9ce0d576484f1d0bac02bd09c3ced227 -->

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

<!-- Source/Vertrag SHA256: 21461f883dd7265578df504602ea474bc2e47725683a7f6fc04bdc8fbbff4e37 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | ZIP-Container als In-memory-BLOB. Das harte Providerlimit beträgt 268435456 Bytes. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter Entry-Name. Der CLR-Provider vergleicht ordinal und case-sensitive. |
| `@MaxEntryBytes` | `bigint` | `104857600` | Input | Obere Grenze für die tatsächlich ausgegebene unkomprimierte Entry-Größe. |
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

<!-- Source/Vertrag SHA256: 2137ee0c115336aff82ac89cf32c04f2565507f8e3fdbaaa721132563aeb5ba4 -->

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

<!-- Source/Vertrag SHA256: 4c4b06b47f8258c312f9a51fc1534dd6969ce35ac2cb00db18d6c5b512950a2a -->

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

<!-- Source/Vertrag SHA256: 678c73d5069f6b7b5ef799080a3a13bfe37fa95dc9ab48b7b378b8e9918ebb61 -->

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

<!-- Source/Vertrag SHA256: bf4bcaf81ff2904a525bfd1056bf56fba95202ec6aea3f63c6874364df46bfde -->

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

<!-- Source/Vertrag SHA256: c6bf20233ed72bc7a5a5b8eff81ac04d6c6b29e7b688dbdd5c2b9a5019ef0e6b -->

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

<!-- Source/Vertrag SHA256: 7870723c41924194fdeaa06076350b627ff2780092b23035febda8158d27764d -->

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

<!-- Source/Vertrag SHA256: b7ad44dc8eaf0077d2f6088ed61e87e57a58f3133fff392492aea25b55c8d3db -->

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

<!-- Source/Vertrag SHA256: 105e96f941befbd7ab2c7c81f9eaf1952c4d2180e6f2cca07f64be5df4e3f30c -->

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

<!-- Source/Vertrag SHA256: 58ea5d032aa1f55fa1c676bef7170d505d652dbebeda58d1a0a9f1182c470d10 -->

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

<!-- Source/Vertrag SHA256: 0af89d9227a7932d41a83fd907514c7cf058886e394c0c36afdc6413ace137e0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Base64- oder Base64URL-Text; keine implizite Zeichenkodierung des decodierten Ergebnisses. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_Base64Decode(N'SGk=') AS ResultValue;
```

## toolbelt_conversion.TVF_IntegerToBase

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `TVF`

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Vertrag und Quelle: [TVF_IntegerToBase.sql](../../Modules/toolbelt.conversion.integer-base/Source/TVF_IntegerToBase.sql), [TVF_IntegerToBase.md](../../Modules/toolbelt.conversion.integer-base/Documentation/TVF_IntegerToBase.md).

<!-- Source/Vertrag SHA256: f6ec7f408fbad36a825f3e52f6d406490c37a1c37edad5e329b386350359dc29 -->

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

<!-- Source/Vertrag SHA256: a5c16ef1376b6aacd0c929a1a26481f2285da598bac3afedf5c2d1bb5999a7dc -->

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

<!-- Source/Vertrag SHA256: 74ada3cc847d1fc749c45638f101699e6b7b90e8d43955002f2251421525f174 -->

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

<!-- Source/Vertrag SHA256: 574c7805c6f53edbccedd4ff8ba735fa0d2b17118ce7c5b333460e71f0e47751 -->

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

<!-- Source/Vertrag SHA256: e9d6c89c7fa36a6fc1dae18e269fc9148e0a04aa6b2aed8da12d18ab54456aea -->

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

<!-- Source/Vertrag SHA256: 6bba08e2e9015d5d54b70d013605267fced073954134aa6366f1da57c93107b6 -->

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

<!-- Source/Vertrag SHA256: 415ba128dca75a590bd74fd4560cffd0b89b06328234cf5f838eea2a69c70f5d -->

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

<!-- Source/Vertrag SHA256: cb75bec54b73f2ce7f3bfc0624bebfe5c64a8b6770293b1611a1a3b63962912a -->

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

<!-- Source/Vertrag SHA256: e00408bc4a9fbbde5a273896161dce9f93a6b0953b443b2a2630157d56a5e49c -->

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

<!-- Source/Vertrag SHA256: 1aa1cfd4fbab3941b62d070ce8f4b01b9f15eae049a452d02226cf26f42c5d8e -->

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

<!-- Source/Vertrag SHA256: b6e61dddac332225683b49bf50f888bac823c7925324fa66e3773bb72865a5eb -->

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

<!-- Source/Vertrag SHA256: f4be51eff557a0ea6613d716fcf50e6c9918832335b0eb1ac0c1cd6c0a5d0bb8 -->

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

<!-- Source/Vertrag SHA256: 49d412e5d51a810c1a4eb78f5fd5b6b2053b24594f49f7ea245dbb9cc676216c -->

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

<!-- Source/Vertrag SHA256: a91eee6fbbaf104781d80385a2d92653ef37f965d0ca287ad7ebc868ac5bc23c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'a%20b%2F%C3%A4') AS ResultValue;
```

## toolbelt_core.USP_WriteConsoleMessage

Modul `toolbelt.core.console-message` · Version `1.0.0` · `USP`

Gibt einen langen Unicode-Text vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.

Vertrag und Quelle: [USP_WriteConsoleMessage.sql](../../Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql), [USP_WriteConsoleMessage.md](../../Modules/toolbelt.core.console-message/Documentation/USP_WriteConsoleMessage.md).

<!-- Source/Vertrag SHA256: b1beac06a353d8f550fcb74dcf5abe51df7faca9ac7c8ae3dc63f946d51a194e -->

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

<!-- Source/Vertrag SHA256: 9f623525e92e57089dd7c053fcfe3aa0544e043b8f3c0e12958cb0e6348a32cd -->

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

Vertrag und Quelle: [VW_Events.sql](../../Modules/toolbelt.core.event-log/Source/VW_Events.sql), [EVENT_LOG_OBJECTS.md](../../Modules/toolbelt.core.event-log/Documentation/EVENT_LOG_OBJECTS.md).

<!-- Source/Vertrag SHA256: ab14e1b100d66df4a942d02b712bca00a37aa82fab097c9b8f32b925c3a749b7 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_Events;
```

## toolbelt_core.USP_WriteEvent

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.

Vertrag und Quelle: [USP_WriteEvent.sql](../../Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql), [EVENT_LOG_OBJECTS.md](../../Modules/toolbelt.core.event-log/Documentation/EVENT_LOG_OBJECTS.md).

<!-- Source/Vertrag SHA256: 214e8f440f1a03cbaa88f924bc546e95492cf65c7e36a30ad16b42d751080d31 -->

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

Vertrag und Quelle: [USP_DeleteEventsBefore.sql](../../Modules/toolbelt.core.event-log/Source/USP_DeleteEventsBefore.sql), [EVENT_LOG_OBJECTS.md](../../Modules/toolbelt.core.event-log/Documentation/EVENT_LOG_OBJECTS.md).

<!-- Source/Vertrag SHA256: bccf57d65f7af15cc12b43c70a45c9e14460a40dc4ff5bdb6d94b1765a036c2d -->

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

## toolbelt_core.TVF_ExecutionCancellationStatus

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `TVF`

Liest den registrierten kooperativen Abbruchstatus einer Ausführung.

Vertrag und Quelle: [TVF_ExecutionCancellationStatus.sql](../../Modules/toolbelt.core.execution-cancel/Source/TVF_ExecutionCancellationStatus.sql), [EXECUTION_CANCELLATION_OBJECTS.md](../../Modules/toolbelt.core.execution-cancel/Documentation/EXECUTION_CANCELLATION_OBJECTS.md).

<!-- Source/Vertrag SHA256: 18228015c20b540a8d55de9b0df9c8b1886142d8bd94da40b589c7be7d619fbe -->

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

Vertrag und Quelle: [SVF_IsCancellationRequested.sql](../../Modules/toolbelt.core.execution-cancel/Source/SVF_IsCancellationRequested.sql), [EXECUTION_CANCELLATION_OBJECTS.md](../../Modules/toolbelt.core.execution-cancel/Documentation/EXECUTION_CANCELLATION_OBJECTS.md).

<!-- Source/Vertrag SHA256: eb6abfacd5b08e76ba484f1b051f6e90517d7069dfb4681bbc4eb57fb5753ed2 -->

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

Vertrag und Quelle: [USP_RequestExecutionCancellation.sql](../../Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql), [EXECUTION_CANCELLATION_OBJECTS.md](../../Modules/toolbelt.core.execution-cancel/Documentation/EXECUTION_CANCELLATION_OBJECTS.md).

<!-- Source/Vertrag SHA256: fa634ad65277a055b80e9735b38bffeb19412f8a7719183bc390a2e44649f0da -->

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

Vertrag und Quelle: [TVF_CurrentExecutionContext.sql](../../Modules/toolbelt.core.execution-context/Source/TVF_CurrentExecutionContext.sql), [EXECUTION_CONTEXT_OBJECTS.md](../../Modules/toolbelt.core.execution-context/Documentation/EXECUTION_CONTEXT_OBJECTS.md).

<!-- Source/Vertrag SHA256: 3c0fd7162115de2dc3108347869ec427c528641b43776e522c9776fe2bbcbd61 -->

Keine Eingabeparameter.

```sql
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
```

## toolbelt_core.SVF_CurrentExecutionId

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `SVF`

Liest die Execution-ID der aktuellen Session.

Vertrag und Quelle: [SVF_CurrentExecutionId.sql](../../Modules/toolbelt.core.execution-context/Source/SVF_CurrentExecutionId.sql), [EXECUTION_CONTEXT_OBJECTS.md](../../Modules/toolbelt.core.execution-context/Documentation/EXECUTION_CONTEXT_OBJECTS.md).

<!-- Source/Vertrag SHA256: 8c8c3b3e19368dd865098668509e7bceeffb7e7a32de5552b6d70156c3efdba8 -->

Keine Eingabeparameter.

```sql
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ResultValue;
```

## toolbelt_core.USP_BeginExecution

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `USP`

Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.

Vertrag und Quelle: [USP_BeginExecution.sql](../../Modules/toolbelt.core.execution-context/Source/USP_BeginExecution.sql), [EXECUTION_CONTEXT_OBJECTS.md](../../Modules/toolbelt.core.execution-context/Documentation/EXECUTION_CONTEXT_OBJECTS.md).

<!-- Source/Vertrag SHA256: 336bc67e085c1aa50437348ed9aa1945bbabf545e53f51ee41d17dff0be609cf -->

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

Vertrag und Quelle: [USP_SetExecutionContext.sql](../../Modules/toolbelt.core.execution-context/Source/USP_SetExecutionContext.sql), [EXECUTION_CONTEXT_OBJECTS.md](../../Modules/toolbelt.core.execution-context/Documentation/EXECUTION_CONTEXT_OBJECTS.md).

<!-- Source/Vertrag SHA256: 41c18fe7a81e0810e1cb0ea37e670e340d8f7c206575437784a5f661f7f22c19 -->

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

Vertrag und Quelle: [USP_EndExecution.sql](../../Modules/toolbelt.core.execution-context/Source/USP_EndExecution.sql), [EXECUTION_CONTEXT_OBJECTS.md](../../Modules/toolbelt.core.execution-context/Documentation/EXECUTION_CONTEXT_OBJECTS.md).

<!-- Source/Vertrag SHA256: f739735d5c753179811f0ad2c0c0ac9454165ade91a01f194a65aa031f079f48 -->

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

<!-- Source/Vertrag SHA256: a2db9843c8603a9152bb4b9ec693d03e4a5ec0581aae3a8cb5a181476c696456 -->

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

<!-- Source/Vertrag SHA256: 9657459b8e41bbc3fe78d27ae94893da71196617b03fb0b6943832040b16b99e -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `int` | `kein Default` | Input | Erster int-Wert der Reihe. |
| `@Stop` | `int` | `kein Default` | Input | Inklusive int-Ober- oder Untergrenze, sofern erreichbar. |
| `@Step` | `int` | `NULL` | Input | Schrittweite; NULL beziehungsweise DEFAULT löst die Richtung automatisch auf. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1);
```

## toolbelt_core.USP_PrepareResultTable

Modul `toolbelt.core.result-table` · Version `1.0.0` · `USP`

Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein.

Vertrag und Quelle: [USP_PrepareResultTable.sql](../../Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql), [USP_PrepareResultTable.md](../../Modules/toolbelt.core.result-table/Documentation/USP_PrepareResultTable.md).

<!-- Source/Vertrag SHA256: 59d5bd2b2c2ba02c8c80309fc55b6f369b1c8250a3fb65e90cb202097103882a -->

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

Vertrag und Quelle: [VW_SecondSessionProviders.sql](../../Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql), [SECOND_SESSION_OBJECTS.md](../../Modules/toolbelt.core.second-session/Documentation/SECOND_SESSION_OBJECTS.md).

<!-- Source/Vertrag SHA256: 604192e568944cd8c4fe0f0b7cd82e3443d8529838ea8b2bd5afde3e66f28074 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_SecondSessionProviders;
```

## toolbelt_core.USP_ConfigureSecondSessionLoopback

Modul `toolbelt.core.second-session` · Version `1.1.0` · `USP`

Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.

Vertrag und Quelle: [USP_ConfigureSecondSessionLoopback.sql](../../Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql), [SECOND_SESSION_OBJECTS.md](../../Modules/toolbelt.core.second-session/Documentation/SECOND_SESSION_OBJECTS.md).

<!-- Source/Vertrag SHA256: d84e897c7b2ce050ed1bee6049aba4a9ff0a21ca1593c53db6a3a52ca077f740 -->

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

Vertrag und Quelle: [USP_ExecuteWorkTypeInNewSession.sql](../../Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql), [SECOND_SESSION_OBJECTS.md](../../Modules/toolbelt.core.second-session/Documentation/SECOND_SESSION_OBJECTS.md).

<!-- Source/Vertrag SHA256: 4d7720fdb486f2da4e485336009390ce7d184ef57089b3143f1141e403fdd26a -->

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

Vertrag und Quelle: [VW_WorkQueue.sql](../../Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: e61b45d4addba048110db16d5dcd76581304c0603b4d3e91833fbfe370e5b729 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueue;
```

## toolbelt_core.VW_WorkQueueBarrierBlockers

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `VIEW`

Zeigt aktive Claim-Generationen, die eine Gruppenbarriere blockieren.

Vertrag und Quelle: [VW_WorkQueueBarrierBlockers.sql](../../Modules/toolbelt.core.work-queue/Source/VW_WorkQueueBarrierBlockers.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 173b50cbd31e38593ed2d0ba54b3c305ae11007a29b8674cee86984a11f07821 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;
```

## toolbelt_core.USP_EnqueueWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

Vertrag und Quelle: [USP_EnqueueWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: a99234dd6df65f4972b583746c8b46115822e1ca0ebdd415c2dc86e31f8a765c -->

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

Vertrag und Quelle: [USP_EnqueueWorkWithPolicy.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 8db3415e980fb66b5cbabf5da0a50dfb7e1aec79a2c61eebe0f0ae4a95780704 -->

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

Vertrag und Quelle: [USP_EnqueueBarrierWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueBarrierWork.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 0a7c47dc9887bb77dd1b56769e8c17cac58c0e71f89daf618660355a73be5314 -->

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

Vertrag und Quelle: [USP_ClaimWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_ClaimWork.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 09c5eb4932a76230a8b4d6fd85b5a6ec22ad6b20378bc6d9d89ca440684b6c70 -->

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

Vertrag und Quelle: [USP_RenewWorkLease.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RenewWorkLease.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 126dbb86e911f760049c11fe8893fb59b4ef74f94c1b272164b2ada80f8dd260 -->

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

Vertrag und Quelle: [USP_RecoverExpiredWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RecoverExpiredWork.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 9da6127845c2ae42f3da9764d5f1f9376d0a49a04ad7d0c4908b5b01d4859ecc -->

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

Vertrag und Quelle: [USP_CompleteWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_CompleteWork.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 409ed0ae0a74d020b54272ad2a00107e9b442a5ec113195e6e2d35a5cdbfc80e -->

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

Vertrag und Quelle: [USP_FailWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_FailWork.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 059e79d13589a0c6d3baee22451a7ac53569d528e4e57f9878dddc183d423036 -->

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

Vertrag und Quelle: [USP_ScheduleWorkRetry.sql](../../Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetry.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 3102a6c40e49114a5be11bae3dfe1a792ca6ef9a48d8f6030e5360430b8ef7d7 -->

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

Vertrag und Quelle: [USP_RequeueDeadLetter.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: ce1624dfdd2b3784f146e3593e0e439112a86f94f1ffba794389f594e14e6e18 -->

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

Vertrag und Quelle: [USP_GetWorkStatus.sql](../../Modules/toolbelt.core.work-queue/Source/USP_GetWorkStatus.sql), [WORK_QUEUE_OBJECTS.md](../../Modules/toolbelt.core.work-queue/Documentation/WORK_QUEUE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 16756a7d6116b6409baa92c329662b07b3ecae58ac0f6a1f8ba91a8ee6166332 -->

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

## toolbelt_core.VW_WorkTypes

Modul `toolbelt.core.work-type` · Version `1.1.0` · `VIEW`

Zeigt registrierte Work Types und deren Konfiguration.

Vertrag und Quelle: [VW_WorkTypes.sql](../../Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql), [WORK_TYPE_OBJECTS.md](../../Modules/toolbelt.core.work-type/Documentation/WORK_TYPE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 9e4eead5f9e8ddeed5a3d961721c4c73e84e5d1e3927023f8e389b8b5a8c855e -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkTypes;
```

## toolbelt_core.USP_RegisterWorkType

Modul `toolbelt.core.work-type` · Version `1.1.0` · `USP`

Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.

Vertrag und Quelle: [USP_RegisterWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_RegisterWorkType.sql), [WORK_TYPE_OBJECTS.md](../../Modules/toolbelt.core.work-type/Documentation/WORK_TYPE_OBJECTS.md).

<!-- Source/Vertrag SHA256: e1cc231d047c5810e4d7042a7e019b9b12eb9d544d77f09d343c19805f3b7cc6 -->

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

Modul `toolbelt.core.work-type` · Version `1.1.0` · `USP`

Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.

Vertrag und Quelle: [USP_DisableWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_DisableWorkType.sql), [WORK_TYPE_OBJECTS.md](../../Modules/toolbelt.core.work-type/Documentation/WORK_TYPE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 5c140c2fb4e7eb152aa793f6ee3f643d339063139ba323c55ed17c5f8496697c -->

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

Modul `toolbelt.core.work-type` · Version `1.1.0` · `USP`

Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.

Vertrag und Quelle: [USP_RemoveWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_RemoveWorkType.sql), [WORK_TYPE_OBJECTS.md](../../Modules/toolbelt.core.work-type/Documentation/WORK_TYPE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 5ee46ae41189ee9e9a106552a221e036671ab6833a606b7a838f85c961323827 -->

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

Modul `toolbelt.core.work-type` · Version `1.1.0` · `USP`

Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.

Vertrag und Quelle: [USP_ResolveWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_ResolveWorkType.sql), [WORK_TYPE_OBJECTS.md](../../Modules/toolbelt.core.work-type/Documentation/WORK_TYPE_OBJECTS.md).

<!-- Source/Vertrag SHA256: 93644e989e57fba9601415f469ee6908c37a1b4edf4561b6bfe8c79291d1fdf2 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@RequireEnabled` | `bit` | `1` | Input | 1 verlangt einen aktiven Work Type. |
| `@RequireExecutableByCaller` | `bit` | `1` | Input | 1 prüft die vorhandene Ausführbarkeit des Handlers. |
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

<!-- Source/Vertrag SHA256: f3b228d750b87f5587b8bbc50b51f76586fe33c2912cd5bc6e88e1749e9c1bbc -->

Voraussetzung: Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkerStatus;
```

## toolbelt_core.VW_WorkerExecutionStatus

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `VIEW`

Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads.

Vertrag und Quelle: [VW_WorkerExecutionStatus.sql](../../Modules/toolbelt.core.worker-control/Source/VW_WorkerExecutionStatus.sql), [VW_WorkerExecutionStatus.md](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerExecutionStatus.md).

<!-- Source/Vertrag SHA256: cad3699d9983d91dd1dbe2b4a04f1057830984d76aa6ab542437d703c578e66d -->

Voraussetzung: Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkerExecutionStatus;
```

## toolbelt_core.USP_ClaimWorkerWork

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Fachliche Fassade der privaten atomaren Managed-Admission.

Vertrag und Quelle: [USP_ClaimWorkerWork.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ClaimWorkerWork.sql), [USP_ClaimWorkerWork.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ClaimWorkerWork.md).

<!-- Source/Vertrag SHA256: e58eaf9b00f5608236f087bf4237c7552e1f3f72b177092d3c42a02e83234cae -->

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

<!-- Source/Vertrag SHA256: 4175900343850d6897d398dca533b6e21e41fb0310a49f6502e0cff920ed36a9 -->

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

<!-- Source/Vertrag SHA256: 49dead4eda9ab9c3b49df4cbe7cb9d83c0250091f5137e005f89a1a3bfff4588 -->

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

<!-- Source/Vertrag SHA256: 4c5c3a377566d29c9294dc1b79aeb23758c30f8b14bd3f0d9e6552de2925e393 -->

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

<!-- Source/Vertrag SHA256: e3a8307263d6a9d2c4f17c528557be274386280f3a7f2911a809bb955a75d9a8 -->

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

<!-- Source/Vertrag SHA256: a858601f8f7adfef8567e9626ef7528c2df4a547cd765a3da2384775f4edf951 -->

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

<!-- Source/Vertrag SHA256: fa175ea8d3d123e32f4706ea935120594eb431369dac71985ba53962698fb8a8 -->

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

<!-- Source/Vertrag SHA256: da5c9e891a2e7185a48dabeb02e4f8abb9c3a5bdadb4bf642d7c5085a08d2e6d -->

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

<!-- Source/Vertrag SHA256: 6e30ec9a28a0a8c25ae9e60e5664faa139d82a4621ddb9b4345bacdbbe4fcbc9 -->

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

<!-- Source/Vertrag SHA256: 4b81cb8e921a9e72ba403e8e2f8e4bedbbc9e159780e4b4513955b7f4169e428 -->

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

<!-- Source/Vertrag SHA256: d5fd6a8dc32444b0f164eec92621095c996a0d87a5c85628e61a708d1b46d1f1 -->

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

<!-- Source/Vertrag SHA256: 398da55eb9f3bb298a0422655d02c3617520bcfd56c582f5f19a4e7ee0bbfe45 -->

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

<!-- Source/Vertrag SHA256: 3cd9f8a50a9dd7539110ad653fed15bf1e1661e4fdbd4c226a5f2c658a7fa456 -->

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

<!-- Source/Vertrag SHA256: 47e17e45202b379ee15eb09a08ec308030f20705d006e304dae14fc28870af87 -->

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

<!-- Source/Vertrag SHA256: fd15d7d974f5fa1ce5366f0bfe842c88a0a7acbeac0a0ba6539fc41174866ed7 -->

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

<!-- Source/Vertrag SHA256: d8b12b07da2dcfea24bc2c5ba7f6f859f36c3f678f548b363a7facade481c745 -->

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

<!-- Source/Vertrag SHA256: 6cd48830b08eac5ea2db9e7cca66fafbc47da58e68d6b3b440e2a5ffdf0c6a49 -->

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

<!-- Source/Vertrag SHA256: 13732ac3cfeffaa29d9f4dbfc47a62308f4542a25a4593c489c187343f369376 -->

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

<!-- Source/Vertrag SHA256: bf1a39510887d6ef90285dee0edddfca1dbc5b763d57c760c10face3da1dc9d4 -->

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

<!-- Source/Vertrag SHA256: f1d54a4613eb6bf8f1183db0db7fb979b6013c610645ca07340166acf7ea3dba -->

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

<!-- Source/Vertrag SHA256: 206984bdbc8c467778e70f524e6a33a695ec62612597664fc6c57be2168fb555 -->

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

<!-- Source/Vertrag SHA256: ed0417b7184bd746bfcbee639a4afb18f93254b03b43c7e150bea86d9bd15c97 -->

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

<!-- Source/Vertrag SHA256: f189dcfc152f8bdc8ac834f4a3b6edcc5f9c8e786f23ec38c96d999329ac6ec5 -->

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

<!-- Source/Vertrag SHA256: a0384ab3fd00655029a9b93705dcc16bebb020641c9e3cfb8f8b3bd72d8f3c9a -->

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

<!-- Source/Vertrag SHA256: 5a806c2ee458b1237984350caed9647a5af79139bfe7a5c779305de8262ee250 -->

Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `kein Default` | Input | Absoluter Pfad zur Datei. UNC-Pfade sind erlaubt. Relative Pfade, ..-Segmente und Pfade außerhalb der Allowlist werden abgelehnt. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionales Limit. Wenn die gelesene Datei mehr Bytes enthält, wird ein Validierungsfehler zurückgegeben, der Inhalt bleibt jedoch NULL. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter des USP-Vertrags. Version 1 erzeugt keine Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: passende Allowlist und eigene synthetische Datei.
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=N'C:\ExampleRoot\sample.bin', @MaxBytes=1048576;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=NULL, @Hilfe=1;
```

## toolbelt_file.USP_LoadTextFile

Modul `toolbelt.file.content` · Version `1.0.0` · `USP`

Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen.

Vertrag und Quelle: [USP_LoadTextFile.sql](../../Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql), [USP_LoadTextFile.md](../../Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md).

<!-- Source/Vertrag SHA256: 15c04ebe9f3afa17c93dcdb0aeb66d14b919e6f26290f446ea789d6861d8ddbb -->

Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `kein Default` | Input | Absoluter Pfad zur Datei. UNC-Pfade sind erlaubt. Relative Pfade, ..-Segmente und Pfade außerhalb der Allowlist werden abgelehnt. |
| `@FallbackEncoding` | `nvarchar(128)` | `N'Windows-1252'` | Input | Codepage für Dateien ohne BOM. Unterstützt werden Windows-1252 und SQL_Latin1_General_CP1_CI_AS äquivalente 8-Bit-Codepages. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionales Limit. Wenn die gelesene Datei mehr Bytes enthält, wird ein Validierungsfehler zurückgegeben, der Inhalt bleibt jedoch NULL. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter des USP-Vertrags. Version 1 erzeugt keine Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
-- Voraussetzung: passende Allowlist und eigene synthetische Datei.
EXEC toolbelt_file.USP_LoadTextFile @FilePath=N'C:\ExampleRoot\sample.txt', @MaxBytes=1048576;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_LoadTextFile @FilePath=NULL, @Hilfe=1;
```

## toolbelt_file.USP_ParseCsv

Modul `toolbelt.file.csv-memory` · Version `1.0.0` · `USP`

Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle.

Vertrag und Quelle: [USP_ParseCsv.sql](../../Modules/toolbelt.file.csv-memory/Source/USP_ParseCsv.sql), [USP_ParseCsv.md](../../Modules/toolbelt.file.csv-memory/Documentation/USP_ParseCsv.md).

<!-- Source/Vertrag SHA256: 71313aaa0705888c7246d02e32f348e12b90c0bb6df822a4592d73b15eb838e9 -->

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

<!-- Source/Vertrag SHA256: 83dffe079b49d77c6c2ec07bea1f6b2427e7930ff319836233f15f33dd4d197c -->

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

<!-- Source/Vertrag SHA256: a7deb3d507443bfe721b81182473a53841e5930687778d18135c87f85a4d380b -->

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

<!-- Source/Vertrag SHA256: 2d9033f89ea96a1b4678b913a5acadb433e3c8ee17cddc9a0c01d7dcde50ecab -->

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

<!-- Source/Vertrag SHA256: 0247b0ae90bc5daf11ef62c0dd74d267a6fc94f722e18aa12d7b489144a0f512 -->

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

<!-- Source/Vertrag SHA256: f9962bdcd6906193d9013d52a5f9ed39ee09875379c5ebc303db36be3647fece -->

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

<!-- Source/Vertrag SHA256: fb0f84cb00125890d6b18faea13daab47458989ea7c51ea262f153352d577eee -->

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

<!-- Source/Vertrag SHA256: 9f5a0cf3231abf1f55e7675fd43be6f85029c4b7d620a1bdfb99dc33fdd34be1 -->

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

<!-- Source/Vertrag SHA256: 59560732647bf78327ba5559df2e03d497a43bbd0c8854f8cc2df82c2305f8fd -->

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

<!-- Source/Vertrag SHA256: dc6dc5ae73e39fe036b28ab330a119ee7290979157eb7305ea73926a6b351871 -->

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

<!-- Source/Vertrag SHA256: 72d88fbe1f277551413f2a2a3eaa1f370ca28e3741c31521183880f05686a0a5 -->

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

<!-- Source/Vertrag SHA256: f7c4180865e65e14f448d3824a71c8462e16e5f09d78e0c7bf17918ba1b176ba -->

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

<!-- Source/Vertrag SHA256: 31869a885113333c415677e4feaef4eec00c081542cab1234cba93de21159cad -->

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

<!-- Source/Vertrag SHA256: 1d087c2f7f26620cf35114609c93462a0f4651187df6334f42576bf61cf835e2 -->

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

<!-- Source/Vertrag SHA256: 3740cdde54d3f09be809da3fe9cc33e9139fc74e85ea9b9c17050c339b03d09f -->

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

<!-- Source/Vertrag SHA256: 3897e83ff07301d22348733e7f83f69c67ff215fddf430ffd7dbe9fbf0a8931b -->

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

<!-- Source/Vertrag SHA256: 1dc9ef98796a953e79b02a85f477028868973f39869a0b07f2bbaa2b40c46764 -->

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

Vertrag und Quelle: [JsonAggregates.sql](../../Modules/toolbelt.json.constructors/Source/JsonAggregates.sql), [JSON_AGGREGATES.md](../../Modules/toolbelt.json.constructors/Documentation/JSON_AGGREGATES.md).

<!-- Source/Vertrag SHA256: f46ac7f16e6c42fa7854e2b015f2075612c5936240658ee435288b538f5b597a -->

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

Vertrag und Quelle: [JsonAggregates.sql](../../Modules/toolbelt.json.constructors/Source/JsonAggregates.sql), [JSON_AGGREGATES.md](../../Modules/toolbelt.json.constructors/Documentation/JSON_AGGREGATES.md).

<!-- Source/Vertrag SHA256: f46ac7f16e6c42fa7854e2b015f2075612c5936240658ee435288b538f5b597a -->

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

<!-- Source/Vertrag SHA256: 23151b299e705b82055cdf1fd0ca4ce8cf76bd4a5db5744bed7cae4b8f3a59a0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Zu prüfendes JSON-Dokument; SQL-NULL in Json oder Path liefert PathExists=NULL, ungültiges JSON liefert0. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | Begrenzter JSON-Pfad mit $, Schlüsseln, nullbasierten Array-Indizes oder Wildcards; maximal4000 UTF-16-Codeeinheiten. Keine Ranges, Indexlisten oder last. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExists(N'{"items":[1,2]}', N'$.items[0]');
```

## toolbelt_json.TVF_ResolveJsonPointer

Modul `toolbelt.json.pointer` · Version `1.0.0` · `TVF`

Löst einen RFC6901-Pointer mit exakten Keys und unterscheidet FOUND, MISSING, JSON_NULL, SQL_NULL und INVALID. Der freigegebene feste128er-Guard gibt darüber DEPTH_LIMIT vor JSON_SYNTAX zurück.

Vertrag und Quelle: [TVF_ResolveJsonPointer.sql](../../Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql), [TVF_ResolveJsonPointer.md](../../Modules/toolbelt.json.pointer/Documentation/TVF_ResolveJsonPointer.md).

<!-- Source/Vertrag SHA256: dc6bfe78505445e34f91de6e5442be801a73a764af76f7c39419f9d31199a022 -->

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

<!-- Source/Vertrag SHA256: cb89a74c6d6f969403daf8eecc02c560e08e92291a5022b4016cf30e95e42dc5 -->

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

Modul `toolbelt.metadata.table-clone` · Version `4.1.0` · `USP`

Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.

Vertrag und Quelle: [USP_ScriptTableClone.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql), [USP_ScriptTableClone.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md).

<!-- Source/Vertrag SHA256: 9290b1be57167f307067ba30ceba3f78025a052650b36c2aa83994b44cee4523 -->

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

Modul `toolbelt.metadata.table-clone` · Version `4.1.0` · `USP`

Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie.

Vertrag und Quelle: [USP_ExecuteTableClone.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_ExecuteTableClone.sql), [USP_ExecuteTableClone.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ExecuteTableClone.md).

<!-- Source/Vertrag SHA256: 4ac5d6a2405153bdf03cb4d6cfa0f0c69ee3196f7a0356b2e1947062b33bd2c7 -->

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

Modul `toolbelt.metadata.table-clone` · Version `4.1.0` · `USP`

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

<!-- Source/Vertrag SHA256: fe76a94284907e2c8c4e9994b77936b35c00d3a2a21825219e2603110d532e42 -->

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

<!-- Source/Vertrag SHA256: a685e34ab8b49533a4fd82be206d31a9ff22bdc6f1c177f1a95aaab21e6593bc -->

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

<!-- Source/Vertrag SHA256: f759df0a0323f2d289db58dc28d83e2daca248b167ada1941f94e939162250e1 -->

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

<!-- Source/Vertrag SHA256: eaef95d478e338a462a71fc3e47756d004a7eae5ef5bd761927425fe6b30dc6e -->

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

<!-- Source/Vertrag SHA256: fe348b64f26cbb64d8b95cc4e30acecab1a3577cdc38b99cf79f1b7244de5fe7 -->

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

<!-- Source/Vertrag SHA256: 1e536ac12c861d40c616423711cf7bff4c4f35a4a2adee6473ac7676caec2030 -->

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

<!-- Source/Vertrag SHA256: 348258b44f21db5729158ac438315c82b26bc406c695be2f4a08a1307adb6351 -->

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

<!-- Source/Vertrag SHA256: 81a81b396be9a23eb678578180aee4c20d65ff79fab6bbeba3067a96472d6435 -->

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

<!-- Source/Vertrag SHA256: 85fc741e7dd72f963d0bf3b0d2c63714b8199e99a53b9e2baffe2e8f344d5be7 -->

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

<!-- Source/Vertrag SHA256: d987756ea0d27defdac7b3eabaa59f9553c14c560b36d346c42234e97917d6e9 -->

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

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [REGEX_FUNCTIONS.md](../../Modules/toolbelt.string.regex/Documentation/REGEX_FUNCTIONS.md).

<!-- Source/Vertrag SHA256: 1bd7ae9af96eb3b8633afce9a4b7b4a358c430200a052138ae51e79d87a78aa7 -->

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

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [REGEX_FUNCTIONS.md](../../Modules/toolbelt.string.regex/Documentation/REGEX_FUNCTIONS.md).

<!-- Source/Vertrag SHA256: 1bd7ae9af96eb3b8633afce9a4b7b4a358c430200a052138ae51e79d87a78aa7 -->

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

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [REGEX_FUNCTIONS.md](../../Modules/toolbelt.string.regex/Documentation/REGEX_FUNCTIONS.md).

<!-- Source/Vertrag SHA256: 1bd7ae9af96eb3b8633afce9a4b7b4a358c430200a052138ae51e79d87a78aa7 -->

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

<!-- Source/Vertrag SHA256: a8035edfac4e6bdce5fbff65b767319cd3fc863f2c12b730d9e6b96bd0f668e8 -->

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

<!-- Source/Vertrag SHA256: 03f6d9fccbba63e78bb07dec086a6766ae88f94963158730e5f926f50852e992 -->

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

<!-- Source/Vertrag SHA256: 0b689f04f6ce42ddf852a918f49932aad7d13a93496966c44581e2edba41a136 -->

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

<!-- Source/Vertrag SHA256: 99c2de2b89d2da9ee18d60a11518d7e8681bf73d45d197b14d1be802ad2d18b0 -->

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

<!-- Source/Vertrag SHA256: 8f496e5e182b3c0be7de4671a0515d5250a9988aa37b956cb7b65b87851e2ee3 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Literal interpretierte Menge einzelner Separatorzeichen. |
| `@KeepEmpty` | `bit` | `1` | Input | 1 erhält leere Tokens; 0 verwirft sie. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,b;;c', N',;', 1);
```

## toolbelt_string.USP_CompareTextPairs

Modul `toolbelt.string.text-pairs` · Version `1.0.0` · `USP`

Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.

Vertrag und Quelle: [USP_CompareTextPairs.sql](../../Modules/toolbelt.string.text-pairs/Source/USP_CompareTextPairs.sql), [USP_CompareTextPairs.md](../../Modules/toolbelt.string.text-pairs/Documentation/USP_CompareTextPairs.md).

<!-- Source/Vertrag SHA256: 4e41b5b6077dc215f1a64a218600e3916fbdcb9c7bab9f2dd960d33603fe2e76 -->

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

Modul `toolbelt.tsql.script-parser` · Version `2.0.0` · `CLR_TVF`

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

Modul `toolbelt.tsql.script-parser` · Version `2.0.0` · `CLR_TVF`

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

Modul `toolbelt.tsql.script-parser` · Version `2.0.0` · `CLR_TVF`

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

Modul `toolbelt.tsql.script-parser` · Version `2.0.0` · `CLR_TVF`

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

## toolbelt_validation.TVF_ParseSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Prüft und zerlegt eine Version nach SemVer 2.0.0.

Vertrag und Quelle: [TVF_ParseSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_ParseSemanticVersion.sql), [TVF_ParseSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_ParseSemanticVersion.md).

<!-- Source/Vertrag SHA256: 3e8632e712c214464262d866f1d3926628b7cfecb8beddea3aa7667e8584b437 -->

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

<!-- Source/Vertrag SHA256: 6d427352cf2f89c1ec6178421c6384007cd1a7dc4400fcc4f30dac13b2f437b3 -->

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

<!-- Source/Vertrag SHA256: 1b0366cbe32dc20ae47218f77fefbf472b9a3ba178aae4b3a16fc785e28e5428 -->

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

<!-- Source/Vertrag SHA256: afcc7a6b7d0e92ab053737730c72fa9e97b23c32c4fded0fe2ed137fa38780b8 -->

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

<!-- Source/Vertrag SHA256: 5697a835e044384760aafce3b5e0d9a09ba7b17354f13432bf1ef3bc33041599 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | Strikte SemVer-2.0.0-Version, z. B. 1.2.3-alpha.1+build.7. |

Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.

```sql
SELECT toolbelt_validation.SVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7') AS ResultValue;
```

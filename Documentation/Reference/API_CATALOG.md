# SQL Server Toolbelt Beispielkatalog

<!-- Generiert mit Tests/Documentation/generate_api_catalog.py --write; nicht direkt bearbeiten. -->

168 öffentliche Schnittstellen aus 44 Modulen. Dieser Katalog ergänzt die verbindlichen Objektverträge mit kurzen Erklärungen, Source-Signaturen und synthetischen Beispielaufrufen.

Jedes Beispiel separat verwenden. Funktionen verlangen positionsbezogene Argumente; `DEFAULT` verwendet einen deklarierten Default, `NULL` kann davon abweichen. Prozeduren verwenden benannte Parameter. Vorlagen mit Handlern, Claims, Dateien oder Plan-Hashes erfordern die beschriebenen Voraussetzungen. Eine Syntaxvorlage ist kein Runtime-Nachweis.

Pflege und Generierung: [README](README.md).

## toolbelt_archive.USP_CreateZipFileFromEntries

Modul `toolbelt.archive.zip-files` · Version `1.0.0` · `USP`

Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.

Vertrag und Quelle: [USP_CreateZipFileFromEntries.sql](../../Modules/toolbelt.archive.zip-files/Source/USP_CreateZipFileFromEntries.sql), [USP_CreateZipFileFromEntries.md](../../Modules/toolbelt.archive.zip-files/Documentation/USP_CreateZipFileFromEntries.md).

<!-- Source/Vertrag SHA256: a4241728eb90ef1053f91076934b624638970074428ebc9582647cad15d0d9b5 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. Im Dateifassadenpfad zusätzlich kein #tbx_-Präfix oder eigener #ZipFiles_*Stage-Name. |
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; explizite Zieldatei, deren Verzeichnis bereits bestehen muss. ZIP-Namen werden nicht zu Zielpfaden. |
| `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
| `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. Dateifassade verlangt Namen 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Dateipublikation erfolgt vor SQL-Ausgabe und wird bei späterem Routingfehler nicht rückgängig gemacht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 0bf6f90b3d1ca315fcecabdc766f892f268f8853d3509e0a3e7da069ef08aaa1 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath. |
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Kein Entpacken mehrerer Entries oder automatisches mkdir. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/&lt;1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Datei wird vor SQL-Ausgabe publiziert und bleibt bei späterem Routingfehler bestehen. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 kurze Abschlussmessage ohne Pfade/Entrynamen/Payloads. Interner Reader/Writer laufen mit Debug=0, die optionale endgültige ResultTable erhält Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 45d6e9da9f3bb25b2b35bbfb8e36fc9106659ee2921f716213ec17bb14fa58f9 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. |
| `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
| `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 311dafb554dbf7af40c3ab759f5f548bb4edbcaea0939e4a3fc972d1dbf02425 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/&lt;1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad. |
| `@FailIfEncrypted` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 64840d3e5f60af70b4ea817afbd30ce8df26e4885d95bd2475a1b5c58b6fab78 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..10000 Central-Directory-Entries, Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 62ce6693db46d0a5daf129aa6da1f2a2a0d292b9bfebee152af3762151d57a0f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt links; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_binary.TVF_LeftShiftBigInt(255, 2);
```

## toolbelt_binary.TVF_RightShiftBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Verschiebt die Bits eines bigint-Werts logisch nach rechts.

Vertrag und Quelle: [TVF_RightShiftBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_RightShiftBigInt.sql), [TVF_RightShiftBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_RightShiftBigInt.md).

<!-- Source/Vertrag SHA256: 9ac66c42260bddb6abdc91601432f6aecb7963135cead596c1c5774f61351b35 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt logisch rechts, ohne Vorzeichenerweiterung; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_binary.TVF_RightShiftBigInt(255, 2);
```

## toolbelt_binary.TVF_BitCountBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Zählt gesetzte Bits im bigint-Wert.

Vertrag und Quelle: [TVF_BitCountBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_BitCountBigInt.sql), [TVF_BitCountBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_BitCountBigInt.md).

<!-- Source/Vertrag SHA256: 3adc33f927c95c20e3c331de0ac707c52754e5bb20bb9d358519e6fcefabafcb -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. Gezählt werden alle 64 Bits, einschließlich des Vorzeichenbits; -1 hat 64 gesetzte Bits. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_binary.TVF_BitCountBigInt(255);
```

## toolbelt_binary.TVF_GetBitBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Liest das Bit an einer nullbasierten Position.

Vertrag und Quelle: [TVF_GetBitBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_GetBitBigInt.sql), [TVF_GetBitBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_GetBitBigInt.md).

<!-- Source/Vertrag SHA256: 119e23aa08356d23f87f25fc4ff70f5888c0bca562306c7972966e5c039e998c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_binary.TVF_GetBitBigInt(255, 3);
```

## toolbelt_binary.TVF_SetBitBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Setzt oder löscht ein Bit an einer nullbasierten Position.

Vertrag und Quelle: [TVF_SetBitBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_SetBitBigInt.sql), [TVF_SetBitBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_SetBitBigInt.md).

<!-- Source/Vertrag SHA256: cb5498c210db35d5e47813591ed13839ed1357db3149b7dc8e49e62416c1c2cd -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern. |
| `@BitValue` | `int` | `1` | Input | Taxativ: 0 löscht das ausgewählte Bit; 1 setzt es (Default). Andere int-Werte ergeben IsValid=0/ValidationCode=11, sofern der Offset gültig ist. NULL ergibt NULL in Wert und Validierungsfeldern. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_binary.TVF_SetBitBigInt(255, 3, 1);
```

## toolbelt_conversion.TVF_Base64Encode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Codiert Binärdaten als Base64 oder Base64URL.

Vertrag und Quelle: [TVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql), [TVF_Base64Encode.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64Encode.md).

<!-- Source/Vertrag SHA256: a890c30e8dfc49df5120a42efc40a18592bddb088bcbe085758ba57ad27648d7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64Encode(0x4869, 0);
```

## toolbelt_conversion.TVF_Base64Decode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Decodiert Base64-Text zu Binärdaten.

Vertrag und Quelle: [TVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql), [TVF_Base64Decode.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64Decode.md).

<!-- Source/Vertrag SHA256: 87922e9c2c879ba721c3275dc776f7ee0eb0e60e3ac05fd95721378545da564f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64Decode(N'SGk=');
```

## toolbelt_conversion.SVF_Base64Encode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `SVF`

Codiert Binärdaten als Base64 oder Base64URL.

Vertrag und Quelle: [SVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql), [SVF_Base64Encode.md](../../Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Encode.md).

<!-- Source/Vertrag SHA256: eef4c3b664d6c8e51da04b79d172bda03764c3948a1ea172d6360c4470ec0c0b -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_Base64Encode(0x4869, 0) AS ResultValue;
```

## toolbelt_conversion.SVF_Base64Decode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `SVF`

Decodiert Base64-Text zu Binärdaten.

Vertrag und Quelle: [SVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql), [SVF_Base64Decode.md](../../Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Decode.md).

<!-- Source/Vertrag SHA256: 1ca8e89c95dd7db865f5eca0c1005fa40f9b98bff79fc3954215b772261604f5 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_Base64Decode(N'SGk=') AS ResultValue;
```

## toolbelt_conversion.TVF_Base64EncodeStatus

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Genau eine Zeile. OK enthält den Wert; LIMIT und SQL_NULL enthalten NULL. Der kanonische MSTVF-Kern prüft vor XML. Die bisherige TVF/SVF delegiert und liefert bei Überschreitung NULL.

Vertrag und Quelle: [TVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql), [TVF_Base64EncodeStatus.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64EncodeStatus.md).

<!-- Source/Vertrag SHA256: 9261cc035f98b5bd06149ac603f4e8806afa1320294336c46f91f2588f8419a1 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFE,0);
```

## toolbelt_conversion.TVF_Base64DecodeStatus

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL.

Vertrag und Quelle: [TVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql), [TVF_Base64DecodeStatus.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64DecodeStatus.md).

<!-- Source/Vertrag SHA256: f0446c2730e2603ad050ceef7ec05d3b3293e7ff9d931d96b38d8674c243c1e7 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('YWJj');
```

## toolbelt_conversion.TVF_IntegerToBase

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `TVF`

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Vertrag und Quelle: [TVF_IntegerToBase.sql](../../Modules/toolbelt.conversion.integer-base/Source/TVF_IntegerToBase.sql), [TVF_IntegerToBase.md](../../Modules/toolbelt.conversion.integer-base/Documentation/TVF_IntegerToBase.md).

<!-- Source/Vertrag SHA256: 4a578593ac1617d0ce8e89b189457a69e9c1906ae496d7afa53e611c3c99355b -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_IntegerToBase(255, '0123456789ABCDEF');
```

## toolbelt_conversion.TVF_TryBaseToInteger

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `TVF`

Decodiert einen Text anhand des angegebenen Alphabets in bigint.

Vertrag und Quelle: [TVF_TryBaseToInteger.sql](../../Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql), [TVF_TryBaseToInteger.md](../../Modules/toolbelt.conversion.integer-base/Documentation/TVF_TryBaseToInteger.md).

<!-- Source/Vertrag SHA256: 73c709fc5af9a9505bb3bec290657590dacbfff179dcd5e3736b01173c2b2775 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryBaseToInteger('FF', '0123456789ABCDEF');
```

## toolbelt_conversion.SVF_IntegerToBase

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `SVF`

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Vertrag und Quelle: [SVF_IntegerToBase.sql](../../Modules/toolbelt.conversion.integer-base/Source/SVF_IntegerToBase.sql), [SVF_IntegerToBase.md](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_IntegerToBase.md).

<!-- Source/Vertrag SHA256: 48a155da27c84a6a56b43436c6c2fb7e5a78650e3e95ee63ffde31e15dfd1e25 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_IntegerToBase(255, '0123456789ABCDEF') AS ResultValue;
```

## toolbelt_conversion.SVF_TryBaseToInteger

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `SVF`

Decodiert einen Text anhand des angegebenen Alphabets in bigint.

Vertrag und Quelle: [SVF_TryBaseToInteger.sql](../../Modules/toolbelt.conversion.integer-base/Source/SVF_TryBaseToInteger.sql), [SVF_TryBaseToInteger.md](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_TryBaseToInteger.md).

<!-- Source/Vertrag SHA256: 0b015c4938d3d5b95a657ce6b0fc76fdcbae32688f270c62ff8851547df3ad38 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_TryBaseToInteger('FF', '0123456789ABCDEF') AS ResultValue;
```

## toolbelt_conversion.TVF_TryCastBigInt

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft ASCII-Ganzzahltext und den exakten bigint-Bereich; liefert Value, Status und ErrorCode.

Vertrag und Quelle: [TVF_TryCastBigInt.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBigInt.sql), [TVF_TryCastBigInt.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBigInt.md).

<!-- Source/Vertrag SHA256: 7d333cec80ae234520bc677d2f800beab6956f72de79685ba41635741a0f2848 -->

Voraussetzung: Vorhandenes SELECT; genau eine Zeile, keine Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Dezimaltext mit mindestens einer Ziffer 0..9 und optional einem führenden + oder -. Führende Nullen/negative Null sind zulässig. Kein Trim, kein Unicode-Ziffernersatz, Dezimalpunkt, Exponent oder Tausendertrennzeichen. Zielbereich -9223372036854775808..9223372036854775807. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastBigInt(N'-9223372036854775808', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastDecimal

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft exakten decimal(38,18)-Bereich vor Skalenverlust; rundet niemals still.

Vertrag und Quelle: [TVF_TryCastDecimal.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDecimal.sql), [TVF_TryCastDecimal.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDecimal.md).

<!-- Source/Vertrag SHA256: d7ba9fa5f82c7aa34163a6d26140a7548e3a8a38cc7671a2c749be5098da5443 -->

Voraussetzung: Vorhandenes SELECT; Bereichsüberschreitung ist OUT_OF_RANGE, sonst nichtnull Fractionrest LOSSY.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Dezimaltext mit optional führendem +/-, mindestens einer Ganzzahlziffer und optional Punkt mit mindestens einer Nachkommastelle. Keine Kommas, Exponenten oder Spaces. Führende Nullen sind zulässig. Ziel decimal(38,18), maximal 20 Ganzzahl- und 18 relevante Nachkommastellen; weitere Nullen sind exakt entfernbar, weitere nichtnull Ziffern bedeuten LOSSY/SCALE. Ein Bereichsfehler hat davor Vorrang. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastDecimal(N'99999999999999999999.9999999999999999991', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastDate

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft exakt YYYY-MM-DD und den date-Kalenderbereich unabhängig von Sprache und DATEFORMAT.

Vertrag und Quelle: [TVF_TryCastDate.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDate.sql), [TVF_TryCastDate.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDate.md).

<!-- Source/Vertrag SHA256: 59b28516fd3f6e0dd7fa094632cbd2e42c699e965da34c8a3c1b321e5281189e -->

Voraussetzung: Vorhandenes SELECT; keine Zeit- oder Localeinterpretation.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau YYYY-MM-DD mit ASCII-Ziffern und Bindestrichen (10 UTF-16-Codeeinheiten); keine Uhrzeit oder Localeform. Gültiger gregorianischer SQL-date-Bereich 0001-01-01..9999-12-31; unmögliche Kalenderdaten ergeben OUT_OF_RANGE. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastDate(N'2024-02-29', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastDateTime2

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust.

Vertrag und Quelle: [TVF_TryCastDateTime2.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDateTime2.sql), [TVF_TryCastDateTime2.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDateTime2.md).

<!-- Source/Vertrag SHA256: e112747514e3764b7b4cf6cdfbc39a07ff7d2bbf54da749a549d1d4a60504aec -->

Voraussetzung: Vorhandenes SELECT; datetime2(7), keine Offset-/Zeitzoneninterpretation.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau YYYY-MM-DDTHH:mm:ss, optional gefolgt von Punkt und 1..7 ASCII-Nachkommastellen (großes T, insgesamt 19 oder 21..27 Codeeinheiten). Kein Z, Offset, Leerzeichen, 24-Uhr-Zeit, Schaltsekunde oder Rundung; gültiger SQL-datetime2(7)-Bereich. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastDateTime2(N'2024-02-29T23:59:59.1234567', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastBit

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Akzeptiert ausschließlich den Text0 oder1; native permissive Bitkonversion bleibt ausgeschlossen.

Vertrag und Quelle: [TVF_TryCastBit.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBit.sql), [TVF_TryCastBit.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBit.md).

<!-- Source/Vertrag SHA256: ef1b3e4d812473be5e830286f5e113f357088407647bb88cd1081400925053be -->

Voraussetzung: Vorhandenes SELECT; Bit2 und TRUE sind INVALID_FORMAT.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Taxativ als Text: N'0' ergibt bit 0; N'1' ergibt bit 1. Keine anderen Werte, Vorzeichen, TRUE/FALSE, Spaces oder Normalisierung; dies ist ein strikter Textparser und nicht die native bit-Konvertierung. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastBit(N'2', DEFAULT);
```

## toolbelt_conversion.TVF_TryCastUniqueIdentifier

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft vollständige GUID-Lexik im8-4-4-4-12-Muster vor Konversion; keine Suffixtrunkierung.

Vertrag und Quelle: [TVF_TryCastUniqueIdentifier.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastUniqueIdentifier.sql), [TVF_TryCastUniqueIdentifier.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastUniqueIdentifier.md).

<!-- Source/Vertrag SHA256: 51c0d85a79af4745220012d3df99289d3a505ff40af71bf82379d02e4c71f859 -->

Voraussetzung: Vorhandenes SELECT; Hexbuchstaben upper/lower zulässig, keine Braces.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau 36 ASCII-Codeeinheiten im Hexmuster 8-4-4-4-12, etwa N'00000000-0000-0000-0000-000000000001'. Hexziffern 0..9/A..F/a..f; Bindestriche an den vier festen Positionen. Keine Klammern, Präfixe, Spaces oder Suffixtrunkierung. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastUniqueIdentifier(N'00112233-4455-6677-8899-aabbccddeeff', DEFAULT);
```

## toolbelt_conversion.TVF_UriComponentEncode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Codiert eine URI-Komponente mit UTF-8 und Prozent-Escapes nach RFC 3986.

Vertrag und Quelle: [TVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql), [TVF_UriComponentEncode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncode.md).

<!-- Source/Vertrag SHA256: 17b0f4c57c7d231bb1d0b4c79e89901077bc5990346b050d4bd3dba58b034ba5 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncode(N'a b/ä');
```

## toolbelt_conversion.TVF_UriComponentDecode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

Vertrag und Quelle: [TVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql), [TVF_UriComponentDecode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentDecode.md).

<!-- Source/Vertrag SHA256: 8e06893fa21a4bf41aa807ffed6e4514588e887c2e411492460f34ef1d794b13 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecode(N'a%20b%2F%C3%A4');
```

## toolbelt_conversion.SVF_UriComponentEncode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `SVF`

Codiert eine URI-Komponente mit UTF-8 und Prozent-Escapes nach RFC 3986.

Vertrag und Quelle: [SVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentEncode.sql), [SVF_UriComponentEncode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/SVF_UriComponentEncode.md).

<!-- Source/Vertrag SHA256: 583ab2fd0edb9fa3c7d621d2622a4f6a337934476bc1b1d10daceacd08158133 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_UriComponentEncode(N'a b/ä') AS ResultValue;
```

## toolbelt_conversion.SVF_UriComponentDecode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `SVF`

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

Vertrag und Quelle: [SVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentDecode.sql), [SVF_UriComponentDecode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/SVF_UriComponentDecode.md).

<!-- Source/Vertrag SHA256: 03befd753d8248ee253ee93217e202f6d10fa263559b53714c7744511cf6a8cb -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'a%20b%2F%C3%A4') AS ResultValue;
```

## toolbelt_conversion.TVF_UriComponentEncodeStatus

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL oder LIMIT. Eingang vor UTF-8-Konvertierung/Series prüfen. Aus höchstens 32768 Codeeinheiten entstehen selbst bei drei UTF-8-Bytes und drei Escapezeichen je Byte höchstens 589824 UTF-16-Ausgabebytes; die 1-MiB-Grenze ist damit schon vor Aggregation abgesichert. Altfassaden liefern bei LIMIT NULL.

Vertrag und Quelle: [TVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql), [TVF_UriComponentEncodeStatus.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncodeStatus.md).

<!-- Source/Vertrag SHA256: 0f1d7184f20ce09416cf26e50a487b94157a3c53d131109d1c1ee1d8e8fe7798 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'Contoso €');
```

## toolbelt_conversion.TVF_UriComponentDecodeStatus

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL.

Vertrag und Quelle: [TVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql), [TVF_UriComponentDecodeStatus.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentDecodeStatus.md).

<!-- Source/Vertrag SHA256: 3d069256b8c43b731c6461127a1def8eb7c96827ea814319da098d6786af6595 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%E2%82%AC');
```

## toolbelt_core.USP_WriteConsoleMessage

Modul `toolbelt.core.console-message` · Version `1.0.0` · `USP`

Gibt einen langen Unicode-Text vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.

Vertrag und Quelle: [USP_WriteConsoleMessage.sql](../../Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql), [USP_WriteConsoleMessage.md](../../Modules/toolbelt.core.console-message/Documentation/USP_WriteConsoleMessage.md).

<!-- Source/Vertrag SHA256: 7bee0c6e1e9bd1935303173c92578a5e3a5e27cdf7c89ce5c6ebe62f8e73c1e7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Message` | `nvarchar(max)` | `NULL` | Input | Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen. |
| `@Immediate` | `bit` | `0` | Input | Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert ausschließlich Hilfe und ignoriert alle anderen Argumente; 0 führt die Messageausgabe aus (Default). NULL wird wie 0 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 990612b77da3bcfb10a0ce1a260f486c60fa7fc4697d207bf0f1d810f69a72d7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ErrorNumber` | `int` | `NULL` | Input | Fachlich erforderlich: positive int-Fehlernummer 1..2147483647, üblicherweise ERROR_NUMBER() im aufrufenden CATCH. Technischer Default NULL dient nur Help; NULL/&lt;=0 wird 51400. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Fachlich erforderlich: int 0..25 einschließlich, üblicherweise ERROR_SEVERITY() aus demselben CATCH. NULL/außerhalb ergibt 51401; technischer Default NULL nur für Help. |
| `@ErrorState` | `int` | `NULL` | Input | Fachlich erforderlich: int 0..255 einschließlich aus ERROR_STATE() im CATCH. NULL/außerhalb ergibt 51402; technischer Default NULL nur für Help. |
| `@ErrorProcedure` | `nvarchar(776)` | `NULL` | Input | Optionaler reiner Unicode-Text nvarchar(776), normalerweise ERROR_PROCEDURE() im CATCH, kein auszuführender Objektname. NULL bleibt NULL, leerer Text wird nicht besonders validiert. |
| `@ErrorLine` | `int` | `NULL` | Input | Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL (Default) ist erlaubt, 0/negativ ergibt 51403. |
| `@ErrorMessage` | `nvarchar(4000)` | `NULL` | Input | Fachlich erforderlicher Unicode-Fehlertext nvarchar(4000), normalerweise ERROR_MESSAGE() im CATCH. NULL, leer und nach SQL-Gleichheit leere reine Spacefolgen ergeben 51404; keine automatische Redigierung geheimer Inhalte. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Optionaler SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier). Default/NULL liest toolbelt.execution.id aus SESSION_CONTEXT mit TRY_CONVERT; fehlender/ungültiger Kontext bleibt NULL. Eine explizite ID muss keinem gespeicherten Kontext entsprechen. |
| `@AdditionalContext` | `nvarchar(4000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(4000), kein vorgeschriebenes JSON-Schema und keine Ausführung. NULL/leer wird unverändert ausgegeben; nur bereits bereinigte, für den Empfänger zulässige Zusatzinformation übergeben. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) gibt eine direkte Fehlerzeile aus, auch bei XACT_STATE()=-1. Sonst Name einer bereits vom Caller angelegten lokalen #Temp-Tabelle als sysname, z.B. N'#Envelope', keine globale oder mehrteilige Tabelle; ResultTable-Helper nötig. Bei uncommittable Caller zuerst Rollback, sonst 51406. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 bereitet Replace vor (Default), 1 hängt bei kompatibler ResultTable an; NULL wird vom kanonischen Helper wie 0 behandelt. Nur bei nicht-NULL ResultTable relevant. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) und NULL ohne Diagnose; 1..255 erzeugen eine abstrakte Informationsmeldung ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur Hilfe vor Fachvalidierung; 0 (Default) und NULL führen die Fachoperation aus. Im Hilfemodus sind die fachlich erforderlichen Error*-Werte nicht nötig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: ee5a6dd447561adee9115c35aa761694357a3ebd0d83f9389d70da60ed311a5a -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_Events;
```

## toolbelt_core.USP_WriteEvent

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.

Vertrag und Quelle: [USP_WriteEvent.sql](../../Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql), [USP_WriteEvent.md](../../Modules/toolbelt.core.event-log/Documentation/USP_WriteEvent.md).

<!-- Source/Vertrag SHA256: e0dc7221baf6633ff784d452db012185b6b1d1ae575854891e25aa2b0adf307c -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EventName` | `varchar(128)` | `NULL` | Input | Fachlich erforderlicher lowercase-ASCII-Schlüssel varchar(128), LEN 3..128, beginnt mit a-z; weitere Zeichen ausschließlich a-z, 0-9, Punkt, Unterstrich oder Bindestrich, z.B. app.import.started. Kein Trim oder automatisches Lowercasing. Technischer Default NULL nur für Hilfe; NULL/leer/ungültige Lexik wird abgewiesen. |
| `@EventLevel` | `varchar(16)` | `'INFO'` | Input | Taxativ: TRACE = feinste Ablaufdetails; DEBUG = technische Diagnose; INFO = normale Information (Default und NULL); WARNING = Warnung; ERROR = Fehler; CRITICAL = kritischer Fehler. UPPER normalisiert die Schreibweise; SQL-Gleichheitsregeln gelten. Die Werte sind Klassifikationen, keine automatische Retry-, Abbruch- oder Filtersteuerung. |
| `@Category` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Kategorietext mit Zeichen A-Z, a-z, 0-9, Punkt, Unterstrich und Bindestrich. NULL und leer sind zulässig; keine automatische Normalisierung. |
| `@Message` | `nvarchar(4000)` | `NULL` | Input | Optionaler menschenlesbarer Unicode-Text nvarchar(4000); NULL/leer erlaubt. Er wird persistiert, nicht ausgeführt; Secrets/vertrauliche Inhalte müssen vorher bereinigt werden. |
| `@DataJson` | `nvarchar(max)` | `NULL` | Input | Optionaler JSON-Objekttext nvarchar(max), höchstens 65536 UTF-16-Bytes (64 KiB); Arrays/Scalarroots und ungültiges JSON werden abgewiesen. Nach Entfernen gewöhnlicher führender Spaces muss { folgen; führender Tab/CR/LF genügt dieser LTRIM-Prüfung nicht. NULL bedeutet keine Zusatzdaten; leer ist ungültig. Beispiel N'{"rows":12}'. |
| `@OccurredAtUtc` | `datetime2(7)` | `NULL` | Input | SQL-datetime2(7) als fachlicher UTC-Zeitpunkt, z.B. CONVERT(datetime2(7),'2026-10-30T12:00:00',126); kein Offset im Typ und keine Zeitzonenkonvertierung. NULL/Default verwendet SYSUTCDATETIME(). |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@SourceDatabaseName` | `sysname` | `NULL` | Input | Datenbankkennzeichnung als sysname (bis 128 UTF-16-Codeeinheiten), als reiner Name/Text. NULL/Default wird DB_NAME(); leer wird abgewiesen. Eine explizite Kennzeichnung wird nicht auf Existenz geprüft. |
| `@SourceSchemaName` | `sysname` | `NULL` | Input | Optionale Schemakennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Kein zusammengesetzter Objektname, keine Existenz- oder Rechteprüfung. |
| `@SourceObjectName` | `sysname` | `NULL` | Input | Optionale Objektkennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Text-Metadatum, keine Ausführung und keine Objektauflösung. |
| `@ErrorNumber` | `int` | `NULL` | Input | Optionale int-Fehlernummer aus ERROR_NUMBER(), NULL bedeutet kein Fehlerkontext. Anders als ErrorEnvelope wird hier keine Positivitätsprüfung dieses Feldes durchgeführt. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Optionaler int-Wert 0..25 einschließlich aus ERROR_SEVERITY(); NULL erlaubt, außerhalb Fehler. Die EventLevel-Klassifikation wird dadurch nicht automatisch geändert. |
| `@ErrorState` | `int` | `NULL` | Input | Optionaler int-Wert 0..255 einschließlich aus ERROR_STATE(); NULL erlaubt, außerhalb Fehler. |
| `@ErrorProcedure` | `sysname` | `NULL` | Input | Optionale Fehlerprocedure als sysname (höchstens 128 Codeeinheiten), etwa ERROR_PROCEDURE(); NULL/leer erlaubt, kein auszuführender Aufruf. |
| `@ErrorLine` | `int` | `NULL` | Input | Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL erlaubt, 0/negativ wird abgewiesen. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: db71a70bcb34573f8ebe28255f0b050525d4c46a928cfabb198f305d541ea66d -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeOccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich OccurredAtUtc &lt; Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/&gt;10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/&gt;100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT: Der Eingabewert wird immer auf 0 gesetzt, auch im Hilfemodus; danach Anzahl der in diesem Aufruf gelöschten Zeilen. Zum Empfangen eine bigint-Variable mit OUTPUT übergeben; Eingabe-NULL ist kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: a4064bd25afa4a345b2f3146a4b3eb6357cfe553bbe213056215746ae7ae1103 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeRecordedAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich RecordedAtUtc &lt; Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/&gt;10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/&gt;100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT: Der Eingabewert wird immer auf 0 gesetzt, auch im Hilfemodus; danach Anzahl der in diesem Aufruf gelöschten Zeilen. Zum Empfangen eine bigint-Variable mit OUTPUT übergeben; Eingabe-NULL ist kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 227c823f9f2e02aad01171e1923231d9654ef2bc68ccd20480e17735e18b0c94 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Fallback auf den aktuellen Kontext. Bei NULL oder fehlender Anforderung keine Zeile; bei vorhandener Anforderung genau eine nicht sensible Statuszeile. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
```

## toolbelt_core.SVF_IsCancellationRequested

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `SVF`

Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.

Vertrag und Quelle: [SVF_IsCancellationRequested.sql](../../Modules/toolbelt.core.execution-cancel/Source/SVF_IsCancellationRequested.sql), [SVF_IsCancellationRequested.md](../../Modules/toolbelt.core.execution-cancel/Documentation/SVF_IsCancellationRequested.md).

<!-- Source/Vertrag SHA256: 59f07360338ffba759ec4883a434a85def7fca09375f5dcda2c83daaf0d8aa21 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Kontextfallback. Rückgabe 1 bei vorhandener Anforderung, sonst 0, ausdrücklich auch bei NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS ResultValue;
```

## toolbelt_core.USP_RequestExecutionCancellation

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `USP`

Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.

Vertrag und Quelle: [USP_RequestExecutionCancellation.sql](../../Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql), [USP_RequestExecutionCancellation.md](../../Modules/toolbelt.core.execution-cancel/Documentation/USP_RequestExecutionCancellation.md).

<!-- Source/Vertrag SHA256: dae5648fb0b7e376b8302cb4074e7798479ed82e477bdec93d7efc7aa6ae1cd1 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Explizite Ziel-ID darf nicht die Null-GUID sein. NULL/Default verwendet den aktiven Execution Context; fehlt dann eine ID, entsteht ein Fehler. Keine aktive Callertransaktion zulässig. |
| `@CancellationReason` | `nvarchar(512)` | `NULL` | Input | Optionaler Unicode-Grund nvarchar(512), keine Ausführung und keine automatische Redigierung; keine Secrets übergeben. NULL/leer bzw. LEN=0 (reine Spaces) wird NULL. Bei wiederholter Anforderung derselben ID bleiben erster Grund und Zeitpunkt erhalten. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 13ab462d810dba33519175962add610903c5469854d28c741c1bbdfe8ea231ff -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | OUTPUT | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root bleiben NULL/leer so gespeichert; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root NULL/leer zulässig; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. |
| `@AllowNested` | `bit` | `1` | Input | Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: e3d0e8c3e9d4c6cdb19657a122082c53789d65c7f6861f27088ce6a66d516147 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL (Default) erhält die bisherige CorrelationId; eine explizite ID ersetzt sie. Es gibt hier kein Correlation-Clear-Flag. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearActor=1 verwenden; Actor muss dann NULL sein. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearTenant=1 verwenden; Tenant muss dann NULL sein. |
| `@ClearActor` | `bit` | `0` | Input | Taxativ für bit: 0 erhält den Actor bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Actor aus dem Sessionkontext. Bei 1 darf Actor auch nicht als Leertext übergeben werden, sondern muss NULL sein. |
| `@ClearTenant` | `bit` | `0` | Input | Taxativ für bit: 0 erhält den Tenant bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Tenant. Bei 1 muss Tenant NULL sein, auch Leertext ist ein Konflikt. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: dd0f1e1a8e787a76b5c5c6b5df83b25542b935696ac30f2fea4f72282498db7f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 8e3b50ad972c924028d43172b2164058e0c8028786477a8cb9f80ea3b717b245 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
| `@Step` | `bigint` | `NULL` | Input | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler.Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigInt(1, 5, 1);
```

## toolbelt_core.TVF_GenerateSeriesInt

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Erzeugt eine Folge von int-Werten einschließlich erreichbarem Endwert.

Vertrag und Quelle: [TVF_GenerateSeriesInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql), [TVF_GenerateSeriesInt.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesInt.md).

<!-- Source/Vertrag SHA256: 1fd59911c5eb647fc997fd40e96a7168a7d901faf72174ee3ed057d94eebd73c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `int` | `kein Default` | Input | Erster Wert im gesamten SQL-int-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
| `@Stop` | `int` | `kein Default` | Input | Inklusive Zielgrenze im SQL-int-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
| `@Step` | `int` | `NULL` | Input | Ganzzahlige Schrittweite als int. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler.Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1);
```

## toolbelt_core.TVF_GenerateSeriesBigIntStatus

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen.

Vertrag und Quelle: [TVF_GenerateSeriesBigInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql), [TVF_GenerateSeriesBigIntStatus.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigIntStatus.md).

<!-- Source/Vertrag SHA256: 5430377ddf160b130a11f8ff05bd92fe3b397eba9dd6e14784909e43280b81a3 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL. |
| `@Step` | `bigint` | `NULL` | Input | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,DEFAULT);
```

## toolbelt_core.USP_PrepareResultTable

Modul `toolbelt.core.result-table` · Version `1.0.0` · `USP`

Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein.

Vertrag und Quelle: [USP_PrepareResultTable.sql](../../Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql), [USP_PrepareResultTable.md](../../Modules/toolbelt.core.result-table/Documentation/USP_PrepareResultTable.md).

<!-- Source/Vertrag SHA256: 15c2796c4f91c849b9e95938cd61c3187e4856e6a203b4c08ad1b70cf7226e57 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ResultTableToAlter` | `sysname` | `NULL` | Input | Fachlich erforderliche, bereits existierende caller-lokale #Temp im selben sichtbaren Session-Scope; logischer Name 2..116 UTF-16-Einheiten, genau ein führendes # und kein reserviertes #tbx_-Präfix. Ein einzelner Identifier, kein DDL und keine Tabellenvariable/permanente/globale Tabelle. NULL ist nur technischer Help-Default. Darf nicht dieselbe Tabelle wie LikeTable sein. |
| `@LikeTable` | `nvarchar(776)` | `NULL` | Input | Fachlich erforderliche vorhandene Referenztabelle als #LocalTemplate, Schema.Table oder Database.Schema.Table, optional regulär quotierte Namensbestandteile. Keine einteilige permanente Tabelle, Server-/vierteilige Namen, Views, Synonyme oder ##Temps. NULL/leer ungültig. Referenzspalten müssen dem unterstützten einfügbaren Typ-/Metadatenvertrag in RESULT_TABLE_MODULE_DESIGN.md entsprechen; der Helper übernimmt Spaltenshape und keine fachlichen Zeilen. |
| `@KeepData` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 ersetzt/leert vorhandene Zielinhalte und baut nötigenfalls das Schema um (Default); 1 erhält vorhandene Zeilen und lehnt einen nötigen Schemaumbau bei nicht leerem Ziel mit 51025 ab. Ein leeres Ziel darf auch bei 1 angepasst werden. NULL wirkt wie 0. Keine Append-Operation des Helpers selbst; fachliche Zeilen fügt der Caller danach ein. |
| `@Debug` | `tinyint` | `0` | Input | Ganzzahl tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine Debugmessages, 1 Preflight/Ablauf, 2 zusätzlich zusammengefasste Metadaten/Schemaentscheidung, 3..255 zusätzlich normalisierte Referenzmetadaten und geplantes DDL. Die Schwellwerte gelten kumulativ; 255 besitzt im aktuellen Code keine weitere eigene Stufe. Nur Messages, kein Zusatzresultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 9716d7e39f4843130342e78a5879a7e42ea2d19164ed5a9fbfa198c482b495ec -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_SecondSessionProviders;
```

## toolbelt_core.USP_ConfigureSecondSessionLoopback

Modul `toolbelt.core.second-session` · Version `1.1.0` · `USP`

Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.

Vertrag und Quelle: [USP_ConfigureSecondSessionLoopback.sql](../../Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql), [USP_ConfigureSecondSessionLoopback.md](../../Modules/toolbelt.core.second-session/Documentation/USP_ConfigureSecondSessionLoopback.md).

<!-- Source/Vertrag SHA256: 17ef59e822eeb547f532540d6b631490bdf3afd0918fa1fde691dd8c1e6df38b -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an. |
| `@Enabled` | `bit` | `1` | Input | Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 91ef488952cc567a8b109d1f5120f068d42566607fcb70d7a4a5ac17d4def8ec -->

Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@SuppressResult` | `bit` | `0` | Input | Taxativ für bit: 0 liefert die Infrastruktur-Ergebniszeile oder routet sie nach ResultTable (Default/NULL); 1 unterdrückt nur diese Ausgabe nach erfolgreichem Remote-Handlerlauf und Returncodeprüfung. Mit nicht-NULL ResultTable unvereinbar. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 463753d307452b80f4bbb29519aa54e859a5d53837561c026529ef76e68326b8 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueue;
```

## toolbelt_core.VW_WorkQueueBarrierBlockers

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `VIEW`

Zeigt aktive Claim-Generationen, die eine Gruppenbarriere blockieren.

Vertrag und Quelle: [VW_WorkQueueBarrierBlockers.sql](../../Modules/toolbelt.core.work-queue/Source/VW_WorkQueueBarrierBlockers.sql), [VW_WorkQueueBarrierBlockers.md](../../Modules/toolbelt.core.work-queue/Documentation/VW_WorkQueueBarrierBlockers.md).

<!-- Source/Vertrag SHA256: c54caf0ba6f2b8d171b7beb85f59fb6d7fae22b7c05ff0f6cde541905a507454 -->

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;
```

## toolbelt_core.USP_EnqueueWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

Vertrag und Quelle: [USP_EnqueueWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql), [USP_EnqueueWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueWork.md).

<!-- Source/Vertrag SHA256: 2ddc7adbd07e37845909ed9d6903e389eb4e5bc1b390d3fa70f3c9108f4b559d -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser ältere Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: bc284e57cd26d5ed975e7fef0ac2e3838acb24eb013a628eba5cee40d51fdf49 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. |
| `@Priority` | `tinyint` | `0` | Input | Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz. |
| `@ExecutionGroup` | `varchar(128)` | `'default'` | Input | Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss &lt;= RetryMaxDelaySeconds sein. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. |
| `@ExecutionMode` | `varchar(16)` | `'SHARED'` | Input | Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 1c46ecf1625efaaa67bbfed35bc62f61419a8ab91ff577c2bc62aea6f0231b8e -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@ExecutionGroup` | `varchar(128)` | `NULL` | Input | Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Fachlich erforderlich; technischer Default NULL dient nur dem Hilfemodus. |
| `@Priority` | `tinyint` | `NULL` | Input | Fachlich erforderliche Ganzzahl 0..255 als tinyint. Technischer Default NULL dient nur Hilfe; bei NULL im Fachaufruf Fehler 51975. Der Wrapper setzt den Modus fest auf DRAIN_BARRIER; Callertransaktionen sind ausgeschlossen. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss &lt;= RetryMaxDelaySeconds sein. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 189cd5f421ab55969d46e5dae7f32d7a28bc77730f4aa1552dfe615014a2ba7d -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 0e18d9847ce3ddca3de7d377a01fe48305d6e4fb1642ece2f2c0a771deecdad4 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 3acb733c3b203e6ab5398d07cf2151efda690310fb781da1dd4ceb843883a00a -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MaxItems` | `int` | `100` | Input | Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/&gt;1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 1a5022395b2f809194b9d3f31223af08bbb1e213bfa92b75337bded946a2e2e4 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 502cce195a8176791511f4858d6561993d0eec1af6a0c5388bd3ba8c340a2140 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(max)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: f046ff4a93b58f1243e6504ce01867cb2a794e9f60ad1cb428c18c0ad68fe8c2 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden. |
| `@ResultTable` | `sysname` | `NULL` | Input | Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben. |
| `@KeepData` | `bit` | `0` | Input | bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: b1275c190dc59d4e52f144b0fa8d7ec3178cff4ef062863294b3e43e4d0195fe -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 046bfa3a1326b19224a3076e9de8b52bf8c5342e91d5b0d2b077911d84f55426 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. Liest Status; Payload und ClaimToken sind absichtlich nicht Teil dieser Oberfläche. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 1e0a3c185058823c49f43f225bb13235bd5a40cb07eb223974a49f303ecd24dd -->

Voraussetzung: Work-Type-Katalog 1.2.0, vorhandener Work Type und vorhandener Datenbankprincipal.

Voraussetzung: EXECUTE sowie CONTROL auf toolbelt_core.WorkTypePermission; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@Principal` | `sysname` | `NULL` | Input | Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig. |
| `@PermissionName` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig. |
| `@PermissionState` | `varchar(8)` | `'ALLOW'` | Input | Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 2ab2af413a49e98fb605992dda14c781fadde3a7348d09b915de840069b1e7e3 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Erforderlicher kanonischer varchar(128)-Schlüssel: LEN 3..128, beginnt a-z, danach ausschließlich a-z/0-9/Punkt/Unterstrich/Bindestrich. Lowercase wird verlangt, nicht hergestellt; keine abschließenden oder doppelten Punkte. Z.B. app.import.rows. NULL/leer ungültig; bestehende Registrierung folgt AllowUpdate/Reactivate/RowVersion. |
| `@HandlerSchema` | `sysname` | `NULL` | Input | Einzelner unquotierter Schemaname als sysname in der aktuellen Datenbank, nicht mehrteilig und kein SQL-Ausdruck. NULL/leer oder Schema sys ist unzulässig. Mit HandlerProcedure muss eine vorhandene, nicht von Microsoft ausgelieferte T-SQL- oder CLR-Procedure entstehen; Caller benötigt EXECUTE. |
| `@HandlerProcedure` | `sysname` | `NULL` | Input | Einzelner unquotierter Procedurename als sysname in HandlerSchema; keine Argumentliste oder Datenbankqualifikation. NULL/leer/fehlende Procedure bzw. fehlende Metadatensicht/EXECUTE wird abgewiesen. Registrierung führt den Handler nicht aus; der Dispatcher prüft den zum ParameterMode gehörenden Aufrufvertrag. |
| `@ParameterMode` | `varchar(16)` | `'NONE'` | Input | Taxativ nach UPPER-Normalisierung: NONE = Handleraufruf ohne Payload, PayloadContractJson muss NULL sein (Default und NULL); JSON_PAYLOAD = JSON-Payload-Modus, PayloadContractJson muss ein JSON-Objekt sein. Keine weiteren Modi; SQL-Space-Padding gilt beim Vergleich. |
| `@PayloadContractJson` | `nvarchar(4000)` | `NULL` | Input | Bei NONE ausschließlich NULL. Bei JSON_PAYLOAD erforderlicher JSON-Objekttext als nvarchar(4000), z.B. N'{"description":"synthetic payload"}'; nach LTRIM normaler Spaces muss { folgen. Leer/Array/Scalar/ungültiges JSON ist ungültig. Die Felder sind deklarative Metadaten; diese Procedure führt weder SQL noch eine allgemeine JSON-Schema-Validierung daraus aus. |
| `@DefaultTimeoutSeconds` | `int` | `300` | Input | Ganzzahl 1..86400 Sekunden einschließlich; Default/NULL=300. Wird als Work-Type-Metadatum gespeichert, nicht als Garantie eines autonomen harten Serverabbruchs. Andere Werte ungültig. |
| `@IsIdempotent` | `bit` | `0` | Input | Taxativ für bit: 0 = Handler nicht als idempotent gekennzeichnet (Default/NULL); 1 = deklarativ idempotent gekennzeichnet. Das Flag implementiert selbst keine Idempotenz oder Exactly-once-Ausführung. |
| `@Description` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL/leer erlaubt; keine besonderen Felder, keine Ausführung, keine automatische Redigierung. |
| `@AllowUpdate` | `bit` | `0` | Input | Taxativ für bit: 0 weist eine abweichende vorhandene Konfiguration ab (Default/NULL); 1 erlaubt deren Update. Ein identischer aktiver Eintrag bleibt auch mit 0 idempotent. Für die Reaktivierung eines deaktivierten Eintrags zusätzlich Reactivate beachten. |
| `@Reactivate` | `bit` | `0` | Input | Taxativ für bit: 0 lässt eine deaktivierte Registrierung nicht still reaktivieren (Default/NULL); 1 erlaubt ihre Reaktivierung. Bei gleichzeitig abweichender Konfiguration ist außerdem AllowUpdate=1 erforderlich. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Wird nur gegen einen vorhandenen Work Type geprüft; kein Eingabewert für die neue RowVersion. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: fb38c70e4fd3dd39c569b60ff6911399266c0cd0fb21e932355741926a06cf0a -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@DisabledReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), keine automatische Redigierung. Bei erster Deaktivierung wird der Wert einschließlich NULL gespeichert. Bei wiederholter Deaktivierung erhält NULL den vorhandenen Grund; ein expliziter Text einschließlich leer kann ihn ändern. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: ac7cbee85beafe39d8689f1cd9dcc7546a86c42ca9b8fb4eeaad1f03f9ce562a -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss bereits deaktiviert sein; aktive Einträge sind nicht entfernbar. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
| `@AllowDelete` | `bit` | `0` | Input | Taxativ für bit: 1 ist die ausdrückliche Zustimmung zum irreversiblen Entfernen; 0 (Default) und NULL werden vor der Entfernung abgewiesen. Der Work Type muss zusätzlich deaktiviert sein. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 5a9eb3f37dd219e25f952ab2a05a0c0954a347a0da7286c1d823b7ed133359e0 -->

Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@RequireEnabled` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren. |
| `@RequireExecutableByCaller` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung. |
| `@RequiredPermission` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY. |
| `@SuppressResult` | `bit` | `0` | Input | Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597). |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 9e37dcdfa32a47bc3f689f3987f80ce23e5229b12639d328a0ffb190f0fe1459 -->

Voraussetzung: Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkerStatus;
```

## toolbelt_core.VW_WorkerExecutionStatus

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `VIEW`

Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads.

Vertrag und Quelle: [VW_WorkerExecutionStatus.sql](../../Modules/toolbelt.core.worker-control/Source/VW_WorkerExecutionStatus.sql), [VW_WorkerExecutionStatus.md](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerExecutionStatus.md).

<!-- Source/Vertrag SHA256: c3d15b7896d8caf5947310e046eb51dd7431139774e0e15e892e08a24054e1da -->

Voraussetzung: Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

Keine Eingabeparameter.

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkerExecutionStatus;
```

## toolbelt_core.USP_ClaimWorkerWork

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Fachliche Fassade der privaten atomaren Managed-Admission.

Vertrag und Quelle: [USP_ClaimWorkerWork.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ClaimWorkerWork.sql), [USP_ClaimWorkerWork.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ClaimWorkerWork.md).

<!-- Source/Vertrag SHA256: 52fec142cbc0931b533957a6897017128be5ed012280370f0c915a5371be08bc -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 38de47ac782543381bd4c52e3c55d151b2c9e17d7f5a3661b1517e88e13189a0 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Belegte oder ungeklärte Reservations dieser Generation blockieren Close. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: f98159bbd43df777526c6664434dbbeab572d73e5d61bae6ef5df58684d2e825 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. Moduswechsel ist bei Claims, Holds oder belegten/ungeklärten Reservations nicht zulässig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 0a1743743bc4b38a274f4a760b9dcc18d30f2db66eb28193fa4a05fed5e86d24 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. Moduswechsel ist bei Claims, Holds oder belegten/ungeklärten Reservations nicht zulässig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 17359af63d60e0707600d8cee91efe993b25c1bf5cbfb3a4f381c5db3cc215df -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 8540fd3e5ffb0a29d049b87a18f230e65fb81292e2b7bb0ce13d663036a2780f -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. Der Code prüft Sessionfence und Commitwitness; fehlende Beweisbarkeit bleibt UNKNOWN und ist keine Freigabe zum Replay. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 646653afa5034c5075220dfb0e7d397ce1409157db53b904e682e859b4c35997 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING. |
| `@Capacity` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich. |
| `@RunMode` | `varchar(16)` | `'BOUNDED'` | Input | Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 9617f7f1b133b12a95b2e99e36d1d0810b841490ff2321959f2decae90775340 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 57fd7a58d05249cf48b1a7d525b10f4c3d283738357774447847d4a737ff146c -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine vorhandene nicht geschlossene Generation wird adressiert; der Aufruf übernimmt keine Generation. |
| `@Capacity` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Live-Capacity genau dieser Generation. NULL/0/negativ ungültig. Eine Absenkung bricht laufende Arbeit nicht ab; neue Admission wartet auf freie Kapazität. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 45263fca3ecda0398e8edc42ec1dcd3032f0451c4e6a3fac449e09221ac1afd0 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MaxConcurrentExecutions` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 04b3cfa3a9ece48b807404eec30985975c95a70ec282fa3ec08fbb51aa31aeb4 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@HeartbeatSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..3600 Sekunden. NULL ist ungültig; der technische NULL-Default bedeutet nicht den ursprünglichen Konfigurationswert 15. Wirkt als Registrierungsdefault nur für künftig erzeugte Generationen. |
| `@UnreachableSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 3..86400 Sekunden und mindestens 3*HeartbeatSeconds. NULL ist ungültig, nicht der ursprüngliche Konfigurationswert 60. Bestehende Generationen behalten die bei Registrierung kopierten Intervalle. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: f2cd67bd9d661b60138493671e5da81579c01def3adf89c0d0a4bdf3fd352066 -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Für diesen administrativen Übergang muss es die neueste lebende Generation der stabilen WorkerId sein. |
| `@RequestedState` | `varchar(16)` | `NULL` | Input | Taxativ und binär/case-sensitiv, ohne nachgestellte Spaces: ACTIVE = neue Admission wieder zulassen; PAUSED = neue Admission pausieren; DRAINING = Auslaufen ohne neue Admission anfordern. Laufende Arbeit wird dadurch nicht abgebrochen. CLOSED/UNREACHABLE sind keine setzbaren Eingabewerte; NULL/leer/andere Werte ungültig. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 24a0efdeff4fe729e53fb15c8ce225f67ba875d3049fcc8308c87c9684201edb -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedClaimGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche exakte positive bigint-ClaimGeneration der ausgewählten Reservation, aus ihrer Ausführungs-/Claimstatuszeile übernehmen. Kein WorkerGeneration-Wert; NULL oder Abweichung wird abgewiesen. Ein bereits gewinnender Commit wird nicht durch Retry wiederholt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 2eaa37cd37333e51b0e535dbdf14a39b3c1dcde88851cc973d2b46b19e177a9c -->

Voraussetzung: Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.

Voraussetzung: Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Input | Fachlich erforderlicher sysname einer vorhandenen caller-lokalen #Temp-Tabelle, keine ##Temp/persistente oder mehrteilige Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten: WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. 0..1000 eindeutige (WorkerId,WorkerGeneration)-Paare, Generation &gt;0, jede exakte Generation muss existieren. Doppelpaare werden abgewiesen; leere Auswahl ist ein No-op. Die Auswahl wird vor Stop eingefroren, maximal 100000 Reservations; Beispiel CREATE TABLE #Workers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL). |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 1cff430eb4a81b96d2f5b60af266befff96f906c082e099697086e92dcf67781 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet. |
| `@Value` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `date` | `'19000101'` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDate('day', 7, CONVERT(date,'2024-07-19'), CONVERT(date,'2024-01-01'));
```

## toolbelt_datetime.TVF_DateBucketDateTime2

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen datetime2-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDateTime2.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTime2.sql), [TVF_DateBucketDateTime2.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTime2.md).

<!-- Source/Vertrag SHA256: 3834b1e99c0c4e99169111bb1201ce3ea28d26d2a07ad2c505f798eadfe2df9d -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetime2(7)` | `'19000101'` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTime2('day', 7, CONVERT(datetime2(7),'2024-07-19T14:35:42'), CONVERT(datetime2(7),'2024-01-01'));
```

## toolbelt_datetime.TVF_DateBucketDateTimeOffset

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDateTimeOffset.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTimeOffset.sql), [TVF_DateBucketDateTimeOffset.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTimeOffset.md).

<!-- Source/Vertrag SHA256: 9c355cb98fa9d3c3040c88b8943d085e64a3954b827e0a8874b40abfd0244002 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetimeoffset(7)` | `'1900-01-01 00:00:00 +00:00'` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Referenz für die Bucketgrenzen. Default ist 1900-01-01 00:00:00+00:00; das Ergebnis verwendet den Offset des Origins. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset('day', 7, CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'), CONVERT(datetimeoffset(7),'2024-01-01'));
```

## toolbelt_datetime.TVF_CalendarDifference

Modul `toolbelt.datetime.calendar-difference` · Version `1.0.0` · `TVF`

Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage.

Vertrag und Quelle: [TVF_CalendarDifference.sql](../../Modules/toolbelt.datetime.calendar-difference/Source/TVF_CalendarDifference.sql), [TVF_CalendarDifference.md](../../Modules/toolbelt.datetime.calendar-difference/Documentation/TVF_CalendarDifference.md).

<!-- Source/Vertrag SHA256: 836f0647c6d134537c3cd37086a404ea208fea24673a1183f46c8ccb0ead3da7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StartDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Anfang des Vergleichs. Beide Reihenfolgen und gleiche Daten sind zulässig; die Richtung steht nur in Sign. NULL ergibt NULL in allen Ergebnisspalten. |
| `@EndDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zweites Datum. Vollständige Jahre/Monate folgen der Anniversary-Regel einschließlich Monatsendklammerung. NULL ergibt NULL in allen Ergebnisspalten. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_CalendarDifference(CONVERT(date,'2024-01-31'), CONVERT(date,'2025-03-02'));
```

## toolbelt_datetime.TVF_DateSpineDay

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle Tage, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineDay.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineDay.sql), [TVF_DateSpineDay.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineDay.md).

<!-- Source/Vertrag SHA256: bd9a3026bbb1bc956e218e994107c6331b0e59da0d152aea12a7434a5b958a72 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateSpineDay(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
```

## toolbelt_datetime.TVF_DateSpineIsoWeek

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle ISO-Wochen, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineIsoWeek.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineIsoWeek.sql), [TVF_DateSpineIsoWeek.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineIsoWeek.md).

<!-- Source/Vertrag SHA256: 8c451f13ce1aea58f43dc82e8c3053fef78439ca6f2862a3fbd14714e6cd883d -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateSpineIsoWeek(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
```

## toolbelt_datetime.TVF_DateSpineMonth

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle Monate, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineMonth.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineMonth.sql), [TVF_DateSpineMonth.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineMonth.md).

<!-- Source/Vertrag SHA256: 1600d874bd182a4849a3758f87e418471c05bd4c9f4c44c266874ba37027bbe1 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateSpineMonth(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
```

## toolbelt_datetime.TVF_TruncateDate

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen date-Wert auf den Beginn der ausgewählten Kalenderperiode.

Vertrag und Quelle: [TVF_TruncateDate.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDate.sql), [TVF_TruncateDate.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDate.md).

<!-- Source/Vertrag SHA256: 5b5115711fea2761d2fd3d4092204f54257df6c79eb32c9648585be1244f17e9 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDate('day', CONVERT(date,'2024-07-19'));
```

## toolbelt_datetime.TVF_TruncateDateTime2

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen datetime2-Wert auf den Beginn der gewählten Zeiteinheit.

Vertrag und Quelle: [TVF_TruncateDateTime2.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTime2.sql), [TVF_TruncateDateTime2.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTime2.md).

<!-- Source/Vertrag SHA256: bfdbef348174eef14b7707240ba4f8f13e16948f02ed9746a349fe3324691f3c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTime2('day', CONVERT(datetime2(7),'2024-07-19T14:35:42'));
```

## toolbelt_datetime.TVF_TruncateDateTimeOffset

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset.

Vertrag und Quelle: [TVF_TruncateDateTimeOffset.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTimeOffset.sql), [TVF_TruncateDateTimeOffset.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTimeOffset.md).

<!-- Source/Vertrag SHA256: 79a823cc272bc4f2d4d38d3966c435b73ab17dd553dba7cdb8a6e0c9c7918ac7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Der ursprüngliche Offset bleibt erhalten. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTimeOffset('day', CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'));
```

## toolbelt_file.USP_LoadBinaryFile

Modul `toolbelt.file.content` · Version `1.0.0` · `USP`

Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.

Vertrag und Quelle: [USP_LoadBinaryFile.sql](../../Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql), [USP_LoadBinaryFile.md](../../Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md).

<!-- Source/Vertrag SHA256: 984cd5207611fccaf275c9c91ef195dd5d7f0097dec6c632137c1b816ba3e864 -->

Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 51eda4463c03ca3eeef5f045622d978d0dab0577b6c5530f2efb242fd7fa57c3 -->

Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@FallbackEncoding` | `nvarchar(128)` | `N'Windows-1252'` | Input | Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 25851865d58d0cfd39b38d1c56cb6b2a370d244db9da033896773d30ea522d22 -->

Voraussetzung: Vorhandener SAFE-Provider und bei Routing sameDB-ResultTable-Helper.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `NULL` | Input | Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord. |
| `@Separator` | `nvarchar(2)` | `N','` | Input | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. |
| `@HasHeader` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 kein Header (Default); 1 erster Record als HEADER/RowOrdinal 0, DATA beginnt bei 1. NULL ist ungültig und kein Default. Header zählt zu MaxCells, nicht zu MaxRows. Writer verlangt bei 1 einen vollständigen nicht-NULL-Header. |
| `@NullToken` | `nvarchar(128)` | `NULL` | Input | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. |
| `@MaxRows` | `bigint` | `100000` | Input | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. |
| `@MaxColumns` | `int` | `1024` | Input | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. |
| `@MaxCells` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: d5e3e726c78a11d1ad168e0aa1d53fe43d1da56ddb1642e3eb97adb8c4e972ff -->

Voraussetzung: Vorhandener SAFE-Provider; Quelle ist keine ResultTable und bleibt unverändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@CellsTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name/#tbx_-Präfix. Genau vier sichtbare nicht-computed Basisspalten ohne Alias-/Zusatzspalten: RowKind varchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max). RowKind bytegenau DATA = Datenrecord oder HEADER = Headerrecord; RowKind/Ordinals nicht NULL. HEADER nur bei HasHeader=1 mit RowOrdinal=0; DATA-Ordinals lückenlos 1..n, Spalten lückenlos 1..Breite und jede Zellposition eindeutig. DATA-Value darf nur bei aktivem NullToken NULL sein, HEADER niemals. Leere Quelle nur ohne Header zulässig; keine Mutation/Quell-Ziel-Identität. |
| `@Separator` | `nvarchar(2)` | `N','` | Input | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. |
| `@HasHeader` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 kein Header (Default); 1 erster Record als HEADER/RowOrdinal 0, DATA beginnt bei 1. NULL ist ungültig und kein Default. Header zählt zu MaxCells, nicht zu MaxRows. Writer verlangt bei 1 einen vollständigen nicht-NULL-Header. |
| `@NullToken` | `nvarchar(128)` | `NULL` | Input | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. |
| `@LineEnding` | `varchar(4)` | `'CRLF'` | Input | Taxativ, bytegenau ohne Trim: CRLF (Default) = U+000D gefolgt von U+000A; LF = nur U+000A. Jeder ausgegebene Record einschließlich des letzten erhält diesen Abschluss. NULL/leer/andere Schreibweisen ungültig. |
| `@MaxRows` | `bigint` | `100000` | Input | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. |
| `@MaxColumns` | `int` | `1024` | Input | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. |
| `@MaxCells` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. |
| `@MaxValueBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Snapshotbytes als Summe DATALENGTH(Value), Default 16777216. NULL-Zellen zählen 0; NULL/außerhalb beim Budget ist ungültig. Keine zusätzliche einzelne Zellgrenze außerhalb dieses Gesamtbudgets. |
| `@MaxOutputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes des gesamten CsvText, Default 16777216. Einschließlich Quoteverdopplung, Hüllen, NullTokens, Separatoren und sämtlicher Recordabschlüsse. NULL/außerhalb ungültig; vor Allokation/Veröffentlichung exakt gemessen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: f39c2b22c8bf7cc4083741e6ecf21a8bc7057b6139d06d5b5c6a61e7700a6c89 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | Vollständiger XLSX-Bytepuffer varbinary(max), kein Pfad/Base64text. Unterstützt Transitional-XLSX mit kanonischen Stored-/Deflate-ZIP-Parts, sicheren lokalen Relationships und XML ohne DTD/externe Auflösung; keine XLS/XLSB-/verschlüsselten Workbooks oder Makroausführung. Leer ist ungültig. NULL (Default) liefert keine Zeilen vor Sheet-/Limit-/Dependency-/Zielprüfung und lässt ResultTable unverändert. |
| `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxPartBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxParts` | `int` | `256` | Input | Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSheets` | `int` | `32` | Input | Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCells` | `int` | `100000` | Input | Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStrings` | `int` | `50000` | Input | Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxXmlDepth` | `int` | `64` | Input | Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/&lt;1/&gt;200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. |
| `@BudgetMilliseconds` | `int` | `5000` | Input | Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 0a482fea7a4acf58144ff1d6e569575e288f49ce54b4ce411db692e55ac21ede -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | Vollständiger XLSX-Bytepuffer varbinary(max), kein Pfad/Base64text. Unterstützt Transitional-XLSX mit kanonischen Stored-/Deflate-ZIP-Parts, sicheren lokalen Relationships und XML ohne DTD/externe Auflösung; keine XLS/XLSB-/verschlüsselten Workbooks oder Makroausführung. Leer ist ungültig. NULL (Default) liefert keine Zeilen vor Sheet-/Limit-/Dependency-/Zielprüfung und lässt ResultTable unverändert. |
| `@SheetOrdinal` | `int` | `NULL` | Input | Fachlich erforderliche positive int-Worksheetnummer aus USP_ListXlsxWorksheets, 1-basiert in Workbookreihenfolge; keine SheetId, kein Name und keine nullbasierte Position. Muss tatsächlich existieren. NULL (technischer Default)/0/negativ ungültig bei nicht-NULL-XlsxBinary; bei NULL-Binary ignoriert. |
| `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxPartBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxParts` | `int` | `256` | Input | Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSheets` | `int` | `32` | Input | Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCells` | `int` | `100000` | Input | Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStrings` | `int` | `50000` | Input | Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxXmlDepth` | `int` | `64` | Input | Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/&lt;1/&gt;200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. |
| `@BudgetMilliseconds` | `int` | `5000` | Input | Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 484995fbe21bfd4d2b2aef851855411a8d9974a3d973e41b14f4e15bb95f0481 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung. |
| `@ValuePresent` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: 0 = Zahl ganzzahlig; 0.00 = Zahl mit zwei Dezimalstellen; #,##0.00 = Zahl mit Gruppierung/zwei Stellen; 0% = Prozent ganzzahlig; 0.00% = Prozent mit zwei Stellen; 0.00E+00 = wissenschaftliche Zahl mit zwei Mantissenstellen; yyyy-mm-dd = date; yyyy-mm-dd hh:mm:ss = datetime; hh:mm:ss = time; @ = text. Keine Excel-General-/Farb-/Locale-/Mehrsektionsgrammatik, kein Trim/Casefold; höchstens 128 UTF-16-Einheiten. Zusätzlich [h]:mm:ss = duration. NULL (Default) wählt ohne Formatvorgabe nach TargetType/StoredType; Formatcode klassifiziert hier den Typ und erzeugt keinen Anzeigetext. Unbekannt/leer ergibt Status 6. |
| `@Date1904` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(N'n', 1, N'1.235', NULL, N'number', N'0.00', 0);
```

## toolbelt_file.TVF_FormatXlsxCell

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `TVF`

Formatiert eine XLSX-Einzelzelle mit den unterstützten Literalformaten und Kulturen.

Vertrag und Quelle: [TVF_FormatXlsxCell.sql](../../Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql), [TVF_FormatXlsxCell.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/TVF_FormatXlsxCell.md).

<!-- Source/Vertrag SHA256: d127e5aed4dd1b144fa6e507815b146047397fbeaf1b6b88af1903a65607b0f1 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung. |
| `@ValuePresent` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. Die Anzeige unterstützt keinen eigenen Boolean-/Dauerformatrenderer. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: 0 = Zahl ganzzahlig; 0.00 = Zahl mit zwei Dezimalstellen; #,##0.00 = Zahl mit Gruppierung/zwei Stellen; 0% = Prozent ganzzahlig; 0.00% = Prozent mit zwei Stellen; 0.00E+00 = wissenschaftliche Zahl mit zwei Mantissenstellen; yyyy-mm-dd = date; yyyy-mm-dd hh:mm:ss = datetime; hh:mm:ss = time; @ = text. Keine Excel-General-/Farb-/Locale-/Mehrsektionsgrammatik, kein Trim/Casefold; höchstens 128 UTF-16-Einheiten. NULL (Default) ergibt nach erfolgreicher Typinterpretation Status 2; unbekannt/leer Status 6. [h]:mm:ss wird vom geerbten Typkern erkannt, bleibt als Anzeigeformat unsupported/Status 6. Keine automatische Formatwahl; numerische Rundung half-away-from-zero, @ übernimmt Text unverändert. |
| `@Date1904` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault. |
| `@CultureName` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: en-US = Dezimalpunkt/Gruppierungskomma; de-DE = Dezimalkomma/Gruppierungspunkt; tr-TR = Dezimalkomma/Gruppierungspunkt. Auch bei @-/Temporalformaten explizit erforderlich nach erfolgreicher Typinterpretation; NULL/leer/Aliase/andere Schreibweisen ergeben Status 2. Höchstens 32 UTF-16-Einheiten; keine CurrentCulture/OS-Overrides, Culture beeinflusst keine Inputlexik/Typwahl. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(N'n', 1, N'1.235', NULL, N'number', N'0.00', 0, N'de-DE');
```

## toolbelt_filesystem.USP_ReadBinaryFileChunk

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_ReadBinaryFileChunk.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_ReadBinaryFileChunk.md).

<!-- Source/Vertrag SHA256: 0be4dbb2b4672acf9994bd0c57c656d0e1c14571219f86fbebce44d020d13128 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig. |
| `@ByteOffset` | `bigint` | `0` | Input | Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen. |
| `@MaxBytes` | `int` | `1048576` | Input | Ganzzahl 1..16777216 Rohbytes pro Chunk, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF kürzer sein; kein Gesamtdateilimit. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 74ddafcb1d94281c7a5782f5fccc86b1139a4de83ef5c8c6e16b9a4a4d9ccb6a -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig. |
| `@ByteOffset` | `bigint` | `0` | Input | Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen. |
| `@MaxBytes` | `int` | `1048576` | Input | Ganzzahl 4..16777216 Rohbytes pro Leseversuch, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF oder zum Erhalt einer vollständigen Decodergrenze kürzer sein; kein Gesamtdateilimit. |
| `@EncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. BOM wird als Datenzeichen behandelt; Offset/NextByteOffset zählen weiterhin Bytes. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: d6d65adacefee9a6f4986ec21cc4f6e8f71948f21c84e8d27909f13ef3489878 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen. |
| `@Content` | `varbinary(max)` | `NULL` | Input | Binärer Bytepuffer varbinary(max), etwa 0x0102; keine Text-/Base64-Dekodierung. Leer 0x schreibt eine leere Datei. NULL (technischer Help-Default) ungültig. SQL-LOB wird in begrenzten Blöcken gelesen, kein zusätzliches öffentliches Gesamtbytebudget. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 3d9dd4124333fb758a752aa6256e7af80da92cb2cd3a87f6e62a2ec242a866d0 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen. |
| `@Content` | `nvarchar(max)` | `NULL` | Input | Unicode-Text nvarchar(max), leer schreibt nur eine gegebenenfalls gewählte BOM. NULL (technischer Help-Default) ungültig. Zeichen werden mit explizitem Encoding strikt kodiert; unvertretbare Zeichen/ungültige Surrogate sind Fehler, kein stiller Ersatz. Kein Append oder zusätzliches Gesamttextbudget. |
| `@EncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. |
| `@WriteBom` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: cc1b8b5cf1e01e9b9a58af5e8cc2c04386a7cc98614d4a2b0000345b695c59d9 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceRootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Quelle benötigt AllowRead. |
| `@SourceRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; vorhandene Quelldatei. |
| `@SourceEncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Explizites Sourceencoding; keine BOM-Autoerkennung. StreamReader entfernt gegebenenfalls eine zu diesem Encoding passende Präambel. |
| `@TargetRootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite. |
| `@TargetRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Ausgabe erfolgt über Staging/Publish. |
| `@TargetEncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Bestimmt ausschließlich die Ausgabeencoding. |
| `@WriteBom` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: ce20211a04822a96ca05bc29db9bf4f2ec3221df4ff70e84c696cf0a634c11c4 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `N''` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer (Default) wählt den Root selbst; NULL bleibt ungültig. Kein Suchmuster. |
| `@Recursive` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default. |
| `@MaxDepth` | `int` | `32` | Input | Ganzzahl 0..64, Default 32; Startdirectory hat Tiefe 0. Bei Recursive=1 führt ein nötiger Abstieg über die Grenze zum Fehler, nicht zu einer still gekürzten Ausgabe; bei 0 ist bereits Abstieg in ein Unterverzeichnis verboten. Auch ohne Rekursion muss das Budget gültig sein. NULL/negativ/&gt;64 ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..10000 Verzeichniseinträge (Dateien und Unterverzeichnisse), Default 10000. NULL/außerhalb ungültig; Überschreitung verwirft die vollständig gepufferte Ausgabe, kein TOP-Teilresultat. Zusätzlich gilt ein internes Pfadbytebudget. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 995b5fb35efae9a2522c57aa3392887aff6a361dbdcb6dfcdbe737f2c276ea1d -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer ist erlaubt und bezeichnet den Root; normale fehlende Unterverzeichnisse werden innerhalb der freigegebenen Rootkette angelegt. NULL ungültig. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 368bd749bedde21a163d33e9df523380e63cc6efb171eedcd3cb7e5dc8bd52dc -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer, muss eine vorhandene reguläre Datei adressieren, keine Verzeichnisse/Mehrfachauswahl. Löscht genau die handlegebundene Datei; kein Recycle-Bin-Vertrag. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 1c8efeafabb5fdf417e2ba31e29837f5cec349ce1e24b64b96dba0ad78aa5912 -->

Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer kann syntaktisch aufgelöst werden, aber der Root selbst darf niemals gelöscht werden. Muss ein vorhandenes Verzeichnis sein; keine Wildcard-/Mehrfachauswahl. |
| `@Recursive` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default. Bei 0 muss das Verzeichnis leer sein. |
| `@MaxDepth` | `int` | `32` | Input | Ganzzahl 0..2147483647, Default 32; der Remove-Pfad besitzt anders als List keine zusätzliche 64er-Obergrenze. Startdirectory hat Tiefe 0. Bei Recursive=1 wird jeder nötige Abstieg über das Budget vor der ersten Löschmutation abgewiesen. NULL/negativ ungültig; nicht still trunciert. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..2147483647, Default 10000; der Remove-Pfad besitzt anders als List keine zusätzliche 10000er-Obergrenze. Zählt sämtliche Kinder im vollständigen Vorab-Löschplan, ohne das Startdirectory selbst. NULL/0/negativ ungültig; Überschreitung vor erster Mutation. Keine automatische unbegrenzte Löschung. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 6e34fb35308e9a72bad462dca9fa6bde6a473ba9785fc3ad81644b930c726373 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Leere Tabelle ergibt genau [] beziehungsweise {}. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 7bbdf4dd56eb082c39dfab470c174a68abfc2f7e90535870e2c236751b175e7a -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Leere Tabelle ergibt genau [] beziehungsweise {}. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: b114c2e7cc208fdad188cd2ed07029ad32167d5d0127fdeff1717372c796772f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 80cdd3a3047d3380249f6858446fb091507e1f9c480012a7a341a68653fc222f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 88ca6e935ca2150ba5d1bd24f8e0eae27fb28ff213cc2ddf3b617789caa26f31 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647, nicht NULL und je Aggregatgruppe eindeutig. Bestimmt die Ausgabeordnung unabhängig von Callback-/Inputreihenfolge; Lücken sind erlaubt. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Bei json höchstens 127 Containerebenen, damit der äußere Aggregatcontainer Tiefe 128 nicht überschreitet. |
| `@Profile` | `tinyint` | `kein Default` | Input | Taxativ für tinyint: 1 = höchstens 10000 Entries, 2097152 Payloadbytes und 5242880 serialisierte Zustandsbytes; 2 = 100000 Entries, 16777216 Payloadbytes und 37748736 Zustandsbytes. Kein Default: an jedem Inputeintrag explizit übergeben. Muss in einer Aggregatgruppe gleich bleiben; NULL/andere/gemischte Werte sind Fehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Entries TABLE(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(2,N'number',N'2',1),(1,N'string',N'Contoso',1);
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## toolbelt_json.AGF_JsonObject

Modul `toolbelt.json.constructors` · Version `1.3.0` · `CLR_AGGREGATE`

Aggregiert typisierte Einträge mit eindeutigen Schlüsseln zu einem JSON-Objekt.

Vertrag und Quelle: [JsonAggregates.sql](../../Modules/toolbelt.json.constructors/Source/JsonAggregates.sql), [AGF_JsonObject.md](../../Modules/toolbelt.json.constructors/Documentation/AGF_JsonObject.md).

<!-- Source/Vertrag SHA256: 09615e1bc2f4c7e035b7468f5e8f404e4ec99918a1f91668437ff92b08c44fe0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647, nicht NULL und je Aggregatgruppe eindeutig. Bestimmt die Ausgabeordnung unabhängig von Callback-/Inputreihenfolge; Lücken sind erlaubt. |
| `@Key` | `nvarchar(max)` | `kein Default` | Input | Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Bei json höchstens 127 Containerebenen, damit der äußere Aggregatcontainer Tiefe 128 nicht überschreitet. |
| `@Profile` | `tinyint` | `kein Default` | Input | Taxativ für tinyint: 1 = höchstens 10000 Entries, 2097152 Payloadbytes und 5242880 serialisierte Zustandsbytes; 2 = 100000 Entries, 16777216 Payloadbytes und 37748736 Zustandsbytes. Kein Default: an jedem Inputeintrag explizit übergeben. Muss in einer Aggregatgruppe gleich bleiben; NULL/andere/gemischte Werte sind Fehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Entries TABLE(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(1,N'name',N'string',N'Contoso',1),(2,N'count',N'number',N'2',1);
SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## toolbelt_json.TVF_JsonPathExists

Modul `toolbelt.json.path-exists` · Version `1.0.0` · `TVF`

Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert.

Vertrag und Quelle: [TVF_JsonPathExists.sql](../../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql), [TVF_JsonPathExists.md](../../Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExists.md).

<!-- Source/Vertrag SHA256: f618a6506f54786106491a997e4d792677ec435654b63d4146ba38565348dcce -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExists(N'{"items":[1,2]}', N'$.items[0]');
```

## toolbelt_json.TVF_JsonPathExistsStatus

Modul `toolbelt.json.path-exists` · Version `1.0.0` · `TVF`

Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING.

Vertrag und Quelle: [TVF_JsonPathExists.sql](../../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql), [TVF_JsonPathExistsStatus.md](../../Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExistsStatus.md).

<!-- Source/Vertrag SHA256: 3e3d2b6c48d2f7a82ed37817462a6eb17bb0e264a9b1aa0d22f10bd8f698f4a3 -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":null}',N'$.a');
```

## toolbelt_json.TVF_ResolveJsonPointer

Modul `toolbelt.json.pointer` · Version `1.0.0` · `TVF`

Löst einen RFC6901-Pointer mit exakten Keys und unterscheidet FOUND, MISSING, JSON_NULL, SQL_NULL und INVALID. Der freigegebene feste128er-Guard gibt darüber DEPTH_LIMIT vor JSON_SYNTAX zurück.

Vertrag und Quelle: [TVF_ResolveJsonPointer.sql](../../Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql), [TVF_ResolveJsonPointer.md](../../Modules/toolbelt.json.pointer/Documentation/TVF_ResolveJsonPointer.md).

<!-- Source/Vertrag SHA256: 1ed0a9813ca5fbfdfb50b046705d53ef2435c42a2c6b3e9c6c7ad024cdc2087f -->

Voraussetzung: Vorhandenes SELECT; SQL Server2019+ und CL150+ auch beim zentralen Caller; lesende MSTVF ohne CLR. Freigegebener struktureller128er-Guard: darüber DEPTH_LIMIT vor JSON_SYNTAX; kein Release.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, wohlgeformtes Unicode auch in decodierten Escapes. Leer ist ungültig; DATALENGTH darf MaxInputBytes nicht überschreiten. Vor nativer Prüfung gilt die absolute Containertiefengrenze 128, danach das abgesenkte MaxDepth. NULL in Json oder Pointer ergibt SQL_NULL vor Parameterprüfung. Kein partiell gültiges Dokument und keine Mutation. |
| `@Pointer` | `nvarchar(max)` | `kein Default` | Input | RFC6901-Stringpointer, keine URIfragmentform #/...: leer bezeichnet Root, sonst beginnt der Text mit /. Segmente sind exakte binäre/case-sensitive Objektkeys; ~0 decodiert einmal zu ~, ~1 zu /. Kein anderes ~-Escape oder Percentdecoding. Arrayindizes sind nullbasiert kanonische nicht negative ASCII-Dezimalzahlen ohne führende Nullen; - ist kein Appendindex, Wildcards fehlen. Maximal 4000 UTF-16-Einheiten, wohlgeformtes Unicode; / bezeichnet einen leeren Key. NULL ergibt SQL_NULL. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes des JSON-Dokuments, Default 16777216; keine Zeichenanzahl. NULL/außerhalb ergibt INVALID/PARAMETER, Überschreitung INVALID/INPUT_LIMIT. Nur absenkbar; früher Json-/Pointer-NULL-Pfad hat Vorrang. |
| `@MaxDepth` | `int` | `128` | Input | Ganzzahl 1..128 gleichzeitig offene JSON-Container, Default 128. Gilt für das gesamte Dokument, auch nicht traversierte Teile. NULL/außerhalb ergibt INVALID/PARAMETER; vor nativer JSON-Prüfung bleibt zusätzlich die absolute Schutzgrenze 128 wirksam. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Status,JsonType,Value,ErrorCode FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"items":[null,"example"]}',N'/items/1',DEFAULT,DEFAULT);
```

## toolbelt_json.USP_ValidateJsonSchema

Modul `toolbelt.json.schema` · Version `1.0.1` · `USP`

Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen.

Vertrag und Quelle: [USP_ValidateJsonSchema.sql](../../Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql), [USP_ValidateJsonSchema.md](../../Modules/toolbelt.json.schema/Documentation/USP_ValidateJsonSchema.md).

<!-- Source/Vertrag SHA256: e0450f1d62f7272652853fb21813fe059ed44445291f99107c3547f134f7d76c -->

Voraussetzung: SQL Server2019+ und CL150+, bekannte SAFE-Core-/Schema-Assemblies in derselben Datenbank, ResultTable >=1.0.0, vorhandene Aufrufrechte. Nur Teilqualifikation, unreleased.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `NULL` | Input | Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments. |
| `@Schema` | `nvarchar(max)` | `NULL` | Input | Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung. |
| `@Profile` | `varchar(32)` | `'toolbelt-2020-12-v1'` | Input | Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität. |
| `@MaxDocumentBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES. |
| `@MaxSchemaBytes` | `bigint` | `1048576` | Input | Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES. |
| `@MaxDepth` | `int` | `128` | Input | Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil. |
| `@MaxEvaluationSteps` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL. |
| `@MaxErrors` | `int` | `100` | Input | Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 672d08e3ae116374fe1fb7dd859cfeb07f47afca343930a5a8101710e66a1160 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 Zeichen. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'dbo.[Order Items]');
```

## toolbelt_metadata.SVF_QuoteMultipartName

Modul `toolbelt.metadata.identifier` · Version `1.0.0` · `SVF`

Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten.

Vertrag und Quelle: [SVF_QuoteMultipartName.sql](../../Modules/toolbelt.metadata.identifier/Source/SVF_QuoteMultipartName.sql), [SVF_QuoteMultipartName.md](../../Modules/toolbelt.metadata.identifier/Documentation/SVF_QuoteMultipartName.md).

<!-- Source/Vertrag SHA256: 0018868f0e091edecb81f0a6c6ed862a70a12ae31c80f24428d3b16e8be12ebf -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 Zeichen. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.[Order Items]') AS ResultValue;
```

## toolbelt_metadata.USP_ScriptTableClone

Modul `toolbelt.metadata.table-clone` · Version `4.1.1` · `USP`

Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.

Vertrag und Quelle: [USP_ScriptTableClone.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql), [USP_ScriptTableClone.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md).

<!-- Source/Vertrag SHA256: 10e9d5d6d0aa04eda8117f8abf062405fd9375f3b92f77e9384c3f53ecb7edb8 -->

Voraussetzung: Vorhandene synthetische Quelltabelle und sichtbares Zielschema; Zielname darf noch nicht existieren. IncludeTriggers=1 verlangt Windows und den separat installierten Parser 2.0.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@IncludeIdentity` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen. |
| `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig. |
| `@IncludeTriggers` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 571fc660e198125cde6932e8366a1c8a3ac4de62719d4f93e47a6bd25f2b6f11 -->

Voraussetzung: Erzeugt neue Tabellen. @CalculatedPlanHash ist ein notwendiger Platzhalter für die externe kanonische Hashberechnung; der Beispielaufruf ist bis dahin nicht ausführbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@IncludeIdentity` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen. |
| `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig. |
| `@ExpectedPlanHash` | `varbinary(max)` | `NULL` | Input | Fachlich erforderliche exakt 32 Bytes varbinary des SHA256-Planhashes aus dem dokumentierten Hashlayout1 für Modul4.1.0. Aus unveränderten triggerfreien Vorschauzeilen, exakten Optionen und Installationsdatenbankidentität gemäß TABLE_CLONE_EXECUTE_CONTRACT.md/Examples/CalculatePlanHash.py berechnen. Kein Hextext ohne Konvertierung, kein Hash allein des Scripttexts. NULL/falsche Länge ungültig, Abweichung vom frisch erzeugten Plan bricht ab. |
| `@ForeignKeyMode` | `varchar(16)` | `'CREATE'` | Input | Taxativ, bytegenau ohne Trim/Casefold: CREATE (Default) führt alle fachlichen Planzeilen einschließlich FKs/Zustände aus; DEFER überspringt ausschließlich FOREIGN_KEY und FOREIGN_KEY_STATE für spätere Datenkopie. Beide Zeilenarten bleiben im vollständigen Planhash. NULL/andere Werte ungültig; bestehende Constraints werden nicht deaktiviert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Der Executor plant intern ausdrücklich mit Debug=0 und erzeugt keine eigenen zusätzlichen Diagnosemessages; bei ResultTable wird der übergebene Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: bb10288ca22f7ce40f61659213b4d50ce6a21ded593849cd4cec235b68bd6c00 -->

Voraussetzung: Vorhandene reguläre SameDB-Quellen und leere formgleiche Ziele, keine aktive Callertransaktion. SERIALIZABLE hält Quellsperren; SNAPSHOT benötigt eine bereits aktivierte Datenbankoption.

Voraussetzung: Vorhandene DB-Metadatensicht und Source-/Target-Rechte; fehlende FKs verlangen zusätzlich Server-DDL-Sicht und DDL-Rechte. KEEP benötigt vorhandenes Identity-ALTER. Aktive Targettrigger, RLS und nicht tabellenlokale Ausführung blockieren.

Voraussetzung: Verändert Zielinhalte und kann fehlende gemappte FKs erzeugen. Identity-Zähler können trotz Rollback fortgeschritten bleiben; kein RESEED oder Identitätszuordnungsversprechen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@TableMap` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Fachlich erforderlich, NULL ungültig. Hier müssen die fünf Spalten zusätzlich exakt in der genannten Reihenfolge und ohne IDENTITY stehen. Source und Target müssen beide existieren, formgleich und als Mengen von ObjectIDs disjunkt sein; jedes Ziel muss leer sein. Keine Filter/Upserts/CrossDB oder impliziten Typkonvertierungen. |
| `@IdentityMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: KEEP kopiert Identitywerte unter vorhandenen erforderlichen Rechten; REGENERATE lässt Identityspalten beim Transport weg und erzeugt neue Zielwerte. REGENERATE ist bei identityabhängigen Beziehungen ausgeschlossen. NULL/leer/andere Werte ungültig. Keine neue ID-Zuordnung/RESEED; Identity-Zählerfortschritt kann trotz Rollback bleiben. |
| `@ConsistencyMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: SNAPSHOT verwendet die bereits aktivierte Datenbankoption; SERIALIZABLE hält Quellbereichssperren. NULL/leer/andere Werte ungültig. Keine automatische Optionsänderung; aktive Callertransaktion wird abgelehnt. |
| `@RowLimit` | `bigint` | `100000` | Input | Ganzzahl 1..100000 global kopierte Zeilen über alle gemappten Tabellen, Default 100000. NULL/außerhalb ungültig; Überschreitung verhindert die gesamte Kopie, kein TOP-Teilimport. |
| `@PayloadByteLimit` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes globaler tatsächlich transportierter SQL-Nutzdaten, Default 16777216. Summe bigint-DATALENGTH, NULL zählt 0; computed/rowversion und bei REGENERATE Identity zählen nicht. Kein Gesamt-Heap-/Dateigrößenbudget; NULL/außerhalb ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht TableMap. Die späte ResultTable-Ausgabe ist Teil derselben eigenen Transaktion wie Kopie/FK-DDL. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Aktuell keine eigenen zusätzlichen Copy-Diagnosemessages; bei ResultTable wird der Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 5ada64a0b7c7410fafbbf92cdca4e40b799e778cebdc4170fd3a5a4ba0732f91 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `geography` | `kein Default` | Input | Gültiger nicht leerer zweidimensionaler geography-Point mit SRID 4326, ohne Z/M, serialisierte Größe höchstens 128 Bytes; keine Linien/Polygone/anderen SRIDs. Beispielsweise geography::Point(48.2,16.3,4326). Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Fehlern; ungeeignete Geometrie Code 15. Ausgabe ist ein deterministisch versetzter Punkt, kein Anonymisierungsnachweis. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@RadiusMeters` | `int` | `100` | Input | Ganzzahl 1..10000 Meter, Default 100. Obergrenze des radialen Jitters; Richtung und flächentreuer Radius werden aus dem Mappingkontext abgeleitet. NULL/0/negativ/größer ergibt Code 14. Keine Nullverschiebungsoption mit Radius 0. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(48.2,16.3,4326), 0x01020304, 1, 42, 25);
```

## toolbelt_pseudonymization.TVF_DeterministicTranslate

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung.

Vertrag und Quelle: [DeterministicTranslate.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicTranslate.sql), [TVF_DeterministicTranslate.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicTranslate.md).

<!-- Source/Vertrag SHA256: 59780ed3dc898cb77cfdf31b4d369b06469272650335b796bb6d0c8689beee98 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Kennung: Buchstaben a-z/A-Z und Ziffern 0-9 werden bijektiv substituiert, ausdrücklich erlaubte Separatoren bleiben unverändert. Leer ist gültig; NULL ergibt NULL/Code 0 vor jeder Konfigurationsprüfung. Kein Trim/Unicode-Transliterieren; Akzente, NUL, Controls, DEL und Surrogate ergeben Code 13. Bytebudget durch Profile, Output exakt gleiche Länge. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@AllowedSeparators` | `nvarchar(max)` | `N''` | Input | Explizite Menge von höchstens 33 verschiedenen druckbaren ASCII-Nichtalnum-Zeichen aus Codes 32..126, z.B. N'-/ '; jedes bleibt unverändert. Leer (Default) erlaubt keine Separatoren. Duplikate, Buchstaben/Ziffern, Controls/NUL/DEL/Unicode und NULL ergeben Code 11; trailing Spaces sind relevant. Keine mehrzeichige Separatorgrammatik. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, bytegenau ohne Trim: standard (Default) = höchstens 2097152 UTF-16-Inputbytes; large = höchstens 16777216. NULL/leer/andere Schreibweisen ergeben Code 10; Überschreitung Code 12. Profil ändert nur das Budget, nicht die Mappingpermutation. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'  Contoso-123  ', 1, 42, N'- ', N'standard');
```

## toolbelt_pseudonymization.TVF_DeterministicRange

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu.

Vertrag und Quelle: [TVF_DeterministicRange.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRange.sql), [TVF_DeterministicRange.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicRange.md).

<!-- Source/Vertrag SHA256: 77a9f4ae0bcd992826a8d987c78902d4e1380fafd1edf395d242b545e8bd682b -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@Min` | `bigint` | `kein Default` | Input | Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und &lt;=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen. |
| `@Max` | `bigint` | `kein Default` | Input | Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und &gt;=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x01020304, 1, 42, 1, 100);
```

## toolbelt_pseudonymization.TVF_DeterministicDateShift

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage.

Vertrag und Quelle: [TVF_DeterministicDateShift.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicDateShift.sql), [TVF_DeterministicDateShift.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicDateShift.md).

<!-- Source/Vertrag SHA256: fcfc30ff5e1c0ca67efb95554cbdb29c62962f6d5309e471e1887b1fc618d198 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `datetime2(7)` | `kein Default` | Input | datetime2(7) im nativen Bereich 0001-01-01..9999-12-31; Uhrzeit/Präzision bleiben beim ganzzahligen Tagesoffset erhalten. Keine Zeitzone/DST-Konvertierung. Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Konfigurationsfehlern. Überlauf des gezogenen Offsets ergibt Code 8, kein Clamp/Wrap. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@MaxDays` | `int` | `365` | Input | Ganzzahl 0..3652058 Tage, Default 365. Offset wird deterministisch aus dem geschlossenen Intervall [-MaxDays,+MaxDays] gewählt; 0 lässt das Datum unverändert. NULL/außerhalb ergibt Code 7; Datumsoverflow wird zusätzlich geprüft. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2024-07-19T14:35:42'), 0x01020304, 1, 42, 7);
```

## toolbelt_pseudonymization.USP_DeterministicLookup

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `USP`

Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.

Vertrag und Quelle: [USP_DeterministicLookup.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookup.sql), [USP_DeterministicLookup.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/USP_DeterministicLookup.md).

<!-- Source/Vertrag SHA256: 16de5a0497b025f9e1a6409e8652cd3d12f8ab036ae1bc09b8c3bfe682586ca5 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@InputTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap. |
| `@LookupTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable. |
| `@MappingVersion` | `int` | `NULL` | Input | Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf. |
| `@LookupVersion` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung. |
| `@MaxInputRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Überschreitung. |
| `@MaxLookupRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein. |
| `@MaxLookupTextBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig. |
| `@MaxResultBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: de3bdc9a291d07d5da9347126ac4bd046a61accaa1dac09cf8bf8d3e74e3ef15 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max); Positionen zählen UTF-16-Codeeinheiten. Leer bleibt leer; NULL ergibt NULL. NUL wird nicht entfernt; Zeichenvergleiche verwenden die Installationscollation. |
| `@Characters` | `nvarchar(4000)` | `N' '` | Input | Bis 4000 UTF-16-Codeeinheiten als nvarchar(4000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'  Contoso-123  ', N' ', 'BOTH');
```

## toolbelt_string.TVF_TrimDirectionalVarchar

Modul `toolbelt.string.directional-trim` · Version `1.0.0` · `TVF`

Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem varchar-Text.

Vertrag und Quelle: [TVF_TrimDirectionalVarchar.sql](../../Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalVarchar.sql), [TVF_TrimDirectionalVarchar.md](../../Modules/toolbelt.string.directional-trim/Documentation/TVF_TrimDirectionalVarchar.md).

<!-- Source/Vertrag SHA256: 10afae061f8e56a730d52943d8ed96a8f622c104eee3d139694d1a80f12cb2ae -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Text als varchar(max) unter der Datenbank-Codepage; die Positionsermittlung ist byteorientiert, kein Unicode-Codepoint-Vertrag. Leer bleibt leer; NULL ergibt NULL. NUL wird nicht entfernt; Zeichenvergleiche verwenden die Installationscollation. |
| `@Characters` | `varchar(8000)` | `' '` | Input | Bis 8000 Bytes als varchar(8000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalVarchar('  Contoso  ', N' ', 'BOTH');
```

## toolbelt_string.TVF_JaroWinklerSimilarity

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Berechnet einen Jaro-Winkler-Ähnlichkeitsscore zwischen 0 und 1 über Unicode Scalars.

Vertrag und Quelle: [JaroWinkler.sql](../../Modules/toolbelt.string.edit-distance/Source/JaroWinkler.sql), [TVF_JaroWinklerSimilarity.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_JaroWinklerSimilarity.md).

<!-- Source/Vertrag SHA256: cb1a4ac564354c0cb98f577f761052290628edbec07075e12908ead4c7a4fbc7 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. Bei Jaro begrenzt das Workbudget die konservativ geplante Fenstersuche. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'kitten', N'sitting', N'standard');
```

## toolbelt_string.TVF_LevenshteinDistance

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Berechnet die begrenzte Levenshtein-Editierdistanz zweier Unicode-Texte.

Vertrag und Quelle: [EditDistance.sql](../../Modules/toolbelt.string.edit-distance/Source/EditDistance.sql), [TVF_LevenshteinDistance.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_LevenshteinDistance.md).

<!-- Source/Vertrag SHA256: 3600d43c72c948835d212ecb76322606a24ce9b56d39b9863244f5abf8893bb6 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@MaxDistance` | `int` | `NULL` | Input | NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten', N'sitting', NULL, N'standard');
```

## toolbelt_string.TVF_OsaDistance

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Berechnet die begrenzte Optimal-String-Alignment-Distanz mit benachbarten Transpositionen.

Vertrag und Quelle: [EditDistance.sql](../../Modules/toolbelt.string.edit-distance/Source/EditDistance.sql), [TVF_OsaDistance.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_OsaDistance.md).

<!-- Source/Vertrag SHA256: 11cbc2a534a3f7579cb8633beabf946159510181a7cab0f67753194742a8b370 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@MaxDistance` | `int` | `NULL` | Input | NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'kitten', N'sitting', NULL, N'standard');
```

## toolbelt_string.TVF_ColognePhonetic

Modul `toolbelt.string.phonetic` · Version `1.0.0` · `TVF`

Berechnet den vollständigen begrenzten Kölner Phonetikcode.

Vertrag und Quelle: [TVF_ColognePhonetic.sql](../../Modules/toolbelt.string.phonetic/Source/TVF_ColognePhonetic.sql), [TVF_ColognePhonetic.md](../../Modules/toolbelt.string.phonetic/Documentation/TVF_ColognePhonetic.md).

<!-- Source/Vertrag SHA256: 5e3183dcb18deb1373f0bf74cfd60db55e9b3c5836b7bcc44a76c8a09656f6e9 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Rohtext mit höchstens 4096 UTF-16-Einheiten; gültige Surrogatpaare werden geprüft, ein nicht unterstützter Skalar wird nicht still entfernt. ASCII-Zeichen sind zulässig. NULL ergibt NULL-Code(s)/ErrorCode 0; leer ist gültig. Längen-/Arbeitsgrenze ergibt Code 2, ungepaarte Surrogate Code 1 und nicht unterstützte Zeichen Code 3. Keine frei wählbare Sprache/Transliteration. Zusätzlich zu ASCII sind ÄÖÜäöüß erlaubt; Umlaute werden A/O/U und ß wird SS. Kein allgemeiner Unicode-Phonetikdienst. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'Contoso');
```

## toolbelt_string.TVF_DoubleMetaphone

Modul `toolbelt.string.phonetic` · Version `1.0.0` · `TVF`

Berechnet den primären und alternativen Double-Metaphone-Code.

Vertrag und Quelle: [TVF_DoubleMetaphone.sql](../../Modules/toolbelt.string.phonetic/Source/TVF_DoubleMetaphone.sql), [TVF_DoubleMetaphone.md](../../Modules/toolbelt.string.phonetic/Documentation/TVF_DoubleMetaphone.md).

<!-- Source/Vertrag SHA256: 4530a080c96d0b51c2534cd58e1eea3e6d46a59969da002154c15679d094e469 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Rohtext mit höchstens 4096 UTF-16-Einheiten; gültige Surrogatpaare werden geprüft, ein nicht unterstützter Skalar wird nicht still entfernt. ASCII-Zeichen sind zulässig. NULL ergibt NULL-Code(s)/ErrorCode 0; leer ist gültig. Längen-/Arbeitsgrenze ergibt Code 2, ungepaarte Surrogate Code 1 und nicht unterstützte Zeichen Code 3. Keine frei wählbare Sprache/Transliteration. Zusätzlich zu ASCII sind ÇçÑñ erlaubt. Randzeichen mit Code &lt;=32 werden entfernt, ASCII wird großgeschrieben; Ç/Ñ erhalten die definierte Lautbehandlung. Andere Akzente werden nicht automatisch transliteriert. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'Contoso');
```

## toolbelt_string.TVF_RegexCaptures

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Liefert Gruppen-Captures einschließlich wiederholter Captures.

Vertrag und Quelle: [RegexCaptures.sql](../../Modules/toolbelt.string.regex/Source/RegexCaptures.sql), [TVF_RegexCaptures.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexCaptures.md).

<!-- Source/Vertrag SHA256: 8a0e9acefe89166a3c52a3414b86c7e6e8407190f46c0fd82156ce74841b772c -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. Capturegruppen können unbenannt oder (?&lt;Name&gt;...) sein; Namen 1..128 ASCII-Zeichen, Beginn Buchstabe/_ danach zusätzlich Ziffern, ohne case-insensitive Namensduplikate. Maximal 64 deklarierte Gruppen und konservative Capture-History 100000. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl 1..100000, Default 10000; NULL/0/negativ/größer ungültig. Begrenzt die vollständig materialisierte Ausgabe; Überschreitung verwirft den gesamten Aufruf ohne gültiges Teilpräfix. Zählt jede Capture und auch Kontrollzeilen nicht beteiligter deklarierter Gruppen, nicht bloß Matches. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_RegexCaptures(N'abc123 def456', N'[0-9]+', 1, N'c', N'standard', 1000);
```

## toolbelt_string.SVF_RegexReplaceGroups

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Ersetzt Regex-Treffer mit dem getrennten Gruppen-Ersatzvertrag.

Vertrag und Quelle: [RegexCaptures.sql](../../Modules/toolbelt.string.regex/Source/RegexCaptures.sql), [SVF_RegexReplaceGroups.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexReplaceGroups.md).

<!-- Source/Vertrag SHA256: 7f2d91ffe199dbc0e8f67d2af6515e4ac1fb1047c51539d324caba2cde902e9a -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. Capturegruppen können unbenannt oder (?&lt;Name&gt;...) sein; Namen 1..128 ASCII-Zeichen, Beginn Buchstabe/_ danach zusätzlich Ziffern, ohne case-insensitive Namensduplikate. Maximal 64 deklarierte Gruppen und konservative Capture-History 100000. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Ersetzungstext, leer löscht den Treffer; NULL ergibt NULL vor weiterer Prüfung. Gruppenreferenzen ausschließlich $1..$64 auf vorhandene Gruppen, ${Name} auf deklarierte Namen sowie $$ für ein Dollarzeichen. $0/Gruppe 0, unbekannte Referenzen und ungültige Syntax werden auch ohne Treffer abgewiesen; höchstens 65536 Ersetzungsteile. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Occurrence` | `int` | `0` | Input | Ganzzahl 0..2147483647, Default 0: 0 ersetzt alle Treffer ab Start, positiv nur den n-ten Treffer ab Start. Negativ/NULL ungültig; vor Start bleibt der Text erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexReplaceGroups(N'abc123 def456', N'(?<Digits>[0-9]+)', N'[${Digits}]', 1, 0, N'c', N'standard') AS ResultValue;
```

## toolbelt_string.TVF_RegexMatches

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Liefert vollständige Regex-Treffer mit Ordinals und Positionen.

Vertrag und Quelle: [RegexRelations.sql](../../Modules/toolbelt.string.regex/Source/RegexRelations.sql), [TVF_RegexMatches.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexMatches.md).

<!-- Source/Vertrag SHA256: 20d7b09daf31112168b5fb863561ef44ffc9b014ac96ba677ebd04d67c160735 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl 1..100000, Default 10000; NULL/0/negativ/größer ungültig. Begrenzt die vollständig materialisierte Ausgabe; Überschreitung verwirft den gesamten Aufruf ohne gültiges Teilpräfix. Zählt Matchzeilen. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_RegexMatches(N'abc123 def456', N'[0-9]+', 1, N'c', N'standard', 1000);
```

## toolbelt_string.TVF_RegexSplit

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Zerlegt einen Text an Regex-Treffern.

Vertrag und Quelle: [RegexRelations.sql](../../Modules/toolbelt.string.regex/Source/RegexRelations.sql), [TVF_RegexSplit.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexSplit.md).

<!-- Source/Vertrag SHA256: 957d286bdbb61ea6c96782b6cf59fb22e6e2a8dd9d6a798f3f17483bb3dc48dc -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl 1..100000, Default 10000; NULL/0/negativ/größer ungültig. Begrenzt die vollständig materialisierte Ausgabe; Überschreitung verwirft den gesamten Aufruf ohne gültiges Teilpräfix. Bei Split zählen auch leere Tokens. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_RegexSplit(N'a,b;;c', N'[0-9]+', N'c', N'standard', 1000);
```

## toolbelt_string.SVF_RegexIsMatch

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Prüft, ob ein regulärer Ausdruck im Text trifft.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexIsMatch.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexIsMatch.md).

<!-- Source/Vertrag SHA256: 59dab0304c5a97006b945aee2e921ea11d3d13cea27f401da296e5eef2568c08 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum 1048576 UTF-16-Einheiten (2097152 Bytes). |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Bytes, also 4000 Einheiten. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexIsMatch(N'abc123 def456', N'[0-9]+', N'c') AS ResultValue;
```

## toolbelt_string.SVF_RegexInstr

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Liefert eine UTF-16-Position eines ausgewählten Regex-Treffers.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexInstr.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexInstr.md).

<!-- Source/Vertrag SHA256: 1f2a39824e62480f88f853635342fdb969a13fc37ee1e55ffc372f8f33cca501 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum 1048576 UTF-16-Einheiten (2097152 Bytes). |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Bytes, also 4000 Einheiten. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. Ein Beginn nach Länge+1 liefert 0 vor Pattern-/Flagprüfung. |
| `@Occurrence` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: n-ter Treffer ab Start; 0/negativ/NULL ungültig. |
| `@ReturnOption` | `int` | `0` | Input | Taxativ: 0 = 1-basierter Trefferbeginn (Default); 1 = 1-basierte exklusive Endposition. NULL/andere int-Werte ungültig. Kein Treffer ergibt 0. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexInstr(N'abc123 def456', N'[0-9]+', 1, 1, 0, N'c') AS ResultValue;
```

## toolbelt_string.SVF_RegexCount

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Zählt Regex-Treffer ab der angegebenen Startposition.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexCount.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexCount.md).

<!-- Source/Vertrag SHA256: d32555c8a1446bc429d243da00f80e205a32ee8229451a12154c9857cf25a9f0 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum 1048576 UTF-16-Einheiten (2097152 Bytes). |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Bytes, also 4000 Einheiten. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. Ein Beginn nach Länge+1 liefert 0 vor Pattern-/Flagprüfung. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexCount(N'abc123 def456', N'[0-9]+', 1, N'c') AS ResultValue;
```

## toolbelt_string.SVF_RegexReplace

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Ersetzt ganze Regex-Treffer durch einen literalen Ersatztext.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexReplace.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexReplace.md).

<!-- Source/Vertrag SHA256: 6af2f16b26ecf4be7e499fabc4fbf078a909ff497a427a3aad9c0691d18f6484 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Ersetzungstext, leer löscht den Treffer; NULL ergibt NULL vor weiterer Prüfung. Wird wörtlich eingesetzt: $1, ${Name} und Backslashes lösen keine Gruppenreferenzen aus. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Occurrence` | `int` | `0` | Input | Ganzzahl 0..2147483647, Default 0: 0 ersetzt alle Treffer ab Start, positiv nur den n-ten Treffer ab Start. Negativ/NULL ungültig; vor Start bleibt der Text erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexReplace(N'abc123 def456', N'[0-9]+', N'X', 1, 1, N'c', N'standard') AS ResultValue;
```

## toolbelt_string.SVF_RegexSubstring

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Liefert den ausgewählten vollständigen Regex-Treffer.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexSubstring.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexSubstring.md).

<!-- Source/Vertrag SHA256: bd2c8bc12dd37d0c103de8b870390d9ec7e8c2d72155994fead7f617fd54d265 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Occurrence` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: n-ter Treffer ab Start; 0/negativ/NULL ungültig. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexSubstring(N'abc123 def456', N'[0-9]+', 1, 1, N'c', N'standard') AS ResultValue;
```

## toolbelt_string.TVF_SplitAdvanced

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `TVF`

Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht.

Vertrag und Quelle: [TVF_SplitAdvanced.sql](../../Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql), [TVF_SplitAdvanced.md](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md).

<!-- Source/Vertrag SHA256: e1acfd95cf172e9b527f8a6a469f4962c34d56226c73394aca8f5341b3d9f89f -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
| `@SeparatorsJson` | `nvarchar(max)` | `kein Default` | Input | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N'a,b;;c', N'[",",";"]', N'"', N'\', 1);
```

## toolbelt_string.TVF_UnquoteToken

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `TVF`

Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes.

Vertrag und Quelle: [TVF_UnquoteToken.sql](../../Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql), [TVF_UnquoteToken.md](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_UnquoteToken.md).

<!-- Source/Vertrag SHA256: 2a5d72efca3169ded886ef0dc0c53812248db2f7655f0571deedd9c85e704526 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile. |
| `@Qualifier` | `nvarchar(max)` | `NULL` | Input | NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert. |
| `@ClosingQualifier` | `nvarchar(max)` | `NULL` | Input | NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein. |
| `@BackslashEscape` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \n, \t usw.; Backslash darf im aktiven Modus kein Qualifier sein. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_UnquoteToken(N'[a]]b]', NULL, NULL, 0);
```

## toolbelt_string.USP_SplitAdvanced

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `USP`

Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.

Vertrag und Quelle: [USP_SplitAdvanced.sql](../../Modules/toolbelt.string.split-advanced/Source/USP_SplitAdvanced.sql), [USP_SplitAdvanced.md](../../Modules/toolbelt.string.split-advanced/Documentation/USP_SplitAdvanced.md).

<!-- Source/Vertrag SHA256: a775c8ae8a8264c8276cd82659b082be9a21a545280f1b2f9084150e3afd12b3 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `NULL` | Input | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
| `@SeparatorsJson` | `nvarchar(max)` | `NULL` | Input | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: a4b5ed39ecde3d6f0d6f6ef5a79c356f8898cd335cd98f7995ac415ce9f043ad -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,b;;c', N',;', 1);
```

## toolbelt_string.TVF_SplitByCharactersStatus

Modul `toolbelt.string.split-characters` · Version `1.0.0` · `TVF`

Erst vollständige Spanprüfung, danach höchstens 10000 OK-Tokenzeilen. LIMIT, INVALID, SQL_NULL und EMPTY liefern genau eine Kontrollzeile ohne Value/Ordinal. Keine Tokenpräfixe. Die bisherige TVF filtert ausschließlich OK; bei Grenzüberschreitung liefert sie keine Zeilen. Positionen und Separatorvergleich zählen BIN2-Codeeinheiten.

Vertrag und Quelle: [TVF_SplitByCharacters.sql](../../Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql), [TVF_SplitByCharactersStatus.md](../../Modules/toolbelt.string.split-characters/Documentation/TVF_SplitByCharactersStatus.md).

<!-- Source/Vertrag SHA256: ae1365be4088f698457f5210e1c25f3fc2485f93e6c29f5073d260e0e0c9092c -->

Voraussetzung: Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a,b',N',',1) ORDER BY Ordinal;
```

## toolbelt_string.USP_CompareTextPairs

Modul `toolbelt.string.text-pairs` · Version `1.0.0` · `USP`

Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.

Vertrag und Quelle: [USP_CompareTextPairs.sql](../../Modules/toolbelt.string.text-pairs/Source/USP_CompareTextPairs.sql), [USP_CompareTextPairs.md](../../Modules/toolbelt.string.text-pairs/Documentation/USP_CompareTextPairs.md).

<!-- Source/Vertrag SHA256: a3569dd0d3139e8ab9f051cbf04b731d5019f794b0481f337b1900870d9edd8a -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PairsTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name und kein reserviertes #tbx_-Präfix. Drei bytegenau benannte Basisspalten: PairOrdinal bigint, LeftText nvarchar(max), RightText nvarchar(max); zusätzliche Spalten sind erlaubt, Alias-/computed-/hidden-/generated-/verschlüsselte Vertragsspalten nicht. PairOrdinal muss pro Zeile nicht NULL und eindeutig sein (auch negative Werte erlaubt); Text-NULL und leere Tabelle sind erlaubt. NULL ist nur Help-Default, fachlich ungültig. Keine parallele Mutation. |
| `@Algorithm` | `nvarchar(max)` | `NULL` | Input | Taxativ, bytegenau ohne Trim: levenshtein = Einfügen/Löschen/Ersetzen; osa = zusätzlich eingeschränkte benachbarte Transposition; jaro-winkler = Ähnlichkeit mit Präfixbonus. NULL/leer/andere Schreibweisen ungültig. Bei jaro-winkler muss MaxDistance NULL sein. |
| `@MaxDistance` | `int` | `NULL` | Input | NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift. Bei jaro-winkler ausschließlich NULL, jeder nicht-NULL-Wert wird bereits vor der Paarberechnung abgewiesen. Bei Distanzverfahren erfolgt die Schwellenvalidierung je Paar. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. Wird je Paar vom Provider ausgewertet; eine leere Tabelle erzwingt keinen Profilfehler. |
| `@MaxPairs` | `int` | `10000` | Input | Ganzzahl 1..100000 Paare, Default 10000; NULL/andere Werte ungültig. Mehr Inputzeilen werden vor Berechnung atomar abgewiesen. |
| `@MaxTotalTextBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 Bytes für die Summe DATALENGTH(LeftText)+DATALENGTH(RightText) über alle Paare, Default 2097152. NULL/andere Werte ungültig. Ein nicht-NULL-Text zählt auch bei NULL-Gegenstück; keine Zeichenanzahl. |
| `@MaxTotalWork` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 konservative Admission-Arbeitseinheiten, Default 16777216. Pro Paar min(UTF-16-Länge links * Länge rechts, Profilcap 1048576 bzw. 16777216); bei einem NULL-Text 0. NULL/andere Werte ungültig. Zusätzlich gelten weiterhin die tatsächlichen Providerlimits je Paar. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Zusätzlich Name 2..116 UTF-16-Einheiten, kein #tbx_-Präfix und nicht dieselbe Tabelle wie PairsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 150b287827228f8c356a59628832a125233a68227344979c7537d864b153f5c5 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Zu parsende T-SQL-Quelle als Unicode-Text, kein Objektname/Pfad und keine Ausführung. Leer ist zulässig. NULL liefert keine Zeilen vor jeder anderen Argumentprüfung. MaxInputBytes sowie vorgelagerte Struktur-/Token- und jeweilige Ausgabelimits gelten; Syntaxfehler über TVF_ParseScriptErrors untersuchen, nicht mit fehlenden AST-Zeilen verwechseln. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ: 80 = SQL2000-Grammatik, 90 = 2005, 100 = 2008, 110 = 2012, 120 = 2014, 130 = 2016, 140 = 2017, 150 = 2019, 160 = 2022 (Default), 170 = 2025. Wählt den ScriptDom-Parser, nicht die installierte Engine/DB-Compatibility. NULL wirkt wie 160; alle anderen int-Werte werden abgewiesen. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 interpretiert doppelte Anführungszeichen als Identifier (Default), 0 als Stringliterale gemäß Parsermodus. NULL wirkt wie 1. Kein automatisches Auslesen des Session-SET-Zustands. |
| `@MaxInputBytes` | `int` | `2097152` | Input | Ganzzahl 1..2097152 UTF-16-Bytes, Default 2097152; explizites NULL übernimmt diesen Default. 0/negativ/größer ungültig; Überschreitung des gewählten Budgets wirft TBX_TSQLPARSE_INPUT_TOO_LARGE. Bei SqlText=NULL greift vorher der No-op. |
| `@MaxNestingDepth` | `int` | `100` | Input | Ganzzahl 1..256, Default 100; NULL übernimmt 100. Begrenzt den Struktur-/AST-Pfad, nicht nur Klammerzeichen. Weitere unabhängige Vorabgrenzen (512 Atome, 32 Strukturebenen, 16 Kommentarverschachtelungen) und Ausgabelimits bleiben wirksam; ein höherer Wert hebt sie nicht auf. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.TVF_ParseScriptNodeProperties

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Eigenschaften der geparsten T-SQL-AST-Knoten.

Vertrag und Quelle: [TVF_ParseScriptNodeProperties.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptNodeProperties.sql), [TVF_ParseScriptNodeProperties.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptNodeProperties.md).

<!-- Source/Vertrag SHA256: 93a9ffca0389d816d5a57e08dcec6e9cc114bd515c102bfaca5fb8027ab8abc6 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Zu parsende T-SQL-Quelle als Unicode-Text, kein Objektname/Pfad und keine Ausführung. Leer ist zulässig. NULL liefert keine Zeilen vor jeder anderen Argumentprüfung. MaxInputBytes sowie vorgelagerte Struktur-/Token- und jeweilige Ausgabelimits gelten; Syntaxfehler über TVF_ParseScriptErrors untersuchen, nicht mit fehlenden AST-Zeilen verwechseln. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ: 80 = SQL2000-Grammatik, 90 = 2005, 100 = 2008, 110 = 2012, 120 = 2014, 130 = 2016, 140 = 2017, 150 = 2019, 160 = 2022 (Default), 170 = 2025. Wählt den ScriptDom-Parser, nicht die installierte Engine/DB-Compatibility. NULL wirkt wie 160; alle anderen int-Werte werden abgewiesen. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 interpretiert doppelte Anführungszeichen als Identifier (Default), 0 als Stringliterale gemäß Parsermodus. NULL wirkt wie 1. Kein automatisches Auslesen des Session-SET-Zustands. |
| `@MaxInputBytes` | `int` | `2097152` | Input | Ganzzahl 1..2097152 UTF-16-Bytes, Default 2097152; explizites NULL übernimmt diesen Default. 0/negativ/größer ungültig; Überschreitung des gewählten Budgets wirft TBX_TSQLPARSE_INPUT_TOO_LARGE. Bei SqlText=NULL greift vorher der No-op. |
| `@MaxNestingDepth` | `int` | `100` | Input | Ganzzahl 1..256, Default 100; NULL übernimmt 100. Begrenzt den Struktur-/AST-Pfad, nicht nur Klammerzeichen. Weitere unabhängige Vorabgrenzen (512 Atome, 32 Strukturebenen, 16 Kommentarverschachtelungen) und Ausgabelimits bleiben wirksam; ein höherer Wert hebt sie nicht auf. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.TVF_TokenizeScript

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Tokens eines T-SQL-Skripts.

Vertrag und Quelle: [TVF_TokenizeScript.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_TokenizeScript.sql), [TVF_TokenizeScript.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_TokenizeScript.md).

<!-- Source/Vertrag SHA256: 3803ea26934143e8a9e0443e6f780fd99474d9e0b3e17dc6fc7e6f12b18ebb6d -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Zu parsende T-SQL-Quelle als Unicode-Text, kein Objektname/Pfad und keine Ausführung. Leer ist zulässig. NULL liefert keine Zeilen vor jeder anderen Argumentprüfung. MaxInputBytes sowie vorgelagerte Struktur-/Token- und jeweilige Ausgabelimits gelten; Syntaxfehler über TVF_ParseScriptErrors untersuchen, nicht mit fehlenden AST-Zeilen verwechseln. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ: 80 = SQL2000-Grammatik, 90 = 2005, 100 = 2008, 110 = 2012, 120 = 2014, 130 = 2016, 140 = 2017, 150 = 2019, 160 = 2022 (Default), 170 = 2025. Wählt den ScriptDom-Parser, nicht die installierte Engine/DB-Compatibility. NULL wirkt wie 160; alle anderen int-Werte werden abgewiesen. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 interpretiert doppelte Anführungszeichen als Identifier (Default), 0 als Stringliterale gemäß Parsermodus. NULL wirkt wie 1. Kein automatisches Auslesen des Session-SET-Zustands. |
| `@MaxInputBytes` | `int` | `2097152` | Input | Ganzzahl 1..2097152 UTF-16-Bytes, Default 2097152; explizites NULL übernimmt diesen Default. 0/negativ/größer ungültig; Überschreitung des gewählten Budgets wirft TBX_TSQLPARSE_INPUT_TOO_LARGE. Bei SqlText=NULL greift vorher der No-op. |
| `@MaxNestingDepth` | `int` | `100` | Input | Ganzzahl 1..256, Default 100; NULL übernimmt 100. Begrenzt den Struktur-/AST-Pfad, nicht nur Klammerzeichen. Weitere unabhängige Vorabgrenzen (512 Atome, 32 Strukturebenen, 16 Kommentarverschachtelungen) und Ausgabelimits bleiben wirksam; ein höherer Wert hebt sie nicht auf. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.TVF_ParseScriptErrors

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Parserfehler eines T-SQL-Skripts, ohne das Skript auszuführen.

Vertrag und Quelle: [TVF_ParseScriptErrors.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptErrors.sql), [TVF_ParseScriptErrors.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptErrors.md).

<!-- Source/Vertrag SHA256: 382bb535ce8c83fd2b7d26beccf88cef054d364d392852fbb04bf57cecfa4840 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Zu parsende T-SQL-Quelle als Unicode-Text, kein Objektname/Pfad und keine Ausführung. Leer ist zulässig. NULL liefert keine Zeilen vor jeder anderen Argumentprüfung. MaxInputBytes sowie vorgelagerte Struktur-/Token- und jeweilige Ausgabelimits gelten; Syntaxfehler über TVF_ParseScriptErrors untersuchen, nicht mit fehlenden AST-Zeilen verwechseln. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ: 80 = SQL2000-Grammatik, 90 = 2005, 100 = 2008, 110 = 2012, 120 = 2014, 130 = 2016, 140 = 2017, 150 = 2019, 160 = 2022 (Default), 170 = 2025. Wählt den ScriptDom-Parser, nicht die installierte Engine/DB-Compatibility. NULL wirkt wie 160; alle anderen int-Werte werden abgewiesen. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 interpretiert doppelte Anführungszeichen als Identifier (Default), 0 als Stringliterale gemäß Parsermodus. NULL wirkt wie 1. Kein automatisches Auslesen des Session-SET-Zustands. |
| `@MaxInputBytes` | `int` | `2097152` | Input | Ganzzahl 1..2097152 UTF-16-Bytes, Default 2097152; explizites NULL übernimmt diesen Default. 0/negativ/größer ungültig; Überschreitung des gewählten Budgets wirft TBX_TSQLPARSE_INPUT_TOO_LARGE. Bei SqlText=NULL greift vorher der No-op. |
| `@MaxNestingDepth` | `int` | `100` | Input | Ganzzahl 1..256, Default 100; NULL übernimmt 100. Begrenzt den Struktur-/AST-Pfad, nicht nur Klammerzeichen. Weitere unabhängige Vorabgrenzen (512 Atome, 32 Strukturebenen, 16 Kommentarverschachtelungen) und Ausgabelimits bleiben wirksam; ein höherer Wert hebt sie nicht auf. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
```

## toolbelt_tsql.USP_ExplainSsisDataFlow

Modul `toolbelt.tsql.ssis-debug` · Version `1.0.0` · `USP`

Aktuelle DTSX-Debuganalyse ohne Profil-Opt-in; editierbare typisierte JSON-Vorlage mit Entwurfswerten und Herkunft, vollständiger Strukturpfad und geordnete DebugScript-Batches für auflösbare Ziele. Ressourcen über benannte SQL-Parameter; keine SSIS-/Quell-SQL-Ausführung während der Analyse. Teilweise validiert und unveröffentlicht.

Vertrag und Quelle: [USP_ExplainSsisDataFlow.sql](../../Modules/toolbelt.tsql.ssis-debug/Source/USP_ExplainSsisDataFlow.sql), [USP_ExplainSsisDataFlow.md](../../Modules/toolbelt.tsql.ssis-debug/Documentation/USP_ExplainSsisDataFlow.md).

<!-- Source/Vertrag SHA256: 55cd93a4cfd7312fa7b922e38ebded9bf4c7f056419124e366094a3ef4e8c9f7 -->

Voraussetzung: Windows SQL Server 2019/2022/2025, separate UNSAFE-Assembly, exakter Parser 2.0.1/ScriptDom-Pin und Result Table 1.0.0. Aktuelle Liefer- und Prüfgrenzen gemäß CurrentInstallation.md; historische Nachweise bleiben getrennt.

Voraussetzung: DTSX als Bytes übergeben. Für explain explizite Same-instance-Datenbank-/Connection-Allowlist und vorhandene vollständige Metadatensicht; keine Credentials im JSON. Nur values der vollständigen Bindings-Vorlage bearbeiten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PackageBytes` | `varbinary(max)` | `NULL` | Input | Genau ein vollständiges DTSX-XML-Paket als UTF-8-/UTF-16-Bytepuffer varbinary(max), kein Pfad/Base64-/XML-Stringparameter. DTSX-Formatprofile PackageFormatVersion 6 oder 8 werden unterstützt; kein verschlüsselter Container, DTD, externer Resolver oder XInclude. Leer/NULL ungültig, NULL ist nur technischer Help-Default. MaxPackageBytes begrenzt die Rohbytes; XML-Tiefe bleibt absolut 128. Paket/enthaltenes SQL werden beim Analysieren nicht ausgeführt. |
| `@Operation` | `varchar(32)` | `N'explain'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: explain (Default) analysiert die gebundenen Datenflüsse und erzeugt Workflow, Stufenverzeichnis, Debug-SQL und Diagnosen; bindings-template erzeugt ausschließlich die paket-/kontextgebundene Schema-2-Eingabevorlage zum Bearbeiten unter values. Template verlangt Bindings=NULL und CatalogBindings=NULL. Kein -v2-Alias, kein Opt-in; NULL/leer/andere Schreibweisen ungültig. |
| `@ProjectContext` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet leeren Schema-2-Projektkontext. Sonst JSON-Objekt {"schemaVersion":2,"projectParameters":[...],"connectionManagers":[...]}; beide Arrays optional. Parameterentry: name, ssisType sowie optional designValue, required und sensitive (JSON-Booleans); Connectionentry: refId, name, provider. Provider taxativ sqlserver-oledb oder sqlserver-adonet, beide ordnen vorhandene SQL-Server-Connections zu; keine Connectionstrings/Credentials. Eindeutige Namen/refIds, Projektconnections dürfen Paketconnections nicht überlagern. Typ-/Wertabbildung im Abschnitt SSIS-Eingabetypen der Objektreferenz; unbekannte Typen sind nicht bindbar. Andere Rootkeys, resourceOptions und schemaVersion ungleich 2 ungültig. Feste Kontrollprotokollgrenze 4194304 UTF-16-Bytes zusätzlich zu den gewählten JSON-Limits; beim Zurückgeben der Bindings denselben Kontext verwenden. |
| `@Bindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) verwendet vorhandene nicht sensitive Designdefaults; benötigte fehlende Laufzeitwerte bleiben als fehlender Kontext sichtbar. Sonst vollständiges von bindings-template zurückgegebenes JSON-Objekt mit schemaVersion=2, profile exakt ssis-debug-components-v2, packageSha256, contextSha256, availableInputs und values. Ausschließlich values nach generierten Eingabekeys bearbeiten; Paket-/Kontexthashes und vollständige Herkunftsmetadaten unverändert zurückgeben. values ist ein Objekt typisierter JSON-Werte: Stringtexte/ISO-Datum/-GUID/-Hex, JSON-Boolean für bit, exakte Zahlen gemäß SSIS-Eingabetypen; JSON-null als SQL-NULL, keine SQL-Ausdrücke. Sensitive/ unbekannte/nicht bindbare Keys abgewiesen. Im Template-Modus ausschließlich NULL; kein leeres Ersatzobjekt und keine Ressourcenoptionen. |
| `@CatalogBindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) liefert keine explizite Katalogzuordnung; fehlende erforderliche Bindungen bleiben missing_context. Sonst JSON-Objekt mit schemaVersion 1 oder 2, defaultDatabase als Name, databases als Array eindeutiger erlaubter Same-instance-Datenbanknamen und connections als Objekt {importierteConnectionId:Datenbankname}. Default und jede Zuordnung müssen in databases stehen; Connection-IDs müssen im Paket/Projektkontext vorhanden sein. Version 1 erlaubt nur diese Felder; Version 2 ergänzt flatFileInputs als Objekt (auch {}). Je Flatfileentry: database, schema, object, columns als Mapping importierter Spalten-IDs zu SQL-Spaltennamen; optional rowOrdinalColumn und errorRows als entsprechender Quellobjekt-/Spaltenbeschreiber gemäß Komponentenvertrag. Keine freien SQL-Fragmente, Server-/Credential-/Dateipfade oder automatische Rechte. Template-Modus verlangt NULL; leer/andere Shapes ungültig. |
| `@TargetFlow` | `varchar(64)` | `NULL` | Input | NULL (Default) berücksichtigt alle erkannten Zielflüsse getrennt. Sonst exakte modellinterne TargetFlowId aus der Workflow-/StageIndex-Ausgabe desselben Pakets, maximal varchar(64); keine frei gewählte Komponentenbezeichnung oder dauerhafte Projekt-ID. Groß-/Kleinschreibung/Whitespace werden nicht normalisiert; unbekannt/leer ungültig im Explain-Pfad. |
| `@InspectStage` | `varchar(64)` | `NULL` | Input | Taxativ für Steuerwerte: NULL (Default) liefert Zielskript/Stufenverzeichnis ohne zusätzliche StageSql-Auswahl; all liefert die unterstützten Vorgängerstufen jedes gewählten Ziels. Alternativ eine exakte StageId aus dem StageIndex desselben Pakets; dann ist TargetFlow fachlich erforderlich und die Stufe muss zu dessen Vorgängerpfad gehören. all benötigt keinen expliziten TargetFlow. Kein Trim/Casefold; unbekannte/leere konkrete ID ungültig. |
| `@LookupPolicies` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet beliebige, pro relevantem Snapshot einmal materialisierte Trefferauswahl. Sonst exakt JSON-Objekt {"schemaVersion":1,"lookups":{"&lt;Lookup-Komponenten-ID&gt;":{"orderBy":[{"column":"&lt;Referenzspalte&gt;","direction":"asc"}]}}}. IDs müssen existierende Lookupkomponenten adressieren, orderBy nicht leer und ohne doppelte Spalten. direction taxativ asc = aufsteigend oder desc = absteigend, exakt kleingeschrieben. Keine freien ORDER-BY-Ausdrücke; vollständige Sortierbindung erforderlich, Gleichstände erhalten keine erfundene Eindeutigkeit. |
| `@ComparisonCollation` | `sysname` | `NULL` | Input | NULL (Default) verwendet bei Katalogbindung die Collation der expliziten defaultDatabase. Sonst genau ein tatsächlich vom Server unterstützter Collationname als sysname, kein COLLATE-SQL-Fragment; Prüfung gegen sys.fn_helpcollations. Dynamische Serverwertemenge, kein festes erfundenes Inventar: SELECT name FROM sys.fn_helpcollations() zeigt sie. Dient Vergleichs-/Ausdrucksbindung und ändert keine DB-/Spaltencollation; leer/unbekannt ungültig. |
| `@TSqlVersion` | `smallint` | `150` | Input | Taxativ: 150 = SQL-Server-2019-Grammatik (Default), 160 = 2022, 170 = 2025 für die Parser-/Sicherheitsprüfung erzeugten SQLs. Kein automatischer Dialektwechsel/Ablesen der Engineversion. NULL/andere smallint-Werte ungültig. |
| `@MaxPackageBytes` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: Rohbytes des DTSX-Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxXmlCharacters` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: vom XML-Reader gezählte Zeichen des Pakets. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxXmlNodes` | `bigint` | `1048576` | Input | bigint 0..9223372036854775807, Default 1048576: gelesene XML-Knoten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxModelNodes` | `bigint` | `262144` | Input | bigint 0..9223372036854775807, Default 262144: Knoten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxModelEdges` | `bigint` | `1048576` | Input | bigint 0..9223372036854775807, Default 1048576: Kanten des importierten Modells. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxComponents` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: SSIS-Komponenten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxPaths` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: Datenflusskanten/Pfade. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxColumns` | `bigint` | `65536` | Input | bigint 0..9223372036854775807, Default 65536: importierte Spaltenmetadaten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxInputs` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: entdeckte/gebundene Eingaben. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxJsonDocumentBytes` | `bigint` | `4194304` | Input | bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes je JSON-Eingabedokument; ProjectContext behält zusätzlich das feste Kontrollprotokolllimit. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxAllJsonBytes` | `bigint` | `8388608` | Input | bigint 0..9223372036854775807, Default 8388608: Summe der UTF-16-Bytes von Bindings, CatalogBindings und LookupPolicies, ohne ProjectContext. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxJsonNodes` | `bigint` | `131072` | Input | bigint 0..9223372036854775807, Default 131072: Knoten je begrenzt geparstem JSON-Dokument. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionBytes` | `bigint` | `4194304` | Input | bigint 0..9223372036854775807, Default 4194304: UTF-16-Bytes eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionTokens` | `bigint` | `262144` | Input | bigint 0..9223372036854775807, Default 262144: Tokens eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxExpressionNodes` | `bigint` | `131072` | Input | bigint 0..9223372036854775807, Default 131072: Knoten eines SSIS-Ausdrucks. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxPlanUnits` | `bigint` | `8192` | Input | bigint 0..9223372036854775807, Default 8192: geprüfte Debugplaneinheiten. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxCatalogObjects` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: gebundene Katalogobjekte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxCatalogQueries` | `bigint` | `4096` | Input | bigint 0..9223372036854775807, Default 4096: Katalogabfragen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxParserCalls` | `bigint` | `32768` | Input | bigint 0..9223372036854775807, Default 32768: SQL-Parser-/Sicherheitsprüfaufrufe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxArtifacts` | `bigint` | `65536` | Input | bigint 0..9223372036854775807, Default 65536: erzeugte Ergebnisartefakte. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxDiagnostics` | `bigint` | `16384` | Input | bigint 0..9223372036854775807, Default 16384: erzeugte Diagnosen. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxSqlArtifactBytes` | `bigint` | `2097152` | Input | bigint 0..9223372036854775807, Default 2097152: UTF-16-Bytes je erzeugtem SQL-Artefakt. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxTotalOutputBytes` | `bigint` | `134217728` | Input | bigint 0..9223372036854775807, Default 134217728: UTF-16-Bytes der gezählten Gesamtausgabe. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@MaxAnalysisMilliseconds` | `bigint` | `0` | Input | bigint 0..9223372036854775807, Default 0: Millisekunden kooperatives Analysezeitbudget, keine harte Gesamtwallclock-Garantie. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten; der vollständige Artefaktsatz wird vor Zielmutation erzeugt. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 eine redigierte Abschlussmessage mit Artefakt-/SQL-Prüfeinheitenzählern. Kein zusätzliches Resultset und keine Quell-/Secretwerte; der interne ResultTable-Helper wird ausdrücklich mit Debug=0 aufgerufen. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

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

<!-- Source/Vertrag SHA256: 9818a3812285df7291e50a2664aa770c4cb928fdb49d2b1e5804d9ad9cabb3ba -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_validation.TVF_ParseSemanticVersion(N'1.2.3-alpha.1+build.7');
```

## toolbelt_validation.TVF_CompareSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Vergleicht zwei SemVer-Versionen; Build-Metadaten ändern die fachliche Rangfolge nicht.

Vertrag und Quelle: [TVF_CompareSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_CompareSemanticVersion.sql), [TVF_CompareSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_CompareSemanticVersion.md).

<!-- Source/Vertrag SHA256: f98f27b8cc1b1e46d2e8bcccac98d35cc0d3dc69ad6864e6430698b4b6201926 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | Linker Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | Rechter Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion(N'1.2.3', N'2.0.0');
```

## toolbelt_validation.TVF_SemanticVersionSortKey

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version.

Vertrag und Quelle: [TVF_SemanticVersionSortKey.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_SemanticVersionSortKey.sql), [TVF_SemanticVersionSortKey.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_SemanticVersionSortKey.md).

<!-- Source/Vertrag SHA256: 25a0d144057821f7b60ab2c5a625d3ccbab3bbad59b7aa66535a458429d2d9ac -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_validation.TVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7');
```

## toolbelt_validation.SVF_CompareSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `SVF`

Vergleicht zwei SemVer-Versionen; Build-Metadaten ändern die fachliche Rangfolge nicht.

Vertrag und Quelle: [SVF_CompareSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/SVF_CompareSemanticVersion.sql), [SVF_CompareSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_CompareSemanticVersion.md).

<!-- Source/Vertrag SHA256: 70f72271a5cca9e04091eb7e692c92e532d2f313887e44f1acf789da1eeab3e9 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | Linker Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | Rechter Vergleichsoperand. ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_validation.SVF_CompareSemanticVersion(N'1.2.3', N'2.0.0') AS ResultValue;
```

## toolbelt_validation.SVF_SemanticVersionSortKey

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `SVF`

Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version.

Vertrag und Quelle: [SVF_SemanticVersionSortKey.sql](../../Modules/toolbelt.validation.semantic-version/Source/SVF_SemanticVersionSortKey.sql), [SVF_SemanticVersionSortKey.md](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_SemanticVersionSortKey.md).

<!-- Source/Vertrag SHA256: 294f518d0fc4e9dc0b79ceced99fcdf245eb30d3158f730b90ec19022d208f32 -->

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_validation.SVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7') AS ResultValue;
```

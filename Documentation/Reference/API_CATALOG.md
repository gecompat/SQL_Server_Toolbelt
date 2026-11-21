# SQL Server Toolbelt Beispielkatalog

<!-- Generiert mit Tests/Documentation/generate_api_catalog.py --write; nicht direkt bearbeiten. -->

170 öffentliche Schnittstellen aus 44 Modulen. Dieser Katalog ergänzt die verbindlichen Objektverträge mit kurzen Erklärungen, Source-Signaturen und synthetischen Beispielaufrufen.

Jedes Beispiel separat verwenden. Funktionen verlangen positionsbezogene Argumente; `DEFAULT` verwendet einen deklarierten Default, `NULL` kann davon abweichen. Prozeduren verwenden benannte Parameter. Vorlagen mit Handlern, Claims, Dateien oder Plan-Hashes erfordern die beschriebenen Voraussetzungen. Eine Syntaxvorlage ist kein Runtime-Nachweis.

Pflege und Generierung: [README](README.md).

## toolbelt_archive.USP_CreateZipFileFromEntries

Modul `toolbelt.archive.zip-files` · Version `1.0.0` · `USP`

Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.

Vertrag und Quelle: [USP_CreateZipFileFromEntries.sql](../../Modules/toolbelt.archive.zip-files/Source/USP_CreateZipFileFromEntries.sql), [USP_CreateZipFileFromEntries.md](../../Modules/toolbelt.archive.zip-files/Documentation/USP_CreateZipFileFromEntries.md), [USP_CreateZipFileFromEntries.md](../../Metadata/UsageSkills/toolbelt_archive/USP_CreateZipFileFromEntries.md).

<!-- Source/Vertrag SHA256: dbeb2b8a857ff2e7b7071301502f92f1322eb63aeb2e9d114854bfca39e17097 -->

Voraussetzung: Windows-only mit lokalem ZIPfiles1.0.0-Profil, ZIPmemory1.4.0, Windowsfilesystem1.0.0 und ResultTable derselben Datenbank. Vorhandener aktiver Root mit AllowWrite, bestehendes Zielverzeichnis und NTFS-Rechte. Caller-Modus verlangt Windowsauthentifizierung. ServiceAccount nur bei expliziter Wahl mit toolbelt_filesystem_service_account und Root-AllowServiceAccount. Keine zentrale Cross-DB- oder Linuxroute.

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
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ContosoEntries VALUES(1,N'contoso.txt',0x010203);
-- NurmitvorhandenemautorisiertemRoot/Zielverzeichnis;schreibteineDatei.
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#ContosoEntries',@RootAlias=N'ContosoRoot',@RelativePath=N'out\contoso.zip';
DROP TABLE #ContosoEntries;
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
```

## toolbelt_archive.USP_ExtractZipEntryToFile

Modul `toolbelt.archive.zip-files` · Version `1.0.0` · `USP`

Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.

Vertrag und Quelle: [USP_ExtractZipEntryToFile.sql](../../Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipEntryToFile.sql), [USP_ExtractZipEntryToFile.md](../../Modules/toolbelt.archive.zip-files/Documentation/USP_ExtractZipEntryToFile.md), [USP_ExtractZipEntryToFile.md](../../Metadata/UsageSkills/toolbelt_archive/USP_ExtractZipEntryToFile.md).

<!-- Source/Vertrag SHA256: 1c0086d81e66dc24849c0752e6a6d0eb4d9caf7d0fd1cce4eb16035a9b903750 -->

Voraussetzung: Windows-only mit lokalem ZIPfiles1.0.0-Profil, ZIPmemory1.4.0, Windowsfilesystem1.0.0 und ResultTable derselben Datenbank. Vorhandener aktiver Root mit AllowWrite, bestehendes Zielverzeichnis und NTFS-Rechte. Caller-Modus verlangt Windowsauthentifizierung. ServiceAccount nur bei expliziter Wahl mit toolbelt_filesystem_service_account und Root-AllowServiceAccount. Keine zentrale Cross-DB- oder Linuxroute.

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
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @Hilfe=1;
-- VollständigeZIPbytesvomClientanstelleNULLbinden.
DECLARE @Archive varbinary(max)=NULL;
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=@Archive,@EntryName=N'contoso.txt',@RootAlias=N'ContosoRoot',@RelativePath=N'out\contoso.txt';
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @Hilfe=1;
```

## toolbelt_archive.USP_ExtractZipArchiveToDirectory

Modul `toolbelt.archive.zip-files` · Version `1.0.0` · `USP`

Extrahiert ein ZIP gestreamt in einen konfigurierten lokalen NTFS-Ordner und meldet jeden Eintrag.

Vertrag und Quelle: [USP_ExtractZipArchiveToDirectory.sql](../../Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipArchiveToDirectory.sql), [USP_ExtractZipArchiveToDirectory.md](../../Modules/toolbelt.archive.zip-files/Documentation/USP_ExtractZipArchiveToDirectory.md), [USP_ExtractZipArchiveToDirectory.md](../../Metadata/UsageSkills/toolbelt_archive/USP_ExtractZipArchiveToDirectory.md).

<!-- Source/Vertrag SHA256: 515458a409107af03c7c46b3180423a9c65a3bf85f958994c5b255353bd08bff -->

Voraussetzung: Lokale Installation auf Windows SQL Server, festes NTFS-Laufwerk und vorhandene Root-Konfiguration. Für fehlende Verzeichnisse ist AllowCreateDirectory erforderlich. Die Sitzung darf keine aktive oder implizite SQL-Transaktion haben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig. |
| `@RootAlias` | `sysname` | `NULL` | Input | Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig. |
| `@RelativeDirectory` | `nvarchar(4000)` | `N''` | Input | Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig. |
| `@OverwriteExistingFiles` | `bit` | `0` | Input | 0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig. |
| `@MaxArchiveBytes` | `bigint` | `67108864` | Input | Archivbytes. 1 bis 268435456, NULL ungültig. |
| `@MaxEntries` | `bigint` | `1000` | Input | Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig. |
| `@MaxTotalExpandedBytes` | `bigint` | `268435456` | Input | Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig. |
| `@MaxPathLength` | `int` | `1024` | Input | ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Input | Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag. |
| `@KeepData` | `bit` | `0` | Input | Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | 0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @Hilfe = 1;
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @Hilfe=1;
```

## toolbelt_archive.USP_CreateZipFromEntries

Modul `toolbelt.archive.zip-memory` · Version `1.4.0` · `USP`

Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.

Vertrag und Quelle: [USP_CreateZipFromEntries.sql](../../Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql), [USP_CreateZipFromEntries.md](../../Modules/toolbelt.archive.zip-memory/Documentation/USP_CreateZipFromEntries.md), [USP_CreateZipFromEntries.md](../../Metadata/UsageSkills/toolbelt_archive/USP_CreateZipFromEntries.md).

<!-- Source/Vertrag SHA256: 5c711b21ee50d5533ed20a8ed017b66dbb3cacddfe12b47f563daf91b137fab9 -->

Voraussetzung: ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ContosoEntries VALUES(1,N'contoso.txt',0x010203);
EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
```

## toolbelt_archive.USP_ExtractZipEntryFromBinary

Modul `toolbelt.archive.zip-memory` · Version `1.4.0` · `USP`

Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.

Vertrag und Quelle: [USP_ExtractZipEntryFromBinary.sql](../../Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql), [USP_ExtractZipEntryFromBinary.md](../../Modules/toolbelt.archive.zip-memory/Documentation/USP_ExtractZipEntryFromBinary.md), [USP_ExtractZipEntryFromBinary.md](../../Metadata/UsageSkills/toolbelt_archive/USP_ExtractZipEntryFromBinary.md).

<!-- Source/Vertrag SHA256: 1ad150626ea364a67652530ea48100ee841a84449f22f5e505b494944eb73cd2 -->

Voraussetzung: ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/&lt;1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad. |
| `@FailIfEncrypted` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;
-- VollständigeZIPbytesvomClientanstelleNULLbinden.
DECLARE @Archive varbinary(max)=NULL;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'contoso.txt';
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;
```

## toolbelt_archive.USP_ListZipEntriesFromBinary

Modul `toolbelt.archive.zip-memory` · Version `1.4.0` · `USP`

Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren.

Vertrag und Quelle: [USP_ListZipEntriesFromBinary.sql](../../Modules/toolbelt.archive.zip-memory/Source/USP_ListZipEntriesFromBinary.sql), [USP_ListZipEntriesFromBinary.md](../../Modules/toolbelt.archive.zip-memory/Documentation/USP_ListZipEntriesFromBinary.md), [USP_ListZipEntriesFromBinary.md](../../Metadata/UsageSkills/toolbelt_archive/USP_ListZipEntriesFromBinary.md).

<!-- Source/Vertrag SHA256: 0c7be9bfeb92f3237d8f3dbc9c8de2c6f0b71ba903d309ca08c5ee73b8cb7cfd -->

Voraussetzung: ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..10000 Central-Directory-Entries, Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @Hilfe=1;
-- VollständigeZIPbytesvomClientanstelleNULLbinden.
DECLARE @Archive varbinary(max)=NULL;
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@Archive;
```

Hilfe:

```sql
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @Hilfe=1;
```

## toolbelt_binary.TVF_LeftShiftBigInt

Modul `toolbelt.binary.bit-operations` · Version `1.0.0` · `TVF`

Verschiebt die Bits eines bigint-Werts nach links.

Vertrag und Quelle: [TVF_LeftShiftBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_LeftShiftBigInt.sql), [TVF_LeftShiftBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_LeftShiftBigInt.md), [TVF_LeftShiftBigInt.md](../../Metadata/UsageSkills/toolbelt_binary/TVF_LeftShiftBigInt.md).

<!-- Source/Vertrag SHA256: 9100359be043ed8e810937fc88a98d7e33eb69e9060ea91dcfffdab4123c39c6 -->

Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.

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

Vertrag und Quelle: [TVF_RightShiftBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_RightShiftBigInt.sql), [TVF_RightShiftBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_RightShiftBigInt.md), [TVF_RightShiftBigInt.md](../../Metadata/UsageSkills/toolbelt_binary/TVF_RightShiftBigInt.md).

<!-- Source/Vertrag SHA256: a5f1219527249b4db4ab138731dde75b3fc0eef987721c3347bb5a3e6e5784b5 -->

Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.

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

Vertrag und Quelle: [TVF_BitCountBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_BitCountBigInt.sql), [TVF_BitCountBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_BitCountBigInt.md), [TVF_BitCountBigInt.md](../../Metadata/UsageSkills/toolbelt_binary/TVF_BitCountBigInt.md).

<!-- Source/Vertrag SHA256: 6a1258f344d2586cbb4768e4443f982f83aa7e2a1206ed597e669e945ebb5ad6 -->

Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.

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

Vertrag und Quelle: [TVF_GetBitBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_GetBitBigInt.sql), [TVF_GetBitBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_GetBitBigInt.md), [TVF_GetBitBigInt.md](../../Metadata/UsageSkills/toolbelt_binary/TVF_GetBitBigInt.md).

<!-- Source/Vertrag SHA256: ea55af37f7d291cc2b8d04407449f056dc0d71056db35c7e793d85ad430a66a0 -->

Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.

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

Vertrag und Quelle: [TVF_SetBitBigInt.sql](../../Modules/toolbelt.binary.bit-operations/Source/TVF_SetBitBigInt.sql), [TVF_SetBitBigInt.md](../../Modules/toolbelt.binary.bit-operations/Documentation/TVF_SetBitBigInt.md), [TVF_SetBitBigInt.md](../../Metadata/UsageSkills/toolbelt_binary/TVF_SetBitBigInt.md).

<!-- Source/Vertrag SHA256: 9c97a294c3e700e1399186e4970c8d301a7ee0ad42445c82ebf73262fbc33c85 -->

Voraussetzung: SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.

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

Vertrag und Quelle: [TVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql), [TVF_Base64Encode.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64Encode.md), [TVF_Base64Encode.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_Base64Encode.md).

<!-- Source/Vertrag SHA256: ddb2553f8d55467a780b79a3c6d97471aba77046b0f0c7d4542c93d834d7e06f -->

Voraussetzung: SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT EncodedValue
FROM toolbelt_conversion.TVF_Base64Encode(0xCAFECAFE,0);
-- Erwartet: yv7K/g==
```

## toolbelt_conversion.TVF_Base64Decode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Decodiert Base64-Text zu Binärdaten.

Vertrag und Quelle: [TVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql), [TVF_Base64Decode.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64Decode.md), [TVF_Base64Decode.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_Base64Decode.md).

<!-- Source/Vertrag SHA256: 052f2936c5408fc5c77591f9d2e607f8e18ce169f7c61a08a51b532175cbb2f5 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64Decode('yv7K_g');
-- 0xCAFECAFE
```

## toolbelt_conversion.SVF_Base64Encode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `SVF`

Codiert Binärdaten als Base64 oder Base64URL.

Vertrag und Quelle: [SVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql), [SVF_Base64Encode.md](../../Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Encode.md), [SVF_Base64Encode.md](../../Metadata/UsageSkills/toolbelt_conversion/SVF_Base64Encode.md).

<!-- Source/Vertrag SHA256: 084658123d579b5aa2fd77ec60290f3355a10c8c111bce0d0dfc45366d38184f -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE,0) AS Value;
-- yv7K/g==
```

## toolbelt_conversion.SVF_Base64Decode

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `SVF`

Decodiert Base64-Text zu Binärdaten.

Vertrag und Quelle: [SVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql), [SVF_Base64Decode.md](../../Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Decode.md), [SVF_Base64Decode.md](../../Metadata/UsageSkills/toolbelt_conversion/SVF_Base64Decode.md).

<!-- Source/Vertrag SHA256: 170a2ed9cd5b54afcbfac79cca1f018b787a65c081ce53799a29a300aa701f7b -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_Base64Decode('yv7K_g') AS Value;
-- 0xCAFECAFE
```

## toolbelt_conversion.TVF_Base64EncodeStatus

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Codiert begrenzte Binärdaten als Base64 oder Base64URL mit explizitem NULL-/Limitstatus.

Vertrag und Quelle: [TVF_Base64Encode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql), [TVF_Base64EncodeStatus.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64EncodeStatus.md), [TVF_Base64EncodeStatus.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_Base64EncodeStatus.md).

<!-- Source/Vertrag SHA256: 8f8636d26ea1322b84249e320767c8cb33fb0c059a28246cfc9449e4abcf79cd -->

Voraussetzung: SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT EncodedValue,Status
FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFECAFE,0);
-- yv7K/g==, OK
SELECT EncodedValue,Status
FROM toolbelt_conversion.TVF_Base64EncodeStatus(NULL,1);
-- NULL, SQL_NULL
```

## toolbelt_conversion.TVF_Base64DecodeStatus

Modul `toolbelt.conversion.base64` · Version `1.1.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL.

Vertrag und Quelle: [TVF_Base64Decode.sql](../../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql), [TVF_Base64DecodeStatus.md](../../Modules/toolbelt.conversion.base64/Documentation/TVF_Base64DecodeStatus.md), [TVF_Base64DecodeStatus.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_Base64DecodeStatus.md).

<!-- Source/Vertrag SHA256: 3e60cd8c06402380d4d60f2ccfabf32d1d32d8e787fd420b830cbd6d773030dc -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('yv7K_g');
-- 0xCAFECAFE, Status=OK
```

## toolbelt_conversion.TVF_IntegerToBase

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `TVF`

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Vertrag und Quelle: [TVF_IntegerToBase.sql](../../Modules/toolbelt.conversion.integer-base/Source/TVF_IntegerToBase.sql), [TVF_IntegerToBase.md](../../Modules/toolbelt.conversion.integer-base/Documentation/TVF_IntegerToBase.md), [TVF_IntegerToBase.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_IntegerToBase.md).

<!-- Source/Vertrag SHA256: d586ba4cc906339d1dee801fbe78abd08f6b3a39ae8910b13ac6807078886026 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_IntegerToBase(255,'0123456789ABCDEF');
-- FF
```

## toolbelt_conversion.TVF_TryBaseToInteger

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `TVF`

Decodiert einen Text anhand des angegebenen Alphabets in bigint.

Vertrag und Quelle: [TVF_TryBaseToInteger.sql](../../Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql), [TVF_TryBaseToInteger.md](../../Modules/toolbelt.conversion.integer-base/Documentation/TVF_TryBaseToInteger.md), [TVF_TryBaseToInteger.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_TryBaseToInteger.md).

<!-- Source/Vertrag SHA256: aa2844ac5ee7397aae97322f79ce0894015852b8fe23494f3d8b7ed2fb6d0d32 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_TryBaseToInteger('FF','0123456789ABCDEF');
-- 255
```

## toolbelt_conversion.SVF_IntegerToBase

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `SVF`

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Vertrag und Quelle: [SVF_IntegerToBase.sql](../../Modules/toolbelt.conversion.integer-base/Source/SVF_IntegerToBase.sql), [SVF_IntegerToBase.md](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_IntegerToBase.md), [SVF_IntegerToBase.md](../../Metadata/UsageSkills/toolbelt_conversion/SVF_IntegerToBase.md).

<!-- Source/Vertrag SHA256: 084476647978b2ffef8c619c8869e0fa77668be0d9ef29f0392f997d62c0579e -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_IntegerToBase(255,'0123456789ABCDEF') AS Value;
-- FF
```

## toolbelt_conversion.SVF_TryBaseToInteger

Modul `toolbelt.conversion.integer-base` · Version `1.1.0` · `SVF`

Decodiert einen Text anhand des angegebenen Alphabets in bigint.

Vertrag und Quelle: [SVF_TryBaseToInteger.sql](../../Modules/toolbelt.conversion.integer-base/Source/SVF_TryBaseToInteger.sql), [SVF_TryBaseToInteger.md](../../Modules/toolbelt.conversion.integer-base/Documentation/SVF_TryBaseToInteger.md), [SVF_TryBaseToInteger.md](../../Metadata/UsageSkills/toolbelt_conversion/SVF_TryBaseToInteger.md).

<!-- Source/Vertrag SHA256: e634d0402cf7f5494c907b0e19986f742288233a28db4f5a7956b5a769b58276 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_TryBaseToInteger('FF','0123456789ABCDEF') AS Value;
-- 255
```

## toolbelt_conversion.TVF_TryCastBigInt

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft ASCII-Ganzzahltext und den exakten bigint-Bereich; liefert Value, Status und ErrorCode.

Vertrag und Quelle: [TVF_TryCastBigInt.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBigInt.sql), [TVF_TryCastBigInt.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBigInt.md), [TVF_TryCastBigInt.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_TryCastBigInt.md).

<!-- Source/Vertrag SHA256: 7cbb93f59755e8d3174c92bd0219142c3d26231bca272ebca075778a3c7a0fa4 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Dezimaltext mit mindestens einer Ziffer 0..9 und optional einem führenden + oder -. Führende Nullen/negative Null sind zulässig. Kein Trim, kein Unicode-Ziffernersatz, Dezimalpunkt, Exponent oder Tausendertrennzeichen. Zielbereich -9223372036854775808..9223372036854775807. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBigInt(N'+00042',DEFAULT);
-- 42, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBigInt(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
```

## toolbelt_conversion.TVF_TryCastDecimal

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft exakten decimal(38,18)-Bereich vor Skalenverlust; rundet niemals still.

Vertrag und Quelle: [TVF_TryCastDecimal.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDecimal.sql), [TVF_TryCastDecimal.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDecimal.md), [TVF_TryCastDecimal.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_TryCastDecimal.md).

<!-- Source/Vertrag SHA256: 8a8d3d1b4a84564ebc60121f11f3e80c8976d56073ebe1b32fced155832712dc -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Dezimaltext mit optional führendem +/-, mindestens einer Ganzzahlziffer und optional Punkt mit mindestens einer Nachkommastelle. Keine Kommas, Exponenten oder Spaces. Führende Nullen sind zulässig. Ziel decimal(38,18), maximal 20 Ganzzahl- und 18 relevante Nachkommastellen; weitere Nullen sind exakt entfernbar, weitere nichtnull Ziffern bedeuten LOSSY/SCALE. Ein Bereichsfehler hat davor Vorrang. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDecimal(N'12.5000000000000000000',DEFAULT);
-- 12.500000000000000000, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDecimal(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
```

## toolbelt_conversion.TVF_TryCastDate

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft exakt YYYY-MM-DD und den date-Kalenderbereich unabhängig von Sprache und DATEFORMAT.

Vertrag und Quelle: [TVF_TryCastDate.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDate.sql), [TVF_TryCastDate.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDate.md), [TVF_TryCastDate.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_TryCastDate.md).

<!-- Source/Vertrag SHA256: 9306695997385e4bd48268c4825ae35407a3ce789cfb70af55391d79302a0ae7 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau YYYY-MM-DD mit ASCII-Ziffern und Bindestrichen (10 UTF-16-Codeeinheiten); keine Uhrzeit oder Localeform. Gültiger gregorianischer SQL-date-Bereich 0001-01-01..9999-12-31; unmögliche Kalenderdaten ergeben OUT_OF_RANGE. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDate(N'2026-11-20',DEFAULT);
-- 2026-11-20, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDate(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
```

## toolbelt_conversion.TVF_TryCastDateTime2

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft ISO-Datetime mit großem T und höchstens sieben Fractionziffern ohne Rundung oder Zeitzonenverlust.

Vertrag und Quelle: [TVF_TryCastDateTime2.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDateTime2.sql), [TVF_TryCastDateTime2.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDateTime2.md), [TVF_TryCastDateTime2.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_TryCastDateTime2.md).

<!-- Source/Vertrag SHA256: f0f9645f7c950b15a519e289588a3b28874b787375a413af261887c8ce5a9879 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau YYYY-MM-DDTHH:mm:ss, optional gefolgt von Punkt und 1..7 ASCII-Nachkommastellen (großes T, insgesamt 19 oder 21..27 Codeeinheiten). Kein Z, Offset, Leerzeichen, 24-Uhr-Zeit, Schaltsekunde oder Rundung; gültiger SQL-datetime2(7)-Bereich. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDateTime2(N'2026-11-20T12:34:56.1234567',DEFAULT);
-- 2026-11-20 12:34:56.1234567, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastDateTime2(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
```

## toolbelt_conversion.TVF_TryCastBit

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Akzeptiert ausschließlich den Text0 oder1; native permissive Bitkonversion bleibt ausgeschlossen.

Vertrag und Quelle: [TVF_TryCastBit.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBit.sql), [TVF_TryCastBit.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBit.md), [TVF_TryCastBit.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_TryCastBit.md).

<!-- Source/Vertrag SHA256: 49de10844e1e6e322bf6c2744c9bbf8541bc1711d8be63f030d95bd25e5fd0f1 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Taxativ als Text: N'0' ergibt bit 0; N'1' ergibt bit 1. Keine anderen Werte, Vorzeichen, TRUE/FALSE, Spaces oder Normalisierung; dies ist ein strikter Textparser und nicht die native bit-Konvertierung. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBit(N'1',DEFAULT);
-- 1, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastBit(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
```

## toolbelt_conversion.TVF_TryCastUniqueIdentifier

Modul `toolbelt.conversion.safe-cast` · Version `1.0.0` · `TVF`

Prüft vollständige GUID-Lexik im8-4-4-4-12-Muster vor Konversion; keine Suffixtrunkierung.

Vertrag und Quelle: [TVF_TryCastUniqueIdentifier.sql](../../Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastUniqueIdentifier.sql), [TVF_TryCastUniqueIdentifier.md](../../Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastUniqueIdentifier.md), [TVF_TryCastUniqueIdentifier.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_TryCastUniqueIdentifier.md).

<!-- Source/Vertrag SHA256: d4c72f61a7e3b3ef5ed504dc774931ae4ee6c18ade9f9abd59d35df28de7a189 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Safe-Cast-Modul installiert. Keine Modul-/Tabellen-/CLR-/Katalogabhängigkeit. Beide Funktionsargumentpositionen angeben, DEFAULT für das technische Budget 8192. Eingabe als Unicodeparameter nvarchar(max) binden, damit keine vorgelagerte varchar-Codepagekonversion den Originaltext verändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau 36 ASCII-Codeeinheiten im Hexmuster 8-4-4-4-12, etwa N'00000000-0000-0000-0000-000000000001'. Hexziffern 0..9/A..F/a..f; Bindestriche an den vier festen Positionen. Keine Klammern, Präfixe, Spaces oder Suffixtrunkierung. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastUniqueIdentifier(N'00112233-4455-6677-8899-aabbccddeeff',DEFAULT);
-- 00112233-4455-6677-8899-aabbccddeeff, OK, NULL
SELECT Value,Status,ErrorCode
FROM toolbelt_conversion.TVF_TryCastUniqueIdentifier(NULL,0);
-- NULL, SQL_NULL, NULL (Text-NULL hat Vorrang).
```

## toolbelt_conversion.TVF_UriComponentEncode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung.

Vertrag und Quelle: [TVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql), [TVF_UriComponentEncode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncode.md), [TVF_UriComponentEncode.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_UriComponentEncode.md).

<!-- Source/Vertrag SHA256: 34192d8ce36a1ae0bc40cd23aebce378c8a7063ffed484a0785f17b06241ccfb -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncode(N'a b/Ä');
-- a%20b%2F%C3%84
```

## toolbelt_conversion.TVF_UriComponentDecode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

Vertrag und Quelle: [TVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql), [TVF_UriComponentDecode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentDecode.md), [TVF_UriComponentDecode.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_UriComponentDecode.md).

<!-- Source/Vertrag SHA256: f2fcf3e061354eb481025353a6a7bbcc892e72f41aeb0a217e452785186e17de -->

Voraussetzung: URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
```

## toolbelt_conversion.SVF_UriComponentEncode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `SVF`

Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung.

Vertrag und Quelle: [SVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentEncode.sql), [SVF_UriComponentEncode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/SVF_UriComponentEncode.md), [SVF_UriComponentEncode.md](../../Metadata/UsageSkills/toolbelt_conversion/SVF_UriComponentEncode.md).

<!-- Source/Vertrag SHA256: 56225f0643d6101b4e07e480dab1b7af76b88d83186eb5a5dd1d9e5ea7a5694f -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_conversion.SVF_UriComponentEncode(N'a b/Ä') AS Value;
-- a%20b%2F%C3%84
```

## toolbelt_conversion.SVF_UriComponentDecode

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `SVF`

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

Vertrag und Quelle: [SVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentDecode.sql), [SVF_UriComponentDecode.md](../../Modules/toolbelt.conversion.uri-component/Documentation/SVF_UriComponentDecode.md), [SVF_UriComponentDecode.md](../../Metadata/UsageSkills/toolbelt_conversion/SVF_UriComponentDecode.md).

<!-- Source/Vertrag SHA256: 212a3b16577d9799d3a43049b70283714fed934cfc7b7e9a97c495dc67af7e21 -->

Voraussetzung: URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
```

## toolbelt_conversion.TVF_UriComponentEncodeStatus

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Codiert eine Unicode-URI-Komponente als begrenzte UTF-8-Percentdarstellung.

Vertrag und Quelle: [TVF_UriComponentEncode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql), [TVF_UriComponentEncodeStatus.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncodeStatus.md), [TVF_UriComponentEncodeStatus.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_UriComponentEncodeStatus.md).

<!-- Source/Vertrag SHA256: ffffcb5db42aa4ce5d5e80be638547202047d42a89c8c3adc1a0d6b60b279f04 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. URI-Modul und deklarierte Generate-Series-Abhängigkeit installiert. SQL-UTF8-Kollation Latin1_General_100_BIN2_UTF8 und master.dbo.fn_varbintohexstr werden vom T-SQL-Provider verwendet. Kein CLR, Datei-/Netzwerkzugriff oder Fachsystemkatalog.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'a b/Ä');
-- a%20b%2F%C3%84, Status=OK
```

## toolbelt_conversion.TVF_UriComponentDecodeStatus

Modul `toolbelt.conversion.uri-component` · Version `1.0.0` · `TVF`

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL.

Vertrag und Quelle: [TVF_UriComponentDecode.sql](../../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql), [TVF_UriComponentDecodeStatus.md](../../Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentDecodeStatus.md), [TVF_UriComponentDecodeStatus.md](../../Metadata/UsageSkills/toolbelt_conversion/TVF_UriComponentDecodeStatus.md).

<!-- Source/Vertrag SHA256: d128463f88a1372c827237f2e418f8991d5ed92095b41a3f8df3d097eeac96b7 -->

Voraussetzung: URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
```

## toolbelt_core.USP_WriteConsoleMessage

Modul `toolbelt.core.console-message` · Version `1.0.0` · `USP`

Gibt begrenzten Unicode-Text in den SQL-Messages-Kanal aus, wahlweise mit NOWAIT.

Vertrag und Quelle: [USP_WriteConsoleMessage.sql](../../Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql), [USP_WriteConsoleMessage.md](../../Modules/toolbelt.core.console-message/Documentation/USP_WriteConsoleMessage.md), [USP_WriteConsoleMessage.md](../../Metadata/UsageSkills/toolbelt_core/USP_WriteConsoleMessage.md).

<!-- Source/Vertrag SHA256: cfa58f28d9c810b9fce5deac9be4351f9f01da040ee0b2fe7647462d5377e06f -->

Voraussetzung: Installierte reine T-SQL-Prozedur auf SQL Server 2019/2022/2025, Windows oder Linux, lokal/zentral gemäß Modulvertrag. Client/Treiber muss Informationsnachrichten entgegennehmen; NOWAIT ist keine Zusage sofortiger UI-Darstellung. Keine CLR-, Datei-, Netzwerk- oder Tabellenabhängigkeit.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Message` | `nvarchar(max)` | `NULL` | Input | Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen. |
| `@Immediate` | `bit` | `0` | Input | Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe plus genau ein vierkolumniges Skill-Resultset und kehrt vor Fachprüfungen und Fachausgabe zurück. 0 oder NULL führt den Normalpfad aus. Alle übrigen Parameter werden bei Hilfe fachlich ignoriert; ihre SQL-Typbindung gilt weiterhin. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=N'Example progress: 25%',@Immediate=1;
EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe=1;
```

## toolbelt_core.USP_CaptureErrorEnvelope

Modul `toolbelt.core.error-envelope` · Version `1.0.0` · `USP`

Formatiert explizit übergebene Fehlerdaten mit aktuellem Ausführungskontext als eine Fehlerzeile.

Vertrag und Quelle: [USP_CaptureErrorEnvelope.sql](../../Modules/toolbelt.core.error-envelope/Source/USP_CaptureErrorEnvelope.sql), [USP_CaptureErrorEnvelope.md](../../Modules/toolbelt.core.error-envelope/Documentation/USP_CaptureErrorEnvelope.md), [USP_CaptureErrorEnvelope.md](../../Metadata/UsageSkills/toolbelt_core/USP_CaptureErrorEnvelope.md).

<!-- Source/Vertrag SHA256: c8b05f1252fe109f9cddb0f3e57460b6a6bae7e70b6aa4f35d31e1d678b68cab -->

Voraussetzung: Installierte T-SQL-Prozedur auf SQL Server 2019/2022/2025, Windows/Linux, lokal/zentral gemäß Modulvertrag. Direktes Resultset benötigt keine ResultTable-Operation und funktioniert im vorgesehenen uncommittable Callerpfad ohne Temp-DDL/INSERT. Für ResultTable-Ausgabe vorhandene lokale #Temp und USP_PrepareResultTable; zuerst Caller-Rollback bei XACT_STATE()=-1.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ErrorNumber` | `int` | `NULL` | Input | Fachlich erforderlich: positive int-Fehlernummer 1..2147483647, üblicherweise ERROR_NUMBER() im aufrufenden CATCH. Technischer Default NULL dient nur Help; NULL/&lt;=0 wird 51400. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Fachlich erforderlich: int 0..25 einschließlich, üblicherweise ERROR_SEVERITY() aus demselben CATCH. NULL/außerhalb ergibt 51401; technischer Default NULL nur für Help. |
| `@ErrorState` | `int` | `NULL` | Input | Fachlich erforderlich: int 0..255 einschließlich aus ERROR_STATE() im CATCH. NULL/außerhalb ergibt 51402; technischer Default NULL nur für Help. |
| `@ErrorProcedure` | `nvarchar(776)` | `NULL` | Input | Optionaler reiner Unicode-Text nvarchar(776), normalerweise ERROR_PROCEDURE() im CATCH, kein auszuführender Objektname. NULL bleibt NULL, leerer Text wird nicht besonders validiert. |
| `@ErrorLine` | `int` | `NULL` | Input | Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL (Default) ist erlaubt, 0/negativ ergibt 51403. |
| `@ErrorMessage` | `nvarchar(4000)` | `NULL` | Input | Fachlich erforderlicher Unicode-Fehlertext nvarchar(4000), normalerweise ERROR_MESSAGE() im CATCH. NULL, leer und nach SQL-Gleichheit leere reine Spacefolgen ergeben 51404; keine automatische Redigierung geheimer Inhalte. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Optionaler SQL-uniqueidentifier, Default NULL. NULL liest SESSION_CONTEXT(N'toolbelt.execution.id') mit TRY_CONVERT(uniqueidentifier,...); fehlende oder nicht parsebare Werte können NULL ergeben, ausdrücklich nicht unterstützte Konvertierungen behalten Enginefehler. Explizite ID wird unverändert übernommen und muss keinem gespeicherten Kontext entsprechen. Kein automatischer Kontextschreibzugriff. |
| `@AdditionalContext` | `nvarchar(4000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(4000), kein vorgeschriebenes JSON-Schema und keine Ausführung. NULL/leer wird unverändert ausgegeben; nur bereits bereinigte, für den Empfänger zulässige Zusatzinformation übergeben. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) gibt eine direkte Fehlerzeile aus, auch bei XACT_STATE()=-1. Sonst Name einer bereits vom Caller angelegten lokalen #Temp-Tabelle als sysname, z.B. N'#Envelope', keine globale oder mehrteilige Tabelle; ResultTable-Helper nötig. Bei uncommittable Caller zuerst Rollback, sonst 51406. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 bereitet Replace vor (Default), 1 hängt bei kompatibler ResultTable an; NULL wird vom kanonischen Helper wie 0 behandelt. Nur bei nicht-NULL ResultTable relevant. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) und NULL ohne Diagnose; 1..255 erzeugen eine abstrakte Informationsmeldung ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe plus genau ein vierkolumniges Skill-Resultset und kehrt vor Fachprüfungen und Fachausgabe zurück. 0 oder NULL führt den Normalpfad aus. Alle übrigen Parameter werden bei Hilfe fachlich ignoriert; ihre SQL-Typbindung gilt weiterhin. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Synthetische explizite Fehlerdaten, keine echte Fehlersitzung nötig:
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=50001,@ErrorSeverity=16,@ErrorState=1,
 @ErrorMessage=N'Example failure',@AdditionalContext=N'Synthetic example';
EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
```

## toolbelt_core.VW_Events

Modul `toolbelt.core.event-log` · Version `1.0.0` · `VIEW`

Öffentliche ungefilterte Projektion aller persistierten Ereignis- und Auditspalten.

Vertrag und Quelle: [VW_Events.sql](../../Modules/toolbelt.core.event-log/Source/VW_Events.sql), [VW_Events.md](../../Modules/toolbelt.core.event-log/Documentation/VW_Events.md), [VW_Events.md](../../Metadata/UsageSkills/toolbelt_core/VW_Events.md).

<!-- Source/Vertrag SHA256: 339e490972a6976483cc9d0f5d07a581826829d98270e1680a6b114617e58a8a -->

Voraussetzung: Installiertes Modul toolbelt.core.event-log in der gewählten Datenbank, SQL2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. View benötigt die Tabelle. Für das reine SELECT ist keine aktive Second-Session-Verbindung nötig; die getrennte öffentliche Schreibfassade benötigt ihren konfigurierten Second-Session-/Work-Type-/Execution-Context-Vertrag. Kein automatisches Einrichten dieser Infrastruktur.

Keine Eingabeparameter.

```sql
SELECT TOP (100) EventId,RecordedAtUtc,EventName,EventLevel
FROM toolbelt_core.VW_Events
ORDER BY RecordedAtUtc DESC,EventId DESC;
-- Explizite Reihenfolge; keine ungefilterte Ausgabe von Message/DataJson.
```

## toolbelt_core.USP_WriteEvent

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.

Vertrag und Quelle: [USP_WriteEvent.sql](../../Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql), [USP_WriteEvent.md](../../Modules/toolbelt.core.event-log/Documentation/USP_WriteEvent.md), [USP_WriteEvent.md](../../Metadata/UsageSkills/toolbelt_core/USP_WriteEvent.md).

<!-- Source/Vertrag SHA256: 2ac1b36c3f719a368eaa4816a162ecc314ee8ee7bc32f6298e95862cc6db3ac8 -->

Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux, passende CL150/160/170, lokal/zentral. EventLog und execution-context installiert. Konfigurierter aktivierter Loopback-Provider in second-session >=1.1.0 mit RPC OUT und Remote-Proc-Transaction-Promotion OFF. Aktiv registrierter JSON_PAYLOAD-Work-Type toolbelt.event-log.write mit kanonischem Handler USP_WriteEventInternal(@PayloadJson nvarchar(max),@Hilfe bit=0), ohne fachliches Resultset. Vorhandene lokale und Remote-Policy EXECUTE_NEW_SESSION plus Remote-Handler-EXECUTE. Runtime-Preflight prüft unter anderem OBJECT_ID und @SuppressResult-Parameter; er installiert/konfiguriert nichts.

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
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_WriteEvent @EventName='contoso.example',@EventLevel='INFO',@Message=N'Synthetic event',@DataJson=N'{"rows":1}';
-- Persistiert über den zuvor autorisierten/konfigurierten Provider.
EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
```

## toolbelt_core.USP_DeleteEventsBefore

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.

Vertrag und Quelle: [USP_DeleteEventsBefore.sql](../../Modules/toolbelt.core.event-log/Source/USP_DeleteEventsBefore.sql), [USP_DeleteEventsBefore.md](../../Modules/toolbelt.core.event-log/Documentation/USP_DeleteEventsBefore.md), [USP_DeleteEventsBefore.md](../../Metadata/UsageSkills/toolbelt_core/USP_DeleteEventsBefore.md).

<!-- Source/Vertrag SHA256: 210d4d95951d6d599f6a7fe72d2ec84ddae299aaac89d9b5b308e95a3ae28376 -->

Voraussetzung: Installiertes EventLog, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal oder zentral. Gültiger datetime2(7)-Cutoff als UTC-Konvention ohne automatische Zeitzonenkonvertierung. Kein Second-Session-Provider für Retention erforderlich. Fehlender Cutoff wird im Fachpfad abgewiesen. Committable Callertransaktion erlaubt, uncommittable nicht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeOccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich OccurredAtUtc &lt; Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/&gt;10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/&gt;100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2000-01-01T00:00:00',@BatchSize=100,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
SELECT @Deleted AS DeletedRows;
-- Nur im autorisierten synthetischen Scope; persistente Löschung.
EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
```

## toolbelt_core.USP_DeleteRecordedEventsBefore

Modul `toolbelt.core.event-log` · Version `1.0.0` · `USP`

Nur ausdrücklich aufgerufene Retention nach RecordedAtUtc mit Index (RecordedAtUtc,EventId), deterministischen begrenzten Batches und bestehender Caller-Transaktions-/Savepointsemantik. Kein Job, keine Deploymentlöschung. Die OccurredAtUtc-Retention bleibt unverändert. Erfordert vorhandenes EXECUTE; erteilt keine Berechtigungen. Fehler 51710–51714 wie im bestehenden Retentionvertrag.

Vertrag und Quelle: [USP_DeleteRecordedEventsBefore.sql](../../Modules/toolbelt.core.event-log/Source/USP_DeleteRecordedEventsBefore.sql), [USP_DeleteRecordedEventsBefore.md](../../Modules/toolbelt.core.event-log/Documentation/USP_DeleteRecordedEventsBefore.md), [USP_DeleteRecordedEventsBefore.md](../../Metadata/UsageSkills/toolbelt_core/USP_DeleteRecordedEventsBefore.md).

<!-- Source/Vertrag SHA256: 6b55f9e9becce765f3484018f5aa2c5db5e665ae8fca5383540c6694d677d6c1 -->

Voraussetzung: Installiertes EventLog, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal oder zentral. Gültiger datetime2(7)-Cutoff als UTC-Konvention ohne automatische Zeitzonenkonvertierung. Kein Second-Session-Provider für Retention erforderlich. Fehlender Cutoff wird im Fachpfad abgewiesen. Committable Callertransaktion erlaubt, uncommittable nicht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeRecordedAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich RecordedAtUtc &lt; Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/&gt;10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/&gt;100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2000-01-01T00:00:00',@BatchSize=100,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
SELECT @Deleted AS DeletedRows;
-- Nur im autorisierten synthetischen Scope; persistente Löschung.
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @Hilfe=1;
```

## toolbelt_core.TVF_ExecutionCancellationStatus

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `TVF`

Liest den registrierten kooperativen Abbruchstatus einer Ausführung.

Vertrag und Quelle: [TVF_ExecutionCancellationStatus.sql](../../Modules/toolbelt.core.execution-cancel/Source/TVF_ExecutionCancellationStatus.sql), [TVF_ExecutionCancellationStatus.md](../../Modules/toolbelt.core.execution-cancel/Documentation/TVF_ExecutionCancellationStatus.md), [TVF_ExecutionCancellationStatus.md](../../Metadata/UsageSkills/toolbelt_core/TVF_ExecutionCancellationStatus.md).

<!-- Source/Vertrag SHA256: faaa3af85c3072c9924a12c966e0ddd7232c7f8d42e203e2d7c181a894dc2700 -->

Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Explizites Argument ohne SQL-Default. NULL findet keine Anforderung und ergibt keine Zeilen. Auch Null-GUID ist kein Parameterfehler; sie findet regulär keinen über die öffentliche Request-USP angelegten Eintrag. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS IsRequested;
-- 0.
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
-- Keine Zeilen.
```

## toolbelt_core.SVF_IsCancellationRequested

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `SVF`

Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.

Vertrag und Quelle: [SVF_IsCancellationRequested.sql](../../Modules/toolbelt.core.execution-cancel/Source/SVF_IsCancellationRequested.sql), [SVF_IsCancellationRequested.md](../../Modules/toolbelt.core.execution-cancel/Documentation/SVF_IsCancellationRequested.md), [SVF_IsCancellationRequested.md](../../Metadata/UsageSkills/toolbelt_core/SVF_IsCancellationRequested.md).

<!-- Source/Vertrag SHA256: 0cd4ce9b75cf4bf4febb9146a3931f505236ced82766313950c82023bd5bf9c2 -->

Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Explizites Argument ohne SQL-Default. NULL findet keine Anforderung und ergibt 0. Auch Null-GUID ist kein Parameterfehler; sie findet regulär keinen über die öffentliche Request-USP angelegten Eintrag. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS IsRequested;
-- 0.
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
-- Keine Zeilen.
```

## toolbelt_core.USP_RequestExecutionCancellation

Modul `toolbelt.core.execution-cancel` · Version `1.0.0` · `USP`

Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.

Vertrag und Quelle: [USP_RequestExecutionCancellation.sql](../../Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql), [USP_RequestExecutionCancellation.md](../../Modules/toolbelt.core.execution-cancel/Documentation/USP_RequestExecutionCancellation.md), [USP_RequestExecutionCancellation.md](../../Metadata/UsageSkills/toolbelt_core/USP_RequestExecutionCancellation.md).

<!-- Source/Vertrag SHA256: fbfd2fa3e8eebd0321716301c8557fc9f1fd683757205d77b5fc5188caa57f69 -->

Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL. |
| `@CancellationReason` | `nvarchar(512)` | `NULL` | Input | Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Transaktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Id uniqueidentifier=NEWID();
EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id,@CancellationReason=N'Synthetic checkpoint';
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(@Id);
EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
-- Nur Testidentität in autorisiertem Scope; die Anforderung persistiert.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
```

## toolbelt_core.TVF_CurrentExecutionContext

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `TVF`

Liest den aktuellen Toolbelt-Ausführungskontext als relationale null- oder einzeilige Projektion; geeigneter Einstieg für APPLY und Diagnose.

Vertrag und Quelle: [TVF_CurrentExecutionContext.sql](../../Modules/toolbelt.core.execution-context/Source/TVF_CurrentExecutionContext.sql), [TVF_CurrentExecutionContext.md](../../Modules/toolbelt.core.execution-context/Documentation/TVF_CurrentExecutionContext.md), [TVF_CurrentExecutionContext.md](../../Metadata/UsageSkills/toolbelt_core/TVF_CurrentExecutionContext.md).

<!-- Source/Vertrag SHA256: 22c142e0dd1cfe0de939b76d5365cc81d3c300f3b085007d9fe28050f5a0d4ee -->

Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

Keine Eingabeparameter.

```sql
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
-- Ohne gültige aktive ExecutionId: keine Zeile.
```

## toolbelt_core.SVF_CurrentExecutionId

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `SVF`

Skalarer Komfortzugriff auf die ID des aktuellen Ausführungskontexts; relationaler Kern ist TVF_CurrentExecutionContext.

Vertrag und Quelle: [SVF_CurrentExecutionId.sql](../../Modules/toolbelt.core.execution-context/Source/SVF_CurrentExecutionId.sql), [SVF_CurrentExecutionId.md](../../Modules/toolbelt.core.execution-context/Documentation/SVF_CurrentExecutionId.md), [SVF_CurrentExecutionId.md](../../Metadata/UsageSkills/toolbelt_core/SVF_CurrentExecutionId.md).

<!-- Source/Vertrag SHA256: f82aebe529f8833cc5d569ded01f490808bb61106cffc8a617eeef07ec7fc65f -->

Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

Keine Eingabeparameter.

```sql
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ExecutionId;
```

## toolbelt_core.USP_BeginExecution

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `USP`

Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung.

Vertrag und Quelle: [USP_BeginExecution.sql](../../Modules/toolbelt.core.execution-context/Source/USP_BeginExecution.sql), [USP_BeginExecution.md](../../Modules/toolbelt.core.execution-context/Documentation/USP_BeginExecution.md), [USP_BeginExecution.md](../../Metadata/UsageSkills/toolbelt_core/USP_BeginExecution.md).

<!-- Source/Vertrag SHA256: 6b6eae795ebd367aae400897c619e01117df7372d6a842438753ae93b2d1d524 -->

Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | OUTPUT | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@AllowNested` | `bit` | `1` | Input | Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Eigene Sitzung ohne vorher aktiven Context verwenden.
DECLARE @Id uniqueidentifier;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Actor=N'Contoso example';
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Hilfe liest/schreibt keinen Context und erhält einen vorhandenen OUTPUT-Wert:
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_BeginExecution @Hilfe=1;
```

## toolbelt_core.USP_SetExecutionContext

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `USP`

Ändert CorrelationId, Actor oder Tenant eines aktiven Kontexts unter Prüfung der erwarteten ExecutionId.

Vertrag und Quelle: [USP_SetExecutionContext.sql](../../Modules/toolbelt.core.execution-context/Source/USP_SetExecutionContext.sql), [USP_SetExecutionContext.md](../../Modules/toolbelt.core.execution-context/Documentation/USP_SetExecutionContext.md), [USP_SetExecutionContext.md](../../Metadata/UsageSkills/toolbelt_core/USP_SetExecutionContext.md).

<!-- Source/Vertrag SHA256: c0407fef5c2621750a54bea7e7ee3a32cba0eb1ae0cbe7a0f29bd81c17d59b8a -->

Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL (Default) erhält die bisherige CorrelationId; eine explizite ID ersetzt sie. Es gibt hier kein Correlation-Clear-Flag. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearActor=1 verwenden; Actor muss dann NULL sein. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearTenant=1 verwenden; Tenant muss dann NULL sein. |
| `@ClearActor` | `bit` | `0` | Input | Taxativ für bit: 0 erhält den Actor bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Actor aus dem Sessionkontext. Bei 1 darf Actor auch nicht als Leertext übergeben werden, sondern muss NULL sein. |
| `@ClearTenant` | `bit` | `0` | Input | Taxativ für bit: 0 erhält den Tenant bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Tenant. Bei 1 muss Tenant NULL sein, auch Leertext ist ein Konflikt. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
-- Nur mit eigenem bereits begonnenem Context ausführen:
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id,@Actor=N'Contoso step';
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id,@ClearActor=1;
-- Pflichtargument bleibt auch für Hilfe syntaktisch erforderlich:
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=NULL,@Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=NULL, @Hilfe=1;
```

## toolbelt_core.USP_EndExecution

Modul `toolbelt.core.execution-context` · Version `1.0.0` · `USP`

Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId.

Vertrag und Quelle: [USP_EndExecution.sql](../../Modules/toolbelt.core.execution-context/Source/USP_EndExecution.sql), [USP_EndExecution.md](../../Modules/toolbelt.core.execution-context/Documentation/USP_EndExecution.md), [USP_EndExecution.md](../../Metadata/UsageSkills/toolbelt_core/USP_EndExecution.md).

<!-- Source/Vertrag SHA256: 14987642660071ea79c11cd95768d57f7b8373680f9a81f95cec1f5222ba3ac7 -->

Voraussetzung: Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
-- Nur den eigenen zuvor begonnenen Scope beenden:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Help benötigt das Pflichtargument, aber keinen aktiven Context:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL,@Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL, @Hilfe=1;
```

## toolbelt_core.TVF_GenerateSeriesBigInt

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert.

Vertrag und Quelle: [TVF_GenerateSeriesBigInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql), [TVF_GenerateSeriesBigInt.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigInt.md), [TVF_GenerateSeriesBigInt.md](../../Metadata/UsageSkills/toolbelt_core/TVF_GenerateSeriesBigInt.md).

<!-- Source/Vertrag SHA256: 8ddfbde6f22cd19e9ff4b5955085e9a5a40dcc2171f89dac65d7413adc725cbf -->

Voraussetzung: SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
| `@Step` | `bigint` | `NULL` | Input | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler. Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt(2,10,3) ORDER BY Value;
-- 2, 5, 8; kein künstlicher Endwert 10.
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesBigInt(10,1,-4) ORDER BY Value DESC;
-- 10, 6, 2.
```

## toolbelt_core.TVF_GenerateSeriesInt

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Erzeugt eine Folge von int-Werten einschließlich erreichbarem Endwert.

Vertrag und Quelle: [TVF_GenerateSeriesInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql), [TVF_GenerateSeriesInt.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesInt.md), [TVF_GenerateSeriesInt.md](../../Metadata/UsageSkills/toolbelt_core/TVF_GenerateSeriesInt.md).

<!-- Source/Vertrag SHA256: 4e8e0747e462e02ff1c611e6420bef50d36ffd5fc98ae2fc6a06afdbfc2bdb81 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `int` | `kein Default` | Input | Erster Wert im gesamten SQL-int-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
| `@Stop` | `int` | `kein Default` | Input | Inklusive Zielgrenze im SQL-int-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
| `@Step` | `int` | `NULL` | Input | Ganzzahlige Schrittweite als int. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler. Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(2,10,3) ORDER BY Value;
-- 2, 5, 8; kein künstlicher Endwert 10.
SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(10,1,-4) ORDER BY Value DESC;
-- 10, 6, 2.
```

## toolbelt_core.TVF_GenerateSeriesBigIntStatus

Modul `toolbelt.core.generate-series` · Version `1.0.0` · `TVF`

Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen.

Vertrag und Quelle: [TVF_GenerateSeriesBigInt.sql](../../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql), [TVF_GenerateSeriesBigIntStatus.md](../../Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigIntStatus.md), [TVF_GenerateSeriesBigIntStatus.md](../../Metadata/UsageSkills/toolbelt_core/TVF_GenerateSeriesBigIntStatus.md).

<!-- Source/Vertrag SHA256: a961188bdc65266e12729b03a057b31ae68ca9196579895df6b8f3b5ada61d02 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL. |
| `@Step` | `bigint` | `NULL` | Input | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Status,RequestedRows
FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,2) ORDER BY Value;
-- (1,OK,3), (3,OK,3), (5,OK,3).
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,1000001,1);
-- Eine Zeile: Value=NULL, Status=LIMIT, RequestedRows=1000001.
```

## toolbelt_core.USP_PrepareResultTable

Modul `toolbelt.core.result-table` · Version `1.0.0` · `USP`

Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein.

Vertrag und Quelle: [USP_PrepareResultTable.sql](../../Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql), [USP_PrepareResultTable.md](../../Modules/toolbelt.core.result-table/Documentation/USP_PrepareResultTable.md), [USP_PrepareResultTable.md](../../Metadata/UsageSkills/toolbelt_core/USP_PrepareResultTable.md).

<!-- Source/Vertrag SHA256: 096f48198210e6ebcde5991a9787a42a9b6d510b95ef8350cc8bed805ea3ace9 -->

Voraussetzung: Ziel-#Temp und Referenztabelle müssen im unterstützten Session-/Namensscope existieren. Kein frei geliefertes DDL, keine globale oder permanente Zieltabelle. Der Help-Pfad benötigt keine Ziel-/Referenztabelle.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ResultTableToAlter` | `sysname` | `NULL` | Input | Fachlich erforderliche, bereits existierende caller-lokale #Temp im selben sichtbaren Session-Scope; logischer Name 2..116 UTF-16-Einheiten, genau ein führendes # und kein reserviertes #tbx_-Präfix. Ein einzelner Identifier, kein DDL und keine Tabellenvariable/permanente/globale Tabelle. NULL ist nur technischer Help-Default. Darf nicht dieselbe Tabelle wie LikeTable sein. |
| `@LikeTable` | `nvarchar(776)` | `NULL` | Input | Fachlich erforderliche vorhandene Referenztabelle als #LocalTemplate, Schema.Table oder Database.Schema.Table, optional regulär quotierte Namensbestandteile. Keine einteilige permanente Tabelle, Server-/vierteilige Namen, Views, Synonyme oder ##Temps. NULL/leer ungültig. Referenzspalten müssen dem unterstützten einfügbaren Typ-/Metadatenvertrag in RESULT_TABLE_MODULE_DESIGN.md entsprechen; der Helper übernimmt Spaltenshape und keine fachlichen Zeilen. |
| `@KeepData` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 ersetzt/leert vorhandene Zielinhalte und baut nötigenfalls das Schema um (Default); 1 erhält vorhandene Zeilen und lehnt einen nötigen Schemaumbau bei nicht leerem Ziel mit 51025 ab. Ein leeres Ziel darf auch bei 1 angepasst werden. NULL wirkt wie 0. Keine Append-Operation des Helpers selbst; fachliche Zeilen fügt der Caller danach ein. |
| `@Debug` | `tinyint` | `0` | Input | Ganzzahl tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine Debugmessages, 1 Preflight/Ablauf, 2 zusätzlich zusammengefasste Metadaten/Schemaentscheidung, 3..255 zusätzlich normalisierte Referenzmetadaten und geplantes DDL. Die Schwellwerte gelten kumulativ; 255 besitzt im aktuellen Code keine weitere eigene Stufe. Nur Messages, kein Zusatzresultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert die Standardhilfe und danach genau ein Skill-Resultset vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
CREATE TABLE #Shape (ItemId int NOT NULL);
CREATE TABLE #Result (Dummy int NULL);
EXEC toolbelt_core.USP_PrepareResultTable
 @ResultTableToAlter=N'#Result', @LikeTable=N'#Shape', @KeepData=0;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;
```

## toolbelt_core.VW_SecondSessionProviders

Modul `toolbelt.core.second-session` · Version `1.1.0` · `VIEW`

Katalogsicht auf gespeicherten Second-Session-Provider und sichtbare Linked-Server-Flags.

Vertrag und Quelle: [VW_SecondSessionProviders.sql](../../Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql), [VW_SecondSessionProviders.md](../../Modules/toolbelt.core.second-session/Documentation/VW_SecondSessionProviders.md), [VW_SecondSessionProviders.md](../../Metadata/UsageSkills/toolbelt_core/VW_SecondSessionProviders.md).

<!-- Source/Vertrag SHA256: 66837cee405fd818a2454733634fa28b99e6aea65b494d2c393fb498e4486ac0 -->

Voraussetzung: Installiertes Modul mit dieser Tabelle, SQL2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Die Sicht benötigt zusätzlich bestehende Sichtbarkeit in master.sys.servers. Die DDL selbst prüft keine funktionierende Remoteverbindung, Treiberverfügbarkeit oder Datenbank-/Serveridentität.

Keine Eingabeparameter.

```sql
SELECT ProviderName,IsEnabled,LinkedServerExists,RpcOutEnabled,RemoteProcTransactionPromotionEnabled
FROM toolbelt_core.VW_SecondSessionProviders;
-- Keine Zeile: kein gespeicherter Provider.
-- Flags sind sichtbare Katalogzustände, kein Connectivity-/TLS-Test.
```

## toolbelt_core.USP_ConfigureSecondSessionLoopback

Modul `toolbelt.core.second-session` · Version `1.1.0` · `USP`

Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.

Vertrag und Quelle: [USP_ConfigureSecondSessionLoopback.sql](../../Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql), [USP_ConfigureSecondSessionLoopback.md](../../Modules/toolbelt.core.second-session/Documentation/USP_ConfigureSecondSessionLoopback.md), [USP_ConfigureSecondSessionLoopback.md](../../Metadata/UsageSkills/toolbelt_core/USP_ConfigureSecondSessionLoopback.md).

<!-- Source/Vertrag SHA256: 247bbca45836522d35ada2f7d4b19bc71e6b21ef7f46212eb77534083965e86a -->

Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Vorhandener sichtbarer is_linked=1-Eintrag in master.sys.servers, RPC OUT=1, Remote-Proc-Transaction-Promotion=0. Remote-Ziel muss unter DB_NAME() den kanonischen USP_SecondSessionProbe mit passenden Rechten erreichen. Probe gilt auch für Enabled=0 und vor der Providerzeilenänderung. Name und SQL-Typ sind kein Connection String; QUOTENAME schützt die dynamischen Objektidentifier. Datenbankname/SPID der Probe sind Rückgabedaten, kein kryptografischer Nachweis derselben physischen SQLinstanz; das tatsächliche Loopbackziel ist administrativ festzulegen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an. |
| `@Enabled` | `bit` | `1` | Input | Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Vorhandener administrativ korrekter synthetischer Loopback vorausgesetzt.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'ContosoLoopback',@Enabled=1;
-- Führt Probe-RPC aus und kann Konfigurationsdaten ändern.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
```

## toolbelt_core.USP_ExecuteWorkTypeInNewSession

Modul `toolbelt.core.second-session` · Version `1.1.0` · `USP`

Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.

Vertrag und Quelle: [USP_ExecuteWorkTypeInNewSession.sql](../../Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql), [USP_ExecuteWorkTypeInNewSession.md](../../Modules/toolbelt.core.second-session/Documentation/USP_ExecuteWorkTypeInNewSession.md), [USP_ExecuteWorkTypeInNewSession.md](../../Metadata/UsageSkills/toolbelt_core/USP_ExecuteWorkTypeInNewSession.md).

<!-- Source/Vertrag SHA256: a9b48c4bd91b325a4b294154ce95861fb8dfd73f860046079cefdfecfe74b834 -->

Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Aktiver registrierter lokaler WorkType mit NONE oder JSON_PAYLOAD, sichtbare gültige lokale App-Policy EXECUTE_NEW_SESSION. Aktivierter gespeicherter loopback-Provider mit sichtbarem LinkedServerExists=1,RpcOutEnabled=1,Promotion=0; gültige Remote-Anmeldung und installierter Dispatcher in derselben benannten Toolbelt-DB. Remote ebenfalls aktive Registrierung/Policy/Handler-EXECUTE/korrekte Signatur. Keine automatische Provideranlage oder Umstellung nach Verbindungsfehler.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@SuppressResult` | `bit` | `0` | Input | 0 oder NULL: Infrastrukturresultat direkt oder nach ResultTable; 1: diese Ausgabe nach erfolgreichem Dispatcher-Return unterdrücken. Nicht mit ResultTable kombinierbar. Das prüft NICHT automatisch HandlerReturnCode=0; ein nichtzero Handlercode kann dadurch ohne Ausgabe bleiben. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Registrierter, erlaubter synthetischer NONE-Handler vorausgesetzt.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='contoso.noop';
-- Infrastrukturzeile einschließlich HandlerReturnCode bewusst auswerten.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
```

## toolbelt_core.VW_WorkQueue

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `VIEW`

Öffentliche Queue-Statusprojektion ohne PayloadJson, ClaimToken und Managedtoken.

Vertrag und Quelle: [VW_WorkQueue.sql](../../Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql), [VW_WorkQueue.md](../../Modules/toolbelt.core.work-queue/Documentation/VW_WorkQueue.md), [VW_WorkQueue.md](../../Metadata/UsageSkills/toolbelt_core/VW_WorkQueue.md).

<!-- Source/Vertrag SHA256: 48414a7f7d07bd4876a4bb1714f2797bc1780de10ee5f885ff51c39969cf4707 -->

Voraussetzung: SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.

Keine Eingabeparameter.

```sql
SELECT WorkItemId,WorkTypeName,Status,IsLeaseExpired
FROM toolbelt_core.VW_WorkQueue ORDER BY WorkItemId;
```

## toolbelt_core.VW_WorkQueueBarrierBlockers

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `VIEW`

Öffentliche Barrier-Snapshotprojektion mit aktuellem Claimgenerationsvergleich.

Vertrag und Quelle: [VW_WorkQueueBarrierBlockers.sql](../../Modules/toolbelt.core.work-queue/Source/VW_WorkQueueBarrierBlockers.sql), [VW_WorkQueueBarrierBlockers.md](../../Modules/toolbelt.core.work-queue/Documentation/VW_WorkQueueBarrierBlockers.md), [VW_WorkQueueBarrierBlockers.md](../../Metadata/UsageSkills/toolbelt_core/VW_WorkQueueBarrierBlockers.md).

<!-- Source/Vertrag SHA256: 6e7fb7f3669c434c06c16e2ffe8674493716997619a73deb8b1a2f017471a9bf -->

Voraussetzung: SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.

Keine Eingabeparameter.

```sql
SELECT BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration,IsResolved
FROM toolbelt_core.VW_WorkQueueBarrierBlockers
ORDER BY BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId;
```

## toolbelt_core.USP_EnqueueWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

Vertrag und Quelle: [USP_EnqueueWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql), [USP_EnqueueWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueWork.md), [USP_EnqueueWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_EnqueueWork.md).

<!-- Source/Vertrag SHA256: 321e7b70e8e876e9c18d69479c22355e980f530396a2199fbcce04bfdd7ca355 -->

Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser einfache Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;

-- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='contoso.noop';
-- Erneuter Aufruf erzeugt ein weiteres Item, keine Idempotency-Replaygarantie.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;
```

## toolbelt_core.USP_EnqueueWorkWithPolicy

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.

Vertrag und Quelle: [USP_EnqueueWorkWithPolicy.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql), [USP_EnqueueWorkWithPolicy.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueWorkWithPolicy.md), [USP_EnqueueWorkWithPolicy.md](../../Metadata/UsageSkills/toolbelt_core/USP_EnqueueWorkWithPolicy.md).

<!-- Source/Vertrag SHA256: d1539aedb77699a00608671f265ee45a93fe02d3a4971c12fadaaa11e6413ae0 -->

Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. DRAIN_BARRIER verlangt@@TRANCOUNT0; SHARED unterstützt gesunden Caller-TX/Savepoint. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. SQL-BIN2 ohne zusätzlichen Längenvergleich ist keine Byteidentitätsgarantie; SQL-Spacepadding beachten. |
| `@Priority` | `tinyint` | `0` | Input | Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@ExecutionGroup` | `varchar(128)` | `'default'` | Input | Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss &lt;= RetryMaxDelaySeconds sein. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@ExecutionMode` | `varchar(16)` | `'SHARED'` | Input | Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;

-- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='contoso.noop',@IdempotencyKey='contoso.request.1',
 @ExecutionGroup='contoso.group',@Priority=10,@ExecutionMode='SHARED',
 @MaxAttempts=3,@RetryBaseDelaySeconds=60,@RetryMaxDelaySeconds=3600;
-- Gleicher Key wird nur mit tatsächlich gleicher Policy wiederverwendet.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;
```

## toolbelt_core.USP_EnqueueBarrierWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Reiht DRAIN_BARRIER-Arbeit ein, die vor ihrem exklusiven Claim die relevanten aktiven Claims derselben ExecutionGroup abwartet; Retry-Policy und optionaler Idempotency Key bleiben gebunden.

Vertrag und Quelle: [USP_EnqueueBarrierWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_EnqueueBarrierWork.sql), [USP_EnqueueBarrierWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueBarrierWork.md), [USP_EnqueueBarrierWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_EnqueueBarrierWork.md).

<!-- Source/Vertrag SHA256: 83a2d7c7c45e08c266c678597dfb7ada1a0bf6dab87a2a1d0b0f8923c8ddc26c -->

Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. DRAIN_BARRIER verlangt@@TRANCOUNT0; SHARED unterstützt gesunden Caller-TX/Savepoint. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@ExecutionGroup` | `varchar(128)` | `NULL` | Input | Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Fachlich erforderlich; technischer Default NULL dient nur dem Hilfemodus. |
| `@Priority` | `tinyint` | `NULL` | Input | Fachlich erforderliche Ganzzahl 0..255 als tinyint. Technischer Default NULL dient nur Hilfe; bei NULL im Fachaufruf Fehler 51975. Der Wrapper setzt den Modus fest auf DRAIN_BARRIER; Callertransaktionen sind ausgeschlossen. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. SQL-BIN2 ohne zusätzlichen Längenvergleich ist keine Byteidentitätsgarantie; SQL-Spacepadding beachten. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss &lt;= RetryMaxDelaySeconds sein. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_EnqueueBarrierWork @Hilfe=1;

-- Ohne Caller-TX; registrierter autorisierter NONE-Handler erforderlich.
EXEC toolbelt_core.USP_EnqueueBarrierWork
 @WorkTypeName='contoso.noop',@ExecutionGroup='contoso.group',@Priority=10;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnqueueBarrierWork @Hilfe=1;
```

## toolbelt_core.USP_ClaimWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Öffentlicher Einstieg.

Vertrag und Quelle: [USP_ClaimWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_ClaimWork.sql), [USP_ClaimWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_ClaimWork.md), [USP_ClaimWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_ClaimWork.md).

<!-- Source/Vertrag SHA256: f497a2f8880ec9f0a63c77225d2df5248af859a9dfb7fce4cd8b6ca6c0806eca -->

Voraussetzung: Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Keine Callertransaktion im öffentlichen Claimpfad. Private Managed-Admission verlangt genau eine gesunde bestehende Transaktion und passende Gatebindung. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;

EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
-- Null oder eine vertrauliche tatsächliche Claimzeile sicher übernehmen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;
```

## toolbelt_core.USP_RenewWorkLease

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.

Vertrag und Quelle: [USP_RenewWorkLease.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RenewWorkLease.sql), [USP_RenewWorkLease.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_RenewWorkLease.md), [USP_RenewWorkLease.md](../../Metadata/UsageSkills/toolbelt_core/USP_RenewWorkLease.md).

<!-- Source/Vertrag SHA256: c858e06f313b6a903dfff00bb29718515c80e62b19d3f4af9c27d7f2c9c0f671 -->

Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Nur eigene aktuelle Claim-ID/Token verwenden; die Lease muss noch aktiv sein. Clientzeiten verlängern keine Enginelease. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;

-- Eigene aktive Claim-ID/Token einsetzen, keine fremden Bindings.
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken=@Token;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;
```

## toolbelt_core.USP_RecoverExpiredWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.

Vertrag und Quelle: [USP_RecoverExpiredWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RecoverExpiredWork.sql), [USP_RecoverExpiredWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_RecoverExpiredWork.md), [USP_RecoverExpiredWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_RecoverExpiredWork.md).

<!-- Source/Vertrag SHA256: ed8f1d3c11e2c3ba6aac835e9719edbe7e829d4dd32e958241dd0d0def7b68c0 -->

Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Expliziter Supervisorbatch; keine Übernahme von Managed-/Holditems. MaxItems 1..1000 begrenzt die Zahl ausgewählter Items. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MaxItems` | `int` | `100` | Input | Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/&gt;1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;

-- Autorisierter Supervisor, ohne Caller-TX:
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;
```

## toolbelt_core.USP_CompleteWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert.

Vertrag und Quelle: [USP_CompleteWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_CompleteWork.sql), [USP_CompleteWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_CompleteWork.md), [USP_CompleteWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_CompleteWork.md).

<!-- Source/Vertrag SHA256: 1fbe02e112e77635a08c66a748a1c4411f44749fd017a84895ec119a45064d9c -->

Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Ein gesunder Caller-TX ist zulässig. ManagedCompletion verlangt den geschützten äußeren TX, Nonce und AppLock. Ein einfacher aktiver Claim darf einen eigenen TX verwenden. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;

-- Eigene aktive Claim-ID/Token einsetzen, keine fremden Bindings.
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1,@ClaimToken=@Token;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;
```

## toolbelt_core.USP_FailWork

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Tokengebundener endgültiger FAILED-Abschluss eines aktiven Queueclaims. Öffentlicher Einstieg.

Vertrag und Quelle: [USP_FailWork.sql](../../Modules/toolbelt.core.work-queue/Source/USP_FailWork.sql), [USP_FailWork.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_FailWork.md), [USP_FailWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_FailWork.md).

<!-- Source/Vertrag SHA256: 56f1c26961f2a4cd914aa45257ee6f5f3ba87d7474776115b463151fcc7cc147 -->

Voraussetzung: Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(max)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_FailWork @Hilfe=1;

-- Tatsächliche eigene Claim-ID/Token ersetzen diese synthetischen Werte:
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_FailWork @WorkItemId=1,@ClaimToken=@Token,@FailureCode='CONTOSO.TRANSIENT';
-- Kein freier Replaypfad; falsche/nicht vorhandene Bindung ist kein erfolgreicher Übergang.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_FailWork @Hilfe=1;
```

## toolbelt_core.USP_ScheduleWorkRetry

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Öffentlicher Einstieg.

Vertrag und Quelle: [USP_ScheduleWorkRetry.sql](../../Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetry.sql), [USP_ScheduleWorkRetry.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_ScheduleWorkRetry.md), [USP_ScheduleWorkRetry.md](../../Metadata/UsageSkills/toolbelt_core/USP_ScheduleWorkRetry.md).

<!-- Source/Vertrag SHA256: ef989ef181dfafd92011a1aa0bb92b0de76d3058dc5607e30eba87405aa3d2fb -->

Voraussetzung: Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden. |
| `@ResultTable` | `sysname` | `NULL` | Input | Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben. |
| `@KeepData` | `bit` | `0` | Input | bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;

-- Tatsächliche eigene Claim-ID/Token ersetzen diese synthetischen Werte:
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=1,@ClaimToken=@Token,@FailureCode='CONTOSO.TRANSIENT';
-- Kein freier Replaypfad; falsche/nicht vorhandene Bindung ist kein erfolgreicher Übergang.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;
```

## toolbelt_core.USP_RequeueDeadLetter

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.

Vertrag und Quelle: [USP_RequeueDeadLetter.sql](../../Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql), [USP_RequeueDeadLetter.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_RequeueDeadLetter.md), [USP_RequeueDeadLetter.md](../../Metadata/UsageSkills/toolbelt_core/USP_RequeueDeadLetter.md).

<!-- Source/Vertrag SHA256: bcb2059c4b5e703416fe88ede7101bf8b2e929aae09cb3d1ec9e1460df1293df -->

Voraussetzung: Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Aktuell DEAD_LETTER, nicht gehalten und nicht Managed. Aktuelle RowVersion für optionales CAS; NULL deaktiviert CAS. Keine freie Freigabe unbekannter Ownership. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;

-- Synthetische ID/RowVersion durch das eigene tatsächliche DEAD_LETTER-Item ersetzen.
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=1,
 @ExpectedRowVersion=0x0000000000000001,@RequeueReason=N'Contoso: Ursache behoben';
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;
```

## toolbelt_core.USP_GetWorkStatus

Modul `toolbelt.core.work-queue` · Version `2.1.0` · `USP`

Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt.

Vertrag und Quelle: [USP_GetWorkStatus.sql](../../Modules/toolbelt.core.work-queue/Source/USP_GetWorkStatus.sql), [USP_GetWorkStatus.md](../../Modules/toolbelt.core.work-queue/Documentation/USP_GetWorkStatus.md), [USP_GetWorkStatus.md](../../Metadata/UsageSkills/toolbelt_core/USP_GetWorkStatus.md).

<!-- Source/Vertrag SHA256: 0e608b4ca778fda88b32e1870fbd05b950c43239d2487fac5b01519bb411e319 -->

Voraussetzung: Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächliches existierendes Item; kein aktiver/registrierter Handler für reine Statuslesung erforderlich. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. Liest Status; Payload und ClaimToken sind absichtlich nicht Teil dieser Oberfläche. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;

-- Synthetische ID durch die eigene tatsächliche Enqueue-/Claim-ID ersetzen.
EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=1;
-- Statuslesung liefert weder Payload noch ClaimToken.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;
```

## toolbelt_core.USP_SetWorkTypePermission

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal.

Vertrag und Quelle: [USP_SetWorkTypePermission.sql](../../Modules/toolbelt.core.work-type/Source/USP_SetWorkTypePermission.sql), [USP_SetWorkTypePermission.md](../../Modules/toolbelt.core.work-type/Documentation/USP_SetWorkTypePermission.md), [USP_SetWorkTypePermission.md](../../Metadata/UsageSkills/toolbelt_core/USP_SetWorkTypePermission.md).

<!-- Source/Vertrag SHA256: e96cc15a8b76ee6fd5f27aee124dd9f602992f986e9046d6e15c52941fd81da6 -->

Voraussetzung: SQL Server 2019/2022/2025 auf Windows/Linux, passende CL150/160/170, lokal/zentral. WorkType-Katalog und Policyobjekte in derselben Datenbank; zentrale Verwendung wertet den tatsächlichen DBtoken dieses Katalogs aus. Kein Second-Session- oder Queue-Provider für diese lokale Policyverwaltung/-entscheidung erforderlich. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen. Principal muss im lokalen sys.database_principals sichtbar sein, type in S/U/G/R/E/X und principal_id ungleich 0; keine Erstellung fehlender Identitäten. Work Type muss registriert sein, nicht zwingend enabled. Auch REMOVE setzt vorhandenen Principal und Work Type voraus und ist kein allgemeiner Bereiniger verwaister Zeilen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@Principal` | `sysname` | `NULL` | Input | Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig. |
| `@PermissionName` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig. |
| `@PermissionState` | `varchar(8)` | `'ALLOW'` | Input | Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Parametervalidierung/CONTROL-/Katalogprüfung oder Policyänderung. 0 oder NULL führt den Fachpfad aus. Alle Argumente besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Bestehender synthetischer Work Type und DBprincipal sind Voraussetzung.
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='contoso.noop',@Principal=N'ContosoProducer',@PermissionName='ENQUEUE',@PermissionState='ALLOW';
-- Persistente App-Delegation, nur im autorisierten Verwaltungsscope.
EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
```

## toolbelt_core.VW_WorkTypes

Modul `toolbelt.core.work-type` · Version `1.2.0` · `VIEW`

Liest den Work-Type-Katalog einschließlich Handlername und sichtbarer Handlerexistenz.

Vertrag und Quelle: [VW_WorkTypes.sql](../../Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql), [VW_WorkTypes.md](../../Modules/toolbelt.core.work-type/Documentation/VW_WorkTypes.md), [VW_WorkTypes.md](../../Metadata/UsageSkills/toolbelt_core/VW_WorkTypes.md).

<!-- Source/Vertrag SHA256: 0ee1aba4c3bc2f4fb00ac2e5fa81456842dbcee87a7cdaf5aa80784d77ef7a5c -->

Voraussetzung: Work-Type-Modul in der gewählten Moduldatenbank installiert und lesbar. Bei zentraler Installation gegebenenfalls dreiteiligen Namen verwenden. Kein Aufrufparameter.

Keine Eingabeparameter.

```sql
SELECT WorkTypeName,HandlerQualifiedName,ParameterMode,IsEnabled,HandlerExists
FROM toolbelt_core.VW_WorkTypes
ORDER BY WorkTypeName;
```

## toolbelt_core.USP_RegisterWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.

Vertrag und Quelle: [USP_RegisterWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_RegisterWorkType.sql), [USP_RegisterWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_RegisterWorkType.md), [USP_RegisterWorkType.md](../../Metadata/UsageSkills/toolbelt_core/USP_RegisterWorkType.md).

<!-- Source/Vertrag SHA256: 04c817055d03a0f57003324fef68917b2c65d20d73ba1f0602c1562f45c7532c -->

Voraussetzung: SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. WorkType und VW_WorkTypes in derselben Datenbank, sichtbare vorhandene Handlerprozedur P/PC in dieser Datenbank, nicht sys oder is_ms_shipped. Vorhandenes Handler-EXECUTE des registrierenden Principals erforderlich. Für Routing zusätzlich existierender sameDB ResultTable-Helper und gültige lokale Caller-Temp. ParameterMode ist eine Deklaration: diese Prozedur prüft NICHT die passende Handler-Parametersignatur; der spätere Dispatcher prüft diese separat. NONE ohne Payloadvertrag; JSON_PAYLOAD verlangt ein JSON-Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces, kein ausführbares JSON-Schema.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile vor Fach-/Handler-/Katalogprüfung oder Änderungen. Danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Vorhandener synthetischer Handler dbo.ContosoNoop ohne Parameter vorausgesetzt.
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='contoso.noop',@HandlerSchema=N'dbo',@HandlerProcedure=N'ContosoNoop',@ParameterMode='NONE';
-- Ändert den Katalog im autorisierten Verwaltungsscope; kein Handleraufruf.
EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
```

## toolbelt_core.USP_DisableWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.

Vertrag und Quelle: [USP_DisableWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_DisableWorkType.sql), [USP_DisableWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_DisableWorkType.md), [USP_DisableWorkType.md](../../Metadata/UsageSkills/toolbelt_core/USP_DisableWorkType.md).

<!-- Source/Vertrag SHA256: 6c3452913b5fa94cbfb5b978cf02265ed693a896105af09a424d16d858b281d2 -->

Voraussetzung: WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. ExpectedRowVersion NULL deaktiviert nur den optimistischen Versionsvergleich; sonst exakte binary(8)-Bytes aus zuletzt gelesenem Katalog verwenden, keinen Hextext. Already-disabled mit NULL-Grund ist ein No-op, die optionale RowVersion-Prüfung gilt trotzdem. Jede tatsächliche Änderung erzeugt neue RowVersion und macht ältere gebundene WorkType-Policies unwirksam, bis sie ausdrücklich neu konfiguriert werden.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@DisabledReason` | `nvarchar(1000)` | `NULL` | Input | Optionales nvarchar(1000), NULL/leer erlaubt, keine Redigierung. Bei erster Deaktivierung einschließlich NULL gespeichert. Ist der Eintrag bereits deaktiviert, bewahrt NULL den Grund; nicht-NULL ändert nur bei ungleichem ISNULL(...,N'')-SQL-Textvergleich. Datenbankcollation und SQL-Padding können Groß-/Kleinschreibung oder trailing Spaces als gleich behandeln. Keine garantierte bytegenaue Textersetzung. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='contoso.noop',@DisabledReason=N'Synthetic maintenance';
-- Persistente Änderung, bestehender synthetischer Eintrag erforderlich.
EXEC toolbelt_core.USP_DisableWorkType @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DisableWorkType @Hilfe=1;
```

## toolbelt_core.USP_RemoveWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.

Vertrag und Quelle: [USP_RemoveWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_RemoveWorkType.sql), [USP_RemoveWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_RemoveWorkType.md), [USP_RemoveWorkType.md](../../Metadata/UsageSkills/toolbelt_core/USP_RemoveWorkType.md).

<!-- Source/Vertrag SHA256: a5029fdc55c7d9dfdf9e9e0356db825ad3cfd2772a39529f96e4423ca768af44 -->

Voraussetzung: WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. ExpectedRowVersion NULL deaktiviert nur den optimistischen Versionsvergleich; sonst exakte binary(8)-Bytes aus zuletzt gelesenem Katalog verwenden, keinen Hextext. Aktive Einträge können nicht entfernt werden. Bestehende Referenzen können den DELETE durch Engine-/FK-Fehler verhindern; kein automatisches Entfernen von Workitems oder anderen Verbrauchern.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss bereits deaktiviert sein; aktive Einträge sind nicht entfernbar. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
| `@AllowDelete` | `bit` | `0` | Input | Taxativ für bit: 1 ist die ausdrückliche Zustimmung zum irreversiblen Entfernen; 0 (Default) und NULL werden vor der Entfernung abgewiesen. Der Work Type muss zusätzlich deaktiviert sein. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='contoso.noop',@AllowDelete=1;
-- Nur bereits deaktivierter synthetischer Eintrag im autorisierten Scope.
EXEC toolbelt_core.USP_RemoveWorkType @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RemoveWorkType @Hilfe=1;
```

## toolbelt_core.USP_ResolveWorkType

Modul `toolbelt.core.work-type` · Version `1.2.0` · `USP`

Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.

Vertrag und Quelle: [USP_ResolveWorkType.sql](../../Modules/toolbelt.core.work-type/Source/USP_ResolveWorkType.sql), [USP_ResolveWorkType.md](../../Modules/toolbelt.core.work-type/Documentation/USP_ResolveWorkType.md), [USP_ResolveWorkType.md](../../Metadata/UsageSkills/toolbelt_core/USP_ResolveWorkType.md).

<!-- Source/Vertrag SHA256: abe86226f3f781ddc178017756c4e6a44aee62bdb9b456afbcb1ba26a2ad4e37 -->

Voraussetzung: WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. RequireEnabled und RequireExecutableByCaller NULL=>1; RequiredPermission NULL bedeutet keine App-Policyprüfung. SuppressResult muss 0/1 sein, NULL oder 1 mit ResultTable wird abgewiesen. Ein deaktivierter Eintrag ist mit RequireEnabled=0 möglich; der Handler muss dennoch sichtbar existieren. RequireExecutableByCaller=0 überspringt nur dessen EXECUTE-Check, verleiht kein Recht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@RequireEnabled` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren. |
| `@RequireExecutableByCaller` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung. |
| `@RequiredPermission` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY. |
| `@SuppressResult` | `bit` | `0` | Input | Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597). |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='contoso.noop',@RequiredPermission='EXECUTE_NEW_SESSION',@SuppressResult=1;
-- Nur Preflight; registrierter Handler, bestehende Rechte und Policy nötig.
EXEC toolbelt_core.USP_ResolveWorkType @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ResolveWorkType @Hilfe=1;
```

## toolbelt_core.VW_WorkerStatus

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `VIEW`

Öffentliche tokenfreie Statusprojektion aller registrierten Worker-generationen.

Vertrag und Quelle: [VW_WorkerStatus.sql](../../Modules/toolbelt.core.worker-control/Source/VW_WorkerStatus.sql), [VW_WorkerStatus.md](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerStatus.md), [VW_WorkerStatus.md](../../Metadata/UsageSkills/toolbelt_core/VW_WorkerStatus.md).

<!-- Source/Vertrag SHA256: 5ad504a1cf5fac4e53188f7c93dbb940b70298c3a3566b09e59e08aa45950dae -->

Voraussetzung: Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.

Keine Eingabeparameter.

```sql
SELECT WorkerId,WorkerGeneration,State,Capacity,OccupiedSlots,ConfigVersion
FROM toolbelt_core.VW_WorkerStatus ORDER BY WorkerId,WorkerGeneration;
```

## toolbelt_core.VW_WorkerExecutionStatus

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `VIEW`

Öffentliche tokenfreie Reservationshistorie mit exakt passender aktueller Hold-Disposition.

Vertrag und Quelle: [VW_WorkerExecutionStatus.sql](../../Modules/toolbelt.core.worker-control/Source/VW_WorkerExecutionStatus.sql), [VW_WorkerExecutionStatus.md](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerExecutionStatus.md), [VW_WorkerExecutionStatus.md](../../Metadata/UsageSkills/toolbelt_core/VW_WorkerExecutionStatus.md).

<!-- Source/Vertrag SHA256: 333d2834bf3aefc59588047bb7361ada404c140701f194d964b084498e340cfe -->

Voraussetzung: Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.

Keine Eingabeparameter.

```sql
SELECT SlotReservationId,WorkItemId,ClaimGeneration,State,IsHeld,HoldVersion,StopStatus
FROM toolbelt_core.VW_WorkerExecutionStatus ORDER BY WorkItemId,ClaimGeneration;
```

## toolbelt_core.USP_ClaimWorkerWork

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Öffentlicher Einstieg für atomare Managed-Admission eines eigenen Workers.

Vertrag und Quelle: [USP_ClaimWorkerWork.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ClaimWorkerWork.sql), [USP_ClaimWorkerWork.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ClaimWorkerWork.md), [USP_ClaimWorkerWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_ClaimWorkerWork.md).

<!-- Source/Vertrag SHA256: 229a359392b39a45b2f3e3042d1dc2226982cd44176c1f8ea69d1978219fe0d8 -->

Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;

-- IDs/Token aus tatsächlicher eigener Registrierung verwenden:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
-- Synthetische Bindung ohne Registrierung wird abgewiesen; echte Ausgabe privat behandeln.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;
```

## toolbelt_core.USP_CloseWorker

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Schließt eine exakt token-/principalgebundene Generation ohne belegte Reservations.

Vertrag und Quelle: [USP_CloseWorker.sql](../../Modules/toolbelt.core.worker-control/Source/USP_CloseWorker.sql), [USP_CloseWorker.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_CloseWorker.md), [USP_CloseWorker.md](../../Metadata/UsageSkills/toolbelt_core/USP_CloseWorker.md).

<!-- Source/Vertrag SHA256: f043b5492452a2e3a65cba12df695c66fcbecca0fa435751b8079d2dd6bd4cb6 -->

Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Belegte oder ungeklärte Reservations dieser Generation blockieren Close. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_CloseWorker @Hilfe=1;

-- Synthetische Bindung durch die eigene tatsächliche Registrierung ersetzen:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
EXEC toolbelt_core.USP_CloseWorker @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_CloseWorker @Hilfe=1;
```

## toolbelt_core.USP_DisableManagedWorkers

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Deaktiviert Managed-Admission versionsgebunden nur ohne aktive Claims, belegte Reservations und Holds.

Vertrag und Quelle: [USP_DisableManagedWorkers.sql](../../Modules/toolbelt.core.worker-control/Source/USP_DisableManagedWorkers.sql), [USP_DisableManagedWorkers.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_DisableManagedWorkers.md), [USP_DisableManagedWorkers.md](../../Metadata/UsageSkills/toolbelt_core/USP_DisableManagedWorkers.md).

<!-- Source/Vertrag SHA256: 91d0781d3c87f8e896a57298f43c138dbf50026aaba54a6f7e8dca65f85da83f -->

Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. Moduswechsel ist bei Claims, Holds oder belegten/ungeklärten Reservations nicht zulässig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_DisableManagedWorkers @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_DisableManagedWorkers @ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_DisableManagedWorkers @Hilfe=1;
```

## toolbelt_core.USP_EnableManagedWorkers

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Aktiviert Managed-Admission versionsgebunden nur ohne aktive Claims, belegte Reservations und Holds.

Vertrag und Quelle: [USP_EnableManagedWorkers.sql](../../Modules/toolbelt.core.worker-control/Source/USP_EnableManagedWorkers.sql), [USP_EnableManagedWorkers.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_EnableManagedWorkers.md), [USP_EnableManagedWorkers.md](../../Metadata/UsageSkills/toolbelt_core/USP_EnableManagedWorkers.md).

<!-- Source/Vertrag SHA256: cfc07721430dbd303c787cbe5752f7339d9fb0584e4d011ce69c9de2c9a20231 -->

Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. Moduswechsel ist bei Claims, Holds oder belegten/ungeklärten Reservations nicht zulässig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_EnableManagedWorkers @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_EnableManagedWorkers @ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_EnableManagedWorkers @Hilfe=1;
```

## toolbelt_core.USP_HeartbeatWorker

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Erneuert die Heartbeatzeit einer token-/principalgebundenen, noch nicht abgelaufenen Generation.

Vertrag und Quelle: [USP_HeartbeatWorker.sql](../../Modules/toolbelt.core.worker-control/Source/USP_HeartbeatWorker.sql), [USP_HeartbeatWorker.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_HeartbeatWorker.md), [USP_HeartbeatWorker.md](../../Metadata/UsageSkills/toolbelt_core/USP_HeartbeatWorker.md).

<!-- Source/Vertrag SHA256: 6fa8765be8c5821f3a1db7cbb281ab38aa87f58e7e2d5945834196e30cf04939 -->

Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;

-- Synthetische Identitäten ersetzen durch tatsächliches eigenes Registrierungsresultat:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',
 @Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
EXEC toolbelt_core.USP_HeartbeatWorker @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
-- Beispielwerte ohne passende Registrierung ergeben54215.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
```

## toolbelt_core.USP_ReconcileWorkerExecution

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Klassifiziert eine exakte aktuelle Disposition anhand von Connectionfence und locking Witness-/Absencebelegen.

Vertrag und Quelle: [USP_ReconcileWorkerExecution.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ReconcileWorkerExecution.sql), [USP_ReconcileWorkerExecution.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ReconcileWorkerExecution.md), [USP_ReconcileWorkerExecution.md](../../Metadata/UsageSkills/toolbelt_core/USP_ReconcileWorkerExecution.md).

<!-- Source/Vertrag SHA256: 73c6cf381554a0fb786c8709443ef1eafa2c32d4fceb6805602cf8f1b0ccc445 -->

Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;

-- Nur aktuelle exakte Reservation/Disposition verwenden:
DECLARE @Slot uniqueidentifier='00000000-0000-0000-0000-000000000001',@Hold binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Hold;
-- Nach echter Reconciliation HoldVersion aus VW_WorkerExecutionStatus neu lesen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;
```

## toolbelt_core.USP_RegisterWorker

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Erzeugt eine neue principalgebundene Generation einer stabilen WorkerId ohne Übernahme alter Reservations.

Vertrag und Quelle: [USP_RegisterWorker.sql](../../Modules/toolbelt.core.worker-control/Source/USP_RegisterWorker.sql), [USP_RegisterWorker.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_RegisterWorker.md), [USP_RegisterWorker.md](../../Metadata/UsageSkills/toolbelt_core/USP_RegisterWorker.md).

<!-- Source/Vertrag SHA256: 58aafbef5349002aed08899f687558516fda1870342cdb0e79a4faf8bf1eeb25 -->

Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING. |
| `@Capacity` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich. |
| `@RunMode` | `varchar(16)` | `'BOUNDED'` | Input | Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;

DECLARE @Id uniqueidentifier=NEWID();
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@Id,@Capacity=1,@RunMode='BOUNDED';
-- Registrierungsresultat einschließlich geheimem WorkerToken sicher übernehmen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;
```

## toolbelt_core.USP_ReleaseHeldWork

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei.

Vertrag und Quelle: [USP_ReleaseHeldWork.sql](../../Modules/toolbelt.core.worker-control/Source/USP_ReleaseHeldWork.sql), [USP_ReleaseHeldWork.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_ReleaseHeldWork.md), [USP_ReleaseHeldWork.md](../../Metadata/UsageSkills/toolbelt_core/USP_ReleaseHeldWork.md).

<!-- Source/Vertrag SHA256: 46f3559f145fc89867a7f7ba3cc31366e5e23edd8c72fa50952f053cf5925180 -->

Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;

-- Nur nach bewiesenem Rollback und mit frisch gelesener HoldVersion:
DECLARE @Item bigint=1,@Hold binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Hold;
-- Synthetische/stale Werte werden abgewiesen; UNKNOWN ist keine Freigabe.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerCapacity

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Ändert versionsgebunden die lokale Kapazität einer exakt adressierten nicht geschlossenen Generation.

Vertrag und Quelle: [USP_SetWorkerCapacity.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerCapacity.sql), [USP_SetWorkerCapacity.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerCapacity.md), [USP_SetWorkerCapacity.md](../../Metadata/UsageSkills/toolbelt_core/USP_SetWorkerCapacity.md).

<!-- Source/Vertrag SHA256: 4713d80b9b2244b4c1cb2409e1ebafb866e13283e8ad05b05224e986016543b7 -->

Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine vorhandene nicht geschlossene Generation wird adressiert; der Aufruf übernimmt keine Generation. |
| `@Capacity` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Live-Capacity genau dieser Generation. NULL/0/negativ ungültig. Eine Absenkung bricht laufende Arbeit nicht ab; neue Admission wartet auf freie Kapazität. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_SetWorkerCapacity @Hilfe=1;

-- Nur mit realer adressierter Workeridentität und frischer globaler Version verwenden:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Version binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerCapacity @WorkerId=@Id,@WorkerGeneration=1,@Capacity=2,@ExpectedConfigVersion=@Version;
-- Synthetische/veraltete Werte werden abgewiesen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerCapacity @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerConcurrency

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen.

Vertrag und Quelle: [USP_SetWorkerConcurrency.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerConcurrency.sql), [USP_SetWorkerConcurrency.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerConcurrency.md), [USP_SetWorkerConcurrency.md](../../Metadata/UsageSkills/toolbelt_core/USP_SetWorkerConcurrency.md).

<!-- Source/Vertrag SHA256: 52f6991c025b3d9a09208cfdf5bbd5eb16595beee45f5a9d9c4e075a9e84a13a -->

Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MaxConcurrentExecutions` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=2,@ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerIntervals

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Ändert globale Registrierungsintervalldefaults; bestehende Generationen behalten ihre gespeicherten Werte.

Vertrag und Quelle: [USP_SetWorkerIntervals.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerIntervals.sql), [USP_SetWorkerIntervals.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerIntervals.md), [USP_SetWorkerIntervals.md](../../Metadata/UsageSkills/toolbelt_core/USP_SetWorkerIntervals.md).

<!-- Source/Vertrag SHA256: 2ad922e49e4dc320f960e217d78fbfe05b741d310615b12241f7ef4fc8ec868f -->

Voraussetzung: Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@HeartbeatSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..3600 Sekunden. NULL ist ungültig; der technische NULL-Default bedeutet nicht den ursprünglichen Konfigurationswert 15. Wirkt als Registrierungsdefault nur für künftig erzeugte Generationen. |
| `@UnreachableSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 3..86400 Sekunden und mindestens 3*HeartbeatSeconds. NULL ist ungültig, nicht der ursprüngliche Konfigurationswert 60. Bestehende Generationen behalten die bei Registrierung kopierten Intervalle. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerIntervals @HeartbeatSeconds=15,@UnreachableSeconds=60,@ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;
```

## toolbelt_core.USP_SetWorkerState

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Steuert versionsgebunden die neueste noch lebende Worker-generation auf ACTIVE,PAUSED oder DRAINING.

Vertrag und Quelle: [USP_SetWorkerState.sql](../../Modules/toolbelt.core.worker-control/Source/USP_SetWorkerState.sql), [USP_SetWorkerState.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerState.md), [USP_SetWorkerState.md](../../Metadata/UsageSkills/toolbelt_core/USP_SetWorkerState.md).

<!-- Source/Vertrag SHA256: d07ec8329cca2642b4ad8ad0079e89f2811345c01439c9900cdb824655ab3458 -->

Voraussetzung: Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Für diesen administrativen Übergang muss es die neueste lebende Generation der stabilen WorkerId sein. |
| `@RequestedState` | `varchar(16)` | `NULL` | Input | Taxativ und binär/case-sensitiv, ohne nachgestellte Spaces: ACTIVE = neue Admission wieder zulassen; PAUSED = neue Admission pausieren; DRAINING = Auslaufen ohne neue Admission anfordern. Laufende Arbeit wird dadurch nicht abgebrochen. CLOSED/UNREACHABLE sind keine setzbaren Eingabewerte; NULL/leer/andere Werte ungültig. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;

-- Nur mit neuester lebender Workeridentität und frischer globaler Version:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Version binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerState @WorkerId=@Id,@WorkerGeneration=1,@RequestedState='PAUSED',@ExpectedConfigVersion=@Version;
-- Synthetische/veraltete Werte werden abgewiesen.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;
```

## toolbelt_core.USP_StopWorkerExecution

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Persistiert versionsgebunden Stop/Hold einer exakten Reservation oder erkennt deren vorherigen Commit.

Vertrag und Quelle: [USP_StopWorkerExecution.sql](../../Modules/toolbelt.core.worker-control/Source/USP_StopWorkerExecution.sql), [USP_StopWorkerExecution.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_StopWorkerExecution.md), [USP_StopWorkerExecution.md](../../Metadata/UsageSkills/toolbelt_core/USP_StopWorkerExecution.md).

<!-- Source/Vertrag SHA256: abaf4e41d1d68f14eecbc8a0ed17d3fb69e15c425fbd121768c6a134a17bc189 -->

Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedClaimGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche exakte positive bigint-ClaimGeneration der ausgewählten Reservation, aus ihrer Ausführungs-/Claimstatuszeile übernehmen. Kein WorkerGeneration-Wert; NULL oder Abweichung wird abgewiesen. Ein bereits gewinnender Commit wird nicht durch Retry wiederholt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;

-- Reservation und Claimgeneration aus tatsächlicher Claim-/Statuszeile:
DECLARE @Slot uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@Slot,@ExpectedClaimGeneration=1;
```

Hilfe:

```sql
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;
```

## toolbelt_core.USP_StopWorkers

Modul `toolbelt.core.worker-control` · Version `1.0.0` · `USP`

Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds.

Vertrag und Quelle: [USP_StopWorkers.sql](../../Modules/toolbelt.core.worker-control/Source/USP_StopWorkers.sql), [USP_StopWorkers.md](../../Modules/toolbelt.core.worker-control/Documentation/USP_StopWorkers.md), [USP_StopWorkers.md](../../Metadata/UsageSkills/toolbelt_core/USP_StopWorkers.md).

<!-- Source/Vertrag SHA256: 1521fb381e8951c7d1d479e97c7fdf6467ce616d7fc8a6931ae73dd7d14d6e95 -->

Voraussetzung: Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation&gt;0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;

CREATE TABLE #ContosoWorkers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
-- Nur tatsächlich gewählte vorhandene IDs/Generationen einfügen.
EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N'#ContosoWorkers';
-- Diese leere Beispielauswahl stoppt keinen Worker.
```

Hilfe:

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
```

## toolbelt_datetime.TVF_DateBucketDate

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen date-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDate.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDate.sql), [TVF_DateBucketDate.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDate.md), [TVF_DateBucketDate.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_DateBucketDate.md).

<!-- Source/Vertrag SHA256: aac646fe018650f4478ccf340f4607fed8ab3f7d583fb1c4d3c950e66229f056 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode. |
| `@Value` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `date` | `'19000101'` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDate
 ('day',2,CONVERT(date,'2026-01-04T12:00:00'),
 CONVERT(date,'2026-01-01T00:00:00'));
-- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
```

## toolbelt_datetime.TVF_DateBucketDateTime2

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen datetime2-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDateTime2.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTime2.sql), [TVF_DateBucketDateTime2.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTime2.md), [TVF_DateBucketDateTime2.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_DateBucketDateTime2.md).

<!-- Source/Vertrag SHA256: c3a1a2889c15d708e8f5a0f103a1090029d9f73ac9a06f808275db647bc2217c -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetime2(7)` | `'19000101'` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTime2
 ('day',2,CONVERT(datetime2(7),'2026-01-04T12:00:00'),
 CONVERT(datetime2(7),'2026-01-01T00:00:00'));
-- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
```

## toolbelt_datetime.TVF_DateBucketDateTimeOffset

Modul `toolbelt.datetime.bucket` · Version `1.0.0` · `TVF`

Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu.

Vertrag und Quelle: [TVF_DateBucketDateTimeOffset.sql](../../Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTimeOffset.sql), [TVF_DateBucketDateTimeOffset.md](../../Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTimeOffset.md), [TVF_DateBucketDateTimeOffset.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_DateBucketDateTimeOffset.md).

<!-- Source/Vertrag SHA256: b04e1a0e8ae15b1db616a563ba676017ce5590bf6b6d1b133ca031408fc888eb -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetimeoffset(7)` | `'1900-01-01 00:00:00 +00:00'` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Referenz für die Bucketgrenzen. Default ist 1900-01-01 00:00:00+00:00; das Ergebnis verwendet den Offset des Origins. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
 ('day',2,CONVERT(datetimeoffset(7),'2026-01-04T12:00:00+00:00'),
 CONVERT(datetimeoffset(7),'2026-01-01T00:00:00+00:00'));
-- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
```

## toolbelt_datetime.TVF_CalendarDifference

Modul `toolbelt.datetime.calendar-difference` · Version `1.0.0` · `TVF`

Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage.

Vertrag und Quelle: [TVF_CalendarDifference.sql](../../Modules/toolbelt.datetime.calendar-difference/Source/TVF_CalendarDifference.sql), [TVF_CalendarDifference.md](../../Modules/toolbelt.datetime.calendar-difference/Documentation/TVF_CalendarDifference.md), [TVF_CalendarDifference.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_CalendarDifference.md).

<!-- Source/Vertrag SHA256: 332b30ac6a84a151fca1eda2d7591d390cb2c0399ae9c9ad6754c964109b7c10 -->

Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StartDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Anfang des Vergleichs. Beide Reihenfolgen und gleiche Daten sind zulässig; die Richtung steht nur in Sign. NULL ergibt NULL in allen Ergebnisspalten. |
| `@EndDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zweites Datum. Vollständige Jahre/Monate folgen der Anniversary-Regel einschließlich Monatsendklammerung. NULL ergibt NULL in allen Ergebnisspalten. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_CalendarDifference('20240131','20250302');
-- Sign=1, Years=1, Months=1, Days=2.
```

## toolbelt_datetime.TVF_DateSpineDay

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle Tage, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineDay.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineDay.sql), [TVF_DateSpineDay.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineDay.md), [TVF_DateSpineDay.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_DateSpineDay.md).

<!-- Source/Vertrag SHA256: fbb148ec881392962ff41a09a23d0a4e9d3cfb3d666c406ec9c37adb78158fa2 -->

Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Ordinal,PeriodStart FROM toolbelt_datetime.TVF_DateSpineDay('20260227','20260303')
ORDER BY Ordinal;
-- vier Zeilen von 2026-02-27 bis 2026-03-02.
```

## toolbelt_datetime.TVF_DateSpineIsoWeek

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle ISO-Wochen, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineIsoWeek.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineIsoWeek.sql), [TVF_DateSpineIsoWeek.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineIsoWeek.md), [TVF_DateSpineIsoWeek.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_DateSpineIsoWeek.md).

<!-- Source/Vertrag SHA256: 08437f01259022625b97a0c2f87bf3103cdbc490ac572ee8c4dbe33a54b90d24 -->

Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Ordinal,PeriodStart FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231','20260108')
ORDER BY Ordinal;
-- zwei Zeilen mit 2025-12-29 und 2026-01-05.
```

## toolbelt_datetime.TVF_DateSpineMonth

Modul `toolbelt.datetime.date-spine` · Version `1.0.0` · `TVF`

Liefert alle Monate, die einen halboffenen Zeitraum schneiden.

Vertrag und Quelle: [TVF_DateSpineMonth.sql](../../Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineMonth.sql), [TVF_DateSpineMonth.md](../../Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineMonth.md), [TVF_DateSpineMonth.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_DateSpineMonth.md).

<!-- Source/Vertrag SHA256: 4941439290612686742bd6dc8051eaa442f69685a447edcb9a809d1554a5efb2 -->

Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Ordinal,PeriodStart FROM toolbelt_datetime.TVF_DateSpineMonth('20260115','20260402')
ORDER BY Ordinal;
-- vier Zeilen mit 2026-01-01, 2026-02-01, 2026-03-01 und 2026-04-01.
```

## toolbelt_datetime.TVF_TruncateDate

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen date-Wert auf den Beginn der ausgewählten Kalenderperiode.

Vertrag und Quelle: [TVF_TruncateDate.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDate.sql), [TVF_TruncateDate.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDate.md), [TVF_TruncateDate.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_TruncateDate.md).

<!-- Source/Vertrag SHA256: c4f9ad7528b5f805e58cf9dbcd6223fff722db54ae7766758ce2a4b31b532645 -->

Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDate('month', CONVERT(date,'2026-11-20T12:34:56.1234567'));
-- Beginn November 2026, IsValid=1, ValidationCode=0.
```

## toolbelt_datetime.TVF_TruncateDateTime2

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen datetime2-Wert auf den Beginn der gewählten Zeiteinheit.

Vertrag und Quelle: [TVF_TruncateDateTime2.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTime2.sql), [TVF_TruncateDateTime2.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTime2.md), [TVF_TruncateDateTime2.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_TruncateDateTime2.md).

<!-- Source/Vertrag SHA256: cc16eae2f4a36547268b7ac77dcd3cc7b4a9261b42b8decd14a66859eab3dbf1 -->

Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTime2('month', CONVERT(datetime2(7),'2026-11-20T12:34:56.1234567'));
-- Beginn November 2026, IsValid=1, ValidationCode=0.
```

## toolbelt_datetime.TVF_TruncateDateTimeOffset

Modul `toolbelt.datetime.truncate` · Version `1.0.0` · `TVF`

Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset.

Vertrag und Quelle: [TVF_TruncateDateTimeOffset.sql](../../Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTimeOffset.sql), [TVF_TruncateDateTimeOffset.md](../../Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTimeOffset.md), [TVF_TruncateDateTimeOffset.md](../../Metadata/UsageSkills/toolbelt_datetime/TVF_TruncateDateTimeOffset.md).

<!-- Source/Vertrag SHA256: 05b6e50348637df69b1160ed88deabeb31764d2a0fb35c8900752d46047fbf0b -->

Voraussetzung: SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Der ursprüngliche Offset bleibt erhalten. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTimeOffset('month', CONVERT(datetimeoffset(7),'2026-11-20T12:34:56.1234567+02:00'));
-- Beginn November 2026, IsValid=1, ValidationCode=0.
```

## toolbelt_file.USP_LoadBinaryFile

Modul `toolbelt.file.content` · Version `1.0.0` · `USP`

Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.

Vertrag und Quelle: [USP_LoadBinaryFile.sql](../../Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql), [USP_LoadBinaryFile.md](../../Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md), [USP_LoadBinaryFile.md](../../Metadata/UsageSkills/toolbelt_file/USP_LoadBinaryFile.md).

<!-- Source/Vertrag SHA256: ea1dd7b12af828976379d0a4352583de0c0836bbda7da88bd81571f71e42a9df -->

Voraussetzung: SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=N'C:\Contoso\Input\example.bin',@MaxBytes=1048576;
-- Synthetischer serverseitiger Pfad; aktiver Root und vorhandene Rechte nötig.
-- IsValid/ValidationCode prüfen; MaxBytes ist kein Vorallokationslimit.
EXEC toolbelt_file.USP_LoadBinaryFile @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_LoadBinaryFile @Hilfe=1;
```

## toolbelt_file.USP_LoadTextFile

Modul `toolbelt.file.content` · Version `1.0.0` · `USP`

Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen.

Vertrag und Quelle: [USP_LoadTextFile.sql](../../Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql), [USP_LoadTextFile.md](../../Modules/toolbelt.file.content/Documentation/USP_LoadTextFile.md), [USP_LoadTextFile.md](../../Metadata/UsageSkills/toolbelt_file/USP_LoadTextFile.md).

<!-- Source/Vertrag SHA256: ff0f2e84144b28f9b9dac9131123004e552b4465452efe56ab12b91bb5a5cc95 -->

Voraussetzung: SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@FallbackEncoding` | `nvarchar(128)` | `N'Windows-1252'` | Input | Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_file.USP_LoadTextFile @FilePath=N'C:\Contoso\Input\example.txt',@MaxBytes=1048576;
-- Synthetischer serverseitiger Pfad; aktiver Root und vorhandene Rechte nötig.
-- IsValid/ValidationCode prüfen; MaxBytes ist kein Vorallokationslimit.
EXEC toolbelt_file.USP_LoadTextFile @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_LoadTextFile @Hilfe=1;
```

## toolbelt_file.USP_ParseCsv

Modul `toolbelt.file.csv-memory` · Version `1.0.0` · `USP`

Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle.

Vertrag und Quelle: [USP_ParseCsv.sql](../../Modules/toolbelt.file.csv-memory/Source/USP_ParseCsv.sql), [USP_ParseCsv.md](../../Modules/toolbelt.file.csv-memory/Documentation/USP_ParseCsv.md), [USP_ParseCsv.md](../../Metadata/UsageSkills/toolbelt_file/USP_ParseCsv.md).

<!-- Source/Vertrag SHA256: eef13c0d44b6c2d7f9ffe22d33408a84f832806d92e3afc9886c667cd4cc0af9 -->

Voraussetzung: Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. ResultTable >=1.0.0 in derselben Datenbank für Routing. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `NULL` | Input | Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord. |
| `@Separator` | `nvarchar(2)` | `N','` | Input | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. |
| `@HasHeader` | `bit` | `0` | Input | 0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen. |
| `@NullToken` | `nvarchar(128)` | `NULL` | Input | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. |
| `@MaxRows` | `bigint` | `100000` | Input | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. |
| `@MaxColumns` | `int` | `1024` | Input | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. |
| `@MaxCells` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 oder NULL ohne Diagnose, 1..255 abstrakte Severity-10-NOWAIT-Meldung ohne Zellinhalte und ohne zusätzliches Fachresultset. Bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 0 oder NULL: Fachaufruf; 1: vor Fachvalidierung nur bestehende zwölfspaltige Standardhilfe und genau ein zusätzliches vierspaltiges Skill-Resultset, danach RETURN 0. Alle SQL-Parameter besitzen Defaults, daher genügt @Hilfe=1. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Csv nvarchar(max)=N'name,value'+NCHAR(10)+N'alpha,1';
EXEC toolbelt_file.USP_ParseCsv @Text=@Csv,@HasHeader=1;
-- Vier Zellen: HEADER (0,1)/(0,2), DATA (1,1)/(1,2).
EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
```

## toolbelt_file.USP_WriteCsv

Modul `toolbelt.file.csv-memory` · Version `1.0.0` · `USP`

Schreibt einen read-only Snapshot vier typgenauer caller-lokaler Temp-Spalten als vollständig budgetiertes CSV.

Vertrag und Quelle: [USP_WriteCsv.sql](../../Modules/toolbelt.file.csv-memory/Source/USP_WriteCsv.sql), [USP_WriteCsv.md](../../Modules/toolbelt.file.csv-memory/Documentation/USP_WriteCsv.md), [USP_WriteCsv.md](../../Metadata/UsageSkills/toolbelt_file/USP_WriteCsv.md).

<!-- Source/Vertrag SHA256: b273ae9d191c2c95f7285b0ab459c462d02ab33ec3dc43f34b2f6b24e4db8b0d -->

Voraussetzung: Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. ResultTable >=1.0.0 in derselben Datenbank für Routing. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 oder NULL ohne Diagnose, 1..255 abstrakte Severity-10-NOWAIT-Meldung ohne Zellinhalte und ohne zusätzliches Fachresultset. Bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 0 oder NULL: Fachaufruf; 1: vor Fachvalidierung nur bestehende zwölfspaltige Standardhilfe und genau ein zusätzliches vierspaltiges Skill-Resultset, danach RETURN 0. Alle SQL-Parameter besitzen Defaults, daher genügt @Hilfe=1. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
CREATE TABLE #CsvCells(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,[Value] nvarchar(max));
INSERT #CsvCells VALUES('DATA',1,1,N'a,b'),('DATA',1,2,N'x');
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCells',@LineEnding='LF';
-- CsvText: Doppelquote a,b Doppelquote ,x gefolgt von LF; DataRows=1, ColumnCount=2.
DROP TABLE #CsvCells;
EXEC toolbelt_file.USP_WriteCsv @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_WriteCsv @Hilfe=1;
```

## toolbelt_file.USP_ListXlsxWorksheets

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `USP`

Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.

Vertrag und Quelle: [USP_ListXlsxWorksheets.sql](../../Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql), [USP_ListXlsxWorksheets.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/USP_ListXlsxWorksheets.md), [USP_ListXlsxWorksheets.md](../../Metadata/UsageSkills/toolbelt_file/USP_ListXlsxWorksheets.md).

<!-- Source/Vertrag SHA256: 37917c0ccc13e880bd4da25a302a72a190019d5269bdba909f982ed79f457942 -->

Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;
-- Vollständige Client-Workbookbytes binden, keinen Serverpfad.
DECLARE @Workbook varbinary(max)=NULL;
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Workbook;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;
```

## toolbelt_file.USP_ReadXlsxWorksheetCells

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `USP`

Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.

Vertrag und Quelle: [USP_ReadXlsxWorksheetCells.sql](../../Modules/toolbelt.file.xlsx-memory/Source/USP_ReadXlsxWorksheetCells.sql), [USP_ReadXlsxWorksheetCells.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md), [USP_ReadXlsxWorksheetCells.md](../../Metadata/UsageSkills/toolbelt_file/USP_ReadXlsxWorksheetCells.md).

<!-- Source/Vertrag SHA256: 85a077fa2e61ce9fd5a61875817e42496fa7de20bfab62a259cbafdb94eea9df -->

Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
-- Vollständige Client-Workbookbytes binden, keinen Serverpfad.
DECLARE @Workbook varbinary(max)=NULL;
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Workbook,@SheetOrdinal=1;
```

Hilfe:

```sql
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
```

## toolbelt_file.TVF_InterpretXlsxCell

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `TVF`

Interpretiert den zuvor gelesenen Rohwert einer XLSX-Zelle als begrenzten, typisierten Wert.

Vertrag und Quelle: [TVF_InterpretXlsxCell.sql](../../Modules/toolbelt.file.xlsx-memory/Source/TVF_InterpretXlsxCell.sql), [TVF_InterpretXlsxCell.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/TVF_InterpretXlsxCell.md), [TVF_InterpretXlsxCell.md](../../Metadata/UsageSkills/toolbelt_file/TVF_InterpretXlsxCell.md).

<!-- Source/Vertrag SHA256: bd38ec0e000068bd124729ecf1a3fb9730e0b9384bb847def7dde340a8e33fd3 -->

Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung. |
| `@ValuePresent` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Exakte endliche Klassifikation: 0,0.00,#,##0.00,0%,0.00%,0.00E+00 -&gt; number; yyyy-mm-dd -&gt; date; yyyy-mm-dd hh:mm:ss -&gt; datetime; hh:mm:ss -&gt; time; [h]:mm:ss -&gt; duration; @ -&gt; text. Höchstens128 UTF16-Einheiten. NULL klassifiziert nicht und erlaubt Ziel-/StoredType-Default; leer/unbekannt Status6, Widerspruch zum expliziten Target Status2. Dieser Typkern rendert kein Anzeigeformat und liest keine Styles. |
| `@Date1904` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(N'n',1,N'1.235',NULL,N'number',NULL,NULL);
```

## toolbelt_file.TVF_FormatXlsxCell

Modul `toolbelt.file.xlsx-memory` · Version `1.2.0` · `TVF`

Formatiert eine XLSX-Einzelzelle mit den unterstützten Literalformaten und Kulturen.

Vertrag und Quelle: [TVF_FormatXlsxCell.sql](../../Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql), [TVF_FormatXlsxCell.md](../../Modules/toolbelt.file.xlsx-memory/Documentation/TVF_FormatXlsxCell.md), [TVF_FormatXlsxCell.md](../../Metadata/UsageSkills/toolbelt_file/TVF_FormatXlsxCell.md).

<!-- Source/Vertrag SHA256: 3a2de638bacab9812d1c72dad8628aba8f964f7ea1c074433e53fc31fcddaf5b -->

Voraussetzung: Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.

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
SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(N'n',1,N'1.235',NULL,N'number',N'0.00',NULL,N'de-DE');
```

## toolbelt_filesystem.USP_ReadBinaryFileChunk

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_ReadBinaryFileChunk.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_ReadBinaryFileChunk.md), [USP_ReadBinaryFileChunk.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_ReadBinaryFileChunk.md).

<!-- Source/Vertrag SHA256: f8385001a5fe33de8df937371b29b443a4af45a68c66bfffa7f707bc6a187c57 -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig. |
| `@ByteOffset` | `bigint` | `0` | Input | Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen. |
| `@MaxBytes` | `int` | `1048576` | Input | Ganzzahl 1..16777216 Rohbytes pro Chunk, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF kürzer sein; kein Gesamtdateilimit. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe=1;
-- Fachaufruf nur mit eigener passender Rootkonfiguration:
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @RootAlias=N'ContosoRead',@RelativePath=N'sample.bin',@MaxBytes=1024;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe=1;
```

## toolbelt_filesystem.USP_ReadTextFileChunk

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Liest einen begrenzten Text-Chunk mit expliziter Codepage und liefert die nächste Byte-Position.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_ReadTextFileChunk.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_ReadTextFileChunk.md), [USP_ReadTextFileChunk.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_ReadTextFileChunk.md).

<!-- Source/Vertrag SHA256: 45c188f6e20dcaa03db0cd6e9771ba7126fc8910a8395ec8a6e08648811abece -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig. |
| `@ByteOffset` | `bigint` | `0` | Input | Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen. |
| `@MaxBytes` | `int` | `1048576` | Input | Ganzzahl 4..16777216 Rohbytes pro Leseversuch, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF oder zum Erhalt einer vollständigen Decodergrenze kürzer sein; kein Gesamtdateilimit. |
| `@EncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. BOM wird als Datenzeichen behandelt; Offset/NextByteOffset zählen weiterhin Bytes. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @Hilfe=1;
-- Fachaufruf nur mit eigener passender Rootkonfiguration:
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @RootAlias=N'ContosoRead',@RelativePath=N'sample.txt',@EncodingName=N'utf-8';
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @Hilfe=1;
```

## toolbelt_filesystem.USP_WriteBinaryFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Schreibt Binärdaten gestreamt in eine atomar veröffentlichte Zieldatei.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_WriteBinaryFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_WriteBinaryFile.md), [USP_WriteBinaryFile.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_WriteBinaryFile.md).

<!-- Source/Vertrag SHA256: f23c9e6f20855185cae509d110339e5cf6bf9095bb03f6cd0c8cc3675bc679c8 -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen. |
| `@Content` | `varbinary(max)` | `NULL` | Input | Binärer Bytepuffer varbinary(max), etwa 0x0102; keine Text-/Base64-Dekodierung. Leer 0x schreibt eine leere Datei. NULL (technischer Help-Default) ungültig. SQL-LOB wird in begrenzten Blöcken gelesen, kein zusätzliches öffentliches Gesamtbytebudget. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_WriteBinaryFile @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_WriteBinaryFile @Hilfe=1;
```

## toolbelt_filesystem.USP_WriteTextFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Schreibt Text gestreamt mit expliziter Codepage und optionalem BOM.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_WriteTextFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_WriteTextFile.md), [USP_WriteTextFile.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_WriteTextFile.md).

<!-- Source/Vertrag SHA256: cfd854036d97930f8b5795d43350b9eba35593a2522b2486a9a69dd736de2842 -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen. |
| `@Content` | `nvarchar(max)` | `NULL` | Input | Unicode-Text nvarchar(max), leer schreibt nur eine gegebenenfalls gewählte BOM. NULL (technischer Help-Default) ungültig. Zeichen werden mit explizitem Encoding strikt kodiert; unvertretbare Zeichen/ungültige Surrogate sind Fehler, kein stiller Ersatz. Kein Append oder zusätzliches Gesamttextbudget. |
| `@EncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. |
| `@WriteBom` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_WriteTextFile @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_WriteTextFile @Hilfe=1;
```

## toolbelt_filesystem.USP_TranscodeTextFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_TranscodeTextFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_TranscodeTextFile.md), [USP_TranscodeTextFile.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_TranscodeTextFile.md).

<!-- Source/Vertrag SHA256: b0bd631ac37b3262f835b3d9c622e0f233cc73a7745a025dc3f9b11642bbec81 -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe=1;
```

## toolbelt_filesystem.USP_ListDirectory

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Listet Verzeichniseinträge unter einem freigegebenen Root mit harten Grenzen.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_ListDirectory.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_ListDirectory.md), [USP_ListDirectory.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_ListDirectory.md).

<!-- Source/Vertrag SHA256: f6683343794febfb02c68bc77c182328c007b00d36bc44c852ddc1d62e0a1b39 -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowList erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `N''` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer (Default) wählt den Root selbst; NULL bleibt ungültig. Kein Suchmuster. |
| `@Recursive` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default. |
| `@MaxDepth` | `int` | `32` | Input | Ganzzahl 0..64, Default 32; Startdirectory hat Tiefe 0. Bei Recursive=1 führt ein nötiger Abstieg über die Grenze zum Fehler, nicht zu einer still gekürzten Ausgabe; bei 0 ist bereits Abstieg in ein Unterverzeichnis verboten. Auch ohne Rekursion muss das Budget gültig sein. NULL/negativ/&gt;64 ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..10000 Verzeichniseinträge (Dateien und Unterverzeichnisse), Default 10000. NULL/außerhalb ungültig; Überschreitung verwirft die vollständig gepufferte Ausgabe, kein TOP-Teilresultat. Zusätzlich gilt ein internes Pfadbytebudget. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe=1;
-- Fachaufruf nur mit eigener passender Rootkonfiguration:
EXEC toolbelt_filesystem.USP_ListDirectory @RootAlias=N'ContosoRead',@RelativePath=N'',@MaxEntries=100;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe=1;
```

## toolbelt_filesystem.USP_CreateDirectory

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Erstellt ein Verzeichnis unter einem freigegebenen Root.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_CreateDirectory.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_CreateDirectory.md), [USP_CreateDirectory.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_CreateDirectory.md).

<!-- Source/Vertrag SHA256: dae122786cad89428a4b90f808a04922bab893580a84ebbd6cb4797a3dca562f -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowCreateDirectory erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer ist erlaubt und bezeichnet den Root; fehlende Komponenten des konfigurierten Zielpfads werden durch NativeParents angelegt; physische Rootkonfiguration muss deshalb von autorisierter Verwaltung stammen. NULL ungültig. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_CreateDirectory @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_CreateDirectory @Hilfe=1;
```

## toolbelt_filesystem.USP_RemoveFile

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Entfernt eine Datei unter einem freigegebenen Root.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_RemoveFile.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_RemoveFile.md), [USP_RemoveFile.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_RemoveFile.md).

<!-- Source/Vertrag SHA256: 75c9c42f93f56e9dbbe63f6bfac1a8ed04936c8bb5f4597c636c07d2475e2fef -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowDelete erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer, muss eine vorhandene reguläre Datei adressieren, keine Verzeichnisse/Mehrfachauswahl. Löscht genau die handlegebundene Datei; kein Recycle-Bin-Vertrag. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_RemoveFile @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_RemoveFile @Hilfe=1;
```

## toolbelt_filesystem.USP_RemoveDirectory

Modul `toolbelt.filesystem.windows` · Version `1.0.0` · `USP`

Entfernt ein Verzeichnis; rekursives Entfernen ist explizit und begrenzt.

Vertrag und Quelle: [Procedures.sql](../../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [USP_RemoveDirectory.md](../../Modules/toolbelt.filesystem.windows/Documentation/USP_RemoveDirectory.md), [USP_RemoveDirectory.md](../../Metadata/UsageSkills/toolbelt_filesystem/USP_RemoveDirectory.md).

<!-- Source/Vertrag SHA256: cff75d31e0f6f6c02fe767405b89dea503395dd3b47a01f89e1dc63e331023e9 -->

Voraussetzung: Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowDelete erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die reine Hilfe kehrt vor diesen fachlichen Voraussetzungen zurück. Ein physischer Dateipfad wird nicht als Caller-Eingabe angenommen; RootAlias verweist auf vorhandene autorisierte Konfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer kann syntaktisch aufgelöst werden, aber der Root selbst darf niemals gelöscht werden. Muss ein vorhandenes Verzeichnis sein; keine Wildcard-/Mehrfachauswahl. |
| `@Recursive` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default. Bei 0 muss das Verzeichnis leer sein. |
| `@MaxDepth` | `int` | `32` | Input | Ganzzahl 0..2147483647, Default 32; der Remove-Pfad besitzt anders als List keine zusätzliche 64er-Obergrenze. Startdirectory hat Tiefe 0. Bei Recursive=1 wird jeder nötige Abstieg über das Budget vor der ersten Löschmutation abgewiesen. NULL/negativ ungültig; nicht still trunciert. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..2147483647, Default 10000; der Remove-Pfad besitzt anders als List keine zusätzliche 10000er-Obergrenze. Zählt sämtliche Kinder im vollständigen Vorab-Löschplan, ohne das Startdirectory selbst. NULL/0/negativ ungültig; Überschreitung vor erster Mutation. Keine automatische unbegrenzte Löschung. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und anschließend genau eine vollständige vierkolumnige Skillzeile; Rückkehr vor Root-/Identitäts-/Datei-/ResultTable-Zugriff. 0 oder NULL führt den Fachpfad aus. Fachlich ungültige, aber SQL-typgültige Argumente werden bei Hilfe nicht geprüft. SQL-Typbindung erfolgt dennoch vor dem Prozedureinstieg. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
-- Reine Hilfe ohne Rootkonfiguration oder Dateioperation:
EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe=1;
```

## toolbelt_json.USP_JsonArray

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Array aus Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonArray.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonArray.sql), [USP_JsonArray.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonArray.md), [USP_JsonArray.md](../../Metadata/UsageSkills/toolbelt_json/USP_JsonArray.md).

<!-- Source/Vertrag SHA256: 0abe69b5f2f3e0c423dd1c4d93102863c83443409f35a3ca0f759f81c24bfe10 -->

Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Leere Tabelle ergibt genau [] beziehungsweise {}. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_json.USP_JsonArray @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonArray @Hilfe=1;
```

## toolbelt_json.USP_JsonObject

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Object aus Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonObject.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonObject.sql), [USP_JsonObject.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonObject.md), [USP_JsonObject.md](../../Metadata/UsageSkills/toolbelt_json/USP_JsonObject.md).

<!-- Source/Vertrag SHA256: 41d121c7e010811e797a086c503ffbe8f467982d57441877f3877029a5e7f2e3 -->

Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Leere Tabelle ergibt genau [] beziehungsweise {}. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,N'contoso',N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
```

## toolbelt_json.USP_JsonArraysByGroup

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Array aus GroupOrdinal/Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonArraysByGroup.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonArraysByGroup.sql), [USP_JsonArraysByGroup.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonArraysByGroup.md), [USP_JsonArraysByGroup.md](../../Metadata/UsageSkills/toolbelt_json/USP_JsonArraysByGroup.md).

<!-- Source/Vertrag SHA256: 46a16015ecbf69d601250afedc1f3116cb52522e1bd30c1c3418020d1f594b46 -->

Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_json.USP_JsonArraysByGroup @Hilfe=1;
CREATE TABLE #ContosoEntries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,1,N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonArraysByGroup @Hilfe=1;
```

## toolbelt_json.USP_JsonObjectsByGroup

Modul `toolbelt.json.constructors` · Version `1.3.0` · `USP`

JSON-Object aus GroupOrdinal/Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.

Vertrag und Quelle: [USP_JsonObjectsByGroup.sql](../../Modules/toolbelt.json.constructors/Source/USP_JsonObjectsByGroup.sql), [USP_JsonObjectsByGroup.md](../../Modules/toolbelt.json.constructors/Documentation/USP_JsonObjectsByGroup.md), [USP_JsonObjectsByGroup.md](../../Metadata/UsageSkills/toolbelt_json/USP_JsonObjectsByGroup.md).

<!-- Source/Vertrag SHA256: 91746710f5adc8403f4ba1ea859cb1900feaaf903915f338e97443642c45cae3 -->

Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_json.USP_JsonObjectsByGroup @Hilfe=1;
CREATE TABLE #ContosoEntries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #ContosoEntries VALUES(1,1,N'contoso',N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#ContosoEntries';
DROP TABLE #ContosoEntries;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_JsonObjectsByGroup @Hilfe=1;
```

## toolbelt_json.AGF_JsonArray

Modul `toolbelt.json.constructors` · Version `1.3.0` · `CLR_AGGREGATE`

Aggregiert typisierte JSON-Einträge in Ordinal-Reihenfolge zu einem JSON-Array.

Vertrag und Quelle: [JsonAggregates.sql](../../Modules/toolbelt.json.constructors/Source/JsonAggregates.sql), [AGF_JsonArray.md](../../Modules/toolbelt.json.constructors/Documentation/AGF_JsonArray.md), [AGF_JsonArray.md](../../Metadata/UsageSkills/toolbelt_json/AGF_JsonArray.md).

<!-- Source/Vertrag SHA256: 51cbe44bc273984ea070c69dccc5214c8ff0a904209eb6e810b2712a0ebd30e1 -->

Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647, nicht NULL und je Aggregatgruppe eindeutig. Bestimmt die Ausgabeordnung unabhängig von Callback-/Inputreihenfolge; Lücken sind erlaubt. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Bei json höchstens 127 Containerebenen, damit der äußere Aggregatcontainer Tiefe 128 nicht überschreitet. |
| `@Profile` | `tinyint` | `kein Default` | Input | Taxativ für tinyint: 1 = höchstens 10000 Entries, 2097152 Payloadbytes und 5242880 serialisierte Zustandsbytes; 2 = 100000 Entries, 16777216 Payloadbytes und 37748736 Zustandsbytes. Kein Default: an jedem Inputeintrag explizit übergeben. Muss in einer Aggregatgruppe gleich bleiben; NULL/andere/gemischte Werte sind Fehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],CONVERT(tinyint,1)) AS JsonValue
FROM (VALUES(1,N'string',N'Contoso'),(2,N'number',N'2')) AS e(Ordinal,ValueKind,[Value]);
```

## toolbelt_json.AGF_JsonObject

Modul `toolbelt.json.constructors` · Version `1.3.0` · `CLR_AGGREGATE`

Aggregiert typisierte Einträge mit eindeutigen Schlüsseln zu einem JSON-Objekt.

Vertrag und Quelle: [JsonAggregates.sql](../../Modules/toolbelt.json.constructors/Source/JsonAggregates.sql), [AGF_JsonObject.md](../../Modules/toolbelt.json.constructors/Documentation/AGF_JsonObject.md), [AGF_JsonObject.md](../../Metadata/UsageSkills/toolbelt_json/AGF_JsonObject.md).

<!-- Source/Vertrag SHA256: d3c355cea51328be9c711b1c22d183abf242322f1d49ee78e246f2a7e319f0d3 -->

Voraussetzung: Kanonisches Modul1.3.0 mit JsonCore-Abhängigkeit und bekannter SAFE-Assembly tlblt_JsonConstructors. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Die Prozeduren brauchen den ResultTablehelper auch für direkte Ausgabe. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers; der Aufruf ändert keine Rechte oder Serverkonfiguration.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647, nicht NULL und je Aggregatgruppe eindeutig. Bestimmt die Ausgabeordnung unabhängig von Callback-/Inputreihenfolge; Lücken sind erlaubt. |
| `@Key` | `nvarchar(max)` | `kein Default` | Input | Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Bei json höchstens 127 Containerebenen, damit der äußere Aggregatcontainer Tiefe 128 nicht überschreitet. |
| `@Profile` | `tinyint` | `kein Default` | Input | Taxativ für tinyint: 1 = höchstens 10000 Entries, 2097152 Payloadbytes und 5242880 serialisierte Zustandsbytes; 2 = 100000 Entries, 16777216 Payloadbytes und 37748736 Zustandsbytes. Kein Default: an jedem Inputeintrag explizit übergeben. Muss in einer Aggregatgruppe gleich bleiben; NULL/andere/gemischte Werte sind Fehler. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],CONVERT(tinyint,1)) AS JsonValue
FROM (VALUES(1,N'contoso',N'string',N'Contoso'),(2,N'count',N'number',N'2')) AS e(Ordinal,[Key],ValueKind,[Value]);
```

## toolbelt_json.TVF_JsonPathExists

Modul `toolbelt.json.path-exists` · Version `1.0.0` · `TVF`

Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert.

Vertrag und Quelle: [TVF_JsonPathExists.sql](../../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql), [TVF_JsonPathExists.md](../../Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExists.md), [TVF_JsonPathExists.md](../../Metadata/UsageSkills/toolbelt_json/TVF_JsonPathExists.md).

<!-- Source/Vertrag SHA256: 07f7edad180bdc607d2730884376e334e17e5e2d54e89f1267dd4d229d1dd3d6 -->

Voraussetzung: JSONpath-Modul mit nativer ISJSON/OPENJSON-Unterstützung in derselben DB. Windows/Linux SQL2019/2022/2025, CL150/160/170 im zulässigen Hostprofil. Kein Quellkatalog-, Datei-, Netzwerk-, CLR- oder Trustzugriff.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a&lt;Space&gt; sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"items":[{"name":null}]}',N'$.items[*].name');
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"');
```

## toolbelt_json.TVF_JsonPathExistsStatus

Modul `toolbelt.json.path-exists` · Version `1.0.0` · `TVF`

Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING.

Vertrag und Quelle: [TVF_JsonPathExists.sql](../../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql), [TVF_JsonPathExistsStatus.md](../../Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExistsStatus.md), [TVF_JsonPathExistsStatus.md](../../Metadata/UsageSkills/toolbelt_json/TVF_JsonPathExistsStatus.md).

<!-- Source/Vertrag SHA256: 48991c47c77383138ff7870ca56541e1a617d3a8e4c24df0a63d2f5f68d5cce9 -->

Voraussetzung: JSONpath-Modul mit nativer ISJSON/OPENJSON-Unterstützung in derselben DB. Windows/Linux SQL2019/2022/2025, CL150/160/170 im zulässigen Hostprofil. Kein Quellkatalog-, Datei-, Netzwerk-, CLR- oder Trustzugriff.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a&lt;Space&gt; sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"items":[{"name":null}]}',N'$.items[*].name');
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"');
```

## toolbelt_json.TVF_ResolveJsonPointer

Modul `toolbelt.json.pointer` · Version `1.0.0` · `TVF`

Löst einen RFC6901-Pointer mit exakten Keys und unterscheidet FOUND, MISSING, JSON_NULL, SQL_NULL und INVALID. Der freigegebene feste128er-Guard gibt darüber DEPTH_LIMIT vor JSON_SYNTAX zurück.

Vertrag und Quelle: [TVF_ResolveJsonPointer.sql](../../Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql), [TVF_ResolveJsonPointer.md](../../Modules/toolbelt.json.pointer/Documentation/TVF_ResolveJsonPointer.md), [TVF_ResolveJsonPointer.md](../../Metadata/UsageSkills/toolbelt_json/TVF_ResolveJsonPointer.md).

<!-- Source/Vertrag SHA256: 58d59a61c42da10d745bb5e908aafa826b138245c3554f0970d7dab93d5d3e68 -->

Voraussetzung: SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützter Compatibility Level mindestens150 auch im zentralen Aufrufkontext. Ausschließlich native ISJSON-/OPENJSON-Grammatik und begrenzter UTF16-Policywalker; keine CLR-Assembly, Daten-/Systemkatalogtabelle, Serveroption oder Abhängigkeit eines anderen Moduls. Der gesamte Input muss gültige Syntax, Tiefen- und Unicodepolicy erfüllen, auch nicht traversierte Teile.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, wohlgeformtes Unicode auch in decodierten Escapes. Leer ist ungültig; DATALENGTH darf MaxInputBytes nicht überschreiten. Vor nativer Prüfung gilt die absolute Containertiefengrenze 128, danach das abgesenkte MaxDepth. NULL in Json oder Pointer ergibt SQL_NULL vor Parameterprüfung. Kein partiell gültiges Dokument und keine Mutation. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
| `@Pointer` | `nvarchar(max)` | `kein Default` | Input | RFC6901-Stringpointer, keine URIfragmentform #/...: leer bezeichnet Root, sonst beginnt der Text mit /. Segmente sind exakte binäre/case-sensitive Objektkeys; ~0 decodiert einmal zu ~, ~1 zu /. Kein anderes ~-Escape oder Percentdecoding. Arrayindizes sind nullbasiert kanonische nicht negative ASCII-Dezimalzahlen ohne führende Nullen; - ist kein Appendindex, Wildcards fehlen. Maximal 4000 UTF-16-Einheiten, wohlgeformtes Unicode; / bezeichnet einen leeren Key. NULL ergibt SQL_NULL. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes des JSON-Dokuments, Default 16777216; keine Zeichenanzahl. NULL/außerhalb ergibt INVALID/PARAMETER, Überschreitung INVALID/INPUT_LIMIT. Nur absenkbar; früher Json-/Pointer-NULL-Pfad hat Vorrang. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
| `@MaxDepth` | `int` | `128` | Input | Ganzzahl 1..128 gleichzeitig offene JSON-Container, Default 128. Gilt für das gesamte Dokument, auch nicht traversierte Teile. NULL/außerhalb ergibt INVALID/PARAMETER; vor nativer JSON-Prüfung bleibt zusätzlich die absolute Schutzgrenze 128 wirksam. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Status,JsonType,Value,ErrorCode
FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"a/b":[null,"example"]}',N'/a~1b/1',DEFAULT,DEFAULT);
-- FOUND / STRING / example / NULL.
SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(N'null',N'',DEFAULT,DEFAULT);
-- JSON_NULL mit JsonType als Text NULL und Value SQL-NULL.
SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(NULL,NULL,0,0);
-- SQL_NULL vor Parameterfehlern.
```

## toolbelt_json.USP_ValidateJsonSchema

Modul `toolbelt.json.schema` · Version `1.0.1` · `USP`

Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen.

Vertrag und Quelle: [USP_ValidateJsonSchema.sql](../../Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql), [USP_ValidateJsonSchema.md](../../Modules/toolbelt.json.schema/Documentation/USP_ValidateJsonSchema.md), [USP_ValidateJsonSchema.md](../../Metadata/UsageSkills/toolbelt_json/USP_ValidateJsonSchema.md).

<!-- Source/Vertrag SHA256: e5f45856ad8fe4dbbfdafe173d27ec6ab19029de71912b6c08468d357a9be4f5 -->

Voraussetzung: Installiertes Schema1.0.1 mit autorisierten SAFE-Assemblies tlblt_JsonSchema und tlblt_JsonCore, SQL2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Einziges Profil toolbelt-2020-12-v1, exakte ordinale Schreibweise/Länge ohne Trim. Boolean-Schema true/false oder Schemaobjekt. Kein vollständiges Draft2020-12-Profil. Taxative 22 Keywords: `$schema`, `$ref`, `$defs`, `title`, `description`, `$comment`, `type`, `required`, `properties`, `additionalProperties`, `items`, `prefixItems`, `minItems`, `maxItems`, `minProperties`, `maxProperties`, `minLength`, `maxLength`, `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`. $schema nur String https://json-schema.org/draft/2020-12/schema, keine andere Draftkennung. title/description/$comment nur Stringannotation ohne Validierungseffekt. Unknowns einschließlich enum,const,format,pattern,multipleOf,allOf/anyOf/oneOf,not,if/then/else,contains,uniqueItems,$id/$anchor/$dynamicRef und unevaluated* ergeben UNSUPPORTED, nicht stilles Ignorieren. `type`: einer von null/boolean/number/string/object/array/integer als String oder nichtleere Arraymenge ohne doppelte Typnamen. `required`: Array eindeutiger Strings, leer erlaubt. `properties` und `$defs`: Objekte mit Boolean-/Objektschemas. `additionalProperties` und `items`: einzelnes Boolean-/Objektschema, keine alte Array-items-Tupleform. `prefixItems`: nichtleeres Array von Schemas; `items` gilt für Positionen dahinter oder alle ohne prefixItems. Object-/Array-/Stringkeywords greifen nur auf den passenden Instanztyp. Zählerbounds min*/max* sind mathematisch nichtnegative ganze JSON-Zahlen, keine auf SQL-int beschränkten Eingabeparameter. minLength/maxLength zählen Unicode-Skalare, nicht UTF16-Codeunits/Grapheme. Numeric minimum/maximum/exclusive* verlangen JSON-Zahlen, keine alten Boolean-exclusive-Schalter. integer wird mathematisch bestimmt: z.B. 1.0 ist integer, ohne Coercion oder Gleitkommarundung. Nur nichtrekursive lokale URIfragment-$ref: beginnt mit #, danach einmal strict Percentbytes/UTF8 und dann einmal RFC6901 ~0/~1 decodieren. Rootfragment # möglich, aber Selbst-/Referenzzyklen im gesamten Schema-/Containmentgraph sind UNSUPPORTED/REF_CYCLE. Kein Netzwerk, Dateizugriff oder externer Resolver; leere/externe Referenz ohne # ist UNSUPPORTED/EXTERNAL_REF. Fehlerhafte Prozent-/UTF8-/~-/Fragmentlexik INVALID_SCHEMA/REF_SYNTAX; fehlendes/nicht als Schema erschlossenes Ziel bzw. ungeeigneter Arrayindex INVALID_SCHEMA/REF_TARGET. Alle bekannten Schemaorte einschließlich ungenutzter $defs werden zuerst geprüft, inklusive Formen, lokaler Targets und Zyklen. Schemaorte/Graphkanten stabil nach vollständig codierten Pointern, Instanzmember nach decodierter UTF16-Identität und Instanzarrays numerisch; keine Kultur-/SQL-Padding-Normalisierung. SameDB core.result-table>=1.0.0 mit exakt fünf erwarteten Parametern ist auch für direkten SELECT erforderlich: seine Metadatensignatur wird vor CLR-Auswertung geprüft. Diese Routine installiert/erweitert keine Abhängigkeit.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Argument-/Namespace-/Helper-/CLR-/Fachprüfung oder Zielmutation. 0 oder NULL: Fachpfad. Alle SQL-Argumente besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{"quantity":3}',@Schema=N'{"type":"object","required":["quantity"],"properties":{"quantity":{"type":"integer","minimum":1}}}';
-- SUMMARY VALID,IsValid=1; keine ERROR-Zeilen.
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
```

## toolbelt_metadata.VW_ModuleCapabilities

Modul `toolbelt.metadata.capability-catalog` · Version `1.0.0` · `VW`

Zeigt sichtbare bekannte Modulschnittstellenkandidaten; Version und Deployment-Modus bleiben NULL, MetadataStatus bleibt incomplete.

Vertrag und Quelle: [VW_ModuleCapabilities.sql](../../Modules/toolbelt.metadata.capability-catalog/Source/VW_ModuleCapabilities.sql), [VW_ModuleCapabilities.md](../../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ModuleCapabilities.md), [VW_ModuleCapabilities.md](../../Metadata/UsageSkills/toolbelt_metadata/VW_ModuleCapabilities.md).

<!-- Source/Vertrag SHA256: 4db9e3bfa8d1a8f2d67ffdbed1cb5ddebd8606e8bbcf5e7f84e9d3f58cf0aa19 -->

Voraussetzung: Installierte markerfreie View auf SQL2019/2022/2025 Windows/Linux, lokal oder zentral mit dem zulässigen Compatibility Level. Keine Runtime-Modulabhängigkeit und kein CLR-Aufruf. Der Generator liest beim Offlinebuild alle module.yaml-Dateien deterministisch und erzeugt feste Kandidatentupel ModuleId/qualifizierter Name/zulässige SQL-Objekttypen. Assemblies aus expliziten Deklarationen; bei einem Modul ohne Objekte Fallback auf dessen deklarierten CLR-Assemblynamen. Toolbelt-Assemblyalias tlblt_, bereits tlblt-Namen erhalten; private ScriptDom-Alias tlblt.Microsoft.SqlServer.TransactSql.ScriptDom. Unbekannte Manifestformen/Objekttypen oder Assemblyaliasformen brechen den Build ab, keine automatische Runtime-Discovery.

Keine Eingabeparameter.

```sql
SELECT ModuleId,ModuleVersion,DeploymentMode,MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;

SELECT ModuleId,MetadataStatus
FROM ContosoToolbelt.toolbelt_metadata.VW_ModuleCapabilities
WHERE ModuleId=N'toolbelt.metadata.identifier';
-- Eine Zeile bedeutet nur: mindestens ein sichtbarer namens-/typgleicher Kandidat.
```

## toolbelt_metadata.VW_ObjectUsageSkills

Modul `toolbelt.metadata.capability-catalog` · Version `1.0.0` · `VW`

Bekannte Toolbelt-Objekte und ihre vollständigen maschinenlesbaren Usage-Skills lesen.

Vertrag und Quelle: [VW_ObjectUsageSkills.sql](../../Modules/toolbelt.metadata.capability-catalog/Source/VW_ObjectUsageSkills.sql), [VW_ObjectUsageSkills.md](../../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md), [VW_ObjectUsageSkills.md](../../Metadata/UsageSkills/toolbelt_metadata/VW_ObjectUsageSkills.md).

<!-- Source/Vertrag SHA256: 5e3d3ff419e8dcbbbb4bb2a90159cc517f61ce23b69842ab5bc4d13c8f99d5be -->

Voraussetzung: Neue Skill-Sicht im gewählten Ziel verfügbar und vorhandenes SELECT-Recht. Die Einträge sind konstante bekannte Beschreibungen und bestätigen weder Installation noch aktuelle Objektdefinition oder Ausführungsrechte. DatabaseRole bezeichnet eine logische Projektrolle, keinen fest kodierten Datenbanknamen. Gesamt- und Teilprofile desselben Quellstands enthalten denselben vollständigen Katalog einschließlich nicht ausgewählter Module.

Keine Eingabeparameter.

```sql
SELECT SchemaName,ObjectName,ObjectType,DatabaseRole,IsInternal,Description
FROM toolbelt_metadata.VW_ObjectUsageSkills
ORDER BY DatabaseRole,SchemaName,ObjectName;

SELECT SkillMarkdown
FROM toolbelt_metadata.VW_ObjectUsageSkills
WHERE DatabaseRole=N'toolbelt'
  AND SchemaName=N'toolbelt_conversion'
  AND ObjectName=N'TVF_Base64Encode';
```

## toolbelt_metadata.TVF_ParseMultipartName

Modul `toolbelt.metadata.identifier` · Version `1.0.0` · `TVF`

Zerlegt und validiert ein- bis vierteilige SQL-Identifier.

Vertrag und Quelle: [TVF_ParseMultipartName.sql](../../Modules/toolbelt.metadata.identifier/Source/TVF_ParseMultipartName.sql), [TVF_ParseMultipartName.md](../../Modules/toolbelt.metadata.identifier/Documentation/TVF_ParseMultipartName.md), [TVF_ParseMultipartName.md](../../Metadata/UsageSkills/toolbelt_metadata/TVF_ParseMultipartName.md).

<!-- Source/Vertrag SHA256: 2bf2576b2b158b70a6889fb87ebd25a268d36098cf4bf05522163546cb1e902d -->

Voraussetzung: Identifier-Modul, Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Rein lokale Stringverarbeitung, keine Objekt-/Datenbank-/Serverauflösung oder Metadatensicht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 UTF16-Codeeinheiten. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. ASCII-Delimiter werden binär erkannt, escaped ]] wird einmal zurückgenommen. Gequotete Spaces einschließlich [ ] sind Inhalt, keine Auslassung; Spaces vor einer öffnenden Klammer sind BRACKET_SYNTAX. Parameterbindung auf1035Codeeinheiten liegt vor der Funktion und kann längere Callerwerte kürzen; ursprüngliche Länge bei Bedarf vorher im Client/max-Typ prüfen. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ContosoDb]..[Order]]Line]');
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.ContosoSource');
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ ]');
```

## toolbelt_metadata.SVF_QuoteMultipartName

Modul `toolbelt.metadata.identifier` · Version `1.0.0` · `SVF`

Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten.

Vertrag und Quelle: [SVF_QuoteMultipartName.sql](../../Modules/toolbelt.metadata.identifier/Source/SVF_QuoteMultipartName.sql), [SVF_QuoteMultipartName.md](../../Modules/toolbelt.metadata.identifier/Documentation/SVF_QuoteMultipartName.md), [SVF_QuoteMultipartName.md](../../Metadata/UsageSkills/toolbelt_metadata/SVF_QuoteMultipartName.md).

<!-- Source/Vertrag SHA256: fe3237a7b25ff5604c9f1cf4ce20e2724348e8cd1d03ad74f005599e5a5c5b7f -->

Voraussetzung: Identifier-Modul, Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Rein lokale Stringverarbeitung, keine Objekt-/Datenbank-/Serverauflösung oder Metadatensicht.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 UTF16-Codeeinheiten. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. ASCII-Delimiter werden binär erkannt, escaped ]] wird einmal zurückgenommen. Gequotete Spaces einschließlich [ ] sind Inhalt, keine Auslassung; Spaces vor einer öffnenden Klammer sind BRACKET_SYNTAX. Parameterbindung auf1035Codeeinheiten liegt vor der Funktion und kann längere Callerwerte kürzen; ursprüngliche Länge bei Bedarf vorher im Client/max-Typ prüfen. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ContosoDb]..[Order]]Line]');
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.ContosoSource');
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ ]');
```

## toolbelt_metadata.USP_ScriptTableClone

Modul `toolbelt.metadata.table-clone` · Version `4.1.1` · `USP`

Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.

Vertrag und Quelle: [USP_ScriptTableClone.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql), [USP_ScriptTableClone.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md), [USP_ScriptTableClone.md](../../Metadata/UsageSkills/toolbelt_metadata/USP_ScriptTableClone.md).

<!-- Source/Vertrag SHA256: 366afd87530ef3b804438bc299a13ce258550da59fd537a611a9ca1e923fd323 -->

Voraussetzung: Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
-- Vorhandene synthetische Quelle und freies Ziel in dieser DB vorausgesetzt.
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'ContosoSource',
 @TargetSchema=N'dbo',@TargetTable=N'ContosoClone';
```

Hilfe:

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
```

## toolbelt_metadata.USP_ExecuteTableClone

Modul `toolbelt.metadata.table-clone` · Version `4.1.1` · `USP`

Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie.

Vertrag und Quelle: [USP_ExecuteTableClone.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_ExecuteTableClone.sql), [USP_ExecuteTableClone.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ExecuteTableClone.md), [USP_ExecuteTableClone.md](../../Metadata/UsageSkills/toolbelt_metadata/USP_ExecuteTableClone.md).

<!-- Source/Vertrag SHA256: dfee7ade70bd33ebd233cc4040fe8a4261b3f70469a87630f0ec8f64ce568549 -->

Voraussetzung: Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.

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
| `@ExpectedPlanHash` | `varbinary(max)` | `NULL` | Input | Fachlich erforderliche exakt 32 Bytes varbinary des SHA256-Planhashes aus dem dokumentierten Hashlayout1 für Modul4.1.1. Aus unveränderten triggerfreien Vorschauzeilen, exakten Optionen und Installationsdatenbankidentität gemäß TABLE_CLONE_EXECUTE_CONTRACT.md/Examples/CalculatePlanHash.py berechnen. Kein Hextext ohne Konvertierung, kein Hash allein des Scripttexts. NULL/falsche Länge ungültig, Abweichung vom frisch erzeugten Plan bricht ab. |
| `@ForeignKeyMode` | `varchar(16)` | `'CREATE'` | Input | Taxativ, bytegenau ohne Trim/Casefold: CREATE (Default) führt alle fachlichen Planzeilen einschließlich FKs/Zustände aus; DEFER überspringt ausschließlich FOREIGN_KEY und FOREIGN_KEY_STATE für spätere Datenkopie. Beide Zeilenarten bleiben im vollständigen Planhash. NULL/andere Werte ungültig; bestehende Constraints werden nicht deaktiviert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Der Executor plant intern ausdrücklich mit Debug=0 und erzeugt keine eigenen zusätzlichen Diagnosemessages; bei ResultTable wird der übergebene Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_metadata.USP_ExecuteTableClone @Hilfe=1;
-- Client muss exakten Hash aus unveränderter Vorschau und tatsächlichem DB-Kontext binden.
DECLARE @AcceptedPlanHash varbinary(max)=NULL;
-- NULL vor Fachaufruf durch die berechneten32Bytes ersetzen; sonst bewusst Fehler.
EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'ContosoSource',
 @TargetSchema=N'dbo',@TargetTable=N'ContosoClone',@ExpectedPlanHash=@AcceptedPlanHash;
```

Hilfe:

```sql
EXEC toolbelt_metadata.USP_ExecuteTableClone @Hilfe=1;
```

## toolbelt_metadata.USP_CopyTableCloneData

Modul `toolbelt.metadata.table-clone` · Version `4.1.1` · `USP`

Kopiert einen begrenzten SameDB-Tabellenverbund atomar in bereits vorhandene leere formgleiche Ziele; keine Strukturkopie oder Rechtevergabe.

Vertrag und Quelle: [USP_CopyTableCloneData.sql](../../Modules/toolbelt.metadata.table-clone/Source/USP_CopyTableCloneData.sql), [USP_CopyTableCloneData.md](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_CopyTableCloneData.md), [USP_CopyTableCloneData.md](../../Metadata/UsageSkills/toolbelt_metadata/USP_CopyTableCloneData.md).

<!-- Source/Vertrag SHA256: 125f2fd512045cb62a6a719afb14433798d9e7676fdd6e5be5ff8bc835d514e3 -->

Voraussetzung: Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@TableMap` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Fachlich erforderlich, NULL ungültig. Hier müssen die fünf Spalten zusätzlich exakt in der genannten Reihenfolge und ohne IDENTITY stehen. Source und Target müssen beide existieren, formgleich und als Mengen von ObjectIDs disjunkt sein; jedes Ziel muss leer sein. Keine Filter/Upserts/CrossDB oder impliziten Typkonvertierungen. |
| `@IdentityMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: KEEP kopiert Identitywerte unter vorhandenen erforderlichen Rechten; REGENERATE lässt Identityspalten beim Transport weg und erzeugt neue Zielwerte. REGENERATE ist bei identityabhängigen Beziehungen ausgeschlossen. NULL/leer/andere Werte ungültig. Keine neue ID-Zuordnung/RESEED; Identity-Zählerfortschritt kann trotz Rollback bleiben. |
| `@ConsistencyMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: SNAPSHOT verwendet die bereits aktivierte Datenbankoption; SERIALIZABLE hält Quellbereichssperren. NULL/leer/andere Werte ungültig. Keine automatische Optionsänderung; aktive Callertransaktion wird abgelehnt. SERIALIZABLE verwendet TABLOCK/HOLDLOCK an Quellen; Ziele werden unabhängig vom Quellmodus mit TABLOCKX/UPDLOCK/HOLDLOCK gesperrt. Isolations-/SET-Änderungen bleiben im Prozedurscope. |
| `@RowLimit` | `bigint` | `100000` | Input | Ganzzahl 1..100000 global kopierte Zeilen über alle gemappten Tabellen, Default 100000. NULL/außerhalb ungültig; Überschreitung verhindert die gesamte Kopie, kein TOP-Teilimport. |
| `@PayloadByteLimit` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes globaler tatsächlich transportierter SQL-Nutzdaten, Default 16777216. Summe bigint-DATALENGTH, NULL zählt 0; computed/rowversion und bei REGENERATE Identity zählen nicht. Kein Gesamt-Heap-/Dateigrößenbudget; NULL/außerhalb ungültig. Gezählt wird SUM(DATALENGTH) nur tatsächlich transportierter Sourcefelder; NULL zählt0, Computed/rowversion und bei REGENERATE Identity bleiben außerhalb. Kein Heap-, Log-, Index-, Versionstore- oder physischer Tabellenbytes-Nachweis. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht TableMap. Die späte ResultTable-Ausgabe ist Teil derselben eigenen Transaktion wie Kopie/FK-DDL. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Aktuell keine eigenen zusätzlichen Copy-Diagnosemessages; bei ResultTable wird der Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_metadata.USP_CopyTableCloneData @Hilfe=1;
CREATE TABLE #ContosoMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,
 SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #ContosoMap VALUES(1,N'dbo',N'ContosoSource',N'dbo',N'ContosoClone');
-- Bestehendes leeres formgleiches Ziel, vorhandene Rechte vorausgesetzt; ändert Daten.
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#ContosoMap',
 @IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@RowLimit=1000,@PayloadByteLimit=1048576;
DROP TABLE #ContosoMap;
```

Hilfe:

```sql
EXEC toolbelt_metadata.USP_CopyTableCloneData @Hilfe=1;
```

## toolbelt_pseudonymization.TVF_DeterministicGeoJitter

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius.

Vertrag und Quelle: [DeterministicGeoJitter.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicGeoJitter.sql), [TVF_DeterministicGeoJitter.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicGeoJitter.md), [TVF_DeterministicGeoJitter.md](../../Metadata/UsageSkills/toolbelt_pseudonymization/TVF_DeterministicGeoJitter.md).

<!-- Source/Vertrag SHA256: 03156c5506e2abd41f000c85d699681b72d926821575b3fe9d396df7b989bbf7 -->

Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `geography` | `kein Default` | Input | Gültiger nicht leerer zweidimensionaler geography-Point mit SRID 4326, ohne Z/M, serialisierte Größe höchstens 128 Bytes; keine Linien/Polygone/anderen SRIDs. Beispielsweise geography::Point(48.2,16.3,4326). Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Fehlern; ungeeignete Geometrie Code 15. Ausgabe ist ein deterministisch versetzter Punkt, kein Anonymisierungsnachweis. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@RadiusMeters` | `int` | `100` | Input | Ganzzahl 1..10000 Meter, Default 100. Obergrenze des radialen Jitters; Richtung und flächentreuer Radius werden aus dem Mappingkontext abgeleitet. NULL/0/negativ/größer ergibt Code 14. Keine Nullverschiebungsoption mit Radius 0. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
DECLARE @Point geography=geography::Point(0,0,4326);
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(@Point,0x010203,1,0,100);
```

## toolbelt_pseudonymization.TVF_DeterministicTranslate

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung.

Vertrag und Quelle: [DeterministicTranslate.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicTranslate.sql), [TVF_DeterministicTranslate.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicTranslate.md), [TVF_DeterministicTranslate.md](../../Metadata/UsageSkills/toolbelt_pseudonymization/TVF_DeterministicTranslate.md).

<!-- Source/Vertrag SHA256: 79f9b691aabb657f13d9096d6fa7f8053e6795fbbae6c7f99890dbcd272e971b -->

Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Kennung: Buchstaben a-z/A-Z und Ziffern 0-9 werden bijektiv substituiert, ausdrücklich erlaubte Separatoren bleiben unverändert. Leer ist gültig; NULL ergibt NULL/Code 0 vor jeder Konfigurationsprüfung. Kein Trim/Unicode-Transliterieren; Akzente, NUL, Controls, DEL und Surrogate ergeben Code 13. Bytebudget durch Profile, Output exakt gleiche Länge. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@AllowedSeparators` | `nvarchar(max)` | `N''` | Input | Explizite Menge von höchstens 33 verschiedenen druckbaren ASCII-Nichtalnum-Zeichen aus Codes 32..126, z.B. N'-/ '; jedes bleibt unverändert. Leer (Default) erlaubt keine Separatoren. Duplikate, Buchstaben/Ziffern, Controls/NUL/DEL/Unicode und NULL ergeben Code 11; trailing Spaces sind relevant. Keine mehrzeichige Separatorgrammatik. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, bytegenau ohne Trim: standard (Default) = höchstens 2097152 UTF-16-Inputbytes; large = höchstens 16777216. NULL/leer/andere Schreibweisen ergeben Code 10; Überschreitung Code 12. Profil ändert nur das Budget, nicht die Mappingpermutation. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'Contoso-123',1,0,N'-',N'standard');
```

## toolbelt_pseudonymization.TVF_DeterministicRange

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu.

Vertrag und Quelle: [TVF_DeterministicRange.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRange.sql), [TVF_DeterministicRange.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicRange.md), [TVF_DeterministicRange.md](../../Metadata/UsageSkills/toolbelt_pseudonymization/TVF_DeterministicRange.md).

<!-- Source/Vertrag SHA256: db972e88cb6d5dc51706d6d9ffc3aa90532b80c128466c1ca37ac45241d3f9cb -->

Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@Min` | `bigint` | `kein Default` | Input | Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und &lt;=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen. |
| `@Max` | `bigint` | `kein Default` | Input | Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und &gt;=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203,1,0,-10,10);
```

## toolbelt_pseudonymization.TVF_DeterministicDateShift

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `TVF`

Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage.

Vertrag und Quelle: [TVF_DeterministicDateShift.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicDateShift.sql), [TVF_DeterministicDateShift.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicDateShift.md), [TVF_DeterministicDateShift.md](../../Metadata/UsageSkills/toolbelt_pseudonymization/TVF_DeterministicDateShift.md).

<!-- Source/Vertrag SHA256: 1bd5e0a92aee11e70b615ded8474e4ca9b0596fd4462386baaeff56dc0d22f80 -->

Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `datetime2(7)` | `kein Default` | Input | datetime2(7) im nativen Bereich 0001-01-01..9999-12-31; Uhrzeit/Präzision bleiben beim ganzzahligen Tagesoffset erhalten. Keine Zeitzone/DST-Konvertierung. Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Konfigurationsfehlern. Überlauf des gezogenen Offsets ergibt Code 8, kein Clamp/Wrap. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@MaxDays` | `int` | `365` | Input | Ganzzahl 0..3652058 Tage, Default 365. Offset wird deterministisch aus dem geschlossenen Intervall [-MaxDays,+MaxDays] gewählt; 0 lässt das Datum unverändert. NULL/außerhalb ergibt Code 7; Datumsoverflow wird zusätzlich geprüft. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2026-01-15T12:34:56'),0x010203,1,0,30);
```

## toolbelt_pseudonymization.USP_DeterministicLookup

Modul `toolbelt.pseudonymization.deterministic` · Version `1.2.0` · `USP`

Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.

Vertrag und Quelle: [USP_DeterministicLookup.sql](../../Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookup.sql), [USP_DeterministicLookup.md](../../Modules/toolbelt.pseudonymization.deterministic/Documentation/USP_DeterministicLookup.md), [USP_DeterministicLookup.md](../../Metadata/UsageSkills/toolbelt_pseudonymization/USP_DeterministicLookup.md).

<!-- Source/Vertrag SHA256: 31e659e5ce104aa2aa4174ef5e095ef03e96bf80b145db65ba7f07b54a7336ef -->

Voraussetzung: Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Eigene Caller-Temps ohne parallele Mutation; Fassade vor Core verwenden. Ein gesunder Caller-TX mit Savepoint ist möglich. Kein eigener Reparaturvertrag für doomed Caller-TX.

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
CREATE TABLE #ContosoInput(Ordinal bigint,[Key] varbinary(max));
CREATE TABLE #ContosoPool(Ordinal bigint,[Value] nvarchar(max));
INSERT #ContosoInput VALUES(1,0x010203),(2,NULL);
INSERT #ContosoPool VALUES(10,N'Contoso alpha'),(30,N'Contoso beta');
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#ContosoInput',@LookupTable=N'#ContosoPool',@MappingVersion=1,@LookupVersion=1;
DROP TABLE #ContosoInput;DROP TABLE #ContosoPool;
```

Hilfe:

```sql
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
```

## toolbelt_string.TVF_TrimDirectionalNvarchar

Modul `toolbelt.string.directional-trim` · Version `1.0.0` · `TVF`

Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text.

Vertrag und Quelle: [TVF_TrimDirectionalNvarchar.sql](../../Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalNvarchar.sql), [TVF_TrimDirectionalNvarchar.md](../../Modules/toolbelt.string.directional-trim/Documentation/TVF_TrimDirectionalNvarchar.md), [TVF_TrimDirectionalNvarchar.md](../../Metadata/UsageSkills/toolbelt_string/TVF_TrimDirectionalNvarchar.md).

<!-- Source/Vertrag SHA256: 8c9adda9915d29098e6d557d15df8d52bc781556c7d7bc5ba498df67dc19ebef -->

Voraussetzung: Directionaltrim-Modul und kanonische mathematische TVF_GenerateSeriesBigInt derselben Installationsdatenbank. Windows/Linux SQL2019/2022/2025, zulässigeCL150/160/170. Installationscollation/Codepage bestimmen den Zeichenvergleich, kein dynamischer Caller-Collationvertrag.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max). SUBSTRING/CHARINDEX und NUL-Probe verwenden dieselben Zeichenpositionen der Installationscollation; SC zählt Supplementaryzeichen zusammen. Die obere Seriengrenze ist physisch DATALENGTH/2 bei nvarchar beziehungsweise DATALENGTH bei varchar und kann mehr Positionen als tatsächliche Zeichen enthalten. Leere Positionen jenseits des letzten Zeichens werden bei der Grenzsuche übersprungen. Leer bleibt leer, NULL ergibt NULL; keine dynamische Caller-Collation. NUL wird nicht entfernt. |
| `@Characters` | `nvarchar(4000)` | `N' '` | Input | Bis 4000 UTF-16-Codeeinheiten als nvarchar(4000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N' xxContoso-123xx ',N' x','BOTH');
```

## toolbelt_string.TVF_TrimDirectionalVarchar

Modul `toolbelt.string.directional-trim` · Version `1.0.0` · `TVF`

Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem varchar-Text.

Vertrag und Quelle: [TVF_TrimDirectionalVarchar.sql](../../Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalVarchar.sql), [TVF_TrimDirectionalVarchar.md](../../Modules/toolbelt.string.directional-trim/Documentation/TVF_TrimDirectionalVarchar.md), [TVF_TrimDirectionalVarchar.md](../../Metadata/UsageSkills/toolbelt_string/TVF_TrimDirectionalVarchar.md).

<!-- Source/Vertrag SHA256: 57867404e700720680fe7b15e95b7888985524afcfa752893f201c16baf0d0e0 -->

Voraussetzung: Directionaltrim-Modul und kanonische mathematische TVF_GenerateSeriesBigInt derselben Installationsdatenbank. Windows/Linux SQL2019/2022/2025, zulässigeCL150/160/170. Installationscollation/Codepage bestimmen den Zeichenvergleich, kein dynamischer Caller-Collationvertrag.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Text als varchar(max) unter der Installationscodepage einschließlich gegebenenfalls UTF8. SUBSTRING/CHARINDEX und NUL-Probe verwenden dieselben Zeichenpositionen der Installationscollation; SC zählt Supplementaryzeichen zusammen. Die obere Seriengrenze ist physisch DATALENGTH/2 bei nvarchar beziehungsweise DATALENGTH bei varchar und kann mehr Positionen als tatsächliche Zeichen enthalten. Leere Positionen jenseits des letzten Zeichens werden bei der Grenzsuche übersprungen. Leer bleibt leer, NULL ergibt NULL; keine dynamische Caller-Collation. NUL wird nicht entfernt. |
| `@Characters` | `varchar(8000)` | `' '` | Input | Bis 8000 Bytes als varchar(8000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalVarchar(' xxContoso-123xx ',' x','BOTH');
```

## toolbelt_string.TVF_JaroWinklerSimilarity

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Begrenzte symmetrische Unicode-Skalar-Jaro-Winkler-Ähnlichkeit.

Vertrag und Quelle: [JaroWinkler.sql](../../Modules/toolbelt.string.edit-distance/Source/JaroWinkler.sql), [TVF_JaroWinklerSimilarity.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_JaroWinklerSimilarity.md), [TVF_JaroWinklerSimilarity.md](../../Metadata/UsageSkills/toolbelt_string/TVF_JaroWinklerSimilarity.md).

<!-- Source/Vertrag SHA256: 5c0c4791fcfae9fa1224e31b2939199bbc41044413dbdebe8d885c93639b4d64 -->

Voraussetzung: Installiertes Modul und passende SAFE-Assembly tlblt_String_EditDistance auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux; lokaler/zentraler Aufruf gemäß Modulvertrag. CLR muss bereits gültig konfiguriert und autorisiert sein. Kein Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Vergleichskern, keine nachgeladene Library oder Runtime-Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, keine andere Schreibweise und kein Trim. standard: je Text maximal 2048 UTF-16-Codeunits und 1024 Skalare, maximal 1048576 geplante Arbeitseinheiten. large: 65536 Codeunits, 32768 Skalare, 16777216 Arbeitseinheiten. NULL/leer/unbekannt liefert Code 1, außer beim früheren NULL-Textpfad. Im SQL-Funktionsaufruf bei vorhandenem Default das Argument ausdrücklich als DEFAULT angeben statt seine Position wegzulassen. SQL-Default standard. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'MARTHA',N'MARHTA',N'standard');
-- Similarity ungefähr 0.961111; ErrorCode=0.
-- Für Profil-/Schwellen-Defaults die Position mit DEFAULT belegen.
```

## toolbelt_string.TVF_LevenshteinDistance

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Begrenzte Unicode-Skalar-Levenshtein-Distanz mit optionalem Schwellennachweis.

Vertrag und Quelle: [EditDistance.sql](../../Modules/toolbelt.string.edit-distance/Source/EditDistance.sql), [TVF_LevenshteinDistance.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_LevenshteinDistance.md), [TVF_LevenshteinDistance.md](../../Metadata/UsageSkills/toolbelt_string/TVF_LevenshteinDistance.md).

<!-- Source/Vertrag SHA256: 2a6a15dd21cf972dffc94bc3bb99b61786894b1a7f19f315e130bb4df016340b -->

Voraussetzung: Installiertes Modul und passende SAFE-Assembly tlblt_String_EditDistance auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux; lokaler/zentraler Aufruf gemäß Modulvertrag. CLR muss bereits gültig konfiguriert und autorisiert sein. Kein Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Vergleichskern, keine nachgeladene Library oder Runtime-Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@MaxDistance` | `int` | `NULL` | Input | int-Schwelle: NULL bedeutet vollständige Distanz, nichtnegativ bis 2147483647 begrenzt die gesuchte Distanz; negativ ergibt Code 2 nach Profilprüfung, außer beim frühen NULL-Textpfad. Überschreitung ist ExceedsMaxDistance=1 bei Distance=NULL und Code 0, kein exakter Abstand. Vor DP kann bereits die Skalarlängendifferenz die Überschreitung beweisen. Bei vorhandenem SQL-Default ausdrücklich DEFAULT oder NULL übergeben. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, keine andere Schreibweise und kein Trim. standard: je Text maximal 2048 UTF-16-Codeunits und 1024 Skalare, maximal 1048576 geplante Arbeitseinheiten. large: 65536 Codeunits, 32768 Skalare, 16777216 Arbeitseinheiten. NULL/leer/unbekannt liefert Code 1, außer beim früheren NULL-Textpfad. Im SQL-Funktionsaufruf bei vorhandenem Default das Argument ausdrücklich als DEFAULT angeben statt seine Position wegzulassen. SQL-Default standard. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten',N'sitting',NULL,N'standard');
-- Distance=3, ExceedsMaxDistance=0, ErrorCode=0.
-- Für Profil-/Schwellen-Defaults die Position mit DEFAULT belegen.
```

## toolbelt_string.TVF_OsaDistance

Modul `toolbelt.string.edit-distance` · Version `1.1.0` · `TVF`

Begrenzte Unicode-Skalar-OSA-Distanz mit optionalem Schwellennachweis.

Vertrag und Quelle: [EditDistance.sql](../../Modules/toolbelt.string.edit-distance/Source/EditDistance.sql), [TVF_OsaDistance.md](../../Modules/toolbelt.string.edit-distance/Documentation/TVF_OsaDistance.md), [TVF_OsaDistance.md](../../Metadata/UsageSkills/toolbelt_string/TVF_OsaDistance.md).

<!-- Source/Vertrag SHA256: 57910b6d2b45913c4f635015abf43c5a970f341d20da581b960b8275ee649bf3 -->

Voraussetzung: Installiertes Modul und passende SAFE-Assembly tlblt_String_EditDistance auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux; lokaler/zentraler Aufruf gemäß Modulvertrag. CLR muss bereits gültig konfiguriert und autorisiert sein. Kein Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Vergleichskern, keine nachgeladene Library oder Runtime-Rechtevergabe.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@MaxDistance` | `int` | `NULL` | Input | int-Schwelle: NULL bedeutet vollständige Distanz, nichtnegativ bis 2147483647 begrenzt die gesuchte Distanz; negativ ergibt Code 2 nach Profilprüfung, außer beim frühen NULL-Textpfad. Überschreitung ist ExceedsMaxDistance=1 bei Distance=NULL und Code 0, kein exakter Abstand. Vor DP kann bereits die Skalarlängendifferenz die Überschreitung beweisen. Bei vorhandenem SQL-Default ausdrücklich DEFAULT oder NULL übergeben. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, keine andere Schreibweise und kein Trim. standard: je Text maximal 2048 UTF-16-Codeunits und 1024 Skalare, maximal 1048576 geplante Arbeitseinheiten. large: 65536 Codeunits, 32768 Skalare, 16777216 Arbeitseinheiten. NULL/leer/unbekannt liefert Code 1, außer beim früheren NULL-Textpfad. Im SQL-Funktionsaufruf bei vorhandenem Default das Argument ausdrücklich als DEFAULT angeben statt seine Position wegzulassen. SQL-Default standard. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'ab',N'ba',NULL,N'standard');
-- OSA-Distance=1.
-- Für Profil-/Schwellen-Defaults die Position mit DEFAULT belegen.
```

## toolbelt_string.TVF_ColognePhonetic

Modul `toolbelt.string.phonetic` · Version `1.0.0` · `TVF`

Vollständiger begrenzter Kölner Phonetikcode mit geschlossenem Alphabet.

Vertrag und Quelle: [TVF_ColognePhonetic.sql](../../Modules/toolbelt.string.phonetic/Source/TVF_ColognePhonetic.sql), [TVF_ColognePhonetic.md](../../Modules/toolbelt.string.phonetic/Documentation/TVF_ColognePhonetic.md), [TVF_ColognePhonetic.md](../../Metadata/UsageSkills/toolbelt_string/TVF_ColognePhonetic.md).

<!-- Source/Vertrag SHA256: 571ed7b593b9cf62a3bb54d6ebf5021db150911266adea798aae75a4c6caf6a9 -->

Voraussetzung: Installiertes Modul mit passender autorisierter SAFE-Assembly tlblt_String_Phonetic, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, lokal oder zentral. Keine Abhängigkeit von Distanz-/Jaro-Assembly, Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Scanner. Der markierte Scannerport und sein Herkunfts-/Lizenzvertrag bleiben unverändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Unicode-Rohtext mit höchstens 4096 UTF-16-Codeunits vor jeder eigenen Textkopie. NULL liefert NULL-Code(s) und ErrorCode=0, leerer Text ist gültig und liefert leere Codes. Ungültige Surrogatfolge ergibt Code 1, Größenquote Code 2, Zeichen außerhalb des geschlossenen Alphabets Code 3. Ein gültiges Supplementary-Paar bleibt dennoch außerhalb dieses Alphabets und ergibt Code 3. Zusätzlich zu ASCII U+0000..U+007F ausschließlich ÄÖÜäöüß. ASCII a..z wird zu A..Z, Umlaute zu A/O/U, ß zu SS. Kein globales Trimmen; Satz-/Kontrollzeichen bleiben im Buchstabenkontext und können den Lookahead beeinflussen. Kein SQL-Default; Argument ausdrücklich übergeben. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'PH');
-- PhoneticCode=3, ErrorCode=0.
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(NULL);
-- Genau eine NULL-Codezeile mit ErrorCode=0.
```

## toolbelt_string.TVF_DoubleMetaphone

Modul `toolbelt.string.phonetic` · Version `1.0.0` · `TVF`

Vollständige begrenzte primäre und alternative Double-Metaphone-Codes.

Vertrag und Quelle: [TVF_DoubleMetaphone.sql](../../Modules/toolbelt.string.phonetic/Source/TVF_DoubleMetaphone.sql), [TVF_DoubleMetaphone.md](../../Modules/toolbelt.string.phonetic/Documentation/TVF_DoubleMetaphone.md), [TVF_DoubleMetaphone.md](../../Metadata/UsageSkills/toolbelt_string/TVF_DoubleMetaphone.md).

<!-- Source/Vertrag SHA256: 02c161850019374ee41ed9a01cfe09c1bd2a7d29524dc1049f00a15ad2a0de04 -->

Voraussetzung: Installiertes Modul mit passender autorisierter SAFE-Assembly tlblt_String_Phonetic, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, lokal oder zentral. Keine Abhängigkeit von Distanz-/Jaro-Assembly, Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Scanner. Der markierte Scannerport und sein Herkunfts-/Lizenzvertrag bleiben unverändert.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Unicode-Rohtext mit höchstens 4096 UTF-16-Codeunits vor jeder eigenen Textkopie. NULL liefert NULL-Code(s) und ErrorCode=0, leerer Text ist gültig und liefert leere Codes. Ungültige Surrogatfolge ergibt Code 1, Größenquote Code 2, Zeichen außerhalb des geschlossenen Alphabets Code 3. Ein gültiges Supplementary-Paar bleibt dennoch außerhalb dieses Alphabets und ergibt Code 3. Zusätzlich zu ASCII U+0000..U+007F ausschließlich ÇçÑñ. ASCII a..z wird zu A..Z, ç/ñ zu Ç/Ñ. Vor dem Scanner werden äußere ASCII-Codeunits &lt;=U+0020 entfernt; innere Kontroll-/Satzzeichen bleiben im Kontext. Keine allgemeine Culture- oder Unicode-Normalisierung. Kein SQL-Default; Argument ausdrücklich übergeben. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'PH');
-- PrimaryCode=F, AlternateCode=F, ErrorCode=0.
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(NULL);
-- Genau eine NULL-Codezeile mit ErrorCode=0.
```

## toolbelt_string.TVF_RegexCaptures

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Materialisiert alle Wiederholungen deklarierter Capturegruppen und Kontrollzeilen unbeteiligter Gruppen.

Vertrag und Quelle: [RegexCaptures.sql](../../Modules/toolbelt.string.regex/Source/RegexCaptures.sql), [TVF_RegexCaptures.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexCaptures.md), [TVF_RegexCaptures.md](../../Metadata/UsageSkills/toolbelt_string/TVF_RegexCaptures.md).

<!-- Source/Vertrag SHA256: d8ebbfc36ce0d66d7fc9b0b57955e08748372f22838ad6038a85c9aac7645cf4 -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Normale und (?&lt;Name&gt;...)-Captures zulässig, maximal64 Gruppen; Name1..128 ASCII-Zeichen, BeginnA-Z/a-z/_, danach zusätzlichZiffern, keine ordinal-case-insensitiven Duplikate. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt jede Capture und auch Kontrollzeilen nicht beteiligter Gruppen. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_RegexCaptures(N'abab',N'(ab)+',1,N'c',N'standard',10000) ORDER BY MatchOrdinal,GroupOrdinal,CaptureOrdinal;
```

## toolbelt_string.SVF_RegexReplaceGroups

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Ersetzt Gesamttreffer mit streng geprüften numerischen oder benannten Gruppenreferenzen.

Vertrag und Quelle: [RegexCaptures.sql](../../Modules/toolbelt.string.regex/Source/RegexCaptures.sql), [SVF_RegexReplaceGroups.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexReplaceGroups.md), [SVF_RegexReplaceGroups.md](../../Metadata/UsageSkills/toolbelt_string/SVF_RegexReplaceGroups.md).

<!-- Source/Vertrag SHA256: 7da2fcaac5f30f02087bfda3fe65230bce353b188f1ea6e7c90098b0701edce0 -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Normale und (?&lt;Name&gt;...)-Captures zulässig, maximal64 Gruppen; Name1..128 ASCII-Zeichen, BeginnA-Z/a-z/_, danach zusätzlichZiffern, keine ordinal-case-insensitiven Duplikate. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Strikter Ersatz: $N für eine existierende positive vollständige ASCII-Gruppennummer ohne führende0, ${Name} nur für exakt case-sensitiv passenden expliziten Namen, $$ für ein Dollarzeichen. Backslash bleibt literal. $0,unbekannte/beschädigte Referenzen und einzelneDollarzeichen sind Fehler vor erster Suche; erzeugteDollarzeichen werden nicht erneut interpretiert. Verwendet den letzten erfolgreichen Capture, unbeteiligte Gruppe wird leer. Höchstens65536 geparste Ersatzteile. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Occurrence` | `int` | `0` | Input | 0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexReplaceGroups(N'Contoso42',N'(?<word>[A-Za-z]+)([0-9]+)',N'${word}:$2:$$',1,0,N'c',N'standard') AS Replaced;
```

## toolbelt_string.TVF_RegexMatches

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Materialisiert nicht überlappende Gesamttreffer mit Position, Länge und Originaltext.

Vertrag und Quelle: [RegexRelations.sql](../../Modules/toolbelt.string.regex/Source/RegexRelations.sql), [TVF_RegexMatches.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexMatches.md), [TVF_RegexMatches.md](../../Metadata/UsageSkills/toolbelt_string/TVF_RegexMatches.md).

<!-- Source/Vertrag SHA256: 5e947df6bf2165e14d602b1e4c7eb4a3c7c5d735db10015a851357875357aca3 -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt Gesamttreffer beziehungsweise sämtliche Splittokens einschließlich Leertokens. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_RegexMatches(N'a1b22',N'\d+',1,N'c',N'standard',10000) ORDER BY Ordinal;
```

## toolbelt_string.TVF_RegexSplit

Modul `toolbelt.string.regex` · Version `1.3.0` · `TVF`

Zerlegt den ganzen Input an Regexseparatoren in Originaltokens einschließlich Leertokens.

Vertrag und Quelle: [RegexRelations.sql](../../Modules/toolbelt.string.regex/Source/RegexRelations.sql), [TVF_RegexSplit.md](../../Modules/toolbelt.string.regex/Documentation/TVF_RegexSplit.md), [TVF_RegexSplit.md](../../Metadata/UsageSkills/toolbelt_string/TVF_RegexSplit.md).

<!-- Source/Vertrag SHA256: 9f716e71b216188dfd0a68cbcf6d945a8e383db9db5b011d49c03af7aeed2534 -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt Gesamttreffer beziehungsweise sämtliche Splittokens einschließlich Leertokens. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_RegexSplit(N'a,,b,',N',',N'c',N'standard',10000) ORDER BY Ordinal;
```

## toolbelt_string.SVF_RegexIsMatch

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Prüft im begrenzten Toolbelt-Regexdialekt, ob mindestens ein Gesamttreffer existiert.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexIsMatch.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexIsMatch.md), [SVF_RegexIsMatch.md](../../Metadata/UsageSkills/toolbelt_string/SVF_RegexIsMatch.md).

<!-- Source/Vertrag SHA256: 696e81ad03531a2580a583b83645f7a313161b59668ebb07039b5a75b0e22a7f -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexIsMatch(N'Contoso 42',N'\d+',DEFAULT) AS HasDigits;
```

## toolbelt_string.SVF_RegexInstr

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Liefert die absolute UTF-16-Start- oder Endposition des n-ten Gesamttreffers.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexInstr.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexInstr.md), [SVF_RegexInstr.md](../../Metadata/UsageSkills/toolbelt_string/SVF_RegexInstr.md).

<!-- Source/Vertrag SHA256: 0a295d694e6aa82288dede005a5337c197f1d8ee16b5c0827fbc87d3781ed5a6 -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. Count/Instr liefern dann0 vor Pattern-/Flagintake. |
| `@Occurrence` | `int` | `1` | Input | Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@ReturnOption` | `int` | `0` | Input | Taxativ0=absolute1-basierte Startposition,1=absolute1-basierte Endposition exklusiv. NULL/andereWerte ungültig. OhneTreffer0. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexInstr(N'a1b22',N'\d+',1,2,0,N'c') AS StartPosition;
```

## toolbelt_string.SVF_RegexCount

Modul `toolbelt.string.regex` · Version `1.3.0` · `CLR_SVF`

Zählt nicht überlappende Gesamttreffer ab einer UTF-16-Startposition.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexCount.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexCount.md), [SVF_RegexCount.md](../../Metadata/UsageSkills/toolbelt_string/SVF_RegexCount.md).

<!-- Source/Vertrag SHA256: 7ab3dd0853db7344de93a4a88abd6be261559b0477d12e33f191a1314465497f -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. Count/Instr liefern dann0 vor Pattern-/Flagintake. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexCount(N'a1b22',N'\d+',1,N'c') AS MatchCount;
```

## toolbelt_string.SVF_RegexReplace

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Ersetzt ausgewählte Gesamttreffer durch literalen Unicode-Text ohne Gruppenexpansion.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexReplace.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexReplace.md), [SVF_RegexReplace.md](../../Metadata/UsageSkills/toolbelt_string/SVF_RegexReplace.md).

<!-- Source/Vertrag SHA256: d70c71c36f9ebdb2d11007777033383f7d2be8625d7a212c4792fb796da72a03 -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Literaler Ersatztext: $1,${Name},Backslash werden nicht expandiert. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Occurrence` | `int` | `0` | Input | 0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexReplace(N'a1b22',N'\d+',N'$1',1,0,N'c',N'standard') AS LiteralReplacement;
-- $1 bleibt hier literal; für Gruppen die getrennte ReplaceGroups-API nutzen.
```

## toolbelt_string.SVF_RegexSubstring

Modul `toolbelt.string.regex` · Version `1.3.0` · `SVF`

Liefert den n-ten Gesamttreffer als Unicode-Text oder NULL, wenn er fehlt.

Vertrag und Quelle: [RegexFunctions.sql](../../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [SVF_RegexSubstring.md](../../Modules/toolbelt.string.regex/Documentation/SVF_RegexSubstring.md), [SVF_RegexSubstring.md](../../Metadata/UsageSkills/toolbelt_string/SVF_RegexSubstring.md).

<!-- Source/Vertrag SHA256: 953b0ad7cde577e107d8508911aa286c491f9dc5da6be1174d1f1f9a0ee35af0 -->

Voraussetzung: Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Occurrence` | `int` | `1` | Input | Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_string.SVF_RegexSubstring(N'a1b22',N'\d+',1,2,N'c',N'standard') AS SecondMatch;
```

## toolbelt_string.TVF_SplitAdvanced

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `TVF`

Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht.

Vertrag und Quelle: [TVF_SplitAdvanced.sql](../../Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql), [TVF_SplitAdvanced.md](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md), [TVF_SplitAdvanced.md](../../Metadata/UsageSkills/toolbelt_string/TVF_SplitAdvanced.md).

<!-- Source/Vertrag SHA256: d2c5f0ff4310ad799971ca94f96a974af5e6702c47ebf363c33001c26c40d7d9 -->

Voraussetzung: Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@SeparatorsJson` | `nvarchar(max)` | `kein Default` | Input | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT)
ORDER BY Ordinal;
-- Drei Originaltokens; IsValid=1, Fehlerfelder NULL.
SELECT * FROM toolbelt_string.TVF_SplitAdvanced(NULL,NULL,NULL,NULL,NULL);
-- Keine Zeilen, wegen frühem NULL-No-op.
```

## toolbelt_string.TVF_UnquoteToken

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `TVF`

Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes.

Vertrag und Quelle: [TVF_UnquoteToken.sql](../../Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql), [TVF_UnquoteToken.md](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_UnquoteToken.md), [TVF_UnquoteToken.md](../../Metadata/UsageSkills/toolbelt_string/TVF_UnquoteToken.md).

<!-- Source/Vertrag SHA256: 2bc48dbac6428d5cc5149a9ee99f6b6810b9aa5a1ce19324caecc708b539a655 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Split-Advanced-Modul installiert; diese Funktion selbst hat keine Tabellen-/Helper-/CLR-/Netzwerkabhängigkeit. Alle vier Argumentpositionen angeben, DEFAULT für die gewünschten technischen Defaults.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile. |
| `@Qualifier` | `nvarchar(max)` | `NULL` | Input | NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert. |
| `@ClosingQualifier` | `nvarchar(max)` | `NULL` | Input | NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein. |
| `@BackslashEscape` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \n, \t usw.; Backslash darf im aktiven Modus kein Qualifier sein. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_UnquoteToken
 (N'[a]]b]',DEFAULT,DEFAULT,DEFAULT);
-- Value=a]b, IsValid=1, ErrorCode/ErrorPosition=NULL.
SELECT * FROM toolbelt_string.TVF_UnquoteToken
 (NULL,DEFAULT,DEFAULT,DEFAULT);
-- Keine Zeile.
```

## toolbelt_string.USP_SplitAdvanced

Modul `toolbelt.string.split-advanced` · Version `1.1.0` · `USP`

Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.

Vertrag und Quelle: [USP_SplitAdvanced.sql](../../Modules/toolbelt.string.split-advanced/Source/USP_SplitAdvanced.sql), [USP_SplitAdvanced.md](../../Modules/toolbelt.string.split-advanced/Documentation/USP_SplitAdvanced.md), [USP_SplitAdvanced.md](../../Metadata/UsageSkills/toolbelt_string/USP_SplitAdvanced.md).

<!-- Source/Vertrag SHA256: 4bd38ca17a04e0825580163df59a273b1d617c3b35c6cc642bc031cee09c9502 -->

Voraussetzung: Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Öffentlicher TVF-Kern in derselben Datenbank installiert; ResultTable-Pfad zusätzlich sameDB USP_PrepareResultTable >=1.0.0 mit exakt den fünf erwarteten SQL-Parametern. Keine Extended Properties oder Runtime-Modulmarkerprüfung. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `NULL` | Input | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
| `@SeparatorsJson` | `nvarchar(max)` | `NULL` | Input | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert vor Fachfunktion und Dependency-/Zielprüfung die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile und kehrt zurück. 0 oder NULL führt den Fachpfad aus. Alle USP-Argumente besitzen technische Defaults. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;"b;c";d',@SeparatorsJson=N'[";"]';
-- Drei Originaltokens: a, Doppelquote b;c Doppelquote, d.
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
```

Hilfe:

```sql
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
```

## toolbelt_string.TVF_SplitByCharacters

Modul `toolbelt.string.split-characters` · Version `1.0.0` · `TVF`

Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren.

Vertrag und Quelle: [TVF_SplitByCharacters.sql](../../Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql), [TVF_SplitByCharacters.md](../../Modules/toolbelt.string.split-characters/Documentation/TVF_SplitByCharacters.md), [TVF_SplitByCharacters.md](../../Metadata/UsageSkills/toolbelt_string/TVF_SplitByCharacters.md).

<!-- Source/Vertrag SHA256: 3af5bb3edf4f4945785e25111cad3b1832dda0cc2da83d89c4b9dab3857ef717 -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul und Generate-Series-Abhängigkeit installiert. Alle drei Argumentpositionen angeben; DEFAULT oder NULL bei KeepEmpty wirkt wie 1. Keine CLR-, Datei-, Netzwerk- oder Systemkatalogabhängigkeit.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,,b',N',',DEFAULT)
ORDER BY Ordinal;
-- Value a / leer / b, Ordinal 1 / 2 / 3.
```

## toolbelt_string.TVF_SplitByCharactersStatus

Modul `toolbelt.string.split-characters` · Version `1.0.0` · `TVF`

Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren.

Vertrag und Quelle: [TVF_SplitByCharacters.sql](../../Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql), [TVF_SplitByCharactersStatus.md](../../Modules/toolbelt.string.split-characters/Documentation/TVF_SplitByCharactersStatus.md), [TVF_SplitByCharactersStatus.md](../../Metadata/UsageSkills/toolbelt_string/TVF_SplitByCharactersStatus.md).

<!-- Source/Vertrag SHA256: 5227f5003f15515afafedcec784c54453632b1a3ff6cdde992786ae7b4fab7ce -->

Voraussetzung: SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul und Generate-Series-Abhängigkeit installiert. Alle drei Argumentpositionen angeben; DEFAULT oder NULL bei KeepEmpty wirkt wie 1. Keine CLR-, Datei-, Netzwerk- oder Systemkatalogabhängigkeit.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a,,b',N',',DEFAULT)
ORDER BY Ordinal;
-- Value a / leer / b, Ordinal 1 / 2 / 3, jeweils OK.
```

## toolbelt_string.USP_CompareTextPairs

Modul `toolbelt.string.text-pairs` · Version `1.0.0` · `USP`

Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.

Vertrag und Quelle: [USP_CompareTextPairs.sql](../../Modules/toolbelt.string.text-pairs/Source/USP_CompareTextPairs.sql), [USP_CompareTextPairs.md](../../Modules/toolbelt.string.text-pairs/Documentation/USP_CompareTextPairs.md), [USP_CompareTextPairs.md](../../Metadata/UsageSkills/toolbelt_string/USP_CompareTextPairs.md).

<!-- Source/Vertrag SHA256: 7af2eb4235d0bf0c0c72451559bab37393ade3f01feab3297e1d79668453995a -->

Voraussetzung: Installierte Module text-pairs, edit-distance mit passender SAFE-Assembly und ResultTable-Helfer im selben Toolbelt-Datenbankkontext, SQL Server 2019/2022/2025 unter Windows/Linux gemäß Modulmatrix. Zentrale Verwendung erfolgt dreiteilig mit sessionlokalen #Temps des Callers. Input muss während des synchronen Aufrufs stabil bleiben; keine MARS-/parallele Mutation. Tabellenrouting benötigt eine committable lokale Transaktion oder eine neu startbare eigene Transaktion; verteilte Caller-Savepoints sind nicht unterstützt. Reine Hilfe kehrt vor diesen Fachprüfungen zurück.

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
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor Fach-, Transaktions-, Tabellen- und Dependencyprüfungen. 0 oder NULL führt den Fachpfad aus. Fachargumente werden im Hilfezweig ignoriert, SQL-Typbindung gilt weiterhin. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max));
INSERT #Pairs VALUES(1,N'kitten',N'sitting'),(2,NULL,N'example');
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'levenshtein';
-- Ordinal 1: Distance=3/Exceeds=0/Code=0; Ordinal 2: NULL-Fachwerte/Code=0.
EXEC toolbelt_string.USP_CompareTextPairs @Hilfe=1;
DROP TABLE #Pairs;
```

Hilfe:

```sql
EXEC toolbelt_string.USP_CompareTextPairs @Hilfe=1;
```

## toolbelt_tsql.TVF_ParseScriptNodes

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert die AST-Knoten eines begrenzten T-SQL-Skripts.

Vertrag und Quelle: [TVF_ParseScriptNodes.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptNodes.sql), [TVF_ParseScriptNodes.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptNodes.md), [TVF_ParseScriptNodes.md](../../Metadata/UsageSkills/toolbelt_tsql/TVF_ParseScriptNodes.md).

<!-- Source/Vertrag SHA256: c32174fc9815c161a7f611a7f725bb5d96f5670c6cd083076f6279458a6e2ad5 -->

Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Vollständiger Unicode-T-SQL-Text, kein Dateipfad oder Connectionstring. Leer ist zulässig. SQLNULL liefert null Zeilen vor jeder anderen CLR-Validierung. Höchstens MaxInputBytes UTF16-Bytes; Länge wird vor ToSqlString-Materialisierung geprüft. Der Text wird nur geparst, niemals ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ80,90,100,110,120,130,140,150,160,170; SQLDefault160 und explizitNULL ebenfalls160. Wählt ScriptDom-Grammatik, nicht Hostversion oder Datenbank-CL. Kein automatischer Versionsfallback; andere Werte werfen INVALID_VERSION. Früher NULL-Text überspringt diese Prüfung. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | bit:1 behandelt doppelte Anführungszeichen als Identifier,0 gemäß deaktiviertem QUOTED_IDENTIFIER-Parsermodus. SQLDefault1; explizitNULL ebenfalls1. Kein SET auf der Sitzung; betrifft nur den lokalen Parser. |
| `@MaxInputBytes` | `int` | `2097152` | Input | int1..2097152 einschließlich; SQLDefault2097152,explizitNULL ebenfalls2097152. Positive Byteobergrenze für SqlChars.Length*2 vor Stringkopie. 0/negativ/zu groß wirft INVALID_MAX_BYTES. Keine Ausgabe-/Heap-/Zeitquote. |
| `@MaxNestingDepth` | `int` | `100` | Input | int1..256 einschließlich; SQLDefault100,explizitNULL ebenfalls100. Grenze der iterativen AST-Tiefe,Root0. Zusätzlich konservativer Vorwächter mit Strukturgrenze min(32,angeforderterTiefe); nicht mit AST-Tiefe gleichsetzen. Tokenize erstellt keinen AST,wendet aber denselben Vorwächter an. Ungültig wirft INVALID_MAX_DEPTH. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY NodeId;
```

## toolbelt_tsql.TVF_ParseScriptNodeProperties

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Eigenschaften der geparsten T-SQL-AST-Knoten.

Vertrag und Quelle: [TVF_ParseScriptNodeProperties.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptNodeProperties.sql), [TVF_ParseScriptNodeProperties.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptNodeProperties.md), [TVF_ParseScriptNodeProperties.md](../../Metadata/UsageSkills/toolbelt_tsql/TVF_ParseScriptNodeProperties.md).

<!-- Source/Vertrag SHA256: 49a8840c67f79730b2d7e16bab3ef45c1cb26cb5bdeb2b5fa61ac09f6994a489 -->

Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Vollständiger Unicode-T-SQL-Text, kein Dateipfad oder Connectionstring. Leer ist zulässig. SQLNULL liefert null Zeilen vor jeder anderen CLR-Validierung. Höchstens MaxInputBytes UTF16-Bytes; Länge wird vor ToSqlString-Materialisierung geprüft. Der Text wird nur geparst, niemals ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ80,90,100,110,120,130,140,150,160,170; SQLDefault160 und explizitNULL ebenfalls160. Wählt ScriptDom-Grammatik, nicht Hostversion oder Datenbank-CL. Kein automatischer Versionsfallback; andere Werte werfen INVALID_VERSION. Früher NULL-Text überspringt diese Prüfung. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | bit:1 behandelt doppelte Anführungszeichen als Identifier,0 gemäß deaktiviertem QUOTED_IDENTIFIER-Parsermodus. SQLDefault1; explizitNULL ebenfalls1. Kein SET auf der Sitzung; betrifft nur den lokalen Parser. |
| `@MaxInputBytes` | `int` | `2097152` | Input | int1..2097152 einschließlich; SQLDefault2097152,explizitNULL ebenfalls2097152. Positive Byteobergrenze für SqlChars.Length*2 vor Stringkopie. 0/negativ/zu groß wirft INVALID_MAX_BYTES. Keine Ausgabe-/Heap-/Zeitquote. |
| `@MaxNestingDepth` | `int` | `100` | Input | int1..256 einschließlich; SQLDefault100,explizitNULL ebenfalls100. Grenze der iterativen AST-Tiefe,Root0. Zusätzlich konservativer Vorwächter mit Strukturgrenze min(32,angeforderterTiefe); nicht mit AST-Tiefe gleichsetzen. Tokenize erstellt keinen AST,wendet aber denselben Vorwächter an. Ungültig wirft INVALID_MAX_DEPTH. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY NodeId,PropertyName;
```

## toolbelt_tsql.TVF_TokenizeScript

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Tokens eines T-SQL-Skripts.

Vertrag und Quelle: [TVF_TokenizeScript.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_TokenizeScript.sql), [TVF_TokenizeScript.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_TokenizeScript.md), [TVF_TokenizeScript.md](../../Metadata/UsageSkills/toolbelt_tsql/TVF_TokenizeScript.md).

<!-- Source/Vertrag SHA256: 91ff6613a69ee186cd1e95da5bfeca50ef15c115d2d6e6b38363b5d84f310299 -->

Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Vollständiger Unicode-T-SQL-Text, kein Dateipfad oder Connectionstring. Leer ist zulässig. SQLNULL liefert null Zeilen vor jeder anderen CLR-Validierung. Höchstens MaxInputBytes UTF16-Bytes; Länge wird vor ToSqlString-Materialisierung geprüft. Der Text wird nur geparst, niemals ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ80,90,100,110,120,130,140,150,160,170; SQLDefault160 und explizitNULL ebenfalls160. Wählt ScriptDom-Grammatik, nicht Hostversion oder Datenbank-CL. Kein automatischer Versionsfallback; andere Werte werfen INVALID_VERSION. Früher NULL-Text überspringt diese Prüfung. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | bit:1 behandelt doppelte Anführungszeichen als Identifier,0 gemäß deaktiviertem QUOTED_IDENTIFIER-Parsermodus. SQLDefault1; explizitNULL ebenfalls1. Kein SET auf der Sitzung; betrifft nur den lokalen Parser. |
| `@MaxInputBytes` | `int` | `2097152` | Input | int1..2097152 einschließlich; SQLDefault2097152,explizitNULL ebenfalls2097152. Positive Byteobergrenze für SqlChars.Length*2 vor Stringkopie. 0/negativ/zu groß wirft INVALID_MAX_BYTES. Keine Ausgabe-/Heap-/Zeitquote. |
| `@MaxNestingDepth` | `int` | `100` | Input | int1..256 einschließlich; SQLDefault100,explizitNULL ebenfalls100. Grenze der iterativen AST-Tiefe,Root0. Zusätzlich konservativer Vorwächter mit Strukturgrenze min(32,angeforderterTiefe); nicht mit AST-Tiefe gleichsetzen. Tokenize erstellt keinen AST,wendet aber denselben Vorwächter an. Ungültig wirft INVALID_MAX_DEPTH. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY TokenIndex;
```

## toolbelt_tsql.TVF_ParseScriptErrors

Modul `toolbelt.tsql.script-parser` · Version `2.0.1` · `CLR_TVF`

Liefert Parserfehler eines T-SQL-Skripts, ohne das Skript auszuführen.

Vertrag und Quelle: [TVF_ParseScriptErrors.sql](../../Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptErrors.sql), [TVF_ParseScriptErrors.md](../../Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptErrors.md), [TVF_ParseScriptErrors.md](../../Metadata/UsageSkills/toolbelt_tsql/TVF_ParseScriptErrors.md).

<!-- Source/Vertrag SHA256: 565c1356454699a68cb5f6dec6da13f1809557d93949a66c05af1f98a70f244b -->

Voraussetzung: Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Vollständiger Unicode-T-SQL-Text, kein Dateipfad oder Connectionstring. Leer ist zulässig. SQLNULL liefert null Zeilen vor jeder anderen CLR-Validierung. Höchstens MaxInputBytes UTF16-Bytes; Länge wird vor ToSqlString-Materialisierung geprüft. Der Text wird nur geparst, niemals ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ80,90,100,110,120,130,140,150,160,170; SQLDefault160 und explizitNULL ebenfalls160. Wählt ScriptDom-Grammatik, nicht Hostversion oder Datenbank-CL. Kein automatischer Versionsfallback; andere Werte werfen INVALID_VERSION. Früher NULL-Text überspringt diese Prüfung. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | bit:1 behandelt doppelte Anführungszeichen als Identifier,0 gemäß deaktiviertem QUOTED_IDENTIFIER-Parsermodus. SQLDefault1; explizitNULL ebenfalls1. Kein SET auf der Sitzung; betrifft nur den lokalen Parser. |
| `@MaxInputBytes` | `int` | `2097152` | Input | int1..2097152 einschließlich; SQLDefault2097152,explizitNULL ebenfalls2097152. Positive Byteobergrenze für SqlChars.Length*2 vor Stringkopie. 0/negativ/zu groß wirft INVALID_MAX_BYTES. Keine Ausgabe-/Heap-/Zeitquote. |
| `@MaxNestingDepth` | `int` | `100` | Input | int1..256 einschließlich; SQLDefault100,explizitNULL ebenfalls100. Grenze der iterativen AST-Tiefe,Root0. Zusätzlich konservativer Vorwächter mit Strukturgrenze min(32,angeforderterTiefe); nicht mit AST-Tiefe gleichsetzen. Tokenize erstellt keinen AST,wendet aber denselben Vorwächter an. Ungültig wirft INVALID_MAX_DEPTH. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY ErrorOrdinal;
-- Eigene reine Syntaxgegenprobe,keine Ausführung des Texts:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT FROM;',160,1,2097152,100) ORDER BY ErrorOrdinal;
```

## toolbelt_tsql.USP_ExplainSsisDataFlow

Modul `toolbelt.tsql.ssis-debug` · Version `1.0.0` · `USP`

Debug-SQL aus DTSX-XML, Paketdefaults und optionalen JSON-Startwerten. Standardmäßig paketbasierter Entwurf ohne Quellkatalogzugriff; CatalogMode=catalog wählt strengere Prüfung. Keine automatische Paket-/SQL-Ausführung.

Vertrag und Quelle: [USP_ExplainSsisDataFlow.sql](../../Modules/toolbelt.tsql.ssis-debug/Source/USP_ExplainSsisDataFlow.sql), [USP_ExplainSsisDataFlow.md](../../Modules/toolbelt.tsql.ssis-debug/Documentation/USP_ExplainSsisDataFlow.md), [USP_ExplainSsisDataFlow.md](../../Metadata/UsageSkills/toolbelt_tsql/USP_ExplainSsisDataFlow.md).

<!-- Source/Vertrag SHA256: e0b68ad6bb1825f7e2f39ce0ca227dc8a4c9f28e20a0f5a6e5bf2cba10940642 -->

Voraussetzung: Windows SQL2019/2022/2025 und zum Host zulässiges CL150/160/170. Vorhandene UNSAFE-Assembly tlblt_Tsql_SsisDebug mit privatem gepinntem tlblt.Microsoft.SqlServer.TransactSql.ScriptDom, vorhandene CLR-/Trustvoraussetzungen. Keine Abhängigkeit auf öffentliche Parser-TVFs. Derselbe ResultTable-Helper nur bei optionalem Zielrouting. Vollständiges entschlüsseltes DTSX-XML mit unterstütztem Format6/8; keine SSIS-Installation, Dateiquelle oder Zielserververbindung wird benötigt. Package-Modus kann Zielmetadaten durch Paketdeklarationen ersetzen, aber keine nicht vorhandene Prozedurdefinition rekonstruieren.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PackageBytes` | `varbinary(max)` | `NULL` | Input | Vollständiges DTSX-XML als UTF8-/UTF16-Bytepuffer; alternativ PackageXml verwenden, niemals beide gleichzeitig. Kein Pfad oder Base64-Text. NULL ist bei PackageXml oder Hilfe zulässig; sonst erforderlich. PackageFormatVersion 6/8, kein verschlüsselter Container, DTD, externer Resolver oder XInclude. MaxPackageBytes begrenzt die Rohbytes; XML-Tiefe bleibt absolut 128. Paket und enthaltenes SQL werden nicht ausgeführt. |
| `@Operation` | `varchar(32)` | `N'explain'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv. explain (Default) analysiert die gebundenen Datenflüsse und liefert Workflow, Stufenverzeichnis, Debug-SQL und Diagnosen. bindings-template liefert nur die paket-/kontextgebundene Schema-2-Eingabevorlage zum Bearbeiten unter values und verlangt Bindings=NULL sowie CatalogBindings=NULL. procedure-definition liefert Definition und Manifest für einen geeigneten gebundenen Zielpfad zur gesonderten Installation. Dazu sind TargetFlow, ProcedureSchema und ProcedureName Pflicht und InspectStage muss NULL sein. NULL, leer und andere Schreibweisen sind ungültig. |
| `@ProjectContext` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet leeren Schema-2-Projektkontext. Sonst JSON-Objekt {"schemaVersion":2,"projectParameters":[...],"connectionManagers":[...]}; beide Arrays optional. Parameterentry: name, ssisType sowie optional designValue, required und sensitive (JSON-Booleans); Connectionentry: refId, name, provider. Provider taxativ sqlserver-oledb oder sqlserver-adonet, beide ordnen vorhandene SQL-Server-Connections zu; keine Connectionstrings/Credentials. Eindeutige Namen/refIds, Projektconnections dürfen Paketconnections nicht überlagern. Typ-/Wertabbildung im Abschnitt SSIS-Eingabetypen der Objektreferenz; unbekannte Typen sind nicht bindbar. Andere Rootkeys, resourceOptions und schemaVersion ungleich 2 ungültig. Feste Kontrollprotokollgrenze 4194304 UTF-16-Bytes zusätzlich zu den gewählten JSON-Limits; beim Zurückgeben der Bindings denselben Kontext verwenden. |
| `@Bindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) verwendet vorhandene nicht sensitive Designdefaults; benötigte fehlende Laufzeitwerte bleiben als fehlender Kontext sichtbar. Sonst vollständiges von bindings-template zurückgegebenes JSON-Objekt mit schemaVersion=2, profile exakt ssis-debug-components-v2, packageSha256, contextSha256, availableInputs und values. Ausschließlich values nach generierten Eingabekeys bearbeiten; Paket-/Kontexthashes und vollständige Herkunftsmetadaten unverändert zurückgeben. values ist ein Objekt typisierter JSON-Werte: Stringtexte/ISO-Datum/-GUID/-Hex, JSON-Boolean für bit, exakte Zahlen gemäß SSIS-Eingabetypen; JSON-null als SQL-NULL, keine SQL-Ausdrücke. Sensitive/ unbekannte/nicht bindbare Keys abgewiesen. Im Template-Modus ausschließlich NULL; kein leeres Ersatzobjekt und keine Ressourcenoptionen. |
| `@CatalogBindings` | `nvarchar(max)` | `NULL` | Input | NULL (Default) leitet die benötigte Datenbankzuordnung aus Connectionstrings bzw. unterstützten Connectionexpressions im Paket ab. Mehrdeutige/fehlende Projektverbindungen und unterschiedliche Server werden diagnostiziert; keine externe Verbindung. Eine explizite Zuordnung überschreibt die automatische Ableitung. Sonst JSON-Objekt mit schemaVersion 1 oder 2, defaultDatabase als Name, databases als Array eindeutiger erlaubter Same-instance-Datenbanknamen und connections als Objekt {importierteConnectionId:Datenbankname}. Default und jede Zuordnung müssen in databases stehen; Connection-IDs müssen im Paket/Projektkontext vorhanden sein. Version 1 erlaubt nur diese Felder; Version 2 ergänzt flatFileInputs als Objekt (auch {}). Je Flatfileentry: database, schema, object, columns als Mapping importierter Spalten-IDs zu SQL-Spaltennamen; optional rowOrdinalColumn und errorRows als entsprechender Quellobjekt-/Spaltenbeschreiber gemäß Komponentenvertrag. Keine freien SQL-Fragmente, Server-/Credential-/Dateipfade oder automatische Rechte. Template-Modus verlangt NULL; leer/andere Shapes ungültig. |
| `@TargetFlow` | `varchar(64)` | `NULL` | Input | NULL (Default) berücksichtigt alle erkannten Zielflüsse getrennt. Sonst exakte modellinterne TargetFlowId aus der Workflow-/StageIndex-Ausgabe desselben Pakets, maximal varchar(64). Groß-/Kleinschreibung und Whitespace bleiben erhalten. Leer oder unbekannt ist ungültig. Bei procedure-definition ist genau eine vorhandene TargetFlowId erforderlich. |
| `@InspectStage` | `varchar(64)` | `NULL` | Input | Taxativ für Steuerwerte: NULL (Default) liefert Zielskript/Stufenverzeichnis ohne zusätzliche StageSql-Auswahl; all liefert die unterstützten Vorgängerstufen jedes gewählten Ziels. Alternativ eine exakte StageId aus dem StageIndex desselben Pakets; dann ist TargetFlow fachlich erforderlich und die Stufe muss zu dessen Vorgängerpfad gehören. all benötigt keinen expliziten TargetFlow. Kein Trim/Casefold; unbekannte/leere konkrete ID ungültig. Bei procedure-definition ist ausschließlich NULL zulässig. |
| `@LookupPolicies` | `nvarchar(max)` | `NULL` | Input | NULL (Default) bedeutet beliebige, pro relevantem Snapshot einmal materialisierte Trefferauswahl. Sonst exakt JSON-Objekt {"schemaVersion":1,"lookups":{"&lt;Lookup-Komponenten-ID&gt;":{"orderBy":[{"column":"&lt;Referenzspalte&gt;","direction":"asc"}]}}}. IDs müssen existierende Lookupkomponenten adressieren, orderBy nicht leer und ohne doppelte Spalten. direction taxativ asc = aufsteigend oder desc = absteigend, exakt kleingeschrieben. Keine freien ORDER-BY-Ausdrücke; vollständige Sortierbindung erforderlich, Gleichstände erhalten keine erfundene Eindeutigkeit. |
| `@ComparisonCollation` | `sysname` | `NULL` | Input | NULL (Default) verwendet bei Katalogbindung die Collation der expliziten defaultDatabase. Sonst genau ein tatsächlich vom Server unterstützter Collationname als sysname, kein COLLATE-SQL-Fragment; Prüfung gegen sys.fn_helpcollations. Dynamische Serverwertemenge, kein festes erfundenes Inventar: SELECT name FROM sys.fn_helpcollations() zeigt sie. Dient Vergleichs-/Ausdrucksbindung und ändert keine DB-/Spaltencollation; leer/unbekannt ungültig. Im paketbasierten Modus wird keine Serverliste abgefragt: dort sind nur Latin1_General_100_BIN2 beziehungsweise Latin1_General_100_BIN2_UTF8 bekannt, ohne explizite Wahl BIN2/1252 als Entwurfsannahme. |
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
| `@MaxAllJsonBytes` | `bigint` | `8388608` | Input | bigint 0..9223372036854775807, Default 8388608: Summe der UTF-16-Bytes von Bindings, CatalogBindings, LookupPolicies und StartValues, ohne ProjectContext. 0 bedeutet für genau diesen konfigurierbaren Zähler unbegrenzt, positive Werte setzen die Obergrenze. Explizites NULL/negative Werte sind Parameterfehler; SQL-Parser-/AST-, feste Tiefen-/Protokoll-, Rechte-/Ownershipgrenzen und Caller-Timeouts werden auch bei 0 nicht aufgehoben. |
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
| `@ProcedureSchema` | `nvarchar(max)` | `NULL` | Input | Bei procedure-definition Name des vorgesehenen dedizierten Zielschemas. 1 bis 128 ASCII-Zeichen. Das erste ist ein Buchstabe, danach sind Buchstaben, Ziffern und Unterstriche zulässig. Unquotierter Einzelname ohne Trim oder Normalisierung. NULL (Default) ist bei explain und bindings-template erforderlich und bei procedure-definition ungültig. |
| `@ProcedureName` | `nvarchar(max)` | `NULL` | Input | Bei procedure-definition Objektname mit exakt großem Präfix USP_ und mindestens einem Folgezeichen. Bis zu 128 ASCII-Zeichen insgesamt, zulässig sind Buchstaben, Ziffern und Unterstriche. Unquotierter Einzelname ohne Trim oder Normalisierung. NULL (Default) ist bei explain und bindings-template erforderlich und bei procedure-definition ungültig. |
| `@PackageXml` | `nvarchar(max)` | `NULL` | Input | Vollständiges DTSX-XML als Unicode-Text. Genau PackageXml oder PackageBytes übergeben; beide NULL nur für Hilfe. Die XML-Kodierungsdeklaration wird an die intern erzeugten UTF8-Bytes angepasst. Kein Pfad, keine externe XML-Auflösung; MaxPackageBytes gilt für die erzeugten Bytes. Unterstützte Paketprofile und Komponenten bleiben unverändert. |
| `@StartValues` | `nvarchar(max)` | `NULL` | Input | Optionales JSON-Objekt mit einfachen typisierten Startwerten, z.B. {"User::SourceFloor":5}. Schlüssel ist ein eindeutiger Variablen-/Parametername oder der vollständige Scope mit Backslash und Name. Unbekannte oder mehrdeutige Namen, sensitive Werte und unpassende Typen werden abgewiesen. Werte überschreiben Designdefaults und Expressions; nicht zusammen mit Bindings verwenden. NULL nutzt verfügbare nicht-sensitive Paketdefaults. Fehlende strukturrelevante Werte werden diagnostiziert. JSON unterliegt MaxJsonDocumentBytes, MaxAllJsonBytes und MaxJsonNodes. |
| `@CatalogMode` | `varchar(16)` | `N'package'` | Input | Taxativ package (Default) oder catalog. package rekonstruiert eine lokale CTE-Kette aus DTSX-SELECTs, Ergebnisschemata und Variablen ohne Quellkatalogzugriff. Flatfiles sind ausdrücklich angenommene typisierte NULL-Dummyzeilen. Prozedurresultsets werden im erzeugten Skript mit lokalen #-Tabellen und INSERT EXEC bereitgestellt; vor Lookup-Prozeduren wird der bisherige Datenstand materialisiert. Die Prozeduren werden erst beim manuellen Ausführen aufgerufen und ihre internen Seiteneffekte bleiben ungeprüft. Fehlende Connection-Laufzeitwerte verwenden mit Diagnose den lokalen Caller-Kontext und unveränderte SQL-Objektnamen. IsExecutable=false und SafetyStatus=not_checked: keine Serveridentitäts-, Objekt-, Rechte-, RLS-, Typ-/Collation- oder SSIS-Cache-/Fehlerparität behauptet. catalog behält die strengere lesende Katalogabnahme mit deren Metadatenrechten bei. procedure-definition verlangt catalog. Keine automatische Ausführung beim Erzeugen und kein Fallback nach Katalogfehlern. NULL, leer, andere Schreibweisen oder Werte sind ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten; der vollständige Artefaktsatz wird vor Zielmutation erzeugt. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 eine redigierte Abschlussmessage mit Artefakt-/SQL-Prüfeinheitenzählern. Kein zusätzliches Resultset und keine Quell-/Secretwerte; der interne ResultTable-Helper wird ausdrücklich mit Debug=0 aufgerufen. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile; Rückkehr vor fachlicher Parameter-/Paket-/Katalogprüfung und Ergebniszielmutation. 0 oder NULL führt den Fachpfad aus. Im internen CLR-Einstieg bleiben die neun LOB-Argumente auch bei Hilfe syntaktisch erforderlich. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;
-- Vollständiges synthetisches DTSX-XML vom Client binden.
DECLARE @Dtsx nvarchar(max)=NULL;
-- @Dtsx vor dem Fachaufruf mit dem Paket füllen.
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@Dtsx,@CatalogMode='package',
 @StartValues=N'{"User::SourceFloor":5}';
-- Nur tatsächlich vorhandene, eindeutig benannte, nicht sensitive Werte angeben.
```

Hilfe:

```sql
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;
```

## toolbelt_validation.TVF_ParseSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Prüft und zerlegt einen strikten SemVer-2.0.0-Text mit explizitem Validierungsstatus.

Vertrag und Quelle: [TVF_ParseSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_ParseSemanticVersion.sql), [TVF_ParseSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_ParseSemanticVersion.md), [TVF_ParseSemanticVersion.md](../../Metadata/UsageSkills/toolbelt_validation/TVF_ParseSemanticVersion.md).

<!-- Source/Vertrag SHA256: f4a2f3f3956c5fd41afb29db539026dd522b1f9b07a289234ddc2a040102ec91 -->

Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_validation.TVF_ParseSemanticVersion('1.2.3-alpha.1+build.007');
-- IsValid=1, ValidationCode=VALID; BuildMetadata bleibt build.007.
SELECT IsValid,ValidationCode FROM toolbelt_validation.TVF_ParseSemanticVersion(NULL);
-- Genau eine Zeile mit NULL_INPUT.
```

## toolbelt_validation.TVF_CompareSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Vergleicht zwei gültige SemVer-Versionen nach Präzedenz als relationaler Kern.

Vertrag und Quelle: [TVF_CompareSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_CompareSemanticVersion.sql), [TVF_CompareSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_CompareSemanticVersion.md), [TVF_CompareSemanticVersion.md](../../Metadata/UsageSkills/toolbelt_validation/TVF_CompareSemanticVersion.md).

<!-- Source/Vertrag SHA256: 39d2a40a699b301e1e0d20b5cf863360a434b8895d419a2e6a81a09f9fe03da0 -->

Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion('1.0.0-alpha.2','1.0.0-alpha.10');
-- ComparisonResult=-1.
SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion('1.0.0+one','1.0.0+two');
-- ComparisonResult=0, Builddaten sind kein Tie-Breaker.
```

## toolbelt_validation.TVF_SemanticVersionSortKey

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `TVF`

Erzeugt einen binären Sortierschlüssel für gültige SemVer-Präzedenz.

Vertrag und Quelle: [TVF_SemanticVersionSortKey.sql](../../Modules/toolbelt.validation.semantic-version/Source/TVF_SemanticVersionSortKey.sql), [TVF_SemanticVersionSortKey.md](../../Modules/toolbelt.validation.semantic-version/Documentation/TVF_SemanticVersionSortKey.md), [TVF_SemanticVersionSortKey.md](../../Metadata/UsageSkills/toolbelt_validation/TVF_SemanticVersionSortKey.md).

<!-- Source/Vertrag SHA256: 3bab2293b061240a35898885c08f1b00892f16dd9221e815a8d17e9651c5ddb9 -->

Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT v.Version,s.SortKey
FROM (VALUES('1.0.0'),('1.0.0-beta'),('1.0.0-alpha')) v(Version)
CROSS APPLY toolbelt_validation.TVF_SemanticVersionSortKey(v.Version) s
WHERE s.SortKey IS NOT NULL
ORDER BY s.SortKey,v.Version;
-- alpha, beta, Release; zusätzlicher Tie-Breaker für gleiche Präzedenz.
```

## toolbelt_validation.SVF_CompareSemanticVersion

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `SVF`

Skalarer Komfortaufruf des kanonischen relationalen SemVer-Vergleichs.

Vertrag und Quelle: [SVF_CompareSemanticVersion.sql](../../Modules/toolbelt.validation.semantic-version/Source/SVF_CompareSemanticVersion.sql), [SVF_CompareSemanticVersion.md](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_CompareSemanticVersion.md), [SVF_CompareSemanticVersion.md](../../Metadata/UsageSkills/toolbelt_validation/SVF_CompareSemanticVersion.md).

<!-- Source/Vertrag SHA256: 367cacc4cdea611771af20ab175ac7244c37b7a03096ee76e8255fb6341b5d9e -->

Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftVersion` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
| `@RightVersion` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_validation.SVF_CompareSemanticVersion('2.0.0','1.9.9') AS ComparisonResult;
-- 1; für viele Quellzeilen die TVF per APPLY verwenden.
```

## toolbelt_validation.SVF_SemanticVersionSortKey

Modul `toolbelt.validation.semantic-version` · Version `1.1.0` · `SVF`

Skalarer Komfortaufruf des kanonischen relationalen SemVer-Sortierschlüssels.

Vertrag und Quelle: [SVF_SemanticVersionSortKey.sql](../../Modules/toolbelt.validation.semantic-version/Source/SVF_SemanticVersionSortKey.sql), [SVF_SemanticVersionSortKey.md](../../Modules/toolbelt.validation.semantic-version/Documentation/SVF_SemanticVersionSortKey.md), [SVF_SemanticVersionSortKey.md](../../Metadata/UsageSkills/toolbelt_validation/SVF_SemanticVersionSortKey.md).

<!-- Source/Vertrag SHA256: 90ce8afb583544b90c3c04a6c3878304b244409da1f7bb8a670ddeb8af546a36 -->

Voraussetzung: Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |

Die Beschreibungen nennen Eingabeform, erlaubte Werte, fachliche Pflicht und Grenzen. Der verlinkte Objektvertrag ergänzt Resultate und Implementierungsdetails.

```sql
SELECT toolbelt_validation.SVF_SemanticVersionSortKey('1.2.3-alpha.1') AS SortKey;
-- Für Mengen TVF_SemanticVersionSortKey per APPLY verwenden.
```

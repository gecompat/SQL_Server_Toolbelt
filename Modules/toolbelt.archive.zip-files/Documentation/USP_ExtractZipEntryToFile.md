# toolbelt_archive.USP_ExtractZipEntryToFile

## Zweck

Vollständiges Entry-Binary aus einem ZIP
über den bestehenden Windowsprovider schreiben. Source 1.0.0 implementiert;
Runtime nicht ausgeführt; unveröffentlicht.
[Vertrag](../../../Documentation/Architecture/ZIP_FILES_CONTRACT.md).

## Parameter

<!-- API_PARAMETERS:BEGIN -->
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
<!-- API_PARAMETERS:END -->

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

## Aktueller Sicherheitsvertrag

SC-004: Extraktion erbt Default16 MiB und feste64-MiB-Entrygrenze; Dateifassade prüft diese vor dem Binaryprovider. Größere bisherige Extraktionsparameter sind zu migrieren. Keine stillen Teilpayloads.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zip).

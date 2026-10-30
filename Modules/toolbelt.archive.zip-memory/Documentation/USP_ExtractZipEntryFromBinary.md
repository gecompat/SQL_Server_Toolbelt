# toolbelt_archive.USP_ExtractZipEntryFromBinary

**Typ:** Stored Procedure mit fachlichem Einzelresultset  
**Modulversion:** `1.2.0`; **Objektvertrag:** unverändert seit `1.1.0`
**Status:** `implemented`; `partially validated`

## Zweck

Extrahiert einen einzelnen, eindeutig benannten ZIP-Entry aus einem In-memory-
ZIP-Container (`varbinary(max)`). Der interne `SAFE`-SQL-CLR-Provider
unterstützt Methods `0` (`Stored`) und `8` (`Deflate`) und prüft die CRC32 des
tatsächlich ausgegebenen Payloads.

## Signatur

```sql
CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ExtractZipEntryFromBinary]
(
      @ZipArchive          varbinary(max) = NULL
    , @EntryName           nvarchar(1024) = NULL
    , @MaxEntryBytes       bigint         = 16777216
    , @MaxCompressionRatio decimal(9,2)   = 200.00
    , @FailIfEncrypted     bit            = 1
    , @ResultTable         sysname        = NULL
    , @KeepData            bit            = 0
    , @Debug               tinyint        = 0
    , @Hilfe               bit            = 0
)
```

Die öffentliche Signatur ist gegenüber Version `1.0.0` unverändert.

## Ergebnis

| Spalte | Typ | Bedeutung |
|---|---|---|
| `EntryName` | `nvarchar(1024)` | Exakter Name aus dem Central Directory. |
| `CompressedBytes` | `bigint` | Komprimierte Größe. |
| `UncompressedBytes` | `bigint` | Deklarierte und bei Extraktion bestätigte Payload-Größe. |
| `CompressionMethod` | `int` | `0` oder `8`. |
| `Crc32` | `int NULL` | CRC32-Bitmuster des tatsächlichen Payloads. |
| `IsEncrypted` | `bit` | Verschlüsselungsflag. |
| `EntryPayload` | `varbinary(max)` | Extrahierter Payload oder `NULL` beim erlaubten verschlüsselten Status. |

Bei `@ResultTable` wird die Zeile in die vorbereitete lokale Temp-Tabelle
geschrieben und kein fachliches `SELECT` ausgegeben.

## Semantik

- Entry-Namen werden ordinal und case-sensitive verglichen.
- Flag 11 verwendet UTF-8, sonst CP437.
- Duplicate Names liefern Fehler `51323`.
- `@FailIfEncrypted = 1` liefert Fehler `51324`.
- `@FailIfEncrypted = 0` liefert Metadaten und `IsEncrypted = 1`, aber keinen
  Payload.
- Größe und Compression Ratio werden vor und während des Lesens begrenzt.
- Reale Bytezahl und neu berechnete CRC32 müssen den Metadaten entsprechen.

## Fehlervertrag

| Nummer | Bedeutung |
|---:|---|
| `51320` | Ungültige Parameter. |
| `51321` | Ungültige oder inkonsistente ZIP-Struktur/Kodierung. |
| `51322` | Entry nicht gefunden. |
| `51323` | Duplicate Name. |
| `51324` | Verschlüsselter Entry abgelehnt. |
| `51325` | Größenlimit überschritten. |
| `51326` | Compression-Ratio-Limit überschritten. |
| `51327` | Nicht unterstütztes Feature, etwa ZIP64, Multi-Disk oder Method. |
| `51328` | Tatsächliche Größe oder CRC32 stimmt nicht. |
| `51329` | Interner Provider oder ResultTable-Dependency fehlt/ist inkonsistent. |

Erwartete Providerfehler werden intern als Status übertragen und vom T-SQL-
Wrapper als Toolbelt-Fehler geworfen. CLR-Fehler `6522` ist kein öffentlicher
Fachvertrag.

## Nicht unterstützt

ZIP64, Multi-Disk, Verschlüsselungsentschlüsselung, Deflate64, weitere Methods,
zusätzliche Central-Directory-Datensätze, Archiv-Erzeugung, Multi-Entry- oder
Verzeichnisextraktion sowie Dateisystem-, Netzwerk- oder Prozesszugriff.

## Berechtigung

Das geprüfte schmale Callerprofil benötigt `EXECUTE` auf dieser Procedure und
`SELECT` auf `toolbelt_archive.TVF_InternalExtractZipEntryClr`. Für
`@ResultTable` ist zusätzlich `EXECUTE` auf
`toolbelt_core.USP_PrepareResultTable` erforderlich. Der
[ZIP-Callerbericht](../../../Releases/1.0.0/ZIP-CALLER-PROFILE.md) beschreibt
den geprüften Umfang; daraus folgt keine mathematische Minimalität und keine
Aussage, dass andere Rechteprofile ausgeschlossen sind.

## Deployment

Die Procedure wird gemeinsam mit
`toolbelt_archive.TVF_InternalExtractZipEntryClr` und der `SAFE`-Assembly
`Toolbelt_Archive_ZipMemory` installiert. Vor dem Datenbankdeployment muss der
exakte SHA2-512-Hash serverweit freigegeben sein. Der Installer verändert keine
Instanzoption und keine Trust-Liste.

## Evidenz

GitHub-Actions-Lauf `30615544206` war erfolgreich auf SQL Server 2019, 2022 und
2025 unter Linux sowie für den Windows-.NET-Framework-4.8-Build. Windows-SQL-
Server-Runtime und Release-Extremgrößenläufe bleiben offen.

## Beispiel

Siehe `../Examples/ExtractZipEntryFromBinary.sql`.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206

## Aktueller Sicherheitsvertrag

SC-004: Entryextraktion verwendet standardmäßig 16777216 Bytes (16 MiB), höchstens 67108864 Bytes (64 MiB). Deklarierte und tatsächlich gelesene Größe werden geprüft. Ein exakt dimensionierter finaler Entrybuffer ersetzt wachsenden MemoryStream und ToArray-Abschlusskopie. Archiv-/Compressed-/Ratio-/CRC-Grenzen bleiben bestehen. Die technische ArchiveSession teilt die feste Entryobergrenze.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
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
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zip).

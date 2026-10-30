# toolbelt_filesystem.USP_ReadTextFileChunk

## Zweck

Liest einen begrenzten Text-Chunk mit expliziter Codepage. Rückgabe: Content, BytesRead, NextByteOffset, EndOfFile, EncodingName.

## Parameter

@RootAlias, @RelativePath, @ByteOffset, @MaxBytes, @EncodingName, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
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
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

## Beispielaufruf

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadTextFileChunk
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.txt', @ByteOffset=0, @MaxBytes=1024, @EncodingName=N'utf-8', @ExecutionIdentity=N'Caller';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#dateisystem).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/Procedures.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)

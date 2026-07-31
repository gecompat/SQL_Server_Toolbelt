# ZIP Memory Extraction

**Modul-ID:** `toolbelt.archive.zip-memory`  
**Version:** `1.1.0`  
**Status:** `implemented`; `partially validated`

## Zweck

Das Modul extrahiert genau einen benannten ZIP-Entry aus einem In-memory-
ZIP-Container (`varbinary(max)`) ohne Dateisystemzugriff. Der interne
C#-SQL-CLR-Provider unterstützt Compression Methods `0` (`Stored`) und `8`
(`Deflate`) sowie CRC32-Prüfung über den tatsächlichen Payload.

## Objekte

| Objekt | Rolle |
|---|---|
| `toolbelt_archive.USP_ExtractZipEntryFromBinary` | Einzige öffentliche Entry-Extraktions-API; Signatur gegenüber `1.0.0` unverändert. |
| `toolbelt_archive.TVF_InternalExtractZipEntryClr` | Interner CLR-Provider. |
| `Toolbelt_Archive_ZipMemory` | Modulspezifische `SAFE`-Assembly. |

## Abhängigkeit

`toolbelt.core.result-table` ab Version `1.0.0` wird für den optionalen
`@ResultTable`-Pfad benötigt.

## Build-, Trust- und Deploymentmodell

`Scripts/New-ClrReleaseArtifacts.ps1` erzeugt aus dem C#-Quellcode:

- `Toolbelt.Archive.ZipMemory.dll`;
- ein SHA2-512-Trust-Manifest;
- `Deploy.WithAssembly.sql` mit dem exakten Binary als SQL-Binäritliteral.

Trust ist ein separater administrativer Opt-in über
`Deployment/Add-TrustedAssembly.sql`. Der reguläre Installer prüft
`clr enabled`, `clr strict security` und den exakten Hash in
`sys.trusted_assemblies`, verändert diese Instanzzustände aber nicht.

Der Uninstall entfernt Procedure, internen CLR-TVF und Assembly aus der
Datenbank. Ein serverweiter Trust-Eintrag bleibt bewusst bestehen.

## Providervertrag

- direkte Framework-Referenzen ausschließlich `System` und `System.Data`;
- `DeflateStream` aus `System.dll`;
- kein `ZipArchive` und keine direkte Referenz auf
  `System.IO.Compression.dll`;
- UTF-8-Entry-Namen bei Flag 11, sonst CP437;
- ordinaler case-sensitiver Namensvergleich;
- Local Header mit und ohne Data Descriptor;
- Duplicate-Name-, Header-, Größen-, Ratio- und CRC32-Prüfung.

Default-Limits:

- `@MaxEntryBytes = 104857600`;
- `@MaxCompressionRatio = 200.00`.

Harte Providerlimits:

- Archiv `268435456` Bytes;
- komprimierter Entry `134217728` Bytes;
- maximal `10000` untersuchte Entries.

## Nicht unterstützt

ZIP64, Multi-Disk, Verschlüsselungsentschlüsselung, Deflate64, andere Methods,
Archiv-Erzeugung, Multi-Entry-, Verzeichnis- und rekursive Extraktion sowie
Dateisystem-, Netzwerk- oder Prozesszugriff.

## Dokumentation

- Objekt: `Documentation/USP_ExtractZipEntryFromBinary.md`
- Architektur: `../../Documentation/Architecture/ZIP_ARCHIVE_MODULE_DESIGN.md`
- CLR-Provider: `../../Documentation/Architecture/ZIP_CLR_PROVIDER_DESIGN.md`
- Tests: `Tests/`

## Teststatus

GitHub-Actions-Lauf `30615544206` war erfolgreich für:

- Windows-.NET-Framework-4.8-Build;
- SQL Server 2019 Linux / Compatibility 150;
- SQL Server 2022 Linux / Compatibility 160;
- SQL Server 2025 Linux / Compatibility 150, 160 und 170;
- Stored, Deflate, Data Descriptor, UTF-8, CP437, CRC32, Fehlerverträge,
  ResultTable, Wiederholungsdeployment, Central und Uninstall.

Offen bleiben Windows-SQL-Server-Runtime, echte Extremgrößenläufe und eine
breitere Interoperabilitätsmatrix realer Archive vor Release.

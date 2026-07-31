# ZIP Memory Extraction

**Modul-ID:** `toolbelt.archive.zip-memory`  
**Version:** `1.1.0`  
**Status:** `implemented`; Runtime `not executed`

## Zweck

Das Modul extrahiert genau einen benannten ZIP-Entry aus einem In-memory-
ZIP-Container (`varbinary(max)`) ohne Dateisystemzugriff. Version `1.1.0`
verwendet einen internen C#-SQL-CLR-Provider und unterstützt:

- Compression Method `0` (`Stored`);
- Compression Method `8` (`Deflate`);
- CRC32-Neuberechnung über den tatsächlich ausgegebenen Payload;
- UTF-8-Entry-Namen gemäß General-Purpose-Flag 11, sonst CP437;
- Local Header mit oder ohne Data Descriptor.

## Öffentlicher Vertrag

| Objekt | Typ | Schema | Zweck |
|---|---|---|---|
| `USP_ExtractZipEntryFromBinary` | `USP` | `toolbelt_archive` | Extrahiert einen eindeutigen Entry und erhält Help-, ResultTable- und Fehlervertrag der Version `1.0.0`. |

Interne Runtime-Artefakte:

| Objekt | Rolle |
|---|---|
| `toolbelt_archive.TVF_InternalExtractZipEntryClr` | Interner CLR-Provider; keine öffentliche API. |
| `Toolbelt_Archive_ZipMemory` | Modulspezifische `SAFE`-Assembly. |

## Abhängigkeiten

| Modul | Mindestversion | Begründung |
|---|---:|---|
| `toolbelt.core.result-table` | `1.0.0` | `@ResultTable`-Integration gemäß USP-Vertrag. |

Direkte Framework-Referenzen der Assembly sind ausschließlich `System` und
`System.Data`. `DeflateStream` stammt im .NET-Framework-4.8-Ziel aus
`System.dll`; `System.IO.Compression.dll` wird nicht direkt referenziert.

## Build und Deployment

Das Repository versioniert kein DLL-Binary. Aus dem C#-Quellcode werden das
exakte Release-Binary, ein SHA2-512-Trust-Manifest und ein pfadunabhängiges
Deployment-Skript erzeugt:

```powershell
./Scripts/New-ClrReleaseArtifacts.ps1 `
  -Configuration Release `
  -OutputDirectory ./Artifacts
```

Der Ablauf ist bewusst zweistufig:

1. Ein Administrator führt `Deployment/Add-TrustedAssembly.sql` mit Hash und
   Beschreibung aus dem Manifest aus. Das Skript aktiviert CLR nicht und
   verändert `clr strict security` nicht.
2. `Artifacts/Deploy.WithAssembly.sql` wird mit der SQLCMD-Variable
   `DeploymentMode=local` oder `central` ausgeführt.

Beispiel:

```powershell
sqlcmd -S '<instance>' -d master -b `
  -v "AssemblyHash=<manifest.sqlServerHexLiteral>" `
     "AssemblyDescription=<manifest.description>" `
  -i ./Deployment/Add-TrustedAssembly.sql

sqlcmd -S '<instance>' -d '<database>' -b `
  -v "DeploymentMode=local" `
  -i ./Artifacts/Deploy.WithAssembly.sql
```

Voraussetzungen:

- SQL Server 2019, 2022 oder 2025;
- `clr enabled = 1`;
- `clr strict security = 1`;
- exakte SHA2-512-Freigabe des gebauten Binaries;
- lokale oder zentrale Installation von `toolbelt.core.result-table` in
  derselben Toolbelt-Datenbank.

Der Standardinstaller ändert keine Instanzoption und keinen Trust-Eintrag.
Der Uninstall entfernt den serverweiten Trust-Eintrag nicht.

## Sicherheits- und Ressourcenvertrag

- keine Pfade, Dateien, Netzwerke, Prozesse oder Host-APIs in CLR;
- Entry-Namen werden ordinal und case-sensitive verglichen;
- Duplicate Names führen zu Fehler `51323`;
- verschlüsselte Entries werden bei `@FailIfEncrypted = 1` abgelehnt;
- bei `@FailIfEncrypted = 0` werden Metadaten und `IsEncrypted = 1`, aber kein
  Payload geliefert;
- Default-Limits:
  - `@MaxEntryBytes = 104857600`;
  - `@MaxCompressionRatio = 200.00`;
- zusätzliche harte Providerlimits:
  - Archiv: `268435456` Bytes;
  - komprimierter Entry: `134217728` Bytes;
  - untersuchte Entries: `10000`;
- deklarierte und tatsächliche Größe sowie Compression Ratio werden geprüft;
- CRC32 wird über die tatsächliche Ausgabe neu berechnet.

## Nicht unterstützt

- ZIP64;
- Multi-Disk-Archive;
- Verschlüsselungsentschlüsselung;
- Deflate64 und andere Methods als `0` oder `8`;
- Archiv-Erzeugung;
- Multi-Entry-Extraktion und Verzeichnisextraktion;
- zusätzliche Central-Directory-Datensätze wie digitale Signaturen.

## Dokumentation

- Objekt: `Documentation/USP_ExtractZipEntryFromBinary.md`
- Architektur: `../../Documentation/Architecture/ZIP_ARCHIVE_MODULE_DESIGN.md`
- CLR-Provider: `../../Documentation/Architecture/ZIP_CLR_PROVIDER_DESIGN.md`
- Tests: `Tests/`

## Teststatus

Der Quellstand ist implementiert. Runtime-Evidenz wird erst nach erfolgreichen
GitHub-Actions-Läufen in `module.yaml` und `Tests/README.md` eingetragen.
Windows-.NET-Framework-Build ist kein Windows-SQL-Server-Runtime-Nachweis.

# ZIP-Archiv-Moduldesign (TC-2026-034)

## Status

**Implementiert:** `toolbelt.archive.zip-memory` Version `1.1.0` extrahiert
genau einen benannten ZIP-Entry aus einem In-memory-Archiv über die bestehende
öffentliche `toolbelt_archive.USP_ExtractZipEntryFromBinary`.

**Teilvalidiert:** Der GitHub-Actions-Lauf `30615544206` war erfolgreich für SQL
Server 2019, 2022 und 2025 unter Linux sowie für den Windows-.NET-Framework-4.8-
Build. Auf SQL Server 2025 wurden die Compatibility Levels 150, 160 und 170
geprüft. Windows-SQL-Server-Runtime und echte Extremgrößenläufe bleiben offen.

## Modulgrenze

Das Modul verarbeitet ausschließlich `varbinary(max)` im Speicher. Es besitzt
keine Dateisystem-, Netzwerk- oder Prozessschnittstelle und erzeugt keine
Archive.

| Artefakt | Rolle |
|---|---|
| `toolbelt_archive.USP_ExtractZipEntryFromBinary` | Einzige öffentliche Entry-Extraktions-API. |
| `toolbelt_archive.TVF_InternalExtractZipEntryClr` | Interner CLR-Provider. |
| `Toolbelt_Archive_ZipMemory` | Modulspezifische `SAFE`-Assembly. |

## Öffentlicher Vertrag

Die mit Version `1.0.0` eingeführte Signatur bleibt unverändert:

- `@ZipArchive varbinary(max)`;
- `@EntryName nvarchar(1024)`;
- `@MaxEntryBytes bigint = 104857600`;
- `@MaxCompressionRatio decimal(9,2) = 200.00`;
- `@FailIfEncrypted bit = 1`;
- `@ResultTable sysname = NULL`;
- `@KeepData bit = 0`;
- `@Debug tinyint = 0`;
- `@Hilfe bit = 0`.

Das Resultset enthält `EntryName`, `CompressedBytes`, `UncompressedBytes`,
`CompressionMethod`, `Crc32`, `IsEncrypted` und `EntryPayload`. Bei
`@ResultTable` wird kein fachliches `SELECT` ausgegeben.

## Unterstützter ZIP-Scope

Version `1.1.0` unterstützt:

- Method `0` (`Stored`) und Method `8` (`Deflate`);
- klassische EOCD-, Central-Directory- und Local-Header-Strukturen;
- Local Header mit und ohne Data Descriptor;
- UTF-8-Namen bei Flag 11, sonst CP437;
- ordinalen case-sensitiven Namensvergleich;
- Duplicate-Name-Erkennung;
- CRC32-Neuberechnung über den tatsächlichen Payload.

Nicht unterstützt werden ZIP64, Multi-Disk, Verschlüsselungsentschlüsselung,
Deflate64, weitere Methods, zusätzliche Central-Directory-Datensätze,
Archiv-Erzeugung, Multi-Entry-, Verzeichnis- oder rekursive Extraktion.

## Ressourcen- und Integritätsvertrag

Default-Limits:

- `@MaxEntryBytes = 104857600`;
- `@MaxCompressionRatio = 200.00`.

Harte Providerlimits:

- Archivgröße `268435456` Bytes;
- komprimierter Entry `134217728` Bytes;
- maximal `10000` untersuchte Entries.

Limits werden gegen Metadaten und während des tatsächlichen Lesens geprüft.
Anschließend müssen reale Payload-Länge und neu berechnete CRC32 exakt mit dem
Central Directory übereinstimmen. Der Deflate-Stream ist auf die deklarierte
komprimierte Entry-Länge begrenzt.

## Sicherheit und Deployment

Die Assembly zielt auf .NET Framework 4.8 und referenziert direkt nur `System`
und `System.Data`. `DeflateStream` stammt aus `System.dll`; `ZipArchive` und ein
direkter Verweis auf `System.IO.Compression.dll` sind ausgeschlossen.

Der reguläre Installer:

- verwendet `PERMISSION_SET = SAFE`;
- prüft den exakten SHA2-512-Hash gegen `sys.trusted_assemblies`;
- lädt das Binary aus einem SQL-Binäritliteral;
- verändert weder `clr enabled`, `clr strict security`, `TRUSTWORTHY` noch die
  Trust-Liste.

Trust bleibt ein getrennter administrativer Opt-in. Der Uninstall entfernt
keinen serverweiten Trust-Eintrag.

## Lifecycle

Unterstützt sind Upgrade von `1.0.0` auf `1.1.0`, lokale und zentrale
Installation, inhaltlich idempotentes Wiederholungsdeployment, Dependency-
Schutz und vollständiger Datenbank-Uninstall von Procedure, internem CLR-TVF
und Assembly.

## Fehlerbereiche

- Fach-/Providerfehler `51320–51329`;
- Lifecycle `51330–51339`;
- Trust-/CLR-Preflight `51340–51349`.

Der CLR-Provider überträgt erwartete Fachfehler intern als Statuszeile; der
T-SQL-Wrapper wirft daraus stabile Toolbelt-Fehler. Fehler `6522` ist kein
öffentlicher Fachvertrag.

## Validierung und offene Release-Gates

Erfolgreich geprüft wurden Stored, Deflate, Data Descriptor, UTF-8, CP437,
Duplicate Names, Verschlüsselungsstatus, Größen-/Ratio-/Featurefehler,
Headerinkonsistenz, CRC-Mismatch, ResultTable, Wiederholungsdeployment, Central
und Uninstall.

Offen bleiben:

- SQL Server Runtime unter Windows;
- echte 268-MiB-, 128-MiB- und 10000-Entry-Grenzläufe;
- zusätzliche reale Archive verschiedener Erzeuger vor Release.

## Abgrenzung

`TC-2026-033` bleibt Metadaten-Listing, `TC-2026-037` bleibt dateibasierte
Ein-/Ausgabe. Archiv-Erzeugung und weitere Kompressionsformate bleiben eigene
Capabilities.

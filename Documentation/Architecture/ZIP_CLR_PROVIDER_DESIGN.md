# SQL-CLR ZIP Provider Design (AP-2026-021/AP-2026-023)

## Status und Aussagegrenze

**Implementiert und teilvalidiert:** Der Provider ist Bestandteil von
`toolbelt.archive.zip-memory` Version `1.1.0`. Er ist interner Provider der
bestehenden öffentlichen `toolbelt_archive.USP_ExtractZipEntryFromBinary` und
keine allgemeine Kompressions-API.

Der GitHub-Actions-Lauf `30615544206` belegt Build und Runtime auf SQL Server
2019, 2022 und 2025 unter Linux. Windows-SQL-Server-Runtime und echte
Extremgrößen-Releasefälle bleiben offen.

## Scope

Enthalten sind:

- ZIP-Container als `varbinary(max)`;
- Auswahl genau eines Entries;
- Methods `0` und `8`;
- eigener klassischer ZIP-Parser;
- UTF-8 gemäß Flag 11, sonst CP437;
- begrenztes Lesen, tatsächliche Output-/Ratio-Prüfung und Payload-CRC32;
- stabile Toolbelt-Fehler `51320–51329`.

Ausgeschlossen sind Dateisystem, Netzwerk, Prozesse, Archiv-Erzeugung,
Multi-Entry-/Verzeichnisextraktion, Verschlüsselungsentschlüsselung, ZIP64,
Multi-Disk, Deflate64, weitere Methods und zusätzliche Central-Directory-
Datensätze.

## Provider- und Namensentscheidung

Gemäß `DEC-2026-023`:

- SQL-Assembly: `Toolbelt_Archive_ZipMemory`;
- Binary: `Toolbelt.Archive.ZipMemory.dll`;
- interner SQL-Provider: `toolbelt_archive.TVF_InternalExtractZipEntryClr`;
- einzige öffentliche Extraktions-API bleibt
  `toolbelt_archive.USP_ExtractZipEntryFromBinary`.

Die Namen gelten nur für dieses Modul und begründen keine globale CLR-
Namenskonvention.

## C#- und Assemblyvertrag

- Ziel: .NET Framework 4.8;
- direkte Referenzen ausschließlich `System` und `System.Data`;
- `DeflateStream` aus `System.dll`;
- kein `ZipArchive` und kein direkter Verweis auf
  `System.IO.Compression.dll`;
- eigener Central-/Local-Header-Parser und eigene CRC32-Berechnung;
- `PERMISSION_SET = SAFE`.

## Ressourcen und Integrität

Vor der Dekomprimierung werden Archiv-, Entry-Count-, komprimierte und
unkomprimierte Größe, Method, Verschlüsselungsflags, Duplicate Names und Ratio
geprüft. Während des Lesens werden tatsächliche Ausgabemenge und reale Ratio
erneut begrenzt. Danach müssen reale Länge und CRC32 mit dem Central Directory
übereinstimmen.

Harte Providerlimits:

- Archiv `268435456` Bytes;
- komprimierter Entry `134217728` Bytes;
- `10000` Entries.

## Trust und Deployment

`clr strict security` bleibt aktiviert. Der exakte Release-Hash wird als
SHA2-512-Manifest erzeugt und über ein separates administratives Skript mit
`sys.sp_add_trusted_assembly` freigegeben.

Der Modulinstaller:

- prüft `clr enabled` und `clr strict security`;
- prüft den exakten Hash in `sys.trusted_assemblies`;
- registriert die Assembly aus dem Binärliteral;
- ändert keine Instanzoption und keine Trust-Liste;
- verwendet weder `TRUSTWORTHY ON`, `EXTERNAL_ACCESS` noch `UNSAFE`.

## Lifecycle

Implementiert sind reproduzierbarer Build, Trust-Manifest, lokales und zentrales
Deployment, Upgrade von `1.0.0`, inhaltlich idempotente Wiederholung über den
SHA2-512-Vergleich des registrierten Assembly-Files sowie kontrollierter
Uninstall. Der Uninstall entfernt keinen serverweiten Trust-Eintrag und keine
fremden Objekte oder Assemblies.

## Validierung

Der Lauf `30615544206` war erfolgreich für:

- Windows-.NET-Framework-4.8-Build;
- SQL Server 2019 Linux / Compatibility 150;
- SQL Server 2022 Linux / Compatibility 160;
- SQL Server 2025 Linux / Compatibility 150, 160 und 170;
- Stored, Deflate, Data Descriptor, UTF-8, CP437 und CRC32;
- beschädigte Headerbeziehungen, Duplicate Names, Encryption Flag,
  unbekannte Method, ZIP64-Sentinel, Größen-/Ratiofehler;
- ResultTable, Wiederholungsdeployment, Central und Uninstall.

Nicht ausgeführt sind die SQL-Server-Runtime unter Windows, echte Läufe an den
maximalen Größen-/Entry-Count-Grenzen und eine breitere Interoperabilitätsmatrix
realer ZIP-Erzeuger.

## Quellen

- Microsoft: [Supported .NET Framework libraries – SQL Server](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/database-objects/supported-net-framework-libraries?view=sql-server-ver17).
- Microsoft: [DeflateStream Class](https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.deflatestream?view=netframework-4.8.1).
- Microsoft: [CREATE ASSEMBLY](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-assembly-transact-sql?view=sql-server-ver17).
- Microsoft: [clr strict security](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/clr-strict-security?view=sql-server-ver17).
- Microsoft: [sys.sp_add_trusted_assembly](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-add-trusted-assembly-transact-sql?view=sql-server-ver17).
- PKWARE: [ZIP File Format Specification (APPNOTE)](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT).

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206

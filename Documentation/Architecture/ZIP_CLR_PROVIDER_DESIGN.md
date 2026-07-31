# SQL-CLR ZIP Provider Design (AP-2026-021)

## Status und Aussagegrenze

**Dokumentiert:** `AP-2026-021` ist als Vertragswelle abgeschlossen. Dieser
Entwurf implementiert keine produktive Assembly, keine öffentliche
SQL-CLR-Routine und keinen Produkt-Deployment-Schritt. Der nichtproduktive
Build-/Deployment-Spike liegt getrennt unter
[`Spikes/sql-clr-zip-provider/`](../../Spikes/sql-clr-zip-provider/).

**Freigabestatus:** Der korrigierte Spike prüft den technisch notwendigen
Deflate-/CRC32-Kern. Vor einer produktiven C#-Implementierung bleiben eine
eigene funktionsbezogene Implementierungsfreigabe sowie die vollständige
Security-, Limit-, Lifecycle- und Plattformmatrix erforderlich.

## Ziel

Der optionale Provider schließt genau zwei Lücken des vorhandenen
`toolbelt.archive.zip-memory`-Slices:

- ZIP Compression Method `8` (`Deflate`) für die Extraktion eines einzelnen
  In-memory-Entries;
- explizite CRC32-Prüfung des tatsächlich dekomprimierten Payloads.

ZIP Method `0` (`Stored`) darf derselbe Provider ebenfalls lesen, damit der
spätere Slice einen konsistenten Prüfkern hat. Der bestehende T-SQL-Slice bleibt
für seinen engen `Stored`-Vertrag eigenständig.

## Strikte Scope-Grenze

Enthalten sind ausschließlich:

- Eingabe eines ZIP-Containers als `varbinary(max)`;
- Auswahl genau eines Entries;
- Entry-Metadaten und Payload als SQL-Resultset;
- Methods `0` und `8`;
- begrenztes, streamorientiertes Lesen und Payload-CRC32-Prüfung;
- strukturierte Toolbelt-Fehler für nicht unterstützte ZIP-Eigenschaften.

Ausgeschlossen sind:

- Dateisystemzugriff, Pfade, Netzwerk, Prozessstart und Host-APIs;
- Archiv-Erzeugung und Multi-Entry-Create;
- Extraktion ganzer Archive oder Verzeichnisse;
- Verschlüsselungsentschlüsselung, Passwörter und Key-Material;
- Deflate64, unbekannte Methoden und proprietäre ZIP-Erweiterungen;
- weitere Kompressionsformate; Gzip, Brotli, Zstandard, bzip2 und 7z bleiben
  getrennte Kandidaten;
- eine stillschweigende Änderung des bestehenden öffentlichen
  `USP_ExtractZipEntryFromBinary`-Vertrags.

ZIP64 bleibt für den späteren Implementierungs-Slice ausdrücklich offen: Die
künftige Routine darf ZIP64 weder behaupten noch akzeptieren, bevor Parsing,
Grenzen und Testvektoren getrennt spezifiziert sind.

## Provider- und Public-Contract-Regel

Die C#-Assembly ist ein interner Provider, kein allgemeines
Kompressionsframework. Ob sie durch eine neue öffentliche Procedure oder durch
eine später versionierte, abwärtskompatible Erweiterung angesprochen wird, ist
erst im Implementierungs-Slice zu entscheiden. Bis dahin gibt es keinen
produktiven Assembly-, Klassen- oder öffentlichen Objektnamen.

Das neue Resultset darf keine unsicheren Dateipfade, Secrets oder
Implementierungsdetails preisgeben. Für ResultTable-/Help-/Debug-Verhalten gilt
weiterhin der zentrale USP-Vertrag.

## Ressourcen- und Integritätsgrenzen

Die Implementierung muss vor einer teuren Dekomprimierung mindestens prüfen:

- maximale Archivgröße;
- maximale Anzahl von Entries, die zur eindeutigen Namensauflösung untersucht
  werden;
- maximale komprimierte und unkomprimierte Einzelgröße;
- maximale Gesamtausgabe, falls mehrere interne Streams gelesen werden;
- maximale Compression Ratio;
- eindeutige Entry-Namen, Verschlüsselungsflag und Methodensubset.

Während des Lesens gilt eine zweite, tatsächliche Begrenzung der ausgegebenen
Bytes; ZIP-Metadaten allein sind keine vertrauenswürdige Größenangabe. Die CRC32
ist über den dekomprimierten Byte-Stream neu zu berechnen und gegen die für den
Entry erwartete CRC32 zu vergleichen. Fehlende, inkonsistente oder nicht
passende Integritätsdaten führen zu einem stabilen Toolbelt-Fehler, nicht zu
einer Teilantwort.

Konkrete numerische Default-Limits und Fehlernummern werden erst gemeinsam mit
der endgültigen öffentlichen Signatur festgelegt; sie dürfen nicht unbemerkt
aus der T-SQL-Implementierung übernommen werden.

## C#- und Assembly-Gates

- Ziel ist C# für SQL CLR auf dem von SQL Server unterstützten
  .NET-Framework-CLR, mit `PERMISSION_SET = SAFE` als beabsichtigtem
  Minimalrecht.
- Namespace und Assembly sind getrennt zu beurteilen: `DeflateStream` liegt im
  Namespace `System.IO.Compression`, wird im .NET-Framework-4.8-Ziel jedoch aus
  der von SQL Server unterstützten `System.dll` geladen.
- `ZipArchive` wird für den Providerkern nicht verwendet. Es würde eine direkte
  Referenz auf `System.IO.Compression.dll` erzeugen, die SQL Server nicht als
  automatisch unterstützte Framework-Assembly bereitstellt und deren separater
  Deployment-/Lifecycle-Pfad für diesen engen Scope unnötig wäre.
- ZIP-Containerstrukturen werden daher kontrolliert im eigenen Providercode
  geparst; ausschließlich der Raw-Deflate-Payload von Method 8 wird an
  `DeflateStream` übergeben.
- CRC32 wird über die tatsächlich ausgegebenen Bytes selbst berechnet. Die
  Deflate-API ersetzt keine ZIP-Integritätsprüfung.
- `clr strict security` bleibt aktiviert. Der reguläre Installationsweg
  verwendet eine explizite serverseitige Vertrauensfreigabe der exakt
  freigegebenen Release-Assembly (SHA2-512 via
  `sys.sp_add_trusted_assembly`) oder einen dokumentierten gleichwertigen
  Signaturweg.
- `TRUSTWORTHY ON`, das Abschalten von `clr strict security`,
  `EXTERNAL_ACCESS` und `UNSAFE` sind keine regulären Installationsalternativen.
- Der Standardinstaller verändert keine Instanzkonfiguration und hinterlegt
  keinen Trust-Eintrag stillschweigend. Er prüft Voraussetzungen und beendet
  kontrolliert; ein administratives, klar dokumentiertes Trust-Skript bleibt
  separat.
- Das Assembly-Deployment muss ohne Zugriff des SQL-Server-Dienstkontos auf
  einen Client- oder Buildpfad funktionieren. Der Spike verwendet deshalb
  `CREATE ASSEMBLY ... FROM 0x...` mit den Bytes des exakt gehashten Binaries.

## Lifecycle

Ein späterer Implementierungs-Slice benötigt mindestens:

1. reproduzierbaren C#-Build inklusive Abhängigkeitsinventar und Lizenzprüfung;
2. versioniertes SHA2-512-Trust-Manifest;
3. Preflight für CLR-Aktivierung, Framework-Abhängigkeiten und Trust;
4. idempotentes Installieren ohne Änderungen fremder Assemblies;
5. Upgrade-/Rollback-Regeln mit klarer Verweigerung bei nicht auflösbaren
   Abhängigkeiten;
6. Uninstall, der Toolbelt-Assembly und -Objekte entfernt, aber keinen gemeinsam
   verwendeten Trust-Eintrag oder fremde Assembly entfernt.

## Spike- und Testmatrix vor Implementierung

| Gate | Nachweis |
|---|---|
| Build | Reproduzierbarer .NET-Framework-4.8-Build; direkte Referenzen nur auf freigegebene Framework-Assemblies. |
| Primitive | Raw-Deflate-Dekomprimierung über `System.dll`, exakter Payload und unabhängig berechnete CRC32. |
| Deploy | Separate Testdatenbank; binäres `CREATE ASSEMBLY`, Trust, Wiederholung und Uninstall verhalten sich deterministisch. |
| Plattform | SQL Server 2019, 2022 und 2025 auf Windows und Linux getrennt; fehlende Plattformunterstützung wird als nicht unterstützt, nicht als Fehler kaschiert. |
| ZIP | Stored, Deflate, beschädigte Central/Local Header, CRC-Mismatch, Encryption Flag, Deflate64, unbekannte Method, Duplicate Name und ZIP64. |
| Limits | Archiv-, Entry-, Output-, Ratio- und Entry-Count-Grenzen vor und während des Lesens. |
| Lifecycle | Erstinstallation, Wiederholung, Upgrade, Uninstall und Central/Local-Deployment. |
| Security | Kein Dateisystem-, Netzwerk- oder Prozesszugriff; keine automatische Änderung von `clr strict security`, `TRUSTWORTHY` oder Trust-Listen. |

## Build-/Deployment-Spike

Der ursprüngliche Spike verwendete `ZipArchive`. Dadurch referenzierte das
Binary `System.IO.Compression.dll`; der Linux-Test belegte folgerichtig nur den
SQL-Server-Fehler 10301 wegen der fehlenden Assembly. Dieser Befund war korrekt,
prüfte aber nicht den kleinsten technisch erforderlichen Providerweg.

Der korrigierte Spike verwendet:

- `DeflateStream` aus `System.dll`;
- einen fest eingebetteten Raw-Deflate-Testvektor;
- eine eigene CRC32-Berechnung;
- ein Binärliteral für `CREATE ASSEMBLY`;
- einen positiven SQL-Server-2022-Linux-Gate mit tatsächlichem CLR-Aufruf,
  Ergebnisprüfung und Uninstall.

Ein erfolgreicher Spike-Lauf belegt ausschließlich die technische
Deploybarkeit dieses Deflate-/CRC32-Primitivs. Er ist kein Nachweis für einen
sicheren Parser beliebiger ZIP-Container, keine vollständige Plattformmatrix
und keine Produktfreigabe.

## Nächster Schritt

Zuerst den korrigierten Spike in GitHub Actions ausführen und den positiven
SQL-Server-2022-Linux-Befund festhalten. Danach folgen die gezielten Runtime-
Läufe auf SQL Server 2019 und 2025 sowie Windows. Erst anschließend darf der
produktive Provider-Slice mit eigener Benutzerfreigabe, vollständigem
ZIP-Parservertrag, Limits und Negativtestmatrix beginnen.

## Quellen

- Microsoft: [Supported .NET Framework libraries – SQL Server](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/database-objects/supported-net-framework-libraries?view=sql-server-ver17).
- Microsoft: [DeflateStream Class](https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.deflatestream?view=netframework-4.8.1).
- Microsoft: [CREATE ASSEMBLY](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-assembly-transact-sql?view=sql-server-ver17).
- Microsoft: [clr strict security](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/clr-strict-security?view=sql-server-ver17).
- Microsoft: [sys.sp_add_trusted_assembly](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-add-trusted-assembly-transact-sql?view=sql-server-ver17).
- PKWARE: [ZIP File Format Specification (APPNOTE)](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT).

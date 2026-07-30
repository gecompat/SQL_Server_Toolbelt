# ZIP-Archiv-Moduldesign (TC-2026-034)

## Zweck

Dieses Dokument beschreibt die erste Verarbeitungswelle fuer `TC-2026-034` als
V1A-Vertragsentwurf. Ziel ist ein risikoarmer Einstieg in die ZIP-Capability,
ohne Dateisystemzugriff und ohne automatische Extraktion ganzer Archive.

Der Fokus liegt auf einer kontrollierten In-memory-Extraktion einzelner
Eintraege aus einem ZIP-Archiv, das als `varbinary(max)` geliefert wird.

## Wellenstand

- Kandidat: `TC-2026-034`
- Welle: Verarbeitungswelle 2 (Implementierungswelle V1A)
- Stand: Vertragsbasis finalisiert, Implementierungswelle aktiviert
- Implementierungsfreigabe: erteilt am 2026-07-30

## V1A-Scope

### Enthalten

- genau ein Modul-Slice: In-memory-ZIP-Extraktion einzelner Eintraege;
- Eingabe des ZIP-Containers als `varbinary(max)`;
- Ergebnis als fachliches tabellarisches Resultset gemaess USP-Vertrag;
- kontrollierte Pruefung auf untrusted input inklusive Grenzwerten.

### Ausgeschlossen

- Dateisystempfade als Eingabe oder Ausgabe;
- Extraktion kompletter Archive in Verzeichnisse;
- ZIP-Erzeugung (Create) in derselben Welle;
- unkontrollierte Weitergabe von Dateinamen als Pfadziele;
- implizite Rekursion in verschachtelte Archive;
- automatische Entschluesselung verschluesselter Eintraege.

## Vorgeschlagener Modulzuschnitt (Arbeitsnamen)

- Modul-ID: `toolbelt.archive.zip-memory`
- Primaeres Objekt (Version 1A): `toolbelt_archive.USP_ExtractZipEntryFromBinary`

Der Objektname ist ein Arbeitsname fuer die Vertragsrunde und noch kein
finaler Runtime-Vertrag.

## Geplanter USP-Vertrag (V1A-Arbeitsstand)

### Eingabeparameter

- `@ZipArchive varbinary(max) = NULL`
- `@EntryName nvarchar(1024) = NULL`
- `@MaxEntryBytes bigint = 104857600` (100 MiB)
- `@MaxCompressionRatio decimal(9,2) = 200.00`
- `@FailIfEncrypted bit = 1`
- `@ResultTable sysname = NULL`
- `@KeepData bit = 0`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

### Ergebnisvertrag (bei `@Hilfe = 0`)

Genau ein fachliches Resultset mit einer Zeile bei Erfolg:

- `EntryName nvarchar(1024)`
- `CompressedBytes bigint`
- `UncompressedBytes bigint`
- `CompressionMethod int`
- `Crc32 int NULL`
- `IsEncrypted bit`
- `EntryPayload varbinary(max)`

Fehler werden mit stabiler, dokumentierter Semantik signalisiert. Bei gesetzter
`@ResultTable` wird kein fachliches `SELECT` ausgegeben.

### Hilfevertrag

Der USP-Vertrag aus `Documentation/Standards/USP_CONTRACT.md` gilt vollstaendig,
einschliesslich `@Hilfe`, `@Debug`, `@ResultTable` und `@KeepData`.

## Sicherheits- und Robustheitsregeln (V1A)

- Jeder Entry-Name wird als untrusted input behandelt.
- Keine Pfadauflosung in Dateisystempfade, daher kein Schreibziel und keine
  Dateisystem-Seiteneffekte.
- Harte Ablehnung bei Ueberschreitung von `@MaxEntryBytes`.
- Harte Ablehnung bei Ueberschreitung von `@MaxCompressionRatio`.
- Verschluesselte Eintraege werden bei `@FailIfEncrypted = 1` abgelehnt.
- Header- oder Metadateninkonsistenzen fuehren zu kontrolliertem Fehler, nicht
  zu stiller Teilverarbeitung. V1A berechnet die CRC32 des extrahierten
  Payloads nicht neu; deshalb wird für V1A keine Payload-CRC-Validierung
  behauptet.
- Keine Verarbeitung von nested ZIP-Containern in V1A.

## Tatsaechliche V1A-Funktionsgrenzen

Die implementierte Version `1.0.0` ist ein T-SQL-Binary-Parser mit engerem
Umfang als die ursprüngliche Vertragsabsicht:

- Payload-Extraktion ausschließlich für ZIP Compression Method `0` (`Stored`);
- kein Deflate (Method `8`), Deflate64 oder anderes Verfahren;
- kein ZIP64: verarbeitet werden nur die klassischen EOCD- und 32-Bit-
  Größen-/Offsetfelder;
- CRC32 wird als ZIP-Metadatum ausgegeben und zwischen ausgelesenen Headern
  auf Konsistenz geprüft, nicht über den zurückgegebenen Payload neu berechnet;
- die Byte-/Zeichen-Kodierung von Entry-Namen ist kein vollständiger UTF-8- oder
  CP437-Dekodierungsvertrag.

Diese Grenzen sind produktrelevant. Sie werden weder durch vorhandene Tests
noch durch die Architektur als unterstützt behauptet.

## Optionale CLR-Folgewelle

`AP-2026-021` ist als reiner Providervertrag abgeschlossen. Er beschreibt einen
C#-SQL-CLR-Slice für ZIP Method `0` und `8`, eine explizite Payload-CRC-Prüfung,
Assembly-Trust und die erforderlichen Plattform-Spikes. Es entsteht daraus kein
Runtime-Objekt und keine Implementierungsfreigabe. Details:
[ZIP_CLR_PROVIDER_DESIGN.md](./ZIP_CLR_PROVIDER_DESIGN.md).

## Provider-Entscheidung fuer Welle 1

V1A ist auf einen In-memory-Provider begrenzt.

Begruendung:

- geringere Angriffsflaeche gegenueber Dateisystem-Providern;
- frueher nutzbarer Kernvertrag ohne Pfad-/ACL-Abhaengigkeiten;
- saubere Trennung zu `TC-2026-037` (Datei-I/O) und `TC-2026-038`
  (Directory Listing).

## Abgrenzung zu Nachbar-Kandidaten

- `TC-2026-033`: bleibt read-only Metadaten-Listing ohne Payload-Extraktion.
- `TC-2026-034`: V1A ist nur In-memory-Extraktion einzelner Eintraege.
- `TC-2026-037`: dateibasierte Ein-/Ausgabe bleibt separater Provider.
- `TC-2026-035` und `TC-2026-036`: Kompressionsverfahren bleiben getrennte
  Capabilities.

## Finalisierte V1A-Entscheidungen

1. `Create` bleibt ausserhalb von V1A und wird als spaeterer Slice behandelt.
2. Duplicate Entry-Namen werden in V1A als expliziter Vertragsfehler behandelt.
3. Default-Limits sind verbindlich: `@MaxEntryBytes = 104857600` und
  `@MaxCompressionRatio = 200.00`.
4. Bei `@FailIfEncrypted = 0` liefert ein verschluesselter Entry einen
  expliziten Status ohne Payload, nicht still ein leeres Erfolgsergebnis.

## Testmatrix fuer Verarbeitungswelle 2 (Implementierung)

### Pflichtfaelle

- gueltiger Einzel-Entry (klein, mittel, gross unterhalb Limit);
- Entry nicht vorhanden;
- leeres Archiv und ungueltige ZIP-Struktur;
- ZIP64-Archive liegen ausserhalb des V1A-Vertrags und dürfen nicht als
  unterstützt ausgewiesen werden;
- Entry ueber `@MaxEntryBytes`;
- Entry ueber `@MaxCompressionRatio`;
- verschluesselter Entry mit `@FailIfEncrypted = 1`;
- CRC-Fehler;
- duplicate Entry-Namen gemaess finaler Semantik;
- kompletter USP-Hilfevertrag inklusive `@ResultTable` und `@KeepData`.

### Lifecycle

- lokale Installation, Wiederholungsdeployment, Uninstall;
- zentrale Installation und Uninstall;
- statische Vertragspruefung und modulbezogene Runtime-Evidenz.

## Nicht-Ziele von V1A

- Dateiexport in Verzeichnisse;
- rekursive Archiventpackung;
- Entschluesselung passwortgeschuetzter Archive;
- allgemeiner Binary-File-I/O-Adapter;
- Performancegarantie fuer beliebige LOB-Groessen.

## Naechster Schritt

V1A gezielt auf SQL Server 2025 Linux validieren. Ein optionaler CLR-Slice wird
nur nach Build-/Deployment-Spike und separater Implementierungsfreigabe
begonnen.

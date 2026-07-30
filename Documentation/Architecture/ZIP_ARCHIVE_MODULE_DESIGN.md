# ZIP-Archiv-Moduldesign (TC-2026-034)

## Zweck

Dieses Dokument beschreibt die erste Verarbeitungswelle fuer `TC-2026-034` als
V1A-Vertragsentwurf. Ziel ist ein risikoarmer Einstieg in die ZIP-Capability,
ohne Dateisystemzugriff und ohne automatische Extraktion ganzer Archive.

Der Fokus liegt auf einer kontrollierten In-memory-Extraktion einzelner
Eintraege aus einem ZIP-Archiv, das als `varbinary(max)` geliefert wird.

## Wellenstand

- Kandidat: `TC-2026-034`
- Welle: Verarbeitungswelle 1 (Vertragswelle)
- Stand: Vertragsentwurf vorhanden, keine Runtime-Implementierung
- Implementierungsfreigabe: offen (separate Benutzerentscheidung erforderlich)

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
- CRC- oder Strukturfehler fuehren zu kontrolliertem Fehler, nicht zu stiller
  Teilverarbeitung.
- Keine Verarbeitung von nested ZIP-Containern in V1A.

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

## Offene Punkte vor Implementierungsfreigabe

1. Soll ZIP-Erzeugung (Create) in dieselbe Modulversion oder in einen spaeteren
   Slice verschoben werden?
2. Wie ist Duplicate-Name-Semantik im Archiv vertraglich zu behandeln
   (erster Treffer, letzter Treffer, expliziter Fehler)?
3. Welche finalen Standardwerte gelten fuer `@MaxEntryBytes` und
   `@MaxCompressionRatio`?
4. Soll bei `@FailIfEncrypted = 0` ein verschluesselter Entry als harter Fehler,
   als leeres Ergebnis oder als expliziter Status ausgegeben werden?

## Testmatrix fuer Verarbeitungswelle 2 (Implementierung)

### Pflichtfaelle

- gueltiger Einzel-Entry (klein, mittel, gross unterhalb Limit);
- Entry nicht vorhanden;
- leeres Archiv und ungueltige ZIP-Struktur;
- ZIP64-Faelle im unterstuetzten Bereich;
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

Nach Benutzerentscheid zu den offenen Punkten wird ein separates
Implementierungsarbeitspaket fuer den V1A-In-memory-Extraktionsslice aktiviert.

# FILE_CONTENT_MODULE_DESIGN

## Entscheidung

Dieses Dokument beschreibt den Architekturvertrag für `toolbelt.file.content`.
Es ist eine dauerhafte Entscheidung im Sinne von
[DECISIONS.md](DECISIONS.md).

## Scope

- Modul: `toolbelt.file.content`
- Version: `1.0.0`
- Zielversionen: SQL Server 2019, 2022, 2025
- Plattformen: Windows und Linux

## Ziel

Kontrolliertes Lesen von Text- und Binärdateien aus dem Dateisystem über
einen sicheren, allowlist-basierten Vertrag. Der erste Slice beschränkt sich
auf Lesen; Schreiben bleibt einem späteren Slice oder einem externen Worker
vorbehalten.

## Nicht-Ziele

- Schreiben von Dateien in Slice 1.
- Rekursive Directory-Listing (siehe `TC-2026-038`).
- Vollständige Codepage-Unterstützung; nur UTF-8/UTF-16-LE-BOM sowie
  Windows-1252 als Fallback.
- Symlink-Auflösung oder ACL-Prüfung innerhalb von T-SQL.

## Technologie

- **Provider:** `OPENROWSET(BULK...)` als einziger erster Provider.
- **Kein CLR:** `EXTERNAL_ACCESS`/`UNSAFE` ist unter SQL Server Linux nicht
  unterstützt und wird daher nicht als Default verwendet.
- **Kein xp_cmdshell / OLE Automation:** Undokumentierte oder übermäßig
  mächtige Mechanismen sind keine Vertragsgrundlage.

## Sicherheitsmodell

1. **Root-Allowlist:** `toolbelt_file.FileContentRootAllowlist` enthält
   erlaubte Root-Pfade. Nur aktive (`IsActive = 1`) Einträge gelten.
   Nach Slash-Normalisierung gilt ein nicht leerer Root literal: entweder
   der exakt gleiche Pfad einschließlich Länge oder ein Pfad unter seiner
   Verzeichnisgrenze (`Root/`). Ein abschließender Slash ist optional.
   Geschwisterpräfixe wie `/safe-old` gehören nicht zu `/safe`; `%`, `_` und
   Klammern im Root sind normale Zeichen und keine Suchmuster.
2. **Absolutpfad-Zwang:** Relative Pfade werden abgelehnt.
3. **Traversal-Schutz:** Pfade mit `..`-Segmenten werden abgelehnt.
4. **Plattformnormalisierung:** Backslash und Slash werden für Vergleich
   normalisiert; Vergleich erfolgt mit `Latin1_General_100_BIN2`.
   Beide bestehenden Procedures verwenden hierfür das SQLCMD-Queryfragment
   `Source/FileContentRootPredicate.sql`; es legt kein zusätzliches Objekt an.
   Die Prüfung ist lexikalisch; eine Auflösung von Dateisystemlinks oder
   zusätzliche Dateisystemberechtigungen sind damit nicht nachgewiesen.
5. **UNC-Unterstützung:** UNC-Pfade sind erlaubt, müssen aber ebenfalls in
   der Allowlist liegen.

## Fehlerverhalten

Fachliche Fehler (ungültiger Pfad, Allowlist, Traversal, Größe, Encoding)
werden als standardisiertes Resultset mit `IsValid = 0` und
`ValidationCode` zurückgegeben. Engine-Fehler aus `OPENROWSET(BULK...)`
werden nicht umklassifiziert und propagieren als `THROW`.

## Ergebnisvertrag

### USP_LoadBinaryFile

| Spalte | Typ |
|---|---|
| Content | `varbinary(max)` |
| BytesRead | `bigint` |
| IsValid | `bit` |
| ValidationCode | `int` |
| ValidationMessage | `nvarchar(4000)` |

### USP_LoadTextFile

| Spalte | Typ |
|---|---|
| Content | `nvarchar(max)` |
| BytesRead | `bigint` |
| EncodingDetected | `nvarchar(128)` |
| BomPresent | `bit` |
| IsValid | `bit` |
| ValidationCode | `int` |
| ValidationMessage | `nvarchar(4000)` |

## Encoding-Erkennung

Die Datei wird genau einmal als `SINGLE_BLOB` aufgenommen. Bytezahl, erste vier
BOM-Bytes und Textdecoder verwenden denselben Snapshot. `@MaxBytes` wird danach
geprüft; es besteht keine Vorallokations- oder Heapgarantie für OPENROWSET.
UTF-8-BOM und UTF-16-LE-BOM werden entfernt. UTF-8 wird über eine explizit
UTF8-collatierte varchar-Spalte dekodiert und binär samt Länge zurückgeprüft;
UTF-16 LE verlangt gerade Bytezahl. Ohne BOM wird Windows-1252 explizit auch
unter Linux dekodiert. Ungültige Bytes/Providerfehler erzeugen 51326;
UTF-16 BE und UTF-32 bleiben nicht unterstützt (51325).

## Abhängigkeiten

Keine Runtime-Abhängigkeiten zu anderen Toolbelt-Modulen. Für zukünftige
Slices können `TC-2026-022` (Work-Type-Katalog) und `TC-2026-017`
(Error Envelope) relevant werden.

## Offene Punkte für spätere Slices

- Schreiben von Text- und Binärdateien.
- Externer Worker-Provider.
- Chunking/Streaming für Dateien > 2 GB.
- Erweiterte Codepage-Fallbacks.
- ACL- und Symlink-Prüfung.

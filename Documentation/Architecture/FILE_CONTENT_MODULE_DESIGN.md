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
- Vollständige Codepage-Unterstützung; nur UTF-8/UTF-16/UTF-32-BOM sowie
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
2. **Absolutpfad-Zwang:** Relative Pfade werden abgelehnt.
3. **Traversal-Schutz:** Pfade mit `..`-Segmenten werden abgelehnt.
4. **Plattformnormalisierung:** Backslash und Slash werden für Vergleich
   normalisiert; Vergleich erfolgt mit `Latin1_General_100_BIN2`.
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

Die ersten 4 Bytes der Datei werden als `SINGLE_BLOB` gelesen und auf BOMs
geprüft. Dateien ohne BOM werden mit `@FallbackEncoding` gelesen. Im
Version-1-Slice ist nur `Windows-1252` als Fallback erlaubt.

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

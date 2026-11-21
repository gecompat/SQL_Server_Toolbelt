# USP_ExtractZipArchiveToDirectory

Extrahiert ein vollständiges ZIP aus `varbinary(max)` in einen relativen Ordner
eines registrierten Dateisystemroots. Die Prozedur läuft lokal in der
Toolbelt-Datenbank auf Windows mit einem festen NTFS-Laufwerk.

```sql
-- @Zip enthält die vollständigen Bytes des zu entpackenden ZIP-Archivs.
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive = @Zip,
    @RootAlias = N'ContosoExports',
    @RelativeDirectory = N'Inbox';
```

In Central-Directory-Reihenfolge gibt die Prozedur je Eintrag
`Ordinal`, `EntryName`, `EntryKind`, `Status`, `BytesWritten` und `ErrorCode`
aus. `Status` ist `completed`, `failed` oder `not_attempted`. Angelegte oder
bereits vorhandene Verzeichnisse erhalten `directory` und null geschriebene
Bytes als Wert `0`. Implizite Elternverzeichnisse haben keine eigene
Zeile. Ein leeres ZIP liefert ein leeres Resultset.

Der Preflight prüft vor der Extraktion die erkennbare ZIP-Struktur, die
Ressourcengrenzen sowie die Pfade und bestehenden Zielkonflikte. Scheitert
dieser Schritt an einem zuordenbaren Eintrag, bleiben sämtliche anderen
Einträge `not_attempted`. Bei einem Fehler nach dem Preflight bleiben frühere
Dateien und angelegte Verzeichnisse bestehen. Jede Datei wird nach Größen-
und CRC-Prüfung separat aus einer Stagingdatei veröffentlicht. Ein erst
danach festgestellter Fehler behält `completed` und meldet den Fehlercode.
Ein SQL-Rollback nimmt veröffentlichte Dateien nicht zurück.

Komponenten in der Form automatisch erzeugter NTFS-Kurznamen wie
`LONGNA~1.TXT` werden bereits beim Preflight abgelehnt. Neue Dateien
werden mit einer geschützten DACL für die gewählte Identität angelegt.

Der Root braucht `AllowWrite`, für neue Verzeichnisse auch
`AllowCreateDirectory`. Optional darf der Administrator einen `WorkPath` auf
demselben Root konfigurieren. Standardmäßig verwendet die Prozedur die
Windows-Anmeldung des Aufrufers. `ServiceAccount` erfordert die dafür
vorgesehene Datenbankrolle und `AllowServiceAccount` am Root.

`@OverwriteExistingFiles = 1` setzt zusätzlich `AllowZipOverwrite = 1` am
Root voraus. Der Administrator reserviert diesen Root und seine
Arbeitsverzeichnisse für die ausgewählte Windows-Identität. Besitzer und
DACL werden am tatsächlichen Handle geprüft. Weitere Mutationspfade, bereits
offene fremde Schreibhandles, überlappende Roots und unabhängige Schreiber
unter derselben Windows-Identität sind aus diesem Betriebsscope
ausgeschlossen. Aliase desselben Roots mit gesetztem `AllowZipOverwrite`
verwenden dieselbe Sperre. Eine nach dem Preflight neu aufgetauchte Datei wird auch bei
aktiviertem Überschreiben nicht ersetzt.

Die [SQL-Hilfe](../../../Metadata/UsageSkills/toolbelt_archive/USP_ExtractZipArchiveToDirectory.md)
enthält Parameter, Defaultwerte und technische Grenzwerte.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig. |
| `@RootAlias` | `sysname` | `NULL` | Input | Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig. |
| `@RelativeDirectory` | `nvarchar(4000)` | `N''` | Input | Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig. |
| `@OverwriteExistingFiles` | `bit` | `0` | Input | 0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig. |
| `@MaxArchiveBytes` | `bigint` | `67108864` | Input | Archivbytes. 1 bis 268435456, NULL ungültig. |
| `@MaxEntries` | `bigint` | `1000` | Input | Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig. |
| `@MaxTotalExpandedBytes` | `bigint` | `268435456` | Input | Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig. |
| `@MaxPathLength` | `int` | `1024` | Input | ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Input | Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag. |
| `@KeepData` | `bit` | `0` | Input | Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | Input | 0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus. |
<!-- API_PARAMETERS:END -->

```sql
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @Hilfe = 1;
```

# toolbelt_filesystem.USP_TranscodeTextFile

## Zweck

Konvertiert eine Textdatei zwischen zwei expliziten Codepages. Rückgabe: BytesWritten, RootAlias, RelativePath, State.

## Parameter

@SourceRootAlias, @SourceRelativePath, @SourceEncodingName, @TargetRootAlias, @TargetRelativePath, @TargetEncodingName, @WriteBom, @Overwrite, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

## NoOverwrite

Bei `@Overwrite = 0` veröffentlicht der Provider ausschließlich per nicht überschreibendem `File.Move`. Auch ein erst während des Staging-Schreibens erzeugtes Ziel wird nicht ersetzt; der frühere Existenzcheck allein ist keine Veröffentlichungsbarriere. `@Overwrite = 1` behält den bisherigen Move-/Replace-Pfad. Fehlgeschlagenes Schreiben räumt die eigene Staging-Datei auf; ein vorhandenes Ziel bleibt bei NoOverwrite unverändert. Dies ist keine allgemeine NTFS-, Power-Loss- oder Caller-Impersonation-Garantie.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@SourceRootAlias` | `sysname` | `NULL` | Input | Konfigurierter Root-Alias der Quelldatei. |
| `@SourceRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad der Quelldatei. |
| `@SourceEncodingName` | `nvarchar(128)` | `NULL` | Input | Encoding der Quelldatei. |
| `@TargetRootAlias` | `sysname` | `NULL` | Input | Konfigurierter Root-Alias der Zieldatei. |
| `@TargetRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad der Zieldatei. |
| `@TargetEncodingName` | `nvarchar(128)` | `NULL` | Input | Encoding der Zieldatei. |
| `@WriteBom` | `bit` | `0` | Input | 1 schreibt einen BOM soweit das Encoding dies vorsieht; 0 unterdrückt ihn. |
| `@Overwrite` | `bit` | `0` | Input | 0 verweigert Überschreiben vorhandener Dateien; 1 erlaubt es. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset. |
| `@KeepData` | `bit` | `0` | Input | Gilt ausschließlich mit @ResultTable. |
| `@Debug` | `tinyint` | `0` | Input | Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich dieses Help-Resultset. |

## Voraussetzungen für den Aufruf

- Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

## Beispielaufruf

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_TranscodeTextFile
 @SourceRootAlias=N'ExampleRoot', @SourceRelativePath=N'input.txt', @SourceEncodingName=N'utf-8', @TargetRootAlias=N'ExampleRoot', @TargetRelativePath=N'output.txt', @TargetEncodingName=N'utf-16', @Overwrite=0, @ExecutionIdentity=N'Caller';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/Procedures.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)

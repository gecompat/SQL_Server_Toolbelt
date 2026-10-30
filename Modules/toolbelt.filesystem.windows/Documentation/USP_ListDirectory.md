# toolbelt_filesystem.USP_ListDirectory

## Zweck

Listet Directory-Entries, optional rekursiv und begrenzt. Rückgabe: EntryOrdinal, RelativePath, EntryType, SizeBytes, LastWriteTimeUtc, IsReparsePoint.

## Parameter

@RootAlias, @RelativePath, @Recursive, @MaxDepth, @MaxEntries, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen
Überschreitet die Enumeration `@MaxEntries`, bricht die Procedure mit Fehler
`51540` ab. Die Meldung nennt den verwendeten Grenzwert und empfiehlt, ihn zu
erhöhen oder `@RelativePath` weiter einzugrenzen; es wird keine unvollständige
Liste zurückgegeben.

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `N''` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
| `@Recursive` | `bit` | `0` | Input | 1 arbeitet rekursiv, 0 nur im gewählten Verzeichnis. |
| `@MaxDepth` | `int` | `32` | Input | Maximale rekursive Verzeichnistiefe. |
| `@MaxEntries` | `int` | `10000` | Input | Maximale Anzahl zu bearbeitender Einträge. |
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
EXEC toolbelt_filesystem.USP_ListDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'', @Recursive=0, @MaxEntries=100, @ExecutionIdentity=N'Caller';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/Procedures.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)

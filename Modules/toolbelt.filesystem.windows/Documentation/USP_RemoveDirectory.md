# toolbelt_filesystem.USP_RemoveDirectory

## Zweck

Entfernt ein Directory; rekursiv nur explizit und begrenzt. Rückgabe: RootAlias, RelativePath, State.

## Parameter

@RootAlias, @RelativePath, @Recursive, @MaxDepth, @MaxEntries, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

Das Startdirectory hat Tiefe0. `@MaxDepth = 0` erlaubt direkte Dateien, aber
kein Childdirectory, auch kein leeres. Bei rekursiver Löschung muss jedes
Childdirectory innerhalb der Tiefe liegen; alle Nachfahren (Dateien und Directories)
zählen gegen `@MaxEntries`. Tiefe- und Eintragsüberschreitungen werden vor
der ersten Löschung abgewiesen. Die Fassade verwendet weiterhin `51540`;
der Provider benennt die Grenze als `DepthLimitExceeded` beziehungsweise
`EntryLimitExceeded`.

Nur Einträge des vollständigen Prüfplans werden gelöscht, Directories
nichtrekursiv. Bei nachfolgendem I/O-/Racefehler sind Teilzustände möglich;
Dateisystemänderungen sind nicht durch eine SQL-Transaktion rücksetzbar.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Input | Betreiberseitig konfigurierter Root-Alias; keine beliebigen Pfade. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad im Root-Alias; keine Traversierung. |
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
EXEC toolbelt_filesystem.USP_RemoveDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'own-example-dir', @Recursive=0, @ExecutionIdentity=N'Caller';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/Procedures.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)

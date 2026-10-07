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

# toolbelt_filesystem.USP_ListDirectory

## Zweck

Listet Directory-Entries, optional rekursiv und begrenzt. Rückgabe: EntryOrdinal, RelativePath, EntryType, SizeBytes, LastWriteTimeUtc, IsReparsePoint.

## Parameter

@RootAlias, @RelativePath, @Recursive, @MaxDepth, @MaxEntries, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

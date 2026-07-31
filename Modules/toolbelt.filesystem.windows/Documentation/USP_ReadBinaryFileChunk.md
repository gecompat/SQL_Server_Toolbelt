# toolbelt_filesystem.USP_ReadBinaryFileChunk

## Zweck

Liest einen begrenzten Binary-Chunk. Rückgabe: Content, BytesRead, NextByteOffset, EndOfFile.

## Parameter

@RootAlias, @RelativePath, @ByteOffset, @MaxBytes, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

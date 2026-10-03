# toolbelt_filesystem.USP_WriteBinaryFile

## Zweck

Schreibt varbinary(max) gestreamt und atomar. Rückgabe: BytesWritten, RootAlias, RelativePath, State.

## Parameter

@RootAlias, @RelativePath, @Content, @Overwrite, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

## NoOverwrite

Bei `@Overwrite = 0` veröffentlicht der Provider ausschließlich per nicht überschreibendem `File.Move`. Auch ein erst während des Staging-Schreibens erzeugtes Ziel wird nicht ersetzt; der frühere Existenzcheck allein ist keine Veröffentlichungsbarriere. `@Overwrite = 1` behält den bisherigen Move-/Replace-Pfad. Fehlgeschlagenes Schreiben räumt die eigene Staging-Datei auf; ein vorhandenes Ziel bleibt bei NoOverwrite unverändert. Dies ist keine allgemeine NTFS-, Power-Loss- oder Caller-Impersonation-Garantie.

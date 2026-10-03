# toolbelt_filesystem.USP_WriteBinaryFile

## Zweck

Schreibt varbinary(max) gestreamt und atomar. Rückgabe: BytesWritten, RootAlias, RelativePath, State.

## Parameter

@RootAlias, @RelativePath, @Content, @Overwrite, @ExecutionIdentity, @ResultTable, @KeepData, @Debug, @Hilfe

Alle Pfade sind relativ zum konfigurierten Root-Alias. `Caller` ist der Default für `@ExecutionIdentity`; `ServiceAccount` ist explizit. Die Procedure folgt dem Standardvertrag für `@ResultTable`, `@KeepData`, `@Debug` und `@Hilfe`.

## Grenzen

Windows-only. Absolute oder UNC-Pfade sowie Reparse Points werden abgewiesen. Die vollständigen Sicherheits-, Encoding- und Runtime-Regeln stehen in [WINDOWS_FILESYSTEM_PROCEDURES.md](./WINDOWS_FILESYSTEM_PROCEDURES.md).

## NoOverwrite

Bei `@Overwrite = 0` veröffentlicht der Provider ausschließlich per nicht überschreibendem `File.Move`. Auch ein erst während des Staging-Schreibens erzeugtes Ziel wird nicht ersetzt; der frühere Existenzcheck allein ist keine Veröffentlichungsbarriere. `@Overwrite = 1` behält den bisherigen Move-/Replace-Pfad. Bei Fehlern versucht der Provider, seine eigene Staging-Datei unter derselben gewählten Identität zu bereinigen; der erste Fehler bleibt erhalten. Scheitern Identitätswiederherstellung oder Bereinigung, können Reste bleiben. Ein vorhandenes Ziel bleibt bei NoOverwrite unverändert. Dies ist keine allgemeine NTFS-, Power-Loss- oder Caller-Impersonation-Garantie.

-- Nur synthetische Vorschau, keine DDL-Ausführung durch Toolbelt.
EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
-- Voraussetzung: Caller hat die synthetische Quelltabelle selbst angelegt.
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',
    @TargetSchema=N'dbo',@TargetTable=N'SyntheticClone',@IncludeIdentity=1;

-- Opt-in Properties mit typisiertem Scriptbatch; Ausführung bleibt extern.
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',
    @TargetSchema=N'dbo',@TargetTable=N'SyntheticClone',@IncludeExtendedProperties=1;

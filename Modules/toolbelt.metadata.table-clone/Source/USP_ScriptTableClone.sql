-- ============================================================================
-- Objekt: toolbelt_metadata.USP_ScriptTableClone; Stored Procedure
-- Zweck: Script-only-Vorschau für explizite same-database Tabellenziele
-- Vertrag: USP_CONTRACT 1.0; Documentation/USP_ScriptTableClone.md
-- Parameter: SourceSchema/SourceTable/TargetSchema/TargetTable nvarchar(max)=NULL,
--            IncludeIdentity/IncludeExtendedProperties bit=0; TableMap sysname=NULL,
--            ExternalReferenceRule varchar(16)=REJECT; IncludeTriggers bit=0; Standardtail
-- Resultset: Ordinal int, ObjectKind varchar(32), TargetName nvarchar(776),
--            ScriptText nvarchar(max); alle NOT NULL
-- Dependencies: toolbelt.core.result-table >=1.0.0 same_database;
--               IncludeTriggers=1: exakt gepinnter Parser 2.0.1 same_database
-- Rechte: EXECUTE, datenbankweite VIEW DEFINITION für vollständige FK-/Kollisionssicht
-- Versionen/Plattformen: SQL Server 2019/2022/2025 CL150+, Windows/Linux;
--                       Trigger-Opt-in ausschließlich Windows
-- Fehler: 53900-53909; Enginefehler unverändert; keine DDL-Ausführung/Datenkopie
-- Performance: begrenzte Metadatenmaterialisierung, vollständiger Plan vor Ausgabe
-- Einschränkungen: Momentaufnahme; Unsupported bricht ab; kein Drift-/Recoveryversprechen
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableClone
    @SourceSchema nvarchar(max)=NULL,
    @SourceTable nvarchar(max)=NULL,
    @TargetSchema nvarchar(max)=NULL,
    @TargetTable nvarchar(max)=NULL,
    @IncludeIdentity bit=0,
    @IncludeExtendedProperties bit=0,
    @TableMap sysname=NULL,
    @ExternalReferenceRule varchar(16)='REJECT',
    @IncludeTriggers bit=0,
    @ResultTable sysname=NULL,
    @KeepData bit=0,
    @Debug tinyint=0,
    @Hilfe bit=0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_metadata' AS sysname) AS SchemaName,
            CAST(N'USP_ScriptTableClone' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'Ordinal', N'int', 1, 0, NULL, CAST(N'1-basiert lückenlos; Ausführung ausschließlich außerhalb dieser API.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ObjectKind', N'varchar(32)', 1, 0, NULL, CAST(N'SESSION_OPTION, TABLE, DEFAULT, CHECK, PRIMARY_KEY, UNIQUE_CONSTRAINT, INDEX, EXTENDED_PROPERTY, FOREIGN_KEY, FOREIGN_KEY_STATE sowie beim Trigger-Opt-in TRIGGER und TRIGGER_STATE.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'TargetName', N'nvarchar(776)', 1, 0, NULL, CAST(N'Gequoteter Zielname; Indexnamen mit Zieltabellenqualifier.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ScriptText', N'nvarchar(max)', 1, 0, NULL, CAST(N'Eine Anweisung; EXTENDED_PROPERTY ist ein typisierter DECLARE-plus-EXEC-Batch, TRIGGER ein fester Quell-SET-plus-sp_executesql-Batch mit innerem CREATE zuerst. Sieben SET-Zeilen zuerst; Latin1_General_100_BIN2.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'53900 Argumente,53901 Quelle/Sichtbarkeit,53902 Ziel/Sichtbarkeit,53903 Unsupported,53904 Namekollision,53905 Definitionen,53906 Ressourcen,53907 Dependency,53908 Namespace.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Computed/PERSISTED und Filter unterstützt; W1 ohne FK, W2 mit begrenzten FK-Zuständen. Trigger-Opt-in ohne dynamischen Body, EXECUTE AS, CLR, Verschlüsselung oder externe/unklare Referenzen; kein Kopieren von Funktionen/Prozeduren. Quelle während Planung strukturell stabil halten. Kein späterer Drift-/Kapazitätsnachweis.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE plus datenbankweite VIEW DEFINITION für vollständige FK-/Kollisionssicht; Computed und Trigger-Opt-in zusätzlich vorhandenes SELECT sys.sql_expression_dependencies. Trigger-Opt-in verlangt vollständige Assembly-/Binding-Sicht und SELECT auf vier Parser-TVFs. ResultTable zusätzlich Helper-EXECUTE. Keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetische Vorschau.' AS nvarchar(max)), CAST(N'EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N''dbo'',@SourceTable=N''SyntheticSource'',@TargetSchema=N''dbo'',@TargetTable=N''SyntheticClone'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@SourceSchema', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@SourceTable', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@TargetSchema', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@TargetTable', N'nvarchar(max)', 1, 1, N'NULL', CAST(N'Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@IncludeIdentity', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@IncludeExtendedProperties', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@TableMap', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@ExternalReferenceRule', N'varchar(16)', 0, 0, N'''REJECT''', CAST(N'Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@IncludeTriggers', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    IF @IncludeTriggers IS NULL
        THROW 53900,N'TableClone: IncludeTriggers darf im Fachmodus nicht NULL sein.',10;
    -- Grenze VOR Kompilierung des Kerns: CI-tempdb darf CS-Callerobjekte nicht eclipsen.
    IF LOWER(LEFT(@TableMap,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_' OR LOWER(LEFT(@ResultTable,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_'
        THROW 53908,N'TableClone: reservierter interner Tempnamespace ist kein Caller-Ziel.',1;
    IF EXISTS(SELECT 1 FROM (VALUES(N'#tbx_TableClone_Plan'),(N'#tbx_TableClone_Map'),(N'#tbx_TableClone_Order'),(N'#tbx_TableClone_Names'),(N'#tbx_TableClone_EpOwners'),
        (N'#tbx_TableClone_AstNodes'),(N'#tbx_TableClone_AstProperties'),(N'#tbx_TableClone_AstTokens'),(N'#tbx_TableClone_AstErrors')) names(Name) WHERE OBJECT_ID(N'tempdb..'+Name,N'U') IS NOT NULL)
        THROW 53908,N'TableClone: reservierter interner Tempnamespace ist im Caller belegt.',1;
    EXEC toolbelt_metadata.USP_ScriptTableCloneInternal
        @SourceSchema=@SourceSchema,@SourceTable=@SourceTable,@TargetSchema=@TargetSchema,
        @TargetTable=@TargetTable,@IncludeIdentity=@IncludeIdentity,@IncludeExtendedProperties=@IncludeExtendedProperties,
        @TableMap=@TableMap,@ExternalReferenceRule=@ExternalReferenceRule,@IncludeTriggers=@IncludeTriggers,@InternalPurpose='PREVIEW',
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug,@Hilfe=0;
END;
GO

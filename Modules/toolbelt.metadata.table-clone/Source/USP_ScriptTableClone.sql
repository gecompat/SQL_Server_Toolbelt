-- ============================================================================
-- Objekt: toolbelt_metadata.USP_ScriptTableClone; Stored Procedure
-- Zweck: Script-only-Vorschau für explizite same-database Tabellenziele
-- Vertrag: USP_CONTRACT 1.0; Documentation/USP_ScriptTableClone.md
-- Parameter: SourceSchema/SourceTable/TargetSchema/TargetTable nvarchar(max)=NULL,
--            IncludeIdentity/IncludeExtendedProperties bit=0; TableMap sysname=NULL, ExternalReferenceRule varchar(16)=REJECT; ResultTable/KeepData/Debug/Hilfe Standard
-- Resultset: Ordinal int, ObjectKind varchar(32), TargetName nvarchar(776),
--            ScriptText nvarchar(max); alle NOT NULL
-- Dependencies: toolbelt.core.result-table >=1.0.0 same_database
-- Rechte: EXECUTE, datenbankweite VIEW DEFINITION für vollständige FK-/Kollisionssicht
-- Versionen/Plattformen: SQL Server 2019/2022/2025 CL150+, Windows/Linux
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
    @ResultTable sysname=NULL,
    @KeepData bit=0,
    @Debug tinyint=0,
    @Hilfe bit=0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        DECLARE @Help TABLE(Section varchar(32) NOT NULL,Ordinal int NOT NULL,
            ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,
            IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,
            Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
        INSERT @Help VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.',NULL),
        ('PARAMETER',1,N'@SourceSchema','nvarchar(max)',1,0,N'NULL',N'Explizites Schema in Installationsdatenbank, 1-128 UTF-16-Codeeinheiten.',NULL),
        ('PARAMETER',2,N'@SourceTable','nvarchar(max)',1,0,N'NULL',N'Explizite reguläre diskbasierte Tabelle; VIEW DEFINITION erforderlich.',NULL),
        ('PARAMETER',3,N'@TargetSchema','nvarchar(max)',1,0,N'NULL',N'Bestehendes sichtbares Schema derselben Datenbank.',NULL),
        ('PARAMETER',4,N'@TargetTable','nvarchar(max)',1,0,N'NULL',N'Noch nicht existierender Zielname; keine automatische Namenswahl.',NULL),
        ('PARAMETER',5,N'@IncludeIdentity','bit',0,0,N'0',N'1 übernimmt Seed/Increment; 0 entfernt Identity-Eigenschaft ausdrücklich, niemals aktuellen Zähler.',NULL),
        ('PARAMETER',6,N'@IncludeExtendedProperties','bit',0,0,N'0',N'1 plant unterstützte Properties typgetreu; 0 lehnt relevante Properties ab.',NULL),
        ('PARAMETER',7,N'@TableMap','sysname',0,1,N'NULL',N'NULL ist W1-Einzelmodus; sonst fünfspaltige lokale Map mit 1-64 eindeutigen positiven MapOrdinals und vier nvarchar(max) NOT NULL-Identifiern.',NULL),
        ('PARAMETER',8,N'@ExternalReferenceRule','varchar(16)',0,0,N'REJECT',N'Byteexakt REJECT oder KEEP; KEEP nur im Mapmodus für sichtbare externe Referenzziele.',NULL),
        ('PARAMETER',9,N'@ResultTable','sysname',0,1,N'NULL',N'NULL liefert SELECT; sonst bestehende caller-lokale Temp-Tabelle.',NULL),
        ('PARAMETER',10,N'@KeepData','bit',0,1,N'0',N'0 Replace, 1 Append; NULL entspricht0.',NULL),
        ('PARAMETER',11,N'@Debug','tinyint',0,1,N'0',N'Nur Messages; keine persistierte Quellmetadaten-Ausgabe.',NULL),
        ('PARAMETER',12,N'@Hilfe','bit',0,1,N'0',N'1 umgeht sämtliche Prüfungen und Seiteneffekte.',NULL),
        ('RESULT_COLUMN',1,N'Ordinal','int',1,0,NULL,N'1-basiert lückenlos; Ausführung ausschließlich außerhalb dieser API.',NULL),
        ('RESULT_COLUMN',2,N'ObjectKind','varchar(32)',1,0,NULL,N'SESSION_OPTION, TABLE, DEFAULT, CHECK, PRIMARY_KEY, UNIQUE_CONSTRAINT, INDEX, EXTENDED_PROPERTY, FOREIGN_KEY oder FOREIGN_KEY_STATE.',NULL),
        ('RESULT_COLUMN',3,N'TargetName','nvarchar(776)',1,0,NULL,N'Gequoteter Zielname; Indexnamen mit Zieltabellenqualifier.',NULL),
        ('RESULT_COLUMN',4,N'ScriptText','nvarchar(max)',1,0,NULL,N'Eine Anweisung; ausschließlich EXTENDED_PROPERTY ist ein typisierter DECLARE-plus-EXEC-Batch. Sieben SET-Zeilen zuerst; Latin1_General_100_BIN2.',NULL),
        ('ERROR',1,NULL,NULL,NULL,NULL,NULL,N'53900 Argumente,53901 Quelle/Sichtbarkeit,53902 Ziel/Sichtbarkeit,53903 Unsupported,53904 Namekollision,53905 Definitionen,53906 Ressourcen,53907 Dependency,53908 Namespace.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Computed/PERSISTED und Filter unterstützt; W1 ohne FK, W2 mit begrenzten FK-Zuständen; keine Trigger/Permissions/Specialfeatures; Quelle während Planung strukturell stabil halten. Kein späterer Drift-/Kapazitätsnachweis.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE plus datenbankweite VIEW DEFINITION für vollständige FK-/Kollisionssicht; Computed zusätzlich vorhandenes SELECT sys.sql_expression_dependencies; ResultTable zusätzlich Helper-EXECUTE. Keine Rechteausweitung.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetische Vorschau.',N'EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N''dbo'',@SourceTable=N''SyntheticSource'',@TargetSchema=N''dbo'',@TargetTable=N''SyntheticClone'';');
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,
            CAST(N'toolbelt_metadata' AS sysname) SchemaName,
            CAST(N'USP_ScriptTableClone' AS sysname) ObjectName,
            Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
            WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5
            WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
        RETURN;
    END;
    -- Grenze VOR Kompilierung des Kerns: CI-tempdb darf CS-Callerobjekte nicht eclipsen.
    IF LOWER(LEFT(@TableMap,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_' OR LOWER(LEFT(@ResultTable,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_'
        THROW 53908,N'TableClone: reservierter interner Tempnamespace ist kein Caller-Ziel.',1;
    IF EXISTS(SELECT 1 FROM (VALUES(N'#tbx_TableClone_Plan'),(N'#tbx_TableClone_Map'),(N'#tbx_TableClone_Order'),(N'#tbx_TableClone_Names'),(N'#tbx_TableClone_EpOwners')) names(Name) WHERE OBJECT_ID(N'tempdb..'+Name,N'U') IS NOT NULL)
        THROW 53908,N'TableClone: reservierter interner Tempnamespace ist im Caller belegt.',1;
    EXEC toolbelt_metadata.USP_ScriptTableCloneInternal
        @SourceSchema=@SourceSchema,@SourceTable=@SourceTable,@TargetSchema=@TargetSchema,
        @TargetTable=@TargetTable,@IncludeIdentity=@IncludeIdentity,@IncludeExtendedProperties=@IncludeExtendedProperties,
        @TableMap=@TableMap,@ExternalReferenceRule=@ExternalReferenceRule,
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug,@Hilfe=0;
END;
GO

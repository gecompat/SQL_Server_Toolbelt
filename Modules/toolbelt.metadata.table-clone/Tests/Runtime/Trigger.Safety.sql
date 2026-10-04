-- Begrenzte eigene Negativquellen; keine Rechteerteilung oder fremde Metadatenänderung.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE dbo.SyntheticTriggerSafe(Id int NOT NULL);
CREATE TABLE dbo.SyntheticTriggerOutside(Id int NOT NULL);
CREATE TABLE #TriggerPrior(Ordinal int NOT NULL,ObjectKind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
    TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #TriggerPrior VALUES(-1,'SENTINEL',N'Synthetic',N'unchanged');
GO
CREATE PROCEDURE #AssertTriggerReject @ExpectedNumber int,@ExpectedState int,@CaseOrdinal int,@Map sysname=NULL
AS
BEGIN
    DECLARE @Number int=NULL,@State int=NULL,@BeforeTC int=@@TRANCOUNT,@BeforeXS int=XACT_STATE();
    DECLARE @SourceSchema nvarchar(max)=CASE WHEN @Map IS NULL THEN N'dbo' END,
        @SourceTable nvarchar(max)=CASE WHEN @Map IS NULL THEN N'SyntheticTriggerSafe' END,
        @TargetSchema nvarchar(max)=CASE WHEN @Map IS NULL THEN N'dbo' END,
        @TargetTable nvarchar(max)=CASE WHEN @Map IS NULL THEN N'SyntheticTriggerSafeClone' END;
    BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=@SourceSchema,@SourceTable=@SourceTable,
        @TargetSchema=@TargetSchema,@TargetTable=@TargetTable,@TableMap=@Map,@IncludeTriggers=1,@ResultTable=N'#TriggerPrior';END TRY
    BEGIN CATCH SELECT @Number=ERROR_NUMBER(),@State=ERROR_STATE();END CATCH;
    -- Callerzustand vor jeder datenlesenden Orakelauswertung aufnehmen.
    DECLARE @AfterTC int=@@TRANCOUNT,@AfterXS int=XACT_STATE();
    IF @Number IS NULL OR @Number<>@ExpectedNumber OR @State<>@ExpectedState OR @AfterTC<>@BeforeTC OR @AfterXS<>@BeforeXS
    BEGIN
        -- Nur begrenzte Testmetadaten, keine ursprünglichen Fehlermeldungen oder Objektnamen.
        DECLARE @FailureMessage nvarchar(2048)=CONCAT(N'Triggerablehnung: case=',@CaseOrdinal,N'; expected=',@ExpectedNumber,N'/',@ExpectedState,
            N'; actual=',COALESCE(CONVERT(nvarchar(11),@Number),N'NULL'),N'/',COALESCE(CONVERT(nvarchar(3),@State),N'NULL'),
            N'; tx=',@BeforeTC,N'/',@BeforeXS,N'->',@AfterTC,N'/',@AfterXS,N'.');
        THROW 54941,@FailureMessage,1;
    END;
    IF (SELECT COUNT(*) FROM #TriggerPrior)<>1 OR NOT EXISTS(SELECT 1 FROM #TriggerPrior WHERE Ordinal=-1 AND ObjectKind='SENTINEL' AND TargetName=N'Synthetic' AND ScriptText=N'unchanged')
       OR OBJECT_ID(N'dbo.SyntheticTriggerSafeClone') IS NOT NULL
        THROW 54941,N'Triggerablehnung hat Ausgabe oder Ziel verändert.',2;
END;
GO
-- EXEC wird auch bei syntaktisch gültigem dynamischen Body vollständig abgelehnt.
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTriggerReject ON dbo.SyntheticTriggerSafe AFTER INSERT AS BEGIN EXEC(N''SELECT 1;'');END;';
EXEC #AssertTriggerReject 53903,17,1;
DROP TRIGGER dbo.SyntheticTriggerReject;
-- Eine sichtbare lokale Tabelle außerhalb der Map wird nicht automatisch kopiert.
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTriggerReject ON dbo.SyntheticTriggerSafe AFTER INSERT AS BEGIN DECLARE @Count int;SELECT @Count=COUNT(*) FROM dbo.SyntheticTriggerOutside;END;';
EXEC #AssertTriggerReject 53903,16,2;
DROP TRIGGER dbo.SyntheticTriggerReject;
-- Ungelöste Deferred-Name-Bindung ist kein Beleg für einen sicheren Triggerklon.
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTriggerReject ON dbo.SyntheticTriggerSafe AFTER INSERT AS BEGIN DECLARE @Count int;SELECT @Count=COUNT(*) FROM dbo.SyntheticTriggerMissing;END;';
EXEC #AssertTriggerReject 53903,16,3;
DROP TRIGGER dbo.SyntheticTriggerReject;
-- Die externe Datenbankreferenz wird abgelehnt, ohne dort etwas zu verändern.
-- Systemkatalogreferenzen können ohne Dependencyzeile bleiben; der AST weist drei Namensparts ab.
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTriggerReject ON dbo.SyntheticTriggerSafe AFTER INSERT AS BEGIN DECLARE @Count int;SELECT @Count=COUNT(*) FROM tempdb.sys.tables;END;';
EXEC #AssertTriggerReject 53903,19,4;
DROP TRIGGER dbo.SyntheticTriggerReject;
-- Die eigene verschlüsselte Definition ist absichtlich nicht rekonstruierbar.
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTriggerReject ON dbo.SyntheticTriggerSafe WITH ENCRYPTION AFTER INSERT AS BEGIN SET NOCOUNT ON;END;';
EXEC #AssertTriggerReject 53903,15,5;
DROP TRIGGER dbo.SyntheticTriggerReject;
-- Eine fremde Objektart am deterministischen Namen darf niemals adoptiert werden.
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTriggerReject ON dbo.SyntheticTriggerSafe AFTER INSERT AS BEGIN SET NOCOUNT ON;END;';
DECLARE @Schema nvarchar(max)=N'dbo',@Table nvarchar(max)=N'SyntheticTriggerSafeClone',@Trigger nvarchar(max)=N'SyntheticTriggerReject';
DECLARE @Collision sysname=N'TR_'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(binary(4),DATALENGTH(@Schema)))+CONVERT(varbinary(max),@Schema)
    +CONVERT(binary(4),DATALENGTH(@Table))+CONVERT(varbinary(max),@Table)+CONVERT(binary(4),DATALENGTH(@Trigger))+CONVERT(varbinary(max),@Trigger)),2);
DECLARE @Sql nvarchar(max)=N'CREATE PROCEDURE dbo.'+QUOTENAME(@Collision)+N' AS SELECT 1 AS SyntheticSentinel;';
EXEC sys.sp_executesql @Sql;
DECLARE @CollisionId int=OBJECT_ID(N'dbo.'+QUOTENAME(@Collision)),@CollisionDefinition nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID(N'dbo.'+QUOTENAME(@Collision)));
EXEC #AssertTriggerReject 53904,2,6;
IF @CollisionId IS NULL OR @CollisionDefinition IS NULL OR OBJECT_ID(N'dbo.'+QUOTENAME(@Collision),N'P') IS NULL
   OR OBJECT_ID(N'dbo.'+QUOTENAME(@Collision),N'P')<>@CollisionId
   OR OBJECT_DEFINITION(@CollisionId) IS NULL
   OR CONVERT(varbinary(max),OBJECT_DEFINITION(@CollisionId))<>CONVERT(varbinary(max),@CollisionDefinition)
    THROW 54941,N'Kollision hat das eigene Sentinelobjekt verändert.',3;
SET @Sql=N'DROP PROCEDURE dbo.'+QUOTENAME(@Collision)+N';';EXEC sys.sp_executesql @Sql;
-- Auch ein noch nicht angelegter Map-Tabellenname teilt denselben Objektnamespace.
CREATE TABLE #TriggerCollisionMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,
    TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #TriggerCollisionMap VALUES(1,N'dbo',N'SyntheticTriggerSafe',N'dbo',N'SyntheticTriggerSafeClone'),
    (2,N'dbo',N'SyntheticTriggerOutside',N'dbo',@Collision);
EXEC #AssertTriggerReject 53904,2,7,N'#TriggerCollisionMap';
IF OBJECT_ID(N'dbo.'+QUOTENAME(@Collision)) IS NOT NULL
    THROW 54941,N'Geplante Trigger-/Tabellennamenskollision hat ein Ziel erzeugt.',4;
DROP TRIGGER dbo.SyntheticTriggerReject;
DROP PROCEDURE #AssertTriggerReject;
DROP TABLE dbo.SyntheticTriggerOutside;DROP TABLE dbo.SyntheticTriggerSafe;
-- Unsichtbare/mehrdeutige Bindungen benötigen einen tatsächlich belegten Kontext;
-- diese Fixture erfindet dafür weder Rechteänderungen noch einen Native-Nachweis.
PRINT N'PASS TRIGGER_SAFETY';

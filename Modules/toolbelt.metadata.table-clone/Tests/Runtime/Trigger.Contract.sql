-- Ausschließlich synthetische Test-DDL; der Planner selbst führt keinen Plan aus.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE dbo.[SyntheticTrig]]SourceΩ](Id int NOT NULL,Note nvarchar(100) NULL);
CREATE TABLE dbo.SyntheticTrigInstead(Id int NOT NULL,Note nvarchar(100) NULL);
DECLARE @Body nvarchar(max)=N'CREATE TRIGGER dbo.[SyntheticTrig]]AfterΩ] ON dbo.[SyntheticTrig]]SourceΩ]
AFTER INSERT,UPDATE,DELETE NOT FOR REPLICATION AS
BEGIN
    SET NOCOUNT ON;
    -- 🧪 dbo.[SyntheticTrig]]SourceΩ] bleibt Kommentar, nicht Identifier.
    DECLARE @Literal nvarchar(100)=N''🧪 dbo.[SyntheticTrig]]SourceΩ] O''''Brien'';
    DECLARE @Count int;
    ;WITH C AS (SELECT s.Id FROM dbo.[SyntheticTrig]]SourceΩ] AS s
        WHERE EXISTS(SELECT 1 FROM inserted AS i WHERE i.Id=s.Id))
    SELECT @Count=COUNT(*) FROM C;
    IF EXISTS(SELECT 1 FROM inserted WHERE Id=999)
        THROW 55080,N''Synthetisches AFTER-Orakel.'',1;
END;';
EXEC sys.sp_executesql @Body;
EXEC sys.sp_settriggerorder @triggername=N'dbo.[SyntheticTrig]]AfterΩ]',@order=N'First',@stmttype=N'INSERT';
EXEC sys.sp_settriggerorder @triggername=N'dbo.[SyntheticTrig]]AfterΩ]',@order=N'Last',@stmttype=N'UPDATE';
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTrigDisabled ON dbo.[SyntheticTrig]]SourceΩ]
AFTER INSERT AS BEGIN THROW 55081,N''Deaktivierter synthetischer Trigger wurde ausgeführt.'',1; END;';
DISABLE TRIGGER dbo.SyntheticTrigDisabled ON dbo.[SyntheticTrig]]SourceΩ];
SET QUOTED_IDENTIFIER OFF;
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticTrigInsteadBody ON dbo.SyntheticTrigInstead
INSTEAD OF INSERT,UPDATE,DELETE AS BEGIN
    SET NOCOUNT ON;
    INSERT dbo.SyntheticTrigInstead(Id,Note) SELECT i.Id,i.Note FROM inserted AS i;
END;';
SET QUOTED_IDENTIFIER ON;
CREATE TABLE #TriggerMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #TriggerMap VALUES(7,N'dbo',N'SyntheticTrig]SourceΩ',N'dbo',N'SyntheticTrig]CloneΩ'),
    (19,N'dbo',N'SyntheticTrigInstead',N'dbo',N'SyntheticTrigInsteadClone');
CREATE TABLE #TriggerPlan(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#TriggerMap',@IncludeTriggers=1,@ResultTable=N'#TriggerPlan';
IF (SELECT COUNT(*) FROM #TriggerPlan WHERE ObjectKind='TRIGGER')<>3
   OR (SELECT COUNT(*) FROM #TriggerPlan WHERE ObjectKind='TRIGGER_STATE')<>3
   OR (SELECT MIN(Ordinal) FROM #TriggerPlan)<>1 OR (SELECT MAX(Ordinal) FROM #TriggerPlan)<>(SELECT COUNT(*) FROM #TriggerPlan)
   OR (SELECT MAX(Ordinal) FROM #TriggerPlan WHERE ObjectKind='TRIGGER')>=(SELECT MIN(Ordinal) FROM #TriggerPlan WHERE ObjectKind='TRIGGER_STATE')
    THROW 54940,N'Triggerplan: Anzahl oder Zustandsphase stimmt nicht.',1;
-- Unabhängige Namensreferenz: drei längengerahmte UTF16-Felder, keine Definition im Hash.
DECLARE @Expected TABLE(SourceName sysname NOT NULL,TargetTable sysname NOT NULL,CloneName sysname NULL);
INSERT @Expected VALUES(N'SyntheticTrig]AfterΩ',N'SyntheticTrig]CloneΩ',NULL),
    (N'SyntheticTrigDisabled',N'SyntheticTrig]CloneΩ',NULL),(N'SyntheticTrigInsteadBody',N'SyntheticTrigInsteadClone',NULL);
UPDATE @Expected SET CloneName=N'TR_'+CONVERT(varchar(64),HASHBYTES('SHA2_256',
    CONVERT(varbinary(max),CONVERT(binary(4),DATALENGTH(N'dbo')))+CONVERT(varbinary(max),N'dbo')
    +CONVERT(binary(4),DATALENGTH(TargetTable))+CONVERT(varbinary(max),TargetTable)
    +CONVERT(binary(4),DATALENGTH(SourceName))+CONVERT(varbinary(max),SourceName)),2);
IF EXISTS(SELECT (QUOTENAME(N'dbo')+N'.'+QUOTENAME(CloneName)) COLLATE Latin1_General_100_BIN2 FROM @Expected
    EXCEPT SELECT TargetName FROM #TriggerPlan WHERE ObjectKind='TRIGGER')
    THROW 54940,N'Triggerplan: längengerahmter Zielname stimmt nicht.',2;
DECLARE @AfterName sysname=(SELECT CloneName FROM @Expected WHERE SourceName=N'SyntheticTrig]AfterΩ'),@ExpectedBody nvarchar(max);
SET @ExpectedBody=N'CREATE TRIGGER [dbo].'+QUOTENAME(@AfterName)+N' ON [dbo].[SyntheticTrig]]CloneΩ]
AFTER INSERT,UPDATE,DELETE NOT FOR REPLICATION AS
BEGIN
    SET NOCOUNT ON;
    -- 🧪 dbo.[SyntheticTrig]]SourceΩ] bleibt Kommentar, nicht Identifier.
    DECLARE @Literal nvarchar(100)=N''🧪 dbo.[SyntheticTrig]]SourceΩ] O''''Brien'';
    DECLARE @Count int;
    ;WITH C AS (SELECT s.Id FROM [dbo].[SyntheticTrig]]CloneΩ] AS s
        WHERE EXISTS(SELECT 1 FROM inserted AS i WHERE i.Id=s.Id))
    SELECT @Count=COUNT(*) FROM C;
    IF EXISTS(SELECT 1 FROM inserted WHERE Id=999)
        THROW 55080,N''Synthetisches AFTER-Orakel.'',1;
END;';
DECLARE @Ansi bit,@Qi bit,@ExpectedScript nvarchar(max);
SELECT @Ansi=uses_ansi_nulls,@Qi=uses_quoted_identifier FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'dbo.[SyntheticTrig]]AfterΩ]');
SET @ExpectedScript=CONVERT(nvarchar(max),N'SET ANSI_NULLS ')+CASE @Ansi WHEN 1 THEN N'ON' ELSE N'OFF' END+N';'+NCHAR(10)
    +N'SET QUOTED_IDENTIFIER '+CASE @Qi WHEN 1 THEN N'ON' ELSE N'OFF' END+N';'+NCHAR(10)
    +N'EXEC sys.sp_executesql N'''+REPLACE(@ExpectedBody,N'''',N'''''')+N''';';
IF NOT EXISTS(SELECT 1 FROM #TriggerPlan WHERE ObjectKind='TRIGGER' AND TargetName=N'[dbo].'+QUOTENAME(@AfterName)
    AND CONVERT(varbinary(max),ScriptText)=CONVERT(varbinary(max),@ExpectedScript))
    THROW 54940,N'Triggerplan: Identifierumschreibung oder unveränderte Lexeme stimmen nicht.',3;
-- Testausführung ausschließlich des vollständigen synthetischen Plans außerhalb der Produkt-API.
DECLARE @Script nvarchar(max);
DECLARE SyntheticTriggerPlan CURSOR LOCAL FAST_FORWARD FOR SELECT ScriptText FROM #TriggerPlan ORDER BY Ordinal;
OPEN SyntheticTriggerPlan;FETCH NEXT FROM SyntheticTriggerPlan INTO @Script;
WHILE @@FETCH_STATUS=0 BEGIN EXEC sys.sp_executesql @Script;FETCH NEXT FROM SyntheticTriggerPlan INTO @Script;END;
CLOSE SyntheticTriggerPlan;DEALLOCATE SyntheticTriggerPlan;
IF EXISTS(SELECT t.is_disabled,t.is_instead_of_trigger,t.is_not_for_replication,m.uses_ansi_nulls,m.uses_quoted_identifier,e.type,e.is_first,e.is_last,x.CloneName
    FROM @Expected x JOIN sys.triggers t ON t.object_id=OBJECT_ID(N'dbo.'+QUOTENAME(x.SourceName)) JOIN sys.sql_modules m ON m.object_id=t.object_id JOIN sys.trigger_events e ON e.object_id=t.object_id
    EXCEPT SELECT t.is_disabled,t.is_instead_of_trigger,t.is_not_for_replication,m.uses_ansi_nulls,m.uses_quoted_identifier,e.type,e.is_first,e.is_last,x.CloneName
    FROM @Expected x JOIN sys.triggers t ON t.object_id=OBJECT_ID(N'dbo.'+QUOTENAME(x.CloneName)) JOIN sys.sql_modules m ON m.object_id=t.object_id JOIN sys.trigger_events e ON e.object_id=t.object_id)
   OR (SELECT COUNT(*) FROM sys.trigger_events e JOIN @Expected x ON e.object_id=OBJECT_ID(N'dbo.'+QUOTENAME(x.SourceName)))
      <>(SELECT COUNT(*) FROM sys.trigger_events e JOIN @Expected x ON e.object_id=OBJECT_ID(N'dbo.'+QUOTENAME(x.CloneName)))
   OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_id IN(OBJECT_ID(N'dbo.[SyntheticTrig]]CloneΩ]'),OBJECT_ID(N'dbo.SyntheticTrigInsteadClone')))<>3
    THROW 54940,N'Triggerkatalog: Events, Flags, SET-Metadaten oder FIRST/LAST stimmen nicht.',4;
INSERT dbo.[SyntheticTrig]]CloneΩ] VALUES(1,N'normal');
INSERT dbo.SyntheticTrigInsteadClone VALUES(2,N'INSTEAD');
IF NOT EXISTS(SELECT 1 FROM dbo.SyntheticTrigInsteadClone WHERE Id=2 AND Note=N'INSTEAD')
    THROW 54940,N'INSTEAD-Trigger schreibt nicht in das gemappte Ziel.',5;
DECLARE @Number int=NULL,@State int=NULL;
BEGIN TRY INSERT dbo.[SyntheticTrig]]CloneΩ] VALUES(999,N'AFTER');END TRY
BEGIN CATCH SELECT @Number=ERROR_NUMBER(),@State=ERROR_STATE();END CATCH;
IF @Number IS NULL OR @Number<>55080 OR @State<>1
    THROW 54940,N'AFTER-Trigger wurde nicht mit dem ursprünglichen Body ausgeführt.',6;
DROP TABLE dbo.[SyntheticTrig]]CloneΩ];DROP TABLE dbo.SyntheticTrigInsteadClone;
DROP TABLE dbo.[SyntheticTrig]]SourceΩ];DROP TABLE dbo.SyntheticTrigInstead;
PRINT N'PASS TRIGGER_CONTRACT';

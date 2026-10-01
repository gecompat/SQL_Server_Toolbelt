-- Interner kanonischer Prüf-/Escapingkern. Kein SQL-Text aus Values wird ausgeführt.
-- Vollständiger privater Snapshot und begrenzte Fragmente vor ResultTable-Mutation.
CREATE OR ALTER PROCEDURE toolbelt_json.USP_JsonConstructInternal
 @ObjectMode bit=NULL,@EntriesTable sysname=NULL,@MaxEntries int=NULL,@MaxTotalValueBytes bigint=NULL,
 @MaxResultBytes bigint=NULL,@ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF @Hilfe=1
 BEGIN
  DECLARE @Help TABLE(Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
  INSERT @Help VALUES
  ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Interner kanonischer JSON-Prüf-/Escaping-/Routingkern; kein zusätzlicher öffentlicher Konstruktor.',NULL),
  ('PARAMETER',1,N'@ObjectMode','bit',1,0,NULL,N'0 Array, 1 Object; ausschließlich technischer Modus.',NULL),
  ('PARAMETER',2,N'@EntriesTable','sysname',1,0,NULL,N'Caller-lokale Eingabetabelle.',NULL),
  ('PARAMETER',3,N'@MaxEntries','int',1,0,NULL,N'Positive Grenze bis 100000.',NULL),
  ('PARAMETER',4,N'@MaxTotalValueBytes','bigint',1,0,NULL,N'Positive Gesamtwertbytes bis 16777216.',NULL),
  ('PARAMETER',5,N'@MaxResultBytes','bigint',1,0,NULL,N'Positive Ergebnisbytes bis 16777216.',NULL),
  ('PARAMETER',6,N'@ResultTable','sysname',0,1,NULL,N'SELECT oder lokale ResultTable.',NULL),
  ('PARAMETER',7,N'@KeepData','bit',1,0,NULL,N'Replace/Append vom Wrapper normalisiert.',NULL),
  ('PARAMETER',8,N'@Debug','tinyint',1,0,NULL,N'Nur Messages.',NULL),
  ('PARAMETER',9,N'@Hilfe','bit',0,1,N'0',N'Help ohne fachliche Prüfung oder Mutation.',NULL),
  ('RESULT_COLUMN',1,N'JsonValue','nvarchar(max)',1,0,NULL,N'Genau ein vollständiger JSON-Wert.',NULL),
  ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Öffentliche Fassade bevorzugen.',N'EXEC toolbelt_json.USP_JsonArray @Hilfe=1;');
  SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_json' AS sysname) SchemaName,
  CAST(N'USP_JsonConstructInternal' AS sysname) ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql FROM @Help ORDER BY Section,Ordinal;
  RETURN;
 END;
 IF @ObjectMode IS NULL OR @MaxEntries IS NULL OR @MaxEntries NOT BETWEEN 1 AND 100000
 OR @MaxTotalValueBytes IS NULL OR @MaxTotalValueBytes NOT BETWEEN 1 AND 16777216
 OR @MaxResultBytes IS NULL OR @MaxResultBytes NOT BETWEEN 1 AND 16777216
 THROW 53600,N'JSON: ungültiger Ressourcenparameter.',1;
 DECLARE @DependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),@Version nvarchar(64),@Major int,@Minor int,@Patch int;
 SELECT @Version=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
 SELECT @Major=TRY_CONVERT(int,PARSENAME(@Version,3)),@Minor=TRY_CONVERT(int,PARSENAME(@Version,2)),@Patch=TRY_CONVERT(int,PARSENAME(@Version,1));
 IF @DependencyId IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
 OR CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),CONCAT(@Major,N'.',@Minor,N'.',@Patch))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND TRY_CONVERT(nvarchar(128),value)=N'toolbelt.core.result-table')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@Version))
 THROW 53610,N'JSON: registrierte ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.',1;
 IF @EntriesTable IS NULL OR LEFT(@EntriesTable,1) COLLATE Latin1_General_100_BIN2<>N'#'
 OR LEFT(@EntriesTable,2) COLLATE Latin1_General_100_BIN2=N'##'
 OR LEFT(LOWER(@EntriesTable COLLATE Latin1_General_100_BIN2),5) COLLATE Latin1_General_100_BIN2=N'#tbx_'
 OR QUOTENAME(@EntriesTable) IS NULL
 THROW 53601,N'JSON: caller-lokale Eingabetabelle erforderlich.',1;
 DECLARE @InputId int=OBJECT_ID(N'tempdb..'+@EntriesTable,N'U');
 IF @InputId IS NULL THROW 53601,N'JSON: Eingabetabelle fehlt oder ist nicht sichtbar.',2;
 IF @ResultTable IS NOT NULL AND OBJECT_ID(N'tempdb..'+@ResultTable,N'U')=@InputId
 THROW 53601,N'JSON: Eingabe und Ausgabe dürfen nicht dieselbe Tabelle sein.',3;
 DECLARE @Required TABLE(Name sysname,TypeId int,MaxLength smallint);
 INSERT @Required VALUES(N'Ordinal',56,4),(N'ValueKind',231,-1),(N'Value',231,-1);
 IF @ObjectMode=1 INSERT @Required VALUES(N'Key',231,-1);
 IF EXISTS(SELECT 1 FROM @Required r WHERE NOT EXISTS
 (SELECT 1 FROM tempdb.sys.columns c WHERE c.object_id=@InputId
 AND CONVERT(varbinary(256),c.name)=CONVERT(varbinary(256),r.Name)
 AND c.system_type_id=r.TypeId AND c.user_type_id=c.system_type_id AND c.max_length=r.MaxLength AND c.is_computed=0))
 THROW 53601,N'JSON: erforderliche Spalten besitzen nicht den exakten Typvertrag.',4;
 DECLARE @Own bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,@Saved bit=0,@Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-','');
 BEGIN TRY
  IF @Own=1 BEGIN TRANSACTION;
  ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @Saved=1; END;
 -- Metadatenaggregate vor jeder privaten LOB-Kopie. Der caller-lokale Input
 -- bleibt per Tabellen-S-Lock/HOLDLOCK bis zum konsistenten Snapshot stabil;
 -- bei fremder Transaktion gilt deren reguläre Lock-Lebensdauer.
 DECLARE @SnapshotLimit int=@MaxEntries+1,@PreCount bigint,@PreValueBytes bigint,@PreKeyBytes bigint,
 @BadOrdinal int,@BadKey int,@BadKindLength int,@DuplicateOrdinal bit,@Sql nvarchar(max);
 SET @Sql=N'SELECT @c=COUNT_BIG(*),@v=COALESCE(SUM(CONVERT(bigint,DATALENGTH([Value]))),0),'
 +N'@k='+CASE WHEN @ObjectMode=1 THEN N'COALESCE(SUM(CONVERT(bigint,DATALENGTH([Key]))),0)' ELSE N'0' END
 +N',@o=COALESCE(MAX(CASE WHEN Ordinal IS NULL OR Ordinal<=0 THEN 1 ELSE 0 END),0),'
 +N'@b='+CASE WHEN @ObjectMode=1 THEN N'COALESCE(MAX(CASE WHEN [Key] IS NULL OR DATALENGTH([Key])=0 OR DATALENGTH([Key])>2048 THEN 1 ELSE 0 END),0)' ELSE N'0' END
 +N',@t=COALESCE(MAX(CASE WHEN ValueKind IS NULL OR DATALENGTH(ValueKind)>14 THEN 1 ELSE 0 END),0) '
 +N'FROM(SELECT TOP (@Limit) Ordinal,ValueKind,[Value]'+CASE WHEN @ObjectMode=1 THEN N',[Key]' ELSE N'' END
 +N' FROM '+QUOTENAME(@EntriesTable)+N' WITH(TABLOCK,HOLDLOCK)) bounded;';
 EXEC sys.sp_executesql @Sql,N'@Limit int,@c bigint OUTPUT,@v bigint OUTPUT,@k bigint OUTPUT,@o int OUTPUT,@b int OUTPUT,@t int OUTPUT',
 @SnapshotLimit,@PreCount OUTPUT,@PreValueBytes OUTPUT,@PreKeyBytes OUTPUT,@BadOrdinal OUTPUT,@BadKey OUTPUT,@BadKindLength OUTPUT;
 IF @PreCount>@MaxEntries THROW 53609,N'JSON: Entrylimit überschritten.',1;
 SET @Sql=N'SELECT @d=CASE WHEN EXISTS(SELECT Ordinal FROM '+QUOTENAME(@EntriesTable)+N' WITH(TABLOCK,HOLDLOCK) GROUP BY Ordinal HAVING COUNT_BIG(*)>1) THEN 1 ELSE 0 END;';
 EXEC sys.sp_executesql @Sql,N'@d bit OUTPUT',@DuplicateOrdinal OUTPUT;
 IF @BadOrdinal=1 OR @DuplicateOrdinal=1 THROW 53602,N'JSON: Ordinals müssen positiv und eindeutig sein.',1;
 IF @BadKey=1 THROW 53603,N'JSON: Key ist NULL, leer oder länger als 1024 Codeeinheiten.',1;
 IF @BadKindLength=1 THROW 53605,N'JSON: ValueKind ist NULL oder überschreitet die maximale Kindlänge.',2;
 IF @PreValueBytes>@MaxTotalValueBytes THROW 53609,N'JSON: Gesamtwertbytes vor Snapshot überschritten.',2;
 IF @PreValueBytes+@PreKeyBytes+4+CASE WHEN @PreCount=0 THEN 0 ELSE 2*(@PreCount-1) END
 +CASE WHEN @ObjectMode=1 THEN 6*@PreCount ELSE 0 END>@MaxResultBytes
 THROW 53609,N'JSON: minimale Ergebnisbytegrenze vor Snapshot überschritten.',4;
 CREATE TABLE #tbx_JsonConstructor_Input
 (Ordinal int NULL,[Key] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
 ValueKind nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
 [Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
 SET @Sql=N'INSERT #tbx_JsonConstructor_Input(Ordinal,[Key],ValueKind,[Value]) SELECT TOP (@Limit) Ordinal,'
 +CASE WHEN @ObjectMode=1 THEN N'[Key]' ELSE N'CAST(NULL AS nvarchar(max))' END
 +N',ValueKind,[Value] FROM '+QUOTENAME(@EntriesTable)+N' WITH(TABLOCK,HOLDLOCK);';
 -- Ein Statement liefert den Snapshot; eine überzählige Zeile genügt zum Limitfehler.
 EXEC sys.sp_executesql @Sql,N'@Limit int',@SnapshotLimit;
 IF (SELECT COUNT_BIG(*) FROM #tbx_JsonConstructor_Input)>@MaxEntries THROW 53609,N'JSON: Entrylimit überschritten.',1;
 IF EXISTS(SELECT 1 FROM #tbx_JsonConstructor_Input WHERE Ordinal IS NULL OR Ordinal<=0)
 OR EXISTS(SELECT 1 FROM #tbx_JsonConstructor_Input GROUP BY Ordinal HAVING COUNT(*)>1)
 THROW 53602,N'JSON: Ordinals müssen positiv und eindeutig sein.',1;
 IF @ObjectMode=1 AND EXISTS(SELECT 1 FROM #tbx_JsonConstructor_Input WHERE [Key] IS NULL OR DATALENGTH([Key])=0 OR DATALENGTH([Key])>2048)
 THROW 53603,N'JSON: Key ist NULL, leer oder länger als 1024 Codeeinheiten.',1;
 -- BIN2 allein folgt SQL-Padding. Die zusätzliche Bytelänge unterscheidet 'a'/'a '.
 IF @ObjectMode=1 AND EXISTS(SELECT 1 FROM #tbx_JsonConstructor_Input GROUP BY CONVERT(varbinary(2048),[Key]),DATALENGTH([Key]) HAVING COUNT(*)>1)
 THROW 53604,N'JSON: doppelte binär identische Keys.',1;
 IF EXISTS(SELECT 1 FROM #tbx_JsonConstructor_Input WHERE ValueKind IS NULL OR
 CONVERT(varbinary(max),ValueKind) NOT IN(0x73007400720069006E006700,0x6E0075006D00620065007200,0x62006F006F006C00650061006E00,0x6E0075006C006C00,0x6A0073006F006E00))
 THROW 53605,N'JSON: ValueKind muss exakt string/number/boolean/null/json sein.',1;
 IF EXISTS(SELECT 1 FROM #tbx_JsonConstructor_Input WHERE (ValueKind=N'null' AND [Value] IS NOT NULL) OR(ValueKind<>N'null' AND [Value] IS NULL))
 THROW 53606,N'JSON: SQL-NULL ist ausschließlich für Kind null erforderlich.',1;
 IF (SELECT COALESCE(SUM(CONVERT(bigint,DATALENGTH([Value]))),0) FROM #tbx_JsonConstructor_Input)>@MaxTotalValueBytes
 THROW 53609,N'JSON: Gesamtwertbytes überschritten.',2;
 -- Untere Ergebnisgrenze vor Escaping/Fragmentkopien; die Keysumme ist
 -- durch das Resultbudget begrenzt, nicht nur die einzelne Keylänge.
 DECLARE @MinimumBytes bigint,@InputCount bigint=(SELECT COUNT_BIG(*) FROM #tbx_JsonConstructor_Input);
 SELECT @MinimumBytes=COALESCE(SUM(CONVERT(bigint,CASE WHEN ValueKind=N'null' THEN 8 ELSE DATALENGTH([Value]) END)
 +CASE WHEN ValueKind=N'string' THEN 4 ELSE 0 END
 +CASE WHEN @ObjectMode=1 THEN CONVERT(bigint,DATALENGTH([Key]))+6 ELSE 0 END),0)
 +4+CASE WHEN @InputCount=0 THEN 0 ELSE 2*(@InputCount-1) END FROM #tbx_JsonConstructor_Input;
 IF @MinimumBytes>@MaxResultBytes THROW 53609,N'JSON: minimale Ergebnisbytegrenze überschritten.',4;
 CREATE TABLE #tbx_JsonConstructor_Fragments(Ordinal int NOT NULL,Fragment nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
 CREATE TABLE #tbx_JsonConstructor_Units(Number int NOT NULL PRIMARY KEY);
 ;WITH Digits AS(SELECT n FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d(n))
 INSERT #tbx_JsonConstructor_Units SELECT a.n+10*b.n+100*c.n FROM Digits a CROSS JOIN Digits b CROSS JOIN Digits c;
 DECLARE @Ordinal int,@Key nvarchar(max),@Kind nvarchar(max),@Value nvarchar(max),@Token nvarchar(max),@Text nvarchar(max),
 @Part int,@Position bigint,@Length bigint,@Unit int,@Next int,@NumberPosition bigint,@DigitStart bigint,
 @InString bit,@PendingHigh bit;
 DECLARE Entries CURSOR LOCAL FAST_FORWARD FOR SELECT Ordinal,[Key],ValueKind,[Value] FROM #tbx_JsonConstructor_Input ORDER BY Ordinal;
 OPEN Entries;
 FETCH NEXT FROM Entries INTO @Ordinal,@Key,@Kind,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  -- UTF-16-Codeeinheiten, bewusst nicht-SC: gepaarte Surrogates erhalten, isolierte ablehnen.
  SET @Part=CASE WHEN @ObjectMode=1 THEN 0 ELSE 1 END;
  WHILE @Part<=1
  BEGIN
   SET @Text=CASE WHEN @Part=0 THEN @Key ELSE @Value END;
   SET @Position=1; SET @Length=COALESCE(DATALENGTH(@Text)/2,0);
   WHILE @Position<=@Length
   BEGIN
    -- Begrenzte set-basierte Blöcke; kein LIKE/PATINDEX-NUL-Shortcut und kein
    -- millionenfach vergrößerter Numbersbestand. Paare dürfen Blockgrenzen kreuzen.
    IF EXISTS(SELECT 1 FROM #tbx_JsonConstructor_Units n
      CROSS APPLY(SELECT UNICODE(SUBSTRING(@Text COLLATE Latin1_General_100_BIN2,@Position+n.Number,1)) Unit) u
      WHERE n.Number<@Length-@Position+1 AND
       ((u.Unit BETWEEN 55296 AND 56319 AND
         COALESCE(UNICODE(SUBSTRING(@Text COLLATE Latin1_General_100_BIN2,@Position+n.Number+1,1)),-1) NOT BETWEEN 56320 AND 57343)
        OR(u.Unit BETWEEN 56320 AND 57343 AND
         COALESCE(UNICODE(SUBSTRING(@Text COLLATE Latin1_General_100_BIN2,@Position+n.Number-1,1)),-1) NOT BETWEEN 55296 AND 56319)))
      THROW 53607,N'JSON: ungültige Unicode-Surrogatfolge.',1;
    SET @Position+=1000;
   END;
   SET @Part+=1;
  END;
  IF @Kind=N'string' SET @Token=N'"'+STRING_ESCAPE(@Value,'json')+N'"';
  ELSE IF @Kind=N'null' SET @Token=N'null';
  ELSE IF @Kind=N'boolean'
  BEGIN
   IF CONVERT(varbinary(max),@Value) NOT IN(0x7400720075006500,0x660061006C0073006500) THROW 53608,N'JSON: Booleanliteral ungültig.',1;
   SET @Token=@Value;
  END
  ELSE IF @Kind=N'json'
  BEGIN
   IF ISJSON(@Value)<>1 THROW 53608,N'JSON: Fragment muss vollständiges Objekt oder Array sein.',2;
   -- ISJSON validiert die Syntax, nicht zuverlässig die decodierte Unicode-
   -- Paarigkeit. Ein einziger lexical Scan prüft alle Stringtokens (auch Keys),
   -- ohne rekursive LOB-Kopien, zusätzliche Tiefengrenze oder Neuformatierung.
   IF CHARINDEX(N'\u',@Value COLLATE Latin1_General_100_BIN2)>0
   BEGIN
    SELECT @Position=1,@Length=DATALENGTH(@Value)/2,@InString=0,@PendingHigh=0;
    WHILE @Position<=@Length
    BEGIN
     SET @Unit=UNICODE(SUBSTRING(@Value COLLATE Latin1_General_100_BIN2,@Position,1));
     IF @InString=0
     BEGIN
      IF @Unit=34 SELECT @InString=1,@PendingHigh=0;
      SET @Position+=1;
     END
     ELSE IF @Unit=34
     BEGIN
      IF @PendingHigh=1 THROW 53607,N'JSON: decodierte Unicode-Surrogatfolge ungültig.',2;
      SET @InString=0; SET @Position+=1;
     END
     ELSE
     BEGIN
      IF @Unit=92
      BEGIN
       SET @Next=UNICODE(SUBSTRING(@Value COLLATE Latin1_General_100_BIN2,@Position+1,1));
       IF @Next=117
       BEGIN
        SET @Unit=CONVERT(int,CONVERT(varbinary(2),SUBSTRING(@Value,@Position+2,4),2));
        SET @Position+=6;
       END
       ELSE BEGIN SET @Unit=@Next; SET @Position+=2; END;
      END
      ELSE SET @Position+=1;
      IF @PendingHigh=1
      BEGIN
       IF @Unit NOT BETWEEN 56320 AND 57343 THROW 53607,N'JSON: decodierte Unicode-Surrogatfolge ungültig.',3;
       SET @PendingHigh=0;
      END
      ELSE IF @Unit BETWEEN 55296 AND 56319 SET @PendingHigh=1;
      ELSE IF @Unit BETWEEN 56320 AND 57343 THROW 53607,N'JSON: decodierte Unicode-Surrogatfolge ungültig.',4;
     END;
    END;
   END;
   SET @Token=@Value;
  END
  ELSE
  BEGIN
   -- JSON-Zahlengrammatik ohne Konvertierung/Precisionverlust oder Culture.
   SET @Length=DATALENGTH(@Value)/2; SET @NumberPosition=1;
   IF UNICODE(SUBSTRING(@Value,1,1))=45 SET @NumberPosition+=1;
   SET @Unit=UNICODE(SUBSTRING(@Value,@NumberPosition,1));
   IF @Unit=48 SET @NumberPosition+=1;
   ELSE IF @Unit BETWEEN 49 AND 57
   BEGIN
    SET @NumberPosition+=1;
    WHILE UNICODE(SUBSTRING(@Value,@NumberPosition,1)) BETWEEN 48 AND 57 SET @NumberPosition+=1;
   END
   ELSE THROW 53608,N'JSON: Zahlenliteral ungültig.',3;
   IF UNICODE(SUBSTRING(@Value,@NumberPosition,1))=46
   BEGIN
    SET @NumberPosition+=1; SET @DigitStart=@NumberPosition;
    WHILE UNICODE(SUBSTRING(@Value,@NumberPosition,1)) BETWEEN 48 AND 57 SET @NumberPosition+=1;
    IF @DigitStart=@NumberPosition THROW 53608,N'JSON: Zahlenliteral ungültig.',4;
   END;
   IF UNICODE(SUBSTRING(@Value,@NumberPosition,1)) IN(101,69)
   BEGIN
    SET @NumberPosition+=1;
    IF UNICODE(SUBSTRING(@Value,@NumberPosition,1)) IN(43,45) SET @NumberPosition+=1;
    SET @DigitStart=@NumberPosition;
    WHILE UNICODE(SUBSTRING(@Value,@NumberPosition,1)) BETWEEN 48 AND 57 SET @NumberPosition+=1;
    IF @DigitStart=@NumberPosition THROW 53608,N'JSON: Zahlenliteral ungültig.',5;
   END;
   IF @NumberPosition<>@Length+1 THROW 53608,N'JSON: Zahlenliteral ungültig.',6;
   SET @Token=@Value;
  END;
  INSERT #tbx_JsonConstructor_Fragments VALUES(@Ordinal,CASE WHEN @ObjectMode=1 THEN N'"'+STRING_ESCAPE(@Key,'json')+N'":'+@Token ELSE @Token END);
  FETCH NEXT FROM Entries INTO @Ordinal,@Key,@Kind,@Value;
 END;
 CLOSE Entries; DEALLOCATE Entries;
 DECLARE @Count bigint=(SELECT COUNT_BIG(*) FROM #tbx_JsonConstructor_Fragments),@Bytes bigint;
 SELECT @Bytes=COALESCE(SUM(CONVERT(bigint,DATALENGTH(Fragment))),0)+4+CASE WHEN @Count=0 THEN 0 ELSE 2*(@Count-1) END FROM #tbx_JsonConstructor_Fragments;
 IF @Bytes>@MaxResultBytes THROW 53609,N'JSON: Ergebnisbytegrenze überschritten.',3;
 CREATE TABLE #tbx_JsonConstructor_Result(JsonValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
 -- Geordnete Aggregation statt wiederholter Konkatenation des wachsenden Gesamt-LOBs.
 INSERT #tbx_JsonConstructor_Result SELECT CASE WHEN @ObjectMode=1 THEN N'{' ELSE N'[' END
 +COALESCE(STRING_AGG(Fragment,N',') WITHIN GROUP(ORDER BY Ordinal),N'')
 +CASE WHEN @ObjectMode=1 THEN N'}' ELSE N']' END FROM #tbx_JsonConstructor_Fragments;
 IF @Debug>0 RAISERROR(N'JSON: vollständig validiertes Ergebnis bereit.',10,1) WITH NOWAIT;
 IF @ResultTable IS NULL BEGIN IF @Own=1 COMMIT; SELECT JsonValue FROM #tbx_JsonConstructor_Result; RETURN; END;
  EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_JsonConstructor_Result',@KeepData=@KeepData,@Debug=@Debug;
  SET @Sql=N'INSERT '+QUOTENAME(@ResultTable)+N'(JsonValue) SELECT JsonValue FROM #tbx_JsonConstructor_Result;';
  EXEC sys.sp_executesql @Sql;
  IF @Own=1 COMMIT;
 END TRY
 BEGIN CATCH
  IF @Own=1 AND XACT_STATE()<>0 ROLLBACK;
  ELSE IF @Saved=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
  THROW;
 END CATCH;
END;
GO

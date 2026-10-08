-- Positive Metadatenfixture: keine API-Ausführung, Grants oder Tabelleninhalte.
-- Der Adapter stellt vorher die exakte eigene DB-Identität und die Drei-Modul-Installation sicher.
-- Reine Sessionchecks bleiben von kataloglesenden Prädikaten getrennt.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 THROW 54993,N'Parameterfixture benötigt eine neutrale Sitzung.',1;
IF XACT_STATE()<>0 THROW 54993,N'Parameterfixture benötigt eine neutrale Sitzung.',2;
IF (@@OPTIONS&2)<>0 THROW 54993,N'Parameterfixture benötigt eine neutrale Sitzung.',3;
IF @@LOCK_TIMEOUT<>-1 THROW 54993,N'Parameterfixture benötigt eine neutrale Sitzung.',4;

DECLARE @Objects TABLE
(
 ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
 ObjectId int NULL,ModuleId nvarchar(256) COLLATE Latin1_General_100_BIN2 NOT NULL,
 ModuleVersion nvarchar(64) COLLATE Latin1_General_100_BIN2 NOT NULL
);
INSERT @Objects VALUES
 (N'USP_PrepareResultTable',OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),N'toolbelt.core.result-table',N'1.0.0'),
 (N'USP_EnqueueWork',OBJECT_ID(N'toolbelt_core.USP_EnqueueWork',N'P'),N'toolbelt.core.work-queue',N'2.1.0');
IF EXISTS(SELECT 1 FROM @Objects x LEFT JOIN sys.objects o ON o.object_id=x.ObjectId
 LEFT JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.object_id IS NULL OR o.name COLLATE Latin1_General_100_BIN2<>x.ObjectName
 OR s.name COLLATE Latin1_General_100_BIN2<>N'toolbelt_core' OR o.type<>N'P' OR m.definition IS NULL)
 THROW 54993,N'Die zwei sourcegebundenen SQL-Prozeduren fehlen.',5;
-- Der installierte Marker muss typisiert, sichtbar und dem ausgewählten Release zugeordnet sein.
IF EXISTS(SELECT 1 FROM @Objects x WHERE
 NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=x.ObjectId AND p.minor_id=0
 AND p.name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),p.value)=CONVERT(varbinary(max),x.ModuleId))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=x.ObjectId AND p.minor_id=0
 AND p.name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),p.value)=CONVERT(varbinary(max),x.ModuleVersion)))
 THROW 54993,N'Die sourcegebundenen Objektmarker fehlen oder weichen ab.',6;

DECLARE @Expected TABLE
(
 ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,
 ParameterId int NOT NULL,ParameterName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,
 TypeName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,
 MaxLength smallint NOT NULL,PrecisionValue tinyint NOT NULL,ScaleValue tinyint NOT NULL,
 PRIMARY KEY(ObjectName,ParameterId)
);
-- Genau diese elf Deklarationen stammen aus den beiden unveränderten Source-Dateien.
-- T-SQL-Defaults stehen in sys.sql_modules; has_default_value=0 belegt sie nicht.
INSERT @Expected VALUES
 (N'USP_PrepareResultTable',1,N'@ResultTableToAlter',N'sysname',256,0,0),
 (N'USP_PrepareResultTable',2,N'@LikeTable',N'nvarchar',1552,0,0),
 (N'USP_PrepareResultTable',3,N'@KeepData',N'bit',1,1,0),
 (N'USP_PrepareResultTable',4,N'@Debug',N'tinyint',1,3,0),
 (N'USP_PrepareResultTable',5,N'@Hilfe',N'bit',1,1,0),
 (N'USP_EnqueueWork',1,N'@WorkTypeName',N'varchar',128,0,0),
 (N'USP_EnqueueWork',2,N'@PayloadJson',N'nvarchar',-1,0,0),
 (N'USP_EnqueueWork',3,N'@ResultTable',N'sysname',256,0,0),
 (N'USP_EnqueueWork',4,N'@KeepData',N'bit',1,1,0),
 (N'USP_EnqueueWork',5,N'@Debug',N'tinyint',1,3,0),
 (N'USP_EnqueueWork',6,N'@Hilfe',N'bit',1,1,0);
IF (SELECT COUNT(*) FROM sys.parameters p JOIN @Objects x ON x.ObjectId=p.object_id)<>11
 OR EXISTS(SELECT 1 FROM @Expected e JOIN @Objects x ON x.ObjectName=e.ObjectName
 LEFT JOIN sys.parameters p ON p.object_id=x.ObjectId AND p.parameter_id=e.ParameterId
 LEFT JOIN sys.types t ON t.user_type_id=p.user_type_id
 WHERE p.object_id IS NULL OR p.name COLLATE Latin1_General_100_BIN2<>e.ParameterName
 OR t.name COLLATE Latin1_General_100_BIN2<>e.TypeName OR t.schema_id<>SCHEMA_ID(N'sys')
 OR p.system_type_id<>t.system_type_id OR p.max_length<>e.MaxLength
 OR p.precision<>e.PrecisionValue OR p.scale<>e.ScaleValue
 OR p.is_output<>0 OR p.is_cursor_ref<>0 OR p.has_default_value<>0 OR p.default_value IS NOT NULL
 OR p.is_xml_document<>0 OR p.xml_collection_id<>0 OR p.is_readonly<>0 OR p.is_nullable<>1)
 THROW 54993,N'Die elf sourcegebundenen Parameter stimmen nicht exakt überein.',7;

DECLARE @Witnesses TABLE
(
 ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ParameterId int NOT NULL,
 ParameterName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,
 PropertyName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ExpectedValue sql_variant NOT NULL,
 PRIMARY KEY(ObjectName,ParameterId,PropertyName)
);
INSERT @Witnesses VALUES
 (N'USP_PrepareResultTable',1,N'@ResultTableToAlter',N'Toolbelt.Test.ExportParameter.Typed',CONVERT(sql_variant,CONVERT(varbinary(5),0x00017F80FF))),
 (N'USP_PrepareResultTable',1,N'@ResultTableToAlter',N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Contoso Parameter – Unicode Ω  '))),
 (N'USP_EnqueueWork',1,N'@WorkTypeName',N'Toolbelt.Test.ExportParameter.Typed',CONVERT(sql_variant,CONVERT(int,7))),
 (N'USP_EnqueueWork',1,N'@WorkTypeName',N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Fabrikam Parameter – Padding  ')));

-- Alle vier Namen vor der ersten Mutation auf ihren genau ausgewählten Parametern sperren.
IF EXISTS(SELECT 1 FROM @Witnesses w JOIN @Objects x ON x.ObjectName=w.ObjectName
 JOIN sys.extended_properties ep ON ep.class=2 AND ep.major_id=x.ObjectId
 AND ep.minor_id=w.ParameterId AND ep.name COLLATE DATABASE_DEFAULT=w.PropertyName COLLATE DATABASE_DEFAULT)
 THROW 54993,N'Eine eigene Parameterannotation ist bereits belegt.',8;
DECLARE @Procedure sysname,@Parameter sysname,@Property sysname,@Value sql_variant;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE witnesses_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT ObjectName,ParameterName,PropertyName,ExpectedValue FROM @Witnesses
 ORDER BY ObjectName,ParameterId,PropertyName;
 OPEN witnesses_cursor;FETCH NEXT FROM witnesses_cursor INTO @Procedure,@Parameter,@Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,
   @level0type=N'SCHEMA',@level0name=N'toolbelt_core',
   @level1type=N'PROCEDURE',@level1name=@Procedure,
   @level2type=N'PARAMETER',@level2name=@Parameter;
  FETCH NEXT FROM witnesses_cursor INTO @Procedure,@Parameter,@Property,@Value;
 END;
 CLOSE witnesses_cursor;DEALLOCATE witnesses_cursor;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;

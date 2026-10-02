-- 18 DTO-Originaltypen: Skala, Offset und Rundungsuebertrag ueber den oeffentlichen ScriptOnly-Pfad.
SET NOCOUNT ON;
CREATE TABLE dbo.SyntheticWave1DtoSource(Id int NOT NULL);
DECLARE @DtoCases TABLE(Name sysname NOT NULL,ExpectedScale int NOT NULL,
 ExpectedSecond int NOT NULL,ExpectedNanosecond int NOT NULL,Value sql_variant NOT NULL);
INSERT @DtoCases VALUES(N'S0_Z_F1234567',0,56,0,CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567+00:00')));
INSERT @DtoCases VALUES(N'S0_Z_F9999999',0,57,0,CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.9999999+00:00')));
INSERT @DtoCases VALUES(N'S0_P0530_F1234567',0,56,0,CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567+05:30')));
INSERT @DtoCases VALUES(N'S0_P0530_F9999999',0,57,0,CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.9999999+05:30')));
INSERT @DtoCases VALUES(N'S0_M1234_F1234567',0,56,0,CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567-12:34')));
INSERT @DtoCases VALUES(N'S0_M1234_F9999999',0,57,0,CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.9999999-12:34')));
INSERT @DtoCases VALUES(N'S3_Z_F1234567',3,56,123000000,CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567+00:00')));
INSERT @DtoCases VALUES(N'S3_Z_F9999999',3,57,0,CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.9999999+00:00')));
INSERT @DtoCases VALUES(N'S3_P0530_F1234567',3,56,123000000,CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567+05:30')));
INSERT @DtoCases VALUES(N'S3_P0530_F9999999',3,57,0,CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.9999999+05:30')));
INSERT @DtoCases VALUES(N'S3_M1234_F1234567',3,56,123000000,CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567-12:34')));
INSERT @DtoCases VALUES(N'S3_M1234_F9999999',3,57,0,CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.9999999-12:34')));
INSERT @DtoCases VALUES(N'S7_Z_F1234567',7,56,123456700,CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+00:00')));
INSERT @DtoCases VALUES(N'S7_Z_F9999999',7,56,999999900,CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.9999999+00:00')));
INSERT @DtoCases VALUES(N'S7_P0530_F1234567',7,56,123456700,CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+05:30')));
INSERT @DtoCases VALUES(N'S7_P0530_F9999999',7,56,999999900,CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.9999999+05:30')));
INSERT @DtoCases VALUES(N'S7_M1234_F1234567',7,56,123456700,CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567-12:34')));
INSERT @DtoCases VALUES(N'S7_M1234_F9999999',7,56,999999900,CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.9999999-12:34')));
IF (SELECT COUNT(*) FROM @DtoCases)<>18
 OR (SELECT COUNT(DISTINCT CONVERT(varbinary(256),Name)) FROM @DtoCases)<>18
 OR EXISTS(SELECT 1 FROM @DtoCases WHERE CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(Value,'BaseType'))<>CONVERT(varbinary(max),N'datetimeoffset')
  OR COALESCE(TRY_CONVERT(int,SQL_VARIANT_PROPERTY(Value,'Scale')),-1)<>ExpectedScale
  OR DATEPART(second,CONVERT(datetimeoffset(7),Value))<>ExpectedSecond
  OR DATEPART(nanosecond,CONVERT(datetimeoffset(7),Value))<>ExpectedNanosecond)
 THROW 54930,N'DTO18: Originaltyp, Skala oder Rundungsuebertrag ungueltig.',30;
DECLARE @DtoName sysname,@DtoValue sql_variant;
DECLARE DtoCursor CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Value FROM @DtoCases;
OPEN DtoCursor; FETCH NEXT FROM DtoCursor INTO @DtoName,@DtoValue;
WHILE @@FETCH_STATUS=0
BEGIN
 EXEC sys.sp_addextendedproperty @name=@DtoName,@value=@DtoValue,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1DtoSource';
 FETCH NEXT FROM DtoCursor INTO @DtoName,@DtoValue;
END;
CLOSE DtoCursor; DEALLOCATE DtoCursor;
DECLARE @DtoSource int=OBJECT_ID(N'dbo.SyntheticWave1DtoSource',N'U');
IF @DtoSource IS NULL
 OR (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@DtoSource AND minor_id=0)<>18
 OR EXISTS(SELECT 1 FROM sys.extended_properties e JOIN @DtoCases c ON CONVERT(varbinary(256),e.name)=CONVERT(varbinary(256),c.Name)
  WHERE e.class=1 AND e.major_id=@DtoSource AND e.minor_id=0
   AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(e.value,'BaseType'))<>CONVERT(varbinary(max),N'datetimeoffset')
    OR COALESCE(TRY_CONVERT(int,SQL_VARIANT_PROPERTY(e.value,'Scale')),-1)<>c.ExpectedScale))
 OR EXISTS(SELECT CONVERT(varbinary(256),Name),CONVERT(varbinary(max),Value),SQL_VARIANT_PROPERTY(Value,'BaseType'),SQL_VARIANT_PROPERTY(Value,'Precision'),SQL_VARIANT_PROPERTY(Value,'Scale'),SQL_VARIANT_PROPERTY(Value,'MaxLength'),SQL_VARIANT_PROPERTY(Value,'Collation') FROM @DtoCases
  EXCEPT SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE class=1 AND major_id=@DtoSource AND minor_id=0)
 OR EXISTS(SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE class=1 AND major_id=@DtoSource AND minor_id=0
  EXCEPT SELECT CONVERT(varbinary(256),Name),CONVERT(varbinary(max),Value),SQL_VARIANT_PROPERTY(Value,'BaseType'),SQL_VARIANT_PROPERTY(Value,'Precision'),SQL_VARIANT_PROPERTY(Value,'Scale'),SQL_VARIANT_PROPERTY(Value,'MaxLength'),SQL_VARIANT_PROPERTY(Value,'Collation') FROM @DtoCases)
 THROW 54930,N'DTO18: Gespeicherte Source-Instanzen nicht byte- und typgleich.',31;
CREATE TABLE #Wave1DtoPlan(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticWave1DtoSource',N'dbo',N'SyntheticWave1DtoTarget',@IncludeExtendedProperties=1,@ResultTable=N'#Wave1DtoPlan';
IF (SELECT COUNT(*) FROM #Wave1DtoPlan)<>26
 OR (SELECT COUNT(DISTINCT Ordinal) FROM #Wave1DtoPlan)<>26
 OR EXISTS(SELECT 1 FROM #Wave1DtoPlan WHERE Ordinal IS NULL OR Ordinal<1 OR Ordinal>26 OR ScriptText IS NULL)
 OR (SELECT COUNT(*) FROM #Wave1DtoPlan WHERE ObjectKind='EXTENDED_PROPERTY')<>18
 OR NOT EXISTS(SELECT 1 FROM #Wave1DtoPlan WHERE Ordinal=8 AND ObjectKind='TABLE')
 OR EXISTS(SELECT 1 FROM (VALUES(1,N'SET ANSI_NULLS ON;'),(2,N'SET ANSI_PADDING ON;'),(3,N'SET ANSI_WARNINGS ON;'),(4,N'SET ARITHABORT ON;'),(5,N'SET CONCAT_NULL_YIELDS_NULL ON;'),(6,N'SET QUOTED_IDENTIFIER ON;'),(7,N'SET NUMERIC_ROUNDABORT OFF;')) expected(Ordinal,ScriptText)
  WHERE NOT EXISTS(SELECT 1 FROM #Wave1DtoPlan p WHERE p.Ordinal=expected.Ordinal AND p.ObjectKind='SESSION_OPTION' AND CONVERT(varbinary(max),p.ScriptText)=CONVERT(varbinary(max),expected.ScriptText)))
 THROW 54930,N'DTO18: SET-, TABLE- oder Property-Plan unvollstaendig.',32;
DECLARE @DtoScript nvarchar(max);
SELECT @DtoScript=STRING_AGG(CONVERT(nvarchar(max),ScriptText),NCHAR(10)) WITHIN GROUP(ORDER BY Ordinal) FROM #Wave1DtoPlan;
IF @DtoScript IS NULL THROW 54930,N'DTO18: Aeusserer Scriptbatch fehlt.',32;
-- Nur diese externe Testfixture fuehrt den ordinalsortierten API-Plan aus.
EXEC sys.sp_executesql @DtoScript;
DECLARE @DtoTarget int=OBJECT_ID(N'dbo.SyntheticWave1DtoTarget',N'U');
IF @DtoTarget IS NULL
 OR (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@DtoTarget AND minor_id=0)<>18
 OR EXISTS(SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE class=1 AND major_id=@DtoSource AND minor_id=0
  EXCEPT SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE class=1 AND major_id=@DtoTarget AND minor_id=0)
 OR EXISTS(SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE class=1 AND major_id=@DtoTarget AND minor_id=0
  EXCEPT SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE class=1 AND major_id=@DtoSource AND minor_id=0)
 THROW 54930,N'DTO18: Vollstaendiger gespeicherter Source-/Target-Roundtrip unterscheidet sich.',33;
DROP TABLE dbo.SyntheticWave1DtoTarget;
DROP TABLE dbo.SyntheticWave1DtoSource;
GO

-- ============================================================================
-- Objekt: toolbelt_json.USP_JsonArray; Typ: Stored Procedure
-- Zweck: Begrenzte JSON-Konstruktion aus caller-lokaler #Temp mit expliziten Kinds.
-- Vertrag: Documentation/USP_JsonArray.md; USP_CONTRACT 1.0
-- Parameter: EntriesTable sysname; positive MaxEntries/MaxTotalValueBytes/MaxResultBytes
-- Resultset: JsonValue nvarchar(max) NOT NULL, genau eine Zeile.
-- Dependencies: toolbelt.core.result-table >=1.0.0 same_database
-- Rechte: EXECUTE; eigene lokale Temps; keine Rechteausweitung.
-- Versionen: SQL Server 2019/2022/2025, Compatibility >=150; Windows/Linux.
-- Fehler: 53600-53610; vollständige Prüfung vor Zielmutation, Originalenginefehler.
-- Performance: begrenzter Snapshot, Fragmente und geordnete LOB-Aggregation.
-- Grenzen: keine Inferenz/PrettyPrint/Aggregate/Patch; kein unbegrenzter Aufruf.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_json.USP_JsonArray
 @EntriesTable sysname=NULL,
 @MaxEntries int=10000,
 @MaxTotalValueBytes bigint=2097152,
 @MaxResultBytes bigint=2097152,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
 IF @Hilfe=1
 BEGIN
  DECLARE @Help TABLE(Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
  INSERT @Help VALUES
  ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'JSON-Array aus Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.',NULL),
  ('PARAMETER',1,N'@EntriesTable','sysname',1,0,N'NULL',N'Bestehende caller-lokale #Temp, exakte erforderliche Typen, zusätzliche Spalten ignoriert.',NULL),
  ('PARAMETER',2,N'@MaxEntries','int',0,0,N'10000',N'Positive Grenze bis 100000; Ordinals positiv/eindeutig, Lücken erlaubt.',NULL),
  ('PARAMETER',3,N'@MaxTotalValueBytes','bigint',0,0,N'2097152',N'Summe DATALENGTH(Value), SQL-NULL zählt 0; höchstens 16777216.',NULL),
  ('PARAMETER',4,N'@MaxResultBytes','bigint',0,0,N'2097152',N'Exakte UTF-16-Ergebnisbytes einschließlich Escapes/Keys/Syntax; höchstens 16777216.',NULL),
  ('PARAMETER',5,N'@ResultTable','sysname',0,1,N'NULL',N'NULL: SELECT; sonst bestehende lokale Temp-Tabelle, nicht Eingabeobjekt.',NULL),
  ('PARAMETER',6,N'@KeepData','bit',0,1,N'0',N'Replace=0, Append=1; NULL entspricht 0.',NULL),
  ('PARAMETER',7,N'@Debug','tinyint',0,1,N'0',N'Nur Messages ohne Payloadinhalte; NULL entspricht 0.',NULL),
  ('PARAMETER',8,N'@Hilfe','bit',0,1,N'0',N'Help zuerst; ignoriert sämtliche anderen Parameter ohne Seiteneffekte.',NULL),
  ('RESULT_COLUMN',1,N'JsonValue','nvarchar(max)',1,0,NULL,N'Genau ein JSON-Wert, BIN2; leere Eingabe [].',NULL),
  ('ERROR',1,N'53600-53610',NULL,NULL,NULL,NULL,N'Parameter/Schema/Ordinal/Key/Kind/NULL/Unicode/Literal/Ressourcen/Dependency; Enginefehler unverändert.',NULL),
  ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE und lokale Temp-Sicht; ResultTable-Pfad zusätzlich Helper-EXECUTE.',NULL),
  ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Nur string/number/boolean/null/json; json ist vollständiges Objekt/Array, kein Scalar. Keine Typinferenz.',NULL),
  ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Caller-Eingabe wird nicht mutiert.',N'CREATE TABLE #Entries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max)); EXEC toolbelt_json.USP_JsonArray @EntriesTable=N''#Entries'';');
  SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_json' AS sysname) SchemaName,
  CAST(N'USP_JsonArray' AS sysname) ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
  FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5 WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
  RETURN;
 END;
 -- Diese Sicherheitsgrenze liegt vor Core-Compilation: ein Callerobjekt im
 -- reservierten Namespace kann sonst interne #Temp-Metadaten eclipsen und
 -- schon beim Compile statt des Vertragsfehlers einen Enginefehler auslösen.
 IF LEFT(LOWER(@EntriesTable COLLATE Latin1_General_100_BIN2),5) COLLATE Latin1_General_100_BIN2=N'#tbx_'
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Input',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Fragments',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Units',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructor_Result',N'U') IS NOT NULL
 THROW 53601,N'JSON: reservierter interner Temp-Namespace ist im Caller belegt.',5;
 EXEC toolbelt_json.USP_JsonConstructInternal @ObjectMode=0,@EntriesTable=@EntriesTable,@MaxEntries=@MaxEntries,
 @MaxTotalValueBytes=@MaxTotalValueBytes,@MaxResultBytes=@MaxResultBytes,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
END;
GO

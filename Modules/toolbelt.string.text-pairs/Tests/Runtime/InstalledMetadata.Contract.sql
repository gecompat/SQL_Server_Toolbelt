SET NOCOUNT ON;
DECLARE @Id int=OBJECT_ID(N'toolbelt_string.USP_CompareTextPairs',N'P');
IF @Id IS NULL OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@Id)<>11 THROW 55193,N'Metadata: eleven parameters required.',1;
DECLARE @Expected TABLE(Ordinal int,Name sysname,TypeId int,Length smallint);
INSERT @Expected VALUES(1,N'@PairsTable',231,256),(2,N'@Algorithm',231,-1),(3,N'@MaxDistance',56,4),(4,N'@Profile',231,-1),
 (5,N'@MaxPairs',56,4),(6,N'@MaxTotalTextBytes',127,8),(7,N'@MaxTotalWork',127,8),(8,N'@ResultTable',231,256),
 (9,N'@KeepData',104,1),(10,N'@Debug',48,1),(11,N'@Hilfe',104,1);
IF EXISTS(SELECT 1 FROM @Expected e LEFT JOIN sys.parameters p ON p.object_id=@Id AND p.parameter_id=e.Ordinal
          WHERE p.parameter_id IS NULL OR CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),e.Name) OR p.system_type_id<>e.TypeId OR p.max_length<>e.Length OR p.is_output<>0)
    THROW 55193,N'Metadata: parameter order/type/name mismatch.',2;
IF (SELECT COUNT(DISTINCT referenced_id) FROM sys.sql_expression_dependencies WHERE referencing_id=@Id
    AND referenced_id IN(OBJECT_ID(N'toolbelt_string.TVF_LevenshteinDistance'),OBJECT_ID(N'toolbelt_string.TVF_OsaDistance'),OBJECT_ID(N'toolbelt_string.TVF_JaroWinklerSimilarity')))<>3
    THROW 55193,N'Metadata: static three-provider consumer relation missing.',3;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@Id AND minor_id=0 AND name=N'Toolbelt.ModuleId'
              AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.string.text-pairs'))
    THROW 55193,N'Metadata: module identity missing.',4;
SELECT N'PASS' AS Status;

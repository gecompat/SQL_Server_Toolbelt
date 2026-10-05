-- Lokaler geschlossener Manifestzustand, genau zwei eigene SQL-Slots.
DECLARE @SchemaVersion nvarchar(max),@SchemaMode nvarchar(max),@SchemaAssemblyId int,@SchemaAssemblyOwner int,
 @SchemaInstalledHash varbinary(64),@SchemaOwner int,@SchemaInstalling bit=0,
 @SchemaResultVersion nvarchar(max),@SchemaResultId int,@SchemaMajor int,@SchemaMinor int,@SchemaPatch int,
 @SchemaConstructorId int,@SchemaConstructorVersion nvarchar(max);
DECLARE @SchemaSlots TABLE(Id int PRIMARY KEY,Name sysname NOT NULL,Kind char(2) NOT NULL);
INSERT @SchemaSlots VALUES(1,N'USP_ValidateJsonSchema','P'),(2,N'FT_ValidateJsonSchemaInternal','FT');
DECLARE @SchemaAssemblyMarkers TABLE(Name sysname PRIMARY KEY,Value sql_variant NOT NULL);
DECLARE @SchemaConstructorMarkers TABLE(Name sysname PRIMARY KEY,Value sql_variant NOT NULL);
DECLARE @SchemaParameters TABLE(Id int,Name sysname,TypeId int,Length smallint);
INSERT @SchemaParameters VALUES(1,N'@Json',231,-1),(2,N'@Schema',231,-1),(3,N'@Profile',231,64),
 (4,N'@MaxDocumentBytes',127,8),(5,N'@MaxSchemaBytes',127,8),(6,N'@MaxDepth',56,4),(7,N'@MaxEvaluationSteps',127,8),(8,N'@MaxErrors',56,4);
DECLARE @SchemaColumns TABLE(Id int,Name sysname,TypeId int,Length smallint);
INSERT @SchemaColumns VALUES(1,N'RowKind',231,16),(2,N'ErrorOrdinal',56,4),(3,N'Status',231,48),(4,N'Profile',231,64),
 (5,N'IsValid',104,1),(6,N'DocumentPointer',231,-1),(7,N'SchemaPointer',231,-1),(8,N'Keyword',231,256),
 (9,N'ErrorCode',231,64),(10,N'ErrorsTruncated',104,1);
DECLARE @SchemaPublicParameters TABLE(Id int,Name sysname,TypeId int,Length smallint,AliasName sysname NULL);
INSERT @SchemaPublicParameters SELECT Id,Name,CASE WHEN Id=3 THEN 167 ELSE TypeId END,CASE WHEN Id=3 THEN 32 ELSE Length END,NULL FROM @SchemaParameters;
INSERT @SchemaPublicParameters VALUES(9,N'@ResultTable',231,256,N'sysname'),(10,N'@KeepData',104,1,NULL),(11,N'@Debug',48,1,NULL),(12,N'@Hilfe',104,1,NULL);

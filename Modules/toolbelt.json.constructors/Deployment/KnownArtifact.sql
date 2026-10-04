-- Modullokale geschlossene Registryzeile; kein Targethash als KnownInstalled-Fallback.
DECLARE @KnownHash varbinary(64)=0xFF266A2FC46EB4101D87BC046AEF63197B985C8CCBAEA40F372E9918D1254C44F1F2CF8CED7942383625D28E2E1AF5BF6164FA8A16B3DD5A16DF5957FAA34276,
 @KnownArtifactId varchar(64)='e5d0a37f7643a1a7bbe17602ab0d8457bc959464e97496f45f6ddbe92fa15525',@AssemblyId int,@AssemblyOwner int,@InstalledHash varbinary(64),
 @EffectiveOwner int,@KnownMode nvarchar(16),@KnownCount int,@CreatingSlots bit=0;
DECLARE @Parameters TABLE(Slot sysname,Id int,Name sysname,TypeId int,Length smallint);
INSERT @Parameters VALUES
(N'AGF_JsonArray',0,N'',231,-1),
(N'AGF_JsonArray',1,N'@Ordinal',56,4),
(N'AGF_JsonArray',2,N'@ValueKind',231,-1),
(N'AGF_JsonArray',3,N'@Value',231,-1),
(N'AGF_JsonArray',4,N'@Profile',48,1),
(N'AGF_JsonObject',0,N'',231,-1),
(N'AGF_JsonObject',1,N'@Ordinal',56,4),
(N'AGF_JsonObject',2,N'@Key',231,-1),
(N'AGF_JsonObject',3,N'@ValueKind',231,-1),
(N'AGF_JsonObject',4,N'@Value',231,-1),
(N'AGF_JsonObject',5,N'@Profile',48,1),
(N'FT_JsonEntryEvaluateInternal',1,N'@ObjectMode',104,1),
(N'FT_JsonEntryEvaluateInternal',2,N'@Key',231,-1),
(N'FT_JsonEntryEvaluateInternal',3,N'@ValueKind',231,-1),
(N'FT_JsonEntryEvaluateInternal',4,N'@Value',231,-1),
(N'FT_JsonEntryEvaluateInternal',5,N'@Stage',48,1),
(N'FT_JsonEntryEvaluateInternal',6,N'@Policy',48,1);
DECLARE @Columns TABLE(Id int,Name sysname,TypeId int,Length smallint);
INSERT @Columns VALUES
(1,N'Fragment',231,-1),
(2,N'ErrorNumber',56,4),
(3,N'ErrorState',56,4),
(4,N'FaultPhase',48,1),
(5,N'RawValueBytes',127,8),
(6,N'KeyBytes',127,8),
(7,N'StrongMinimumBytes',127,8),
(8,N'FragmentBytes',127,8);

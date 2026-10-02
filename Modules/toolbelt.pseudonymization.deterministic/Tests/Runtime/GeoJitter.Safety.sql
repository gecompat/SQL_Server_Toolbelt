-- Unabhängige synthetische Geo-Orakel; keine realen Geodaten.
SET NOCOUNT ON;
DECLARE @Cases TABLE(Id int,Value geography,Expected int);
DECLARE @invalid geography=geography::STGeomFromText(N'POLYGON ((0 0, 1 1, 0 1, 1 0, 0 0))',4326);
DECLARE @exact geography=geography::STGeomFromText(N'LINESTRING (0 0,1 0,2 0,3 0,4 0,5 0)',4326);
DECLARE @over geography=geography::STGeomFromText(N'LINESTRING (0 0,1 0,2 0,3 0,4 0,5 0,6 0)',4326);
IF @invalid.STIsValid()<>0 OR DATALENGTH(CONVERT(varbinary(max),@invalid))>128
 OR DATALENGTH(CONVERT(varbinary(max),@exact))<>128 OR DATALENGTH(CONVERT(varbinary(max),@over))<=128
 THROW 54090,N'Geo-native Invalid-/128-/over128-Zeugen fehlen.',1;
INSERT @Cases VALUES(1,@invalid,15),(2,@exact,15),(3,@over,15),
 (4,geography::STGeomFromText(N'POINT EMPTY',4326),15),
 (5,geography::Point(0,0,4269),15),(6,geography::STGeomFromText(N'POINT (0 0 3)',4326),15),
 (7,geography::STGeomFromText(N'POINT (0 0 NULL 4)',4326),15),(8,geography::STGeomFromText(N'POINT (0 0 3 4)',4326),15),
 (9,NULL,0),(10,geography::Point(0,0,4326),0);
DECLARE @Actual TABLE(Id int,Value geography,ErrorCode int);
INSERT @Actual SELECT c.Id,t.Value,t.ErrorCode FROM @Cases c
CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicGeoJitter(c.Value,0x01,1,0,100)t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>10 OR EXISTS(SELECT Id FROM @Actual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @Cases c LEFT JOIN @Actual a ON a.Id=c.Id WHERE a.Id IS NULL OR a.ErrorCode IS NULL OR a.ErrorCode<>c.Expected
 OR (c.Id<>10 AND a.Value IS NOT NULL) OR (c.Id=10 AND a.Value IS NULL))
 THROW 54090,N'Geo-native Operandensicherheit/Atomarität falsch.',1;
GO
DECLARE @Cases TABLE(Id int,Value geography,Expected int);
DECLARE @invalid geography=geography::STGeomFromText(N'POLYGON ((0 0, 1 1, 0 1, 1 0, 0 0))',4326);
DECLARE @exact geography=geography::STGeomFromText(N'LINESTRING (0 0,1 0,2 0,3 0,4 0,5 0)',4326);
DECLARE @over geography=geography::STGeomFromText(N'LINESTRING (0 0,1 0,2 0,3 0,4 0,5 0,6 0)',4326);
IF @invalid.STIsValid()<>0 OR DATALENGTH(CONVERT(varbinary(max),@invalid))>128
 OR DATALENGTH(CONVERT(varbinary(max),@exact))<>128 OR DATALENGTH(CONVERT(varbinary(max),@over))<=128
 THROW 54090,N'Geo-native Invalid-/128-/over128-Zeugen fehlen.',1;
INSERT @Cases VALUES(1,@invalid,15),(2,@exact,15),(3,@over,15),
 (4,geography::STGeomFromText(N'POINT EMPTY',4326),15),
 (5,geography::Point(0,0,4269),15),(6,geography::STGeomFromText(N'POINT (0 0 3)',4326),15),
 (7,geography::STGeomFromText(N'POINT (0 0 NULL 4)',4326),15),(8,geography::STGeomFromText(N'POINT (0 0 3 4)',4326),15),
 (9,NULL,0),(10,geography::Point(0,0,4326),0);
DECLARE @Actual TABLE(Id int,Value geography,ErrorCode int);
INSERT @Actual SELECT c.Id,CASE WHEN c.Id=9 THEN CONVERT(geography,NULL) ELSE t.Value END,t.ErrorCode FROM @Cases c
CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicGeoJitter(c.Value,0x01,1,0,100)t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>10 OR EXISTS(SELECT Id FROM @Actual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @Cases c LEFT JOIN @Actual a ON a.Id=c.Id WHERE a.Id IS NULL OR a.ErrorCode IS NULL OR a.ErrorCode<>c.Expected
 OR (c.Id<>10 AND a.Value IS NOT NULL) OR (c.Id=10 AND a.Value IS NULL))
 THROW 54090,N'Geo-native Operandensicherheit/Atomarität falsch.',1;
GO
DECLARE @a TABLE(Value geography,ErrorCode int);
INSERT @a SELECT Value,ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::STGeomFromText(N'POLYGON ((0 0, 1 1, 0 1, 1 0, 0 0))',4326),0x01,1,0,100);
IF (SELECT COUNT_BIG(*) FROM @a)<>1 OR EXISTS(SELECT 1 FROM @a WHERE Value IS NOT NULL OR ErrorCode IS NULL OR ErrorCode<>15)
 THROW 54090,N'Geo-direkter Literalguard falsch.',1;
GO
DECLARE @a TABLE(Value geography,ErrorCode int);
INSERT @a SELECT Value,ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::STGeomFromText(N'LINESTRING (0 0,1 0,2 0,3 0,4 0,5 0)',4326),0x01,1,0,100);
IF (SELECT COUNT_BIG(*) FROM @a)<>1 OR EXISTS(SELECT 1 FROM @a WHERE Value IS NOT NULL OR ErrorCode IS NULL OR ErrorCode<>15)
 THROW 54090,N'Geo-direkter Literalguard falsch.',1;
GO
DECLARE @a TABLE(Value geography,ErrorCode int);
INSERT @a SELECT Value,ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::STGeomFromText(N'LINESTRING (0 0,1 0,2 0,3 0,4 0,5 0,6 0)',4326),0x01,1,0,100);
IF (SELECT COUNT_BIG(*) FROM @a)<>1 OR EXISTS(SELECT 1 FROM @a WHERE Value IS NOT NULL OR ErrorCode IS NULL OR ErrorCode<>15)
 THROW 54090,N'Geo-direkter Literalguard falsch.',1;
GO
-- Integergrenze ist kein behaupteter 129-Byte-UDT-Zeuge.
IF EXISTS(SELECT 1 FROM (VALUES(127,1),(128,1),(129,0))v(bytes,expected) WHERE CASE WHEN bytes<=128 THEN 1 ELSE 0 END<>expected)
 THROW 54090,N'Geo-Integerbudgetgrenze falsch.',1;
-- Fehlerhafte Argumentkonstruktion liegt außerhalb der TVF; kein ErrorCode15-Oracle.
DECLARE @rejected bit=0;
BEGIN TRY
 DECLARE @outside geography=geography::Point(91,0,4326);
END TRY
BEGIN CATCH
 SET @rejected=1;
END CATCH;
IF @rejected=0 THROW 54090,N'Geo-Callerkonstruktor muss fehlschlagen.',1;
PRINT N'PASS: Geo unabhängige native Safety-Orakel;129-Byte-UDT nicht qualifiziert.';

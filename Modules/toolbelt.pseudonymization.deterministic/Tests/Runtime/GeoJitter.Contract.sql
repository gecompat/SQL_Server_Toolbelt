-- Unabhängige synthetische Geo-Orakel; keine realen Geodaten.
SET NOCOUNT ON;
DECLARE @id int=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicGeoJitter',N'IF');
IF @id IS NULL THROW 54090,N'Geo muss eine echte Inline-TVF sein.',1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id=@id)<>2
 OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@id AND column_id=1 AND name=N'Value' AND user_type_id=TYPE_ID(N'geography') AND is_nullable=1)
 OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@id AND column_id=2 AND name=N'ErrorCode' AND system_type_id=56 AND max_length=4 AND is_nullable=0)
 THROW 54090,N'Geo-Spaltenmetadaten falsch.',1;
DECLARE @p TABLE(Id int,Name sysname,TypeId int,Length int);
INSERT @p VALUES(1,N'@Value',240,-1),(2,N'@Key',165,-1),(3,N'@MappingVersion',56,4),(4,N'@Seed',127,8),(5,N'@RadiusMeters',56,4);
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@id)<>5
 OR EXISTS(SELECT 1 FROM @p p LEFT JOIN sys.parameters a ON a.object_id=@id AND a.parameter_id=p.Id
 WHERE a.parameter_id IS NULL OR a.name COLLATE Latin1_General_100_BIN2<>p.Name COLLATE Latin1_General_100_BIN2 OR a.system_type_id<>p.TypeId OR a.max_length<>p.Length)
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@id AND parameter_id=1 AND user_type_id=TYPE_ID(N'geography'))
 THROW 54090,N'Geo-Parametermetadaten falsch.',1;
GO
DECLARE @Vectors TABLE(Id int,Lat float,Lon float,Radius int,[Key] varbinary(max),Version int,Seed bigint,ExpectedLat float,ExpectedLon float);
INSERT @Vectors VALUES
(1,0,0,100,0x436f6e746f736f,1,CONVERT(bigint,'0'),0.000093295597217,-0.000851220857243),
(2,45,179.999999,10000,0x436f6e746f736f,1,CONVERT(bigint,'0'),45.009266314695601,179.879598675468515),
(3,-45,-179.999999,10000,0x436f6e746f736f,1,CONVERT(bigint,'0'),-44.990607222859673,179.879639878937780),
(4,90,180,1,0x436f6e746f736f,1,CONVERT(bigint,'0'),89.999991436817083,-96.254772306540488),
(5,-90,-180,10000,0x436f6e746f736f,1,CONVERT(bigint,'0'),-89.914368171552539,-83.745227670122702),
(6,89.999999,-179.999999,100,0x00,2147483647,CONVERT(bigint,'-9223372036854775808'),89.999718165690240,-28.790814209926396),
(7,-89.999999,179.999999,1,0xff,42,CONVERT(bigint,'9223372036854775807'),-89.999996864555044,-33.206263718927516),
(8,0,0,10000,CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'x'),8000)),1,CONVERT(bigint,'-1'),0.011164043595591,0.029385142791881),
(9,0,0,1,0x436f6e746f736f,1,CONVERT(bigint,'0'),0.000000932955972,-0.000008512208581),
(10,0,0,100,0x436f6e746f736f,1,CONVERT(bigint,'1'),0.000676184792113,-0.000137847595255);
DECLARE @Actual TABLE(Id int,Value geography,ErrorCode int);
INSERT @Actual SELECT v.Id,t.Value,t.ErrorCode FROM @Vectors v
CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(v.Lat,v.Lon,4326),v.[Key],v.Version,v.Seed,v.Radius)t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>10 OR EXISTS(SELECT Id FROM @Actual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @Vectors v LEFT JOIN @Actual a ON a.Id=v.Id WHERE a.Id IS NULL OR a.ErrorCode IS NULL OR a.ErrorCode<>0 OR a.Value IS NULL
 OR ABS(a.Value.Lat-v.ExpectedLat)>1E-9
 OR ABS((a.Value.Long-v.ExpectedLon)-360.*FLOOR((a.Value.Long-v.ExpectedLon+180.)/360.))>1E-9
 OR a.Value.STIsValid()<>1 OR a.Value.STIsEmpty()<>0 OR a.Value.STGeometryType()<>N'Point' OR a.Value.STSrid<>4326
 OR a.Value.Z IS NOT NULL OR a.Value.M IS NOT NULL
 OR a.Value.Long < -180. OR a.Value.Long >=180.
 OR a.Value.STDistance(geography::Point(v.Lat,v.Lon,4326)) IS NULL
 OR a.Value.STDistance(geography::Point(v.Lat,v.Lon,4326))<0.
 OR a.Value.STDistance(geography::Point(v.Lat,v.Lon,4326))>v.Radius)
 THROW 54090,N'Geo-Festvektoren/Distanznachbedingungen falsch.',1;
GO
DECLARE @a TABLE(Value geography,ErrorCode int);
INSERT @a SELECT Value,ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(0,0,4326),0x436f6e746f736f,1,DEFAULT,DEFAULT);
IF (SELECT COUNT_BIG(*) FROM @a)<>1 OR EXISTS(SELECT 1 FROM @a WHERE Value IS NULL OR ErrorCode IS NULL OR ErrorCode<>0 OR ABS(Value.Lat-(0.000093295597217))>1E-9 OR ABS(Value.Long-(-0.000851220857243))>1E-9)
 THROW 54090,N'Geo-Defaults falsch.',1;
GO
-- Alle Kombinationen von NULL/invalid/gültig über die unabhängigen Prioritätsdimensionen.
DECLARE @good geography=geography::Point(0,0,4326),@bad geography=geography::STGeomFromText(N'POLYGON ((0 0, 1 1, 0 1, 1 0, 0 0))',4326);
IF @bad.STIsValid()<>0 THROW 54090,N'Invalid-Geo-Zeuge fehlt.',1;
DECLARE @Cases TABLE(Id int IDENTITY,Value geography,[Key] varbinary(max),Version int,Seed bigint,Radius int,Expected int);
INSERT @Cases SELECT CASE g.x WHEN 0 THEN NULL WHEN 1 THEN @good ELSE @bad END,
 CASE k.x WHEN 0 THEN NULL WHEN 1 THEN 0x WHEN 2 THEN 0x01 ELSE CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'x'),8001)) END,
 v.x,s.x,r.x,
 CASE WHEN g.x=0 OR k.x=0 THEN 0 WHEN v.x IS NULL OR v.x<=0 THEN 1 WHEN s.x IS NULL THEN 2
 WHEN r.x IS NULL OR r.x NOT BETWEEN 1 AND 10000 THEN 14 WHEN k.x IN(1,3) THEN 4 WHEN g.x=2 THEN 15 ELSE 0 END
FROM (VALUES(0),(1),(2))g(x) CROSS JOIN(VALUES(0),(1),(2),(3))k(x)
 CROSS JOIN(VALUES(CONVERT(int,NULL)),(0),(1))v(x)
 CROSS JOIN(VALUES(CONVERT(bigint,NULL)),(CONVERT(bigint,0)))s(x)
 CROSS JOIN(VALUES(CONVERT(int,NULL)),(-1),(0),(1),(100),(10000),(10001))r(x);
DECLARE @Actual TABLE(Id int,Value geography,ErrorCode int);
INSERT @Actual SELECT c.Id,t.Value,t.ErrorCode FROM @Cases c
CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicGeoJitter(c.Value,c.[Key],c.Version,c.Seed,c.Radius)t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>504 OR EXISTS(SELECT Id FROM @Actual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @Cases c LEFT JOIN @Actual a ON a.Id=c.Id WHERE a.Id IS NULL OR a.ErrorCode IS NULL OR a.ErrorCode<>c.Expected
 OR (c.Expected<>0 AND a.Value IS NOT NULL) OR (c.Expected=0 AND c.Value IS NOT NULL AND c.[Key] IS NOT NULL AND a.Value IS NULL)
 OR (c.Expected=0 AND (c.Value IS NULL OR c.[Key] IS NULL) AND a.Value IS NOT NULL))
 THROW 54090,N'Geo-kombinierte Fehlerpriorität/Zeilenatomarität falsch.',1;
GO
-- Wiederholung und identische Polbasis: ein API-Ausdruck, gespeicherte Ergebnisse vergleichen.
DECLARE @Inputs TABLE(Id int,Lat float,Lon float);
INSERT @Inputs VALUES(1,0,0),(2,0,0),(3,90,-180),(4,90,180),(5,-90,-180),(6,-90,180);
DECLARE @a TABLE(Id int,Value geography,ErrorCode int);
INSERT @a SELECT i.Id,t.Value,t.ErrorCode FROM @Inputs i CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(i.Lat,i.Lon,4326),0x436f6e746f736f,1,0,100)t;
IF (SELECT COUNT_BIG(*) FROM @a)<>6 OR EXISTS(SELECT Id FROM @a GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @a WHERE Value IS NULL OR ErrorCode IS NULL OR ErrorCode<>0)
 OR EXISTS(SELECT 1 FROM (VALUES(1,2),(3,4),(5,6))p(x,y) JOIN @a a ON a.Id=p.x JOIN @a b ON b.Id=p.y WHERE ABS(a.Value.Lat-b.Value.Lat)>1E-9 OR ABS(a.Value.Long-b.Value.Long)>1E-9)
 THROW 54090,N'Geo-Wiederholung/kanonische Pole falsch.',1;
PRINT N'PASS: Geo unabhängiger Vertrag/Prioritätsmatrix/Festvektoren.';

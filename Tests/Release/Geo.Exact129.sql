-- Neuer enger Native-Zeuge; keine Produktfunktion oder QuotenÃ¤nderung.
SET NOCOUNT ON;
DECLARE @Wkt nvarchar(max)=N'POINT (0 0)',@Depth int=0;
WHILE @Depth<9
BEGIN SET @Wkt=N'GEOMETRYCOLLECTION ('+@Wkt+N')';SET @Depth+=1;END;
DECLARE @Boundary geography=geography::STGeomFromText(@Wkt,4326);
DECLARE @Bytes int=DATALENGTH(CONVERT(varbinary(max),@Boundary));
IF @Boundary IS NULL OR @Bytes<>129 OR @Boundary.STIsValid()<>1
 OR @Boundary.STGeometryType()<>N'GeometryCollection'
BEGIN
 DECLARE @Message nvarchar(2048)=CONCAT(N'Exact native 129-byte geography witness unavailable. ActualBytes=',COALESCE(CONVERT(nvarchar(12),@Bytes),N'NULL'));
 THROW 54090,@Message,1;
END;
DECLARE @B table([Value] geography,ErrorCode int);
INSERT @B SELECT [Value],ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(@Boundary,0x01,1,0,100);
IF (SELECT COUNT(*) FROM @B)<>1 OR NOT EXISTS(SELECT 1 FROM @B WHERE ErrorCode=15 AND [Value] IS NULL)
 THROW 54090,N'Exact 129-byte native operand must be rejected without value.',2;
DECLARE @P table([Value] geography,ErrorCode int);
INSERT @P SELECT [Value],ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(0,0,4326),0x01,1,0,100);
IF (SELECT COUNT(*) FROM @P)<>1 OR NOT EXISTS(SELECT 1 FROM @P WHERE ErrorCode=0 AND [Value] IS NOT NULL
 AND [Value].STIsValid()=1 AND [Value].STGeometryType()=N'Point' AND [Value].STSrid=4326)
 THROW 54090,N'Positive point control must remain usable.',3;
SELECT @Bytes BoundaryBytes,B.ErrorCode BoundaryError,
 CASE WHEN B.[Value] IS NULL THEN 1 ELSE 0 END BoundaryNull,P.ErrorCode PositiveError,
 CONVERT(int,P.[Value].STIsValid()) PositiveValid FROM @B B CROSS JOIN @P P;

SET NOCOUNT ON;
DECLARE @CompatibilityLevel int=TRY_CONVERT(int,N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN(150,160,170) THROW 52720,N'CompatibilityLevel muss 150, 160 oder 170 sein.',1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>@CompatibilityLevel THROW 52721,N'Falscher Compatibility Level.',1;
IF OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentEncode',N'IF') IS NULL OR OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentDecode',N'IF') IS NULL THROW 52722,N'Die Funktionen fehlen.',1;
IF (SELECT EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncode(N'Kaffee & Tee'))<>N'Kaffee%20%26%20Tee' THROW 52723,N'Encode ist falsch.',1;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'%252F') WHERE DecodedValue<>N'%2F' OR IsValid<>1 OR ValidationCode<>0)
BEGIN
 SELECT DecodedValue,IsValid,ValidationCode FROM toolbelt_conversion.TVF_UriComponentDecode(N'%252F');
 THROW 52724,N'Einmaliges Decoding ist falsch.',1;
END;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'%G0') WHERE IsValid<>0 OR ValidationCode<>11) THROW 52725,N'Ungültiges Prozent-Triplet ist falsch.',1;
IF (SELECT EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncode(N'€😀'))<>N'%E2%82%AC%F0%9F%98%80' THROW 52740,N'Das UTF-8-Encoding ist falsch.',1;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'%E2%82%AC%F0%9F%98%80') WHERE DecodedValue<>N'€😀' OR IsValid<>1 OR ValidationCode<>0)
BEGIN
 SELECT DecodedValue,IsValid,ValidationCode FROM toolbelt_conversion.TVF_UriComponentDecode(N'%E2%82%AC%F0%9F%98%80');
 THROW 52741,N'Das UTF-8-Decoding ist falsch.',1;
END;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'%C0%AF') WHERE IsValid<>0 OR ValidationCode<>12) THROW 52742,N'Nicht kanonisches UTF-8 wird nicht abgelehnt.',1;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'%00') WHERE IsValid<>0 OR ValidationCode<>13) THROW 52743,N'Decodiertes NUL wird nicht abgelehnt.',1;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'ä') WHERE IsValid<>0 OR ValidationCode<>10) THROW 52744,N'Unescaped Nicht-ASCII-Input wird nicht als IRI abgelehnt.',1;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(NULL) WHERE DecodedValue IS NOT NULL OR IsValid IS NOT NULL OR ValidationCode IS NOT NULL) THROW 52745,N'NULL wird nicht vertragsgemäß weitergegeben.',1;
IF (SELECT EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncode(N''))<>N'' OR EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'') WHERE DecodedValue<>N'' OR IsValid<>1 OR ValidationCode<>0) THROW 52746,N'Der Leerstringvertrag ist falsch.',1;
IF toolbelt_conversion.SVF_UriComponentEncode(N'€😀')<>(SELECT EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncode(N'€😀')) OR toolbelt_conversion.SVF_UriComponentDecode(N'%E2%82%AC%F0%9F%98%80')<>(SELECT DecodedValue FROM toolbelt_conversion.TVF_UriComponentDecode(N'%E2%82%AC%F0%9F%98%80')) THROW 52747,N'Die SVF-/TVF-Parität ist falsch.',1;

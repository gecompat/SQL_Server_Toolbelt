SET NOCOUNT ON;
DECLARE @CompatibilityLevel int=TRY_CONVERT(int,N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN(150,160,170) THROW 52720,N'CompatibilityLevel muss 150, 160 oder 170 sein.',1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>@CompatibilityLevel THROW 52721,N'Falscher Compatibility Level.',1;
IF OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentEncode',N'IF') IS NULL OR OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentDecode',N'IF') IS NULL THROW 52722,N'Die Funktionen fehlen.',1;
IF (SELECT EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncode(N'Kaffee & Tee'))<>N'Kaffee%20%26%20Tee' THROW 52723,N'Encode ist falsch.',1;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'%252F') WHERE DecodedValue<>N'%2F' OR IsValid<>1 OR ValidationCode<>0) THROW 52724,N'Einmaliges Decoding ist falsch.',1;
IF EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecode(N'%G0') WHERE IsValid<>0 OR ValidationCode<>11) THROW 52725,N'Ungültiges Prozent-Triplet ist falsch.',1;

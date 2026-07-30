SET NOCOUNT ON;
DECLARE @CompatibilityLevel int=TRY_CONVERT(int,N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN(150,160,170) THROW 52710,N'CompatibilityLevel muss 150, 160 oder 170 sein.',1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>@CompatibilityLevel THROW 52711,N'Falscher Compatibility Level.',1;
IF OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalNvarchar',N'IF') IS NULL OR OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalVarchar',N'IF') IS NULL THROW 52712,N'Die Funktionen fehlen.',1;
IF (SELECT Value FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'..A..',N'.','LEADING'))<>N'A..' THROW 52713,N'LEADING ist falsch.',1;
IF (SELECT Value FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'..A..',N'.','TRAILING'))<>N'..A' THROW 52714,N'TRAILING ist falsch.',1;
IF (SELECT Value FROM toolbelt_string.TVF_TrimDirectionalVarchar('..A..','.','BOTH'))<>'A' THROW 52715,N'BOTH ist falsch.',1;
IF (SELECT Value FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'%_[A]_%',N'%_[]','BOTH'))<>N'A' THROW 52716,N'Der Zeichensatz wird nicht literal interpretiert.',1;
IF (SELECT Value FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'',N'.','BOTH'))<>N'' THROW 52717,N'Der Leerstring ist falsch.',1;
IF EXISTS(SELECT 1 FROM toolbelt_string.TVF_TrimDirectionalNvarchar(NULL,N'.','BOTH') WHERE Value IS NOT NULL) THROW 52718,N'NULL wird nicht vertragsgemäß weitergegeben.',1;
IF (SELECT Value FROM toolbelt_string.TVF_TrimDirectionalNvarchar(NCHAR(0)+N'A'+NCHAR(0),NCHAR(0),'BOTH'))<>NCHAR(0)+N'A'+NCHAR(0) THROW 52719,N'NUL darf nicht als Trim-Zeichen behandelt werden.',1;
IF @CompatibilityLevel>=160
BEGIN
 DECLARE @Native nvarchar(max),@Portable nvarchar(max);
 EXEC sys.sp_executesql N'SELECT @Result=TRIM(LEADING N''.'' FROM N''..A..'');',N'@Result nvarchar(max) OUTPUT',@Result=@Native OUTPUT;
 SELECT @Portable=Value FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'..A..',N'.','LEADING');
 IF @Native<>@Portable THROW 52726,N'Die native TRIM-Parität ist falsch.',1;
END;

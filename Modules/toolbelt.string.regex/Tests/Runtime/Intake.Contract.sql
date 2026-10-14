SET NOCOUNT ON;
-- All nine SQL-bound entries must use the streaming intake surface.
IF (SELECT COUNT(*) FROM sys.assembly_modules WHERE assembly_class=N'Toolbelt.String.Regex.RegexProvider'
    AND assembly_method LIKE N'%Bounded')<>9
 THROW 52079,N'Die neun begrenzten CLR-Einstiege fehlen.',1;
DECLARE @Oversized nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),1048577);
DECLARE @Calls table(Id int IDENTITY,Statement nvarchar(max));
INSERT @Calls VALUES
 (N'SELECT toolbelt_string.SVF_RegexIsMatch(@x,N''x'',''c'');'),
 (N'SELECT toolbelt_string.SVF_RegexCount(@x,N''x'',1,''c'');'),
 (N'SELECT toolbelt_string.SVF_RegexInstr(@x,N''x'',1,1,0,''c'');'),
 (N'SELECT toolbelt_string.SVF_RegexSubstring(@x,N''x'',1,1,''c'',''standard'');'),
 (N'SELECT toolbelt_string.SVF_RegexReplace(@x,N''x'',N''y'',1,0,''c'',''standard'');'),
 (N'SELECT toolbelt_string.SVF_RegexReplaceGroups(@x,N''(x)'',N''$1'',1,0,''c'',''standard'');'),
 (N'SELECT * FROM toolbelt_string.TVF_RegexMatches(@x,N''x'',1,''c'',''standard'',10);'),
 (N'SELECT * FROM toolbelt_string.TVF_RegexSplit(@x,N''x'',''c'',''standard'',10);'),
 (N'SELECT * FROM toolbelt_string.TVF_RegexCaptures(@x,N''(x)'',1,''c'',''standard'',10);');
DECLARE @Id int=1,@Statement nvarchar(max);
WHILE @Id<=9
BEGIN
 SELECT @Statement=Statement FROM @Calls WHERE Id=@Id;
 BEGIN TRY
  EXEC sys.sp_executesql @Statement,N'@x nvarchar(max)',@x=@Oversized;
  THROW 52079,N'Übergroßer CLR-Input wurde angenommen.',2;
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()<>6522 OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_INPUT_TOO_LARGE%' THROW;
 END CATCH;
 SET @Id+=1;
END;
PRINT N'Regex bounded SQL intake: all nine entries PASS.';

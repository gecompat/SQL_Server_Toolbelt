SET NOCOUNT ON;
PRINT N'REGEX_DIAG_0_standard-no-match';
DECLARE @V nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),1048576);
DECLARE @Actual nvarchar(max)=toolbelt_string.SVF_RegexReplace(@V,N'Z',N'',1,0,N'c',N'standard');
IF @Actual IS NULL OR DATALENGTH(@Actual)<>DATALENGTH(@V) OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@V) THROW 52094,N'Isolated positive boundary byte oracle failed.',1;

GO
SET NOCOUNT ON;
PRINT N'REGEX_DIAG_1_large-no-match';
DECLARE @V nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608);
DECLARE @Actual nvarchar(max)=toolbelt_string.SVF_RegexReplace(@V,N'Z',N'',1,0,N'c',N'large');
IF @Actual IS NULL OR DATALENGTH(@Actual)<>DATALENGTH(@V) OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@V) THROW 52094,N'Isolated positive boundary byte oracle failed.',2;

GO
SET NOCOUNT ON;
PRINT N'REGEX_DIAG_2_large-replacement';
DECLARE @V nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608);
DECLARE @Actual nvarchar(max)=toolbelt_string.SVF_RegexReplace(N'x',N'x',@V,1,1,N'c',N'large');
IF @Actual IS NULL OR DATALENGTH(@Actual)<>DATALENGTH(@V) OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@V) THROW 52094,N'Isolated positive boundary byte oracle failed.',3;

GO
SET NOCOUNT ON;
PRINT N'REGEX_DIAG_3_large-substring';
DECLARE @V nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608);
DECLARE @Actual nvarchar(max)=toolbelt_string.SVF_RegexSubstring(@V,N'a{1000}',1,1,N'c',N'large');
IF @Actual IS NULL OR DATALENGTH(@Actual)<>DATALENGTH(CONVERT(nvarchar(max),REPLICATE(N'a',1000))) OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),CONVERT(nvarchar(max),REPLICATE(N'a',1000))) THROW 52094,N'Isolated positive boundary byte oracle failed.',4;

GO
SET NOCOUNT ON;
PRINT N'REGEX_DIAG_4_pattern-8000';
DECLARE @V nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8000);
DECLARE @Actual nvarchar(max)=toolbelt_string.SVF_RegexSubstring(@V,@V,1,1,N'c',N'standard');
IF @Actual IS NULL OR DATALENGTH(@Actual)<>DATALENGTH(@V) OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@V) THROW 52094,N'Isolated positive boundary byte oracle failed.',5;

GO
SET NOCOUNT ON;
PRINT N'REGEX_DIAG_5_depth-64';
DECLARE @P nvarchar(max)=REPLICATE(N'(',64)+N'x'+REPLICATE(N')',64);
DECLARE @Actual nvarchar(max)=toolbelt_string.SVF_RegexSubstring(N'x',@P,1,1,N'c',N'standard');
IF @Actual IS NULL OR DATALENGTH(@Actual)<>DATALENGTH(N'x') OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),N'x') THROW 52094,N'Isolated positive boundary byte oracle failed.',6;

GO
SET NOCOUNT ON;
PRINT N'REGEX_DIAG_6_alternations-1024';
DECLARE @P nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x|'),1024)+N'x';
DECLARE @Actual nvarchar(max)=toolbelt_string.SVF_RegexSubstring(N'x',@P,1,1,N'c',N'standard');
IF @Actual IS NULL OR DATALENGTH(@Actual)<>DATALENGTH(N'x') OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),N'x') THROW 52094,N'Isolated positive boundary byte oracle failed.',7;

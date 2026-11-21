-- Current focused functional countercases. Synthetic input only.
-- Execute only in an explicitly selected, owned test database containing the
-- four modules and GenerateSeries. Repeat under selected non-SC, SC and UTF8
-- database collations only within a concrete finite native test authorization.
-- No installation, rights, configuration, data or infrastructure changes here.
SET NOCOUNT ON;
DECLARE @Pair nvarchar(2)=CONVERT(nvarchar(2),0x3DD800DE);

IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256))
    WHERE DecodedValue IS NULL AND IsValid=0 AND ValidationCode=10 AND Status='INVALID')
    THROW 52800,N'EDGE_URI_NON_ASCII_STATUS',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%GG')
    WHERE DecodedValue IS NULL AND IsValid=0 AND ValidationCode=11 AND Status='INVALID')
    THROW 52800,N'EDGE_URI_INVALID_PERCENT',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%00')
    WHERE DecodedValue IS NULL AND IsValid=0 AND ValidationCode=13 AND Status='INVALID')
    THROW 52800,N'EDGE_URI_NUL_STATUS',3;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'')
    WHERE DATALENGTH(DecodedValue)=0 AND IsValid=1 AND ValidationCode=0 AND Status='OK')
    THROW 52800,N'EDGE_URI_EMPTY',4;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%F0%9F%98%80')
    WHERE Status='OK' AND IsValid=1 AND ValidationCode=0
      AND CONVERT(varbinary(max),DecodedValue)=CONVERT(varbinary(max),@Pair)
      AND CONVERT(varbinary(max),toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80'))=CONVERT(varbinary(max),@Pair))
    THROW 52800,N'EDGE_URI_SUPPLEMENTARY_BYTES',5;

IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"')
    WHERE PathExists=0 AND Status='MISSING')
    THROW 52801,N'EDGE_JSON_KEY_TRAILING_SPACE',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":1}',N'$."a "')
    WHERE PathExists=0 AND Status='MISSING')
    THROW 52801,N'EDGE_JSON_PATH_TRAILING_SPACE',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{" ":1}',N'$.""')
    WHERE PathExists=0 AND Status='MISSING')
    THROW 52801,N'EDGE_JSON_EMPTY_VERSUS_SPACE',3;
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":null}',N'$."a "')
    WHERE PathExists=1 AND Status='FOUND')
    THROW 52801,N'EDGE_JSON_EXACT_NULL_VALUE_KEY',4;
DECLARE @HomoglyphJson nvarchar(max)=N'"'+NCHAR(65282)+REPLICATE(N'[',129)+N'"';
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(@HomoglyphJson,N'$')
    WHERE PathExists=1 AND Status='FOUND')
    THROW 52801,N'EDGE_JSON_LITERAL_ASCII_QUOTING',5;

DECLARE @Input nvarchar(1035),@Expected nvarchar(1035);
SET @Input=N'dbo.'+@Pair;
SET @Expected=N'[dbo].['+@Pair+N']';
IF NOT EXISTS(SELECT 1 FROM toolbelt_metadata.TVF_ParseMultipartName(@Input)
    WHERE IsValid=1 AND CONVERT(varbinary(max),ObjectName)=CONVERT(varbinary(max),@Pair)
      AND CONVERT(varbinary(max),QuotedName)=CONVERT(varbinary(max),@Expected))
    THROW 52802,N'EDGE_IDENTIFIER_SUPPLEMENTARY_BYTES',1;
IF NOT EXISTS(SELECT 1 WHERE CONVERT(varbinary(max),toolbelt_metadata.SVF_QuoteMultipartName(@Input))=CONVERT(varbinary(max),@Expected))
    THROW 52802,N'EDGE_IDENTIFIER_SCALAR_BYTES',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_metadata.TVF_ParseMultipartName(REPLICATE(@Pair,64)) WHERE IsValid=1)
    THROW 52802,N'EDGE_IDENTIFIER_128_UNITS',3;
IF NOT EXISTS(SELECT 1 FROM toolbelt_metadata.TVF_ParseMultipartName(REPLICATE(@Pair,65))
    WHERE IsValid=0 AND ValidationCode='PART_TOO_LONG')
    THROW 52802,N'EDGE_IDENTIFIER_130_UNITS',4;
IF NOT EXISTS(SELECT 1 FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ ]')
    WHERE IsValid=1 AND CONVERT(varbinary(max),ObjectName)=CONVERT(varbinary(max),N' '))
    THROW 52802,N'EDGE_IDENTIFIER_DELIMITED_SPACE',5;
IF NOT EXISTS(SELECT 1 FROM toolbelt_metadata.TVF_ParseMultipartName(N' [x]')
    WHERE IsValid=0 AND ValidationCode='BRACKET_SYNTAX')
    THROW 52802,N'EDGE_IDENTIFIER_SPACE_BEFORE_DELIMITER',6;
SET @Input=NCHAR(65339)+N'x'+NCHAR(65341);
SET @Expected=N'['+@Input+N']';
IF NOT EXISTS(SELECT 1 FROM toolbelt_metadata.TVF_ParseMultipartName(@Input)
    WHERE IsValid=1 AND CONVERT(varbinary(max),QuotedName)=CONVERT(varbinary(max),@Expected))
    THROW 52802,N'EDGE_IDENTIFIER_LITERAL_DELIMITERS',7;

DECLARE @Unicode nvarchar(max)=@Pair+NCHAR(0)+N'x',
    @UnicodeExpected nvarchar(max)=@Pair+NCHAR(0),
    @Ansi varchar(max),@AnsiExpected varchar(max);
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_TrimDirectionalNvarchar(@Unicode,N'x','TRAILING')
    WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),@UnicodeExpected))
    THROW 52803,N'EDGE_TRIM_SC_NUL_POSITION',1;
SET @Ansi=CONVERT(varchar(max),@Unicode);
SET @AnsiExpected=CONVERT(varchar(max),@UnicodeExpected);
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_TrimDirectionalVarchar(@Ansi,'x','TRAILING')
    WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),@AnsiExpected))
    THROW 52803,N'EDGE_TRIM_UTF8_NUL_POSITION',2;

SELECT CONVERT(int,19) AS AssertionsPassed;

SET NOCOUNT ON;

DECLARE @Sql nvarchar(max) = N'
IF [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexIsMatch(N''abc123'', N''^[a-z]+\d+$'', ''c'') <> 1
   OR [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexInstr(N''abc123'', N''\d+'', 1, 1, 0, ''c'') <> 4
   OR [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexCount(N''a1b2'', N''\d'', 1, ''c'') <> 2
   OR ISNULL([$(ToolbeltDatabase)].toolbelt_string.SVF_RegexReplace(N''a12'', N''[0-9]+'', N''X'', DEFAULT, DEFAULT, DEFAULT, DEFAULT) COLLATE Latin1_General_100_BIN2,N''#NULL#'') <> N''aX'' COLLATE Latin1_General_100_BIN2
   OR ISNULL([$(ToolbeltDatabase)].toolbelt_string.SVF_RegexSubstring(N''a12'', N''[0-9]+'', DEFAULT, DEFAULT, DEFAULT, DEFAULT) COLLATE Latin1_General_100_BIN2,N''#NULL#'') <> N''12'' COLLATE Latin1_General_100_BIN2
    THROW 52087, N''Der zentrale Regex-Vertrag ist verletzt.'', 1;';
EXEC sys.sp_executesql @Sql;

-- Explizite Dekodierung erfolgt unter der Quell-Collation vor dem Centralcall.
SET @Sql = N'
DECLARE @Sources TABLE (Classic varchar(max) COLLATE Latin1_General_100_CI_AS,
 Utf8 varchar(max) COLLATE Latin1_General_100_CI_AS_SC_UTF8);
INSERT @Sources VALUES (N''Grüße'',N''Grüße'');
DECLARE @DecodedClassic nvarchar(max), @DecodedUtf8 nvarchar(max);
SELECT @DecodedClassic = CONVERT(nvarchar(max),Classic),
 @DecodedUtf8 = CONVERT(nvarchar(max),Utf8) FROM @Sources;
IF ISNULL([$(ToolbeltDatabase)].toolbelt_string.SVF_RegexSubstring(@DecodedClassic,N''Grüße'',DEFAULT,DEFAULT,DEFAULT,DEFAULT) COLLATE Latin1_General_100_BIN2,N''#NULL#'') <> N''Grüße'' COLLATE Latin1_General_100_BIN2
 OR ISNULL([$(ToolbeltDatabase)].toolbelt_string.SVF_RegexReplace(@DecodedUtf8,N''ü'',N''ue'',DEFAULT,DEFAULT,DEFAULT,DEFAULT) COLLATE Latin1_General_100_BIN2,N''#NULL#'') <> N''Grueße'' COLLATE Latin1_General_100_BIN2
 THROW 52087,N''Quell-Codepage-Konvertierung vor Centralcall falsch.'',2;';
EXEC sys.sp_executesql @Sql;

PRINT N'Regex-Central-Contract erfolgreich.';

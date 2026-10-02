SET NOCOUNT ON;

-- Beide neuen Fassaden ausschließlich qualifiziert aus der Caller-Datenbank.
DECLARE @Rows table
(MatchOrdinal bigint,GroupOrdinal int,CaptureOrdinal bigint,GroupName nvarchar(128),
 Matched bit,StartPosition bigint,Length bigint,Value nvarchar(max));
INSERT @Rows
SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexCaptures(N'b',N'(?<First>a)?(b)',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM @Rows)<>2
 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE MatchOrdinal=1 AND GroupOrdinal=1 AND CaptureOrdinal=0 AND GroupName=N'First' AND Matched=0 AND StartPosition IS NULL AND Length IS NULL AND Value IS NULL)
 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE MatchOrdinal=1 AND GroupOrdinal=2 AND CaptureOrdinal=1 AND GroupName=N'2' AND Matched=1 AND StartPosition=1 AND Length=1 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'b'))
 THROW 52097,N'Zentrale Capture-Fassade verletzt Sentinel-/Ordinalvertrag.',7;
DECLARE @Result nvarchar(max)=[$(ToolbeltDatabase)].toolbelt_string.SVF_RegexReplaceGroups(N'b',N'(?<First>a)?(b)',N'${First}:$2',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
IF @Result IS NULL OR CONVERT(varbinary(max),@Result)<>CONVERT(varbinary(max),N':b')
 THROW 52097,N'Zentrale Replace-Fassade verletzt Gruppenvertrag.',8;
PRINT N'Capture-/Replace-Central-Vertrag erfolgreich.';

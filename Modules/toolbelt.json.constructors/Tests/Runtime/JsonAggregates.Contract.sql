-- Synthetische positive Engineproben. Keine Behauptung über Callbackhäufigkeit oder Spill.
SET NOCOUNT ON;
DECLARE @Entries TABLE(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(1,2,N'b',N'number',N'2',1),(1,1,N'a',N'string',N'x',1),
 (2,2,N'n',N'null',NULL,2),(2,1,N'j',N'json',N'[]',2);
DECLARE @Actual TABLE(GroupOrdinal int,ArrayValue nvarchar(max),ObjectValue nvarchar(max));
INSERT @Actual SELECT GroupOrdinal,toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile),
 toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile)
 FROM @Entries GROUP BY GroupOrdinal;
IF (SELECT COUNT(*) FROM @Actual)<>2 OR EXISTS(SELECT 1 FROM @Actual WHERE
 (GroupOrdinal=1 AND (CONVERT(varbinary(max),ArrayValue)<>CONVERT(varbinary(max),N'["x",2]')
  OR CONVERT(varbinary(max),ObjectValue)<>CONVERT(varbinary(max),N'{"a":"x","b":2}')))
 OR(GroupOrdinal=2 AND (CONVERT(varbinary(max),ArrayValue)<>CONVERT(varbinary(max),N'[[],null]')
  OR CONVERT(varbinary(max),ObjectValue)<>CONVERT(varbinary(max),N'{"j":[],"n":null}')))
 OR ArrayValue IS NULL OR ObjectValue IS NULL)
 THROW 53690,N'JSON aggregate grouped output mismatch.',1;
DELETE FROM @Entries;
DECLARE @EmptyArray nvarchar(max),@EmptyObject nvarchar(max);
SELECT @EmptyArray=toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile),
 @EmptyObject=toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile) FROM @Entries;
IF @EmptyArray IS NULL OR @EmptyObject IS NULL OR CONVERT(varbinary(max),@EmptyArray)<>CONVERT(varbinary(max),N'[]')
 OR CONVERT(varbinary(max),@EmptyObject)<>CONVERT(varbinary(max),N'{}')
 THROW 53690,N'JSON aggregate empty output mismatch.',2;
PRINT N'PASS: JSON aggregate finite grouped and empty outputs.';
GO

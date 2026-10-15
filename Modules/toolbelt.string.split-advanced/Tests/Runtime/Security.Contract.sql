SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=N'"'+REPLICATE(CONVERT(nvarchar(max),N'""'),32767)+N'"';
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_UnquoteToken(@Input,DEFAULT,DEFAULT,DEFAULT) WHERE IsValid=1 AND DATALENGTH(Value)=65534 AND Value=REPLICATE(CONVERT(nvarchar(max),N'"'),32767)) THROW 52990,N'Unquote dense exact input.',1;
SET @Input=N'"'+REPLICATE(CONVERT(nvarchar(max),N'a'),65534)+N'"';
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_UnquoteToken(@Input,DEFAULT,DEFAULT,DEFAULT) WHERE IsValid=1 AND DATALENGTH(Value)=131068) THROW 52990,N'Unquote literal span.',2;
GO

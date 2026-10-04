-- Technische Bridge: Stage0 vor echtem ISJSON, Stage1 danach; keine öffentliche API.
IF OBJECT_ID(N'toolbelt_json.FT_JsonEntryEvaluateInternal') IS NULL
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_json.FT_JsonEntryEvaluateInternal
(@ObjectMode bit,@Key nvarchar(max),@ValueKind nvarchar(max),@Value nvarchar(max),@Stage tinyint,@Policy tinyint)
RETURNS TABLE
(Fragment nvarchar(max) NULL,ErrorNumber int NULL,ErrorState int NULL,FaultPhase tinyint NULL,
 RawValueBytes bigint NULL,KeyBytes bigint NULL,StrongMinimumBytes bigint NULL,FragmentBytes bigint NULL)
AS EXTERNAL NAME [Toolbelt_JsonConstructors].[Toolbelt.JsonConstructors.JsonEntryEvaluateBridge].[Evaluate];';
GO

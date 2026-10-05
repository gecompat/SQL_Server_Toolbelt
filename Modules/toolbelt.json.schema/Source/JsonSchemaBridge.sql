-- Technischer SAFE-TVF-Slot; öffentliche NOT-NULL-Hülle liegt in der USP.
IF OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') IS NULL
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_json.FT_ValidateJsonSchemaInternal
(@Json nvarchar(max),@Schema nvarchar(max),@Profile nvarchar(32),@MaxDocumentBytes bigint,
 @MaxSchemaBytes bigint,@MaxDepth int,@MaxEvaluationSteps bigint,@MaxErrors int)
RETURNS TABLE
(RowKind nvarchar(8) NULL,ErrorOrdinal int NULL,Status nvarchar(24) NULL,Profile nvarchar(32) NULL,
 IsValid bit NULL,DocumentPointer nvarchar(max) NULL,SchemaPointer nvarchar(max) NULL,
 Keyword nvarchar(128) NULL,ErrorCode nvarchar(32) NULL,ErrorsTruncated bit NULL)
AS EXTERNAL NAME [Toolbelt_JsonSchema].[Toolbelt.JsonSchema.JsonSchemaBridge].[Validate];';
GO

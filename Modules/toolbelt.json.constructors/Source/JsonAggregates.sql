-- Einzeln freigegebene SAFE-Aggregate; Profile und Wireversion sind im bekannten Binary gebunden.
IF OBJECT_ID(N'toolbelt_json.AGF_JsonArray') IS NULL
 EXEC sys.sp_executesql N'CREATE AGGREGATE toolbelt_json.AGF_JsonArray
(@Ordinal int,@ValueKind nvarchar(max),@Value nvarchar(max),@Profile tinyint)
RETURNS nvarchar(max)
EXTERNAL NAME [Toolbelt_JsonConstructors].[Toolbelt.JsonConstructors.JsonArrayAggregate];';
GO
IF OBJECT_ID(N'toolbelt_json.AGF_JsonObject') IS NULL
 EXEC sys.sp_executesql N'CREATE AGGREGATE toolbelt_json.AGF_JsonObject
(@Ordinal int,@Key nvarchar(max),@ValueKind nvarchar(max),@Value nvarchar(max),@Profile tinyint)
RETURNS nvarchar(max)
EXTERNAL NAME [Toolbelt_JsonConstructors].[Toolbelt.JsonConstructors.JsonObjectAggregate];';
GO

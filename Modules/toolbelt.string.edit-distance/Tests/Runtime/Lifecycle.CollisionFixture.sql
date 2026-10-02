-- Nur synthetische eigene Fixture-DB; Snapshot vor/nach rejected Deploy vergleichen.
SET NOCOUNT ON;
DECLARE @Case nvarchar(32)=N'$(CollisionCase)';
IF @Case=N'unknown-version'
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.edit-distance.Version',@value=N'9.9.9';
ELSE IF @Case=N'padded-version'
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.edit-distance.Version',@value=N'1.0.0 ';
ELSE IF @Case=N'missing-marker'
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Managed',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_OsaDistance';
ELSE IF @Case=N'external-dependency'
 EXEC sys.sp_executesql N'CREATE VIEW dbo.ToolbeltDistanceFixtureConsumer AS SELECT * FROM toolbelt_string.TVF_OsaDistance(N''a'',N''b'',DEFAULT,DEFAULT);';
ELSE IF @Case=N'wrong-kind'
 BEGIN
 DROP FUNCTION toolbelt_string.TVF_OsaDistance;
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_string.TVF_OsaDistance() RETURNS int AS BEGIN RETURN 1; END;';
 END;
ELSE IF @Case=N'alias-parameter'
 BEGIN
 DROP FUNCTION toolbelt_string.TVF_OsaDistance;
 EXEC sys.sp_executesql N'CREATE TYPE dbo.ToolbeltDistanceFixtureAlias FROM nvarchar(max);';
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_string.TVF_OsaDistance(@LeftText dbo.ToolbeltDistanceFixtureAlias,@RightText nvarchar(max),@MaxDistance int=NULL,@Profile nvarchar(max)=N''standard'') RETURNS TABLE AS RETURN SELECT Distance,ExceedsMaxDistance,ErrorCode FROM toolbelt_string.TVF_OsaDistanceCore(@LeftText,@RightText,@MaxDistance,@Profile);';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_OsaDistance';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.string.edit-distance',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_OsaDistance';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_OsaDistance';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Visibility',@value=N'public',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_OsaDistance';
 END;
ELSE THROW 55093,N'Unbekannter synthetischer Kollisionstest.',1;
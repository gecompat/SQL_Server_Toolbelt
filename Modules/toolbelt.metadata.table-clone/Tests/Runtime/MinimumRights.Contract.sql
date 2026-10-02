SET NOCOUNT ON;
CREATE TABLE dbo.SyntheticRightsSource(Id int NOT NULL);
CREATE USER TbxCloneReader WITHOUT LOGIN;
GRANT EXECUTE ON toolbelt_metadata.USP_ScriptTableClone TO TbxCloneReader;
GRANT EXECUTE ON toolbelt_core.USP_PrepareResultTable TO TbxCloneReader;
GRANT VIEW DEFINITION ON dbo.SyntheticRightsSource TO TbxCloneReader;
GRANT VIEW DEFINITION ON SCHEMA::dbo TO TbxCloneReader;
GRANT VIEW DEFINITION TO TbxCloneReader;
CREATE TABLE #RightsPlan(Dummy int);
EXECUTE AS USER=N'TbxCloneReader';
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticRightsSource',N'dbo',N'SyntheticRightsTarget',@ResultTable=N'#RightsPlan';
REVERT;
IF (SELECT COUNT(*) FROM #RightsPlan)<>8 OR OBJECT_ID(N'dbo.SyntheticRightsTarget') IS NOT NULL THROW 54920,N'Minimum rights/script-only failed.',6;
REVOKE VIEW DEFINITION ON SCHEMA::dbo FROM TbxCloneReader;
REVOKE VIEW DEFINITION ON dbo.SyntheticRightsSource FROM TbxCloneReader;
REVOKE VIEW DEFINITION FROM TbxCloneReader;
EXECUTE AS USER=N'TbxCloneReader';
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticRightsSource',N'dbo',N'SyntheticRightsTarget'; THROW 54920,N'Invisible source accepted.',7; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53901 THROW; END CATCH;
REVERT;
-- Quellen-/Zielsicht allein darf verborgene incoming-FKs nicht als Abwesenheit behaupten.
GRANT VIEW DEFINITION ON dbo.SyntheticRightsSource TO TbxCloneReader;
GRANT VIEW DEFINITION ON SCHEMA::dbo TO TbxCloneReader;
ALTER TABLE dbo.SyntheticRightsSource ADD CONSTRAINT PK_SyntheticRightsSource PRIMARY KEY(Id);
EXEC(N'CREATE SCHEMA SyntheticHiddenRights');
CREATE TABLE SyntheticHiddenRights.Incoming(Id int REFERENCES dbo.SyntheticRightsSource(Id));
EXECUTE AS USER=N'TbxCloneReader';
IF OBJECT_ID(N'SyntheticHiddenRights.Incoming') IS NOT NULL THROW 54920,N'Hidden-FK fixture unexpectedly visible.',22;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticRightsSource',N'dbo',N'SyntheticRightsTarget',@ResultTable=N'#RightsPlan'; THROW 54920,N'Incomplete FK visibility accepted.',23; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53901 THROW; END CATCH;
REVERT;
IF (SELECT COUNT(*) FROM #RightsPlan)<>8 THROW 54920,N'Visibility rejection mutated output.',24;
GRANT VIEW DEFINITION TO TbxCloneReader;
EXECUTE AS USER=N'TbxCloneReader';
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticRightsSource',N'dbo',N'SyntheticRightsTarget'; THROW 54920,N'Visible incoming FK accepted.',25; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
REVERT;
DROP TABLE SyntheticHiddenRights.Incoming;
DROP SCHEMA SyntheticHiddenRights;
DROP USER TbxCloneReader;
DROP TABLE dbo.SyntheticRightsSource;

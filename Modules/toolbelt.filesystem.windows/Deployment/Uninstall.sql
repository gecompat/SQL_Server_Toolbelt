:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.filesystem.windows.Version') RETURN;
IF EXISTS (SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id IN (SELECT object_id FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_filesystem')) AND referencing_id NOT IN (SELECT object_id FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_filesystem')))
    THROW 51538, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;
BEGIN TRANSACTION;
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_ReadBinaryFileChunk];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_ReadTextFileChunk];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_WriteBinaryFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_WriteTextFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_TranscodeTextFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_ListDirectory];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_CreateDirectory];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_RemoveFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_RemoveDirectory];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_InternalRouteResult];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[USP_InternalEmitHelp];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_ReadBinaryFileChunk];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_ReadTextFileChunk];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_WriteBinaryFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_WriteTextFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_TranscodeTextFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_ListDirectory];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_CreateDirectory];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_RemoveFile];
DROP PROCEDURE IF EXISTS [toolbelt_filesystem].[CLR_RemoveDirectory];
DROP TABLE IF EXISTS [toolbelt_filesystem].[FileSystemRoot];
DROP ASSEMBLY IF EXISTS [Toolbelt_Filesystem_Windows];
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Module.toolbelt.filesystem.windows.Version';
COMMIT TRANSACTION;
GO

/* The instance-level trusted assembly registration remains an explicit administrative lifecycle step. */

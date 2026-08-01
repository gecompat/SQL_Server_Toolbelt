SET NOCOUNT ON;

DECLARE @Sql nvarchar(max) =
    N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)')
    + N'.sys.sp_executesql N''CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestCentralWorkType AS BEGIN SET NOCOUNT ON; END;'';';
EXEC sys.sp_executesql @Sql;

DECLARE @Rows TABLE
(
      WorkTypeId bigint, WorkTypeName varchar(128), HandlerSchema sysname
    , HandlerProcedure sysname, HandlerQualifiedName nvarchar(517)
    , ParameterMode varchar(16), PayloadContractJson nvarchar(4000) NULL
    , DefaultTimeoutSeconds int, IsIdempotent bit, IsEnabled bit
    , Description nvarchar(1000) NULL, CreatedAtUtc datetime2(7), CreatedBy sysname
    , ModifiedAtUtc datetime2(7), ModifiedBy sysname, DisabledAtUtc datetime2(7) NULL
    , DisabledBy sysname NULL, DisabledReason nvarchar(1000) NULL
    , RowVersion binary(8), HandlerExists bit
);

SET @Sql =
    N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)')
    + N'.toolbelt_core.USP_RegisterWorkType'
    + N' @WorkTypeName=''test.central'', @HandlerSchema=N''toolbelt_core'', @HandlerProcedure=N''USP_TestCentralWorkType'';';
INSERT INTO @Rows EXEC sys.sp_executesql @Sql;

IF NOT EXISTS (SELECT 1 FROM @Rows WHERE WorkTypeName='test.central' AND HandlerExists=1)
    THROW 52540, N'Central Register ist inkonsistent.', 1;

SET @Sql =
    N'DELETE FROM ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.WorkType WHERE WorkTypeName=''test.central'';'
    + N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)')
    + N'.sys.sp_executesql N''DROP PROCEDURE toolbelt_core.USP_TestCentralWorkType;'';';
EXEC sys.sp_executesql @Sql;

PRINT N'Work Type Central: erfolgreich';

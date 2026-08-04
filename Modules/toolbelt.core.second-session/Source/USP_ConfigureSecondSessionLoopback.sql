SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ConfigureSecondSessionLoopback]
(
      @LinkedServerName   sysname = NULL
    , @Enabled            bit = 1
    , @ExpectedRowVersion binary(8) = NULL
    , @ResultTable        sysname = NULL
    , @KeepData           bit = 0
    , @Debug              tinyint = 0
    , @Hilfe              bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    SET @Enabled = ISNULL(@Enabled, 1);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_ConfigureSecondSessionLoopback' AS sysname) AS ObjectName
            , v.Section
            , v.Ordinal
            , v.ItemName
            , v.SqlDataType
            , v.IsRequired
            , v.IsNullable
            , v.DefaultValue
            , v.Description
            , v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@LinkedServerName', 'sysname', 1, 0, NULL, N'Vorhandener Linked Server mit rpc out und deaktivierter Remote-Transaction-Promotion.', NULL)
            , ('PARAMETER', 2, N'@Enabled', 'bit', 0, 0, N'1', N'Aktiviert oder deaktiviert den Provider.', NULL)
            , ('PARAMETER', 3, N'@ExpectedRowVersion', 'binary(8)', 0, 1, NULL, N'Optionale Optimistic-Concurrency-Prüfung.', NULL)
            , ('PARAMETER', 4, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für die Konfigurationszeile.', NULL)
            , ('ERROR', 1, N'51600-51609', NULL, NULL, NULL, NULL, N'Konfigurations-, Probe-, Concurrency- und ResultTable-Fehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Konfiguriert den administrativ vorbereiteten Provider.', N'EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N''TBX_LOOPBACK'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF XACT_STATE() = -1
        THROW 51600, N'Die Providerkonfiguration ist in einer uncommittable Caller-Transaktion nicht zulässig.', 1;
    IF NULLIF(@LinkedServerName, N'') IS NULL OR QUOTENAME(@LinkedServerName) IS NULL
        THROW 51601, N'@LinkedServerName ist erforderlich und muss ein gültiger SQL-Identifier sein.', 1;

    DECLARE
          @LinkedServerExists bit = 0
        , @RpcOutEnabled bit = 0
        , @PromotionEnabled bit = 1;

    SELECT
          @LinkedServerExists = 1
        , @RpcOutEnabled = CONVERT(bit, s.is_rpc_out_enabled)
        , @PromotionEnabled = CONVERT(bit, s.is_remote_proc_transaction_promotion_enabled)
    FROM master.sys.servers AS s
    WHERE s.name = @LinkedServerName
      AND s.is_linked = 1;

    IF @LinkedServerExists = 0
        THROW 51602, N'Der angegebene Linked Server existiert nicht.', 1;
    IF @RpcOutEnabled = 0
        THROW 51603, N'Der Linked Server benötigt rpc out = true.', 1;
    IF @PromotionEnabled = 1
        THROW 51604, N'Der Linked Server benötigt remote proc transaction promotion = false.', 1;

    DECLARE @DatabaseName sysname = DB_NAME();
    DECLARE @ProbeSql nvarchar(max) =
        N'EXEC @ProbeReturnCode = '
        + QUOTENAME(@LinkedServerName) + N'.' + QUOTENAME(@DatabaseName)
        + N'.[toolbelt_core].[USP_SecondSessionProbe]'
        + N' @RemoteSessionId=@RemoteSessionId OUTPUT,'
        + N' @RemoteDatabaseName=@RemoteDatabaseName OUTPUT WITH RESULT SETS NONE;';
    DECLARE @ProbeReturnCode int;
    DECLARE @RemoteSessionId int;
    DECLARE @RemoteDatabaseName sysname;

    EXEC sys.sp_executesql
          @ProbeSql
        , N'@RemoteSessionId int OUTPUT, @RemoteDatabaseName sysname OUTPUT, @ProbeReturnCode int OUTPUT'
        , @RemoteSessionId = @RemoteSessionId OUTPUT
        , @RemoteDatabaseName = @RemoteDatabaseName OUTPUT
        , @ProbeReturnCode = @ProbeReturnCode OUTPUT;

    IF ISNULL(@ProbeReturnCode, -1) <> 0
        THROW 51605, N'Der Remote-Probe lieferte keinen erfolgreichen Returncode.', 1;
    IF @RemoteDatabaseName <> @DatabaseName
        THROW 51606, N'Der Loopback-Provider erreicht nicht dieselbe Toolbelt-Datenbank.', 1;
    IF @RemoteSessionId IS NULL OR @RemoteSessionId = @@SPID
        THROW 51607, N'Der Provider erzeugt keine getrennte SQL-Server-Session.', 1;

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_SecondSession_Config;

    BEGIN TRY
        DECLARE @CurrentRowVersion binary(8);
        SELECT @CurrentRowVersion = CONVERT(binary(8), p.RowVersion)
        FROM toolbelt_core.SecondSessionProvider AS p WITH (UPDLOCK, HOLDLOCK)
        WHERE p.ProviderName = 'loopback';

        IF @CurrentRowVersion IS NOT NULL
           AND @ExpectedRowVersion IS NOT NULL
           AND @ExpectedRowVersion <> @CurrentRowVersion
            THROW 51608, N'@ExpectedRowVersion stimmt nicht mit der aktuellen Providerkonfiguration überein.', 1;

        IF @CurrentRowVersion IS NULL
        BEGIN
            INSERT INTO toolbelt_core.SecondSessionProvider
            (
                  ProviderName, LinkedServerName, IsEnabled
                , CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy
            )
            VALUES
            (
                  'loopback', @LinkedServerName, @Enabled
                , SYSUTCDATETIME(), ORIGINAL_LOGIN(), SYSUTCDATETIME(), ORIGINAL_LOGIN()
            );
        END
        ELSE
        BEGIN
            UPDATE toolbelt_core.SecondSessionProvider
            SET
                  LinkedServerName = @LinkedServerName
                , IsEnabled = @Enabled
                , ModifiedAtUtc = SYSUTCDATETIME()
                , ModifiedBy = ORIGINAL_LOGIN()
            WHERE ProviderName = 'loopback'
              AND
              (
                  LinkedServerName <> @LinkedServerName
                  OR IsEnabled <> @Enabled
              );
        END;

        IF @InitialTranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_SecondSession_Config;
        THROW;
    END CATCH;

    CREATE TABLE #tbx_SecondSessionProviderShape
    (
          ProviderName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL
        , LinkedServerName sysname NOT NULL
        , IsEnabled bit NOT NULL
        , RowVersion binary(8) NOT NULL
        , LinkedServerExists bit NOT NULL
        , RpcOutEnabled bit NOT NULL
        , RemoteProcTransactionPromotionEnabled bit NOT NULL
        , ProbeRemoteSessionId int NOT NULL
        , ProbeDatabaseName sysname NOT NULL
    );

    IF @ResultTable IS NULL
    BEGIN
        SELECT
              p.ProviderName
            , p.LinkedServerName
            , p.IsEnabled
            , CONVERT(binary(8), p.RowVersion) AS RowVersion
            , @LinkedServerExists AS LinkedServerExists
            , @RpcOutEnabled AS RpcOutEnabled
            , @PromotionEnabled AS RemoteProcTransactionPromotionEnabled
            , @RemoteSessionId AS ProbeRemoteSessionId
            , @RemoteDatabaseName AS ProbeDatabaseName
        FROM toolbelt_core.SecondSessionProvider AS p
        WHERE p.ProviderName = 'loopback';
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51609, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_SecondSessionProviderShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (ProviderName, LinkedServerName, IsEnabled, RowVersion, LinkedServerExists, RpcOutEnabled, RemoteProcTransactionPromotionEnabled, ProbeRemoteSessionId, ProbeDatabaseName)'
        + N' SELECT ProviderName, LinkedServerName, IsEnabled, CONVERT(binary(8), RowVersion), @LinkedServerExists, @RpcOutEnabled, @PromotionEnabled, @RemoteSessionId, @RemoteDatabaseName'
        + N' FROM toolbelt_core.SecondSessionProvider WHERE ProviderName=''loopback'';';
    EXEC sys.sp_executesql
          @InsertSql
        , N'@LinkedServerExists bit, @RpcOutEnabled bit, @PromotionEnabled bit, @RemoteSessionId int, @RemoteDatabaseName sysname'
        , @LinkedServerExists = @LinkedServerExists
        , @RpcOutEnabled = @RpcOutEnabled
        , @PromotionEnabled = @PromotionEnabled
        , @RemoteSessionId = @RemoteSessionId
        , @RemoteDatabaseName = @RemoteDatabaseName;

    IF @Debug > 0
        RAISERROR(N'USP_ConfigureSecondSessionLoopback: Providerkonfiguration ist gültig.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO

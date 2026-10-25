-- Feste deaktivierte synthetische Konfiguration; kein RPC und keine Infrastrukturmutation.
DECLARE @ExpectedApiCount int=1;
IF EXISTS(SELECT 1 FROM toolbelt_core.SecondSessionProvider) THROW 52097,N'Provider fixture requires empty owned registry.',12;
IF EXISTS(SELECT 1 FROM master.sys.servers WHERE name=N'ContosoAbsentLoopback') THROW 52097,N'Provider synthetic server collision.',12;
INSERT toolbelt_core.SecondSessionProvider(ProviderName,LinkedServerName,IsEnabled,CreatedAtUtc,CreatedBy,ModifiedAtUtc,ModifiedBy)
VALUES('loopback',N'ContosoAbsentLoopback',0,'2026-01-01T00:00:00',N'Contoso','2026-01-02T00:00:00',N'Contoso');
INSERT @Apis VALUES
(1,N'toolbelt_core',N'VW_SecondSessionProviders','SELECT',N'SELECT * FROM toolbelt_core.VW_SecondSessionProviders;',N'DECLARE @Rows table(ProviderName varchar(32),LinkedServerName sysname,IsEnabled bit,CreatedAtUtc datetime2(7),CreatedBy sysname,ModifiedAtUtc datetime2(7),ModifiedBy sysname,RowVersion binary(8),LinkedServerExists bit,RpcOutEnabled bit,RemoteProcTransactionPromotionEnabled bit);
BEGIN TRY
 INSERT @Rows SELECT ProviderName,LinkedServerName,IsEnabled,CreatedAtUtc,CreatedBy,ModifiedAtUtc,ModifiedBy,RowVersion,LinkedServerExists,RpcOutEnabled,RemoteProcTransactionPromotionEnabled FROM toolbelt_core.VW_SecondSessionProviders;
END TRY
BEGIN CATCH
 DECLARE @AccessNumber int=ERROR_NUMBER(),@Diagnostic nvarchar(2048)=CONCAT(N''Provider dependency access error '',ERROR_NUMBER(),N''.'');
 THROW 52097,@Diagnostic,13;
END CATCH;
IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE ProviderName COLLATE Latin1_General_100_BIN2=''loopback'' AND LinkedServerName COLLATE Latin1_General_100_BIN2=N''ContosoAbsentLoopback'' AND IsEnabled=0 AND CreatedAtUtc=CONVERT(datetime2(7),''2026-01-01T00:00:00'') AND CreatedBy COLLATE Latin1_General_100_BIN2=N''Contoso'' AND ModifiedAtUtc=CONVERT(datetime2(7),''2026-01-02T00:00:00'') AND ModifiedBy COLLATE Latin1_General_100_BIN2=N''Contoso'' AND DATALENGTH(RowVersion)=8 AND LinkedServerExists=0 AND RpcOutEnabled=0 AND RemoteProcTransactionPromotionEnabled=1) THROW 52097,N''Provider fixed projection oracle.'',12;
');
INSERT @Denied VALUES
(1,N'toolbelt_core',N'SecondSessionProvider','SELECT',N'SELECT * FROM toolbelt_core.SecondSessionProvider;'),
(2,N'toolbelt_core',N'USP_ConfigureSecondSessionLoopback','EXECUTE',N'EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;'),
(3,N'toolbelt_core',N'USP_ExecuteWorkTypeInNewSession','EXECUTE',N'EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;'),
(4,N'toolbelt_core',N'USP_PrepareResultTable','EXECUTE',N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;');

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [toolbelt_core].[VW_SecondSessionProviders]
AS
SELECT
      p.[ProviderName]
    , p.[LinkedServerName]
    , p.[IsEnabled]
    , p.[CreatedAtUtc]
    , p.[CreatedBy]
    , p.[ModifiedAtUtc]
    , p.[ModifiedBy]
    , p.[RowVersion]
    , CONVERT(bit, CASE WHEN s.server_id IS NULL THEN 0 ELSE 1 END) AS [LinkedServerExists]
    , CONVERT(bit, ISNULL(s.is_rpc_out_enabled, 0)) AS [RpcOutEnabled]
    , CONVERT(bit, ISNULL(s.is_remote_proc_transaction_promotion_enabled, 1)) AS [RemoteProcTransactionPromotionEnabled]
FROM [toolbelt_core].[SecondSessionProvider] AS p
LEFT JOIN master.sys.servers AS s
  ON s.name = p.[LinkedServerName]
 AND s.is_linked = 1;
GO

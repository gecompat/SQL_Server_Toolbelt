SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ClaimWork]
(
      @LeaseDurationSeconds int = 300
    , @ResultTable sysname       = NULL
    , @KeepData    bit           = 0
    , @Debug       tinyint       = 0
    , @Hilfe       bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);

    IF @Hilfe=1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ClaimWork' AS sysname) ObjectName,
               v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@LeaseDurationSeconds','int',0,0,N'300',N'Lease-Dauer von 5 bis 86400 Sekunden.',NULL),
          ('PARAMETER',2,N'@ResultTable','sysname',0,1,NULL,N'Optionale lokale Temp-Tabelle für die Claim-Zeile.',NULL),
          ('PARAMETER',3,N'@KeepData','bit',0,0,N'0',N'Steuert die ResultTable-Vorbereitung.',NULL),
          ('PARAMETER',4,N'@Debug','tinyint',0,0,N'0',N'Erzeugt eine abstrakte Informationsmeldung.',NULL),
          ('PARAMETER',5,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich dieses Help-Resultset aus.',NULL),
          ('RESULT_COLUMN',1,N'WorkItemId','bigint',0,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('RESULT_COLUMN',2,N'WorkTypeName','varchar(128)',0,0,NULL,N'Kanonischer Work-Type-Name.',NULL),
          ('RESULT_COLUMN',3,N'PayloadJson','nvarchar(max)',0,1,NULL,N'Optionale bereinigte JSON-Payload.',NULL),
          ('RESULT_COLUMN',4,N'ClaimToken','uniqueidentifier',0,0,NULL,N'Geheimes Ownership-Token für Heartbeat, Complete oder Fail.',NULL),
          ('RESULT_COLUMN',5,N'ClaimedAtUtc','datetime2(7)',0,0,NULL,N'UTC-Zeitpunkt des Claims.',NULL),
          ('RESULT_COLUMN',6,N'ClaimGeneration','bigint',0,0,NULL,N'Monotoner Ownership-Zähler dieses Work Items.',NULL),
          ('RESULT_COLUMN',7,N'LeaseUntilUtc','datetime2(7)',0,0,NULL,N'Exklusive UTC-Grenze der Lease.',NULL),
          ('RESULT_COLUMN',8,N'LastHeartbeatAtUtc','datetime2(7)',0,0,NULL,N'Beim Claim identisch mit ClaimedAtUtc.',NULL),
          ('ERROR',1,N'51910-51918',NULL,NULL,NULL,NULL,N'Caller-Transaktions-, Lease- oder ResultTable-Fehler.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Beansprucht synthetische Arbeit für fünf Minuten.',N'EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END,v.Ordinal;
        RETURN 0;
    END;

    EXEC toolbelt_core.USP_ClaimWorkCore @LeaseDurationSeconds=@LeaseDurationSeconds,
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
END;
GO

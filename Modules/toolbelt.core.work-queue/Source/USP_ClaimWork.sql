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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_ClaimWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'PayloadJson', N'nvarchar(max)', 0, 1, NULL, CAST(N'Optionale bereinigte JSON-Payload.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ClaimToken', N'uniqueidentifier', 0, 0, NULL, CAST(N'Geheimes Ownership-Token für Heartbeat, Complete oder Fail.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'ClaimedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt des Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Monotoner Ownership-Zähler dieses Work Items.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'LeaseUntilUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Exklusive UTC-Grenze der Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Beim Claim identisch mit ClaimedAtUtc.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51910-51918', NULL, NULL, NULL, NULL, CAST(N'Caller-Transaktions-, Lease- oder ResultTable-Fehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beansprucht synthetische Arbeit für fünf Minuten.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@LeaseDurationSeconds', N'int', 0, 0, N'300', CAST(N'Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    EXEC toolbelt_core.USP_ClaimWorkCore @LeaseDurationSeconds=@LeaseDurationSeconds,
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
END;
GO

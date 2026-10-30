SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueBarrierWork]
      @WorkTypeName varchar(128)=NULL,@PayloadJson nvarchar(max)=NULL,@ExecutionGroup varchar(128)=NULL,@Priority tinyint=NULL,@IdempotencyKey varchar(128)=NULL,
      @MaxAttempts tinyint=3,@RetryBaseDelaySeconds int=60,@RetryMaxDelaySeconds int=3600,@ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 IF ISNULL(@Hilfe,0)=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_EnqueueBarrierWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Reiht eine DRAIN_BARRIER-Arbeit ein. @Priority muss fachlich angegeben werden; Barrier-Enqueue ist außerhalb einer Callertransaktion erforderlich.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51908,51975,51997-51998', NULL, NULL, NULL, NULL, CAST(N'Fehlende ResultTable-Dependency, fehlende Priority, Callertransaktion oder fehlende ENQUEUE-Autorisierung.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und explizite ENQUEUE-Autorisierung für den Work Type; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'DRAIN_BARRIER kann nicht innerhalb einer Callertransaktion eingereiht werden.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Barrier mit expliziter Gruppe und Priorität; der Work Type muss registriert und autorisiert sein.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_EnqueueBarrierWork @WorkTypeName=''registered-type'',@ExecutionGroup=''default'',@Priority=10;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WasCreated', N'bit', 1, 0, NULL, CAST(N'1 bei Neuanlage, 0 bei idempotenter Wiederverwendung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@PayloadJson', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N''{"value":1}''. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExecutionGroup', N'varchar(128)', 1, 1, N'NULL', CAST(N'Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Fachlich erforderlich; technischer Default NULL dient nur dem Hilfemodus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Priority', N'tinyint', 1, 0, N'NULL', CAST(N'Fachlich erforderliche Ganzzahl 0..255 als tinyint. Technischer Default NULL dient nur Hilfe; bei NULL im Fachaufruf Fehler 51975. Der Wrapper setzt den Modus fest auf DRAIN_BARRIER; Callertransaktionen sind ausgeschlossen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@IdempotencyKey', N'varchar(128)', 0, 1, N'NULL', CAST(N'Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxAttempts', N'tinyint', 0, 0, N'3', CAST(N'Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@RetryBaseDelaySeconds', N'int', 0, 0, N'60', CAST(N'Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss <= RetryMaxDelaySeconds sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@RetryMaxDelaySeconds', N'int', 0, 0, N'3600', CAST(N'Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 IF @Priority IS NULL THROW 51975,N'@Priority ist für eine Barrier erforderlich.',1;
 EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName,@PayloadJson,@IdempotencyKey,@Priority,@ExecutionGroup,@MaxAttempts,@RetryBaseDelaySeconds,@RetryMaxDelaySeconds,'DRAIN_BARRIER',@ResultTable,@KeepData,@Debug,@Hilfe;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[WorkType]
    (
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-core-worktype"
-- description: "Interner Katalog registrierter Work-Type-Handler und ihrer Konfiguration."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-type"
-- schema_name: "toolbelt_core"
-- object_name: "WorkType"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.work-type/Source/WorkType.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- public_entrypoints: ["toolbelt_core.VW_WorkTypes", "toolbelt_core.USP_RegisterWorkType", "toolbelt_core.USP_DisableWorkType", "toolbelt_core.USP_RemoveWorkType"]
-- ---
--
-- # WorkType
--
-- ## Zweck und Einsatzfälle
--
-- Persistenter interner Work-Type-Katalog. Für Lesen VW_WorkTypes und für Änderungen die öffentlichen Register-/Disable-/Remove-Prozeduren verwenden; kein direkter fachlicher Tabellen-Schreibpfad.
--
-- ## Voraussetzungen
--
-- Die Tabelle gehört zur Moduldatenbank. Verwaltungsaufrufe benötigen vorhandene passende Rechte und einen geeigneten registrierbaren Handler. Keine neue Tabelle aus diesem Skill anlegen.
--
-- ## Parameter und Zugriff
--
-- Keine Aufrufparameter. WorkTypeId bigint IDENTITY ist Schlüssel; WorkTypeName varchar(128) ist unter BIN2 eindeutig, klein geschrieben, 3..128 Zeichen, beginnt mit a-z und enthält nur a-z/0-9/._-, ohne führenden/abschließenden oder doppelten Punkt. HandlerSchema/HandlerProcedure sysname bezeichnen die Procedure. ParameterMode ist NONE oder JSON_PAYLOAD; bei NONE muss PayloadContractJson NULL, sonst ein gültiges JSON-Objekt in nvarchar(4000) sein. DefaultTimeoutSeconds int ist 1..86400 (Default 300), IsIdempotent/IsEnabled sind bit (Defaults 0/1). Description nvarchar(1000) und DisabledReason nvarchar(1000) sind optional. Created/Modified datetime2(7)/sysname werden mit UTC/ORIGINAL_LOGIN vorbelegt; DisabledAtUtc/DisabledBy/DisabledReason sind bei aktivem Eintrag NULL, beim Deaktivieren sind Zeitpunkt und Principal erforderlich. RowVersion ist ein enginegeneriertes rowversion-Token.
--
-- ## Ergebnisse
--
-- Die Tabelle speichert Konfiguration und Betriebsmetadaten, keine fachlichen Handlerergebnisse. Öffentliche Verwaltungsprozeduren definieren ihre eigenen Resultsets und Concurrencyverträge.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Vorgesehener Leseweg statt direkter Tabellenmutation:
-- SELECT WorkTypeName,ParameterMode,DefaultTimeoutSeconds,IsEnabled
-- FROM toolbelt_core.VW_WorkTypes
-- ORDER BY WorkTypeName;
-- ```
--
-- ## Rechte
--
-- Öffentliche Views/Verwaltungs-USPs mit vorhandenen SELECT-/EXECUTE-Rechten nutzen. Keine direkten Tabellenrechte durch diesen Skill oder den Installer erteilen; keine Umgehung der Handler-/Work-Type-Autorisierung.
--
-- ## Ressourcenbedarf
--
-- Persistente Katalogzeilen; Cluster-PK, eindeutiger WorkTypeName-Index und IsEnabled/WorkTypeName-Index. Schreiboperationen können Sperren und Log erzeugen; kein unbeschränktes Kapazitätsversprechen.
--
-- ## Nebenwirkungen
--
-- Die Tabelle selbst ist passiver Zustand. Direkte INSERT/UPDATE/DELETE können öffentliche Validierung, Autorisierung, Concurrency und abhängige Consumers umgehen und sind kein unterstützter Fachaufruf.
--
-- ## Fehlerbehandlung
--
-- Engine-Constraints sichern Teilinvarianten. Fachliche Fehler- und Transaktionsbehandlung über die öffentlichen Verwaltungs-USPs; nicht versuchen, einen Constraintfehler durch ungeprüfte Direktmutation zu umgehen.
--
-- ## Aussagegrenzen
--
-- Vorhandene Zeile beweist keinen erreichbaren, passenden oder autorisierten Handler. IsIdempotent ist deklarierte Konfiguration und keine mathematische Zusage. Reale Kataloginhalte werden nicht in Skills eingebettet.
-- OBJECT_USAGE_SKILL:END
          [WorkTypeId]             bigint IDENTITY(1,1) NOT NULL
        , [WorkTypeName]           varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [HandlerSchema]          sysname NOT NULL
        , [HandlerProcedure]       sysname NOT NULL
        , [ParameterMode]          varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_WorkType_ParameterMode] DEFAULT ('NONE')
        , [PayloadContractJson]    nvarchar(4000) NULL
        , [DefaultTimeoutSeconds]  int NOT NULL CONSTRAINT [DF_WorkType_DefaultTimeoutSeconds] DEFAULT (300)
        , [IsIdempotent]           bit NOT NULL CONSTRAINT [DF_WorkType_IsIdempotent] DEFAULT (0)
        , [IsEnabled]              bit NOT NULL CONSTRAINT [DF_WorkType_IsEnabled] DEFAULT (1)
        , [Description]            nvarchar(1000) NULL
        , [CreatedAtUtc]           datetime2(7) NOT NULL CONSTRAINT [DF_WorkType_CreatedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [CreatedBy]              sysname NOT NULL CONSTRAINT [DF_WorkType_CreatedBy] DEFAULT (ORIGINAL_LOGIN())
        , [ModifiedAtUtc]          datetime2(7) NOT NULL CONSTRAINT [DF_WorkType_ModifiedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [ModifiedBy]             sysname NOT NULL CONSTRAINT [DF_WorkType_ModifiedBy] DEFAULT (ORIGINAL_LOGIN())
        , [DisabledAtUtc]          datetime2(7) NULL
        , [DisabledBy]             sysname NULL
        , [DisabledReason]         nvarchar(1000) NULL
        , [RowVersion]             rowversion NOT NULL
        , CONSTRAINT [PK_WorkType]
            PRIMARY KEY CLUSTERED ([WorkTypeId])
        , CONSTRAINT [UQ_WorkType_WorkTypeName]
            UNIQUE NONCLUSTERED ([WorkTypeName])
        , CONSTRAINT [CK_WorkType_WorkTypeName]
            CHECK
            (
                LEN([WorkTypeName]) BETWEEN 3 AND 128
                AND [WorkTypeName] = LOWER([WorkTypeName]) COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] NOT LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] NOT LIKE '%.'
                AND [WorkTypeName] NOT LIKE '.%'
                AND [WorkTypeName] NOT LIKE '%..%'
            )
        , CONSTRAINT [CK_WorkType_ParameterMode]
            CHECK ([ParameterMode] IN ('NONE', 'JSON_PAYLOAD'))
        , CONSTRAINT [CK_WorkType_PayloadContract]
            CHECK
            (
                ([ParameterMode] = 'NONE' AND [PayloadContractJson] IS NULL)
                OR
                (
                    [ParameterMode] = 'JSON_PAYLOAD'
                    AND [PayloadContractJson] IS NOT NULL
                    AND ISJSON([PayloadContractJson]) = 1
                    AND LEFT(LTRIM([PayloadContractJson]), 1) = N'{'
                )
            )
        , CONSTRAINT [CK_WorkType_DefaultTimeoutSeconds]
            CHECK ([DefaultTimeoutSeconds] BETWEEN 1 AND 86400)
        , CONSTRAINT [CK_WorkType_DisabledMetadata]
            CHECK
            (
                ([IsEnabled] = 1 AND [DisabledAtUtc] IS NULL AND [DisabledBy] IS NULL AND [DisabledReason] IS NULL)
                OR
                ([IsEnabled] = 0 AND [DisabledAtUtc] IS NOT NULL AND [DisabledBy] IS NOT NULL)
            )
    );

    CREATE NONCLUSTERED INDEX [IX_WorkType_IsEnabled_WorkTypeName]
        ON [toolbelt_core].[WorkType] ([IsEnabled], [WorkTypeName])
        INCLUDE
        (
              [HandlerSchema]
            , [HandlerProcedure]
            , [ParameterMode]
            , [DefaultTimeoutSeconds]
            , [IsIdempotent]
        );
END;
GO

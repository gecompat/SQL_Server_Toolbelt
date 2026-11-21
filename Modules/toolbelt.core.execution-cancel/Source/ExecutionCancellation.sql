SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.ExecutionCancellation', N'U') IS NULL
BEGIN
CREATE TABLE [toolbelt_core].[ExecutionCancellation]
(
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-execution-cancellation-table"
-- description: "Interne persistente Cancellation-Anforderungen und ihre Audit-/Quotenidentitäten."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.execution-cancel"
-- schema_name: "toolbelt_core"
-- object_name: "ExecutionCancellation"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- public_entrypoints: ["toolbelt_core.USP_RequestExecutionCancellation", "toolbelt_core.TVF_ExecutionCancellationStatus", "toolbelt_core.SVF_IsCancellationRequested"]
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.execution-cancel/Source/ExecutionCancellation.sql", "Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # ExecutionCancellation
--
-- ## Zweck und Einsatzfälle
--
-- Interne persistente Cancellation-Anforderungen und ihre Audit-/Quotenidentitäten. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.
--
-- ## Parameter und Zugriff
--
-- Keine Aufrufparameter. Persistentes Tabellenschema: ExecutionId uniqueidentifier NOT NULL als Clustered-Primary-Key; RequestedAtUtc datetime2(7) NOT NULL mit DEFAULT SYSUTCDATETIME(); RequestedBy sysname NOT NULL; CancellationReason nvarchar(512) NULL; RowVersion rowversion NOT NULL; RequestedByPrincipalId int NULL, RequestedByPrincipalSid varbinary(85) NULL, RequestedByPrincipalCreatedAt datetime NULL. Zusätzlicher nicht eindeutiger Requesterindex auf den letzten drei Spalten. Bei neuen Anforderungen speichert RequestedBy ORIGINAL_LOGIN(), die drei Quotenfelder dagegen den tatsächlichen Datenbankprincipal USER_ID()/sid/create_date; das ist absichtlich nicht dieselbe Identitätsquelle. Historische nicht zuordenbare NULL-Quotenfelder bleiben zulässig und zählen zur Gesamtquote. Vorgesehener Schreibweg ausschließlich USP_RequestExecutionCancellation; Statuslesen über TVF_ExecutionCancellationStatus/SVF_IsCancellationRequested. Direkte DML würde Quoten, Identitätsbindung oder Irreversibilität umgehen und ist kein Anwendungsaufruf.
--
-- ## Ergebnisse
--
-- ExecutionId uniqueidentifier NOT NULL als Clustered-Primary-Key; RequestedAtUtc datetime2(7) NOT NULL mit DEFAULT SYSUTCDATETIME(); RequestedBy sysname NOT NULL; CancellationReason nvarchar(512) NULL; RowVersion rowversion NOT NULL; RequestedByPrincipalId int NULL, RequestedByPrincipalSid varbinary(85) NULL, RequestedByPrincipalCreatedAt datetime NULL. Zusätzlicher nicht eindeutiger Requesterindex auf den letzten drei Spalten. Bei neuen Anforderungen speichert RequestedBy ORIGINAL_LOGIN(), die drei Quotenfelder dagegen den tatsächlichen Datenbankprincipal USER_ID()/sid/create_date; das ist absichtlich nicht dieselbe Identitätsquelle. Historische nicht zuordenbare NULL-Quotenfelder bleiben zulässig und zählen zur Gesamtquote. Direkter Tabellenzugriff kann Auditidentitäten und Gründe sehen; die öffentlichen Statusfunktionen projizieren diese bewusst nicht. Tabellen haben keine garantierte Ausgabeordnung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT ExecutionId,IsCancellationRequested,RequestedAtUtc
-- FROM toolbelt_core.TVF_ExecutionCancellationStatus(CONVERT(uniqueidentifier,'00000000-0000-0000-0000-000000000001'));
-- -- Vorgesehener Leseweg ohne direkte Auditspalten.
-- ```
--
-- ## Rechte
--
-- Vorhandene DDL-Rechte für Installation separat. Keine Empfehlung von direktem INSERT/UPDATE/DELETE an Anwendungen; privilegierter Direktzugriff auf alle Tabellenfelder ist bewusst von Statusrechten zu trennen. Zentrale Nutzung erfordert gültige Datenbankauthentifizierung/Mapping und passende Rechte im Toolbelt-Ziel; ein Dreiteilname allein erteilt diese nicht. Keine Serverrollen oder Identitätsumschaltung durch diese Objekte.
--
-- ## Ressourcenbedarf
--
-- Persistenter unbefristeter Speicher für alle Anforderungen und Indexe; keine automatische Retention. Neue IDs: höchstens 100000 Tabellenzeilen insgesamt und 10000 je exaktem Tupel des tatsächlichen DBprincipals (ID/SID/create_date). Ein transaktionsgebundener exklusiver AppLock im public-Kontext serialisiert Quotenprüfung und Insert, Timeout 10000 ms; eine bereits vorhandene ExecutionId ist vor Quotenprüfung ein No-op. Kein automatisches Löschen abgelaufener Anforderungen. Direktes privilegiertes DML wird durch diese Anwendungsquoten nicht als Tabellenconstraint verhindert. Keine feste CPU-/Heap-/Durchsatz-/Latenzgarantie.
--
-- ## Nebenwirkungen
--
-- Das CREATE enthält bei fehlender Tabelle Basisdefinition und bei fehlendem Principal-ID-Feld die drei ergänzenden nullable Identitätsfelder sowie einen gegebenenfalls fehlenden Requesterindex. Das ist keine allgemeine Reparatur beliebiger Teilschemata; der aktuelle Installer bleibt create-only. Daten bleiben persistent, RowVersion wird enginegeführt verändert. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.
--
-- ## Fehlerbehandlung
--
-- Keine fachlichen Fehlercodes beim direkten Tabellenlesen; Enginefehler und Constraints gelten bei privilegiertem DML/DDL. Öffentliche Schreibfehler siehe Request-USP.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechteabnahme. Historische Fach-/Repeat-/Quotenbelege behalten ihre ursprüngliche Bindung. Keine Installations-/Rechteattestation, kein Echtzeit-/Unterbrechungsversprechen. Eine ExecutionId ist kein Authentifizierungsgeheimnis und diese APIs prüfen keine fachliche Eigentümerschaft einer ID. Kontextwerte sind keine Sicherheitsgrenze.
-- OBJECT_USAGE_SKILL:END
      [ExecutionId] uniqueidentifier NOT NULL
    , [RequestedAtUtc] datetime2(7) NOT NULL
        CONSTRAINT [DF_ExecutionCancellation_RequestedAtUtc] DEFAULT (SYSUTCDATETIME())
    , [RequestedBy] sysname NOT NULL
    , [CancellationReason] nvarchar(512) NULL
    , [RowVersion] rowversion NOT NULL
    , CONSTRAINT [PK_ExecutionCancellation] PRIMARY KEY CLUSTERED ([ExecutionId])
);
END;
GO

-- Legacyanforderungen behalten ihre bisherige Zuordnung. Neue Quoten binden
-- den tatsächlichen DBprincipal, niemals einen übergebenen Namen.
IF COL_LENGTH(N'toolbelt_core.ExecutionCancellation', N'RequestedByPrincipalId') IS NULL
BEGIN
    ALTER TABLE toolbelt_core.ExecutionCancellation ADD
        RequestedByPrincipalId int NULL,
        RequestedByPrincipalSid varbinary(85) NULL,
        RequestedByPrincipalCreatedAt datetime NULL;
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.ExecutionCancellation') AND name=N'IX_ExecutionCancellation_Requester')
    CREATE INDEX IX_ExecutionCancellation_Requester ON toolbelt_core.ExecutionCancellation
        (RequestedByPrincipalId,RequestedByPrincipalSid,RequestedByPrincipalCreatedAt);
GO

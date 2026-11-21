SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[SecondSessionProvider]
    (
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-second-session-secondsessionprovider"
-- description: "Interne persistente Auswahl eines administrativ vorbereiteten Loopback-Linked-Servers."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.second-session"
-- schema_name: "toolbelt_core"
-- object_name: "SecondSessionProvider"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.second-session/Source/SecondSessionProvider.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- public_entrypoints: ["toolbelt_core.USP_ConfigureSecondSessionLoopback", "toolbelt_core.VW_SecondSessionProviders", "toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
-- ---
--
-- # SecondSessionProvider
--
-- ## Zweck und Einsatzfälle
--
-- Interne persistente Auswahl eines administrativ vorbereiteten Loopback-Linked-Servers. Keine automatische Erstellung oder Reparatur eines Linked Servers, Loginmappings oder RPC-Providers.
--
-- ## Voraussetzungen
--
-- Installiertes Modul mit dieser Tabelle, SQL2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Die Sicht benötigt zusätzlich bestehende Sichtbarkeit in master.sys.servers. Die DDL selbst prüft keine funktionierende Remoteverbindung, Treiberverfügbarkeit oder Datenbank-/Serveridentität.
--
-- ## Parameter und Zugriff
--
-- Keine Aufrufparameter. Vorgesehener Schreibweg USP_ConfigureSecondSessionLoopback, vorgesehener Leseweg VW_SecondSessionProviders. Direkte privilegierte Tabellen-/View-DML ist kein Consumervertrag und könnte die Probe-/Prüfregeln der Fassade umgehen. Eine SQL-Sicht ist hier kein ausdrücklich erzwungenes DML-Verbot.
--
-- ## Ergebnisse
--
-- ProviderName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL, LinkedServerName sysname NOT NULL, IsEnabled bit NOT NULL DEFAULT 1, CreatedAtUtc datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME(), CreatedBy sysname NOT NULL DEFAULT ORIGINAL_LOGIN(), ModifiedAtUtc datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME(), ModifiedBy sysname NOT NULL DEFAULT ORIGINAL_LOGIN(), RowVersion rowversion NOT NULL (8 Byte). Clustered-PK ProviderName, eindeutiger nichtclustered Index LinkedServerName, CHECK ProviderName='loopback' nach BIN2-SQL-Textgleichheit einschließlich Padding. Kein eigener Trigger aktualisiert Modified-Defaults bei beliebiger direkter DML; das verantwortet die Verwaltungs-USP. Kein Default auf LinkedServerName und keine automatische Konfiguration. Keine Tabellen-/View-Ausgabeordnung. NULL-/Typmetadaten eines abgeleiteten Views sind nicht mit einer neuen fachlichen Validierung gleichzusetzen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT ProviderName,IsEnabled,LinkedServerExists,RpcOutEnabled,RemoteProcTransactionPromotionEnabled
-- FROM toolbelt_core.VW_SecondSessionProviders;
-- -- Keine Zeile: kein gespeicherter Provider.
-- -- Flags sind sichtbare Katalogzustände, kein Connectivity-/TLS-Test.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf der öffentlichen Sicht plus funktionierende bestehende Ownership-/Abhängigkeitsrechte und notwendige master.sys.servers-Metadatensichtbarkeit. Kein pauschaler Direkt-DML-Grant auf die interne Tabelle vorgeschlagen. Auditprincipals und Linked-Server-Namen sind reale Umgebungsmetadaten und privat zu behandeln. Zentrale Nutzung braucht gültiges Ziel-DB-Mapping/Rechte; keine automatische Rechteerteilung.
--
-- ## Ressourcenbedarf
--
-- Kleine Providerkatalogtabelle mit PK/Unique-Index und serverseitigem Metadatenjoin; keine eigene Heap-/CPU-/Latenz-/Zeilenquote. Der CHECK begrenzt bekannte Providernamen, aber ersetzt keine Probe oder physische Endpointbindung. Optimizer und vorhandene Rechte bestimmen die tatsächliche Katalogsicht; keine Parallelitäts-/Memory-Grant-Zusage.
--
-- ## Nebenwirkungen
--
-- CREATE bei fehlender Tabelle einschließlich Defaults/Constraints. Bestehende Zeilen werden von dieser DDL nicht automatisch migriert, verändert oder entfernt; aktueller Installer bleibt create-only. Gespeicherte Änderung von IsEnabled ist nur die lokale Providerfreigabe, keine Deaktivierung des Linked Servers. Kein Netzwerkzugriff durch das bloße Lesen dieser Objekte.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen Geschäftsfehlercodes/-resultsets. Engine-/Berechtigungs-/Constraintfehler bleiben sichtbar. Fehlende sichtbare Linked-Server-Zeile wird in der View durch sichere negative Flags dargestellt, nicht als erfolgreiche Transportprüfung. Datenbankgleicher Name, SPID- oder Katalogflags sind keine authentifizierte Serveridentität.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag dieser Objekte, keine neue native Hilfe-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Katalogeintrag/IsEnabled bedeutet weder erreichbare noch richtig authentifizierte Verbindung. Die View attestiert weder Installation aller Abhängigkeiten noch ausreichende Aufruferrechte.
-- OBJECT_USAGE_SKILL:END
          [ProviderName]     varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [LinkedServerName] sysname NOT NULL
        , [IsEnabled]        bit NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_IsEnabled] DEFAULT (1)
        , [CreatedAtUtc]     datetime2(7) NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_CreatedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [CreatedBy]        sysname NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_CreatedBy] DEFAULT (ORIGINAL_LOGIN())
        , [ModifiedAtUtc]    datetime2(7) NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_ModifiedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [ModifiedBy]       sysname NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_ModifiedBy] DEFAULT (ORIGINAL_LOGIN())
        , [RowVersion]       rowversion NOT NULL
        , CONSTRAINT [PK_SecondSessionProvider]
            PRIMARY KEY CLUSTERED ([ProviderName])
        , CONSTRAINT [UQ_SecondSessionProvider_LinkedServerName]
            UNIQUE NONCLUSTERED ([LinkedServerName])
        , CONSTRAINT [CK_SecondSessionProvider_ProviderName]
            CHECK ([ProviderName] = 'loopback')
    );
END;
GO

-- ============================================================================
-- Objekt:          toolbelt_file.FileContentRootAllowlist
-- Typ:             Konfigurationstabelle
-- Zweck:           Enthält die für das File-Content-Modul erlaubten Root-Pfade.
-- Vertrag:         Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md
-- Dependencies:    Keine.
-- Rechte:          Lesen durch öffentliche Procedures; Schreiben durch
--                  berechtigte Administratoren oder Deployment.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux.
-- Hinweise:        - Nur absolute Pfade sind zulässig.
--                  - UNC-Pfade sind erlaubt.
--                  - Relative Pfade und Traversal werden von den Procedures
--                    abgelehnt. Die Root-Prüfung ist lexikalisch und löst keine
--                    Dateisystemlinks auf; diese Tabelle prüft das ebenfalls nicht.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_file].[FileContentRootAllowlist]
    (
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-file-content-root-allowlist"
-- description: "Öffentliche administrativ gepflegte Rootkonfiguration für lesenden File-Content-Zugriff."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.file.content"
-- schema_name: "toolbelt_file"
-- object_name: "FileContentRootAllowlist"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: []
-- source_paths: ["Modules/toolbelt.file.content/Source/FileContentRootAllowlist.sql", "Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # FileContentRootAllowlist
--
-- ## Zweck und Einsatzfälle
--
-- Administrativ gesteuerte erlaubte Leseorte für USP_LoadBinaryFile/USP_LoadTextFile. Keine Datei-/Netzwerkoperation durch die Tabelle selbst. Direkte Verwaltung ist ein bewusster Konfigurationsvorgang; keine automatische Rootanlage.
--
-- ## Voraussetzungen
--
-- SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie. Die Tabelle selbst erzwingt diese Procedureregeln nicht durch zusätzliche CHECK-Constraints.
--
-- ## Parameter und Zugriff
--
-- Keine Aufrufparameter. RootPathId int IDENTITY(1,1) NOT NULL als clustered PK; RootPath nvarchar(4000) NOT NULL mit UNIQUE-Constraint nach Datenbankcollation; Description nvarchar(4000) NULL; IsActive bit NOT NULL DEFAULT1; CreatedAt datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(). Keine eigene CHECK-Constraint auf absoluten/normalisierten/erreichbaren Rootpfad, keine Rootformat-/OS-Prüfung beim INSERT. Die Deklaration nvarchar(4000) garantiert nicht, dass jeder so lange Wert in den eindeutigen Index eingefügt werden kann; SQL-Indexkeygrenzen gelten.
--
-- ## Ergebnisse
--
-- Persistente Konfigurationszeilen mit obigem Schema, keine Ausgabeordnung. IsActive=1 wird ausgewertet, 0 ignoriert. Mehrere Roottexte können nach Slashnormalisierung denselben Ort bezeichnen; der UNIQUE-Constraint prüft den gespeicherten Text unter DBcollation, nicht den normalisierten physischen Dateisystemort. Tabellenzeile bestätigt weder vorhandenen Root noch fehlende Links, Dateirechte oder erfolgreiche Leseoperation.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Nur im autorisierten Konfigurationsscope, mit tatsächlichen Rechten prüfen.
-- SELECT RootPathId,RootPath,Description,IsActive,CreatedAt
-- FROM toolbelt_file.FileContentRootAllowlist ORDER BY RootPathId;
-- -- Lesen verändert keine Rootfreigabe.
-- ```
--
-- ## Rechte
--
-- Bestehende bewusste administrative SELECT/INSERT/UPDATE/DELETE-Rechte nach Verwaltungsscope; Tabelle ist eine öffentliche Konfigurationsschnittstelle, kein automatischer Grant an Datei-Consumer. Vorhandenes EXECUTE auf der öffentlichen USP und gültige Abhängigkeitsrechte auf die Allowlist. Zusätzlich für die konkrete SQL-Server-Version/Plattform ausreichende Bulkberechtigung (ADMINISTER BULK OPERATIONS bzw. ADMINISTER DATABASE BULK OPERATIONS, soweit unterstützt) und Lesezugriff des tatsächlich wirksamen Dateisystem-Sicherheitskontexts. Bei SQL-Authentifizierung ist regelmäßig der SQL-Server-Prozesskontext relevant, bei Windows-Anmeldung der passende delegierte Kontext. Linux-/Patchbesonderheiten separat beachten; kein versionsunabhängiger Minimalrechte-PASS behauptet. Eine Ad-hoc-Konfigurationsoption ersetzt keine Rechte. Die Procedure erteilt nichts und aktiviert keine Serveroption. [Microsoft-Bulkvertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/openrowset-bulk-transact-sql?view=sql-server-ver17), [Dateizugriffskontext](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/prepare-data-for-bulk-export-or-import-sql-server). Routing zusätzlich vorhandene Helper-/Temp-Rechte; keine neue Privilegienvergabe im Aufruf.
--
-- ## Ressourcenbedarf
--
-- Persistente Roottexte und eindeutiger Rootindex, keine globale Zeilen-/Bytequote oder automatische Bereinigung. Normalisierte Präfixverkettung castet vor /-Append nach nvarchar(max), damit 4000 deklarierte Codeunits nicht still gekürzt werden. Eine lange DDL-Spalte ist keine Zusage einfügbarer Index-/Providerpfadlänge.
--
-- ## Nebenwirkungen
--
-- CREATE bei fehlender Tabelle einschließlich Identity/Defaults/Constraints, keine Befüllung/Umstellung vorhandener Roots. Bestehende administrativ erlaubte DML verändert die Lesepolicy; keine automatische Retention oder Rootkanonisierung. Lesekonsumenten sollen keine pauschalen Schreibrechte auf diese Konfiguration erhalten.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen Geschäftsfehlercodes. Engine-/Index-/Unique-/Berechtigungsfehler bei DDL/DML bleiben erhalten. Ein formal gespeicherter Root garantiert kein zulässiges Dateilesen. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Datei-I/O-/Minimalrechte-/Skill-/Installerabnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Dateiinhalt, Pfade und Providerfehlermeldungen können vertrauliche Umgebungsdaten enthalten; nicht veröffentlichen. Keine Installation-/Rechteattestation, keine unbegrenzte Kapazität oder Garantie eines stabilen Dateisystems.
-- OBJECT_USAGE_SKILL:END
          RootPathId    int              NOT NULL IDENTITY(1,1)
        , RootPath      nvarchar(4000)   NOT NULL
        , Description   nvarchar(4000)   NULL
        , IsActive      bit              NOT NULL CONSTRAINT DF_FileContentRootAllowlist_IsActive
                                           DEFAULT (1)
        , CreatedAt     datetime2(0)     NOT NULL CONSTRAINT DF_FileContentRootAllowlist_CreatedAt
                                           DEFAULT (SYSUTCDATETIME())
        , CONSTRAINT PK_FileContentRootAllowlist PRIMARY KEY CLUSTERED (RootPathId)
        , CONSTRAINT UQ_FileContentRootAllowlist_RootPath UNIQUE (RootPath)
    );
END;
GO

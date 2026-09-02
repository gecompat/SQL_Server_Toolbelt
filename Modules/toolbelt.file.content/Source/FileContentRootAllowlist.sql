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
--                  - Relative Segmente, Symlinks und Traversal werden von den
--                    Procedures abgelehnt, nicht von dieser Tabelle.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_file].[FileContentRootAllowlist]
    (
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

IF EXISTS
(
    SELECT 1
    FROM sys.extended_properties AS ep
    INNER JOIN sys.tables AS tables
        ON tables.object_id = ep.major_id
    INNER JOIN sys.schemas AS schemas
        ON schemas.schema_id = tables.schema_id
    WHERE ep.class = 1
      AND ep.minor_id = 0
      AND ep.name = N'MS_Description'
      AND schemas.name = N'toolbelt_file'
      AND tables.name = N'FileContentRootAllowlist'
)
    EXEC sys.sp_updateextendedproperty
          @name = N'MS_Description'
        , @value = N'Allowlist der Root-Pfade für toolbelt.file.content. Pfade müssen absolut sein; UNC-Pfade sind erlaubt.'
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_file'
        , @level1type = N'TABLE',  @level1name = N'FileContentRootAllowlist';
ELSE
    EXEC sys.sp_addextendedproperty
          @name = N'MS_Description'
        , @value = N'Allowlist der Root-Pfade für toolbelt.file.content. Pfade müssen absolut sein; UNC-Pfade sind erlaubt.'
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_file'
        , @level1type = N'TABLE',  @level1name = N'FileContentRootAllowlist';
GO

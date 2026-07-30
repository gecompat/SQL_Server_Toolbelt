-- ============================================================================
-- Objekt:          toolbelt_metadata.VW_ModuleCapabilities
-- Typ:             View
-- Zweck:           Projiziert installierte Toolbelt-Module und den Zustand
--                  ihrer Database-level Extended-Property-Marker.
-- Vertrag:         Documentation/Architecture/CAPABILITY_CATALOG_MODULE_DESIGN.md
-- Parameter:       Keine.
-- Resultset:       ModuleId, ModuleVersion, DeploymentMode, MetadataStatus.
-- Dependencies:    sys.extended_properties der aktuellen Datenbank.
-- Rechte:          SELECT auf der View; Metadata Visibility gilt unverändert.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux.
-- Fehlerverhalten: Read-only; Konvertierungsfehler werden als invalid sichtbar.
-- Performance:     Ein Scan der Database-level Extended Properties.
-- Einschränkungen: Keine Objektinventur, keine module.yaml-Projektion und keine
--                  persistente Registry. Nur stabile Release-Versionen.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [toolbelt_metadata].[VW_ModuleCapabilities]
AS
WITH MarkerRows AS
(
    SELECT
          ModuleId = CONVERT
          (
              sysname,
              SUBSTRING
              (
                    ep.name
                  , LEN(N'Toolbelt.Module.') + 1
                  , LEN(ep.name)
                    - LEN(N'Toolbelt.Module.')
                    - CASE marker.MarkerKind
                          WHEN N'Version' THEN LEN(N'.Version')
                          ELSE LEN(N'.DeploymentMode')
                      END
              )
          )
        , marker.MarkerKind
        , MarkerValue = TRY_CONVERT(nvarchar(4000), ep.value)
        , MarkerBaseType =
              TRY_CONVERT(sysname, SQL_VARIANT_PROPERTY(ep.value, 'BaseType'))
        , MarkerNameIsCanonical = CONVERT
          (
              bit,
              CASE
                  WHEN LEFT(ep.name, LEN(N'Toolbelt.Module.'))
                           COLLATE Latin1_General_100_BIN2
                           = N'Toolbelt.Module.'
                   AND
                   (
                       (marker.MarkerKind = N'Version'
                        AND RIGHT(ep.name, LEN(N'.Version'))
                                COLLATE Latin1_General_100_BIN2 = N'.Version')
                       OR
                       (marker.MarkerKind = N'DeploymentMode'
                        AND RIGHT(ep.name, LEN(N'.DeploymentMode'))
                                COLLATE Latin1_General_100_BIN2
                                = N'.DeploymentMode')
                   )
                  THEN 1
                  ELSE 0
              END
          )
    FROM sys.extended_properties AS ep
    CROSS APPLY
    (
        VALUES
        (
            CASE
                WHEN RIGHT(ep.name, LEN(N'.Version'))
                         COLLATE Latin1_General_100_CI_AS = N'.Version'
                THEN N'Version'
                WHEN RIGHT(ep.name, LEN(N'.DeploymentMode'))
                         COLLATE Latin1_General_100_CI_AS
                         = N'.DeploymentMode'
                THEN N'DeploymentMode'
            END
        )
    ) AS marker (MarkerKind)
    WHERE ep.class = 0
      AND ep.major_id = 0
      AND ep.minor_id = 0
      AND LEFT(ep.name, LEN(N'Toolbelt.Module.'))
              COLLATE Latin1_General_100_CI_AS = N'Toolbelt.Module.'
      AND marker.MarkerKind IS NOT NULL
),
AggregatedMarkers AS
(
    SELECT
          marker_rows.ModuleId
        , ModuleVersion = MAX
          (
              CASE marker_rows.MarkerKind
                  WHEN N'Version' THEN marker_rows.MarkerValue
              END
          )
        , DeploymentMode = MAX
          (
              CASE marker_rows.MarkerKind
                  WHEN N'DeploymentMode' THEN marker_rows.MarkerValue
              END
          )
        , VersionMarkerCount = SUM
          (
              CASE marker_rows.MarkerKind WHEN N'Version' THEN 1 ELSE 0 END
          )
        , ModeMarkerCount = SUM
          (
              CASE marker_rows.MarkerKind
                  WHEN N'DeploymentMode' THEN 1
                  ELSE 0
              END
          )
        , MarkerNamesAreCanonical =
              MIN(CONVERT(tinyint, marker_rows.MarkerNameIsCanonical))
        , VersionTypeIsText = MIN
          (
              CASE
                  WHEN marker_rows.MarkerKind <> N'Version' THEN 1
                  WHEN marker_rows.MarkerBaseType IN
                       (N'char', N'nchar', N'varchar', N'nvarchar') THEN 1
                  ELSE 0
              END
          )
        , ModeTypeIsText = MIN
          (
              CASE
                  WHEN marker_rows.MarkerKind <> N'DeploymentMode' THEN 1
                  WHEN marker_rows.MarkerBaseType IN
                       (N'char', N'nchar', N'varchar', N'nvarchar') THEN 1
                  ELSE 0
              END
          )
    FROM MarkerRows AS marker_rows
    GROUP BY marker_rows.ModuleId
),
ParsedVersions AS
(
    SELECT
          aggregated.ModuleId
        , aggregated.ModuleVersion
        , aggregated.DeploymentMode
        , aggregated.VersionMarkerCount
        , aggregated.ModeMarkerCount
        , aggregated.MarkerNamesAreCanonical
        , aggregated.VersionTypeIsText
        , aggregated.ModeTypeIsText
        , VersionMajor = PARSENAME(aggregated.ModuleVersion, 3)
        , VersionMinor = PARSENAME(aggregated.ModuleVersion, 2)
        , VersionPatch = PARSENAME(aggregated.ModuleVersion, 1)
        , VersionDotCount =
              LEN(aggregated.ModuleVersion)
              - LEN(REPLACE(aggregated.ModuleVersion, N'.', N''))
    FROM AggregatedMarkers AS aggregated
)
SELECT
      parsed.ModuleId
    , parsed.ModuleVersion
    , parsed.DeploymentMode
    , MetadataStatus = CONVERT
      (
          varchar(16),
          CASE
              WHEN parsed.VersionMarkerCount > 1
                OR parsed.ModeMarkerCount > 1
                OR parsed.MarkerNamesAreCanonical <> 1
                OR parsed.VersionTypeIsText <> 1
                OR parsed.ModeTypeIsText <> 1
                OR parsed.ModuleId IS NULL
                OR parsed.ModuleId COLLATE Latin1_General_100_BIN2
                       NOT LIKE N'toolbelt.%'
                OR parsed.ModuleId COLLATE Latin1_General_100_BIN2
                       LIKE N'%[^a-z0-9.-]%'
                OR parsed.ModuleId LIKE N'%..%'
                OR RIGHT(parsed.ModuleId, 1) IN (N'.', N'-')
                OR
                   (
                       parsed.VersionMarkerCount = 1
                       AND
                       (
                           parsed.ModuleVersion IS NULL
                           OR DATALENGTH(parsed.ModuleVersion) = 0
                           OR DATALENGTH(parsed.ModuleVersion) > 128
                           OR parsed.VersionDotCount <> 2
                           OR parsed.VersionMajor IS NULL
                           OR parsed.VersionMinor IS NULL
                           OR parsed.VersionPatch IS NULL
                           OR parsed.VersionMajor
                                  COLLATE Latin1_General_100_BIN2
                                  LIKE N'%[^0-9]%'
                           OR parsed.VersionMinor
                                  COLLATE Latin1_General_100_BIN2
                                  LIKE N'%[^0-9]%'
                           OR parsed.VersionPatch
                                  COLLATE Latin1_General_100_BIN2
                                  LIKE N'%[^0-9]%'
                           OR (LEN(parsed.VersionMajor) > 1
                               AND LEFT(parsed.VersionMajor, 1) = N'0')
                           OR (LEN(parsed.VersionMinor) > 1
                               AND LEFT(parsed.VersionMinor, 1) = N'0')
                           OR (LEN(parsed.VersionPatch) > 1
                               AND LEFT(parsed.VersionPatch, 1) = N'0')
                       )
                   )
                OR
                   (
                       parsed.ModeMarkerCount = 1
                       AND
                       (
                           parsed.DeploymentMode IS NULL
                           OR parsed.DeploymentMode
                                  COLLATE Latin1_General_100_BIN2
                                  NOT IN (N'local', N'central')
                       )
                   )
              THEN 'invalid'
              WHEN parsed.VersionMarkerCount = 0
                OR parsed.ModeMarkerCount = 0
              THEN 'incomplete'
              ELSE 'valid'
          END
      )
FROM ParsedVersions AS parsed;
GO

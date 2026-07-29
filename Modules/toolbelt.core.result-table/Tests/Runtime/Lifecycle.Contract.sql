-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- Daten: keine fachlichen oder realen Runtime-Daten
-- Status im Repository: not executed
-- ============================================================================

SET NOCOUNT ON;

DECLARE
      @SchemaId        int = SCHEMA_ID(N'toolbelt_core')
    , @ProcedureId     int = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P')
    , @Managed         int
    , @SchemaCategory  nvarchar(128)
    , @ModuleId        nvarchar(256)
    , @ModuleVersion   nvarchar(64)
    , @ContractVersion nvarchar(64)
    , @DeploymentMode  nvarchar(16)
    , @SourceHash      varchar(64)
    , @ActualHash      varchar(64)
    , @InstalledVersion nvarchar(64)
    , @RegisteredMode   nvarchar(16);

IF @SchemaId IS NULL OR @ProcedureId IS NULL
BEGIN
    THROW 52100, N'Schema oder Procedure der Modulinstallation fehlt.', 1;
END;

SELECT
      @Managed = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.Managed'
                  THEN TRY_CONVERT(int, ep.value)
          END
      )
    , @SchemaCategory = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.SchemaCategory'
                  THEN TRY_CONVERT(nvarchar(128), ep.value)
          END
      )
FROM sys.extended_properties AS ep
WHERE ep.class = 3
  AND ep.major_id = @SchemaId
  AND ep.minor_id = 0;

SELECT
      @ModuleId = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.ModuleId'
                  THEN TRY_CONVERT(nvarchar(256), ep.value)
          END
      )
    , @ModuleVersion = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.ModuleVersion'
                  THEN TRY_CONVERT(nvarchar(64), ep.value)
          END
      )
    , @ContractVersion = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.ContractVersion'
                  THEN TRY_CONVERT(nvarchar(64), ep.value)
          END
      )
    , @DeploymentMode = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.DeploymentMode'
                  THEN TRY_CONVERT(nvarchar(16), ep.value)
          END
      )
    , @SourceHash = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.SourceHash'
                  THEN TRY_CONVERT(varchar(64), ep.value)
          END
      )
FROM sys.extended_properties AS ep
WHERE ep.class = 1
  AND ep.major_id = @ProcedureId
  AND ep.minor_id = 0;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = N'Toolbelt.Module.toolbelt.core.result-table.Version';

SELECT @RegisteredMode = TRY_CONVERT(nvarchar(16), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode';

SET @ActualHash = CONVERT
(
      varchar(64)
    , HASHBYTES
      (
          N'SHA2_256'
        , CONVERT(varbinary(max), OBJECT_DEFINITION(@ProcedureId))
      )
    , 2
);

IF
   (
       NOT
       (
           @Managed IS NULL
           AND @SchemaCategory IS NULL
       )
       AND NOT
       (
           ISNULL(@Managed, 0) = 1
           AND ISNULL(@SchemaCategory, N'') COLLATE Latin1_General_100_BIN2 = N'core'
       )
   )
   OR ISNULL(@ModuleId, N'') COLLATE Latin1_General_100_BIN2
          <> N'toolbelt.core.result-table'
   OR ISNULL(@ModuleVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
   OR ISNULL(@ContractVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0'
   OR ISNULL(@DeploymentMode, N'') NOT IN (N'local', N'central')
   OR ISNULL(@InstalledVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
   OR ISNULL(@RegisteredMode, N'') COLLATE Latin1_General_100_BIN2
          <> ISNULL(@DeploymentMode, N'') COLLATE Latin1_General_100_BIN2
   OR @SourceHash IS NULL
   OR @ActualHash IS NULL
   OR @SourceHash COLLATE Latin1_General_100_BIN2
          <> @ActualHash COLLATE Latin1_General_100_BIN2
BEGIN
    THROW 52101, N'Release-, Objekt-, Deployment- oder diagnostische Source-Hash-Marker sind inkonsistent.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.objects AS o
       WHERE o.object_id = @ProcedureId
         AND o.schema_id = @SchemaId
         AND o.type IN ('P', 'PC')
         AND o.is_ms_shipped = 0
   )
BEGIN
    THROW 52102, N'Das vereinbarte persistente Release-Objekt fehlt.', 1;
END;

PRINT N'ResultTable Lifecycle-Contract-Prüfung: erfolgreich';
GO

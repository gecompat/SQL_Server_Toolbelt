:On Error exit
-- Q1 V1: wiederholbares Deploy und Uninstall eines isolierten,
-- dependency-freien T-SQL-Moduls ohne persistente Zustandsobjekte.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
    THROW 52940, N'Der Verifier darf nicht in einer Systemdatenbank laufen.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.objects AS objects
       JOIN sys.schemas AS schemas
         ON schemas.schema_id = objects.schema_id
       WHERE schemas.name COLLATE Latin1_General_100_BIN2
                 LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
         AND objects.is_ms_shipped = 0
   )
   OR EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND major_id = 0
            AND minor_id = 0
            AND name COLLATE Latin1_General_100_BIN2
                  LIKE N'Toolbelt.Module.%' COLLATE Latin1_General_100_BIN2
      )
    THROW 52940, N'Der Q1-V1-Verifier benötigt eine isolierte leere Testdatenbank.', 1;

CREATE TABLE #tbx_MigrationSnapshot
(
      SnapshotOrdinal tinyint NOT NULL
    , ItemKind         nvarchar(32) COLLATE DATABASE_DEFAULT NOT NULL
    , ItemKey          nvarchar(400) COLLATE DATABASE_DEFAULT NOT NULL
    , ItemValue        nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL
    , CONSTRAINT PK_tbx_MigrationSnapshot
          PRIMARY KEY (SnapshotOrdinal, ItemKind, ItemKey)
);

PRINT N'Q1_STAGE_INITIALIZED';
GO

:r $(DeployScriptPath)
PRINT N'Q1_STAGE_FIRST_DEPLOYED';

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name COLLATE Latin1_General_100_BIN2
               = N'Toolbelt.Module.$(ModuleId).Version'
                 COLLATE Latin1_General_100_BIN2
         AND TRY_CONVERT(nvarchar(64), value) = N'$(ExpectedVersion)'
   )
    THROW 52942, N'Das erste Deployment registrierte nicht die erwartete Modulversion.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.objects AS objects
       JOIN sys.schemas AS schemas
         ON schemas.schema_id = objects.schema_id
       WHERE schemas.name COLLATE Latin1_General_100_BIN2
                 LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
         AND objects.is_ms_shipped = 0
         AND objects.type NOT IN ('FN', 'IF', 'TF', 'P', 'V')
   )
    THROW 52943, N'Q1 V1 unterstützt nur zustandslose T-SQL-Funktionen, Procedures und Views.', 1;
GO

:setvar SnapshotOrdinal "1"
:r $(CaptureSnapshotPath)
PRINT N'Q1_STAGE_FIRST_CAPTURED';

:r $(DeployScriptPath)
PRINT N'Q1_STAGE_SECOND_DEPLOYED';

:setvar SnapshotOrdinal "2"
:r $(CaptureSnapshotPath)
PRINT N'Q1_STAGE_SECOND_CAPTURED';

IF EXISTS
   (
       SELECT 1
       FROM #tbx_MigrationSnapshot AS first_snapshot
       FULL OUTER JOIN #tbx_MigrationSnapshot AS second_snapshot
         ON second_snapshot.SnapshotOrdinal = 2
        AND first_snapshot.ItemKind = second_snapshot.ItemKind
        AND first_snapshot.ItemKey = second_snapshot.ItemKey
       WHERE first_snapshot.SnapshotOrdinal = 1
         AND
         (
             second_snapshot.ItemKey IS NULL
             OR first_snapshot.ItemValue COLLATE Latin1_General_100_BIN2
                <> second_snapshot.ItemValue COLLATE Latin1_General_100_BIN2
         )
   )
   OR EXISTS
      (
          SELECT 1
          FROM #tbx_MigrationSnapshot AS second_snapshot
          LEFT JOIN #tbx_MigrationSnapshot AS first_snapshot
            ON first_snapshot.SnapshotOrdinal = 1
           AND first_snapshot.ItemKind = second_snapshot.ItemKind
           AND first_snapshot.ItemKey = second_snapshot.ItemKey
          WHERE second_snapshot.SnapshotOrdinal = 2
            AND first_snapshot.ItemKey IS NULL
      )
    THROW 52944, N'Wiederholungsdeployment erzeugte Katalogdrift.', 1;
GO

PRINT N'Migration-Idempotency-Deployvergleich: erfolgreich';
GO

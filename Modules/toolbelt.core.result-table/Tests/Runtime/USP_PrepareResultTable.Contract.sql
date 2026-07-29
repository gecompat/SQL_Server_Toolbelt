-- ============================================================================
-- Runtime-Contract-Tests für toolbelt_core.USP_PrepareResultTable
-- Daten: ausschließlich synthetisch
-- Status im Repository: not executed
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT OFF;

IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
BEGIN
    THROW 52000, N'Testvoraussetzung fehlt: USP_PrepareResultTable ist nicht installiert.', 1;
END;

DECLARE @ReturnCode int;

-- RT-H-001 bis RT-H-008: Help ignoriert alle fachlichen Parameter.
CREATE TABLE #ResultTableHelp
(
      HelpContractVersion varchar(16)    NOT NULL
    , SchemaName          sysname        NOT NULL
    , ObjectName          sysname        NOT NULL
    , Section             varchar(32)    NOT NULL
    , Ordinal             int            NOT NULL
    , ItemName            sysname        NULL
    , SqlDataType         varchar(256)   NULL
    , IsRequired          bit            NULL
    , IsNullable          bit            NULL
    , DefaultValue        nvarchar(4000) NULL
    , Description         nvarchar(max)  NOT NULL
    , ExampleSql          nvarchar(max)  NULL
);

INSERT INTO #ResultTableHelp
EXEC @ReturnCode = toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'not-a-temp-table'
    , @LikeTable          = N'not-a-reference'
    , @KeepData           = 1
    , @Debug              = 255
    , @Hilfe              = 1;

IF @ReturnCode <> 0
BEGIN
    THROW 52001, N'Help-Aufruf lieferte keinen RETURN 0.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM #ResultTableHelp
       WHERE Section = 'DESCRIPTION'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM #ResultTableHelp
       WHERE Section = 'PARAMETER'
         AND ItemName = N'@ResultTableToAlter'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM #ResultTableHelp
       WHERE Section = 'RESULT_COLUMN'
         AND ItemName IS NULL
         AND SqlDataType IS NULL
         AND IsNullable IS NULL
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM #ResultTableHelp
       WHERE Section = 'EXAMPLE'
         AND ExampleSql IS NOT NULL
   )
BEGIN
    THROW 52002, N'Das Help-Resultset enthält nicht alle Pflichtbestandteile.', 1;
END;

DROP TABLE #ResultTableHelp;

-- RT-N-001: NULL-Zielname.
BEGIN TRY
    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = NULL
        , @LikeTable          = N'#MissingShape';
    THROW 52003, N'Erwarteter Fehler 51020 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51020
    BEGIN
        THROW;
    END;
END CATCH;

-- RT-N-007: zulässiger, aber nicht sichtbarer Zielname.
BEGIN TRY
    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = N'#MissingTarget'
        , @LikeTable          = N'#MissingShape';
    THROW 52004, N'Erwarteter Fehler 51021 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51021
    BEGIN
        THROW;
    END;
END CATCH;

-- RT-K-003/009 und RT-T-001/005/006/018: leeres Dummy-Schema ersetzen.
CREATE TABLE #ResultTableTarget
(
    ArbitraryDummyColumn uniqueidentifier NULL
);

CREATE TABLE #tbx_ResultTableContract_ResultShape
(
      ItemOrdinal bigint        NOT NULL
    , ItemCode    varchar(20)   COLLATE Latin1_General_100_BIN2 NOT NULL
    , ItemText    nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL
    , Amount      decimal(19,4) NULL
    , CreatedAt   datetime2(3)  NOT NULL
);

DECLARE @TargetObjectIdBefore int =
    OBJECT_ID(N'tempdb..[#ResultTableTarget]', N'U');

EXEC @ReturnCode = toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableTarget'
    , @LikeTable          = N'#tbx_ResultTableContract_ResultShape'
    , @KeepData           = 0;

IF @ReturnCode <> 0
BEGIN
    THROW 52005, N'Schemaanpassung lieferte keinen RETURN 0.', 1;
END;

IF OBJECT_ID(N'tempdb..[#ResultTableTarget]', N'U') <> @TargetObjectIdBefore
BEGIN
    THROW 52006, N'Die Zieltable wurde gedroppt und neu erstellt.', 1;
END;

DECLARE @ExpectedSchema TABLE
(
      ColumnOrdinal  int      NOT NULL
    , ColumnName     sysname  NOT NULL
    , TypeName       sysname  NOT NULL
    , MaxLength      smallint NOT NULL
    , PrecisionValue tinyint  NOT NULL
    , ScaleValue     tinyint  NOT NULL
    , IsNullable     bit      NOT NULL
);

INSERT INTO @ExpectedSchema
(
      ColumnOrdinal
    , ColumnName
    , TypeName
    , MaxLength
    , PrecisionValue
    , ScaleValue
    , IsNullable
)
VALUES
      (1, N'ItemOrdinal', N'bigint', 8, 19, 0, 0)
    , (2, N'ItemCode', N'varchar', 20, 0, 0, 0)
    , (3, N'ItemText', N'nvarchar', 200, 0, 0, 1)
    , (4, N'Amount', N'decimal', 9, 19, 4, 1)
    , (5, N'CreatedAt', N'datetime2', 7, 27, 3, 0);

DECLARE @SchemaDifferenceCount int;

;WITH ActualSchema AS
(
    SELECT
          ROW_NUMBER() OVER (ORDER BY c.column_id) AS ColumnOrdinal
        , c.name AS ColumnName
        , st.name AS TypeName
        , c.max_length AS MaxLength
        , c.precision AS PrecisionValue
        , c.scale AS ScaleValue
        , c.is_nullable AS IsNullable
    FROM tempdb.sys.columns AS c
    INNER JOIN tempdb.sys.types AS st
        ON st.user_type_id = c.user_type_id
    WHERE c.object_id = @TargetObjectIdBefore
)
SELECT @SchemaDifferenceCount = COUNT(*)
FROM ActualSchema AS a
FULL OUTER JOIN @ExpectedSchema AS e
    ON e.ColumnOrdinal = a.ColumnOrdinal
WHERE a.ColumnOrdinal IS NULL
   OR e.ColumnOrdinal IS NULL
   OR a.ColumnName COLLATE Latin1_General_100_BIN2
          <> e.ColumnName COLLATE Latin1_General_100_BIN2
   OR a.TypeName COLLATE Latin1_General_100_BIN2
          <> e.TypeName COLLATE Latin1_General_100_BIN2
   OR a.MaxLength <> e.MaxLength
   OR a.PrecisionValue <> e.PrecisionValue
   OR a.ScaleValue <> e.ScaleValue
   OR a.IsNullable <> e.IsNullable;

IF @SchemaDifferenceCount <> 0
BEGIN
    THROW 52007, N'Das erzeugte Zielschema entspricht nicht dem Referenzschema.', 1;
END;

INSERT INTO #ResultTableTarget
(
      ItemOrdinal
    , ItemCode
    , ItemText
    , Amount
    , CreatedAt
)
VALUES
(
      1
    , 'SYNTHETIC'
    , N'Synthetic value'
    , 12.3400
    , CONVERT(datetime2(3), '2026-01-01T00:00:00.000')
);

-- RT-K-006: passendes Schema und KeepData=1 erhält Daten.
EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableTarget'
    , @LikeTable          = N'#tbx_ResultTableContract_ResultShape'
    , @KeepData           = 1;

IF (SELECT COUNT(*) FROM #ResultTableTarget) <> 1
BEGIN
    THROW 52008, N'@KeepData = 1 hat Daten bei passendem Schema nicht erhalten.', 1;
END;

-- RT-K-005: passendes Schema und KeepData=0 leert Daten.
EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableTarget'
    , @LikeTable          = N'#tbx_ResultTableContract_ResultShape'
    , @KeepData           = 0;

IF EXISTS (SELECT 1 FROM #ResultTableTarget)
BEGIN
    THROW 52009, N'@KeepData = 0 hat Daten bei passendem Schema nicht entfernt.', 1;
END;

-- RT-K-008: vorhandene Daten plus Schemaabweichung und KeepData=1 ist atomar.
INSERT INTO #ResultTableTarget
(
      ItemOrdinal
    , ItemCode
    , ItemText
    , Amount
    , CreatedAt
)
VALUES
(
      2
    , 'UNCHANGED'
    , N'Must remain'
    , NULL
    , CONVERT(datetime2(3), '2026-01-02T00:00:00.000')
);

CREATE TABLE #tbx_ResultTableContract_ChangedShape
(
    ChangedValue int NOT NULL
);

BEGIN TRY
    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = N'#ResultTableTarget'
        , @LikeTable          = N'#tbx_ResultTableContract_ChangedShape'
        , @KeepData           = 1;
    THROW 52010, N'Erwarteter Fehler 51025 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51025
    BEGIN
        THROW;
    END;
END CATCH;

IF (SELECT COUNT(*) FROM #ResultTableTarget) <> 1
   OR NOT EXISTS
      (
          SELECT 1
          FROM tempdb.sys.columns AS c
          WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableTarget]', N'U')
            AND c.name COLLATE Latin1_General_100_BIN2 = N'ItemOrdinal'
      )
BEGIN
    THROW 52011, N'Fehler 51025 hat Daten oder Schema verändert.', 1;
END;

-- RT-D-003: Index blockiert den notwendigen Schemaumbau vor jeder Mutation.
CREATE INDEX IX_ResultTableContract_ItemCode
    ON #ResultTableTarget (ItemCode);

BEGIN TRY
    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = N'#ResultTableTarget'
        , @LikeTable          = N'#tbx_ResultTableContract_ChangedShape'
        , @KeepData           = 0;
    THROW 52012, N'Erwarteter Fehler 51026 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51026
    BEGIN
        THROW;
    END;
END CATCH;

IF (SELECT COUNT(*) FROM #ResultTableTarget) <> 1
BEGIN
    THROW 52013, N'Der Dependency-Preflight erfolgte nicht vor der Datenmutation.', 1;
END;

DROP INDEX IX_ResultTableContract_ItemCode ON #ResultTableTarget;

-- RT-X-003: erfolgreiche Mutation nutzt in Caller-Transaktion nur Savepoint.
BEGIN TRANSACTION;

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableTarget'
    , @LikeTable          = N'#tbx_ResultTableContract_ChangedShape'
    , @KeepData           = 0;

IF @@TRANCOUNT <> 1
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52014, N'Die Procedure hat die Caller-Transaktion committed oder erweitert.', 1;
END;

ROLLBACK TRANSACTION;

-- RT-N-008/RT-L-014: delimitierbare Sonderzeichen bleiben ein Identifier.
CREATE TABLE [#Result.With]]Bracket]
(
    Dummy int NULL
);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#Result.With]Bracket'
    , @LikeTable          = N'#tbx_ResultTableContract_ChangedShape'
    , @KeepData           = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#Result.With]]Bracket]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'ChangedValue'
   )
BEGIN
    THROW 52015, N'Delimitierbarer Zielname wurde nicht sicher verarbeitet.', 1;
END;

-- RT-T-013: Identity in der Referenz wird vor Mutation abgelehnt.
CREATE TABLE #tbx_ResultTableContract_UnsupportedShape
(
    UnsupportedIdentity int IDENTITY(1,1) NOT NULL
);

BEGIN TRY
    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = N'#ResultTableTarget'
        , @LikeTable          = N'#tbx_ResultTableContract_UnsupportedShape'
        , @KeepData           = 0;
    THROW 52016, N'Erwarteter Fehler 51024 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51024
    BEGIN
        THROW;
    END;
END CATCH;

DROP TABLE #tbx_ResultTableContract_UnsupportedShape;
DROP TABLE [#Result.With]]Bracket];
DROP TABLE #tbx_ResultTableContract_ChangedShape;
DROP TABLE #tbx_ResultTableContract_ResultShape;
DROP TABLE #ResultTableTarget;

PRINT N'USP_PrepareResultTable Runtime-Contract-Tests: erfolgreich';
GO

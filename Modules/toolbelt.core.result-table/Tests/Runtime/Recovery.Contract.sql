-- ============================================================================
-- Recovery-Vertrag für USP_PrepareResultTable
-- Daten und Objekte: ausschließlich synthetisch
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
--
-- Der temporäre DDL-Trigger injiziert nach bereits erfolgter Mutation einen
-- echten Konvertierungsfehler 245. Er gehört ausschließlich zum Test-Harness
-- und wird im Erfolgs- wie im Fehlerpfad wieder entfernt.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;

EXEC tempdb.sys.sp_executesql
    N'DROP TRIGGER IF EXISTS [tbx_ResultTable_InjectConversionFailure]
      ON DATABASE;';

BEGIN TRY
    EXEC tempdb.sys.sp_executesql
        N'CREATE TRIGGER [tbx_ResultTable_InjectConversionFailure]
          ON DATABASE
          FOR ALTER_TABLE
          AS
          BEGIN
              SET NOCOUNT ON;

              IF TRY_CONVERT
                 (
                     bit,
                     SESSION_CONTEXT
                     (
                         N''tbx.ResultTable.InjectConversionFailure''
                     )
                 ) = 1
              BEGIN
                  DECLARE @CommandText nvarchar(max) =
                      EVENTDATA().value
                      (
                          N''(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]'',
                          N''nvarchar(max)''
                      );

                  IF @CommandText LIKE N''%ReplacementValue%''
                  BEGIN
                      SET XACT_ABORT OFF;

                      DECLARE
                            @InvalidValue nvarchar(40) =
                                N''tbx-not-an-integer''
                          , @ConversionTarget int;

                      SET @ConversionTarget =
                          CONVERT(int, @InvalidValue);
                  END;
              END;
          END;';

    CREATE TABLE #ResultTableRecovery
    (
        OriginalValue int NULL
    );

    CREATE TABLE #tbx_ResultTableRecovery_Shape
    (
        ReplacementValue bigint NOT NULL
    );

    CREATE TABLE #CallerRecoveryMarker
    (
        MarkerValue int NOT NULL
    );

    DECLARE
          @TargetObjectId     int =
              OBJECT_ID(N'tempdb..[#ResultTableRecovery]', N'U')
        , @ObservedError      int
        , @ObservedXactState  smallint
        , @ObservedTranCount  int;

    BEGIN TRANSACTION;

    INSERT INTO #CallerRecoveryMarker (MarkerValue)
    VALUES (29);

    EXEC sys.sp_set_session_context
          @key   = N'tbx.ResultTable.InjectConversionFailure'
        , @value = 1;

    BEGIN TRY
        EXEC toolbelt_core.USP_PrepareResultTable
              @ResultTableToAlter = N'#ResultTableRecovery'
            , @LikeTable          = N'#tbx_ResultTableRecovery_Shape'
            , @KeepData           = 0;
    END TRY
    BEGIN CATCH
        SET @ObservedError = ERROR_NUMBER();
    END CATCH;

    EXEC sys.sp_set_session_context
          @key   = N'tbx.ResultTable.InjectConversionFailure'
        , @value = NULL;

    SELECT
          @ObservedXactState = XACT_STATE()
        , @ObservedTranCount = @@TRANCOUNT;

    IF @ObservedError <> 245
    BEGIN
        THROW 52320, N'Der injizierte Engine-Fehler 245 wurde nicht unverändert weitergegeben.', 1;
    END;

    IF @ObservedXactState <> 1 OR @ObservedTranCount <> 1
    BEGIN
        THROW 52321, N'Die Caller-Transaktion ist nach dem DDL-Fehler nicht mehr committable und offen.', 1;
    END;

    IF NOT EXISTS
       (
           SELECT 1
           FROM #CallerRecoveryMarker
           WHERE MarkerValue = 29
       )
    BEGIN
        THROW 52322, N'Der Savepoint-Rollback hat frühere Caller-Änderungen entfernt.', 1;
    END;

    IF OBJECT_ID(N'tempdb..[#ResultTableRecovery]', N'U') <> @TargetObjectId
    BEGIN
        THROW 52323, N'Der Savepoint-Rollback hat die Objektidentität verändert.', 1;
    END;

    IF
    (
        SELECT COUNT(*)
        FROM tempdb.sys.columns AS c
        WHERE c.object_id = @TargetObjectId
    ) <> 1
    BEGIN
        THROW 52324, N'Der Savepoint-Rollback hat nicht exakt eine Ausgangsspalte wiederhergestellt.', 1;
    END;

    IF EXISTS
       (
           SELECT 1
           FROM tempdb.sys.columns AS c
           WHERE c.object_id = @TargetObjectId
             AND c.name COLLATE Latin1_General_100_BIN2 LIKE N'#tbx[_]%'
       )
    BEGIN
        THROW 52325, N'Der Savepoint-Rollback hat die interne Anchor-Spalte zurückgelassen.', 1;
    END;

    IF EXISTS
       (
           SELECT 1
           FROM tempdb.sys.columns AS c
           WHERE c.object_id = @TargetObjectId
             AND c.name COLLATE Latin1_General_100_BIN2 =
                 N'ReplacementValue'
       )
    BEGIN
        THROW 52326, N'Der Savepoint-Rollback hat die geplante Replacement-Spalte zurückgelassen.', 1;
    END;

    IF NOT EXISTS
       (
           SELECT 1
           FROM tempdb.sys.columns AS c
           WHERE c.object_id = @TargetObjectId
             AND c.name COLLATE Latin1_General_100_BIN2 = N'OriginalValue'
       )
    BEGIN
        THROW 52327, N'Der Savepoint-Rollback hat einen unbekannten Spaltenzustand hinterlassen.', 1;
    END;

    IF NOT EXISTS
       (
           SELECT 1
           FROM tempdb.sys.columns AS c
           WHERE c.object_id = @TargetObjectId
             AND c.name COLLATE Latin1_General_100_BIN2 = N'OriginalValue'
             AND c.system_type_id = 56
             AND c.max_length = 4
             AND c.precision = 10
             AND c.scale = 0
             AND c.is_nullable = 1
       )
    BEGIN
        THROW 52328, N'Der Savepoint-Rollback hat den Typ der Ausgangsspalte nicht wiederhergestellt.', 1;
    END;

    IF EXISTS
       (
           SELECT 1
           FROM tempdb.sys.columns AS c
           WHERE c.object_id = @TargetObjectId
             AND
             (
                    c.name COLLATE Latin1_General_100_BIN2 =
                        N'ReplacementValue'
                 OR c.name COLLATE Latin1_General_100_BIN2 LIKE N'#tbx[_]%'
             )
       )
    BEGIN
        THROW 52329, N'Der Savepoint-Rollback hat eine nicht klassifizierte Mutationsspalte zurückgelassen.', 1;
    END;

    ROLLBACK TRANSACTION;

    DROP TABLE #CallerRecoveryMarker;
    DROP TABLE #tbx_ResultTableRecovery_Shape;
    DROP TABLE #ResultTableRecovery;

    EXEC tempdb.sys.sp_executesql
        N'DROP TRIGGER IF EXISTS [tbx_ResultTable_InjectConversionFailure]
          ON DATABASE;';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    EXEC sys.sp_set_session_context
          @key   = N'tbx.ResultTable.InjectConversionFailure'
        , @value = NULL;

    EXEC tempdb.sys.sp_executesql
        N'DROP TRIGGER IF EXISTS [tbx_ResultTable_InjectConversionFailure]
          ON DATABASE;';

    THROW;
END CATCH;

PRINT N'USP_PrepareResultTable Recovery-Vertrag: erfolgreich';
GO

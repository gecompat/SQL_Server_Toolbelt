-- ============================================================================
-- Synthetisches Beispiel für toolbelt_core.USP_PrepareResultTable
-- Voraussetzung: Modul toolbelt.core.result-table ist lokal oder zentral
--                installiert. Bei zentraler Installation ist der dreiteilige
--                Procedure-Name einzusetzen.
-- ============================================================================

CREATE TABLE #ExampleResult
(
    DummyColumn int NULL
);

/*
 * Die routinenspezifische Helper-Tabelle beschreibt ausschließlich das
 * Resultsetschema. Eine spätere fachliche USP würde dieselbe explizite
 * Spaltenliste für ihren Insert verwenden.
 */
CREATE TABLE #tbx_Example_ResultShape
(
      ItemOrdinal bigint        NOT NULL
    , ItemValue   varchar(100)  COLLATE Latin1_General_100_BIN2 NULL
    , CreatedAt   datetime2(3)  NOT NULL
);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ExampleResult'
    , @LikeTable          = N'#tbx_Example_ResultShape'
    , @KeepData           = 0
    , @Debug              = 1;

INSERT INTO #ExampleResult
(
      ItemOrdinal
    , ItemValue
    , CreatedAt
)
VALUES
(
      1
    , 'Synthetic value'
    , CONVERT(datetime2(3), '2026-01-01T00:00:00.000')
);

SELECT
      ItemOrdinal
    , ItemValue
    , CreatedAt
FROM #ExampleResult;

DROP TABLE #tbx_Example_ResultShape;
DROP TABLE #ExampleResult;
GO

-- ============================================================================
-- Objekt:          toolbelt_core.TVF_GenerateSeriesBigInt
-- Zweck:           Portable bigint-Zahlenreihe einschließlich Startwert
-- Parameter:       @Start bigint, @Stop bigint, @Step bigint = NULL
-- Resultset:       Value bigint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; konstante Rowsets und zeilenzahlgesteuerter TOP
-- Collation:       nicht anwendbar
-- Einschränkungen: keine garantierte Reihenfolge; Row Count muss bigint-fähig sein
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigInt]
(
      @Start bigint
    , @Stop  bigint
    , @Step  bigint = NULL
)
RETURNS TABLE
AS
RETURN
(
    /*
     * Die binäre Stapelung stellt 2^64 logische Quellzeilen bereit. TOP
     * begrenzt die tatsächlich angeforderte Menge durch einen Row Goal; die
     * Zwischenmenge wird nicht materialisiert. decimal(38,0) verhindert
     * Überläufe bei Differenz, Betrag und Wertberechnung an bigint-Grenzen.
     */
    WITH
    ResolvedParameters AS
    (
        SELECT
              StartValue = @Start
            , StopValue  = @Stop
            , StepValue  = COALESCE
              (
                  @Step
                , CASE WHEN @Start <= @Stop
                       THEN CONVERT(bigint, 1)
                       ELSE CONVERT(bigint, -1)
                  END
              )
    ),
    CountedParameters AS
    (
        SELECT
              parameters.StartValue
            , parameters.StepValue
            , RequestedRows = CASE
                  /*
                   * Eine Schrittweite 0 bleibt ein unveränderter Enginefehler.
                   * Die Division wird nur für diesen ungültigen Fall gewählt.
                   */
                  WHEN parameters.StepValue = 0
                      THEN CONVERT(bigint, 1 / parameters.StepValue)
                  WHEN parameters.StartValue IS NULL
                    OR parameters.StopValue IS NULL
                      THEN CONVERT(bigint, 0)
                  WHEN parameters.StepValue > 0
                   AND parameters.StartValue <= parameters.StopValue
                      THEN CONVERT
                           (
                               bigint
                             , (
                                   CONVERT(decimal(38, 0), parameters.StopValue)
                                   - CONVERT(decimal(38, 0), parameters.StartValue)
                               )
                               / CONVERT(decimal(38, 0), parameters.StepValue)
                               + 1
                           )
                  WHEN parameters.StepValue < 0
                   AND parameters.StartValue >= parameters.StopValue
                      THEN CONVERT
                           (
                               bigint
                             , (
                                   CONVERT(decimal(38, 0), parameters.StartValue)
                                   - CONVERT(decimal(38, 0), parameters.StopValue)
                               )
                               / -CONVERT(decimal(38, 0), parameters.StepValue)
                               + 1
                           )
                  ELSE CONVERT(bigint, 0)
              END
        FROM ResolvedParameters AS parameters
    ),
    E1(N) AS
    (
        SELECT source.N
        FROM (VALUES (0), (0)) AS source(N)
    ),
    E2(N) AS
    (
        SELECT 0 FROM E1 AS a CROSS JOIN E1 AS b
    ),
    E4(N) AS
    (
        SELECT 0 FROM E2 AS a CROSS JOIN E2 AS b
    ),
    E8(N) AS
    (
        SELECT 0 FROM E4 AS a CROSS JOIN E4 AS b
    ),
    E16(N) AS
    (
        SELECT 0 FROM E8 AS a CROSS JOIN E8 AS b
    ),
    E32(N) AS
    (
        SELECT 0 FROM E16 AS a CROSS JOIN E16 AS b
    ),
    E64(N) AS
    (
        SELECT 0 FROM E32 AS a CROSS JOIN E32 AS b
    ),
    Ordinals AS
    (
        SELECT TOP
        (
            COALESCE
            (
                (SELECT counted.RequestedRows FROM CountedParameters AS counted)
              , CONVERT(bigint, 0)
            )
        )
            Ordinal = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1
        FROM E64
    )
    SELECT
        Value = CONVERT
        (
            bigint
          , CONVERT(decimal(38, 0), parameters.StartValue)
            + CONVERT(decimal(38, 0), ordinals.Ordinal)
              * CONVERT(decimal(38, 0), parameters.StepValue)
        )
    FROM CountedParameters AS parameters
    CROSS JOIN Ordinals AS ordinals
);
GO

-- Begrenzte Oberfläche für untrusted Aufrufe. Die mathematische Altfassade
-- bleibt unter der ausdrücklichen Betreiberpolicy für vertrauenswürdige Principals.
CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigIntStatus]
(@Start bigint,@Stop bigint,@Step bigint=NULL)
RETURNS @Result TABLE(Value bigint NULL,Status varchar(16) NOT NULL,RequestedRows decimal(38,0) NULL)
AS
BEGIN
    IF @Start IS NULL OR @Stop IS NULL
    BEGIN INSERT @Result VALUES(NULL,'SQL_NULL',NULL); RETURN; END;
    SET @Step=COALESCE(@Step,CASE WHEN @Start<=@Stop THEN CONVERT(bigint,1) ELSE CONVERT(bigint,-1) END);
    IF @Step=0 BEGIN INSERT @Result VALUES(NULL,'INVALID',NULL); RETURN; END;
    IF (@Step>0 AND @Start>@Stop) OR (@Step<0 AND @Start<@Stop)
    BEGIN INSERT @Result VALUES(NULL,'EMPTY',0); RETURN; END;
    DECLARE @Distance decimal(38,0)=ABS(CONVERT(decimal(38,0),@Stop)-CONVERT(decimal(38,0),@Start)),
            @Magnitude decimal(38,0)=ABS(CONVERT(decimal(38,0),@Step)),@Rows decimal(38,0);
    SET @Rows=(@Distance-(@Distance%@Magnitude))/@Magnitude+1;
    IF @Rows>1000000 BEGIN INSERT @Result VALUES(NULL,'LIMIT',@Rows); RETURN; END;
    INSERT @Result SELECT Value,'OK',@Rows FROM toolbelt_core.TVF_GenerateSeriesBigInt(@Start,@Stop,@Step);
    RETURN;
END;
GO

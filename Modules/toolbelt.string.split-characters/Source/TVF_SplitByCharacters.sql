-- ============================================================================
-- Objekt:          toolbelt_string.TVF_SplitByCharacters
-- Zweck:           Literal an mehreren einzelnen Unicode-Zeichen trennen
-- Parameter:       @Input nvarchar(max), @Separators nvarchar(4000),
--                  @KeepEmpty bit = 1
-- Resultset:       Value nvarchar(max), Ordinal bigint
-- Dependencies:    toolbelt_core.TVF_GenerateSeriesBigInt
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; synchrone lineare Verarbeitung
-- Collation:       Latin1_General_100_BIN2 für Separatorvergleiche
-- Einschränkungen: einzelne UTF-16-Codeeinheiten; ORDER BY Ordinal erforderlich
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitByCharacters]
(
      @Input      nvarchar(max)
    , @Separators nvarchar(4000)
    , @KeepEmpty  bit = 1
)
RETURNS TABLE
AS
RETURN
(
    WITH
    Parameters AS
    (
        SELECT
              InputLength = CONVERT(bigint, DATALENGTH(@Input) / 2)
            , SeparatorLength = CONVERT(bigint, DATALENGTH(@Separators) / 2)
            , KeepEmpty = COALESCE(@KeepEmpty, CONVERT(bit, 1))
    ),
    SeparatorValidation AS
    (
        SELECT
              parameters.InputLength
            , parameters.KeepEmpty
            , HasNullSeparator = CONVERT
              (
                  bit
                , CASE
                      WHEN EXISTS
                           (
                               SELECT 1
                               FROM toolbelt_core.TVF_GenerateSeriesBigInt
                                    (
                                        CONVERT(bigint, 1),
                                        parameters.SeparatorLength,
                                        CONVERT(bigint, 1)
                                    ) AS separator_positions
                               WHERE UNICODE
                                     (
                                         SUBSTRING
                                         (
                                             @Separators
                                                 COLLATE Latin1_General_100_BIN2,
                                             separator_positions.Value,
                                             1
                                         )
                                     ) = 0
                           )
                          THEN 1
                      ELSE 0
                  END
              )
        FROM Parameters AS parameters
        WHERE @Input IS NOT NULL
          AND @Separators IS NOT NULL
    ),
    Boundaries AS
    (
        SELECT BoundaryPosition = CONVERT(bigint, 0)
        FROM SeparatorValidation AS validation
        WHERE validation.HasNullSeparator = 0

        UNION ALL

        SELECT input_positions.Value
        FROM SeparatorValidation AS validation
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt
        (
            CONVERT(bigint, 1),
            validation.InputLength,
            CONVERT(bigint, 1)
        ) AS input_positions
        WHERE validation.HasNullSeparator = 0
          AND CASE
                  /*
                   * U+0000 ist als Eingabeinhalt erlaubt, aber nie Separator.
                   * CHARINDEX erhält diesen unter Windows-Collations nicht.
                   */
                  WHEN UNICODE
                       (
                           SUBSTRING
                           (
                               @Input COLLATE Latin1_General_100_BIN2,
                               input_positions.Value,
                               1
                           )
                       ) = 0
                      THEN 0
                  ELSE CHARINDEX
                       (
                           SUBSTRING
                           (
                               @Input COLLATE Latin1_General_100_BIN2,
                               input_positions.Value,
                               1
                           ),
                           @Separators COLLATE Latin1_General_100_BIN2
                       )
              END > 0

        UNION ALL

        SELECT validation.InputLength + CONVERT(bigint, 1)
        FROM SeparatorValidation AS validation
        WHERE validation.HasNullSeparator = 0
    ),
    BoundaryPairs AS
    (
        SELECT
              BoundaryPosition
            , NextBoundaryPosition =
                  LEAD(BoundaryPosition) OVER (ORDER BY BoundaryPosition)
        FROM Boundaries
    ),
    Tokens AS
    (
        SELECT
              Value = SUBSTRING
              (
                  @Input,
                  pairs.BoundaryPosition + CONVERT(bigint, 1),
                  pairs.NextBoundaryPosition
                      - pairs.BoundaryPosition
                      - CONVERT(bigint, 1)
              )
            , Ordinal = ROW_NUMBER() OVER (ORDER BY pairs.BoundaryPosition)
        FROM BoundaryPairs AS pairs
        CROSS JOIN SeparatorValidation AS validation
        WHERE pairs.NextBoundaryPosition IS NOT NULL
          AND
          (
              validation.KeepEmpty = 1
              OR pairs.NextBoundaryPosition
                   > pairs.BoundaryPosition + CONVERT(bigint, 1)
          )
    )
    SELECT
          Value
        , Ordinal
    FROM Tokens
);
GO

-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_TruncateDateTime2
-- Zweck:           Portabler DATETRUNC-Vertrag für datetime2(7).
-- Parameter:       @DatePart varchar(16), @Value datetime2(7)
-- Resultset:       Value datetime2(7), IsValid bit, ValidationCode tinyint
-- Dependencies:    TVF_TruncateDateTimeOffset im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; dünner relationaler Typ-Wrapper
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_TruncateDateTime2]
(
      @DatePart varchar(16)
    , @Value    datetime2(7)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
          Value = CONVERT(datetime2(7), truncated.Value)
        , truncated.IsValid
        , truncated.ValidationCode
    FROM toolbelt_datetime.TVF_TruncateDateTimeOffset
         (
               @DatePart
             , CONVERT(datetimeoffset(7), @Value)
         ) AS truncated
);
GO

-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketDateTime2
-- Zweck:           Portabler DATE_BUCKET-Vertrag für datetime2(7).
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value datetime2(7), @Origin datetime2(7) = 1900-01-01
-- Resultset:       Value datetime2(7), IsValid bit, ValidationCode tinyint
-- Dependencies:    TVF_DateBucketDateTimeOffset im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; dünner relationaler Typ-Wrapper
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateBucketDateTime2]
(
      @DatePart varchar(16)
    , @Width    int
    , @Value    datetime2(7)
    , @Origin   datetime2(7) = '19000101'
)
RETURNS TABLE
AS
RETURN
(
    SELECT
          Value = CONVERT(datetime2(7), bucket.Value)
        , bucket.IsValid
        , bucket.ValidationCode
    FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
         (
               @DatePart
             , @Width
             , CONVERT(datetimeoffset(7), @Value)
             , CONVERT(datetimeoffset(7), @Origin)
         ) AS bucket
);
GO

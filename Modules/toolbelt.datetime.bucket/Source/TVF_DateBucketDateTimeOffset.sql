-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketDateTimeOffset
-- Zweck:           Portabler DATE_BUCKET-Vertrag für datetimeoffset(7).
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value datetimeoffset(7),
--                  @Origin datetimeoffset(7) = 1900-01-01 +00:00
-- Resultset:       Value datetimeoffset(7), IsValid bit,
--                  ValidationCode tinyint
-- Dependencies:    interne TVF_DateBucketCore im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF vor einer einzeiligen internen Optimizer-Grenze
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateBucketDateTimeOffset]
(
      @DatePart varchar(16)
    , @Width    int
    , @Value    datetimeoffset(7)
    , @Origin   datetimeoffset(7) = '1900-01-01 00:00:00 +00:00'
)
RETURNS TABLE
AS
RETURN
(
    SELECT bucket.Value, bucket.IsValid, bucket.ValidationCode
    FROM toolbelt_datetime.TVF_DateBucketCore
         (@DatePart, @Width, @Value, @Origin) AS bucket
);
GO

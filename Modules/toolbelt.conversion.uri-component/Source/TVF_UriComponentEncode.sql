-- ============================================================================
-- Objekt: toolbelt_conversion.TVF_UriComponentEncode
-- Zweck:  RFC-3986-Percent-Encoding einer URI-Komponente als UTF-8-Octets.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentEncode]
(
    @Value nvarchar(max)
)
RETURNS TABLE
AS
RETURN
(
    WITH Utf8 AS
    (
        SELECT Bytes = CONVERT
        (
            varbinary(max),
            CONVERT
            (
                varchar(max),
                @Value COLLATE Latin1_General_100_BIN2_UTF8
            )
        )
    ),
    Encoded AS
    (
        SELECT EncodedValue = STRING_AGG(CONVERT(varchar(max), CASE
            WHEN SUBSTRING(utf8.Bytes, positions.Value, 1) BETWEEN 0x41 AND 0x5A
              OR SUBSTRING(utf8.Bytes, positions.Value, 1) BETWEEN 0x61 AND 0x7A
              OR SUBSTRING(utf8.Bytes, positions.Value, 1) BETWEEN 0x30 AND 0x39
              OR SUBSTRING(utf8.Bytes, positions.Value, 1) IN (0x2D,0x2E,0x5F,0x7E)
                THEN CONVERT(varchar(1), SUBSTRING(utf8.Bytes, positions.Value, 1)) COLLATE Latin1_General_100_BIN2
            ELSE '%' + UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(SUBSTRING(utf8.Bytes, positions.Value, 1)), 3, 2)) END), '') WITHIN GROUP (ORDER BY positions.Value)
        FROM Utf8 AS utf8
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1, CONVERT(bigint, DATALENGTH(utf8.Bytes)), 1) AS positions
    )
    SELECT EncodedValue = CASE WHEN @Value IS NULL THEN CONVERT(nvarchar(max),NULL) ELSE CONVERT(nvarchar(max),COALESCE(encoded.EncodedValue,'')) END
    FROM Encoded AS encoded
);
GO

-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_UriComponentEncodeStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Value nvarchar(max)
-- Resultset:       EncodedValue nvarchar(max), Status varchar(16)
-- Vertrag:         Documentation/TVF_UriComponentEncodeStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentEncodeStatus](@Value nvarchar(max))
RETURNS @Result TABLE(EncodedValue nvarchar(max) NULL,Status varchar(16) NOT NULL) AS
BEGIN
    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Value)>65536 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    DECLARE @Output nvarchar(max);
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
    SELECT @Output = CASE WHEN @Value IS NULL THEN CONVERT(nvarchar(max),NULL) ELSE CONVERT(nvarchar(max),COALESCE(encoded.EncodedValue,'')) END
    FROM Encoded AS encoded;
    IF DATALENGTH(@Output)>1048576 INSERT @Result VALUES(NULL,'LIMIT'); ELSE INSERT @Result VALUES(@Output,'OK');
    RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_UriComponentEncode.md
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentEncode](@Value nvarchar(max))
RETURNS TABLE AS RETURN
(SELECT EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(@Value));
GO

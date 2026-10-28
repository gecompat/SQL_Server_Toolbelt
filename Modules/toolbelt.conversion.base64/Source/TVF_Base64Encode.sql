-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_Base64EncodeStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Value varbinary(max), @UrlSafe bit = 0
-- Resultset:       EncodedValue varchar(max), Status varchar(16)
-- Vertrag:         Documentation/TVF_Base64EncodeStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64EncodeStatus]
(@Value varbinary(max),@UrlSafe bit=0)
RETURNS @Result TABLE(EncodedValue varchar(max) NULL,Status varchar(16) NOT NULL)
WITH SCHEMABINDING
AS
BEGIN
    /* DDL-Hilfe: Codiert varbinary(max) als Base64/Base64URL.
       Parameter: @Value varbinary(max), NULL erlaubt; @UrlSafe bit = 0,
       NULL entspricht 0. Höchstens 16777216 Eingabebytes; darüber Status LIMIT.
       Ergebnis: genau eine Zeile (EncodedValue varchar(max), Status varchar(16));
       Status ist SQL_NULL, LIMIT oder OK. Für den Aufruf ist SELECT erforderlich.
       Beispiel: SELECT * FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFECAFE,0);
       Erwartet: EncodedValue='yv7K/g==', Status='OK'. */
    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Value)>16777216 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    DECLARE @Encoded varchar(max);
    WITH Encoded AS
    (
        SELECT EncodedValue =
            CASE
                WHEN @Value IS NULL
                    THEN CONVERT(varchar(max), NULL)
                ELSE
                    CAST(N'' AS xml).value
                    (
                          N'xs:base64Binary(sql:variable("@Value"))'
                        , N'varchar(max)'
                    )
            END
    ),
    UrlSafe AS
    (
        SELECT
              EncodedValue
            , TransformedValue =
                  REPLACE(REPLACE(EncodedValue, '+', '-'), '/', '_')
        FROM Encoded
    )
    SELECT @Encoded =
        CONVERT
        (
              varchar(max)
            , CASE
                  WHEN ISNULL(@UrlSafe, 0) <> 1 OR EncodedValue IS NULL
                      THEN EncodedValue
                  ELSE LEFT
                       (
                             TransformedValue
                           , DATALENGTH(TransformedValue)
                             - CASE
                                   WHEN RIGHT(TransformedValue, 2) = '=='
                                       THEN 2
                                   WHEN RIGHT(TransformedValue, 1) = '='
                                       THEN 1
                                   ELSE 0
                               END
                       )
              END
        )
    FROM UrlSafe;
    INSERT @Result VALUES(@Encoded,'OK'); RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_Base64Encode.md
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64Encode]
(@Value varbinary(max),@UrlSafe bit=0)
RETURNS TABLE AS RETURN
/* DDL-Hilfe: Liefert eine Base64-Wertzeile für Binärdaten.
   Parameter: @Value varbinary(max), NULL erlaubt; @UrlSafe bit = 0,
   NULL entspricht 0. Höchstens 16777216 Eingabebytes; bei Überschreitung NULL.
   Ergebnis: EncodedValue varchar(max), genau eine Zeile; bei Größen-LIMIT NULL.
   Für den Aufruf ist SELECT erforderlich.
   Beispiel: SELECT EncodedValue FROM toolbelt_conversion.TVF_Base64Encode(0xCAFECAFE,0);
   Erwartet: yv7K/g==. */
(SELECT EncodedValue FROM toolbelt_conversion.TVF_Base64EncodeStatus(@Value,@UrlSafe));
GO

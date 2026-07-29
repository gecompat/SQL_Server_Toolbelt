-- ============================================================================
-- Objekt:          toolbelt_conversion.SVF_Base64Decode
-- Zweck:           Base64 oder Base64URL in Binärdaten decodieren
-- Parameter:       @Value varchar(max)
-- Rückgabewert:    varbinary(max); NULL bleibt NULL
-- Dependencies:    keine Toolbelt-Module; T-SQL/XML-Provider
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     synchrone LOB-Konvertierung; keine Inlining-Zusage
-- Collation:       ASCII-Vertrag; Vergleiche sind nicht sprachabhängig
-- Einschränkungen: ignoriert nur Space, Tab, CR und LF
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_Base64Decode]
(
    @Value varchar(max)
)
RETURNS varbinary(max)
AS
BEGIN
    IF @Value IS NULL
    BEGIN
        RETURN NULL;
    END;

    /*
     * SQL Server 2025 akzeptiert beide RFC-4648-Alphabete, optionales Padding
     * sowie genau diese vier Whitespace-Zeichen. Der XML-Provider erhält
     * deshalb eine kanonische Standard-Base64-Darstellung.
     */
    DECLARE @NormalizedValue varchar(max) =
        REPLACE
        (
            REPLACE
            (
                REPLACE
                (
                    REPLACE
                    (
                        REPLACE
                        (
                            REPLACE(@Value, '-', '+')
                          , '_'
                          , '/'
                        )
                      , CHAR(32)
                      , ''
                    )
                  , CHAR(9)
                  , ''
                )
              , CHAR(13)
              , ''
            )
          , CHAR(10)
          , ''
        );

    DECLARE
          @ValueLength      bigint =
              DATALENGTH(@NormalizedValue)
        , @FirstPadding     bigint =
              NULLIF(CHARINDEX('=', @NormalizedValue), 0)
        , @PaddingCount     tinyint = 0
        , @LengthRemainder  tinyint
        , @InvalidFormat    bit = 0;

    IF @NormalizedValue COLLATE Latin1_General_100_BIN2
           LIKE '%[^A-Za-z0-9+/=]%'
    BEGIN
        SET @InvalidFormat = 1;
    END;

    IF @FirstPadding IS NOT NULL
    BEGIN
        SET @PaddingCount =
            CONVERT(tinyint, @ValueLength - @FirstPadding + 1);

        IF @PaddingCount NOT IN (1, 2)
           OR REPLACE
              (
                  SUBSTRING
                  (
                        @NormalizedValue
                      , @FirstPadding
                      , @PaddingCount
                  )
                , '='
                , ''
              ) <> ''
           OR @ValueLength % 4 <> 0
           OR
              (
                  @PaddingCount = 1
                  AND (@FirstPadding - 1) % 4 <> 3
              )
           OR
              (
                  @PaddingCount = 2
                  AND (@FirstPadding - 1) % 4 <> 2
              )
        BEGIN
            SET @InvalidFormat = 1;
        END;
    END;

    SET @LengthRemainder =
        CONVERT
        (
              tinyint
            , ISNULL(@FirstPadding - 1, @ValueLength) % 4
        );

    IF @FirstPadding IS NULL AND @LengthRemainder = 1
    BEGIN
        SET @InvalidFormat = 1;
    END;

    IF @InvalidFormat = 1
    BEGIN
        /*
         * Scalar UDFs können keinen stabilen Toolbelt-Fehler werfen. Ein
         * fester synthetischer Sentinel erzwingt deshalb einen unveränderten
         * SQL-Engine-Konvertierungsfehler, ohne Eingabedaten offenzulegen.
         */
        DECLARE @InvalidSentinel varchar(32) = 'toolbelt.invalid.base64';
        RETURN CONVERT(varbinary(max), CONVERT(int, @InvalidSentinel));
    END;

    IF @FirstPadding IS NULL AND @LengthRemainder = 2
    BEGIN
        SET @NormalizedValue += '==';
    END;
    ELSE IF @FirstPadding IS NULL AND @LengthRemainder = 3
    BEGIN
        SET @NormalizedValue += '=';
    END;

    RETURN CAST(N'' AS xml).value
    (
          N'xs:base64Binary(sql:variable("@NormalizedValue"))'
        , N'varbinary(max)'
    );
END;
GO

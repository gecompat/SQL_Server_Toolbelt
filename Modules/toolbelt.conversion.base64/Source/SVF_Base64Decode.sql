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

    DECLARE @LengthRemainder tinyint =
        CONVERT(tinyint, DATALENGTH(@NormalizedValue) % 4);

    IF @LengthRemainder = 2
    BEGIN
        SET @NormalizedValue += '==';
    END;
    ELSE IF @LengthRemainder = 3
    BEGIN
        SET @NormalizedValue += '=';
    END;

    /*
     * Rest 1, ungültige Zeichen und fehlerhaftes Padding werden bewusst an den
     * Provider weitergegeben. Dessen Originalfehler bleibt unverändert.
     */
    RETURN CAST(N'' AS xml).value
    (
          N'xs:base64Binary(sql:variable("@NormalizedValue"))'
        , N'varbinary(max)'
    );
END;
GO

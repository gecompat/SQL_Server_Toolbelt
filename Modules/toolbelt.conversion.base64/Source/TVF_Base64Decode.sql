-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_Base64DecodeStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Value varchar(max)
-- Resultset:       DecodedValue varbinary(max), Status varchar(16)
-- Vertrag:         Documentation/TVF_Base64DecodeStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64DecodeStatus]
(@Value varchar(max))
RETURNS @Result TABLE(DecodedValue varbinary(max) NULL,Status varchar(16) NOT NULL)
WITH SCHEMABINDING
AS
BEGIN
    /* DDL-Hilfe: Decodiert Base64/Base64URL und meldet den festen Status.
       Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF werden
       ignoriert. Eingabe höchstens 25165824 Bytes, Ergebnis höchstens 16777216.
       Ergebnis: genau eine Zeile (DecodedValue varbinary(max), Status varchar(16));
       Status ist SQL_NULL, LIMIT, INVALID oder OK. Für den Aufruf ist SELECT erforderlich.
       Beispiel: SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('yv7K_g');
       Erwartet: DecodedValue=0xCAFECAFE, Status='OK'. */
    IF @Value IS NULL BEGIN INSERT @Result VALUES(NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Value)>25165824 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    DECLARE @Canonical varchar(max),@InvalidFormat bit=0,@Expected bigint,@Decoded varbinary(max),
        @Normalized varchar(max),@Length bigint,@FirstPadding bigint,@PaddingCount bigint,@LengthRemainder bigint;
    -- Normalisierung einmal materialisieren; CTE-Expansion scannte große
    -- gültige Inputs mehrfach. Die binäre ASCII-Prüfung nutzt denselben Stand.
    SET @Normalized=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Value,'-','+'),'_','/'),CHAR(32),''),CHAR(9),''),CHAR(13),''),CHAR(10),'');
    SET @Length=DATALENGTH(@Normalized);
    SET @FirstPadding=NULLIF(CHARINDEX('=',@Normalized COLLATE Latin1_General_100_BIN2),0);
    SET @PaddingCount=CASE WHEN @FirstPadding IS NULL THEN 0 ELSE @Length-@FirstPadding+1 END;
    SET @LengthRemainder=COALESCE(@FirstPadding-1,@Length)%4;
    IF @Normalized COLLATE Latin1_General_100_BIN2 LIKE '%[^A-Za-z0-9+/=]%'
        SET @InvalidFormat=1;
    IF (@FirstPadding IS NULL AND @LengthRemainder=1)
       OR (@FirstPadding IS NOT NULL AND (@PaddingCount NOT IN(1,2)
           OR DATALENGTH(REPLACE(SUBSTRING(@Normalized,@FirstPadding,@PaddingCount),'=',''))<>0
           OR @Length%4<>0 OR (@PaddingCount=1 AND @LengthRemainder<>3) OR (@PaddingCount=2 AND @LengthRemainder<>2)))
        SET @InvalidFormat=1;
    SET @Canonical=CASE WHEN @FirstPadding IS NULL AND @LengthRemainder=2 THEN @Normalized+'=='
                        WHEN @FirstPadding IS NULL AND @LengthRemainder=3 THEN @Normalized+'=' ELSE @Normalized END;
    IF @InvalidFormat=1 BEGIN INSERT @Result VALUES(NULL,'INVALID'); RETURN; END;
    SET @Expected=(DATALENGTH(@Canonical)/4)*CONVERT(bigint,3)
        -CASE WHEN RIGHT(@Canonical,2)='==' THEN 2 WHEN RIGHT(@Canonical,1)='=' THEN 1 ELSE 0 END;
    IF @Expected>16777216 BEGIN INSERT @Result VALUES(NULL,'LIMIT'); RETURN; END;
    IF DATALENGTH(@Canonical)=0 SET @Decoded=0x;
    ELSE SET @Decoded=CAST(N'' AS xml).value(N'xs:base64Binary(sql:variable("@Canonical"))',N'varbinary(max)');
    INSERT @Result VALUES(@Decoded,'OK'); RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_Base64Decode.md
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64Decode](@Value varchar(max))
RETURNS TABLE AS RETURN
/* DDL-Hilfe: Decodiert eine Base64/Base64URL-Wertzeile; ungültige Eingabe
   löst einen SQL-Engine-Konvertierungsfehler aus.
   Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF werden
   ignoriert. Eingabe höchstens 25165824 Bytes, decodierte Ausgabe höchstens 16777216.
   Ergebnis: DecodedValue varbinary(max), genau eine Zeile; bei Größen-LIMIT NULL.
   Für den Aufruf ist SELECT erforderlich.
   Beispiel: SELECT DecodedValue FROM toolbelt_conversion.TVF_Base64Decode('yv7K_g');
   Erwartet: 0xCAFECAFE. */
(SELECT DecodedValue=CASE WHEN Status='INVALID'
    THEN CONVERT(varbinary(max),CONVERT(int,LEFT('toolbelt.invalid.base64'+ISNULL(@Value,''),23)))
    ELSE DecodedValue END FROM toolbelt_conversion.TVF_Base64DecodeStatus(@Value));
GO

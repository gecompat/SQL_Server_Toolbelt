-- ============================================================================
-- Objekt: toolbelt_conversion.TVF_UriComponentDecode
-- Zweck:  Striktes einmaliges RFC-3986-Percent-Decoding einer URI-Komponente.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_UriComponentDecode]
(
    @Value nvarchar(max)
)
RETURNS TABLE
AS
RETURN
(
    WITH Parameters AS
    (
        SELECT InputLength = CONVERT(bigint,DATALENGTH(@Value)/2)
    ),
    Positions AS
    (
        SELECT positions.Value
        FROM Parameters AS parameters
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1,parameters.InputLength,1) AS positions
    ),
    Validation AS
    (
        SELECT
              HasNonAscii=CONVERT(bit,MAX(CASE WHEN UNICODE(SUBSTRING(@Value COLLATE Latin1_General_100_BIN2,positions.Value,1))>127 THEN 1 ELSE 0 END))
            , HasInvalidPercent=CONVERT(bit,MAX(CASE WHEN SUBSTRING(@Value,positions.Value,1)=N'%' AND (positions.Value+2>parameters.InputLength OR SUBSTRING(@Value,positions.Value+1,1) COLLATE Latin1_General_100_BIN2 NOT LIKE N'[0-9A-Fa-f]' OR SUBSTRING(@Value,positions.Value+2,1) COLLATE Latin1_General_100_BIN2 NOT LIKE N'[0-9A-Fa-f]') THEN 1 ELSE 0 END))
        FROM Parameters AS parameters LEFT JOIN Positions AS positions ON 1=1
    ),
    Bytes AS
    (
        SELECT HexValue=STRING_AGG(CONVERT(varchar(max),CASE
          WHEN SUBSTRING(@Value,positions.Value,1)=N'%'
           AND positions.Value+2<=parameters.InputLength
           AND SUBSTRING(@Value,positions.Value+1,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]'
           AND SUBSTRING(@Value,positions.Value+2,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]'
              THEN CONVERT(varchar(2),SUBSTRING(@Value,positions.Value+1,2))
          WHEN SUBSTRING(@Value,positions.Value,1)=N'%' THEN '00'
          ELSE SUBSTRING('0123456789ABCDEF',UNICODE(SUBSTRING(@Value,positions.Value,1))/16+1,1)+SUBSTRING('0123456789ABCDEF',UNICODE(SUBSTRING(@Value,positions.Value,1))%16+1,1) END),'') WITHIN GROUP(ORDER BY positions.Value)
        FROM Parameters AS parameters CROSS APPLY Positions AS positions
        WHERE NOT (positions.Value>1 AND SUBSTRING(@Value,positions.Value-1,1)=N'%' AND positions.Value+1<=parameters.InputLength AND SUBSTRING(@Value,positions.Value,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]' AND SUBSTRING(@Value,positions.Value+1,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]')
          AND NOT (positions.Value>2 AND SUBSTRING(@Value,positions.Value-2,1)=N'%' AND SUBSTRING(@Value,positions.Value-1,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]' AND SUBSTRING(@Value,positions.Value,1) COLLATE Latin1_General_100_BIN2 LIKE N'[0-9A-Fa-f]')
    ),
    Decoded AS
    (
        SELECT TextValue=CONVERT(nvarchar(max),CONVERT(varchar(max),CONVERT(varbinary(max),CONCAT('0x',COALESCE(bytes.HexValue,'')),1)) COLLATE Latin1_General_100_BIN2_UTF8)
        FROM Bytes AS bytes
    ),
    Utf8Validation AS
    (
        SELECT IsUtf8=CONVERT(bit,CASE WHEN CONVERT(varbinary(max),CONVERT(varchar(max),decoded.TextValue) COLLATE Latin1_General_100_BIN2_UTF8)=CONVERT(varbinary(max),CONCAT('0x',COALESCE(bytes.HexValue,'')),1) THEN 1 ELSE 0 END)
             , HasNul=CONVERT(bit,COALESCE
               (
                   (
                       SELECT MAX(CASE WHEN UNICODE(SUBSTRING(decoded.TextValue COLLATE Latin1_General_100_BIN2,positions.Value,1))=0 THEN 1 ELSE 0 END)
                       FROM toolbelt_core.TVF_GenerateSeriesBigInt(1,CONVERT(bigint,DATALENGTH(decoded.TextValue)/2),1) AS positions
                   ),
                   0
               ))
        FROM Bytes AS bytes CROSS JOIN Decoded AS decoded
    )
    SELECT
          DecodedValue=CONVERT(nvarchar(max),CASE WHEN @Value IS NULL OR validation.HasNonAscii=1 OR validation.HasInvalidPercent=1 OR utf8.IsUtf8=0 OR utf8.HasNul=1 THEN NULL ELSE decoded.TextValue END)
        , IsValid=CONVERT(bit,CASE WHEN @Value IS NULL THEN NULL WHEN validation.HasNonAscii=1 OR validation.HasInvalidPercent=1 OR utf8.IsUtf8=0 OR utf8.HasNul=1 THEN 0 ELSE 1 END)
        , ValidationCode=CONVERT(tinyint,CASE WHEN @Value IS NULL THEN NULL WHEN validation.HasNonAscii=1 THEN 10 WHEN validation.HasInvalidPercent=1 THEN 11 WHEN utf8.IsUtf8=0 THEN 12 WHEN utf8.HasNul=1 THEN 13 ELSE 0 END)
    FROM Validation AS validation CROSS JOIN Bytes AS bytes CROSS JOIN Decoded AS decoded CROSS JOIN Utf8Validation AS utf8
);
GO

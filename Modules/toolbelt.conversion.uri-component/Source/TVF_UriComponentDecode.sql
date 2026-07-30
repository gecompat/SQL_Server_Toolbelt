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
    BinaryData AS
    (
        SELECT
              BinaryValue=CONVERT(varbinary(max),CONCAT('0x',COALESCE(bytes.HexValue,'')),1)
            , ByteLength=CONVERT(bigint,DATALENGTH(CONVERT(varbinary(max),CONCAT('0x',COALESCE(bytes.HexValue,'')),1)))
        FROM Bytes AS bytes
    ),
    Octets AS
    (
        SELECT
              Position=positions.Value
            , data.ByteLength
            , FirstByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value,1))
            , SecondByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value+1,1))
            , ThirdByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value+2,1))
            , FourthByte=CONVERT(int,SUBSTRING(data.BinaryValue,positions.Value+3,1))
        FROM BinaryData AS data
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1,data.ByteLength,1) AS positions
    ),
    ValidSequences AS
    (
        SELECT
              StartPosition=octets.Position
            , SequenceLength=CONVERT(tinyint,CASE
                WHEN octets.FirstByte<=127 THEN 1
                WHEN octets.FirstByte<=223 THEN 2
                WHEN octets.FirstByte<=239 THEN 3
                ELSE 4 END)
            , CodePoint=CONVERT(int,CASE
                WHEN octets.FirstByte<=127 THEN octets.FirstByte
                WHEN octets.FirstByte<=223 THEN
                    (octets.FirstByte-192)*64+(octets.SecondByte-128)
                WHEN octets.FirstByte<=239 THEN
                    (octets.FirstByte-224)*4096
                    +(octets.SecondByte-128)*64
                    +(octets.ThirdByte-128)
                ELSE
                    (octets.FirstByte-240)*262144
                    +(octets.SecondByte-128)*4096
                    +(octets.ThirdByte-128)*64
                    +(octets.FourthByte-128) END)
        FROM Octets AS octets
        WHERE octets.FirstByte<=127
           OR
              (
                  octets.FirstByte BETWEEN 194 AND 223
                  AND octets.Position+1<=octets.ByteLength
                  AND octets.SecondByte BETWEEN 128 AND 191
              )
           OR
              (
                  octets.FirstByte BETWEEN 224 AND 239
                  AND octets.Position+2<=octets.ByteLength
                  AND octets.ThirdByte BETWEEN 128 AND 191
                  AND
                  (
                      (octets.FirstByte=224 AND octets.SecondByte BETWEEN 160 AND 191)
                      OR (octets.FirstByte BETWEEN 225 AND 236 AND octets.SecondByte BETWEEN 128 AND 191)
                      OR (octets.FirstByte=237 AND octets.SecondByte BETWEEN 128 AND 159)
                      OR (octets.FirstByte BETWEEN 238 AND 239 AND octets.SecondByte BETWEEN 128 AND 191)
                  )
              )
           OR
              (
                  octets.FirstByte BETWEEN 240 AND 244
                  AND octets.Position+3<=octets.ByteLength
                  AND octets.ThirdByte BETWEEN 128 AND 191
                  AND octets.FourthByte BETWEEN 128 AND 191
                  AND
                  (
                      (octets.FirstByte=240 AND octets.SecondByte BETWEEN 144 AND 191)
                      OR (octets.FirstByte BETWEEN 241 AND 243 AND octets.SecondByte BETWEEN 128 AND 191)
                      OR (octets.FirstByte=244 AND octets.SecondByte BETWEEN 128 AND 143)
                  )
              )
    ),
    Decoded AS
    (
        SELECT
              TextValue=CONVERT(nvarchar(max),COALESCE
              (
                  STRING_AGG
                  (
                      CONVERT(nvarchar(max),CASE
                          WHEN sequences.CodePoint<=65535
                              THEN NCHAR(sequences.CodePoint)
                          ELSE
                              NCHAR(55296+(sequences.CodePoint-65536)/1024)
                              +NCHAR(56320+(sequences.CodePoint-65536)%1024)
                      END),
                      N''
                  ) WITHIN GROUP(ORDER BY sequences.StartPosition),
                  N''
              ))
            , IsUtf8=CONVERT(bit,CASE
                WHEN COALESCE(SUM(CONVERT(bigint,sequences.SequenceLength)),0)=data.ByteLength
                    THEN 1 ELSE 0 END)
            , HasNul=CONVERT(bit,COALESCE(MAX(CASE WHEN sequences.CodePoint=0 THEN 1 ELSE 0 END),0))
        FROM BinaryData AS data
        LEFT JOIN ValidSequences AS sequences ON 1=1
        GROUP BY data.ByteLength
    )
    SELECT
          DecodedValue=CONVERT(nvarchar(max),CASE WHEN @Value IS NULL OR validation.HasNonAscii=1 OR validation.HasInvalidPercent=1 OR decoded.IsUtf8=0 OR decoded.HasNul=1 THEN NULL ELSE decoded.TextValue END)
        , IsValid=CONVERT(bit,CASE WHEN @Value IS NULL THEN NULL WHEN validation.HasNonAscii=1 OR validation.HasInvalidPercent=1 OR decoded.IsUtf8=0 OR decoded.HasNul=1 THEN 0 ELSE 1 END)
        , ValidationCode=CONVERT(tinyint,CASE WHEN @Value IS NULL THEN NULL WHEN validation.HasNonAscii=1 THEN 10 WHEN validation.HasInvalidPercent=1 THEN 11 WHEN decoded.IsUtf8=0 THEN 12 WHEN decoded.HasNul=1 THEN 13 ELSE 0 END)
    FROM Validation AS validation CROSS JOIN Decoded AS decoded
);
GO

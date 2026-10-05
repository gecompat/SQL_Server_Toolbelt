-- Synthetische Werte; Funktionen liefern je genau eine typisierte Diagnosezeile.
SELECT * FROM toolbelt_conversion.TVF_TryCastBigInt(N'-9223372036854775808',DEFAULT);
SELECT * FROM toolbelt_conversion.TVF_TryCastDecimal(N'99999999999999999999.9999999999999999991',DEFAULT);
SELECT * FROM toolbelt_conversion.TVF_TryCastDate(N'2024-02-29',DEFAULT);
SELECT * FROM toolbelt_conversion.TVF_TryCastDateTime2(N'2024-02-29T23:59:59.1234567',DEFAULT);
SELECT * FROM toolbelt_conversion.TVF_TryCastBit(N'2',DEFAULT);
SELECT * FROM toolbelt_conversion.TVF_TryCastUniqueIdentifier(N'00112233-4455-6677-8899-aabbccddeeff',DEFAULT);
GO
SELECT input.Ordinal,converted.Value,converted.Status,converted.ErrorCode
FROM (VALUES(1,N'42'),(2,N' 42'),(3,CONVERT(nvarchar(16),NULL))) input(Ordinal,TextValue)
CROSS APPLY toolbelt_conversion.TVF_TryCastBigInt(input.TextValue,DEFAULT) converted;
GO

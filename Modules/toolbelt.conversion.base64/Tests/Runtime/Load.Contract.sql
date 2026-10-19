-- Pflicht-Lastfall: vollständiger Roundtrip eines synthetischen 4-MiB-Werts.
-- Keine Zeitmessung, Baseline oder Aussage über Produktionskapazität.
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @Synthetic varbinary(max) = CONVERT(varbinary(max),
    REPLICATE(CONVERT(varchar(max), '0123456789ABCDEF'), 262144));
IF DATALENGTH(@Synthetic) <> 4194304
    THROW 52353, N'Die synthetische Lastfixture ist nicht exakt 4 MiB groß.', 1;

DECLARE @Encoded varchar(max) = toolbelt_conversion.SVF_Base64Encode(@Synthetic, 0);
DECLARE @Decoded varbinary(max) = toolbelt_conversion.SVF_Base64Decode(@Encoded);
IF @Encoded IS NULL OR DATALENGTH(@Encoded) <> 5592408
   OR @Decoded IS NULL OR DATALENGTH(@Decoded) <> DATALENGTH(@Synthetic)
   OR @Decoded <> @Synthetic
    THROW 52354, N'Der 4-MiB-Lastfall verlor oder veränderte synthetische Daten.', 1;

PRINT N'Base64 Pflicht-Lastfall mit Ergebnisprüfung: erfolgreich.';
GO

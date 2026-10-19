-- Pflicht-Lastfall: zehn Millionen Werte vollständig serverseitig auswerten.
-- Anzahl, Eindeutigkeit und Grenzen belegen exakt die Menge 1..10000000.
-- Keine Materialisierung im Client und keine Laufzeitschwelle.
SET NOCOUNT ON;

DECLARE @Count bigint, @DistinctCount bigint, @Minimum bigint, @Maximum bigint;
SELECT @Count = COUNT_BIG(*), @DistinctCount = COUNT_BIG(DISTINCT Value),
       @Minimum = MIN(Value), @Maximum = MAX(Value)
FROM toolbelt_core.TVF_GenerateSeriesBigInt(1, 10000000, 1);

IF @Count IS NULL OR @Count <> 10000000
   OR @DistinctCount IS NULL OR @DistinctCount <> 10000000
   OR @Minimum IS NULL OR @Minimum <> 1
   OR @Maximum IS NULL OR @Maximum <> 10000000
    THROW 52454, N'Der Zehn-Millionen-Lastfall lieferte nicht die vollständige erwartete Wertemenge.', 1;

PRINT N'Generate Series Pflicht-Lastfall mit Ergebnisprüfung: erfolgreich.';
GO

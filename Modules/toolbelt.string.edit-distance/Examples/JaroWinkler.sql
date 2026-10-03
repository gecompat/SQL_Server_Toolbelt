-- Ausschließlich synthetische Beispiele.
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'ABC',N'ACB',DEFAULT);
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'ABCA',N'ACBA',N'large');
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(NULL,N'ABC',N'invalid');

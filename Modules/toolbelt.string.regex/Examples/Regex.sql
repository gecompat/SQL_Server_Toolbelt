SELECT toolbelt_string.SVF_RegexIsMatch(
           N'order-2048', N'^order-\d+$', N'c') AS IsOrderKey;

SELECT toolbelt_string.SVF_RegexInstr(
           N'alpha 12 beta 34', N'\d+', 1, 2, 0, N'c') AS SecondNumberStart;

SELECT toolbelt_string.SVF_RegexCount(
           N'alpha 12 beta 34', N'\d+', 1, N'c') AS NumberCount;
-- R2b: synthetische Gesamttreffer und Empty-Split ohne Zeichenverlust.
SELECT * FROM toolbelt_string.TVF_RegexMatches(N'a12 b3',N'[0-9]+',DEFAULT,DEFAULT,DEFAULT,DEFAULT) ORDER BY Ordinal;
SELECT * FROM toolbelt_string.TVF_RegexSplit(N'abc',N'',DEFAULT,DEFAULT,DEFAULT) ORDER BY Ordinal;

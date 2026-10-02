-- Synthetische Beispiele; zuerst regulär bereitstellen und vorhandene Rechte nutzen.
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten',N'sitting',DEFAULT,DEFAULT);
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'CA',N'AC',DEFAULT,DEFAULT);
SELECT v.LeftText,v.RightText,d.Distance,d.ExceedsMaxDistance,d.ErrorCode
FROM (VALUES(N'Contoso',N'Contoso'),(N'Fabrikam',N'Fabrikan'))v(LeftText,RightText)
CROSS APPLY toolbelt_string.TVF_OsaDistance(v.LeftText,v.RightText,2,N'standard')d;

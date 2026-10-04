-- Synthetische Beispiele; das Modul muss bereits separat installiert sein.
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'Contoso');
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'Fabrikam');
-- Vollständiger Code statt Default-Vierzeichen-Clamp; terminales Leerzeichen
-- mittels Bytevergleich prüfen, nicht mit gepaddetem SQL-Stringvergleich.
SELECT PrimaryCode,AlternateCode,DATALENGTH(AlternateCode) AS AlternateBytes
FROM toolbelt_string.TVF_DoubleMetaphone(N'AJ');
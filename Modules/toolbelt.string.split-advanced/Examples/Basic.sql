-- Synthetisches Beispiel; Fehlerzeile vor fachlicher Verwendung prüfen.
SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT)
ORDER BY Ordinal;
GO

-- Synthetisches Beispiel; Fehlerzeile vor fachlicher Verwendung prüfen.
SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT)
ORDER BY Ordinal;
GO
-- Separate Transformation: S2-Originaltokenvertrag bleibt unverändert.
SELECT * FROM toolbelt_string.TVF_UnquoteToken(N'[a]]b]',DEFAULT,DEFAULT,DEFAULT);
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;"b;c";d',@SeparatorsJson=N'[";"]';
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;

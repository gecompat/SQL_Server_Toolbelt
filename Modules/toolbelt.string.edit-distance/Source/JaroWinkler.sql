SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Interner SAFE-Transport; gemeinsamer Scalar-Helfer ohne Culture-/Datenzugriffe.
CREATE FUNCTION toolbelt_string.TVF_JaroWinklerSimilarityCore
(@LeftText nvarchar(max),@RightText nvarchar(max),@Profile nvarchar(max))
RETURNS TABLE (Similarity float(53),ErrorCode int)
AS EXTERNAL NAME [Toolbelt_String_EditDistance].[Toolbelt.String.EditDistance.JaroProvider].[Evaluate];
GO
-- ============================================================================
-- Objekt: toolbelt_string.TVF_JaroWinklerSimilarity; Typ: inline TVF.
-- Zweck: begrenzte vollständige symmetrische Scalar-Ähnlichkeit von 0 bis 1.
-- Parameter: LeftText/RightText nvarchar(max), Profile nvarchar(max)=N'standard'.
-- Resultset: genau eine Zeile Similarity float(53) NULL, ErrorCode int logisch NOT NULL;
-- physische SQL-/Clientnullability nullable zulässig, kein Erfolgsfallback.
-- NULL: irgendein Text NULL ergibt NULL/ErrorCode 0 vor anderen Argumenten.
-- Fehler: Profil 1, Raw 3, UTF-16 4, Scalar 5, geplante Fensterarbeit 6.
-- Dependencies: eigener SAFE-Provider 1.1 und UnicodeScalar; SELECT auf öffentliche IF.
-- Versionen/Plattformen: Ziel SQL Server 2019/2022/2025 Windows/Linux; Runtime offen.
-- Performance: endliche Raw/Scalar-/Workprofile, lineare Matchpuffer;
-- keine SARGability-/Inlining-/Parallelitäts-/Heap-/Hardwallzusage.
-- Besonderheiten: h/2 reell, strikt J>0.7, Präfixbonus 0.1/maximal 4; keine Normalisierung.
-- Vertrag: Documentation/Architecture/JARO_WINKLER_CONTRACT.md.
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_JaroWinklerSimilarity
(@LeftText nvarchar(max),@RightText nvarchar(max),@Profile nvarchar(max)=N'standard')
RETURNS TABLE
AS RETURN
    SELECT Similarity,ErrorCode
    FROM toolbelt_string.TVF_JaroWinklerSimilarityCore(@LeftText,@RightText,@Profile);
GO

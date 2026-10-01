SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Interne SAFE-CLR-TVFs: kanonischer Regexdialekt, kein Datenzugriff.
-- Vollständig materialisierte Ergebnisse; SQL6522 mit TBX_REGEX_*-Präfix.
-- Ohne Defaults: SQL CLR akzeptiert keine Defaults an max-Parametern.
CREATE FUNCTION toolbelt_string.TVF_RegexMatchesCore
(@Input nvarchar(max), @Pattern nvarchar(max), @Start int,
 @Flags nvarchar(max), @Profile nvarchar(max), @MaxRows int)
RETURNS TABLE(Ordinal bigint, StartPosition bigint, Length bigint, Value nvarchar(max))
AS EXTERNAL NAME [Toolbelt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexMatches];
GO
CREATE FUNCTION toolbelt_string.TVF_RegexSplitCore
(@Input nvarchar(max), @Pattern nvarchar(max),
 @Flags nvarchar(max), @Profile nvarchar(max), @MaxRows int)
RETURNS TABLE(Ordinal bigint, StartPosition bigint, Length bigint, Value nvarchar(max))
AS EXTERNAL NAME [Toolbelt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexSplit];
GO
-- ============================================================================
-- Objekt: toolbelt_string.TVF_RegexMatches; Typ: inline TVF.
-- Zweck: nicht überlappende Gesamttreffer, keine Capture-Ausgabe.
-- Vertrag: Documentation/TVF_RegexMatches.md; Parameter: Input/Pattern max,
-- Start=1, Flags=c, Profile=standard, MaxRows=10000 (höchstens 100000).
-- Resultset: Ordinal/StartPosition/Length bigint, Value nvarchar(max).
-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT auf dieser TVF.
-- Versionen/Plattformen: SQL Server 2019/2022/2025, Windows/Linux.
-- Fehler: SQL6522/TBX_REGEX_*; vollständig geprüft vor Ausgabe.
-- Performance: begrenzte Materialisierung; keine Streaming-/Plan-Zusage.
-- Einschränkungen: UTF-16, keine Captures/Backreferences; NULL => 0 Zeilen.
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_RegexMatches
(@Input nvarchar(max), @Pattern nvarchar(max), @Start int = 1,
 @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard', @MaxRows int = 10000)
RETURNS TABLE
AS RETURN
    SELECT Ordinal, StartPosition, Length, Value
    FROM toolbelt_string.TVF_RegexMatchesCore(@Input COLLATE DATABASE_DEFAULT,
        @Pattern COLLATE DATABASE_DEFAULT, @Start, @Flags COLLATE DATABASE_DEFAULT,
        @Profile COLLATE DATABASE_DEFAULT, @MaxRows);
GO
-- ============================================================================
-- Objekt: toolbelt_string.TVF_RegexSplit; Typ: inline TVF.
-- Zweck: vollständige Quelle an Regexseparatoren in Originaltokens zerlegen.
-- Vertrag: Documentation/TVF_RegexSplit.md; Parameter: Input/Pattern max,
-- Flags=c, Profile=standard, MaxRows=10000 (höchstens 100000), kein Start.
-- Resultset: Ordinal/StartPosition/Length bigint, Value nvarchar(max).
-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT auf dieser TVF.
-- Versionen/Plattformen: SQL Server 2019/2022/2025, Windows/Linux.
-- Fehler: SQL6522/TBX_REGEX_*; keine verwertbaren Teilergebnisse.
-- Performance: begrenzte Materialisierung, kein relationaler Regexparser.
-- Einschränkungen: UTF-16; Leertrenner konsumieren nichts, nur Suchcursor+1;
-- Rand-/Zwischenleertokens erhalten, keine Captures/Entquotierung.
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_RegexSplit
(@Input nvarchar(max), @Pattern nvarchar(max),
 @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard', @MaxRows int = 10000)
RETURNS TABLE
AS RETURN
    SELECT Ordinal, StartPosition, Length, Value
    FROM toolbelt_string.TVF_RegexSplitCore(@Input COLLATE DATABASE_DEFAULT,
        @Pattern COLLATE DATABASE_DEFAULT, @Flags COLLATE DATABASE_DEFAULT,
        @Profile COLLATE DATABASE_DEFAULT, @MaxRows);
GO

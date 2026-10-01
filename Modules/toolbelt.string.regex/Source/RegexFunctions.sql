SET ANSI_NULLS ON;
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexReplaceCore (intern)
-- Typ: CLR SVF; Zweck: SAFE-CLR-Kern der öffentlichen Replace-Fassade.
-- Vertrag: Documentation/SVF_RegexReplace.md; Parameter: max-Texte, Start=1,
-- Occurrence=0, Flags=c, Profile=standard; Resultset: nvarchar(max).
-- Dependencies: SAFE Toolbelt_String_Regex; Rechte: SELECT/REFERENCES.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehlerverhalten: SQL 6522 / TBX_REGEX_*; keine Teilresultate/Seiteneffekte.
-- Performance: vollständige Materialisierung, kooperatives Gesamtbudget.
-- Einschränkungen: UTF-16-Positionen, keine Captures oder Backreferences.
-- ============================================================================
-- Technischer CLR-Kern: max-Parameter besitzen hier keine Defaults, weil
-- SQL Server diese für CLR-Funktionen zurückweist (1096).
CREATE FUNCTION [toolbelt_string].[SVF_RegexReplaceCore]
(
      @Input nvarchar(max)
    , @Pattern nvarchar(max)
    , @Replacement nvarchar(max)
    , @Start int
    , @Occurrence int
    , @Flags nvarchar(max)
    , @Profile nvarchar(max)
)
RETURNS nvarchar(max)
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME [Toolbelt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexReplace];
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexReplace
-- Typ: T-SQL SVF; Zweck: Regex-Gesamttreffer durch literal Unicode ersetzen.
-- Vertrag: Documentation/SVF_RegexReplace.md; max-Texte, Start=1,
-- Occurrence=0, Flags=c, Profile=standard; Ergebnis: nvarchar(max).
-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT/REFERENCES.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehler: SQL 6522 / TBX_REGEX_*; NULL-Short-Circuit, keine Teilresultate.
-- Performance: Materialisierung und zusätzlicher SVF-Aufrufoverhead;
-- keine Inlining-/iTVF-Zusage, kooperatives Gesamtbudget im CLR-Kern.
-- Einschränkungen: UTF-16-Positionen, keine Capture-Ausgabe/Backreferences.
-- ============================================================================
CREATE FUNCTION [toolbelt_string].[SVF_RegexReplace]
(
      @Input nvarchar(max), @Pattern nvarchar(max), @Replacement nvarchar(max)
    , @Start int = 1, @Occurrence int = 0
    , @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard'
)
RETURNS nvarchar(max)
AS
BEGIN
    -- Nach Unicode-Decoding vereinheitlicht die Fassade Collation-Metadaten,
    -- damit zentrale max-Defaults nicht mit Caller-Collations kollidieren.
    RETURN [toolbelt_string].[SVF_RegexReplaceCore](@Input COLLATE DATABASE_DEFAULT, @Pattern COLLATE DATABASE_DEFAULT, @Replacement COLLATE DATABASE_DEFAULT, @Start, @Occurrence, @Flags COLLATE DATABASE_DEFAULT, @Profile COLLATE DATABASE_DEFAULT);
END;
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexSubstringCore (intern)
-- Typ: CLR SVF; Zweck: SAFE-CLR-Kern der öffentlichen Substring-Fassade.
-- Vertrag: Documentation/SVF_RegexSubstring.md; Parameter: max-Texte,
-- Start=1, Occurrence=1, Flags=c, Profile=standard; Resultset: nvarchar(max).
-- Dependencies: SAFE Toolbelt_String_Regex; Rechte: SELECT/REFERENCES.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehlerverhalten: SQL 6522 / TBX_REGEX_*; ohne Treffer NULL, leerer Treffer N''.
-- Performance: vollständige Materialisierung, kooperatives Gesamtbudget.
-- Einschränkungen: UTF-16-Positionen, keine Capture-Ausgabe/Backreferences.
-- ============================================================================
CREATE FUNCTION [toolbelt_string].[SVF_RegexSubstringCore]
(
      @Input nvarchar(max)
    , @Pattern nvarchar(max)
    , @Start int
    , @Occurrence int
    , @Flags nvarchar(max)
    , @Profile nvarchar(max)
)
RETURNS nvarchar(max)
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME [Toolbelt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexSubstring];
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexSubstring
-- Typ: T-SQL SVF; Zweck: n-ten Regex-Gesamttreffer als Unicode-Text liefern.
-- Vertrag: Documentation/SVF_RegexSubstring.md; max-Texte, Start=1,
-- Occurrence=1, Flags=c, Profile=standard; Ergebnis: nvarchar(max).
-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT/REFERENCES.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehler: SQL 6522 / TBX_REGEX_*; ohne Treffer NULL, leerer Treffer N''.
-- Performance: Materialisierung und zusätzlicher SVF-Aufrufoverhead;
-- keine Inlining-/iTVF-Zusage, kooperatives Gesamtbudget im CLR-Kern.
-- Einschränkungen: UTF-16-Positionen, keine Capture-Ausgabe/Backreferences.
-- ============================================================================
CREATE FUNCTION [toolbelt_string].[SVF_RegexSubstring]
(
      @Input nvarchar(max), @Pattern nvarchar(max)
    , @Start int = 1, @Occurrence int = 1
    , @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard'
)
RETURNS nvarchar(max)
AS
BEGIN
    RETURN [toolbelt_string].[SVF_RegexSubstringCore](@Input COLLATE DATABASE_DEFAULT, @Pattern COLLATE DATABASE_DEFAULT, @Start, @Occurrence, @Flags COLLATE DATABASE_DEFAULT, @Profile COLLATE DATABASE_DEFAULT);
END;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexIsMatch]
(
      @Input   nvarchar(max)
    , @Pattern nvarchar(max)
    , @Flags   nvarchar(4) = N'c'
)
RETURNS bit
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME
    [Toolbelt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexIsMatch];
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexInstr]
(
      @Input        nvarchar(max)
    , @Pattern      nvarchar(max)
    , @Start        int = 1
    , @Occurrence   int = 1
    , @ReturnOption int = 0
    , @Flags        nvarchar(4) = N'c'
)
RETURNS int
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME
    [Toolbelt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexInstr];
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexCount]
(
      @Input   nvarchar(max)
    , @Pattern nvarchar(max)
    , @Start   int = 1
    , @Flags   nvarchar(4) = N'c'
)
RETURNS int
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME
    [Toolbelt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexCount];
GO

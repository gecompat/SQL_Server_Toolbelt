SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Interne SAFE-CLR-Kerne ohne max-Parameterdefaults; kein Datenzugriff.
CREATE FUNCTION toolbelt_string.TVF_RegexCapturesCore
(@Input nvarchar(max), @Pattern nvarchar(max), @Start int,
 @Flags nvarchar(max), @Profile nvarchar(max), @MaxRows int)
RETURNS TABLE(MatchOrdinal bigint, GroupOrdinal int, CaptureOrdinal bigint,
 GroupName nvarchar(128), Matched bit, StartPosition bigint, Length bigint, Value nvarchar(max))
AS EXTERNAL NAME [Toolbelt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexCaptures];
GO
CREATE FUNCTION toolbelt_string.SVF_RegexReplaceGroupsCore
(@Input nvarchar(max), @Pattern nvarchar(max), @Replacement nvarchar(max),
 @Start int, @Occurrence int, @Flags nvarchar(max), @Profile nvarchar(max))
RETURNS nvarchar(max)
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME [Toolbelt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexReplaceGroups];
GO
-- ============================================================================
-- Objekt: toolbelt_string.TVF_RegexCaptures; Typ: inline TVF.
-- Zweck: alle Capture-Wiederholungen nach Treffer/Gruppe/Capture ausgeben.
-- Vertrag: Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md.
-- Parameter: Input/Pattern max, Start=1, Flags=c, Profile=standard,
-- MaxRows=10000 (1..100000); 64 Gruppen, erfolgreiche Pfadhistory <=100000.
-- Resultset: MatchOrdinal/CaptureOrdinal/Position/Length bigint, GroupOrdinal
-- int, GroupName nvarchar(128), Matched bit, Value nvarchar(max).
-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT auf dieser TVF.
-- Versionen/Plattformen: SQL Server 2019/2022/2025, Windows/Linux.
-- Fehler: SQL6522/TBX_REGEX_*; atomare Materialisierung vor erster Zeile.
-- Performance: endliche Profil-/Zeilen-/Textgrenzen, kooperatives Budget;
-- keine Heap-/Backtracking-Garantie. GroupName+Value zählen zum Textbudget.
-- Einschränkungen: UTF-16; keine Pattern-Backreferences; NULL => 0 Zeilen.
-- Gruppenöffnung bestimmt Ordinal; unbeteiligt => CaptureOrdinal0/Matched0
-- und NULL-Position/Length/Value, tatsächlicher Leercapture => Matched1.
-- Ausgabeordnung: ORDER BY MatchOrdinal, GroupOrdinal, CaptureOrdinal.
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_RegexCaptures
(@Input nvarchar(max), @Pattern nvarchar(max), @Start int = 1,
 @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard', @MaxRows int = 10000)
RETURNS TABLE
AS RETURN
    SELECT MatchOrdinal, GroupOrdinal, CaptureOrdinal, GroupName, Matched, StartPosition, Length, Value
    FROM toolbelt_string.TVF_RegexCapturesCore(@Input COLLATE DATABASE_DEFAULT,
        @Pattern COLLATE DATABASE_DEFAULT, @Start, @Flags COLLATE DATABASE_DEFAULT,
        @Profile COLLATE DATABASE_DEFAULT, @MaxRows);
GO
-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexReplaceGroups; Typ: T-SQL SVF.
-- Zweck: Gesamttreffer mit $N/${Name}/$$ gruppenbezogen ersetzen.
-- Vertrag: Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md.
-- Parameter: Input/Pattern/Replacement max, Start=1, Occurrence=0 (alle),
-- Flags=c, Profile=standard; Ergebnis nvarchar(max), NULL => NULL.
-- Dependencies: interner SAFE-CLR-Kern; Rechte: SELECT/REFERENCES.
-- Versionen/Plattformen: SQL Server 2019/2022/2025, Windows/Linux.
-- Fehler: SQL6522/TBX_REGEX_*; strikte Referenzprüfung vor erster Suche.
-- Performance: begrenzte Materialisierung, kooperatives Gesamtbudget.
-- Einschränkungen: letzter erfolgreicher Capture je Gruppe; unbeteiligt leer;
-- positive vollständige ASCII-Dezimalreferenz ohne führende Null; ${Name}
-- nur explizit benannt. Backslash literal; erzeugte Dollarzeichen nicht parsen.
-- Ohne entsprechenden Treffer bleibt Input unverändert; UTF-16-Startposition.
-- ============================================================================
CREATE FUNCTION toolbelt_string.SVF_RegexReplaceGroups
(@Input nvarchar(max), @Pattern nvarchar(max), @Replacement nvarchar(max),
 @Start int = 1, @Occurrence int = 0,
 @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard')
RETURNS nvarchar(max)
AS
BEGIN
    RETURN toolbelt_string.SVF_RegexReplaceGroupsCore(@Input COLLATE DATABASE_DEFAULT,
        @Pattern COLLATE DATABASE_DEFAULT, @Replacement COLLATE DATABASE_DEFAULT,
        @Start, @Occurrence, @Flags COLLATE DATABASE_DEFAULT, @Profile COLLATE DATABASE_DEFAULT);
END;
GO

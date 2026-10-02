SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Interner SAFE-CLR-Transport; gemeinsame Scalar-/DP-Implementierung.
CREATE FUNCTION toolbelt_string.TVF_LevenshteinDistanceCore
(@LeftText nvarchar(max), @RightText nvarchar(max), @MaxDistance int, @Profile nvarchar(max))
RETURNS TABLE (Distance int, ExceedsMaxDistance bit, ErrorCode int)
AS EXTERNAL NAME [Toolbelt_String_EditDistance].[Toolbelt.String.EditDistance.DistanceProvider].[Levenshtein];
GO
-- ============================================================================
-- Objekt: toolbelt_string.TVF_LevenshteinDistance; Typ: inline TVF.
-- Zweck: begrenzte exakte Unicode-Scalar-Editierdistanz oder Thresholdnachweis.
-- Parameter: LeftText/RightText nvarchar(max), MaxDistance int=NULL,
-- Profile nvarchar(max)=standard; large ausdrücklich auswählen, kein Abschneiden.
-- Ergebnis: genau eine Zeile Distance int NULL, ExceedsMaxDistance bit NULL,
-- ErrorCode int logisch nicht NULL; native Metadaten nullable zulässig.
-- NULL: irgendein Text NULL => NULL/NULL/0 vor übrigen Prüfungen.
-- Fehler: Profile1, negative Grenze2, Raw3, UTF164, Scalars5, DP-Budget6.
-- Dependencies: eigener SAFE-CLR-Provider; Rechte: SELECT auf dieser Funktion.
-- Versionen: SQL Server 2019/2022/2025, Windows/Linux; native Gates noch offen.
-- Performance: bandierte zwei/drei DP-Zeilen, endliche Profilbudgets;
-- keine relationale Inlining-/Heap-/Parallelitätszusage. Keine Datenzugriffe.
-- Besonderheiten: ordinal, keine Normalisierung, NUL/trailing spaces erhalten.
-- Vertrag: Documentation/Architecture/EDIT_DISTANCE_CONTRACT.md.
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_LevenshteinDistance
(@LeftText nvarchar(max), @RightText nvarchar(max), @MaxDistance int = NULL,
 @Profile nvarchar(max) = N'standard')
RETURNS TABLE
AS RETURN
    SELECT Distance, ExceedsMaxDistance, ErrorCode
    FROM toolbelt_string.TVF_LevenshteinDistanceCore(@LeftText, @RightText, @MaxDistance, @Profile);
GO
-- Interner SAFE-CLR-Transport; gemeinsame Scalar-/DP-Implementierung.
CREATE FUNCTION toolbelt_string.TVF_OsaDistanceCore
(@LeftText nvarchar(max), @RightText nvarchar(max), @MaxDistance int, @Profile nvarchar(max))
RETURNS TABLE (Distance int, ExceedsMaxDistance bit, ErrorCode int)
AS EXTERNAL NAME [Toolbelt_String_EditDistance].[Toolbelt.String.EditDistance.DistanceProvider].[Osa];
GO
-- ============================================================================
-- Objekt: toolbelt_string.TVF_OsaDistance; Typ: inline TVF.
-- Zweck: begrenzte exakte Unicode-Scalar-Editierdistanz oder Thresholdnachweis.
-- Parameter: LeftText/RightText nvarchar(max), MaxDistance int=NULL,
-- Profile nvarchar(max)=standard; large ausdrücklich auswählen, kein Abschneiden.
-- Ergebnis: genau eine Zeile Distance int NULL, ExceedsMaxDistance bit NULL,
-- ErrorCode int logisch nicht NULL; native Metadaten nullable zulässig.
-- NULL: irgendein Text NULL => NULL/NULL/0 vor übrigen Prüfungen.
-- Fehler: Profile1, negative Grenze2, Raw3, UTF164, Scalars5, DP-Budget6.
-- Dependencies: eigener SAFE-CLR-Provider; Rechte: SELECT auf dieser Funktion.
-- Versionen: SQL Server 2019/2022/2025, Windows/Linux; native Gates noch offen.
-- Performance: bandierte zwei/drei DP-Zeilen, endliche Profilbudgets;
-- keine relationale Inlining-/Heap-/Parallelitätszusage. Keine Datenzugriffe.
-- Besonderheiten: ordinal, keine Normalisierung, NUL/trailing spaces erhalten.
-- Vertrag: Documentation/Architecture/EDIT_DISTANCE_CONTRACT.md.
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_OsaDistance
(@LeftText nvarchar(max), @RightText nvarchar(max), @MaxDistance int = NULL,
 @Profile nvarchar(max) = N'standard')
RETURNS TABLE
AS RETURN
    SELECT Distance, ExceedsMaxDistance, ErrorCode
    FROM toolbelt_string.TVF_OsaDistanceCore(@LeftText, @RightText, @MaxDistance, @Profile);
GO
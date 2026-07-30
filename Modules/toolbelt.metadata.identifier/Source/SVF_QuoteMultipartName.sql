SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- Objekt:          toolbelt_metadata.SVF_QuoteMultipartName
-- Typ:             Scalar-valued Function
-- Zweck:           Begrenzt einen gültigen Multipart-Namen sicher mit [].
-- Vertrag:         Documentation/SVF_QuoteMultipartName.md
-- Parameter:       @MultipartName nvarchar(1035)
-- Rückgabewert:    nvarchar(1035), bei ungültiger Eingabe NULL
-- Dependencies:    toolbelt_metadata.TVF_ParseMultipartName
-- Rechte:          SELECT oder REFERENCES
-- Versionen:       SQL Server 2019/2022/2025
-- Plattformen:     Windows/Linux
-- Fehlerverhalten: Ungültige Eingaben liefern NULL.
-- Performance:     Verwendet den kanonischen linearen Parser genau einmal.
-- Einschränkungen: Führt keine Objekt- oder Berechtigungsauflösung aus.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_metadata].[SVF_QuoteMultipartName]
(
    @MultipartName nvarchar(1035)
)
RETURNS nvarchar(1035)
AS
BEGIN
    DECLARE @QuotedName nvarchar(1035);

    SELECT @QuotedName = parsed.QuotedName
    FROM [toolbelt_metadata].[TVF_ParseMultipartName](@MultipartName) AS parsed
    WHERE parsed.IsValid = 1;

    RETURN @QuotedName;
END;
GO

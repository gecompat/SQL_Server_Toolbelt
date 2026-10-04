-- ============================================================================
-- Objekt:          toolbelt_string.TVF_DoubleMetaphone
-- Typ:             Inline TVF
-- Zweck:           Vollständiger primärer und alternativer Double-Metaphone-Code.
-- Vertrag:         Documentation/Architecture/PHONETIC_CONTRACT.md
-- Parameter:       @Text nvarchar(max), kein Default
-- Resultset:       PrimaryCode/AlternateCode varchar(max) NULL, ErrorCode int
-- Dependencies:    eigener SAFE-Kern TVF_DoubleMetaphoneCore
-- Rechte:          SELECT; keine Runtime-Metadaten-/Hashprüfung
-- Versionen:       SQL Server 2019/2022/2025
-- Plattformen:     Windows/Linux, Qualifikation noch offen
-- Fehlerverhalten: Status0..3, technische CLR-Defekte bleiben technische Fehler
-- Performance:     4096 UTF16-Einheiten; kein Vierzeichenclamp
-- Einschränkungen: geschlossenes Alphabet; terminales Alternativ-Leerbyte bleibt
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_DoubleMetaphone(@Text nvarchar(max))
RETURNS TABLE
AS RETURN
(
    SELECT CONVERT(varchar(max),PrimaryCode COLLATE Latin1_General_100_BIN2) COLLATE Latin1_General_100_BIN2 AS PrimaryCode,
           CONVERT(varchar(max),AlternateCode COLLATE Latin1_General_100_BIN2) COLLATE Latin1_General_100_BIN2 AS AlternateCode, ErrorCode
    FROM toolbelt_string.TVF_DoubleMetaphoneCore(@Text)
);
GO

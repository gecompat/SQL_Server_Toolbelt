-- ============================================================================
-- Objekt:          toolbelt_string.TVF_ColognePhonetic
-- Typ:             Inline TVF
-- Zweck:           Vollständige begrenzte Kölner Phonetik ohne Vergleichsoption.
-- Vertrag:         Documentation/Architecture/PHONETIC_CONTRACT.md
-- Parameter:       @Text nvarchar(max), kein Default
-- Resultset:       PhoneticCode varchar(max) NULL, ErrorCode int
-- Dependencies:    eigener SAFE-Kern TVF_ColognePhoneticCore
-- Rechte:          SELECT; keine Runtime-Metadaten-/Hashprüfung
-- Versionen:       SQL Server 2019/2022/2025
-- Plattformen:     Windows/Linux, Qualifikation noch offen
-- Fehlerverhalten: Status0..3, technische CLR-Defekte bleiben technische Fehler
-- Performance:     4096 UTF16-Einheiten; keine Parallelitäts-/Heapzusage
-- Einschränkungen: geschlossenes Alphabet; keine optionale Normalisierung
-- ============================================================================
CREATE FUNCTION toolbelt_string.TVF_ColognePhonetic(@Text nvarchar(max))
RETURNS TABLE
AS RETURN
(
    SELECT CONVERT(varchar(max),PhoneticCode COLLATE Latin1_General_100_BIN2) COLLATE Latin1_General_100_BIN2 AS PhoneticCode, ErrorCode
    FROM toolbelt_string.TVF_ColognePhoneticCore(@Text)
);
GO

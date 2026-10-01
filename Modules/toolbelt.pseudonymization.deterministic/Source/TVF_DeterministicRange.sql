-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicRange
-- Typ:             Inline Table-valued Function
-- Plattformen:     Windows und Linux, portabler T-SQL-Kern.
-- Vertrag:         Documentation/TVF_DeterministicRange.md
-- Zweck:           Versionsstabile Auswahl im geschlossenen bigint-Bereich.
-- Parameter:       Key varbinary(max), MappingVersion int, Seed bigint = 0,
--                  Min bigint, Max bigint.
-- Resultset:       Value bigint NULL, ErrorCode int NOT NULL.
-- Dependencies:    interne Inline-TVF TVF_DeterministicRangeCore.
-- Rechte:          SELECT auf öffentlicher TVF; keine Rechteausweitung.
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux.
-- Performance:     Relational inline; maximal 128 SHA256-Kandidaten je Key.
-- Collation:       Kein Textvergleich, keine Normalisierung oder Codepage.
-- Fehlerverhalten: NULL-Key zuerst; Fehlercode ohne Value, keine Exceptions.
-- Einschränkungen: Keine Eindeutigkeit, Kryptografie- oder Privacy-Garantie.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicRange]
(
      @Key            varbinary(max)
    , @MappingVersion int
    , @Seed           bigint = 0
    , @Min            bigint
    , @Max            bigint
)
RETURNS TABLE
AS
RETURN
(
    SELECT rangeValue.Value, rangeValue.ErrorCode
    FROM [toolbelt_pseudonymization].[TVF_DeterministicRangeCore]
        (0x54425844524E4731, 0, @Key, @MappingVersion, @Seed, @Min, @Max) AS rangeValue
);
GO

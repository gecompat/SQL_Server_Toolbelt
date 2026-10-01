-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicDateShift
-- Typ:             Inline Table-valued Function
-- Plattformen:     Windows und Linux, portabler T-SQL-Kern.
-- Vertrag:         Documentation/TVF_DeterministicDateShift.md
-- Zweck:           Gleicher Entity-Key ergibt denselben ganzzahligen Tagesoffset.
-- Parameter:       Value datetime2(7), Key varbinary(max), MappingVersion int,
--                  Seed bigint = 0, MaxDays int = 365 (0..3652058).
-- Resultset:       Value datetime2(7) NULL, ErrorCode int NOT NULL.
-- Dependencies:    kanonische öffentliche Inline-TVF TVF_DeterministicRange.
-- Rechte:          SELECT auf öffentlicher TVF; keine Rechteausweitung.
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux.
-- Performance:     Echte Inline TVF, keine zweite Hash-/Range-Implementierung.
-- Collation:       binärer Key; keine Text-, Zeitzonen- oder DST-Konvertierung.
-- Fehlerverhalten: NULL-Value/Key zuerst; Fehlercode ohne Value, kein Clamp.
-- Einschränkungen: Overflow ist Fehler; kein Clamp, Wrap oder Offset-Resultat.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicDateShift]
(
      @Value          datetime2(7)
    , @Key            varbinary(max)
    , @MappingVersion int
    , @Seed           bigint = 0
    , @MaxDays        int = 365
)
RETURNS TABLE
AS
RETURN
(
    WITH Configuration AS
    (
        SELECT SafeMaxDays = CONVERT(bigint, CASE
            WHEN @MaxDays BETWEEN 0 AND 3652058 THEN @MaxDays ELSE 0 END)
    ), Shift AS
    (
        SELECT rangeValue.Value AS OffsetDays, rangeValue.ErrorCode AS RangeError
        FROM Configuration AS configuration
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicRange]
            (CASE WHEN @Value IS NULL THEN NULL ELSE @Key END, @MappingVersion, @Seed,
             -configuration.SafeMaxDays, configuration.SafeMaxDays) AS rangeValue
    ), Resolved AS
    (
        SELECT shift.OffsetDays
            , ErrorCode = CONVERT(int, CASE
                WHEN @Value IS NULL OR @Key IS NULL THEN 0
                WHEN @MappingVersion IS NULL OR @MappingVersion <= 0 THEN 1
                WHEN @Seed IS NULL THEN 2
                WHEN @MaxDays IS NULL OR @MaxDays < 0 OR @MaxDays > 3652058 THEN 7
                WHEN shift.RangeError <> 0 THEN shift.RangeError
                WHEN shift.OffsetDays < -CONVERT(bigint, DATEDIFF(day, CONVERT(date, '00010101', 112), CONVERT(date, @Value)))
                  OR shift.OffsetDays > CONVERT(bigint, DATEDIFF(day, CONVERT(date, @Value), CONVERT(date, '99991231', 112))) THEN 8
                ELSE 0 END)
        FROM Shift AS shift
    )
    SELECT Value = CONVERT(datetime2(7), CASE
            WHEN @Value IS NULL OR @Key IS NULL OR resolved.ErrorCode <> 0 THEN NULL
            ELSE DATEADD(day, CONVERT(int, CASE
                WHEN resolved.ErrorCode = 0 AND @Value IS NOT NULL AND @Key IS NOT NULL THEN resolved.OffsetDays ELSE 0 END), @Value) END)
        , ErrorCode = ISNULL(resolved.ErrorCode, 5)
    FROM Resolved AS resolved
);
GO

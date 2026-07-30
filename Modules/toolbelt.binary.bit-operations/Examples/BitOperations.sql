-- Synthetisches Beispiel für Flag-Manipulation.
DECLARE @Flags TABLE (FlagId int, FlagValue bigint);
INSERT INTO @Flags VALUES (1, 0), (2, 4096);

SELECT flags.FlagId, changed.Value AS FlagValue
FROM @Flags AS flags
CROSS APPLY toolbelt_binary.TVF_SetBitBigInt
            (flags.FlagValue, 12, 1) AS changed
WHERE changed.IsValid = 1;

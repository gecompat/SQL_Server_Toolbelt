-- Releases 1.0.0 / 1.1.0: sechs historische Slots und ein neuer Translate-Slot.
IF OBJECT_ID(N'tempdb..#tbx_Deterministic_Release',N'U') IS NOT NULL
    THROW 54024, N'Deterministic: reserved lifecycle temp name is already visible.', 1;
CREATE TABLE #tbx_Deterministic_Release
(ObjectOrdinal int NOT NULL PRIMARY KEY, ObjectName sysname COLLATE DATABASE_DEFAULT NOT NULL, ObjectType char(2) COLLATE DATABASE_DEFAULT NOT NULL, Visibility nvarchar(16) COLLATE DATABASE_DEFAULT NOT NULL, FirstRelease int NOT NULL);
INSERT #tbx_Deterministic_Release VALUES
    (1,N'TVF_DeterministicIntegerBytes','IF',N'internal',10),
    (2,N'TVF_DeterministicRangeCore','IF',N'internal',10),
    (3,N'TVF_DeterministicRange','IF',N'public',10),
    (4,N'TVF_DeterministicDateShift','IF',N'public',10),
    (5,N'USP_DeterministicLookupCore','P',N'internal',10),
    (6,N'USP_DeterministicLookup','P',N'public',10),
    (7,N'TVF_DeterministicTranslate','IF',N'public',11);
GO

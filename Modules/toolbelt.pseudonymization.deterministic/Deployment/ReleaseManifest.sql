-- Release 1.0.0: sechs eigene Objekte; kein unterstütztes Vorgängerrelease.
IF OBJECT_ID(N'tempdb..#tbx_Deterministic_Release',N'U') IS NOT NULL
    THROW 54024, N'Deterministic: reserved lifecycle temp name is already visible.', 1;
CREATE TABLE #tbx_Deterministic_Release
(ObjectOrdinal int NOT NULL PRIMARY KEY, ObjectName sysname NOT NULL, ObjectType char(2) NOT NULL, Visibility nvarchar(16) NOT NULL);
INSERT #tbx_Deterministic_Release VALUES
    (1,N'TVF_DeterministicIntegerBytes','IF',N'internal'),
    (2,N'TVF_DeterministicRangeCore','IF',N'internal'),
    (3,N'TVF_DeterministicRange','IF',N'public'),
    (4,N'TVF_DeterministicDateShift','IF',N'public'),
    (5,N'USP_DeterministicLookupCore','P',N'internal'),
    (6,N'USP_DeterministicLookup','P',N'public');
GO

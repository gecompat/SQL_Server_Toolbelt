-- Synthetic contract only; requires deployed module. No runtime claim.
SET NOCOUNT ON;
DECLARE @Min bigint = CONVERT(bigint, '-9223372036854775808');
DECLARE @Max bigint = CONVERT(bigint, '9223372036854775807');

IF ISNULL(TRY_CONVERT(int,OBJECTPROPERTYEX(OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicRange'), N'IsInlineFunction')),0) <> 1
    THROW 54090, 'Range must be a genuine inline TVF.', 1;

DECLARE @Encoding TABLE (Input bigint, Expected binary(8));
INSERT @Encoding VALUES (@Min, 0x8000000000000000), (@Max, 0x7FFFFFFFFFFFFFFF),
    (-1, 0xFFFFFFFFFFFFFFFF), (-256, 0xFFFFFFFFFFFFFF00), (0, 0x0000000000000000), (256, 0x0000000000000100);
IF EXISTS (SELECT 1 FROM @Encoding AS example
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicIntegerBytes(example.Input) AS encoded
    WHERE encoded.Bytes IS NULL OR encoded.Bytes <> example.Expected)
    THROW 54090, 'Explicit byte encoding mismatch.', 1;

DECLARE @Vectors TABLE (KeyBytes varbinary(max), MappingVersion int, Seed bigint, LowerBound bigint, UpperBound bigint, Expected bigint);
INSERT @Vectors VALUES
    (0x010203, 1, 0, -10, 10, -9),
    (0x00, 1, @Min, @Min, @Max, 4631573001509251638),
    (0xFF00, 2147483647, @Max, @Min, @Min, @Min),
    (0x73796E7468657469632D72616E6765, 42, -17, -99999, -1, -57910),
    (CONVERT(varbinary(max), REPLICATE(CONVERT(varchar(max), CHAR(0)), 8000)), 1, 0, @Min, 0, -2303072262022855583);
IF EXISTS (SELECT 1 FROM @Vectors AS vector
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicRange(vector.KeyBytes, vector.MappingVersion, vector.Seed, vector.LowerBound, vector.UpperBound) AS actual
    WHERE actual.Value IS NULL OR actual.Value <> vector.Expected OR actual.ErrorCode IS NULL OR actual.ErrorCode <> 0)
    THROW 54090, 'Stable V1 vector mismatch (includes rejected attempts and 8000-byte frame).', 1;
IF (SELECT COUNT_BIG(*) FROM @Vectors AS vector
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicRange(vector.KeyBytes, vector.MappingVersion, vector.Seed, vector.LowerBound, vector.UpperBound)) <> 5
    THROW 54090, 'Range must return exactly one row per input.', 1;

DECLARE @Errors TABLE (KeyBytes varbinary(max), MappingVersion int, Seed bigint, LowerBound bigint, UpperBound bigint, Expected int);
INSERT @Errors VALUES
    (NULL, NULL, NULL, NULL, NULL, 0), -- NULL priority precedes every config error.
    (0x, 0, NULL, 10, -10, 1),
    (0x01, NULL, 0, 0, 0, 1),
    (0x, 1, NULL, 10, -10, 2),
    (0x, 1, 0, 10, -10, 3),
    (0x01, 1, 0, NULL, 1, 3),
    (0x01, 1, 0, 0, NULL, 3),
    (0x, 1, 0, 0, 1, 4),
    (CONVERT(varbinary(max), REPLICATE(CONVERT(varchar(max), 'x'), 8001)), 1, 0, 0, 1, 4);
IF EXISTS (SELECT 1 FROM @Errors AS example
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicRange(example.KeyBytes, example.MappingVersion, example.Seed, example.LowerBound, example.UpperBound) AS actual
    WHERE actual.Value IS NOT NULL OR actual.ErrorCode IS NULL OR actual.ErrorCode <> example.Expected)
    THROW 54090, 'Range error/NULL priority mismatch.', 1;
IF (SELECT COUNT_BIG(*) FROM @Errors AS example
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicRange(example.KeyBytes, example.MappingVersion, example.Seed, example.LowerBound, example.UpperBound)) <> 9
    THROW 54090, 'Error or NULL input lost its one row.', 1;

IF EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203, 1, DEFAULT, -10, 10)
    WHERE Value IS NULL OR Value <> -9 OR ErrorCode IS NULL OR ErrorCode <> 0)
    THROW 54090, 'Seed default mismatch.', 1;
IF NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203, 1, DEFAULT, -10, 10))
    THROW 54090, 'Seed default returned no row.', 1;

DECLARE @Columns TABLE (Ordinal int, ColumnName sysname, TypeId int, MaxLength int, IsNullable bit);
INSERT @Columns VALUES (1,N'Value',127,8,1),(2,N'ErrorCode',56,4,0);
IF EXISTS (SELECT 1 FROM @Columns AS expected
    LEFT JOIN sys.columns AS actual ON actual.object_id = OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicRange') AND actual.column_id = expected.Ordinal
    WHERE actual.column_id IS NULL OR actual.name COLLATE Latin1_General_100_BIN2 <> expected.ColumnName COLLATE Latin1_General_100_BIN2
       OR actual.system_type_id <> expected.TypeId OR actual.max_length <> expected.MaxLength OR actual.is_nullable <> expected.IsNullable)
    OR (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicRange')) <> 2
    THROW 54090, 'Range column metadata mismatch.', 1;
PRINT 'PASS: Range synthetic contract';
GO

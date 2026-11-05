-- Exercise the actual public token quota, including the EOF token, without injected limits.
DECLARE @Input nvarchar(max) = REPLICATE(CONVERT(nvarchar(max), N' ' + NCHAR(10)), 4096);
DECLARE @Below nvarchar(max) = LEFT(@Input,8190), @At nvarchar(max) = LEFT(@Input,8191);
IF (SELECT COUNT(*) FROM toolbelt_tsql.TVF_TokenizeScript(@Below,160,1,2097152,256)) <> 8191
   OR (SELECT COUNT(*) FROM toolbelt_tsql.TVF_TokenizeScript(@At,160,1,2097152,256)) <> 8192
    THROW 53141, N'Actual token output boundary mismatch.', 1;
DECLARE @Rejected bit = 0;
BEGIN TRY
    SELECT COUNT(*) FROM toolbelt_tsql.TVF_TokenizeScript(@Input,160,1,2097152,256);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522 OR ERROR_MESSAGE() NOT LIKE N'%TBX_TSQLPARSE_OUTPUT_LIMIT%' THROW;
    SET @Rejected = 1;
END CATCH;
IF @Rejected <> 1 THROW 53141, N'Actual token output overflow was accepted.', 2;
PRINT N'PARSER_ACTUAL_TOKEN_CEILING_PASS';

-- The error row limit is reachable; the next batch is already outside the atom admission bound.
DECLARE @ErrorBatch nvarchar(max) = N'SELECT' + NCHAR(10) + N'GO' + NCHAR(10);
DECLARE @ErrorsBelow nvarchar(max) = REPLICATE(@ErrorBatch,255),
        @ErrorsAt nvarchar(max) = REPLICATE(@ErrorBatch,256),
        @ErrorsBeyond nvarchar(max) = REPLICATE(@ErrorBatch,257);
IF (SELECT COUNT(*) FROM toolbelt_tsql.TVF_ParseScriptErrors(@ErrorsBelow,160,1,2097152,256)) <> 255
   OR (SELECT COUNT(*) FROM toolbelt_tsql.TVF_ParseScriptErrors(@ErrorsAt,160,1,2097152,256)) <> 256
    THROW 53141, N'Actual error row boundary mismatch.', 3;
SET @Rejected = 0;
BEGIN TRY
    SELECT COUNT(*) FROM toolbelt_tsql.TVF_ParseScriptErrors(@ErrorsBeyond,160,1,2097152,256);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522 OR ERROR_MESSAGE() NOT LIKE N'%TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT%' THROW;
    SET @Rejected = 1;
END CATCH;
IF @Rejected <> 1 THROW 53141, N'Error corpus beyond admission bound was accepted.', 4;
PRINT N'PARSER_ACTUAL_ERROR_BOUNDARY_AND_PRIOR_GUARD_PASS';

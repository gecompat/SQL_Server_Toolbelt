-- Synthetische SQL-Transportprobe; keine Callback-/Spillbehauptung.
SET NOCOUNT ON;
DECLARE @Actual TABLE(Fragment nvarchar(max),ErrorNumber int,ErrorState int,FaultPhase tinyint,
 RawValueBytes bigint,KeyBytes bigint,StrongMinimumBytes bigint,FragmentBytes bigint);
INSERT @Actual SELECT * FROM toolbelt_json.FT_JsonEntryEvaluateInternal(0,NULL,N'number',N'01',0,1);
IF (SELECT COUNT(*) FROM @Actual)<>1 OR EXISTS(SELECT 1 FROM @Actual WHERE Fragment IS NOT NULL
 OR ErrorNumber IS NULL OR ErrorNumber<>0 OR ErrorState IS NULL OR ErrorState<>0 OR FaultPhase IS NULL OR FaultPhase<>0
 OR RawValueBytes IS NULL OR RawValueBytes<>4 OR KeyBytes IS NULL OR KeyBytes<>0
 OR StrongMinimumBytes IS NULL OR StrongMinimumBytes<>4 OR FragmentBytes IS NULL OR FragmentBytes<>0)
 THROW 53690,N'JSON bridge raw-only number priority mismatch.',3;
DELETE FROM @Actual;
INSERT @Actual SELECT * FROM toolbelt_json.FT_JsonEntryEvaluateInternal(0,NULL,N'number',N'01',1,1);
IF (SELECT COUNT(*) FROM @Actual)<>1 OR EXISTS(SELECT 1 FROM @Actual WHERE Fragment IS NOT NULL
 OR ErrorNumber IS NULL OR ErrorNumber<>53608 OR ErrorState IS NULL OR ErrorState<>6 OR FaultPhase IS NULL OR FaultPhase<>3
 OR RawValueBytes IS NULL OR RawValueBytes<>4 OR KeyBytes IS NULL OR KeyBytes<>0
 OR StrongMinimumBytes IS NULL OR StrongMinimumBytes<>4 OR FragmentBytes IS NULL OR FragmentBytes<>0)
 THROW 53690,N'JSON bridge exact number fault mismatch.',4;
DELETE FROM @Actual;
INSERT @Actual SELECT * FROM toolbelt_json.FT_JsonEntryEvaluateInternal(1,N'k',N'null',NULL,1,1);
IF (SELECT COUNT(*) FROM @Actual)<>1 OR EXISTS(SELECT 1 FROM @Actual WHERE Fragment IS NULL
 OR CONVERT(varbinary(max),Fragment)<>CONVERT(varbinary(max),N'"k":null')
 OR ErrorNumber IS NULL OR ErrorNumber<>0 OR ErrorState IS NULL OR ErrorState<>0 OR FaultPhase IS NULL OR FaultPhase<>0
 OR RawValueBytes IS NULL OR RawValueBytes<>0 OR KeyBytes IS NULL OR KeyBytes<>2
 OR StrongMinimumBytes IS NULL OR StrongMinimumBytes<>16 OR FragmentBytes IS NULL OR FragmentBytes<>16)
 THROW 53690,N'JSON bridge SQL NULL and object fragment mismatch.',5;
PRINT N'PASS: JSON entry bridge raw-only, number fault and SQL NULL transport.';
GO

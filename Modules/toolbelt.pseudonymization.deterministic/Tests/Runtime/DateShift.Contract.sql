-- Ausschließlich synthetische Vertragswerte; kein Runtime-Nachweis ohne Ausführung.
SET NOCOUNT ON;
DECLARE @Date datetime2(7)=CONVERT(datetime2(7),'2026-01-02T03:04:05.1234567');
DECLARE @Cases TABLE (InputDate datetime2(7),KeyBytes varbinary(max),MappingVersion int,Seed bigint,MaxDays int,Expected datetime2(7),ExpectedError int);
INSERT @Cases VALUES
    (@Date,0x010203,1,0,365,DATEADD(day,177,@Date),0),
    (@Date,0x010203,1,0,0,@Date,0),
    (@Date,0x02,1,0,1,DATEADD(day,-1,@Date),0),
    (@Date,0x08,1,0,1,DATEADD(day,1,@Date),0),
    (NULL,0x,NULL,NULL,-1,NULL,0),
    (@Date,NULL,NULL,NULL,-1,NULL,0),
    (@Date,0x,NULL,NULL,-1,NULL,1),
    (@Date,0x,1,NULL,-1,NULL,2),
    (@Date,0x,1,0,-1,NULL,7),
    (@Date,0x01,1,0,NULL,NULL,7),
    (@Date,0x01,1,0,3652059,NULL,7),
    (@Date,0x01,1,0,-2147483648,NULL,7),
    (@Date,0x,1,0,1,NULL,4),
    (CONVERT(datetime2(7),'0001-01-01T00:00:00'),0x02,1,0,1,NULL,8),
    (CONVERT(datetime2(7),'9999-12-31T23:59:59.9999999'),0x08,1,0,1,NULL,8),
    (CONVERT(datetime2(7),'0001-01-01T00:00:00'),0x08,1,0,1,CONVERT(datetime2(7),'0001-01-02T00:00:00'),0),
    (CONVERT(datetime2(7),'9999-12-31T23:59:59.9999999'),0x02,1,0,1,CONVERT(datetime2(7),'9999-12-30T23:59:59.9999999'),0);
IF EXISTS(SELECT 1 FROM @Cases AS example CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicDateShift
    (example.InputDate,example.KeyBytes,example.MappingVersion,example.Seed,example.MaxDays) AS actual
    WHERE actual.ErrorCode IS NULL OR actual.ErrorCode<>example.ExpectedError
       OR (example.Expected IS NULL AND actual.Value IS NOT NULL)
       OR (example.Expected IS NOT NULL AND (actual.Value IS NULL OR actual.Value<>example.Expected)))
    THROW 54090,N'DateShift: Defaultvektor, Fehlerpriorität, Identity oder Overflow verletzt.',1;
IF (SELECT COUNT_BIG(*) FROM @Cases AS example CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicDateShift
    (example.InputDate,example.KeyBytes,example.MappingVersion,example.Seed,example.MaxDays))<>17
    THROW 54090,N'DateShift: exakt eine Zeile pro Eingabe erforderlich.',1;
DECLARE @First datetime2(7),@Second datetime2(7);
SELECT @First=Value FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(@Date,0x010203,1,DEFAULT,DEFAULT);
SELECT @Second=Value FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(DATEADD(day,30,@Date),0x010203,1,DEFAULT,DEFAULT);
IF @First IS NULL OR @Second IS NULL OR @First<>DATEADD(day,177,@Date) OR @Second<>DATEADD(day,30,@First)
    THROW 54090,N'DateShift: Defaults oder Entity-Intervallerhalt verletzt.',1;
IF ISNULL(TRY_CONVERT(int,OBJECTPROPERTYEX(OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicDateShift'),N'IsInlineFunction')),0)<>1
    THROW 54090,N'DateShift muss echte Inline-TVF sein.',1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicDateShift'))<>2
    OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicDateShift') AND column_id=1 AND name=N'Value' AND system_type_id=42 AND scale=7 AND is_nullable=1)
    OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicDateShift') AND column_id=2 AND name=N'ErrorCode' AND system_type_id=56 AND is_nullable=0)
    THROW 54090,N'DateShift: Spaltenmetadaten verletzt.',1;
PRINT N'PASS: DateShift synthetischer Vertrag';
GO

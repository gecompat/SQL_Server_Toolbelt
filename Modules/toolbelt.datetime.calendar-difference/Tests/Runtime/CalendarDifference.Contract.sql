SET NOCOUNT ON;
DECLARE @CompatibilityLevel int=TRY_CONVERT(int,N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN(150,160,170) THROW 52700,N'CompatibilityLevel muss 150, 160 oder 170 sein.',1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>@CompatibilityLevel THROW 52701,N'Falscher Compatibility Level.',1;
IF OBJECT_ID(N'toolbelt_datetime.TVF_CalendarDifference',N'IF') IS NULL THROW 52702,N'Die Funktion fehlt.',1;
IF EXISTS(SELECT 1 FROM toolbelt_datetime.TVF_CalendarDifference('2020-02-29','2021-02-28') WHERE Sign<>1 OR Years<>1 OR Months<>0 OR Days<>0) THROW 52703,N'Die Schaltjahr-Anniversary-Regel ist falsch.',1;
IF EXISTS(SELECT 1 FROM toolbelt_datetime.TVF_CalendarDifference('2024-02-29','2024-01-31') WHERE Sign<>-1 OR Years<>0 OR Months<>1 OR Days<>0) THROW 52704,N'Die negative Monatsende-Regel ist falsch.',1;
IF EXISTS(SELECT 1 FROM toolbelt_datetime.TVF_CalendarDifference('2024-01-01','2024-01-01') WHERE Sign<>0 OR Years<>0 OR Months<>0 OR Days<>0) THROW 52705,N'Der Nullabstand ist falsch.',1;

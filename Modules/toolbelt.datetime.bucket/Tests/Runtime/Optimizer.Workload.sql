:on error exit
SET NOCOUNT ON;

DECLARE @RowCount bigint;
DECLARE @MinimumValue datetime2(7);
DECLARE @MaximumValue datetime2(7);

;WITH Inputs AS
(
    SELECT TOP (100000)
          Ordinal = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
)
SELECT
      @RowCount = COUNT_BIG(*)
    , @MinimumValue = MIN(bucketed.Value)
    , @MaximumValue = MAX(bucketed.Value)
FROM Inputs AS inputs
CROSS APPLY toolbelt_datetime.TVF_DateBucketDateTime2
(
      'minute'
    , 15
    , DATEADD(minute, inputs.Ordinal, CONVERT(datetime2(7), '2020-01-01T00:00:00'))
    , CONVERT(datetime2(7), '2020-01-01T00:00:00')
) AS bucketed
WHERE bucketed.IsValid = 1
OPTION (MAXDOP 1);

IF @RowCount <> 100000
    THROW 52843, N'Der Bucket-Optimizer-Workload lieferte nicht alle Eingabezeilen.', 1;
IF @MinimumValue <> CONVERT(datetime2(7), '2020-01-01T00:00:00')
    THROW 52844, N'Der minimale Bucketwert des Optimizer-Workloads ist falsch.', 1;
IF @MaximumValue <> CONVERT(datetime2(7), '2020-03-10T10:30:00')
    THROW 52845, N'Der maximale Bucketwert des Optimizer-Workloads ist falsch.', 1;

PRINT N'Date/Time Bucket Optimizer-Workload: erfolgreich; Rows=100000';
GO

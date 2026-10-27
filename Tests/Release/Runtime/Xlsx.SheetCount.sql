-- Feste Workbook-Worksheetgrenze der bestehenden Listen-API.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
IF @@TRANCOUNT <> 0 THROW 52097,N'Neutraler Caller-Transaktionszustand erforderlich.',1;
DECLARE @Owner nvarchar(32)=(
    SELECT CONVERT(nvarchar(32),value)
    FROM sys.extended_properties
    WHERE class=0 AND name=N'Test.Release.Owner'
);
IF @Owner IS NULL
   OR @Owner COLLATE Latin1_General_100_BIN2 NOT LIKE REPLICATE(N'[0-9a-f]',32) COLLATE Latin1_General_100_BIN2
   OR DB_NAME() NOT IN (N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c')
    THROW 52097,N'Markierter eigener XLSX-Grenztestscope erforderlich.',2;
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@XlsxBinary;

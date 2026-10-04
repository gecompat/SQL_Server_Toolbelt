/*
-- Objekt: toolbelt_file.TVF_FormatXlsxCell.
-- Zweck: Bereits gelesene XLSX-Einzelzelle mit endlichen Formaten anzeigen.
-- Parameter: @StoredType/@RawValue/@TextValue/@TargetType/@FormatCode nvarchar(max),
-- @ValuePresent/@Date1904 bit, @CultureName nvarchar(max), alle Default NULL.
-- Kultur: ausschließlich en-US, de-DE oder tr-TR, ohne Betriebssysteminferenz.
-- Resultset: DisplayText nvarchar(max) nullable und StatusCode int immer gesetzt.
-- NULL: Keine Null-on-null-Abkürzung; genau eine Statuszeile auch bei NULL-Input.
-- Fehler: 0OK/1Absent/2Argument/3Limit/4LexikUTF16/5NumberRange/6Unsupported/
-- 7Serial60/8TemporalRange/9Precision/10ExcelError/11NullBinding; Fehlertext NULL.
-- Rechte: vorhandenes SELECT/Ownershipchain, keine Rechteerteilung.
-- Performance: Typkernbudgets unverändert; Kultur höchstens32 UTF16-Einheiten.
-- Grenzen: Kein Workbook-/SST-/Stylezugriff, keine Formelberechnung oder Daueranzeige.
-- Dependencies: Interne FT in vorhandener SAFE-XLSX-Assembly, Typkern unverändert.
-- Beispiel: SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(N'n',1,N'1.235',NULL,N'number',N'0.00',NULL,N'en-US');
-- Vertrag: Documentation/Architecture/XLSX_CELL_DISPLAY_CONTRACT.md.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER FUNCTION toolbelt_file.TVF_FormatXlsxCell
(
 @StoredType nvarchar(max)=NULL, @ValuePresent bit=NULL, @RawValue nvarchar(max)=NULL,
 @TextValue nvarchar(max)=NULL, @TargetType nvarchar(max)=NULL, @FormatCode nvarchar(max)=NULL,
 @Date1904 bit=NULL, @CultureName nvarchar(max)=NULL
)
RETURNS TABLE AS RETURN
 SELECT CASE WHEN r.StatusCode IS NOT NULL THEN r.DisplayText END DisplayText,
        ISNULL(r.StatusCode,11) StatusCode
 FROM toolbelt_file.TVF_InternalFormatXlsxCell
 (@StoredType,@ValuePresent,@RawValue,@TextValue,@TargetType,@FormatCode,@Date1904,@CultureName) r;
GO

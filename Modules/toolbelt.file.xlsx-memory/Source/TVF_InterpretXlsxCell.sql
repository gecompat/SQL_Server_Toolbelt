/*
-- Objekt: toolbelt_file.TVF_InterpretXlsxCell
-- Zweck: Bereits gelesene XLSX-Einzelzelle invariant typisieren, ohne Anzeigeformatierung.
-- Parameter: @StoredType nvarchar(max)=NULL (n/b/s/str/inlineStr/d/e),
-- @ValuePresent bit=NULL (XML-v-Presence), @RawValue nvarchar(max)=NULL,
-- @TextValue nvarchar(max)=NULL (bereits aufgelöster Text), @TargetType nvarchar(max)=NULL
-- (number/boolean/text/date/datetime/time/duration), @FormatCode nvarchar(max)=NULL
-- (endliche Zielklassifikation), @Date1904 bit=NULL (n-Date/Datetime benötigt Datumssystem).
-- Resultset: Genau eine Zeile mit StoredType nvarchar(32), ValuePresent bit,
-- RawValue nvarchar(max), TextValue nvarchar(max), EchoPreserved bit,
-- ResolvedType nvarchar(16), NumberValue sql_variant (exaktes SqlDecimal p<=38),
-- BooleanValue bit, DateValue date, DateTimeValue datetime2(7), TimeValue time(7),
-- DurationTicks bigint, TypedTextValue nvarchar(max), StatusCode int.
-- NULL: Echo-/Typedwerte nullable; EchoPreserved/StatusCode logisch immer gesetzt.
-- Ausschließlich NULL-Input liefert eine Statuszeile, keine Null-on-null-Abkürzung.
-- Fehlerverhalten: 0OK/1Absent/2Argument/3Limit/4LexikUTF16/5NumberRange/6Unsupported/
-- 7Serial60/8TemporalRange/9Precision/10ExcelError/11NullBinding. Alle Typedwerte
-- bei Fehler NULL; Status3/11 verwirft Echos atomar. Andere Enginefehler original.
-- Dependencies: Interne FT derselben vorhandenen SAFE-XLSX-Assembly; Moduldependencies
-- ZIP>=1.4.0/ResultTable>=1.0.0 bleiben. Caller benötigt bestehendes SELECT auf der TVF;
-- Deployment erstellt keine Berechtigungen. SQL2019/2022/2025 Windows/Linux Zielmatrix,
-- neue API dort erst nach tatsächlicher integrierter Qualifikation als PASS behandeln.
-- Performance: Input32/32/128/65536/65536 UTF16; Number-/Serialparser128; Ausgabecharge
-- 262144=256+4*Stringunits, keine gesamte Heap-/SQL-Memorygrant-/Laufzeitgarantie.
-- Grenzen: Keine Workbook-/SST-/Style-Neulesung, Cultureinferenz oder Formelberechnung.
-- Beispiel: SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(N'n',1,N'1',NULL,NULL,NULL,NULL);
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER FUNCTION toolbelt_file.TVF_InterpretXlsxCell
(
 @StoredType nvarchar(max) = NULL, @ValuePresent bit = NULL, @RawValue nvarchar(max) = NULL,
 @TextValue nvarchar(max) = NULL, @TargetType nvarchar(max) = NULL,
 @FormatCode nvarchar(max) = NULL, @Date1904 bit = NULL
)
RETURNS TABLE
AS
RETURN
 SELECT
  CASE WHEN r.StatusCode IS NOT NULL THEN r.StoredType END AS StoredType,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.ValuePresent END AS ValuePresent,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.RawValue END AS RawValue,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.TextValue END AS TextValue,
  ISNULL(CASE WHEN r.StatusCode IS NOT NULL THEN r.EchoPreserved END,CONVERT(bit,0)) AS EchoPreserved,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.ResolvedType END AS ResolvedType,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.NumberValue END AS NumberValue,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.BooleanValue END AS BooleanValue,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.DateValue END AS DateValue,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.DateTimeValue END AS DateTimeValue,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.TimeValue END AS TimeValue,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.DurationTicks END AS DurationTicks,
  CASE WHEN r.StatusCode IS NOT NULL THEN r.TypedTextValue END AS TypedTextValue,
  ISNULL(r.StatusCode,11) AS StatusCode
 FROM toolbelt_file.TVF_InternalInterpretXlsxCell
  (@StoredType,@ValuePresent,@RawValue,@TextValue,@TargetType,@FormatCode,@Date1904) AS r;
GO

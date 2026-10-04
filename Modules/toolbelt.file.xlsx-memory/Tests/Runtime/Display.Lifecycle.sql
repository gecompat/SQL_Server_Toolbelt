-- Neun bekannte Slots; keine Übertragung früherer 1.1-Lifecycle-Evidenz.
SET NOCOUNT ON;
DECLARE @Expected TABLE(Name sysname COLLATE DATABASE_DEFAULT NOT NULL,Kind char(2) COLLATE DATABASE_DEFAULT NOT NULL);
INSERT @Expected VALUES(N'USP_ListXlsxWorksheets','P'),(N'USP_ReadXlsxWorksheetCells','P'),(N'USP_InternalXlsxRead','P'),
(N'TVF_InternalXlsxSheets','FT'),(N'TVF_InternalXlsxCells','FT'),(N'TVF_InternalInterpretXlsxCell','FT'),(N'TVF_InterpretXlsxCell','IF'),
(N'TVF_InternalFormatXlsxCell','FT'),(N'TVF_FormatXlsxCell','IF');
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.2.0'))
 OR EXISTS(SELECT 1 FROM @Expected e LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(e.Name))
 WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),e.Name) OR CONVERT(varbinary(max),o.type)<>CONVERT(varbinary(max),e.Kind)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),N'toolbelt.file.xlsx-memory'))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),N'1.2.0')))
 THROW 51594,N'Anzeige-Lifecycle: neun Slots oder Releasezuordnung inkohärent.',3;
IF NOT EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.assembly_modules m ON m.assembly_id=a.assembly_id
 WHERE a.name=N'Toolbelt_File_XlsxMemory' AND a.permission_set=1 AND m.object_id=OBJECT_ID(N'toolbelt_file.TVF_InternalFormatXlsxCell')
 AND CONVERT(varbinary(max),m.assembly_class)=CONVERT(varbinary(max),N'Toolbelt.Xlsx.Qualification.XlsxCellDisplayBridge')
 AND CONVERT(varbinary(max),m.assembly_method)=CONVERT(varbinary(max),N'Evaluate'))
 THROW 51594,N'Anzeige-Binding: exakte Klasse/Methode in bestehender SAFE-Assembly fehlt.',4;
SELECT N'PASS' AS Status;
GO

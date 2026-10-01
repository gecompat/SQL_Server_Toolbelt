"""Struktureller XLSX-Vertrag; ersetzt keine Framework-/SQL-/NoIO-Evidenz."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

module = Path(__file__).resolve().parents[2]
repo = module.parents[1]
public = ("USP_ListXlsxWorksheets", "USP_ReadXlsxWorksheetCells")
internal = ("USP_InternalXlsxRead", "TVF_InternalXlsxSheets", "TVF_InternalXlsxCells")
for name in public:
    source = (module / "Source" / (name + ".sql")).read_text(encoding="utf-8-sig")
    for token in ("-- Objekt:", "-- Parameter:", "-- Resultset:", "-- Fehlerverhalten:",
                  "-- Performance:", "SET NOCOUNT ON", "@Hilfe bit = 0",
                  "DECLARE @Empty TABLE", "LOWER(LEFT(@ResultTable COLLATE Latin1_General_100_BIN2",
                  "EXEC toolbelt_file.USP_InternalXlsxRead"):
        assert token in source, (name, token)
    assert "CREATE TABLE #" not in source, "Private Temp-DDL gehört hinter die Compilergrenze."
    assert source.index("IF @Hilfe=1") < source.index("IF @XlsxBinary IS NULL") < source.index("THROW 51520") < source.index("EXEC toolbelt_file.USP_InternalXlsxRead")
    assert (module / "Documentation" / (name + ".md")).is_file()
core = (module / "Source/USP_InternalXlsxRead.sql").read_text(encoding="utf-8-sig")
for token in ("@Hilfe bit = 0", "IF @Hilfe=1", "@SavepointSet", "XACT_STATE()=1",
              "CONVERT(varbinary(max)", "THROW @", "SAVE TRANSACTION"):
    assert token in core or token.replace("@SavepointSet", "@SheetsSavepointSet") in core, token
assert "@@Sheets" not in core and "@@Cells" not in core
provider = (module / "Clr/XlsxEntryPoints.cs").read_text(encoding="utf-8-sig")
assert provider.count("DataAccess=DataAccessKind.None") == 2
assert provider.count("SystemDataAccess=SystemDataAccessKind.None") == 2
assert "catch (InvalidDataException" in provider and "catch (Exception" not in provider
workbook = (module / "Clr/Workbook.cs").read_text(encoding="utf-8-sig")
for token in ("DtdProcessing.Prohibit", "XmlResolver = null", "ZipEntryProvider.ArchiveSession",
              "ROW_NESTING_INVALID", "SHEET_NESTING_INVALID", "inSheetData", "inSheets"):
    assert token in workbook, token
for token in ("File.", "Directory.", "Process.", "IsolatedStorage", "ZipArchive", "WebClient"):
    assert token not in workbook and token not in provider, token
ns = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
project = ET.parse(module / "Clr/Toolbelt.File.XlsxMemory.csproj")
assert sorted(n.attrib["Include"] for n in project.findall(".//m:Compile", ns)) == ["AssemblyInfo.cs", "Workbook.cs", "XlsxEntryPoints.cs"]
assert sorted(n.attrib["Include"] for n in project.findall(".//m:Reference", ns)) == ["System", "System.Data", "System.Xml", "Toolbelt.Archive.ZipMemory"]
deploy = (module / "Deployment/Deploy.sql").read_text(encoding="utf-8-sig")
uninstall = (module / "Deployment/Uninstall.sql").read_text(encoding="utf-8-sig")
for script in (deploy, uninstall):
    assert script.index("IF @@TRANCOUNT<>0") < script.index("SET NOCOUNT ON") < script.index("SET XACT_ABORT ON")
    assert "RAISERROR(N'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:" in script and "RETURN;" in script
assert "HelpContractVersion varchar(16) NOT NULL DEFAULT" in core
assert "SchemaName sysname NOT NULL DEFAULT" in core and "ObjectName sysname NOT NULL DEFAULT" in core
for name in public + internal:
    assert "../Source/" + name + ".sql" in deploy and name in uninstall, name
for token in ("HASHBYTES('SHA2_512'", "permission_set=1", "sys.sp_getapplock", "sys.assembly_references", "CONVERT(varbinary(max)"):
    assert token in deploy, token
for token in ("sp_configure", "TRUSTWORTHY ON", "GRANT ", "WITH OVERRIDE"):
    assert token not in deploy and token not in uninstall, token
assert "ZipProviderException" not in provider, "Keine Kopplung an privaten ZIP-Fehlertyp."
assert not (repo / "Spikes/XlsxMemory/XlsxQualification.cs").exists(), "Kein duplizierter Workbookkern."
print("PASS: XLSX struktureller Source-/Compiler-/Lifecycle-/Dependencyvertrag; keine Runtimebehauptung.")

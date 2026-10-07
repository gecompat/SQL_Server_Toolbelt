"""Struktureller XLSX-Vertrag; ersetzt keine Framework-/SQL-/NoIO-Evidenz."""
from pathlib import Path
from fnmatch import fnmatchcase
import re
import hashlib
import zipfile
import xml.etree.ElementTree as ET

module = Path(__file__).resolve().parents[2]
repo = module.parents[1]
public = ("USP_ListXlsxWorksheets", "USP_ReadXlsxWorksheetCells")
internal = ("USP_InternalXlsxRead", "TVF_InternalXlsxSheets", "TVF_InternalXlsxCells")
type_public = "TVF_InterpretXlsxCell"
type_internal = "TVF_InternalInterpretXlsxCell"
for name in public:
    source = (module / "Source" / (name + ".sql")).read_text(encoding="utf-8-sig")
    for token in ("-- Objekt:", "-- Parameter:", "-- Resultset:", "-- Fehlerverhalten:",
                  "-- Performance:", "SET NOCOUNT ON", "@Hilfe bit = 0",
                  "DECLARE @Empty TABLE", "LOWER(LEFT(@ResultTable COLLATE Latin1_General_100_BIN2",
                  "EXEC toolbelt_file.USP_InternalXlsxRead"):
        assert token in source, (name, token)
    assert "CREATE TABLE #" not in source, "Private Temp-DDL gehÃ¶rt hinter die Compilergrenze."
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
assert sorted(n.attrib["Include"] for n in project.findall(".//m:Compile", ns)) == ["AssemblyInfo.cs", "Workbook.cs", "XlsxCellDisplay.cs", "XlsxCellDisplayBridge.cs", "XlsxCellType.cs", "XlsxEntryPoints.cs"]
assert sorted(n.attrib["Include"] for n in project.findall(".//m:Reference", ns)) == ["System", "System.Data", "System.Xml", "Toolbelt.Archive.ZipMemory"]
deploy = (module / "Deployment/Deploy.sql").read_text(encoding="utf-8-sig")
uninstall = (module / "Deployment/Uninstall.sql").read_text(encoding="utf-8-sig")
for script in (deploy, uninstall):
    assert script.index("IF @@TRANCOUNT<>0") < script.index("SET NOCOUNT ON") < script.index("SET XACT_ABORT ON")
    assert "RAISERROR(N'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:" in script and "RETURN;" in script
assert "HelpContractVersion varchar(16) NOT NULL DEFAULT" in core
assert "SchemaName sysname NOT NULL DEFAULT" in core and "ObjectName sysname NOT NULL DEFAULT" in core
for name in public + internal + (type_public, type_internal, "TVF_FormatXlsxCell", "TVF_InternalFormatXlsxCell"):
    assert "../Source/" + name + ".sql" in deploy and name in uninstall, name
for token in ("HASHBYTES('SHA2_512'", "permission_set=1", "sys.sp_getapplock", "sys.assembly_references", "CONVERT(varbinary(max)"):
    assert token in deploy, token
for token in ("sp_configure", "TRUSTWORTHY ON", "GRANT ", "WITH OVERRIDE"):
    assert token not in deploy and token not in uninstall, token
assert "ZipProviderException" not in provider, "Keine Kopplung an privaten ZIP-Fehlertyp."
assert not (repo / "Spikes/XlsxMemory/XlsxQualification.cs").exists(), "Kein duplizierter Workbookkern."
typed = (module / "Clr/XlsxCellType.cs").read_text(encoding="utf-8-sig")
wrapper = (module / "Source/TVF_InterpretXlsxCell.sql").read_text(encoding="utf-8-sig")
binding = (module / "Source/TVF_InternalInterpretXlsxCell.sql").read_text(encoding="utf-8-sig")
for token in ("DataAccess = DataAccessKind.None", "SystemDataAccess = SystemDataAccessKind.None", "SqlChars", "new SqlDecimal", "whole == 60", "262144", "65536", "Discard(3)"):
    assert token in typed, token
for token in ("File.", "Directory.", "Process.", "IsolatedStorage", "WebClient", "SqlConnection", "catch (Exception", "System.Decimal", "double "):
    assert token not in typed, token
assert "ISNULL(r.StatusCode,11)" in wrapper and wrapper.count("r.StatusCode IS NOT NULL") == 13
assert "RETURNS TABLE" in binding and "StatusCode int NULL" in binding
for text in (deploy, uninstall):
    for token in ("WHILE @Phase<2", "CONVERT(varbinary(max),N'1.0.0')", "CONVERT(varbinary(max),N'1.1.0')", "CONVERT(varbinary(max),N'1.2.0')", "FirstRelease", "s.Kind='FT'", "assembly_method", "s.FirstRelease<=@Release"):
        assert token in text, token
    for token in ("HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')", "HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT')", "THROW 51535,N'Vollständige Sicht auf SQL-Abhängigkeiten ist erforderlich.',2"):
        assert token in text, token
assert "ExpectedInstalledAssemblyHash" not in deploy and "ExpectedInstalledAssemblyHash" not in uninstall
# Anzeige nutzt ausschlieÃŸlich den unverÃ¤nderten Typkern und zehn Literalformate.
display = (module / 'Clr/XlsxCellDisplay.cs').read_text(encoding='utf-8-sig')
bridge = (module / 'Clr/XlsxCellDisplayBridge.cs').read_text(encoding='utf-8-sig')
formats = re.findall(r'case "([^"]+)":', display.split('private static bool RoundSeconds')[0])
assert set(formats) == {'0','0.00','#,##0.00','0%','0.00%','0.00E+00','yyyy-mm-dd','yyyy-mm-dd hh:mm:ss','hh:mm:ss','@'}
assert len(formats) == 10
for token in ('XlsxCellType.Evaluate', 'value.Data', 'typed.Status != 0', '262144', '65536', '"en-US"', '"de-DE"', '"tr-TR"'):
    assert token in display
for token in ('File.', 'Directory.', 'Process.', 'SqlConnection', 'double ', 'decimal ', 'value.Value', 'CurrentCulture', 'catch (Exception'):
    assert token not in display
assert bridge.index('if (Length(stored)') < bridge.index('XlsxCellDisplay.Evaluate(Copy(stored)')
assert 'out SqlChars display, out SqlInt32 status' in bridge
for name in ('Deploy.sql', 'Uninstall.sql'):
    lifecycle = (module / 'Deployment' / name).read_text(encoding='utf-8-sig')
    assert "(N'TVF_InternalFormatXlsxCell','FT',12" in lifecycle
    assert "(N'TVF_FormatXlsxCell','IF',12" in lifecycle
assert 'IF @Release>=12' in uninstall and 'IF @Release>=11' in uninstall
assert hashlib.sha256((module / 'Clr/XlsxCellType.cs').read_bytes()).hexdigest().upper() == '564162B8C6FEF1145842E92A6CEEF2F8478BCBE8D30FE4BCE360A160D659A300'

# Reproduzierbarer Adapter: konsumierte Kompositionsdateien mÃ¼ssen seinen festen Pins entsprechen.
driver = (repo / 'Tests/CI/run-xlsx-types-lab.ps1').read_text(encoding='utf-8-sig')
for filename in ('Invoke-TypesComposition.ps1', 'Types.Composition.sql', 'Types.Composition.xlsx'):
    path = module / 'Tests/Runtime' / filename
    digest = hashlib.sha256(path.read_bytes()).hexdigest().upper()
    assert "'" + filename + "'='" + digest + "'" in driver, filename
helper = (module / 'Tests/Runtime/Invoke-TypesComposition.ps1').read_text(encoding='utf-8-sig')
assert '$sqlBytes=[IO.File]::ReadAllBytes($sqlFile)' in helper
assert '[Text.UTF8Encoding]::new($false,$true).GetString($sqlBytes)' in helper
assert r"(?m)^ COMMIT TRANSACTION;\r?$" in driver
assert '$text.Insert($matches[0].Index' in driver
assert 'XLSX_DOOM_CALLER_WITNESS_MISSING' in driver
for filename in ('Invoke-DisplayComposition.ps1', 'Display.Composition.sql'):
    digest = hashlib.sha256((module / 'Tests/Runtime' / filename).read_bytes()).hexdigest().upper()
    assert "'" + filename + "'='" + digest + "'" in driver
assert "Version='1.2.0';Label='current'" in driver
assert "@('clean','genuine1.0','genuine1.1')" in driver
assert "Count -ne 20" in driver
assert "'Scripts/Invoke-XlsxBuildProcess.ps1'" in driver
assert 'Display.Metadata.ps1' in driver
assert 'Legacy11Directory' in driver and 'ExpectedLegacy11ProvenanceSHA256' in driver
for token in ('workMilliseconds=960000L', 'totalMilliseconds=1200000L',
              'CommandTimeout=Get-XlsxCommandTimeout', 'Invoke-XlsxOwnSql',
              'XLSX_PREEXISTING_TRUST_CHANGED', 'Assert-XlsxDisposition',
              'XLSX_FINAL_DISPOSITION_REQUIRED'):
    assert token in driver, token
for filename in ('Types.Metadata.ps1', 'Display.Metadata.ps1',
                 'Invoke-TypesComposition.ps1', 'Invoke-DisplayComposition.ps1'):
    helper_text = (module / 'Tests/Runtime' / filename).read_text(encoding='utf-8-sig')
    assert '[scriptblock]$CommandTimeoutProvider' in helper_text
    assert '[scriptblock]$ReadBudgetProvider' in helper_text
    assert '$command.CommandTimeout=& $CommandTimeoutProvider' in helper_text
release_text = (module / 'Scripts/New-ClrReleaseArtifacts.ps1').read_text(encoding='utf-8-sig')
assert 'Invoke-OwnedProcess' in release_text and "'/m:1') 120000" in release_text
assert "'MSBuild/**/Bin/MSBuild.exe') 20000" in release_text and 'Assert-ReleaseTools' in release_text
assert '& $msbuild.Source' not in release_text and '& $vswhere' not in release_text
with zipfile.ZipFile(module / 'Tests/Runtime/Types.Composition.xlsx') as fixture:
    assert len(fixture.infolist()) == 6
    assert all(i.compress_type == zipfile.ZIP_STORED and i.date_time == (2000, 1, 1, 0, 0, 0) for i in fixture.infolist())
    worksheet = ET.fromstring(fixture.read('xl/worksheets/sheet1.xml'))
    cells = worksheet.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c')
    assert len(cells) == 9 and any(c.attrib['r'] == 'XFD1048576' for c in cells)
# DirectoryBuild-Hooks ohne Exists-Bedingung mÃ¼ssen global leer gebunden werden.
build_helper = (module / 'Scripts/Invoke-XlsxBuildProcess.ps1').read_text(encoding='utf-8-sig')
empty_hooks = "@('CustomBeforeDirectoryBuildProps','CustomAfterDirectoryBuildProps','CustomBeforeDirectoryBuildTargets','CustomAfterDirectoryBuildTargets')"
assert build_helper.count(empty_hooks) == 2
assert "$properties.Add('/p:'+$name+'=')" in build_helper
assert "$expected.Add('/p:'+$name+'=')" in build_helper
absent_hooks = "@('CustomBeforeMicrosoftCommonProps','CustomAfterMicrosoftCommonProps','CustomBeforeMicrosoftCommonTargets','CustomAfterMicrosoftCommonTargets','CustomBeforeMicrosoftCSharpTargets','CustomAfterMicrosoftCSharpTargets')"
assert build_helper.count(absent_hooks) == 2
assert "$properties.Add('/p:'+$name+'='+$absent)" in build_helper
assert "$expected.Add('/p:'+$name+'='+$Control.Absent)" in build_helper
# NuGet-Verzeichnisimporte bleiben global deaktiviert und frisch abgewiesen.
package_flags = "@('ImportDirectoryBuildProps','ImportDirectoryBuildTargets','ImportProjectExtensionProps','ImportProjectExtensionTargets','ImportDirectoryPackagesProps')"
assert build_helper.count(package_flags) == 2
assert "'Directory.Packages.props'" in build_helper
# CI must consume the same packaged DLLs; no second provider build or core-only substitute.
candidate = (module / 'Tests/Framework/Invoke-CandidateQualification.ps1').read_text(encoding='utf-8-sig')
packaging = (module / 'Tests/Framework/Invoke-CandidatePackaging.ps1').read_text(encoding='utf-8-sig')
workflow = (repo / '.github/workflows/xlsx-memory-qualification.yml').read_text(encoding='utf-8-sig')
# Die echte Uploadauswahl gegen Releaseinputs und private Sentinels prüfen.
# Für den erlaubten Literalpfad-Teilumfang ist keine YAML-/Globdependency nötig.
upload_marker = '      - uses: actions/upload-artifact@v4\n'
assert workflow.count(upload_marker) == 1, 'XLSX_UPLOAD_STEP_COUNT'
upload = workflow.split(upload_marker, 1)[1].split('\n      - ', 1)[0]
assert re.findall(r'^          name: (.+)$', upload, re.M) == ['xlsx-qualified-release-input']
assert re.findall(r'^          if-no-files-found: (.+)$', upload, re.M) == ['error']
path_values = re.findall(r'^          path: (.*)$', upload, re.M)
assert len(path_values) == 1, 'XLSX_UPLOAD_PATH_COUNT'
upload_paths = (re.findall(r'^            (.+)$', upload.split('          path: |\n', 1)[1], re.M)
                if path_values[0] == '|' else path_values)
upload_root = '${{ env.XLSX_PACKAGE_ROOT }}/'
assert all(path.startswith(upload_root) for path in upload_paths), 'XLSX_UPLOAD_ROOT'
upload_patterns = [path[len(upload_root):] for path in upload_paths]
release_inputs = set()
for directory, assembly in (
    ('zip', 'Toolbelt.Archive.ZipMemory'),
    ('xlsx', 'Toolbelt.File.XlsxMemory'),
    ('zip13/artifacts', 'Toolbelt.Archive.ZipMemory'),
    ('xlsx10/original/Modules/toolbelt.file.xlsx-memory/Artifacts', 'Toolbelt.File.XlsxMemory'),
    ('xlsx11/original/Modules/toolbelt.file.xlsx-memory/Artifacts', 'Toolbelt.File.XlsxMemory'),
):
    release_inputs.update(directory + '/' + name for name in
                          (assembly + '.dll', assembly + '.trust-manifest.json', 'Deploy.WithAssembly.sql'))
private_sentinels = {
    'qualification/CompileTypes.argv.json', 'qualification/RunEvidence.json',
    'qualification/CompileTypes.stdout.txt', 'qualification/CompileTypes.stderr.txt',
    'qualification/CompileTypes.process.json', 'qualification/Bin/Toolbelt.File.XlsxMemory.dll',
    'PackagingEvidence.json', 'zip.stdout.txt', 'xlsx.stderr.txt',
    'zip13/Build.stdout.txt', 'zip13/Build.process.json',
    'xlsx10/original/Modules/toolbelt.file.xlsx-memory/Clr/bin/Release/provider.pdb',
    'xlsx11/LegacyProvenance.json', 'future-root-file.json',
}
for fixture in (release_inputs, release_inputs | private_sentinels,
                release_inputs | {path + '.argv.json' for path in release_inputs}):
    selected = {path for path in fixture if any(fnmatchcase(path, pattern) for pattern in upload_patterns)}
    assert selected == release_inputs, 'XLSX_UPLOAD_SELECTION_BOUNDARY'
assert len(upload_patterns) == len(set(upload_patterns)) == 15, 'XLSX_UPLOAD_LITERAL_COUNT'
assert set(upload_patterns) == release_inputs, 'XLSX_UPLOAD_RELEASE_INPUTS'
assert not any(re.search(r'[*?\[\]!\\]', path) for path in upload_patterns), 'XLSX_UPLOAD_LITERAL_ONLY'
print('PASS XLSX_UPLOAD_BOUNDARY releaseinputs=15 privatesentinels=14 selectioncases=3')
forwarder = (repo / 'Spikes/XlsxMemory/Run-FrameworkQualification.ps1').read_text(encoding='utf-8-sig')
assert workflow.index('Invoke-CandidatePackaging.ps1 -OutputDirectory') < workflow.index('Run-FrameworkQualification.ps1 -XlsxDirectory')
assert 'Invoke-Types.ps1' not in workflow
assert 'run: ./Modules/toolbelt.file.xlsx-memory/Tests/Framework/Invoke-Display.ps1' not in workflow
assert 'Invoke-OwnedProcess' in packaging and '-TimeoutMilliseconds 120000' in packaging
assert 'ProcessStartInfo' not in packaging and 'ProcessStartInfo' not in candidate
assert '/t:Rebuild' not in candidate and '/t:Rebuild' not in forwarder
for token in ('RELEASE_MANIFEST_BINDING','RELEASE_SQL_HEX_BINDING','RELEASE_SOURCE_DRIFT',
              'Read-PinnedBytes','Check-Pins','ConvertTo-Json -InputObject $value',
              "@($record.phases).Count-ne19", 'Require-QuietCompiler',
              "PASS API=652 NUMERIC=370 ASSERTIONS=6437", 'PASS CASES=5619',
              'PASS TRANSPORT ASSERTIONS=55', 'PASS RAW EXISTING_ORACLE'):
    assert token in candidate, token
for filename, api in (('TypeCandidateHarness.cs','XlsxCellType.Interpret'),
                      ('DisplayCandidateHarness.cs','XlsxCellDisplayBridge.Evaluate')):
    text = (module / 'Tests/Framework' / filename).read_text(encoding='utf-8-sig')
    assert api in text and 'Fill' in text
assert "Compile 'CompileTypes' 'TypeHarness.exe' (Join-Path $bin 'TypeHarness.cs') 'exe'" in candidate
assert "Compile 'CompileDisplay' 'DisplayHarness.exe' (Join-Path $bin 'DisplayHarness.cs') 'exe'" in candidate
assert '$argv+=,$source;' in candidate
# Aktuelle Legacyadapter verwenden nur den gemeinsamen endlichen Prozesshelfer.
for filename, revision in (('New-Xlsx10LegacyFixture.ps1','fdafa8038e4d5240dd727096f144c8d5fd884117'),
                           ('New-Zip13LegacyFixture.ps1','677e68c269b084379143c058cad0f03baee1bf79')):
    legacy = (module / 'Scripts' / filename).read_text(encoding='utf-8-sig')
    assert revision in legacy
    assert 'ProcessStartInfo' not in legacy and 'ReadToEndAsync' not in legacy
    assert '& git ' not in legacy and '& pwsh ' not in legacy
    for token in ('Invoke-OwnedProcess','Pin-LegacyTool $PSCommandPath',
                  'LEGACY_HELPER_CAPTURE_DRIFT','Assert-LegacyPins',
                  'LEGACY_HELPER_FAILED_DISPOSITION_UNKNOWN',
                  'LegacySecondaryFailures','ConvertTo-Json -InputObject $receipt',
                  '$receipt.PostPins=$true', '$arguments 30000 $true', '60000 $false'):
        assert token in legacy, (filename, token)
    assert 'CaptureComplete=$false' in legacy and 'Disposed=$null' in legacy
print("PASS: XLSX struktureller Source-/Compiler-/Lifecycle-/Dependencyvertrag; keine Runtimebehauptung.")

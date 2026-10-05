"""Statischer CSV-Vertrag; kein Framework-, IL-, SQL- oder Performancenachweis."""
from pathlib import Path
import re

module = Path(__file__).resolve().parents[2]
public = ('USP_ParseCsv', 'USP_WriteCsv')
internal = ('TVF_InternalParseCsv', 'SVF_InternalMeasureCsvCell', 'SVF_InternalQuoteCsvCell')
sources = {name: (module / 'Source' / (name + '.sql')).read_text(encoding='utf-8-sig') for name in public + internal}
deploy = (module / 'Deployment/Deploy.sql').read_text(encoding='utf-8-sig')
uninstall = (module / 'Deployment/Uninstall.sql').read_text(encoding='utf-8-sig')
preflight = (module / 'Deployment/Preflight.sql').read_text(encoding='utf-8-sig')
markers = (module / 'Deployment/MarkRelease.sql').read_text(encoding='utf-8-sig')
trust = (module / 'Deployment/Add-TrustedAssembly.sql').read_text(encoding='utf-8-sig')
for name in public + internal:
    assert ':r ../Source/' + name + '.sql' in deploy, name
    assert name in preflight and name in markers, name
assert deploy.count('$(AssemblyBits)') == 1
assert 'WHILE @Phase<2' in preflight
assert preflight.index('IF @@TRANCOUNT<>0') < preflight.index('SET NOCOUNT ON') < preflight.index('SET XACT_ABORT ON')
assert 'RAISERROR' in preflight and 'RETURN;' in preflight
assert 'TBX_CSV_LIFECYCLE_CALLER_TRANSACTION:' in uninstall
for token in ('sys.sql_expression_dependencies', 'sys.assembly_references', 'sys.sp_getapplock',
              'Toolbelt.Module.toolbelt.core.result-table.Version', 'permission_set=1',
              'SQL_VARIANT_PROPERTY', 'assembly_class', 'assembly_method', 'null_on_null_input=0',
              "N'Toolbelt.Csv.CsvEntryPoints'", 'ROLLBACK TRANSACTION', 'CONVERT(varbinary(max)'):
    assert token in preflight, token
assert 'sys.parameters' in preflight and 'sys.columns' in preflight
assert 'p.user_type_id<>p.system_type_id' in preflight and 'c.is_nullable<>1' in preflight
assert sorted(p.stem for p in (module / 'Source').glob('*.sql')) == sorted(public + internal)
assert 'COMMIT TRANSACTION' in markers and 'ROLLBACK TRANSACTION' in markers
for lifecycle in (preflight, markers, deploy, uninstall):
    for forbidden in ('TRUSTWORTHY ON', 'sp_configure', 'GRANT ', 'RECONFIGURE', 'sp_add_trusted_assembly'):
        assert forbidden not in lifecycle, forbidden
assert 'sys.sp_add_trusted_assembly' in trust
assert 'DATALENGTH(@Text)<>260' in trust and 'DATALENGTH(TRY_CONVERT(varbinary(max),@Text,1))<>64' in trust
assert not re.search(r'THROW\s+(?!553[24]\d\b)\d+', preflight + markers + uninstall + trust)
for name in public:
    text = sources[name]
    for token in ('@Hilfe', '@Debug', '@ResultTable', '@KeepData', 'USP_PrepareResultTable'):
        assert token in text, (name, token)
    assert 'AS EXTERNAL NAME' not in text
for name, method in zip(internal, ('Parse', 'MeasureCell', 'QuoteCell')):
    assert 'AS EXTERNAL NAME' in sources[name] and 'CsvEntryPoints' in sources[name] and method in sources[name]
parser = sources['TVF_InternalParseCsv']
for column in ('RowKind', 'RowOrdinal', 'ColumnOrdinal', 'Value', 'ErrorCode'):
    assert column in parser
assert 'NOT NULL' not in re.sub(r'--[^\n]*', '', parser)
package = (module / 'Scripts/New-ClrReleaseArtifacts.ps1').read_text(encoding='utf-8-sig')
for token in ('sha256=$sha256', 'sha512=$sha512', 'DirectorySeparatorChar', 'CSV_RELEASE_OUTPUT_NOT_EMPTY',
              'CSV_RELEASE_INPUT_OUTPUT_ALIAS', '[IO.FileMode]::CreateNew', 'CSV_RELEASE_SOURCE_SET_CHANGED',
              'CSV_RELEASE_BINARY_SNAPSHOT_PIN', 'CSV_RELEASE_INPUT_CHANGED', 'Expand-CsvDeploy'):
    assert token in package, token
assert package.index('CSV_RELEASE_INPUT_OUTPUT_ALIAS') < package.index('New-Item -ItemType Directory -Path $output')
print('PASS: CSV static lifecycle/public/internal/trust contracts; runtime not established.')

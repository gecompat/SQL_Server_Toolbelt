"""Scopebezogene synthetische JSON-Vertrags-/Kopplungsprüfung."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[2]
legacy = (root/'Deployment/New-LegacyTestArtifacts.ps1').read_text(encoding='utf-8')
assert "$treePaths=@($expected|ForEach-Object{$modulePath+$_})" in legacy
assert "Read-GitBytes (@('ls-tree','--full-tree','-r','-z',$revision)+$treePaths)" in legacy
assert "($modulePath+'Deployment'),($modulePath+'Source')" not in legacy
assert (root/'Tests/Static/Test-LegacyTree.ps1').exists()
names = ['USP_JsonArray', 'USP_JsonObject', 'USP_JsonArraysByGroup', 'USP_JsonObjectsByGroup', 'USP_JsonConstructInternal']
for name in names:
    text = (root / 'Source' / (name + '.sql')).read_text(encoding='utf-8')
    assert 'CREATE OR ALTER PROCEDURE toolbelt_json.' + name in text
    assert '@Hilfe' in text and 'HelpContractVersion' in text
    assert '@ResultTable' in text and '@KeepData' in text
    assert (root / 'Documentation' / (name + '.md')).exists()
    if name != 'USP_JsonConstructInternal':
        expected = [('EntriesTable', 'sysname', 'NULL'), ('MaxEntries', 'int', '10000'),
                    ('MaxTotalValueBytes', 'bigint', '2097152'), ('MaxResultBytes', 'bigint', '2097152'),
                    ('ResultTable', 'sysname', 'NULL'), ('KeepData', 'bit', '0'),
                    ('Debug', 'tinyint', '0'), ('Hilfe', 'bit', '0')]
        for parameter, data_type, default in expected:
            assert re.search(r'^\s*@' + parameter + r'\s+' + data_type + r'\s*=\s*' + default + r'\s*[,\n]', text, re.M), parameter
core = (root / 'Source/USP_JsonConstructInternal.sql').read_text(encoding='utf-8')
for marker in ['STRING_AGG', 'WITHIN GROUP', 'FT_JsonEntryEvaluateInternal', 'DATALENGTH',
               'Latin1_General_100_BIN2', '53607', 'SAVE TRANSACTION',
               'XACT_STATE()=1', 'USP_PrepareResultTable', 'tempdb.sys.columns']:
    assert marker in core, marker
assert 'INSERT EXEC' not in core and 'TRUSTWORTHY' not in core
deploy = (root / 'Deployment/Deploy.sql').read_text(encoding='utf-8')
uninstall = (root / 'Deployment/Uninstall.sql').read_text(encoding='utf-8')
for name in names:
    assert '../Source/' + name + '.sql' in deploy
    assert name in uninstall
assert '1.1.0' in deploy and '1.1.0' in uninstall
assert 'JSON_LIFECYCLE_CALLER_TRANSACTION:' in deploy and 'JSON_LIFECYCLE_CALLER_TRANSACTION:' in uninstall
assert 'toolbelt_string' not in deploy + uninstall
assert "CONVERT(varbinary(2),o.type)=CONVERT(varbinary(2),s.Kind)" in deploy
assert "CONVERT(varbinary(2),o.type)=CONVERT(varbinary(2),s.Kind)" in uninstall
assert "Release-Ownership ist inkohärent" in deploy
for relative in ['Tests/Runtime/JsonConstructors.Contract.sql', 'Tests/Runtime/Lifecycle.Contract.sql',
                 'Tests/Runtime/Central.Contract.sql', 'Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md',
                 'Tests/README.md', 'README.md', 'module.yaml']:
    assert (root / relative).exists(), relative
# Der frühere Parser wird vollständig durch den gemeinsamen qualifizierten Kern ersetzt.
# Beide unveränderten globalen SQL-Abschnitte behalten die Legacypriorität und das Routing.
import subprocess, json, hashlib, struct
base = 'f64ee9eb8f6a7f66fd441821c7c40fcf2d92ee1e'
relative = 'Modules/toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql'
old = subprocess.check_output(['git','show',f'{base}:{relative}'],cwd=root.parents[1]).decode('utf-8').replace('\r\n','\n')
assert core.split(' CREATE TABLE #tbx_JsonConstructor_Fragments',1)[0] == old.split(' CREATE TABLE #tbx_JsonConstructor_Fragments',1)[0]
assert core.split(' CLOSE Entries; DEALLOCATE Entries;',1)[1] == old.split(' CLOSE Entries; DEALLOCATE Entries;',1)[1]
assert 'STRING_ESCAPE' not in core and '-- UTF-16-Codeeinheiten' not in core
assert core.count('FROM toolbelt_json.FT_JsonEntryEvaluateInternal(')==1
assert core.index('SELECT @Stage=0') < core.index('IF ISJSON(@Value)<>1') < core.index('SET @Stage+=1')
assert "IF @Stage=0 AND @Kind=N'json'" in core
assert core.count("IF ISJSON(@Value)<>1 THROW 53608,N'JSON: Fragment muss vollständiges Objekt oder Array sein.',2;")==1
for item in ('COUNT_BIG(*) FROM @Entry)<>1','StrongMinimumBytes<>@ExpectedStrong','FragmentBytes<>DATALENGTH(Fragment)','THROW 53611'):
    assert item in core,item
registry=json.loads((root/'Documentation/KNOWN_CLR_ARTIFACTS.json').read_text(encoding='utf-8'))
assert registry['status']=='OFFLINE_QUALIFIED_KNOWN_ARTIFACT'
assert len(registry['artifacts'])==1 and len(registry['fieldOrder'])==34
row=registry['artifacts'][0];fields=row['Fields']
assert set(fields)==set(registry['fieldOrder']) and len(set(registry['fieldOrder']))==34
frame=b'TBXJSONART1'+struct.pack('<I',34)
for name in registry['fieldOrder']:
    for text in (name,fields[name]):
        assert isinstance(text,str)
        data=text.encode('utf-8');frame+=struct.pack('<I',len(data))+data
assert len(frame)==2824 and hashlib.sha256(frame).hexdigest()==row['ArtifactId']
for name,digest in fields.items():
    if name.startswith('source/'):
        assert hashlib.sha256((root/'Clr'/name[7:]).read_bytes()).hexdigest()==digest,name
known=(root/'Deployment/KnownArtifact.sql').read_text(encoding='utf-8')
assert fields['binarySha512'].upper() in known and row['ArtifactId'] in known
preflight=(root/'Deployment/ClrPreflight.sql').read_text(encoding='utf-8')
for item in ('SQL_VARIANT_PROPERTY','sys.assembly_files','sys.assembly_modules','sys.assembly_references','@Parameters','@Columns','@EffectiveOwner'):
    assert item in preflight,item
assert deploy.count(':r ./ClrPreflight.sql')==2 and uninstall.count(':r ./ClrPreflight.sql')==1
assert deploy.index('IF @@TRANCOUNT>0')<deploy.index('SET NOCOUNT')<deploy.index('BEGIN TRANSACTION')
assert uninstall.index('IF @@TRANCOUNT>0')<uninstall.index('SET NOCOUNT')<uninstall.index('BEGIN TRANSACTION')
assert 'CREATE ASSEMBLY' in deploy and 'DROP ASSEMBLY' in uninstall
assert not re.search(r'(?im)^\s*(GRANT|DENY|REVOKE|ALTER AUTHORIZATION)\b',deploy+uninstall+preflight)
assert '@MaxResultBytes bigint=NULL,@GroupMode bit=0,@ResultTable' in core
assert 'GROUP BY GroupOrdinal,Ordinal' in core
assert 'GROUP BY GroupOrdinal,CONVERT(varbinary(2048),[Key]),DATALENGTH([Key])' in core
assert 'ORDER BY GroupOrdinal,Ordinal' in core
assert '4*@PreGroups+2*(@PreCount-@PreGroups)' in core
assert core.count('CREATE TABLE #tbx_JsonConstructor_GroupResult(')==1
for name in names[:-1]:
    text=(root/'Source'/f'{name}.sql').read_text(encoding='utf-8')
    assert '#tbx_JsonConstructor_GroupResult' in text
    if name.endswith('ByGroup'): assert '@GroupMode=1' in text
for relative in ('JsonGroups.Contract.sql','JsonGroups.Boundaries.sql','InstalledMetadata.Contract.sql'):
    assert (root/'Tests/Runtime'/relative).exists()
print('JSON Constructors Static: source/contract/lifecycle coupling PASS (no runtime evidence).')

# Metadatensichtbarkeit ist eine Voraussetzung, keine Berechtigungserteilung.
metadata_gate = "  IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1\n   OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1\n   THROW 53622,N'JSON lifecycle: erforderliche Metadatenrechte für Uninstall fehlen.',1;"
assert metadata_gate in uninstall
assert uninstall.index('WHILE @Pass<2') < uninstall.index(metadata_gate) < uninstall.index('FROM sys.sql_expression_dependencies') < uninstall.index('BEGIN TRANSACTION')
assert uninstall.index('SET @Pass+=1') < uninstall.index('SET @Id=@Count')
assert not re.search(r'(?im)^\s*(GRANT|DENY|REVOKE)\b', uninstall)
for view in (None, 0, 1):
    for select in (None, 0, 1):
        rejects = (0 if view is None else view) != 1 or (0 if select is None else select) != 1
        assert rejects == (view != 1 or select != 1)
print('JSON Uninstall metadata gate: both-pass ordering/NULL rejection/no rights changes PASS (static only).')

ci = (root.parents[1] / 'Tests/CI/run-json-constructors-linux.sh').read_text(encoding='utf-8')
assert 'for permission in view select;' in ci and 'for injected in 0 NULL;' in ci
assert 'CASE WHEN @Pass=1 THEN {value} ELSE {expression} END' in ci
assert 'expect_failure 53622 run_uninstall_metadata_injection' in ci

# Die sechs sql_variant-Marker bewahren die bereits festgelegten Basistypen.
marker_insert = deploy.split(' INSERT @AssemblyMarkers VALUES', 1)[1].split(' WHILE @MarkerId<=6', 1)[0]
for expression in ('CONVERT(int,1)', '@ModuleIdValue', '@ModuleVersionValue', '@ModeValue', '@KnownHash', '@ArtifactValue'):
    assert marker_insert.count('CONVERT(sql_variant,' + expression + ')') == 1
assert marker_insert.count('CONVERT(sql_variant,') == 6
framework = (root/'Tests/Framework/Invoke-Framework.ps1').read_text(encoding='utf-8')
assert "@(('/reference:'+$dll),(Join-Path $PSScriptRoot 'ProductHarness.cs'))" in framework
# Wirklichen eingebetteten CI-Pythontext mit synthetischer Source statt SQL ausführen.
# Nur der fest bezeichnete Uninstallblock darf sich ändern; die weiteren Gates bleiben gleich.
import io, contextlib, sys
from unittest.mock import patch
injection = 'from pathlib import Path\n' + ci.split('\nfrom pathlib import Path\n', 1)[1].split('\nPYSQL', 1)[0]
expanded = uninstall.replace(':r ./KnownArtifact.sql', known).replace(':r ./ClrPreflight.sql', preflight)
original_argv = sys.argv
try:
    for permission, expression in (('view', "HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')"),
                                   ('select', "HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT')")):
        assert expanded.count(expression) == 3
        for value in ('0', 'NULL'):
            sys.argv = ['synthetic', permission, value]
            capture = io.StringIO()
            with patch.object(Path, 'read_text', return_value=expanded), contextlib.redirect_stdout(capture):
                exec(compile(injection, '<synthetic-ci-injection>', 'exec'), {})
            expected = expanded.replace(metadata_gate, metadata_gate.replace(expression, f'CASE WHEN @Pass=1 THEN {value} ELSE {expression} END')).replace('$(ConfirmNoExternalConsumers)', '0')
            assert capture.getvalue() == expected + '\n'
            assert expected.count(f'CASE WHEN @Pass=1 THEN {value} ELSE {expression} END') == 1
finally:
    sys.argv = original_argv
print('JSON narrow fixes: six typed markers/byte types/argv/four scoped injection controls PASS (no SQL).')

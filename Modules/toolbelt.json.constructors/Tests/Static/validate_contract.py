"""Scopebezogene synthetische JSON-Vertrags-/Kopplungsprüfung."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[2]
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
for marker in ['STRING_AGG', 'WITHIN GROUP', 'STRING_ESCAPE', 'DATALENGTH',
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
assert "AND o.type='P'" in deploy
assert "Release-Ownership ist inkohärent" in deploy
for relative in ['Tests/Runtime/JsonConstructors.Contract.sql', 'Tests/Runtime/Lifecycle.Contract.sql',
                 'Tests/Runtime/Central.Contract.sql', 'Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md',
                 'Tests/README.md', 'README.md', 'module.yaml']:
    assert (root / relative).exists(), relative
# Der unveränderte Scannerblock ist die einzige fachliche Unicode-/Literalimplementierung.
import subprocess
base = '435340a25b10ef5dccd60bf892727bd7e4e45be6'
relative = 'Modules/toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql'
old = subprocess.check_output(['git', 'show', f'{base}:{relative}'], cwd=root.parents[1]).decode('utf-8').replace('\r\n','\n')
start='  -- UTF-16-Codeeinheiten';end='  INSERT #tbx_JsonConstructor_Fragments'
assert core.split(start,1)[1].split(end,1)[0] == old.split(start,1)[1].split(end,1)[0]
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
assert uninstall.index('WHILE @Pass<2') < uninstall.index(metadata_gate) < uninstall.index('FROM sys.sql_expression_dependencies') < uninstall.index('IF @Pass=0')
assert uninstall.index('SET @Pass+=1') < uninstall.index('DROP PROCEDURE')
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

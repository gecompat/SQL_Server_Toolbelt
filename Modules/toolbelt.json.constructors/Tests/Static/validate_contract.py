"""Scopebezogene synthetische JSON-Vertrags-/Kopplungsprüfung."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[2]
names = ['USP_JsonArray', 'USP_JsonObject', 'USP_JsonConstructInternal']
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
assert '1.1.0' not in deploy + uninstall
assert 'toolbelt_string' not in deploy + uninstall
assert "WHEN objects.type IN ('FN', 'FS', 'FT', 'IF', 'TF')" in deploy
assert "AND objects.type IN ('P', 'PC', 'V', 'FN', 'FS', 'FT', 'IF', 'TF')" in deploy
for relative in ['Tests/Runtime/JsonConstructors.Contract.sql', 'Tests/Runtime/Lifecycle.Contract.sql',
                 'Tests/Runtime/Central.Contract.sql', 'Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md',
                 'Tests/README.md', 'README.md', 'module.yaml']:
    assert (root / relative).exists(), relative
print('JSON Constructors Static: source/contract/lifecycle coupling PASS (no runtime evidence).')

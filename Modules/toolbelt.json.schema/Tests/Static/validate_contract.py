"""Source-/Closure-/Lifecyclekopplung; kein nativer SQL-Nachweis."""
from pathlib import Path
import hashlib
import json
import re
import struct
import xml.etree.ElementTree as ET

repo = Path(__file__).resolve().parents[4]
modules = repo / 'Modules'
registry = json.loads((modules / 'toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json').read_text(encoding='utf-8'))
assert registry['framing'] == 'toolbelt.json.shared-closure/v1'
assert registry['framePrefix'] == 'TBXJSONCLOSURE1'
assert len(registry['artifacts']) == 3
rows = {}
for row in registry['artifacts']:
    fields, order = row['Fields'], row['fieldOrder']
    assert set(order) == set(fields) and len(set(order)) == len(order)
    frame = b'TBXJSONCLOSURE1' + struct.pack('<I', len(order))
    for name in order:
        for text in (name, fields[name]):
            value = text.encode('utf-8')
            frame += struct.pack('<I', len(value)) + value
    assert hashlib.sha256(frame).hexdigest() == row['ArtifactId']
    root = modules / fields['moduleId']
    project = root / 'Clr' / (fields['managedAssembly'] + '.csproj')
    assert hashlib.sha256(project.read_bytes()).hexdigest() == fields['projectSha256']
    compiled = [item.attrib['Include'].replace('\\', '/') for item in ET.parse(project).iter() if item.tag.endswith('}Compile')]
    sources = [name[7:] for name in fields if name.startswith('source/')]
    assert set(compiled) == set(sources) and len(compiled) == len(sources)
    for source in sources:
        assert hashlib.sha256((root / 'Clr' / source).read_bytes()).hexdigest() == fields['source/' + source]
    known = root / 'Deployment' / ('KnownArtifact1_3.sql' if fields['moduleId'].endswith('constructors') else 'KnownArtifact.sql')
    known_text = known.read_text(encoding='utf-8')
    assert fields['binarySha512'].lower() in known_text.lower() and row['ArtifactId'] in known_text
    for action in ('Deploy', 'Uninstall'):
        text = (root / 'Deployment' / (action + '.sql')).read_text(encoding='utf-8')
        assert text.index('IF @@TRANCOUNT>0') < text.index('SET NOCOUNT') < text.index('BEGIN TRANSACTION')
        assert 'WHILE @Pass<2' in text and 'toolbelt.deploy.json.shared-core' in text
        if action == 'Uninstall':
            assert re.search(r'DROP ASSEMBLY \[Toolbelt_Json\w+\] WITH NO DEPENDENTS;', text)
        assert not re.search(r'(?im)^\s*(GRANT|DENY|REVOKE|ALTER AUTHORIZATION|RECONFIGURE|EXEC\s+.*sp_add_trusted_assembly)\b', text)
    rows[fields['moduleId']] = row
assert len(rows) == 3
for module in ('toolbelt.json.constructors', 'toolbelt.json.schema'):
    assert rows[module]['Fields']['coreArtifactId'] == rows['toolbelt.json.core']['ArtifactId']
core_clr = '\n'.join(path.read_text(encoding='utf-8') for path in (modules / 'toolbelt.json.core/Clr').rglob('*.cs'))
assert '[SqlFunction' not in core_clr and '[SqlProcedure' not in core_clr
assert 'class JsonSyntaxScanner' in core_clr
assert not (modules / 'toolbelt.json.constructors/Clr/AgfCore.cs').exists()
schema = (modules / 'toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql').read_text(encoding='utf-8')
assert schema.index('IF @Hilfe=1') < schema.index('THROW 55600')
assert 'INSERT EXEC' not in schema
assert 'Latin1_General_100_BIN2' in schema and 'SAVE TRANSACTION' in schema
assert schema.count('FROM toolbelt_json.FT_ValidateJsonSchemaInternal(') == 1
assert 'XACT_STATE()=1' in schema and '55601' in schema
print('PASS JSON_SHARED_CLOSURE_STATIC_ONLY')

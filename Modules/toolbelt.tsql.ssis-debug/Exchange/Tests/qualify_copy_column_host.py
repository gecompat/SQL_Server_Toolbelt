"""Aktueller Copy-Column-Modellhost: Plattformvergleich ohne SQL oder SSIS-Runtime."""
from pathlib import Path
import argparse
import json
import os
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
import qualify_host as base

METHOD = base.MODULE / 'Exchange/Tests/qualify_copy_column_host.py'
FIXTURES = tuple(base.MODULE / f'Tests/Fixtures/copy-column-{v}-{kind}.dtsx'
                 for v in (6, 8) for kind in ('int', 'text'))
DTS = '{www.microsoft.com/SqlServer/Dts}'


def source_pins(root):
    pins = base.source_pins(root)
    for p in (METHOD, *FIXTURES):
        pins[p.as_posix()] = base.sha((root / p).read_bytes())
    return pins


def qualify(root, host, dotnet, expected_platform, source_commit):
    if not re.fullmatch('[0-9a-f]{40}', source_commit):
        raise ValueError('SOURCE_COMMIT_REQUIRED')
    before = source_pins(root)
    original = base.qualify(root, host, dotnet, expected_platform)
    if original['source_commit'] != source_commit:
        raise ValueError('HOST_SOURCE_COMMIT_MISMATCH')
    cases = []
    env = dict(os.environ, DOTNET_CLI_TELEMETRY_OPTOUT='1', DOTNET_SKIP_FIRST_TIME_EXPERIENCE='1',
               DOTNET_MULTILEVEL_LOOKUP='0')
    with tempfile.TemporaryDirectory(prefix='ToolbeltSsisCopyHost-') as temporary:
        path = Path(temporary) / 'Synthetisch-\u00c4-\u6c49.dtsx'
        for fixture in FIXTURES:
            data = (root / fixture).read_bytes()
            xml = ET.fromstring(data)
            copy = next(c for c in xml.iter('component') if c.get('name') == 'Copy')
            guid = copy.get('componentClassID')
            marker = f'componentClassID="{guid}" version="1"'.encode('ascii')
            if data.count(marker) != 1:
                raise ValueError('EXACT_COPY_FIXTURE_VERSION_REQUIRED')
            for version in (1, 2):
                test_data = data if version == 1 else data.replace(marker, marker.replace(b'"1"', b'"2"'))
                path.write_bytes(test_data)
                result = subprocess.run([str(dotnet), str(host), str(path)], capture_output=True,
                                        timeout=15, env=env)
                count = 0
                name = fixture.stem + ':version' + str(version)

                def check(condition, label):
                    nonlocal count
                    if not condition:
                        raise AssertionError(name + ':' + label)
                    count += 1

                check(result.returncode == 0, 'successful-model-export')
                check(not result.stderr, 'empty-stderr')
                model = json.loads(result.stdout.decode('utf-8'))
                check(model['contract'] == 'ssis-package-model-components-v2', 'current-model-contract')
                check(model['source']['packageSha256'] == base.sha(test_data), 'exact-input-bytes')
                check(model['source']['byteLength'] == len(test_data), 'exact-input-length')
                check(model['producer']['sourceCommit'] == source_commit, 'exact-source-commit')
                check(model['producer']['buildSha256'] == original['host_sha256'], 'same-portable-binary')
                check(model['source']['packageFormatVersion'] == int(fixture.stem.split('-')[2]), 'native-package-format')
                nodes = model['nodes']
                copies = [n for n in nodes if n['kind'] == 'COMPONENT' and n['name'] == 'Copy']
                check(len(copies) == 1, 'one-copy-component')
                component = copies[0]
                check(component['attributes']['componentClassId'] == guid, 'native-class-id')
                unknown = [d for d in model['diagnostics'] if d.get('code') == 'UNKNOWN_COMPONENT'
                           and d.get('objectId') == component['id']]
                check(bool(unknown) == (version == 2), 'version-is-not-silently-admitted')
                inputs = [n for n in nodes if n['kind'] == 'PORT' and n['parentId'] == component['id']
                          and n['attributes']['direction'] == 'INPUT']
                outputs = [n for n in nodes if n['kind'] == 'PORT' and n['parentId'] == component['id']
                           and n['attributes']['direction'] == 'OUTPUT']
                check(len(inputs) == 1 and len(outputs) == 1, 'fixed-port-shape')
                output = outputs[0]
                check(output['attributes']['synchronousInputPortId'] == inputs[0]['id'], 'same-component-sync')
                check(output['attributes']['portRole'] == ('REGULAR' if version == 1 else 'UNKNOWN'),
                      'qualified-regular-role-only')
                columns = [n for n in nodes if n['kind'] == 'COLUMN' and n['parentId'] == output['id']]
                check([n['name'] for n in columns] == ['KeyACopy', 'AmountCopy'], 'ordered-copy-columns')
                expected_type = 'wstr' if fixture.stem.endswith('text') else 'i4'
                check([n['attributes']['typeCode'] for n in columns] == [expected_type, 'i4'], 'typed-copy-columns')
                check(str(path).encode('utf-8') not in result.stdout, 'input-path-not-exported')
                cases.append({'name':name, 'exit_code':result.returncode, 'assertions':count,
                              'output_sha256':base.sha(json.dumps(model, ensure_ascii=True, sort_keys=True,
                                                                 separators=(',', ':')).encode('utf-8'))})
    if source_pins(root) != before or base.sha(host.read_bytes()) != original['host_sha256']:
        raise ValueError('INPUT_DRIFT')
    return {'contract':'ssis-copy-column-export-host-native/1',
            'date':datetime.now(timezone.utc).date().isoformat(), 'platform':expected_platform,
            'result':'PASS', 'sql_executed':False, 'host_sha256':original['host_sha256'],
            'source_commit':source_commit, 'source_sha256':before,
            'base':original, 'copy_cases':cases, 'case_count':original['case_count']+len(cases),
            'assertions':original['assertions']+sum(c['assertions'] for c in cases)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host',type=Path,required=True)
    parser.add_argument('--dotnet',type=Path,required=True)
    parser.add_argument('--platform',choices=('Windows','Linux'),required=True)
    parser.add_argument('--source-commit',required=True)
    parser.add_argument('--result',type=Path,required=True)
    args=parser.parse_args()
    report=qualify(Path(__file__).resolve().parents[4],args.host.resolve(),args.dotnet.resolve(),
                   args.platform,args.source_commit)
    args.result.write_text(json.dumps(report,indent=2,ensure_ascii=True)+'\n',encoding='utf-8')
    print(f"SSIS_COPY_EXPORT_HOST_PASS platform={report['platform']} cases={report['case_count']} assertions={report['assertions']}")


if __name__ == '__main__':
    main()

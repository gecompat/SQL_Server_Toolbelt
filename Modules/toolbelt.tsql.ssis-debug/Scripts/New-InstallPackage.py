"""Packt ausschließlich den exakt qualifizierten SSIS-Satz; kein Build oder SQL."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path, PurePosixPath
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[3]
MODULE = 'Modules/toolbelt.tsql.ssis-debug/'
NAME = 'SSIS-Debug-1.0.0-Install-Windows'
MODULES = ('toolbelt.core.result-table', 'toolbelt.tsql.script-parser', 'toolbelt.tsql.ssis-debug')


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def require(value, reason):
    if not value:
        raise ValueError('SSIS_PACKAGE_BUILD_INVALID: ' + reason)


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def build(args):
    commit = subprocess.check_output(['git', 'rev-parse', args.source_commit], cwd=ROOT, text=True).strip()
    names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', commit], cwd=ROOT, text=True).splitlines()
    def source(path):
        require(path in names, 'source missing: ' + path)
        return subprocess.check_output(['git', 'show', commit + ':' + path], cwd=ROOT)
    payload = {p: source(p) for p in names if any(p.startswith('Modules/' + m + '/') for m in MODULES)
               and ('/InstallPackages/' not in p or p == MODULE + 'InstallPackages/README.md')}
    for p in ('LICENSE.md', 'Documentation/Standards/USP_CONTRACT.md',
              'Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md',
              'Documentation/Architecture/SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md',
              'Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md',
              'Documentation/Architecture/TSQL_SCRIPT_PARSER_MODULE_DESIGN.md'):
        payload[p] = source(p)
    for p in names:
        prefix = MODULE + 'InstallPackages/'
        if p.startswith(prefix + 'ThirdParty/'):
            payload[p[len(prefix):]] = source(p)
    payload['START-HERE.txt'] = source(MODULE + 'InstallPackages/START-HERE.txt').replace(b'@SOURCE_COMMIT@', commit.encode())
    release_pins = json.loads(source(MODULE + 'Contracts/InstallPackageInputs.json'))
    allowed = {'Tests/Qualification/Identities.Windows2019-2025.20261025.json':1626,
               'Tests/Qualification/Iterations.Windows2019-2025.20261025.json':1590,
               'Tests/Qualification/Release.Windows.CL.20261025.json':3516}
    evidence = release_pins['qualification_evidence']
    require(evidence in allowed, 'explicit qualification contract')
    record_path = MODULE + evidence
    record = json.loads(source(record_path))
    explicit_cl = evidence == 'Tests/Qualification/Release.Windows.CL.20261025.json'
    expected = {(v,cl,m) for v,levels in (('2019',(150,)),('2022',(150,160)),('2025',(150,160,170)))
                for cl in levels for m in ('local','central')} if explicit_cl else {
                    (v,m) for v in ('2019','2022','2025') for m in ('local','central')}
    actual = {(c['sql_version'],c['compatibility_level'],c['deployment_mode']) if explicit_cl else
              (c['sql_version'],c['deployment_mode']) for c in record['cases']}
    require(record['result'] == 'PASS' and len(record['cases']) == len(expected) and record['total_native_assertions'] == allowed[evidence] and
            actual == expected and
            all(c['result'] == 'PASS' for c in record['cases']),
            'exact native qualification missing')
    pins = json.loads(source(MODULE + 'Contracts/DependencyPins.json'))
    manifests = {}
    roots = {}
    for mid, directory, files in (
        ('toolbelt.tsql.script-parser', args.parser_release, ('Toolbelt.Tsql.ScriptParser.dll',
         'Microsoft.SqlServer.TransactSql.ScriptDom.dll', 'Toolbelt.Tsql.ScriptParser.trust-manifest.json', 'Deploy.WithAssembly.sql')),
        ('toolbelt.tsql.ssis-debug', args.ssis_release, ('Toolbelt.Tsql.SsisDebug.dll',
         'Toolbelt.Tsql.SsisDebug.trust-manifest.json', 'Deploy.WithAssembly.sql', 'Uninstall.Expanded.sql'))):
        prefix = 'Modules/' + mid + '/'
        for name in files:
            payload[prefix + 'Artifacts/' + name] = (directory / name).read_bytes()
        m = json.loads(next(
            payload[prefix + 'Artifacts/' + name] for name in files if name.endswith('.trust-manifest.json')))
        manifest_data = next(payload[prefix + 'Artifacts/' + name] for name in files if name.endswith('.trust-manifest.json'))
        require(sha(manifest_data) == release_pins['ssis_release_manifest_sha256' if mid.endswith('ssis-debug') else 'parser_release_manifest_sha256'],
                'original qualified release manifest')
        manifests[mid] = m
        require(m['moduleId'] == mid, 'manifest identity')
        binary = payload[prefix + 'Artifacts/' + files[0]]
        require(hashlib.sha512(binary).hexdigest().upper() == m['sha512'], 'qualified DLL hash')
        require(sha(payload[prefix + 'Artifacts/Deploy.WithAssembly.sql']) == m['deploymentArtifactSha256'], 'deployment hash')
        if mid.endswith('ssis-debug'):
            require(sha(binary).lower() == record['qualified_assembly_sha256'] and
                    m['deploymentArtifactSha256'].lower() == record['qualified_deploy_sql_sha256'], 'native build binding')
            source_root = ''
        else:
            require(m['sha512'] == pins['parserSha512'] and m['scriptDomSha512'] == pins['scriptDomSha512'], 'parser pins')
            source_root = 'BuildSources/ScriptParser-2.0.1/'
        roots[mid] = source_root + prefix.rstrip('/')
        # Git normalisiert Zeilenenden; nur eine exakt manifestgebundene Variante ist zulässig.
        for key in ('sourceFiles', 'deploymentFiles', 'deploymentSourceFiles'):
            for item in m.get(key, []):
                relative, expected = item.split(':', 1)
                import posixpath
                path = posixpath.normpath(prefix + relative)
                require(path.startswith('Modules/') and '..' not in PurePosixPath(path).parts, 'source boundary')
                data = source(path).replace(b'\r\n', b'\n')
                matches = {b for b in (data, data.replace(b'\n', b'\r\n')) if sha(b) == expected}
                require(len(matches) == 1, 'qualified source differs beyond line endings: ' + path)
                payload[source_root + path] = matches.pop()
    parser = manifests['toolbelt.tsql.script-parser']; ssis = manifests['toolbelt.tsql.ssis-debug']
    require(ssis['parserSha512'] == parser['sha512'] == pins['parserSha512'] and
            ssis['scriptDomSha512'] == parser['scriptDomSha512'] == pins['scriptDomSha512'], 'closure pins')
    require(hashlib.sha512(payload['Modules/toolbelt.tsql.script-parser/Artifacts/Microsoft.SqlServer.TransactSql.ScriptDom.dll']).hexdigest().upper()
            == pins['scriptDomSha512'], 'ScriptDom bytes')
    manifest = dict(schemaVersion=1, packageName=NAME, packageDate='2026-10-25',
                    packageKind='development-test-installation', sourceRepository='https://github.com/gecompat/SQL_Server_Toolbelt',
                    sourceCommit=commit, modules=[{'id':m, 'version':'2.0.1' if m.endswith('script-parser') else '1.0.0'} for m in MODULES],
                    scriptDomNugetVersion='180.117.0', binaryBuildProfile='net48-anycpu-release-deterministic',
                    buildSourceRoots=roots, nativeBinaryQualification=record_path,
                    validationScope='Exact previously qualified binaries and SQL; original manifests and pinned dependencies. Package lifecycle qualification is recorded separately against the final ZIP hash.',
                    hashListExcludes=['PACKAGE-MANIFEST.json', 'SHA256SUMS.txt'],
                    files=[{'path':p, 'bytes':len(b), 'sha256':sha(b)} for p,b in sorted(payload.items())])
    payload['PACKAGE-MANIFEST.json'] = encoded(manifest)
    payload['SHA256SUMS.txt'] = ''.join(sha(b) + '  ' + p + '\n' for p,b in sorted(payload.items())).encode('utf-8')
    require(not args.output.exists(), 'output already exists')
    with zipfile.ZipFile(args.output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p,b in sorted(payload.items()):
            info = zipfile.ZipInfo(NAME + '/' + p, (2026,10,25,0,0,0)); info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3; info.external_attr = 0o100644 << 16
            z.writestr(info,b)
    args.output.with_suffix('.zip.sha256').write_text(sha(args.output.read_bytes()) + '  ' + args.output.name + '\n', encoding='ascii')
    print('SSIS_PACKAGE_BUILD_PASS exact qualified artifacts, source roots and deterministic ZIP; no SQL')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-commit', default='HEAD')
    parser.add_argument('--parser-release', type=Path, required=True)
    parser.add_argument('--ssis-release', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    build(parser.parse_args())

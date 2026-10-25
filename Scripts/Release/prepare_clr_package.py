#!/usr/bin/env python3
"""Packt bestehende reproduzierbare CLR-Builds; kompiliert/veröffentlicht nichts.

Der SQL-Export bleibt der kanonische Deploy-All-Exporter. Erst- und Repeatdateien
bewahren dessen explizite Hash-Anwesenheitsverträge; keine automatische Migration.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

import prepare_release as release
from check_clr_builds import check_binary, clr_projects

PACKAGE = 'SQL-Server-Toolbelt-1.0.0-CLR-Install'
LOCATION = release.CLR_PACKAGE
QUALIFICATION = 'Releases/1.0.0/clr-qualification.json'
SSIS = 'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip'
WINDOWS_ONLY = {'toolbelt.filesystem.windows', 'toolbelt.tsql.script-parser', 'toolbelt.tsql.ssis-debug'}


def digest(data: bytes, algorithm='sha256') -> str:
    return hashlib.new(algorithm, data).hexdigest()


def format_assembly_literals(sql: bytes, artifacts: list[dict]) -> bytes:
    """Nur bekannte Assemblyliterale umbrechen; ihre Bytes bleiben identisch.

    Mehrere Megabyte lange Einzelzeilen überlasten den ODBC-sqlcmd-Einlesepfad.
    Die dokumentierte T-SQL-Zeilenfortsetzung erhält denselben Binärwert und
    vermeidet zusätzliche Ausdrücke, Konvertierungen oder SQL-Anweisungen.
    """
    for artifact in artifacts:
        literal = b'0x' + artifact['_bytes'].hex().encode('ascii')
        if len(literal) > 4096 and literal in sql:
            digits = literal[2:]
            continued = b'0x' + b'\\\n'.join(digits[i:i+4096] for i in range(0, len(digits), 4096))
            release.require(continued.replace(b'\\\n', b'') == literal, 'Assemblyliteralkodierung abweichend.')
            sql = sql.replace(literal, continued)
    return sql


def profiles(artifacts: list[dict]) -> dict[str, list[dict]]:
    modules = [a for a in artifacts if a['module_id']]
    return {f'{platform}-{mode}': [a for a in modules
             if not (platform == 'Portable' and a['module_id'] in WINDOWS_ONLY)
             and not (mode == 'central' and a['module_id'] == 'toolbelt.filesystem.windows')]
            for platform in ('Windows', 'Portable') for mode in ('local', 'central')}


def trust_sql(artifacts: list[dict]) -> bytes:
    text = '-- Exakter Assembly-Trust; administrativ bewusst in master ausführen.\n:ON ERROR EXIT\nUSE [master];\nGO\n'
    text += "IF @@TRANCOUNT<>0 THROW 51593,N'Keine Callertransaktion erlaubt.',1;\n"
    text += "IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51593,N'Vorhandene administrative Rechte erforderlich.',2;\n"
    for a in artifacts:
        release.require(re.fullmatch(r'[A-Za-z0-9_.-]+\.dll', a['file']) is not None
                        and re.fullmatch(r'[a-f0-9]{128}', a['sha512']) is not None,
                        'Ungültiger Trustinput.')
        text += f"IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x{a['sha512']})\n"
        text += f" EXEC sys.sp_add_trusted_assembly @hash=0x{a['sha512']},@description=N'Toolbelt 1.0.0 {a['file']}';\n"
    return (text + 'GO\n').encode()


def expand_uninstall(files: dict[str, bytes], path: str, expected: dict, stack=()) -> str:
    release.require(path not in stack and path in files, 'Uninstall-Include fehlt oder ist zyklisch.')
    text = files[path].decode('utf-8-sig')
    def include(match):
        child = (Path(path).parent / match[1].strip().strip('"\'')).as_posix()
        # JSON-Lifecycle-Skripte referenzieren ihre gepinnten Core-/Consumer-
        # Dependencies auch modulübergreifend. Nur versionierte SQL-Quellen.
        import posixpath
        child = posixpath.normpath(child)
        release.require(child.startswith('Modules/') and child.endswith('.sql') and child in files,
                        'Uninstall außerhalb der versionierten Modulquellen.')
        return expand_uninstall(files, child, expected, stack + (path,))
    text = re.sub(r'(?im)^\s*:r\s+([^\r\n]+)\s*$', include, text)
    values = dict(expected, ConfirmNoExternalConsumers='1')
    def replace(match):
        release.require(match[1] in values, f'Uninstallvariable nicht gebunden: {match[1]}')
        return values[match[1]]
    return re.sub(r'\$\(([^)]+)\)', replace, text)


def exports(files: dict[str, bytes], artifacts: list[dict]) -> dict[str, bytes]:
    result = {}
    pwsh = shutil.which('pwsh')
    release.require(pwsh is not None, 'PowerShell 7 für verbindungsfreien Export erforderlich.')
    with tempfile.TemporaryDirectory(prefix='clr-export-', dir=release.runtime_root()) as temp:
        root = Path(temp)
        for path, data in files.items():
            if path.startswith(('Modules/', 'Deployment/')):
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
        wrapper = root / 'export.ps1'
        wrapper.write_text("param([string]$InputFile,[string]$OutputFile)\n$ErrorActionPreference='Stop'\n"
                           "$c=Get-Content -LiteralPath $InputFile -Raw|ConvertFrom-Json -AsHashtable\n"
                           "& (Join-Path $PSScriptRoot 'Deployment/Deploy-All.ps1') -DeploymentMode $c.mode "
                           "-ModuleId $c.modules -ModuleVariables $c.variables -OutputSqlFile $OutputFile\n", encoding='utf-8')
        for profile, selected in profiles(artifacts).items():
            for action in ('Install', 'Repeat'):
                variables = {}
                for a in selected:
                    mid = a['module_id']
                    # Die Includevariablen werden vom vorhandenen Exporter
                    # vollständig erkannt, einschließlich geschachtelter Preflights.
                    all_sql = '\n'.join(data.decode('utf-8-sig') for p, data in files.items()
                                        if p.startswith(f'Modules/{mid}/Deployment/') and p.endswith('.sql'))
                    required = set(re.findall(r'\$\(([^)]+)\)', all_sql))
                    values = {'AssemblyBits': '0x' + a['_bytes'].hex()}
                    if 'ExpectedInstalledAssemblyHash' in required:
                        values['ExpectedInstalledAssemblyHash'] = '0x' if action == 'Install' else '0x' + a['sha512']
                    if 'ExpectedAssemblySha512' in required:
                        values['ExpectedAssemblySha512'] = '0x' + a['sha512']
                    if mid == 'toolbelt.tsql.script-parser':
                        values['ScriptDomAssemblyBits'] = '0x' + next(x['_bytes'] for x in artifacts if not x['module_id']).hex()
                    variables[mid] = values
                config = {'mode': profile.split('-')[1], 'modules': [a['module_id'] for a in selected], 'variables': variables}
                inp, out = root / 'input.json', root / 'output.sql'
                inp.write_bytes(release.encoded(config))
                if out.exists():
                    out.unlink()  # nur die eigene temporäre Exportdatei
                completed = subprocess.run([pwsh, '-NoProfile', '-NonInteractive', '-File', str(wrapper),
                                            '-InputFile', str(inp), '-OutputFile', str(out)],
                                           cwd=root, capture_output=True, timeout=120)
                release.require(completed.returncode == 0 and out.is_file(), 'CLR-Offlineexport fehlgeschlagen.')
                result[f'SQL/{action}-{profile}.sql'] = format_assembly_literals(out.read_bytes(), artifacts)
            sql = result[f'SQL/Install-{profile}.sql'].decode('utf-8')
            order = re.findall(r'(?m)^-- BEGIN MODULE (toolbelt\.[a-z0-9.-]+)', sql)
            by_module = {a['module_id']: a for a in selected}
            for action in ('Uninstall', 'UninstallAbsent'):
                uninstall = ':ON ERROR EXIT\n-- Nur nach Prüfung aller externen Consumer; Trust bleibt erhalten.\n'
                for mid in reversed(order):
                    values = {'DeploymentMode': profile.split('-')[1]}
                    if mid in by_module:
                        values['ExpectedInstalledAssemblyHash'] = '0x' if action == 'UninstallAbsent' else '0x' + by_module[mid]['sha512']
                    uninstall += expand_uninstall(files, f'Modules/{mid}/Deployment/Uninstall.sql', values) + '\nGO\n'
                result[f'SQL/{action}-{profile}.sql'] = uninstall.encode('utf-8')
            trusted = list(selected)
            if profile.startswith('Windows-'):
                trusted += [a for a in artifacts if not a['module_id']]
            result[f'SQL/Trust-{profile}.sql'] = trust_sql(trusted)
    return result


def build(build_directory: Path, output: Path, unqualified_candidate: bool = False) -> None:
    if unqualified_candidate:
        release.require(output.resolve().is_relative_to(release.runtime_root().resolve()),
                        'Unqualifizierte Kandidaten ausschließlich privat unter .runtime.')
    commit, files = release.snapshot('HEAD')
    report = json.loads((build_directory / 'build-check.json').read_bytes())
    release.require(report['scope'] == 'OFFLINE_BUILD_ONLY' and len(report['builds']) == 12, 'Buildnachweis fehlt.')
    _, built_sources = release.snapshot(report['source_commit'])
    current_inputs = {p:b for p,b in files.items() if p.startswith(('Modules/','Deployment/'))}
    built_inputs = {p:b for p,b in built_sources.items() if p.startswith(('Modules/','Deployment/'))}
    if current_inputs != built_inputs:
        # Keine erneute Kompilation identischer C#/SQL-Inputs: ausschließlich
        # die sechs exakten Rechtefelder und bereits öffentliche Lesepfade.
        record = json.loads((release.ROOT / release.caller_metadata.RECORD).read_bytes())
        _, previous, _ = release.qualification_sources(record['previous_product_commit'])
        release.require(built_inputs == {p:b for p,b in previous.items() if p.startswith(('Modules/','Deployment/'))},
                        'Buildinput gehört nicht zur gebundenen vorherigen Lieferung.')
        _, baseline = release.snapshot(release.caller_metadata.BASELINE)
        release.caller_metadata.validate_product_delta(built_sources, files, record, baseline)
    old = zipfile.ZipFile(io.BytesIO(files[SSIS]))
    artifacts, payload = [], {}
    for project in clr_projects(files):
        mid = project.split('/')[1]
        assembly = next(n.text for n in ET.fromstring(files[project]).iter() if n.tag.endswith('}AssemblyName'))
        filename = assembly + '.dll'
        if mid in ('toolbelt.tsql.script-parser', 'toolbelt.tsql.ssis-debug'):
            matches = [p for p in old.namelist() if p.endswith('/' + filename)]
            release.require(len(matches) == 1, 'Qualifizierter SSIS-/Parserinput fehlt.')
            data = old.read(matches[0]); origin = 'existing_qualified_ssis_package'
        else:
            path = Path(project).parent / 'bin/Release' / filename
            data = (build_directory / 'first' / path).read_bytes()
            release.require(data == (build_directory / 'second' / path).read_bytes(), 'Doppelbuild abweichend.')
            known = next(a for a in report['builds'] if a['module_id'] == mid)
            release.require(digest(data) == known['sha256'] and digest(data,'sha512') == known['sha512'], 'Buildpin abweichend.')
            origin = 'reproducible_double_build'
        check_binary(data, [build_directory.resolve()])
        manifest = files[f'Modules/{mid}/module.yaml'].decode('utf-8')
        sql_name = re.search(r'^  assembly_sql_name:\s*["\']?([^"\'\r\n]+)', manifest, re.M)
        release.require(sql_name is not None, 'SQL-Assemblyidentität fehlt.')
        a = {'module_id':mid,'file':filename,'sql_name':sql_name[1].strip(), 'origin':origin,
             'sha256':digest(data),'sha512':digest(data,'sha512'),'_bytes':data}
        artifacts.append(a); payload['Binaries/' + filename] = data
    scriptdom_name = 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
    matches = [p for p in old.namelist() if p.endswith('/' + scriptdom_name)]
    release.require(len(matches) == 1, 'ScriptDom fehlt.')
    data = old.read(matches[0])
    release.require(digest(data,'sha512') == '459e137268a4ca378023cd7e68a04655cec2c19a8d01546e81b1a7abf1fe2f9226a03cc3fa2323081c3c1b05626af988c98527711d577919cf409367f853dac7', 'ScriptDom-Pin abweichend.')
    artifacts.append({'module_id':None,'file':scriptdom_name,'sql_name':'Microsoft.SqlServer.TransactSql.ScriptDom',
                      'origin':'existing_qualified_scriptdom','sha256':digest(data),'sha512':digest(data,'sha512'),'_bytes':data})
    payload['Binaries/' + scriptdom_name] = data
    for path in old.namelist():
        relative = path.split('/',1)[1] if '/' in path else ''
        if relative.startswith('ThirdParty/'):
            payload[relative] = old.read(path)
    payload.update(exports(files, artifacts))
    selected = {a['module_id'] for a in artifacts if a['module_id']} | {'toolbelt.core.result-table'}
    for path, data in files.items():
        if path.startswith('Modules/') and path.split('/')[1] in selected and '/InstallPackages/' not in path:
            payload['Sources/' + path] = data
        elif path.startswith('Deployment/'):
            payload['Sources/' + path] = data
    payload['LICENSE.md'] = files['LICENSE.md']
    guide = files['Releases/1.0.0/CLR-INSTALL.md'].replace(b'(../../', b'(https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/')
    payload['START-HERE.md'] = guide.replace(b'(InstallPackages/', b'(https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Releases/1.0.0/InstallPackages/')
    payload['Install-ClrPackage.ps1'] = files['Scripts/Release/Install-ClrPackage.ps1']
    qualification_path = release.SSIS_CLR_QUALIFICATION if release.SSIS_CLR_QUALIFICATION in files else QUALIFICATION
    if qualification_path in files and not unqualified_candidate:
        payload['QUALIFICATION.json'] = files[qualification_path]
    metadata = {'schema_version':'1.0','state':'prepared_not_published','source_commit':commit,
                'qualification_state':'pending' if unqualified_candidate else 'qualified',
                'build_source_commit':report['source_commit'],'publication_authorized':False,
                'qualification_evidence':qualification_path,
                'artifacts':[{k:v for k,v in a.items() if k != '_bytes'} for a in artifacts],
                'profiles':{k:[a['module_id'] for a in v] for k,v in profiles(artifacts).items()},
                'files':{p:{'sha256':digest(b),'size':len(b)} for p,b in sorted(payload.items())}}
    payload['CLR-PACKAGE.json'] = release.encoded(metadata)
    archive = release.write_zip(payload, PACKAGE)
    release.require(not output.exists() and not Path(str(output)+'.sha256').exists(), 'Ausgabe existiert bereits.')
    output.write_bytes(archive)
    Path(str(output)+'.sha256').write_text(digest(archive) + '  ' + output.name + '\n', encoding='ascii')
    verify(output, allow_unqualified_candidate=unqualified_candidate)


def verify(path: Path, allow_unqualified_candidate: bool = False) -> dict:
    checksum = Path(str(path) + '.sha256').read_text(encoding='ascii').split()
    release.require(checksum == [digest(path.read_bytes()), path.name], 'CLR-ZIP-Prüfsumme abweichend.')
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        release.require(len(names) == len(set(names)) and len(names) < 10000, 'Doppelte/zu viele ZIP-Einträge.')
        prefix = PACKAGE + '/'
        for name in names:
            release.safe_path(name)
            release.require((archive.getinfo(name).external_attr >> 16) & 0o170000 in (0,0o100000), 'Kein regulärer ZIP-Dateieintrag.')
        release.require(all(p.startswith(prefix) and '\\' not in p and '..' not in p.split('/') and not p.endswith('/') for p in names), 'Unsicherer ZIP-Pfad.')
        release.require(sum(i.file_size for i in archive.infolist()) < 256*1024*1024, 'CLR-ZIP zu groß.')
        data = {p[len(prefix):]:archive.read(p) for p in names}
    metadata = json.loads(data['CLR-PACKAGE.json'])
    release.require(metadata['state'] == 'prepared_not_published' and metadata['publication_authorized'] is False, 'Keine Veröffentlichungsfreigabe.')
    release.require(set(data) == set(metadata['files']) | {'CLR-PACKAGE.json'}, 'CLR-Dateiliste abweichend.')
    for name, pin in metadata['files'].items():
        release.require(pin == {'sha256':digest(data[name]),'size':len(data[name])}, 'CLR-Dateiintegrität verletzt.')
    release.require(len(metadata['artifacts']) == 13 and len({a['file'] for a in metadata['artifacts']}) == 13, 'Dreizehn DLLs erforderlich.')
    for a in metadata['artifacts']:
        binary = data['Binaries/' + a['file']]
        release.require(digest(binary) == a['sha256'] and digest(binary,'sha512') == a['sha512'], 'CLR-Binarypin abweichend.')
        if a['module_id']:
            check_binary(binary, [])
    release.require(metadata['profiles'] == {k:[a['module_id'] for a in v] for k,v in profiles(metadata['artifacts']).items()}, 'CLR-Profil driftet.')
    for profile, selected in profiles(metadata['artifacts']).items():
        trusted = list(selected) + ([a for a in metadata['artifacts'] if not a['module_id']] if profile.startswith('Windows-') else [])
        release.require(data[f'SQL/Trust-{profile}.sql'] == trust_sql(trusted), 'Trust-SQL driftet.')
        for action in ('Install','Repeat','Uninstall','UninstallAbsent'):
            sql = data[f'SQL/{action}-{profile}.sql']
            release.require(b'$(' not in sql and re.search(br'(?im)^\s*:(?!on error exit\s*$)',sql) is None, 'Unaufgelöste SQLCMD-Direktive.')
    qualification = release.ROOT / release.clr_qualification_path(metadata)
    pending = metadata.get('qualification_state') == 'pending'
    if pending:
        release.require(allow_unqualified_candidate and path.resolve().is_relative_to(release.runtime_root().resolve())
                        and 'QUALIFICATION.json' not in data,
                        'Privater Kandidat besitzt noch keine native Qualifikation.')
    elif qualification.is_file():
        qualified = json.loads(qualification.read_bytes())
        release.validate_clr_qualification(data, qualified, release.clr_qualification_method_sources(qualified))
    print('PASS CLR_CANDIDATE native NOT_EXECUTED; private qualification input only' if pending else
          'PASS CLR_PACKAGE 12 modules, 13 DLLs, four explicit deployment profiles; no build needed on installation')
    return metadata


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-directory',type=Path)
    parser.add_argument('--output',type=Path)
    parser.add_argument('--verify',type=Path)
    parser.add_argument('--unqualified-candidate',action='store_true',help='Expliziter privater Testinput, kein qualifiziertes Releaseasset.')
    args = parser.parse_args()
    try:
        if args.verify:
            verify(args.verify, allow_unqualified_candidate=args.unqualified_candidate)
        else:
            release.require(args.build_directory is not None and args.output is not None, 'Buildverzeichnis und neue Ausgabe erforderlich.')
            build(args.build_directory, args.output, unqualified_candidate=args.unqualified_candidate)
    except (release.ReleaseError,OSError,ValueError,KeyError,subprocess.TimeoutExpired,zipfile.BadZipFile) as error:
        print(f'CLR_PACKAGE_FAILED: {error}',file=sys.stderr); sys.exit(1)

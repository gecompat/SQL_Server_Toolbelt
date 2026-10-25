"""Erzeugt private Gesamtpaket-Prüfinputs aus dem tatsächlichen Quell-ZIP.

Kein Build, SQL-Zugriff oder Releaseasset. Der kanonische Offline-Exporter
erhält ausschließlich die Quellen und DLLs des bereits geprüften Archivs.
"""
from __future__ import annotations
import argparse
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'Scripts/Release'))
import prepare_release as release
import prepare_clr_package as clr

ROOT_NAME = 'Toolbelt-Complete-Qualification'


def module_profiles(files: dict[str, bytes]) -> dict[str, list[str]]:
    manifests = {p.split('/')[1]: b.decode('utf-8-sig').replace('\r\n', '\n') for p, b in files.items()
                 if re.fullmatch(r'Modules/[^/]+/module.yaml', p)}
    release.require(len(manifests) == 45, 'Gesamtbestand muss genau 45 Module enthalten.')
    result = {}
    for platform in ('Windows', 'Portable'):
        for mode in ('local', 'central'):
            selected = set()
            for mid, text in manifests.items():
                host = 'windows' if platform == 'Windows' else 'linux'
                status = re.search(rf'^  {host}:\s*(.+)$', text, re.M)
                capability = re.search(r'^deployment_capabilities:\n((?:[ \t].*\n)+)', text, re.M)
                release.require(status is not None and capability is not None, 'Profildeklaration fehlt.')
                if 'not applicable' not in status[1] and re.search(rf'^  {mode}: true$', capability[1], re.M):
                    selected.add(mid)
            # Unsupported Dependencies begrenzen auch ihre Consumer.
            while True:
                reduced = {m for m in selected if set(release.dependencies(manifests[m])) <= selected}
                if reduced == selected:
                    break
                selected = reduced
            result[f'{platform}-{mode}'] = sorted(selected)
    release.require(set(result['Windows-local']) == set(manifests), 'Windows-local muss alle 45 Module einschließen.')
    return result


def prepare(package: Path, output: Path, product_commit: str | None = None,
            clr_candidate: Path | None = None) -> None:
    release.require(output.resolve().is_relative_to(release.runtime_root().resolve())
                    and not output.exists() and not output.with_suffix('.zip.sha256').exists()
                    and output.parent.is_dir(), 'Neues privates Ausgabeziel erforderlich.')
    release.verify(package)
    prefix = release.NAME + '/'
    files = {p[len(prefix):]: b for p, b in release.read_zip(package.read_bytes()).items()}
    source_commit = json.loads(files['PACKAGE-MANIFEST.json'])['product_commit']
    if clr_candidate is not None:
        release.require(product_commit is not None, 'Explizite SSIS-Produktquelle erforderlich.')
        clr.verify(clr_candidate, allow_unqualified_candidate=True)
    if product_commit is not None:
        source_commit, updated = release.snapshot(product_commit)
        allowed = {'Modules/toolbelt.string.edit-distance/Deployment/Deploy.sql',
                   'Modules/toolbelt.core.event-log/Deployment/Uninstall.sql'}
        changed = {p for p in set(files) | set(updated)
                   if p.startswith(('Modules/', 'Deployment/', 'Workers/'))
                   and not p.endswith(('.md', '.yaml')) and files.get(p) != updated.get(p)}
        if clr_candidate is None:
            release.require(changed <= allowed, 'Kandidat verändert weitere Runtime-/Build-/Binaryinputs.')
        else:
            record = json.loads((release.ROOT / release.SSIS_UPDATE).read_bytes())
            release.require(record['previous_product_commit'] == json.loads(files['PACKAGE-MANIFEST.json'])['product_commit'],
                            'SSIS-Kandidat hat einen anderen qualifizierten Vorgänger.')
            release.validate_ssis_product_applicability(record['previous_product_commit'], source_commit, updated)
        files.update({p: b for p, b in updated.items() if p.startswith(('Modules/', 'Deployment/', 'Workers/'))})
    inner_prefix = clr.PACKAGE + '/'
    clr_bytes = clr_candidate.read_bytes() if clr_candidate is not None else files[release.CLR_PACKAGE]
    inner = {p[len(inner_prefix):]: b for p, b in release.read_zip(clr_bytes).items()}
    metadata = json.loads(inner['CLR-PACKAGE.json'])
    if clr_candidate is not None:
        release.require(clr_candidate.resolve().is_relative_to(release.runtime_root().resolve())
                        and metadata['qualification_state'] == 'pending', 'SSIS-Folgekandidat muss ausdrücklich privat/pending bleiben.')
        old_inner = {p[len(inner_prefix):]: b for p, b in release.read_zip(files[release.CLR_PACKAGE]).items()}
        old_binaries = {p: b for p, b in old_inner.items() if p.startswith('Binaries/')}
        new_binaries = {p: b for p, b in inner.items() if p.startswith('Binaries/')}
        ssis_binary = 'Binaries/Toolbelt.Tsql.SsisDebug.dll'
        release.require(set(new_binaries) == set(old_binaries)
                        and all(new_binaries[p] == old_binaries[p] for p in old_binaries if p != ssis_binary),
                        'Nicht-SSIS-Binaries gegenüber der qualifizierten Lieferung geändert.')
        ssis_build = json.loads(files[release.SSIS_BUILD_QUALIFICATION])
        release.require(release.sha(new_binaries[ssis_binary]) == ssis_build['qualified_assembly_sha256'],
                        'Gesamtpaket hat einen anderen SSIS-Binary als die neue Vollqualifikation.')
    profiles = module_profiles(files)
    metadata['complete_profiles'] = profiles
    metadata['versions'] = {m: release.documentation.top_scalar(files[f'Modules/{m}/module.yaml'].decode('utf-8-sig'), 'version')
                            for m in profiles['Windows-local']}
    metadata['input_source_zip_sha256'] = release.sha(package.read_bytes())
    metadata['purpose'] = 'complete_installation_qualification_only_not_publication'
    metadata['product_commit'] = source_commit
    payload = {'CLR-PACKAGE.json': release.encoded(metadata),
               'Fixtures/Pointer.Security.sql': files['Modules/toolbelt.json.pointer/Tests/Runtime/Security.Contract.sql']}
    pwsh = shutil.which('pwsh')
    release.require(pwsh is not None, 'PowerShell 7 erforderlich.')
    with tempfile.TemporaryDirectory(prefix='complete-export-', dir=release.runtime_root()) as temp:
        root = Path(temp)
        for path, data in files.items():
            if path.startswith(('Modules/', 'Deployment/')):
                dest = root / path
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
        wrapper = root / 'export.ps1'
        wrapper.write_text("param($InputFile,$OutputFile)\n$ErrorActionPreference='Stop'\n"
                           "$c=Get-Content -LiteralPath $InputFile -Raw|ConvertFrom-Json -AsHashtable\n"
                           "& (Join-Path $PSScriptRoot 'Deployment/Deploy-All.ps1') -DeploymentMode $c.mode "
                           "-ModuleId $c.modules -ModuleVariables $c.variables -OutputSqlFile $OutputFile\n", encoding='utf-8')
        artifacts = {a['module_id']: a for a in metadata['artifacts'] if a['module_id']}
        for profile, modules in profiles.items():
            mode = profile.split('-')[1]
            for action in ('Install', 'Repeat'):
                variables = {}
                for mid in modules:
                    if mid == 'toolbelt.string.text-pairs':
                        variables[mid] = {'ExpectedComparisonAssemblyHash': '0x' + artifacts['toolbelt.string.edit-distance']['sha512']}
                    if mid not in artifacts:
                        continue
                    a = artifacts[mid]
                    sql = '\n'.join(b.decode('utf-8-sig') for p, b in files.items()
                                    if p.startswith(f'Modules/{mid}/Deployment/') and p.endswith('.sql'))
                    required = set(re.findall(r'\$\(([^)]+)\)', sql))
                    values = {'AssemblyBits': '0x' + inner['Binaries/' + a['file']].hex()}
                    if 'ExpectedInstalledAssemblyHash' in required:
                        values['ExpectedInstalledAssemblyHash'] = '0x' if action == 'Install' else '0x' + a['sha512']
                    if 'ExpectedAssemblySha512' in required:
                        values['ExpectedAssemblySha512'] = '0x' + a['sha512']
                    if mid == 'toolbelt.tsql.script-parser':
                        dom = next(x for x in metadata['artifacts'] if not x['module_id'])
                        values['ScriptDomAssemblyBits'] = '0x' + inner['Binaries/' + dom['file']].hex()
                    variables[mid] = values
                config = {'mode': mode, 'modules': modules, 'variables': variables}
                inp, out = root / 'input.json', root / f'{action}-{profile}.sql'
                inp.write_bytes(release.encoded(config))
                completed = subprocess.run([pwsh, '-NoProfile', '-NonInteractive', '-File', str(wrapper),
                                            '-InputFile', str(inp), '-OutputFile', str(out)],
                                           cwd=root, capture_output=True, timeout=120)
                if completed.returncode != 0:
                    output.with_suffix('.diagnostic.txt').write_bytes(completed.stdout + b'\n' + completed.stderr)
                release.require(completed.returncode == 0 and out.is_file(), 'Gesamt-Offlineexport fehlgeschlagen.')
                payload[f'SQL/{action}-{profile}.sql'] = out.read_bytes()
            order = re.findall(r'(?m)^-- BEGIN MODULE (toolbelt\.[a-z0-9.-]+)', payload[f'SQL/Install-{profile}.sql'].decode())
            release.require(set(order) == set(modules) and len(order) == len(modules), 'Exportprofil erweitert/verändert.')
            for action in ('Uninstall', 'UninstallAbsent'):
                text = ':ON ERROR EXIT\n-- Nur eigener synthetischer Testscope ohne externe Consumer.\n'
                for mid in reversed(order):
                    values = {'DeploymentMode': mode, 'AllowDataLoss': '1'}
                    if mid in artifacts:
                        values['ExpectedInstalledAssemblyHash'] = '0x' if action == 'UninstallAbsent' else '0x' + artifacts[mid]['sha512']
                    text += f'-- BEGIN UNINSTALL MODULE {mid}\n'
                    text += clr.expand_uninstall(files, f'Modules/{mid}/Deployment/Uninstall.sql', values) + '\nGO\n'
                    text += f'-- END UNINSTALL MODULE {mid}\n'
                payload[f'SQL/{action}-{profile}.sql'] = text.encode()
            payload[f'SQL/Trust-{profile}.sql'] = inner[f'SQL/Trust-{profile}.sql']
    output.write_bytes(release.write_zip(payload, ROOT_NAME))
    output.with_suffix('.zip.sha256').write_text(f'{release.sha(output.read_bytes())}  {output.name}\n', encoding='ascii')
    print('PASS COMPLETE_OFFLINE_EXPORT ' + json.dumps({p: len(m) for p, m in profiles.items()}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--package', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--product-commit', help='Expliziter privater Lifecycle-Kandidat; ausschließlich die zwei freigegebenen SQL-Korrekturen.')
    parser.add_argument('--clr-candidate', type=Path, help='Privater SSIS-Folgekandidat mit exakter Build-/Produktdeltaqualifikation; keine Freigabe als Releaseasset.')
    args = parser.parse_args()
    prepare(args.package, args.output, args.product_commit, args.clr_candidate)

"""Aktuellen nativen geprüften Installationssatz als reines T-SQL bündeln."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

import new_ssis_standalone_tsql as renderer
from new_ssis_current_package import ROOT, MODULE, NAME, require, sha
from validate_ssis_current_package import validate

QUALIFICATION = Path(MODULE + 'Tests/Qualification/Current.InstallPackage.20261029.json')
OUTPUT = Path('Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT.sql')
PROVENANCE = Path('Releases/1.0.0/ssis-current-standalone-installer.json')
RUNTIME = Path('Releases/1.0.0/ssis-current-standalone-runtime-qualification.json')
XML_LINE_ENDINGS = {
    MODULE + 'Tests/Fixtures/components-v2-flatfile.dtsx': (
        '1FBE98E8B920EE61101A97ECED896222D5383C22673AB5D8DF7073B2241D3B69',
        'ABBA5E5D960F31347BFCC653C7DCDAB8921E2E8B9A8FA378CD913296ACC2A93F'),
    MODULE + 'Tests/Fixtures/components-v2-rowcount.dtsx': (
        'A6E2A2155B8964978625C9D868B38F4EAA5DDF59FA60A4BEF9DF997E7644FCDA',
        '8157C20130CCA4F34987B5C73D8FB6DB2F61F69DC8D24AD3231DF88BF97876D1'),
}


def validate_runtime(root=ROOT):
    """Bind the new runtime evidence to its actual installer and execution inputs."""
    record = json.loads(renderer.read_regular_bounded(root / RUNTIME, 1024 * 1024))
    require(record.get('kind') == 'ssis_current_standalone_tsql_runtime_qualification' and
            record.get('schema_version') == '1.0' and record.get('profile') == 'ssis-debug-current' and
            record.get('result') == 'PASS' and record.get('publication_authorized') is False,
            'current standalone runtime identity')
    provenance_bytes = renderer.read_regular_bounded(root / PROVENANCE, 1024 * 1024)
    provenance = json.loads(provenance_bytes)
    installer = renderer.read_regular_bounded(root / OUTPUT, renderer.MAX_PACKAGE_BYTES)
    require(record.get('installer') == {'path': OUTPUT.as_posix(), 'sha256': sha(installer)} and
            record.get('provenance') == {'path': PROVENANCE.as_posix(), 'sha256': sha(provenance_bytes)} and
            provenance.get('output') == {'path': OUTPUT.as_posix(), 'bytes': len(installer), 'sha256': sha(installer)} and
            provenance.get('component_profile') == 'ssis-debug-current' and
            provenance.get('publication_authorized') is False, 'current installer and provenance bytes')
    scope = record.get('scope', {})
    targets = scope.get('targets', [])
    require(len(targets) == 2 and
            {(t.get('platform'), t.get('sql_server'), t.get('compatibility_level')) for t in targets} ==
            {('windows', '2019', 150), ('windows', '2025', 170)} and
            scope.get('deployment_modes') == ['local', 'central'], 'exact current runtime targets')
    require(scope.get('case_count') == 2 and scope.get('installed_mode_contexts') == 4 and
            scope.get('results') == {'target_cases': 'PASS', 'cleanup_audits': 'PASS',
                                     'case_count_passed': 2, 'cleanup_audits_passed': 2},
            'current standalone runtime cases')
    execution = record.get('execution', {})
    modes = execution.get('mode_bindings', {})
    local, central = modes.get('local', {}), modes.get('central', {})
    override = {'from': "DECLARE @DeploymentMode nvarchar(16)=N'local';",
                'to': "DECLARE @DeploymentMode nvarchar(16)=N'central';", 'count': 1}
    require(execution.get('driver') == 'Tests/Release/Invoke-CurrentStandaloneTsqlInstallerLab.ps1' and
            local.get('header_override_count') == 0 and local.get('command_sha256') == sha(installer) and
            central.get('header_override') == override, 'current runtime command modes')
    header_from, header_to = override['from'].encode('utf-8'), override['to'].encode('utf-8')
    require(installer.count(header_from) == 1 and
            sha(installer.replace(header_from, header_to, 1)) == central.get('command_sha256'),
            'exact current central command bytes')
    audit = record.get('final_audit', {})
    require(audit.get('case_audits') == 2 and audit.get('owned_database_names_absent') == 4 and
            audit.get('trust_states_restored') == 6 and audit.get('configuration_baselines_restored') is True and
            audit.get('input_pins_unchanged') is True, 'current standalone final audit')
    pins = record.get('execution_input_pins', [])
    bridge = record.get('integration_binding', {})
    require(bridge.get('kind') == 'ssis_current_xml_line_endings_binding' and
            bridge.get('native_execution_inputs_preserved') is True and
            bridge.get('installer_bytes_unchanged') is True and
            bridge.get('qualification_semantics_unchanged') is True,
            'exact current XML line-ending binding')
    changes = bridge.get('changes', [])
    expected_changes = [{'path': path, 'execution_sha256': old, 'integrated_sha256': new,
                         'transform': 'lf-to-crlf-exact-reconstruction'}
                        for path, (old, new) in XML_LINE_ENDINGS.items()]
    require(changes == expected_changes, 'exact current XML line-ending transformations')
    required = {
        'Tests/Release/Invoke-CurrentStandaloneTsqlInstallerLab.ps1',
        'Tests/Release/Prepare-CurrentStandaloneTsqlInstallerRunset.ps1',
        MODULE + 'Tests/Runtime/Invoke-CurrentCases.ps1',
        MODULE + 'Tests/Fixtures/synthetic-8.dtsx',
        MODULE + 'Tests/Fixtures/components-v2-rowcount.dtsx',
        MODULE + 'Tests/Fixtures/components-v2-flatfile.dtsx',
        MODULE + 'Contracts/Api.json', OUTPUT.as_posix(), PROVENANCE.as_posix(),
        QUALIFICATION.as_posix(), MODULE + 'InstallPackages/' + NAME + '.zip',
        MODULE + 'InstallPackages/' + NAME + '.zip.sha256',
        MODULE + 'Tests/Runtime/Invoke-LabContract.ps1',
        'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1',
        'Tests/CI/LabQualifiedContract.ps1', 'Tests/CI/run-csv-memory-lab.ps1',
        'Tests/CI/run-lab-local.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
    }
    paths = {pin.get('path') for pin in pins if isinstance(pin, dict)}
    require(len(pins) == len(paths) and required == paths, 'exact current runtime input closure')
    for pin in pins:
        relative = Path(pin['path'])
        require(not relative.is_absolute() and '..' not in relative.parts and
                re.fullmatch('[0-9A-F]{64}', str(pin.get('sha256', ''))), 'runtime input boundary')
        data = renderer.read_regular_bounded(root / relative, renderer.MAX_PACKAGE_BYTES)
        if relative.as_posix() in XML_LINE_ENDINGS:
            old, new = XML_LINE_ENDINGS[relative.as_posix()]
            require(pin['sha256'] == old, 'original XML execution pin preserved')
            if sha(data) == old:
                require(sha(data.replace(b'\r\n', b'\n')) == new, 'exact executed XML source')
            else:
                require(sha(data) == new and b'\r' not in data and
                        sha(data.replace(b'\n', b'\r\n')) == old,
                        'exact current XML fixture checkout: ' + relative.as_posix())
        else:
            if relative.as_posix() == MODULE + 'Contracts/Api.json' and sha(data) != pin['sha256']:
                import parameter_help_transition
                try:
                    data = parameter_help_transition.predecessor_source(root, relative.as_posix(), pin['sha256'])
                except ValueError as error:
                    raise ValueError('SSIS_CURRENT_PACKAGE_INVALID: current execution input changed: ' + relative.as_posix()) from error
            require(sha(data) == pin['sha256'], 'current execution input changed: ' + relative.as_posix())
    source = provenance.get('source_package', {})
    require(source.get('path') == MODULE + 'InstallPackages/' + NAME + '.zip' and
            source.get('qualification') == QUALIFICATION.as_posix(), 'current package source paths')
    package = renderer.read_regular_bounded(root / source['path'], renderer.MAX_PACKAGE_BYTES)
    qualification = renderer.read_regular_bounded(root / QUALIFICATION, 1024 * 1024)
    require(source.get('qualification') == QUALIFICATION.as_posix() and
            source.get('qualification_sha256') == sha(qualification) and source.get('sha256') == sha(package),
            'current package provenance')
    validate_package_qualification(qualification, sha(qualification), sha(package))
    renderer.validate_installer_guards(installer)
    validate(root / source['path'])
    return record


def validate_package_qualification(data, expected_sha, package_sha):
    require(sha(data) == expected_sha, 'exact current package qualification')
    record = json.loads(data)
    require(record.get('schema_version') == '1.0' and
            record.get('kind') == 'ssis_current_install_package_qualification' and
            record.get('profile') == 'ssis-debug-current' and
            record.get('result') == 'PASS' and record.get('publication_authorized') is False and
            record.get('package_sha256') == package_sha.lower(), 'qualified current package')
    cases = record.get('cases', [])
    expected = {('2019', 150, 'local'), ('2025', 170, 'central')}
    actual = {(c.get('sql_version'), c.get('compatibility_level'), c.get('deployment_mode')) for c in cases}
    require(len(cases) == len(expected) and actual == expected and
            all(c.get('result') == 'PASS' and c.get('final_independent_audit') == 'PASS' for c in cases),
            'both current package modes and independent audits')
    audit = record.get('final_audit', {})
    require(audit.get('case_audits') == 2 and audit.get('owned_database_names_absent') == 4 and
            audit.get('trust_states_restored') == 6 and
            audit.get('configuration_baselines_restored') is True and
            audit.get('input_pins_unchanged') is True, 'current package cleanup')
    return record


def main(args):
    archive = Path(MODULE + 'InstallPackages/' + NAME + '.zip')
    qualification = renderer.read_regular_bounded(ROOT / QUALIFICATION, 1024 * 1024)
    package = renderer.read_regular_bounded(ROOT / archive, renderer.MAX_PACKAGE_BYTES)
    validate_package_qualification(qualification, args.qualification_sha256, sha(package))
    validate(ROOT / archive)
    renderer.PACKAGE = archive
    renderer.PACKAGE_SIDECAR = Path(str(archive) + '.sha256')
    renderer.PACKAGE_QUALIFICATION = QUALIFICATION
    renderer.PACKAGE_QUALIFICATION_SHA256 = args.qualification_sha256
    renderer.ARCHIVE_ROOT = NAME + '/'
    renderer.OUTPUT = OUTPUT
    renderer.PROVENANCE = PROVENANCE
    renderer.LICENSE_COPY = Path('Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT-LICENSE.md')
    renderer.SCRIPTDOM_NOTICE = Path('Releases/1.0.0/ThirdParty/SSIS-Current/ScriptDom-180.117.0')
    original_render = renderer.render

    def render(payloads, hashes):
        result = original_render(payloads, hashes)
        result = result.replace(
            'Toolbelt SSIS-Debug 1.0.0 – eigenständiger T-SQL-Installer.'.encode('utf-8'),
            'Toolbelt SSIS-Debug – aktueller eigenständiger T-SQL-Installer.'.encode('utf-8'))
        result = result.replace(b'SSIS-INSTALL-TSQL-LICENSE.md', b'SSIS-INSTALL-TSQL-CURRENT-LICENSE.md')
        renderer.validate_installer_guards(result)
        return result

    renderer.render = render
    result = renderer.main()
    provenance = json.loads((ROOT / PROVENANCE).read_bytes())
    provenance['component_profile'] = 'ssis-debug-current'
    provenance['limits'].append('Aktueller Standard ohne Toolbelt-Legacy-Profil; Limits über benannte SQL-Parameter, nicht JSON')
    (ROOT / PROVENANCE).write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + '\n',
                                   encoding='utf-8', newline='\n')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--qualification-sha256', required=True, type=str.upper)
    options = parser.parse_args()
    require(re.fullmatch('[0-9A-F]{64}', options.qualification_sha256), 'qualification digest format')
    raise SystemExit(main(options))

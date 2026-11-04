"""Bindet das reparierte Installations-ZIP an seinen eigenen nativen Lauf."""
import json
import posixpath

from new_ssis_current_package import QUALIFIED_PROFILE, QUALIFIED_NAME
from validate_ssis_current_package import ROOT, MODULE, validate, read_regular_bounded, require, sha, MAX_PACKAGE_BYTES

REPORT = MODULE + 'Tests/Qualification/Current.Build.Delivery.20261104.json'
ARCHIVE = MODULE + 'InstallPackages/' + QUALIFIED_NAME + '.zip'


def validate_delivery(report=None, *, check_files=True):
    if report is None:
        report = json.loads(read_regular_bounded(ROOT / REPORT, 1024 * 1024))
    require(report.get('kind') == 'ssis_current_build_package_qualification' and report.get('result') == 'PASS' and
            report.get('publication_authorized') is False and report.get('reproduced_zip') is True,
            'current package identity')
    require(report.get('case') == {
        'platform': 'windows', 'sql_version': '2025', 'patch': 'CU8', 'compatibility_level': 170,
        'deployment_mode': 'local', 'test_purpose': 'Functional', 'authenticated_tls': 'not executed',
        'package_assertions': 8, 'procedure_assertions': 222, 'result': 'PASS_CLEANED', 'cleanup_audit': 'PASS',
    }, 'current package native scope and audit')
    package = report.get('package', {})
    require(package.get('path') == ARCHIVE, 'current package path')
    inputs = report.get('execution_inputs', {})
    require(MODULE + 'Tests/Runtime/Invoke-CurrentBuildLab.ps1' in inputs and
            MODULE + 'Tests/Runtime/Invoke-ProcedureBoundaryCases.ps1' in inputs and
            MODULE + 'Tests/Fixtures/procedure-bigint-8.dtsx' in inputs and len(inputs) > 20,
            'current package test closure')
    if check_files:
        manifest, release, payload = validate(ROOT / ARCHIVE, profile=QUALIFIED_PROFILE)
        require(package.get('sha256') == sha(read_regular_bounded(ROOT / ARCHIVE, MAX_PACKAGE_BYTES)) and
                package.get('manifest_sha256') == sha(payload['PACKAGE-MANIFEST.json']), 'exact executed current ZIP')
        for key in ('sourceFiles', 'deploymentFiles'):
            for entry in release[key]:
                relative, digest = entry.split(':', 1)
                path = posixpath.normpath(MODULE + relative)
                require(sha(read_regular_bounded(ROOT / path, MAX_PACKAGE_BYTES)) == digest, 'current package source drift')
        for path, digest in inputs.items():
            require(sha(read_regular_bounded(ROOT / path, MAX_PACKAGE_BYTES)) == digest, 'current package execution input drift')
    return report


if __name__ == '__main__':
    validate_delivery()
    print('SSIS_CURRENT_QUALIFIED_PACKAGE_PASS; exact repaired ZIP and independent native audit')

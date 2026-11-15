"""Current archive admission; real bytes, no SQL, credentials or GUI."""
from pathlib import Path
import base64
import json
import os
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
AREA = 'Modules/toolbelt.tsql.ssis-debug/'
METHOD = AREA + 'Tests/WindowsClientRecovery/'
PWSH = shutil.which('pwsh')


@unittest.skipUnless(PWSH, 'PowerShell required; no native fallback')
class CopySsmsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        runtime = ROOT / '.runtime'
        runtime.mkdir(exist_ok=True)
        cls.temp = tempfile.TemporaryDirectory(prefix='copy-ssms-admission-', dir=runtime)
        cls.addClassCleanup(cls.temp.cleanup)
        cls.stage = Path(cls.temp.name)
        with zipfile.ZipFile(ROOT / AREA / 'InstallPackages/SSIS-Debug-CopyColumnV1-Install-Windows.zip') as z:
            for module in ('toolbelt.tsql.ssis-debug', 'toolbelt.tsql.script-parser'):
                prefix = f'SSIS-Debug-CopyColumnV1-Install-Windows/Modules/{module}/Artifacts/'
                for name in z.namelist():
                    if name.startswith(prefix) and not name.endswith('/'):
                        target = cls.stage / module / Path(name).name
                        target.parent.mkdir(exist_ok=True)
                        target.write_bytes(z.read(name))
        p = cls.ps("& './" + METHOD + "Invoke-CopyColumnSsms.ps1' -PlanPath './.runtime/unused-copy-ssms.json' -DescribeOnly")
        if p.returncode:
            raise AssertionError(p.stderr)
        cls.description = json.loads(p.stdout)

    @classmethod
    def ps(cls, script):
        script = "[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)\n" + script
        env = dict(os.environ, TB_COPY_SSMS_STAGE=str(cls.stage))
        return subprocess.run([PWSH, '-NoProfile', '-EncodedCommand',
                               base64.b64encode(script.encode('utf-16le')).decode('ascii')],
                              cwd=ROOT, capture_output=True, text=True, encoding='utf-8',
                              timeout=30, env=env)

    def test_current_wrapper_and_artifact_guard_are_bound(self):
        text = self.description['canonical']
        for name in ('Invoke-CopyColumnSsms.ps1', 'CopyColumnArtifacts.ps1',
                     'Invoke-CurrentBuildSsms.ps1', 'CopyColumn.V1.20261114.json',
                     'CopyColumn.Delivery.20261115.json'):
            self.assertIn(name, text)
        self.assertNotIn("'CurrentBuildArtifacts.ps1')", text)
        self.assertIn(".Rows[0].N-eq 40) 'CURRENT_INSTALLED_API'", text)

    def test_preflight_precedes_database_and_preserves_windows_guards(self):
        text = self.description['canonical']
        self.assertLess(text.index(' Invoke-SsmsTargetPreflight\n'), text.index('Exec-Client $master ($prepare.Replace'))
        for guard in ('WRONG_LAB_TARGET', 'WINDOWS_AUTH_REQUIRED', 'ENCRYPTED_CONNECTION_REQUIRED'):
            self.assertIn(guard, self.description['preflightQuery'])
        self.assertIn('manualConnectionRequired=$true', self.description['preflight'])

    def test_native_stop_and_full_receipt_oracles_preserved(self):
        for guard in ('SQLCMD_ERROR_STOPS_BEFORE_LATER_SENTINEL',
                      'EXECUTION_ENVELOPE_PRESERVES_COMPLETE_COPY_AND_RECEIPT',
                      'COMPLETE_GUI_COPY_UNICODE_TRANSPORT'):
            self.assertIn(guard, self.description['gui'])

    def probe(self, fault=None, expected=None):
        script = r'''
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repoRoot=(Get-Location).Path
. './Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/RecoveryFixture.ps1'
function Get-ClientHash([string]$Path){
 if(@FAULT@){return '0'*64}
 (Get-FileHash -LiteralPath $Path).Hash
}
. './Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/CopyColumnArtifacts.ps1'
$plan=@{ssis=(Join-Path $env:TB_COPY_SSMS_STAGE 'toolbelt.tsql.ssis-debug');parser=(Join-Path $env:TB_COPY_SSMS_STAGE 'toolbelt.tsql.script-parser')}
try{Assert-RecoveryArtifacts $plan;@SUCCESS@}
catch{if($_.Exception.Message -cne '@EXPECTED@'){throw};'EXPECTED_REJECTION'}
'''
        script = script.replace('@FAULT@', fault or '$false')
        script = script.replace('@SUCCESS@', "throw 'UNEXPECTED_ACCEPTANCE'" if expected else "'ACTUAL_ARCHIVE_ADMITTED'")
        script = script.replace('@EXPECTED@', expected or 'NO_FAILURE_EXPECTED')
        p = self.ps(script)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('EXPECTED_REJECTION' if expected else 'ACTUAL_ARCHIVE_ADMITTED', p.stdout)

    def test_actual_archive_sources_parser_and_core_accepted(self):
        self.probe()

    def test_approval_record_mismatch_rejected(self):
        self.probe("$Path.EndsWith('CopyColumn.V1.20261114.json')", 'SSIS_COPY_SSMS_APPROVAL_RECORD')

    def test_product_drift_rejected(self):
        self.probe("$Path.EndsWith('ProcedureDefinition.cs')", 'SSIS_COPY_SSMS_PRODUCT_SOURCE_CHANGED')

    def test_archive_drift_rejected(self):
        self.probe("$Path.EndsWith('SSIS-Debug-CopyColumnV1-Install-Windows.zip')", 'SSIS_COPY_SSMS_ARCHIVE_CHANGED')

    def test_stale_dll_rejected(self):
        self.probe("$Path.EndsWith('Toolbelt.Tsql.SsisDebug.dll')", 'SSIS_COPY_SSMS_ARTIFACT_CHANGED')

    def test_stale_deployment_rejected(self):
        self.probe("$Path.EndsWith('Deploy.WithAssembly.sql')", 'SSIS_COPY_SSMS_ARTIFACT_CHANGED')



# Historische C7-Quellenbindung bleibt von der aktuellen Korrektur getrennt.
import sys
sys.path.insert(0,str(ROOT/'Scripts/Release'))
from ssis_historical_scope import copy_column_v1_scope
def setUpModule():
    global _historical_scope, _original_paths
    _historical_scope=copy_column_v1_scope(ROOT)
    snapshot=_historical_scope.__enter__()
    _original_paths={key:value for key,value in list(globals().items())
                     if isinstance(value,Path) and value.is_relative_to(ROOT)}
    original=ROOT
    for key,value in _original_paths.items():
        globals()[key]=snapshot/value.relative_to(original)
def tearDownModule():
    globals().update(_original_paths)
    _historical_scope.__exit__(None,None,None)

if __name__ == '__main__':
    unittest.main()

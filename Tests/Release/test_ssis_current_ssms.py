"""Fresh current-build adapter: compose without SQL and reject stale artifact bindings."""
import json
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
AREA = ROOT / 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery'
PWSH = shutil.which('pwsh')


@unittest.skipUnless(PWSH, 'PowerShell required; no native fallback')
class CurrentSsmsTests(unittest.TestCase):
    def run_ps(self, text):
        return subprocess.run([PWSH, '-NoProfile', '-Command', text], cwd=ROOT,
                              capture_output=True, text=True, timeout=30)

    @classmethod
    def setUpClass(cls):
        result = subprocess.run([PWSH, '-NoProfile', '-File', str(AREA / 'Invoke-CurrentBuildSsms.ps1'),
            '-PlanPath', str(ROOT / '.runtime/unused-current-ssms.json'), '-DescribeOnly'],
            capture_output=True, text=True, timeout=30)
        if result.returncode:
            raise AssertionError(result.stderr)
        cls.description = json.loads(result.stdout)

    def test_current_guard_and_complete_method_in_bound_plan(self):
        text = self.description['canonical']
        for name in ('Invoke-CurrentBuildSsms.ps1', 'CurrentBuildArtifacts.ps1',
                     'Current.Build.20261104.json', 'Current.Build.Native.20261104.json'):
            self.assertIn(name, text)
        self.assertIn("'CurrentBuildArtifacts.ps1')", text)
        self.assertIn('SQLCMD_ERROR_STOPS_BEFORE_LATER_SENTINEL', self.description['gui'])
        self.assertIn('EXECUTION_ENVELOPE_PRESERVES_COMPLETE_COPY_AND_RECEIPT', self.description['gui'])

    def test_preflight_still_precedes_database_and_requires_windows(self):
        text = self.description['canonical']
        self.assertLess(text.index(' Invoke-SsmsTargetPreflight\n'), text.index('Exec-Client $master ($prepare.Replace'))
        for guard in ('WRONG_LAB_TARGET', 'WINDOWS_AUTH_REQUIRED', 'ENCRYPTED_CONNECTION_REQUIRED'):
            self.assertIn(guard, self.description['preflightQuery'])

    def test_installed_api_check_uses_current_parameter_count(self):
        text = self.description['canonical']
        self.assertIn(".Rows[0].N-eq 40) 'CURRENT_INSTALLED_API'", text)
        self.assertNotIn(".Rows[0].N-eq 38) 'CURRENT_INSTALLED_API'", text)

    def guard_probe(self, fault, expected):
        # Hash/record probes stop before parser extraction, SQL, credential access, or GUI.
        script = r'''
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repoRoot=(Get-Location).Path
. './Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/RecoveryFixture.ps1'
function Get-ClientHash([string]$Path){
 if($Path.Contains('ContosoArtifacts')){
  $record=Get-Content './Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.Build.Native.20261104.json' -Raw|ConvertFrom-Json
  switch([IO.Path]::GetFileName($Path)){
   'Toolbelt.Tsql.SsisDebug.dll' {return $record.qualified_assembly_sha256.ToUpperInvariant()}
   'Deploy.WithAssembly.sql' {return $record.qualified_deploy_sql_sha256.ToUpperInvariant()}
   'Uninstall.Expanded.sql' {return $record.qualified_uninstall_sql_sha256.ToUpperInvariant()}
   'Toolbelt.Tsql.SsisDebug.trust-manifest.json' {return $record.qualified_trust_manifest_sha256.ToUpperInvariant()}
  }
 }
 return (Get-FileHash -LiteralPath $Path).Hash
}
$baseline=${function:Get-ClientHash}
function Get-ClientHash([string]$Path){
 if(@FAULT@){return '0'*64}
 & $baseline $Path
}
. './Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/CurrentBuildArtifacts.ps1'
try{Assert-RecoveryArtifacts @{ssis=(Join-Path $repoRoot '.runtime/ContosoArtifacts')};throw 'UNEXPECTED_ACCEPTANCE'}
catch{if($_.Exception.Message -cne '@EXPECTED@'){throw};'EXPECTED_REJECTION'}
'''
        result = self.run_ps(script.replace('@FAULT@', fault).replace('@EXPECTED@', expected))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('EXPECTED_REJECTION', result.stdout)

    def test_changed_approval_record_rejected(self):
        self.guard_probe("$Path.EndsWith('Current.Build.20261104.json')", 'SSIS_CURRENT_SSMS_APPROVAL_RECORD')

    def test_stale_dll_rejected(self):
        self.guard_probe("$Path.EndsWith('Toolbelt.Tsql.SsisDebug.dll')", 'SSIS_CURRENT_SSMS_ARTIFACT_CHANGED')

    def test_wrong_deployment_rejected(self):
        self.guard_probe("$Path.EndsWith('Deploy.WithAssembly.sql')", 'SSIS_CURRENT_SSMS_ARTIFACT_CHANGED')

    def test_changed_product_source_rejected(self):
        self.guard_probe("$Path.EndsWith('ProcedureDefinition.cs')", 'SSIS_CURRENT_SSMS_PRODUCT_SOURCE_CHANGED')


if __name__ == '__main__':
    unittest.main()

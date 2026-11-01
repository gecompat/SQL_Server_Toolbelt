"""Gegenproben für Quellenbindung, Abbruchorakel und garantiert SQL-freien Preflight."""
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import validate_ssis_preparation_recovery as validator


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.report = json.loads((ROOT / validator.RECORD).read_text())

    def check(self, report=None, read=None):
        validator.validate_report(report or self.report, read or (lambda p: (ROOT / p).read_bytes()))

    def test_actual_source_bound_aggregate(self):
        validator.validate(ROOT)

    def test_mutated_native_assertions_rejected(self):
        for section, key in [('preparation', 'assertions'), ('host', 'assertions'), ('sql_transport', 'assertions')]:
            with self.subTest(section=section):
                r = copy.deepcopy(self.report)
                r[section][key] -= 1
                with self.assertRaises(ValueError):
                    self.check(r)

    def test_wrong_target_or_missing_target_rejected(self):
        for kind in ('patch', 'missing', 'order'):
            r = copy.deepcopy(self.report)
            if kind == 'patch': r['preparation']['cases'][0]['patch'] = 'CU31'
            elif kind == 'missing': r['preparation']['cases'].pop()
            else: r['preparation']['cases'].reverse()
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                self.check(r)

    def test_failed_or_unreconciled_scope_rejected(self):
        changes = [('preparation', 'cases', 0, 'fresh_independent_audit'),
                   ('preparation', 'cases', 0, 'configuration_restored'),
                   ('preparation', 'cases', 0, 'database_removed')]
        for section, key, index, field in changes:
            r = copy.deepcopy(self.report)
            r[section][key][index][field] = False
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)
        for field in ('configuration_restored', 'trust_restored', 'other_consumers_unchanged'):
            r = copy.deepcopy(self.report); r['sql_transport'][field] = False
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)

    def test_unobserved_or_successful_termination_rejected(self):
        for field, value in [('interrupted_exit_code', 0), ('partial_json_rejected', False),
                             ('fresh_output_identical', False), ('input_unchanged', False),
                             ('interrupted_exit_code', True)]:
            r = copy.deepcopy(self.report); r['host']['cases'][0][field] = value
            with self.subTest(field=field, value=value), self.assertRaises(ValueError): self.check(r)

    def test_numeric_values_cannot_substitute_native_boolean_oracles(self):
        for section, field in [('preparation', 'windows_guest_authentication'),
                               ('sql_transport', 'processKilled')]:
            r = copy.deepcopy(self.report)
            r[section]['cases'][0][field] = 1
            with self.subTest(section=section), self.assertRaises(ValueError): self.check(r)

    def test_all_modes_and_both_faults_required(self):
        for change in ('missing', 'duplicate'):
            r = copy.deepcopy(self.report)
            if change == 'missing': r['host']['cases'].pop()
            else: r['host']['cases'][1] = copy.deepcopy(r['host']['cases'][0])
            with self.subTest(change=change), self.assertRaises(ValueError): self.check(r)

    def test_source_and_resealed_source_rejected(self):
        path = validator.AREA + 'RecoveryFixture.ps1'
        modified = (ROOT / path).read_bytes() + b'\n# changed\n'
        read = lambda p: modified if p == path else (ROOT / p).read_bytes()
        with self.assertRaises(ValueError): self.check(read=read)
        self.report['sql_transport']['source_sha256'][path] = hashlib.sha256(modified).hexdigest().upper()
        with self.assertRaises(ValueError): self.check(read=read)

    def test_common_delta_cannot_change_sql_coordinator_branch(self):
        original = (ROOT / validator.COMMON).read_bytes()
        changed = original.replace(b"$b['Pooling']=$false", b"$b['Pooling']=$true")
        self.assertNotEqual(original, changed)
        self.report['source_integration']['current_sha256'] = validator.digest(changed)
        with self.assertRaises(ValueError):
            self.check(read=lambda p: changed if p == validator.COMMON else (ROOT / p).read_bytes())

    def test_common_change_cannot_be_generalized(self):
        self.report['source_integration']['kind'] = 'any_windows_change'
        with self.assertRaises(ValueError): self.check()

    def test_path_escape_and_extra_source_rejected(self):
        for path in ('../outside.sql', '/outside.sql', 'C:\\outside.sql'):
            r = copy.deepcopy(self.report)
            pins = r['preparation']['source_sha256']
            pins[path] = pins.pop(validator.COMMON)
            with self.subTest(path=path), self.assertRaises(ValueError): self.check(r)

    def test_caller_rollback_and_session_end_required(self):
        for field in ('callerChangesRolledBack', 'serverSessionGone', 'freshResultsIdentical'):
            r = copy.deepcopy(self.report); r['sql_transport']['cases'][1][field] = False
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)

    def test_limits_and_coordinator_survival_cannot_be_erased(self):
        r = copy.deepcopy(self.report); r['not_qualified'] = []
        with self.assertRaises(ValueError): self.check(r)
        r = copy.deepcopy(self.report); r['sql_transport']['sql_server_or_vm_killed'] = True
        with self.assertRaises(ValueError): self.check(r)


class WindowsInstallerEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.report = json.loads((ROOT / validator.WINDOWS_RECORD).read_text())
        self.recovery = json.loads((ROOT / validator.RECORD).read_text())

    def check(self, report=None, read=None):
        validator.validate_windows_report(report or self.report, read or (lambda p: (ROOT / p).read_bytes()), self.recovery)

    def test_actual_windows_installer_scope_preserves_failed_gui(self):
        self.check()

    def test_sql_login_and_new_privileges_cannot_become_windows_evidence(self):
        for field, value in [('client', 'SQL'), ('existing_sysadmin', False), ('new_permissions', True)]:
            r = copy.deepcopy(self.report); r['authentication'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)

    def test_failed_gui_cannot_be_relabelled_pass_or_executed(self):
        for field, value in [('state', 'PASS_CLEANED'), ('ssms_qualified', True), ('gui_queries_executed', 1),
                             ('own_ssms_closed', False), ('gui_queries_executed', False)]:
            r = copy.deepcopy(self.report); r['coordinator'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)

    def test_failed_cleanup_or_missing_independent_audit_rejected(self):
        for field in self.report['cleanup']:
            r = copy.deepcopy(self.report); r['cleanup'][field] = False
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)

    def test_changed_and_resealed_windows_method_rejected(self):
        path = validator.AREA + 'ClientGuiHook.ps1'
        data = (ROOT / path).read_bytes() + b'\n# changed\n'
        read = lambda p: data if p == path else (ROOT / p).read_bytes()
        with self.assertRaises(ValueError): self.check(read=read)
        r = copy.deepcopy(self.report); r['source_sha256'][path] = validator.digest(data)
        with self.assertRaises(ValueError): self.check(r, read)

    def test_missing_source_or_forged_lab_support_rejected(self):
        r = copy.deepcopy(self.report); r['source_sha256'].pop(validator.COMMON)
        with self.assertRaises(ValueError): self.check(r)
        for field, value in [('support_source_commit', '0'*40), ('launcher_sha256', '0'*64),
                             ('automatic_retry', True), ('credential_returned', True)]:
            r = copy.deepcopy(self.report); r['lab_support'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)

    def test_partial_install_or_incomplete_script_rejected(self):
        for section, field, value in [('installer', 'first_and_repeat_passes', 1),
                                     ('installer', 'repeat_trust_unchanged', False),
                                     ('client_baseline', 'complete_executable_debugscript', False),
                                     ('client_baseline', 'target_rows', 0)]:
            r = copy.deepcopy(self.report); r[section][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.check(r)

    def test_transport_scope_and_limits_cannot_be_expanded(self):
        r = copy.deepcopy(self.report); r['not_qualified'] = []
        with self.assertRaises(ValueError): self.check(r)
        r = copy.deepcopy(self.report); r['transport']['authenticated_tls_claimed'] = True
        with self.assertRaises(ValueError): self.check(r)


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell unavailable; native SQL is never a fallback')
class PreflightTests(unittest.TestCase):
    def setUp(self):
        runtime = ROOT / '.runtime'; runtime.mkdir(exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(prefix='ssis-recovery-preflight-', dir=runtime)
        self.stage = Path(self.temporary.name)
        assert self.stage.resolve().is_relative_to(runtime.resolve())
        self.plan = self.stage / 'plan.json'
        native = json.loads((ROOT / validator.RECORD).read_text())['preparation']
        self.value = {'contract': 'ssis-server-preparation/1',
                      'targets': [{'version': v, 'patch': p, 'key': 'synthetic-' + v}
                                  for v,p in [('2019','CU32'),('2022','CU26'),('2025','CU8')]],
                      'files': {p: validator.digest((ROOT / p).read_bytes()) for p in native['source_sha256']}}

    def tearDown(self):
        assert self.stage.resolve().is_relative_to((ROOT / '.runtime').resolve())
        self.temporary.cleanup()

    def run_preflight(self, value):
        self.plan.write_text(json.dumps(value), encoding='utf-8')
        env = dict(os.environ, SQL_SERVER_LAB_TEST_ENV_FILE=str(self.stage / 'MUST_NOT_BE_READ.json'))
        return subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File',
                               str(ROOT / validator.AREA / 'Invoke-Preparation.ps1'), '-Mode', 'Run',
                               '-PlanPath', str(self.plan), '-ExpectedPlanSha256', validator.digest(self.plan.read_bytes()),
                               '-ValidateOnly'], capture_output=True, text=True, env=env, timeout=25)

    def test_validated_without_lab_file_or_sql(self):
        r = self.run_preflight(self.value)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('no SQL or Lab import', r.stdout)

    def test_resealed_missing_source_rejected_before_lab(self):
        self.value['files'].pop(validator.COMMON)
        r = self.run_preflight(self.value)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('PLAN_SCHEMA', r.stderr)

    def test_resealed_changed_source_rejected_before_lab(self):
        self.value['files'][validator.COMMON] = '0' * 64
        r = self.run_preflight(self.value)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('SOURCE_CHANGED', r.stderr)

    def test_resealed_different_target_rejected_before_lab(self):
        self.value['targets'][2]['patch'] = 'RTM'
        r = self.run_preflight(self.value)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('PLAN_SCHEMA', r.stderr)

    def test_canonical_function_parameters_and_expansion_retained(self):
        script = self.stage / 'definitions.ps1'
        script.write_text("""$ErrorActionPreference='Stop'
$repoRoot=$env:SSIS_TEST_ROOT
. (Join-Path $repoRoot 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/LabClientCommon.ps1')
. (Join-Path $repoRoot 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/RecoveryFixture.ps1')
Import-RecoveryDefinitions
if(-not (Get-Command Expand).Parameters.ContainsKey('Path') -or -not (Get-Command Batches).Parameters.ContainsKey('Mode')){throw 'LOST_PARAMETERS'}
$text=Expand (Join-Path $repoRoot 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')
if($text-match '(?m)^:r\\s' -or -not $text.Contains('USP_PrepareResultTable')){throw 'EXPANSION_INCOMPLETE'}
$mock=[pscustomobject]@{Command=[Data.SqlClient.SqlCommand]::new()}
$mock|Add-Member ScriptMethod CreateCommand {return $this.Command}
try{[void](Invoke-RecoveryExplain $mock ([byte[]]@(1)) 'bindings-template' $null $null)}catch{}
if($mock.Command.Parameters['@Bindings'].Value-isnot [DBNull] -or $mock.Command.Parameters['@CatalogBindings'].Value-isnot [DBNull]){throw 'JSON_NULL_LOST'}
'NO_SQL_DEFINITION_PARAMETER_NULL_TEST_PASS'
""", encoding='utf-8')
        r = subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File', str(script)],
                           capture_output=True, text=True, env=dict(os.environ, SSIS_TEST_ROOT=str(ROOT)), timeout=25)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('NO_SQL_DEFINITION_PARAMETER_NULL_TEST_PASS', r.stdout)

    def test_installer_witness_retains_datetime2_precision_without_sql(self):
        script = self.stage / 'witness.ps1'
        script.write_text("""$ErrorActionPreference='Stop'
. (Join-Path $env:SSIS_TEST_ROOT 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/ClientGuiHook.ps1')
$connection=[Data.SqlClient.SqlConnection]::new()
$started=[datetime]::ParseExact('2001-02-03T04:05:06.1234567','yyyy-MM-ddTHH:mm:ss.fffffff',[Globalization.CultureInfo]::InvariantCulture)
$old=[Globalization.CultureInfo]::CurrentCulture
try{
 foreach($culture in @('de-AT','en-US')){
  [Globalization.CultureInfo]::CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo($culture)
  $cmd=New-ClientTrustWitnessCommand $connection ('AA'*64) $started
  try{
   if($cmd.Parameters['@started'].SqlDbType-ne [Data.SqlDbType]::DateTime2 -or $cmd.Parameters['@started'].Scale-ne 7 -or $cmd.Parameters['@started'].Value.Ticks-ne $started.Ticks){throw 'DATE_PRECISION_LOST'}
   if($cmd.Parameters['@hash'].Size-ne 64 -or $cmd.Parameters['@hash'].Value.Length-ne 64){throw 'HASH_PARAMETER_LOST'}
   if($cmd.CommandText.Contains('2001') -or $cmd.CommandText.Contains('CONVERT(datetime') -or -not $cmd.CommandText.Contains('created_by=SUSER_SNAME()')){throw 'WITNESS_CONTRACT_LOST'}
  }finally{$cmd.Dispose()}
 }
}finally{[Globalization.CultureInfo]::CurrentCulture=$old;$connection.Dispose()}
'DATE_WITNESS_NO_SQL_PASS'
""", encoding='utf-8')
        r = subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File', str(script)],
                           capture_output=True, text=True, env=dict(os.environ, SSIS_TEST_ROOT=str(ROOT)), timeout=25)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('DATE_WITNESS_NO_SQL_PASS', r.stdout)

    def test_windows_installer_handoff_opens_one_target_database_connection(self):
        script = self.stage / 'handoff.ps1'
        script.write_text("""$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $env:SSIS_TEST_ROOT 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/ClientGuiHook.ps1')
$repoRoot=$PSScriptRoot
$plan=@{ssis=(Join-Path $PSScriptRoot 'ssis');parser=(Join-Path $PSScriptRoot 'parser');sqlcmd='synthetic-unused'}
$installerDirectory=Join-Path $repoRoot 'Modules/toolbelt.tsql.ssis-debug/Examples/Installation'
foreach($d in @($plan.ssis,$plan.parser,$installerDirectory)){[void][IO.Directory]::CreateDirectory($d)}
foreach($pair in @(@($plan.ssis,'Toolbelt.Tsql.SsisDebug.dll'),@($plan.parser,'Toolbelt.Tsql.ScriptParser.dll'),@($plan.parser,'Microsoft.SqlServer.TransactSql.ScriptDom.dll'))){[IO.File]::WriteAllText((Join-Path $pair[0] $pair[1]),'synthetic hash input only')}
[IO.File]::WriteAllText((Join-Path $installerDirectory 'Install-Local.ps1'),'param($Server,$Database,$RepositoryRoot,$ParserReleaseDirectory,$SsisReleaseDirectory,$SqlcmdPath,$TrustServerCertificate);$global:installerCalls++')
$global:installerCalls=0;$script:opens=0;$script:connection=$null
$journal=[ordered]@{ownedTrust=@();state='';authentication='';authScheme=''}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new();$builder['Data Source']='localhost'
$db='ContosoClientHandoff';$target=[pscustomobject]@{key='synthetic'};$master=$null
function Save {}
function Check($Value,$Name){if(-not $Value){throw $Name}}
function Query-Client($Connection,[string]$Sql){
 if($Sql.Contains('auth_scheme')){return [pscustomobject]@{Rows=@([pscustomobject]@{A='NTLM';S=1})}}
 if($Sql.Contains('COUNT_BIG')){return [pscustomobject]@{Rows=@([pscustomobject]@{N=1})}}
 if($Sql.Contains('SYSDATETIME')){return [pscustomobject]@{Rows=@([pscustomobject]@{T=[datetime]'2001-02-03T04:05:06'})}}
 throw 'UNEXPECTED_SQL_IN_OFFLINE_DOUBLE'
}
function Get-RecoveryTrust($Connection){return 'synthetic unchanged trust'}
function Same-Client($A,$B){return $A-ceq $B}
function Open-ClientSql($Entry,[string]$Database,[switch]$Windows){
 if($Entry.key-cne 'synthetic' -or $Database-cne $db -or -not $Windows){throw 'WRONG_CLIENT_DATABASE_OR_AUTH'}
 $script:opens++;return [pscustomobject]@{database=$Database;Windows=$true}
}
Invoke-ClientInstallation
if($global:installerCalls-ne 2 -or $script:opens-ne 1 -or $null-eq $script:connection -or $script:connection.database-cne $db){throw 'WINDOWS_TARGET_CONNECTION_NOT_INITIALIZED'}
'WINDOWS_INSTALLER_HANDOFF_NO_SQL_PASS'
""", encoding='utf-8')
        r = subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File', str(script)],
                           capture_output=True, text=True, env=dict(os.environ, SSIS_TEST_ROOT=str(ROOT)), timeout=25)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('WINDOWS_INSTALLER_HANDOFF_NO_SQL_PASS', r.stdout)


if __name__ == '__main__':
    unittest.main()

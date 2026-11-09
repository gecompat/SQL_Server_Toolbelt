"""File-Content-AppLock: echte Admission ohne Lab/SQL."""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import copy
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-FileContentLeaseRecoveryLab.ps1'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class FileRecoveryAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clone-planner-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.file.content\nSELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = [ROOT / ('Tests/Release/Runtime/' + name) for name in ('FileContent.LeaseRecovery.Contract.ps1',)]
        files = [DRIVER, *fixtures, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1', 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        files += [ROOT / 'Tests/Release/Runtime/FileContent.LockProfiles.Contract.ps1', ROOT / 'Modules/toolbelt.file.content/Deployment/Uninstall.sql', ROOT / 'Tests/Release/Runtime/LifecycleProfiles.Contract.ps1']
        for module in ('toolbelt.core.result-table','toolbelt.file.content'):
            root = ROOT / 'Modules' / module
            files += [root / 'module.yaml', *sorted((root/'Deployment').rglob('*.sql')), *sorted((root/'Source').rglob('*.sql'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        cases = []
        cases = [dict(Platform='windows', Version='2025', Patch='CU8', CL=170, modes=['local','central'])]
        self.record = dict(schema_version='file-content-lease-recovery/v1', explicit_qualification_approved=True,
                           started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
                           fixtures=list(map(str, fixtures)), exports=exports, cases=cases,
                           pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in sorted(set(files))])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
                                 '-CaseIndex', '0', '-ValidateOnly'], cwd=ROOT, capture_output=True, text=True, timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')), [])
        return result

    def reject(self, mutate):
        record = copy.deepcopy(self.record)
        mutate(record)
        result = self.admission(record)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_valid_scope_without_lab_import(self):
        result = self.admission()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('no Lab import or SQL', result.stdout)

    def test_authority_requires_boolean_true(self):
        self.reject(lambda r: r.update(explicit_qualification_approved=False))
        self.reject(lambda r: r.update(explicit_qualification_approved='true'))

    def test_deadline_expiry_and_extension(self):
        expired = datetime.now(timezone.utc) - timedelta(hours=2)
        self.reject(lambda r: r.update(started_utc=expired.isoformat(), deadline_utc=(expired + timedelta(minutes=45)).isoformat()))
        self.reject(lambda r: r.update(deadline_utc=(datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()))

    def test_later_target_cannot_be_relabelled(self):
        self.reject(lambda r: r['cases'][0].update(Patch='base'))
        self.reject(lambda r: r['cases'][0].update(CL=150))

    def test_each_target_requires_both_declared_modes(self):
        for index in (0,):
            self.reject(lambda r: r['cases'][index].update(modes=['central']))

    def test_canonical_fixture_and_method_pins_are_mandatory(self):
        fixture = self.directory / 'imposter.sql'
        fixture.write_bytes(Path(self.record['fixtures'][0]).read_bytes())
        record = copy.deepcopy(self.record)
        record['fixtures'] = [str(fixture)]
        record['pins'].append(dict(path=str(fixture), sha256=hashlib.sha256(fixture.read_bytes()).hexdigest().upper()))
        self.assertNotEqual(self.admission(record).returncode, 0)
        self.reject(lambda r: r['pins'].pop(0))

    def test_changed_real_export_bytes_are_rejected(self):
        Path(self.record['exports']['local']).write_text('SELECT 2;\n', encoding='utf-8')
        self.assertNotEqual(self.admission().returncode, 0)

    def test_unpinned_product_include_is_rejected(self):
        self.reject(lambda r: r.update(pins=[p for p in r['pins'] if not p['path'].endswith('USP_LoadTextFile.sql')]))

    def scope(self, text, from_file=False):
        quoted = "'" + str(text).replace("'", "''") + "'"
        payload = "([IO.File]::ReadAllText(" + quoted + "))" if from_file else quoted
        script = "$ErrorActionPreference='Stop';$errors=$null;" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile('" + str(DRIVER).replace("'", "''") + "',[ref]$null,[ref]$errors);" + \
            "$functions=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-FileRecoveryFixtureScope'},$true));" + \
            "if($errors.Count-or$functions.Count-ne1){throw 'SCOPE_FUNCTION'};. ([scriptblock]::Create($functions[0].Extent.Text));" + \
            "Assert-FileRecoveryFixtureScope " + payload + ";'PASS fixture scope without SQL'"
        return subprocess.run(['pwsh', '-NoProfile', '-Command', script], cwd=ROOT, capture_output=True, text=True, timeout=20)

    def test_forbidden_fixture_rights_and_server_scope_rejected(self):
        for text in ('GRANT EXECUTE ON dbo.Synthetic TO Contoso;', 'CREATE USER Contoso WITHOUT LOGIN;',
                     'ALTER AUTHORIZATION ON SCHEMA::dbo TO Contoso;', 'ALTER DATABASE Synthetic SET TRUSTWORTHY ON;',
                     'EXEC sys.sp_configure N\'clr enabled\',1;', 'CREATE TRIGGER Synthetic ON ALL SERVER FOR CREATE_DATABASE AS SELECT 1;',
                     'CREATE ASSEMBLY Contoso FROM 0x00;'):
            result = self.scope(text)
            self.assertNotEqual(result.returncode, 0, text)
            self.assertIn('FILE_RECOVERY_FIXTURE_EXCEEDS_SCOPE', result.stdout + result.stderr)

    def test_all_original_fixtures_remain_permitted(self):
        for path in self.record['fixtures']:
            result = self.scope(path, from_file=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)




    def test_kill_sql_rejects_foreign_or_worker_session_numbers(self):
        fixture = ROOT / 'Tests/Release/Runtime/FileContent.LeaseRecovery.Contract.ps1'
        script = "$ErrorActionPreference='Stop';$e=$null;" + \
            "$a=[Management.Automation.Language.Parser]::ParseFile('" + str(fixture).replace("'", "''") + "',[ref]$null,[ref]$e);" + r"""
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Get-FileRecoveryKillSql'},$true))
if($e.Count-or$n.Count-ne1){throw 'KILL_FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
$sql=Get-FileRecoveryKillSql 71 72 9
if($sql-notmatch'KILL 71;'-or$sql-notmatch's.open_transaction_count=0'-or$sql-notmatch'c.connection_id=TRY_CONVERT'-or$sql-notmatch's.context_info=@OwnerTag'-or$sql-notmatch'sys.dm_exec_requests'){throw 'LAST_SERVER_GUARDS_MISSING'}
foreach($p in @(@(71,71,9),@(1,72,9),@(71,1,9),@(71,72,1),@(0,72,9))){
 $blocked=$false
 try{Get-FileRecoveryKillSql $p[0] $p[1] $p[2]|Out-Null}catch{if($_.Exception.Message-ne'FILE_RECOVERY_OWN_SEPARATE_SESSION_REQUIRED'){throw};$blocked=$true}
 if(-not$blocked){throw 'FOREIGN_SESSION_ACCEPTED'}
}
'PASS own idle holder termination guards'
"""
        result = subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_read_statement_transaction_is_not_a_user_transaction(self):
        fixture = ROOT / 'Tests/Release/Runtime/FileContent.LeaseRecovery.Contract.ps1'
        script = "$ErrorActionPreference='Stop';$e=$null;" + \
            "$a=[Management.Automation.Language.Parser]::ParseFile('" + str(fixture).replace("'", "''") + "',[ref]$null,[ref]$e);" + r"""
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Assert-FileRecoveryIdentity'},$true))
if($e.Count-or$n.Count-ne1){throw 'IDENTITY_FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
$worker=[pscustomobject]@{Spid=71;DatabaseId=9}
foreach($state in @(0,1)){
 Assert-FileRecoveryIdentity @([pscustomobject]@{Spid=72;DatabaseId=9;TranCount=0;XactState=$state;ConnectionId='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'}) $worker
}
foreach($rows in @(@(),@([pscustomobject]@{DatabaseId=9;TranCount=1;XactState=1;ConnectionId='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'}),
 @([pscustomobject]@{DatabaseId=9;TranCount=0;XactState=-1;ConnectionId='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'}),
 @([pscustomobject]@{DatabaseId=8;TranCount=0;XactState=0;ConnectionId='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'}),
 @([pscustomobject]@{DatabaseId=9;TranCount=0;XactState=0;ConnectionId='00000000-0000-0000-0000-000000000000'}))){
 $blocked=$false
 try{Assert-FileRecoveryIdentity $rows $worker}catch{if($_.Exception.Message-ne'FILE_RECOVERY_IDLE_CONNECTION_REQUIRED'){throw};$blocked=$true}
 if(-not$blocked){throw 'INVALID_CALLER_IDENTITY_ACCEPTED'}
}
'PASS autocommit statement versus user transaction distinction'
"""
        result = subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_original_idle_oracle_keeps_external_transaction_and_lock_checks(self):
        helper = ROOT / 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1'
        script = "$ErrorActionPreference='Stop';$e=$null;" + \
            "$a=[Management.Automation.Language.Parser]::ParseFile('" + str(helper).replace("'", "''") + "',[ref]$null,[ref]$e);" + r"""
foreach($name in @('Test-ExternalSessionIdle','Test-ContenderStateIdle')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'ORACLE_FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
function New-Samples{
 return [ordered]@{errors=@{external=$null;combined=$null;isolated=$null;session=$null};
  external_rows=@([pscustomobject]@{SessionId=71;OpenTransactionCount=0;UserTransactionCount=0;ApplicationLockCount=0});
  combined_rows=@([pscustomobject]@{Spid=71;TranCount=0;XactState=1});isolated_rows=@([pscustomobject]@{TranCount=0;XactState=0});session_rows=@([pscustomobject]@{ScalarValue=71})}
}
$s=New-Samples
if(-not(Test-ContenderStateIdle $s ([Data.ConnectionState]::Open) 71)){throw 'ORIGINAL_IDLE_PROFILE_REJECTED'}
foreach($field in @('OpenTransactionCount','UserTransactionCount','ApplicationLockCount')){
 $s=New-Samples;$s.external_rows[0].$field=1
 if(Test-ContenderStateIdle $s ([Data.ConnectionState]::Open) 71){throw 'EXTERNAL_LEAK_ACCEPTED'}
}
$s=New-Samples;$s.isolated_rows[0].XactState=-1
if(Test-ContenderStateIdle $s ([Data.ConnectionState]::Open) 71){throw 'DOOMED_STATE_ACCEPTED'}
$s=New-Samples;$s.errors.external='synthetic adapter failure'
if(Test-ContenderStateIdle $s ([Data.ConnectionState]::Open) 71){throw 'OBSERVER_ERROR_ACCEPTED'}
"""
        result = subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)


if __name__ == '__main__':
    unittest.main()

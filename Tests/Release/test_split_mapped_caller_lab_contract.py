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
DRIVER = ROOT / 'Tests/Release/Invoke-SplitAdvancedMappedCallerLab.ps1'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class SplitMappedAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clone-planner-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.string.split-advanced\nSELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = [ROOT / ('Tests/Release/Runtime/' + name) for name in ('SplitAdvanced.MappedCaller.Contract.ps1',)]
        files = [DRIVER, *fixtures, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1', 
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        files += [ROOT / 'Modules/toolbelt.string.split-advanced/Deployment/Uninstall.sql', ROOT / 'Tests/Release/Runtime/SplitAdvanced.LifecycleProfiles.Contract.ps1']
        for module in ('toolbelt.core.result-table','toolbelt.string.split-advanced'):
            root = ROOT / 'Modules' / module
            files += [root / 'module.yaml', *sorted((root/'Deployment').rglob('*.sql')), *sorted((root/'Source').rglob('*.sql'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        cases = []
        cases = [dict(Platform='windows', Version='2025', Patch='CU8', CL=170, modes=['central'])]
        self.record = dict(schema_version='split-advanced-mapped-caller/v1', explicit_qualification_approved=True,
                           temporary_identity_rights_approved=True,database_right_set=['CONNECT consumer','CONNECT installation','SELECT installation.toolbelt_string.TVF_SplitAdvanced'],started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
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
            self.reject(lambda r: r['cases'][index].update(modes=['local']))

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
        self.reject(lambda r: r.update(pins=[p for p in r['pins'] if not p['path'].endswith('TVF_SplitAdvanced.sql')]))

    def scope(self, text, from_file=False):
        quoted = "'" + str(text).replace("'", "''") + "'"
        payload = "([IO.File]::ReadAllText(" + quoted + "))" if from_file else quoted
        script = "$ErrorActionPreference='Stop';$errors=$null;" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile('" + str(DRIVER).replace("'", "''") + "',[ref]$null,[ref]$errors);" + \
            "$functions=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-SplitMappedFixtureScope'},$true));" + \
            "if($errors.Count-or$functions.Count-ne1){throw 'SCOPE_FUNCTION'};. ([scriptblock]::Create($functions[0].Extent.Text));" + \
            "Assert-SplitMappedFixtureScope " + payload + ";'PASS fixture scope without SQL'"
        return subprocess.run(['pwsh', '-NoProfile', '-Command', script], cwd=ROOT, capture_output=True, text=True, timeout=20)

    def test_forbidden_fixture_rights_and_server_scope_rejected(self):
        for text in ('GRANT EXECUTE ON dbo.Synthetic TO Contoso;', 'CREATE USER Contoso WITHOUT LOGIN;',
                     'ALTER AUTHORIZATION ON SCHEMA::dbo TO Contoso;', 'ALTER DATABASE Synthetic SET TRUSTWORTHY ON;',
                     'EXEC sys.sp_configure N\'clr enabled\',1;', 'CREATE TRIGGER Synthetic ON ALL SERVER FOR CREATE_DATABASE AS SELECT 1;',
                     'CREATE ASSEMBLY Contoso FROM 0x00;'):
            result = self.scope(text)
            self.assertNotEqual(result.returncode, 0, text)
            self.assertIn('SPLIT_MAPPED_', result.stdout + result.stderr)

    def test_all_original_fixtures_remain_permitted(self):
        for path in self.record['fixtures']:
            result = self.scope(path, from_file=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)




    def test_identity_authority_and_right_set_are_exact(self):
        self.reject(lambda r:r.update(temporary_identity_rights_approved=False))
        self.reject(lambda r:r.update(temporary_identity_rights_approved='true'))
        self.reject(lambda r:r['database_right_set'].append('VIEW DEFINITION installation'))

    def test_missing_mapping_helper_pin_is_rejected(self):
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if not p['path'].endswith('SplitAdvanced.LifecycleProfiles.Contract.ps1')]))

    def test_unapproved_grants_and_identities_are_rejected(self):
        for text in ('GRANT CONNECT TO [Contoso];','GRANT SELECT ON OBJECT::dbo.Source TO [$login];',
                     'GRANT VIEW DEFINITION TO [$login];','CREATE LOGIN Contoso WITH PASSWORD=@Password;',
                     'CREATE USER Contoso FOR LOGIN Contoso;'):
            self.assertNotEqual(self.scope(text).returncode,0,text)

    def fixture_functions(self,names,body):
        path=ROOT/'Tests/Release/Runtime/SplitAdvanced.MappedCaller.Contract.ps1'
        prefix="$ErrorActionPreference='Stop';$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile('"+str(path).replace("'","''")+"',[ref]$null,[ref]$e);"
        for name in names:
            prefix+="$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'"+name+"'},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text));"
        return subprocess.run(['pwsh','-NoProfile','-Command',prefix+body],cwd=ROOT,capture_output=True,text=True,timeout=20)

    def test_permission_plan_contains_only_the_approved_three_rights(self):
        result=self.fixture_functions(['Get-SplitMappedPermissionPlan'],r"""
$p=Get-SplitMappedPermissionPlan ('a'*32)
if($p.databaseRightSet.Count-ne3-or$p.grant-cne('GRANT SELECT ON OBJECT::toolbelt_string.TVF_SplitAdvanced TO ['+$p.login+'];')){throw 'RIGHT_SET'}
foreach($owner in @('', 'Contoso', ('A'*32), ('a'*31)+';')){
 $blocked=$false;try{Get-SplitMappedPermissionPlan $owner|Out-Null}catch{$blocked=$true};if(-not$blocked){throw 'FOREIGN_OWNER_ACCEPTED'}
}
""")
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_golden_query_uses_only_the_owned_central_database(self):
        result=self.fixture_functions(['Get-SplitMappedGoldenSql'],r"""
$q=Get-SplitMappedGoldenSql ('Toolbelt_Release_'+('a'*32)+'_c')
if($q-notmatch'TVF_SplitAdvanced'-or$q-notmatch'ORDER BY Ordinal'){throw 'GOLDEN_SHAPE'}
foreach($db in @('master','Contoso',('Toolbelt_Release_'+('a'*32)+'_u'))){
 $blocked=$false;try{Get-SplitMappedGoldenSql $db|Out-Null}catch{$blocked=$true};if(-not$blocked){throw 'FOREIGN_DATABASE_ACCEPTED'}
}
""")
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_network_observer_requires_real_matching_sql_tcp_context(self):
        result=self.fixture_functions(['Assert-SplitMappedNetwork'],r"""
$ledger=@{login=@{name='ToolbeltSplitMapped_'+('a'*32);sid='0102030405060708090A0B0C0D0E0F10'};mappedReceipts=@([ordered]@{networkObservations=@()})};$control=$null
function Save-ReleaseJournal{}
$script:proof=1;$script:adminFlag=0
function Invoke-ReleaseSql($Connection,$Text,$Parameters=@{},[switch]$Rows){
 if($Text.Contains('SET CONTEXT_INFO')){return}
 if($Text.Contains('ORIGINAL_LOGIN')){return [pscustomobject]@{Spid=71;LoginName=$ledger.login.name;UserName=$ledger.login.name;Sid=[byte[]](1..16);Admin=$script:adminFlag;OwnerRole=0;DbControl=0;Definition=0;ServerControl=0;AnyDefinition=0;ServerState=0;ServerPerformanceState=0}}
 if(-not$Text.Contains('s.context_info=@Tag')-or-not$Text.Contains("c.auth_scheme=N'SQL'")-or-not$Text.Contains("c.net_transport=N'TCP'")-or$Parameters['@Tag'].Length-ne16){throw 'NETWORK_IDENTITY_PREDICATE'}
 return [pscustomobject]@{N=$script:proof}
}
Assert-SplitMappedNetwork ([pscustomobject]@{})
$script:proof=0;$blocked=$false;try{Assert-SplitMappedNetwork $null}catch{if($_.Exception.Message-ne'SPLIT_MAPPED_REAL_SQL_TCP_IDENTITY_REQUIRED'){throw};$blocked=$true};if(-not$blocked){throw 'MISSING_NETWORK_PROOF_ACCEPTED'}
$script:proof=1;$script:adminFlag=1;$blocked=$false;try{Assert-SplitMappedNetwork $null}catch{if($_.Exception.Message-ne'SPLIT_MAPPED_CALLER_NOT_MINIMAL'){throw};$blocked=$true};if(-not$blocked){throw 'ADMINISTRATOR_ACCEPTED'}
""")
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_cleanup_identity_rejects_drift_and_ambiguous_rows(self):
        result=self.fixture_functions(['Test-SplitMappedLoginIdentity'],r"""
$expected=[pscustomobject]@{name='ToolbeltSplitMapped_'+('a'*32);sid=('B'*32);id=71;created=('0'*16);consumer='Toolbelt_Release_'+('a'*32)+'_u'}
$row=[pscustomobject]@{Name=$expected.name;Sid=$expected.sid;Id=71;Created=$expected.created;DefaultDatabase=$expected.consumer;Type='S';Disabled=0;Policy=1;Expiration=1}
if(-not(Test-SplitMappedLoginIdentity $expected @($row))){throw 'OWN_LOGIN_REJECTED'}
foreach($field in @('Name','Sid','Id','Created','DefaultDatabase','Type','Disabled','Policy','Expiration')){
 $bad=$row.PSObject.Copy()
 switch($field){
  'Name' {$bad.Name='ContosoForeign'}; 'Sid' {$bad.Sid='C'*32}; 'Id' {$bad.Id=72}; 'Created' {$bad.Created='1'*16}
  'DefaultDatabase' {$bad.DefaultDatabase='ContosoForeign'}; 'Type' {$bad.Type='U'}
  'Disabled' {$bad.Disabled=1}; 'Policy' {$bad.Policy=0}; 'Expiration' {$bad.Expiration=0}
 }
 if(Test-SplitMappedLoginIdentity $expected @($bad)){throw 'FOREIGN_LOGIN_ACCEPTED'}
}
if((Test-SplitMappedLoginIdentity $expected @())-or(Test-SplitMappedLoginIdentity $expected @($row,$row))){throw 'LOGIN_CARDINALITY'}
""")
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)


if __name__=='__main__':unittest.main()

"""Scope admission and nonempty ACL snapshot counterexamples, no Lab connection."""
from datetime import datetime, timedelta, timezone
from pathlib import Path
import copy
import json
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-JsonConstructorsAclLab.ps1'
PROFILE = ROOT / 'Tests/Release/JsonConstructors.AclUpgrade.ps1'
FIXTURE = ROOT / 'Tests/Release/Runtime/JsonConstructors.AclSetup.sql'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class ConstructorAclTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='constructor-acl-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        cases = []
        for platform in ('windows', 'linux'):
            for version, patch, levels in [('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)), ('2025', 'CU8', (150, 160, 170))]:
                cases.extend(dict(Platform=platform, Version=version, Patch=patch if platform == 'windows' else 'latest',
                                  CL=cl, modes=['local', 'central']) for cl in levels)
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        self.record = dict(schema_version='json-constructors-acl-upgrade/v1',
            explicit_qualification_approved=True, explicit_acl_profile_approved=True,
            started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
            cases=cases, fixture=str(FIXTURE), artifacts=[], exports={}, pins=[])

    def tearDown(self):
        self.temp.cleanup()

    def reject(self, mutate, expected):
        record = copy.deepcopy(self.record)
        mutate(record)
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
                                 '-CaseIndex', '11', '-ValidateOnly'], cwd=ROOT, capture_output=True, text=True, timeout=20)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(expected, result.stdout + result.stderr)
        self.assertFalse(list(self.directory.glob('case-*')))

    def test_each_authority_requires_boolean_true(self):
        for field in ('explicit_qualification_approved', 'explicit_acl_profile_approved'):
            for value in (False, 'true'):
                self.reject(lambda r: r.update({field: value}), 'CONSTRUCTOR_ACL_RUNSET_INVALID')

    def test_deadline_cannot_expire_or_be_extended(self):
        expired = datetime.now(timezone.utc) - timedelta(hours=2)
        self.reject(lambda r: r.update(started_utc=expired.isoformat(), deadline_utc=(expired + timedelta(minutes=45)).isoformat()),
                    'CONSTRUCTOR_ACL_UPGRADE_ADMISSION_CLOSED')
        self.reject(lambda r: r.update(deadline_utc=(datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()),
                    'CONSTRUCTOR_ACL_UPGRADE_ADMISSION_CLOSED')

    def test_later_engine_level_patch_and_mode_are_not_relabelled(self):
        for update in ({'CL': 160}, {'Patch': 'base'}, {'Platform': 'windows'}, {'modes': ['local']}):
            self.reject(lambda r: r['cases'][11].update(update), 'CONSTRUCTOR_ACL_CASE_SCOPE')

    def test_fixture_canonical_path_required(self):
        self.reject(lambda r: r.update(fixture=str(self.directory / 'imposter.sql')), 'CONSTRUCTOR_ACL_CANONICAL_FIXTURE_REQUIRED')

    def test_unknown_or_missing_artifact_roles_rejected(self):
        self.reject(lambda r: None, 'CONSTRUCTOR_ACL_ARTIFACT_SCOPE')
        self.reject(lambda r: r.update(artifacts=[dict(role='core'), dict(role='core'), dict(role='current13')]),
                    'CONSTRUCTOR_ACL_ARTIFACT_SCOPE')

    def profile(self, script):
        command = "$ErrorActionPreference='Stop'; . '" + str(PROFILE).replace("'", "''") + "'; " + script
        return subprocess.run(['pwsh', '-NoProfile', '-Command', command], cwd=ROOT,
                              capture_output=True, text=True, timeout=20)

    def test_empty_partial_or_extra_acl_never_counts_as_nonempty_profile(self):
        result = self.profile(r'''
function Invoke-ReleaseSql {param($Connection,$Sql,[switch]$Rows);return $script:FakeRows}
foreach($n in @(0,3,5)){
 $script:FakeRows=@(1..5|ForEach-Object{@{Kind='procedure'}})+@(@{Kind='caller'})
 if($n){$script:FakeRows+=@(1..$n|ForEach-Object{@{Kind='acl'}})}
 try{$null=Get-ConstructorAclSnapshot $null;throw 'ACCEPTED_BAD_ACL'}catch{if($_.Exception.Message-ne'CONSTRUCTOR_ACL_NONEMPTY_SNAPSHOT_REQUIRED'){throw}}
}
'PASS empty/partial/additional ACL rejected'
''')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_missing_procedure_or_caller_never_counts_as_preservation(self):
        result = self.profile(r'''
function Invoke-ReleaseSql {param($Connection,$Sql,[switch]$Rows);return $script:FakeRows}
$script:FakeRows=@(1..4|ForEach-Object{@{Kind='procedure'}})+@(1..4|ForEach-Object{@{Kind='acl'}})+@(@{Kind='caller'})
try{$null=Get-ConstructorAclSnapshot $null;throw 'ACCEPTED_MISSING_PROCEDURE'}catch{if($_.Exception.Message-ne'CONSTRUCTOR_ACL_NONEMPTY_SNAPSHOT_REQUIRED'){throw}}
$script:FakeRows=@(1..5|ForEach-Object{@{Kind='procedure'}})+@(1..4|ForEach-Object{@{Kind='acl'}})
try{$null=Get-ConstructorAclSnapshot $null;throw 'ACCEPTED_MISSING_CALLER'}catch{if($_.Exception.Message-ne'CONSTRUCTOR_ACL_NONEMPTY_SNAPSHOT_REQUIRED'){throw}}
'PASS missing procedure/caller rejected'
''')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_snapshot_retains_permission_grantor_owner_and_caller_identity(self):
        result = self.profile(r'''
function Invoke-ReleaseSql {param($Connection,$Sql,[switch]$Rows);return $script:FakeRows}
$script:FakeRows=@(1..5|ForEach-Object{[ordered]@{Kind='procedure';Id=$_;Owner=-1;EffectiveOwner=1}})+
 @(1..4|ForEach-Object{[ordered]@{Kind='acl';major_id=$_;grantee_principal_id=9;grantor_principal_id=1;type='EX';state='G'}})+
 @([ordered]@{Kind='caller';principal_id=9;Sid='A1';Created='01';type='S';authentication_type=0})
$before=Get-ConstructorAclSnapshot $null
$script:FakeRows[5].grantor_principal_id=2
if($before-ceq(Get-ConstructorAclSnapshot $null)){throw 'GRANTOR_CHANGE_HIDDEN'}
$script:FakeRows[5].grantor_principal_id=1;$script:FakeRows[0].EffectiveOwner=2
if($before-ceq(Get-ConstructorAclSnapshot $null)){throw 'OWNER_CHANGE_HIDDEN'}
$script:FakeRows[0].EffectiveOwner=1;$script:FakeRows[9].Sid='A2'
if($before-ceq(Get-ConstructorAclSnapshot $null)){throw 'CALLER_REPLACEMENT_HIDDEN'}
'PASS actual comparison snapshots expose ACL/owner/caller drift'
''')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_fixture_scope_remains_exact_four_existing_object_grants(self):
        import re
        sql = FIXTURE.read_text(encoding='utf-8-sig')
        targets = re.findall(r'GRANT EXECUTE ON OBJECT::toolbelt_json\.(\w+) TO ContosoJsonCaller;', sql)
        self.assertEqual(targets, ['USP_JsonArray', 'USP_JsonObject', 'USP_JsonArraysByGroup', 'USP_JsonObjectsByGroup'])
        self.assertEqual(len(re.findall(r'\bGRANT\b', sql)), 4)
        self.assertIn('CREATE USER ContosoJsonCaller WITHOUT LOGIN', sql)
        self.assertIn('Test.Release.Owner', sql)
        self.assertIn('Test.Constructor.AclProfile.Approved', sql)
        self.assertNotIn('ALTER AUTHORIZATION', sql)
        self.assertNotIn('CONTROL', sql)


if __name__ == '__main__':
    unittest.main()

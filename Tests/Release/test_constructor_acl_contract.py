"""Scope admission and nonempty ACL snapshot counterexamples, no Lab connection."""
from datetime import datetime, timedelta, timezone
from pathlib import Path
import copy
import json
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-JsonConstructorsAclLab.ps1'
PROFILE = ROOT / 'Tests/Release/JsonConstructors.AclUpgrade.ps1'
FIXTURE = ROOT / 'Tests/Release/Runtime/JsonConstructors.AclSetup.sql'


def scalar_session_guard(sql):
    """Prüft nur die eng begrenzten Fixture-Prädikate, kein allgemeiner SQL-Parser."""
    # Kommentare/Literale dürfen weder eine Beobachtung noch eine Prüfung vortäuschen.
    clean = re.sub(r"--[^\r\n]*|/\*.*?\*/|N?'(?:''|[^'])*'", ' ', sql, flags=re.S | re.I)
    declarations = list(re.finditer(
        r'DECLARE\s+(@\w+)\s+int\s*=\s*@@TRANCOUNT\s*,\s*(@\w+)\s+int\s*=\s*XACT_STATE\(\)\s*;',
        clean, re.I))
    predicates = list(re.finditer(r'\bIF\b(.*?)(?=\bTHROW\b|\bBEGIN\b)', clean, re.S | re.I))
    catalog = [p for p in predicates if re.search(r'\b(?:USER_ID|OBJECT_ID|EXISTS)\b', p.group(1), re.I)]
    if any(re.search(r'\bXACT_STATE\s*\(', predicate.group(1), re.I) for predicate in catalog):
        return False
    for predicate in catalog:
        for declaration in declarations:
            if declaration.end() <= predicate.start() and all(
                    re.search(re.escape(name) + r'\s*<>\s*0', predicate.group(1), re.I)
                    for name in declaration.groups()):
                return True
    return False


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

    def export_record(self):
        exports = {}
        for mode in ('local', 'central'):
            paths = {}
            for part, text in (
                ('base', ':On Error Exit\n-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.json.core\nSELECT 1;\n'),
                ('historical12', 'SELECT 1;\n'), ('current13', '  SET @AssemblyId=NULL;\n')):
                path = self.directory / (mode + '.' + part + '.sql')
                path.write_text(text, encoding='utf-8')
                paths[part] = str(path)
            exports[mode] = paths
        path = self.directory / 'exports.json'
        path.write_text(json.dumps(exports), encoding='utf-8')
        return exports, "$exports=Get-Content -Raw -LiteralPath '" + str(path).replace("'", "''") + "'|ConvertFrom-Json; "

    def test_complete_base_required_before_sql_in_both_modes(self):
        exports, load = self.export_record()
        result = self.profile(load + "function Invoke-ReleaseSql {throw 'SQL_MUST_NOT_RUN'}; Assert-ConstructorAclExports $exports; 'PASS complete base without SQL'")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for text in ('-- BEGIN MODULE toolbelt.json.core\n', '-- BEGIN MODULE toolbelt.core.result-table\n',
                     '-- BEGIN MODULE toolbelt.json.core\n-- BEGIN MODULE toolbelt.core.result-table\n',
                     '-- BEGIN MODULE toolbelt.core.result-table\n-- BEGIN MODULE toolbelt.json.core\n-- BEGIN MODULE toolbelt.unapproved.extra\n'):
            Path(exports['central']['base']).write_text(text, encoding='utf-8')
            result = self.profile(load + "try{Assert-ConstructorAclExports $exports;throw 'ACCEPTED_BAD_CLOSURE'}catch{if($_.Exception.Message-ne'CONSTRUCTOR_ACL_BASE_CLOSURE_REQUIRED'){throw}}; 'PASS wrong closure rejected'")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_fault_anchor_and_unresolved_exports_fail_before_sql(self):
        exports, load = self.export_record()
        for text, error in (('SELECT 1;\n', 'CONSTRUCTOR_ACL_ROLLBACK_ANCHOR'),
                            ('  SET @AssemblyId=NULL;\n  SET @AssemblyId=NULL;\n', 'CONSTRUCTOR_ACL_ROLLBACK_ANCHOR'),
                            (':r unapproved.sql\n  SET @AssemblyId=NULL;\n', 'CONSTRUCTOR_ACL_EXPORT_UNRESOLVED_DIRECTIVES')):
            Path(exports['central']['current13']).write_text(text, encoding='utf-8')
            result = self.profile(load + "try{Assert-ConstructorAclExports $exports;throw 'ACCEPTED_BAD_EXPORT'}catch{if($_.Exception.Message-ne'" + error + "'){throw}}; 'PASS wrong export rejected'")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

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

    def test_catalog_autocommit_counterexamples_are_not_neutral_session_proofs(self):
        for predicate in (
                "USER_ID(N'Contoso') IS NOT NULL OR @@TRANCOUNT<>0 OR XACT_STATE()<>0",
                "XACT_STATE()<>0 OR EXISTS(SELECT 1 FROM sys.objects)"):
            self.assertFalse(scalar_session_guard('IF ' + predicate + ' THROW 53695,N\'stop\',2;'))
        self.assertFalse(scalar_session_guard(
            "-- DECLARE @T int=@@TRANCOUNT,@X int=XACT_STATE();\n"
            "IF USER_ID(N'Contoso') IS NOT NULL OR @T<>0 OR @X<>0 THROW 53695,N'stop',2;"))

    def test_scalar_observation_must_precede_catalog_and_remain_checked(self):
        capture = 'DECLARE @T int=@@TRANCOUNT,@X int=XACT_STATE();'
        guard = "IF USER_ID(N'Contoso') IS NOT NULL OR @T<>0 OR @X<>0 THROW 53695,N'stop',2;"
        self.assertTrue(scalar_session_guard(capture + guard))
        self.assertFalse(scalar_session_guard(guard + capture))
        self.assertFalse(scalar_session_guard(capture + guard.replace(' OR @X<>0', '')))
        self.assertFalse(scalar_session_guard(capture + guard.replace('@X<>0', '0<>0')))
        self.assertFalse(scalar_session_guard(
            capture + guard + " IF USER_ID(N'Contoso') IS NOT NULL OR XACT_STATE()<>0 THROW 53695,N'stop',2;"))

    def test_entry_and_cleanup_keep_both_session_guards_outside_catalog(self):
        self.assertTrue(scalar_session_guard(FIXTURE.read_text(encoding='utf-8-sig')))
        profile = PROFILE.read_text(encoding='utf-8-sig')
        cleanup = profile.split("$cleanup=@'", 1)[1].split("'@", 1)[0]
        self.assertTrue(scalar_session_guard(cleanup))


if __name__ == '__main__':
    unittest.main()

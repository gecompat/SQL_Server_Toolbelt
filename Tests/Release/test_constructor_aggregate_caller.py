"""Aggregate caller authority, exact rights and source-bound admission without SQL."""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import copy
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-JsonConstructorsAggregateCallerLab.ps1'
FIXTURE = ROOT / 'Tests/Release/JsonConstructors.AggregateCaller.sql'
REGISTRY = ROOT / 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'


def quote(value):
    return "'" + str(value).replace("'", "''") + "'"


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class ConstructorAggregateCallerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        registry = json.loads(REGISTRY.read_bytes())
        record = json.loads((ROOT / 'Releases/1.0.0/JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.json').read_bytes())
        cls.artifacts = []
        # Historical record supplies a package locator, not a current whole-ZIP attestation.
        with zipfile.ZipFile(ROOT / record['package']['path']) as archive:
            for module in ('toolbelt.json.core', 'toolbelt.json.constructors'):
                fields = next(x['Fields'] for x in registry['artifacts'] if x['Fields']['moduleId'] == module)
                filename = fields['managedAssembly'] + '.dll'
                names = [n for n in archive.namelist() if n == filename or n.endswith('/' + filename)]
                if len(names) != 1:
                    raise AssertionError('Unique canonical managed DLL required')
                binary = archive.read(names[0])
                if hashlib.sha256(binary).hexdigest() != fields['binarySha256'] or hashlib.sha512(binary).hexdigest() != fields['binarySha512']:
                    raise AssertionError('Canonical registry binary bytes required')
                cls.artifacts.append((module, fields, binary))

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='constructor-metadata-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        artifacts = []
        for module, fields, binary in self.artifacts:
            path = self.directory / (fields['managedAssembly'] + '.dll')
            path.write_bytes(binary)
            artifacts.append(dict(module_id=module, path=str(path), sql_name=fields['sqlAssembly'],
                sha256=hashlib.sha256(binary).hexdigest().upper(), sha512=hashlib.sha512(binary).hexdigest().upper()))
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('SELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        paths = [DRIVER, FIXTURE, REGISTRY, *(Path(a['path']) for a in artifacts),
                 *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/Release/ClrCaller.Environment.ps1', 'Tests/CI/run-csv-memory-lab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        self.record = dict(schema_version='json-constructors-aggregate-caller/v1', explicit_qualification_approved=True, explicit_aggregate_object_grants_approved=True,
            fixture=str(FIXTURE), exports=exports, artifacts=artifacts,
            module_versions={'toolbelt.core.result-table': '1.0.0', 'toolbelt.json.core': '1.0.0', 'toolbelt.json.constructors': '1.3.0'},
            started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
            cases=self.cases('windows'),
            pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in paths])

    @staticmethod
    def cases(platform):
        result = []
        for version, patch, levels in [('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)), ('2025', 'CU8', (150, 160, 170))]:
            result.extend(dict(Platform=platform, Version=version, Patch=patch if platform == 'windows' else 'latest', CL=cl) for cl in levels)
        return result

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None, platform='windows'):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
            '-CaseIndex', '0', '-Platform', platform, '-ValidateOnly'], cwd=ROOT,
            capture_output=True, text=True, timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')), [])
        return result

    def test_actual_both_platform_admission_does_not_import_lab_or_connect(self):
        for platform in ('windows', 'linux'):
            record = copy.deepcopy(self.record)
            record['cases'] = self.cases(platform)
            result = self.admission(record, platform)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('no Lab import or SQL', result.stdout)

    def test_authority_target_pins_and_expired_window_fail_before_sql(self):
        for mutate in (lambda r: r.update(explicit_qualification_approved='true'),
                       lambda r: r.update(explicit_aggregate_object_grants_approved=False),
                       lambda r: r.update(explicit_aggregate_object_grants_approved='true'),
                       lambda r: r['cases'][5].update(CL=160),
                       lambda r: r['cases'][0].update(Patch='base'),
                       lambda r: r['pins'].pop(0),
                       lambda r: r.update(started_utc=(datetime.now(timezone.utc) - timedelta(hours=2)).isoformat(),
                                          deadline_utc=(datetime.now(timezone.utc) - timedelta(minutes=75)).isoformat())):
            record = copy.deepcopy(self.record)
            mutate(record)
            self.assertNotEqual(self.admission(record).returncode, 0)

    def test_self_hashed_foreign_dll_does_not_replace_registry_artifact(self):
        record = copy.deepcopy(self.record)
        artifact = record['artifacts'][0]
        path = Path(artifact['path'])
        path.write_bytes(b'not the known assembly')
        artifact.update(sha256=hashlib.sha256(path.read_bytes()).hexdigest().upper(), sha512=hashlib.sha512(path.read_bytes()).hexdigest().upper())
        for pin in record['pins']:
            if pin['path'] == str(path):
                pin['sha256'] = artifact['sha256']
        self.assertNotEqual(self.admission(record).returncode, 0)

    def test_identical_imposter_fixture_is_not_the_canonical_oracle(self):
        path = self.directory / 'imposter.sql'
        path.write_bytes(FIXTURE.read_bytes())
        record = copy.deepcopy(self.record)
        record['fixture'] = str(path)
        record['pins'].append(dict(path=str(path), sha256=hashlib.sha256(path.read_bytes()).hexdigest().upper()))
        self.assertNotEqual(self.admission(record).returncode, 0)

    def test_only_two_individual_object_grants_and_revoke_oracles(self):
        source = FIXTURE.read_text(encoding='utf-8-sig')
        import re
        grants = re.findall(r'GRANT EXECUTE ON OBJECT::([A-Za-z_.]+) TO \[ContosoAggregateCaller\];', source)
        self.assertEqual(grants, ['toolbelt_json.AGF_JsonArray', 'toolbelt_json.AGF_JsonObject'])
        self.assertEqual(source.count('REVOKE EXECUTE ON OBJECT::'), 2)
        self.assertIn('WITHOUT LOGIN', source)
        self.assertIn("@Error<>229", source)
        self.assertIn('@Positive<>2 OR @Denied<>6', source)
        self.assertIn('EXCEPT SELECT * FROM @Baseline', source)
        self.assertIn("UserRemoved", source)
        self.assertNotRegex(source, r'GRANT (?:SELECT|CONTROL|IMPERSONATE|ALTER|CREATE)')
        self.assertNotIn('ALTER ROLE', source)

    def test_session_context_owner_is_bounded_before_sql_variant_conversion(self):
        # Der echte Release-SQL-Helfer bindet Strings als nvarchar(max).
        # SQL-variant-Kontextwerte brauchen deshalb eine lokale begrenzte Variable.
        source = DRIVER.read_text(encoding='utf-8-sig')
        batch = next(line for line in source.splitlines() if 'sp_set_session_context' in line)
        self.assertIn('DECLARE @ContextOwner nvarchar(32)=@Owner;', batch)
        self.assertIn("Rights.Owner',@value=@ContextOwner;", batch)
        self.assertNotIn("Rights.Owner',@value=@Owner;", batch)
        self.assertLess(batch.index('DECLARE @ContextOwner'), batch.index('sp_set_session_context'))

    def test_source_pinning_product_and_full_server_restoration_are_preserved(self):
        source = DRIVER.read_text(encoding='utf-8-sig')
        for guard in ('Assert-ReleaseInputs', 'originalJournalSHA256', 'Read-ConstructorAggregateCallerTarget',
                      'Assert-ReleaseOwnIdentity', 'Assert-ClrCallerTrustCleanupScope',
                      'Restore-ClrCallerConfiguration', 'CONSTRUCTOR_AGGREGATE_CALLER_PRODUCT_OBJECT_DRIFT',
                      'CONSTRUCTOR_AGGREGATE_CALLER_ASSEMBLY_POST_DRIFT', 'UserRemoved-ne1'):
            self.assertIn(guard, source)
        self.assertLess(source.index('if($ValidateOnly)'), source.index('$lab=Resolve-LabContract'))


if __name__ == '__main__':
    unittest.main()

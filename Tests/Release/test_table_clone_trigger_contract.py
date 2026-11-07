"""Windows-only admission negatives; no private artifacts, Lab import or SQL."""
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
DRIVER = ROOT / 'Tests/Release/Invoke-TableCloneTriggerLab.ps1'
UTF8_CONSOLE = '[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false);$OutputEncoding=[Console]::OutputEncoding;'


def ps_quote(value):
    return "'" + str(value).replace("'", "''") + "'"


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class CloneTriggerAdmissionTests(unittest.TestCase):
    def setUp(self):
        (ROOT / '.runtime').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='clone-trigger-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_bytes(b'-- BEGIN MODULE toolbelt.core.result-table\nSELECT 1;\n-- BEGIN MODULE toolbelt.metadata.table-clone\nSELECT 1;\n')
            exports[mode] = str(path)
        fixtures = [ROOT / ('Modules/toolbelt.metadata.table-clone/Tests/Runtime/' + name)
                    for name in ('Trigger.Contract.sql', 'Trigger.Safety.sql')]
        files = [DRIVER, *fixtures, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1',
            'Tests/CI/run-csv-memory-lab.ps1', 'Tests/Release/ClrCaller.Environment.ps1'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        cases = []
        for version, patch, levels in (('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)),
                                       ('2025', 'CU8', (150, 160, 170))):
            for level in levels:
                cases.append(dict(Platform='windows', Version=version, Patch=patch, CL=level,
                                  modes=['local', 'central']))
        self.record = dict(schema_version='table-clone-trigger/v1', explicit_qualification_approved=True,
                           started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=60)).isoformat(),
                           fixtures=list(map(str, fixtures)), exports=exports, cases=cases,
                           pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None, startup_codepage=None):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        initial = '' if startup_codepage is None else '[Console]::OutputEncoding=[Text.Encoding]::GetEncoding(' + str(startup_codepage) + ');'
        command = initial + UTF8_CONSOLE + "$ErrorActionPreference='Stop';& " + ps_quote(DRIVER) + \
            ' -RunsetPath ' + ps_quote(path) + ' -CaseIndex 5 -ValidateOnly'
        result = subprocess.run(['pwsh', '-NoProfile', '-NonInteractive', '-Command', command],
                                cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')), [])
        return result

    def reject(self, mutate, reason):
        record = copy.deepcopy(self.record)
        mutate(record)
        result = self.admission(record)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(reason, result.stdout + result.stderr)

    def test_public_scope_reaches_explicit_private_artifact_boundary(self):
        # Positive real-artifact admission is checked privately, not fabricated in CI.
        result = self.admission()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('parserArtifact', result.stdout + result.stderr)

    def test_utf8_transport_overrides_both_windows_startup_codepages(self):
        for codepage in (850, 1252):
            result = self.admission(startup_codepage=codepage)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('parserArtifact', result.stdout + result.stderr)

    def test_authority_requires_boolean_true(self):
        for value in (False, 'true'):
            self.reject(lambda r: r.update(explicit_qualification_approved=value), 'CLONE_TRIGGER_RUNSET_SCOPE')

    def test_deadline_expiry_and_extension(self):
        expired = datetime.now(timezone.utc) - timedelta(hours=2)
        self.reject(lambda r: r.update(started_utc=expired.isoformat(), deadline_utc=(expired + timedelta(minutes=60)).isoformat()),
                    'CLONE_TRIGGER_ADMISSION_CLOSED')
        self.reject(lambda r: r.update(deadline_utc=(datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()),
                    'CLONE_TRIGGER_ADMISSION_CLOSED')

    def test_windows_target_cannot_be_substituted(self):
        self.reject(lambda r: r['cases'][0].update(Platform='linux'), 'CLONE_TRIGGER_CONTEXT_SCOPE')
        self.reject(lambda r: r['cases'][5].update(Patch='base'), 'CLONE_TRIGGER_CONTEXT_SCOPE')
        self.reject(lambda r: r['cases'][5].update(CL=160), 'CLONE_TRIGGER_CONTEXT_SCOPE')

    def test_each_target_requires_both_declared_modes(self):
        for index in (0, 2, 5):
            self.reject(lambda r: r['cases'][index].update(modes=['central']), 'CLONE_TRIGGER_CONTEXT_SCOPE')

    def test_canonical_fixture_and_method_pins_required(self):
        fixture = self.directory / 'imposter.sql'
        fixture.write_bytes(Path(self.record['fixtures'][0]).read_bytes())
        self.reject(lambda r: r.update(fixtures=[str(fixture)]), 'CLONE_TRIGGER_CANONICAL_FIXTURES_REQUIRED')
        self.reject(lambda r: r['pins'].pop(0), 'CLONE_TRIGGER_REQUIRED_PIN_MISSING')

    def test_changed_export_bytes_rejected(self):
        Path(self.record['exports']['local']).write_bytes(b'SELECT 2;\n')
        self.reject(lambda r: None, 'RELEASE_INPUT_DRIFT')

    def test_extra_export_module_rejected_even_with_matching_pin(self):
        path = Path(self.record['exports']['local'])
        path.write_bytes(path.read_bytes() + b'-- BEGIN MODULE toolbelt.synthetic.foreign\nSELECT 1;\n')
        def change(record):
            for pin in record['pins']:
                if pin['path'] == str(path):
                    pin['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest().upper()
        self.reject(change, 'CLONE_TRIGGER_EXPORT_CLOSURE_REQUIRED')

    def scope(self, text, from_file=False):
        quoted = "'" + str(text).replace("'", "''") + "'"
        payload = '([IO.File]::ReadAllText(' + quoted + '))' if from_file else quoted
        script = UTF8_CONSOLE + "$ErrorActionPreference='Stop';$errors=$null;" + \
            "$ast=[Management.Automation.Language.Parser]::ParseFile('" + str(DRIVER).replace("'", "''") + "',[ref]$null,[ref]$errors);" + \
            "$functions=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-CloneTriggerFixtureScope'},$true));" + \
            "if($errors.Count-or$functions.Count-ne1){throw 'SCOPE_FUNCTION'};. ([scriptblock]::Create($functions[0].Extent.Text));" + \
            'Assert-CloneTriggerFixtureScope ' + payload + ";'PASS fixture scope without SQL'"
        return subprocess.run(['pwsh', '-NoProfile', '-Command', script], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', timeout=20)

    def test_fixture_rights_and_server_scope_rejected(self):
        for text in ('GRANT EXECUTE ON dbo.Synthetic TO Contoso;', 'CREATE USER Contoso WITHOUT LOGIN;',
                     'ALTER AUTHORIZATION ON SCHEMA::dbo TO Contoso;', 'ALTER DATABASE Synthetic SET TRUSTWORTHY ON;',
                     "EXEC sys.sp_configure N'clr enabled',1;", 'CREATE TRIGGER Synthetic ON ALL SERVER FOR CREATE_DATABASE AS SELECT 1;'):
            result = self.scope(text)
            self.assertNotEqual(result.returncode, 0, text)
            self.assertIn('CLONE_TRIGGER_FIXTURE_EXCEEDS_SCOPE', result.stdout + result.stderr)

    def test_original_trigger_fixtures_pass_scope_without_sql(self):
        for fixture in self.record['fixtures']:
            result = self.scope(fixture, from_file=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_option_zero_reuse_requires_exact_single_pin_change(self):
        # Previous Main's complete normalized source, not an inferred runtime PASS.
        source = (ROOT / 'Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableCloneInternal.sql').read_bytes().replace(b'\r\n', b'\n')
        current = b'F2213559FA9085BDAC9B6A4C1954D7BE18EAAE9BFBF950E2A29CC0121D8B36D6838D4366327D3A6B0C9ED655179ACBE898E2887D917AA0D0C2B7C243C891C16A'
        previous = b'7F34D0472DBE5913C8D019A72B2684D89CB4CA79590B599DD5B06154D6A40C5494334D8F46218E10E9D1BC5DB983A8750BA77A685D68865D9BCDF30C3D853506'
        self.assertEqual(source.count(current), 1)
        self.assertEqual(source.count(previous), 0)
        self.assertLess(source.index(b'IF @IncludeTriggers=1'), source.index(current))
        reconstructed = source.replace(current, previous)
        self.assertEqual(hashlib.sha256(reconstructed).hexdigest().upper(),
                         '94A2F00F8E0DCB07C9E2E1FA5FBEC287CF0D89FC578C53315A96AB033C9C079C')


if __name__ == '__main__':
    unittest.main()

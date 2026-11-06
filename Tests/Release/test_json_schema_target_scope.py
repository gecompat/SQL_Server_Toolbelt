"""Reale verbindungslose Auswahlprüfung vor dem neuen Schema-Zielscope."""
from pathlib import Path
import itertools
import json
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class JsonSchemaTargetScopeTests(unittest.TestCase):
    def test_all_supported_and_rejected_scope_combinations(self):
        levels = {'2019': (150,), '2022': (150, 160), '2025': (150, 160, 170)}
        patches = {'2019': 'CU32', '2022': 'CU26', '2025': 'CU8'}
        rows = []
        for platform, version, patch, level, scope in itertools.product(
                ('windows', 'linux', 'WINDOWS'), ('2019', '2022', '2025', '2017'),
                ('CU32', 'CU26', 'CU8', 'latest', 'base'), (150, 160, 170),
                ('core-schema', 'constructors', 'migration', 'unknown', 'MIGRATION')):
            native = level in levels.get(version, ()) and (
                platform == 'windows' and patch == patches.get(version) or
                platform == 'linux' and patch == 'latest')
            old = native and (platform == 'windows' and version == '2025' or
                              platform == 'linux' and version == '2019')
            expected = native if scope in ('core-schema', 'migration') else (
                old or native and platform == 'windows') if scope == 'constructors' else (
                False)
            rows.append(dict(Platform=platform, Version=version, Patch=patch,
                             CL=level, Scope=scope, Expected=bool(expected)))
        with tempfile.TemporaryDirectory(prefix='schema-scope-', dir=ROOT / '.runtime') as directory:
            directory = Path(directory)
            cases = directory / 'cases.json'
            cases.write_text(json.dumps(rows), encoding='utf-8')
            script = directory / 'Check.ps1'
            script.write_text('''param($Helper,$Cases)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
. $Helper
$rows=Get-Content -LiteralPath $Cases -Raw|ConvertFrom-Json
foreach($r in $rows){
 $actual=Test-JsonSchemaTargetScope $r.Platform $r.Version $r.Patch $r.CL $r.Scope
 if($actual-isnot[bool]-or$actual-ne$r.Expected){throw ('SCOPE_MISMATCH '+($r|ConvertTo-Json -Compress))}
}
'PASS '+$rows.Count+' scope combinations; no Lab/SQL'
''', encoding='utf-8')
            result = subprocess.run(['pwsh', '-NoProfile', '-File', str(script),
                                     str(ROOT / 'Tests/CI/JsonSchemaQualificationScope.ps1'), str(cases)],
                                    cwd=ROOT, capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn(f'PASS {len(rows)} scope combinations', result.stdout)

    def test_disposition_rejects_unbound_scope_before_lab_access(self):
        with tempfile.TemporaryDirectory(prefix='schema-audit-pin-', dir=ROOT / '.runtime') as directory:
            directory = Path(directory)
            journal = directory / 'Journal.private.json'
            journal.write_text(json.dumps(dict(State='COMPLETE', PostPins=True, DispositionVerified=True,
                                                ConfigurationChanges=0, RightsChanges=0, Databases=[], Trust=[],
                                                FrozenInputs=[])), encoding='utf-8')
            import hashlib
            digest = hashlib.sha256(journal.read_bytes()).hexdigest()
            result = subprocess.run(['pwsh', '-NoProfile', '-File', str(ROOT / 'Tests/CI/Test-JsonSchemaLabDisposition.ps1'),
                                     '-JournalDirectory', str(directory), '-ExpectedJournalSHA256', digest,
                                     '-OutputDirectory', str(directory / 'audit')], cwd=ROOT,
                                    capture_output=True, text=True, timeout=20)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('JSON_DISPOSITION_SCOPE_PIN', result.stderr)
            self.assertFalse((directory / 'audit').exists())


if __name__ == '__main__':
    unittest.main()

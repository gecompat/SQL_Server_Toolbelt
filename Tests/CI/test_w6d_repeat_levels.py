"""Echte Shell-Auswahl mit SQL-/Datei-Stubs; kein Docker, Lab oder SQL."""
from pathlib import Path
import os
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'Tests/CI/run-w6d-execution-cancel-linux.sh'
BASH = (Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Git/bin/bash.exe'
        if os.name == 'nt' else 'bash')


def function(source, name):
    start = source.index(name + '(){\n')
    end = source.index('\n}\n', start) + 3
    return source[start:end]


class RepeatLevelsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding='utf-8-sig')
        cls.selector = next(line for line in cls.source.splitlines()
                            if line.startswith('case "${sql_version}" in'))
        cls.functions = '\n'.join(function(cls.source, name) for name in
                                  ('set_compatibility_level', 'run_repeat_matrix'))

    def execute(self, version, mode='local', query_exit=0, fixture_exit=0,
                levels_override=None):
        script = 'set -euo pipefail\nsql_version=' + version + '\n' + self.selector + '\n'
        if levels_override is not None:
            script += 'levels="' + levels_override + '"\n'
        # Die echte Auswahl/Guardfunktion läuft, nur die externen Effekte sind ersetzt.
        script += '''run_query(){ printf 'SQL|%s|%s\\n' "$1" "$2"; return QUERY_EXIT; }
run_file(){ printf 'FILE|%s|%s|%s\\n' "$1" "$3" "$5"; return FIXTURE_EXIT; }
'''.replace('QUERY_EXIT', str(query_exit)).replace('FIXTURE_EXIT', str(fixture_exit))
        script += self.functions + '\nrun_repeat_matrix ContosoCancellation ' + mode + '\n'
        return subprocess.run([str(BASH), '-c', script], cwd=ROOT,
                              capture_output=True, text=True, timeout=15)

    def test_all_supported_pairs_both_modes_in_real_selector(self):
        for version, levels in (('2019', (150,)), ('2022', (150, 160)),
                                ('2025', (150, 160, 170))):
            for mode in ('local', 'central'):
                with self.subTest(version=version, mode=mode):
                    result = self.execute(version, mode)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    lines = result.stdout.splitlines()
                    self.assertEqual(len(lines), len(levels) * 3)
                    for index, level in enumerate(levels):
                        query, fixture, witness = lines[index * 3:index * 3 + 3]
                        self.assertIn(f'SET COMPATIBILITY_LEVEL={level};', query)
                        self.assertIn('database_id=DB_ID()', query)
                        self.assertIn(f'compatibility_level={level}', query)
                        self.assertIn('THROW 52748', query)
                        self.assertEqual(fixture, 'FILE|ContosoCancellation|'
                                         '../Tests/Runtime/RepeatCurrent.Contract.sql|'
                                         f'DeploymentMode={mode}')
                        self.assertEqual(witness, 'W6D_REPEAT_LEVEL_VERIFIED '
                                         f'version={version} level={level} mode={mode}')

    def test_invalid_engine_level_rejected_before_any_query(self):
        for version, level in (('2019', '160'), ('2022', '170'),
                               ('2025', '140'), ('2025', '150;bad')):
            result = self.execute(version, levels_override=level)
            self.assertEqual(result.returncode, 64)
            self.assertEqual(result.stdout, '')
            self.assertIn('W6D_REPEAT_SCOPE_INVALID', result.stderr)
        self.assertNotEqual(self.execute('2017').returncode, 0)

    def test_level_change_or_actual_level_guard_failure_stops_fixture(self):
        result = self.execute('2025', query_exit=7)
        self.assertEqual(result.returncode, 7)
        self.assertEqual(result.stdout.count('SQL|'), 1)
        self.assertNotIn('FILE|', result.stdout)
        self.assertNotIn('VERIFIED', result.stdout)

    def test_repeat_failure_stops_next_level_and_success_marker(self):
        result = self.execute('2025', fixture_exit=8)
        self.assertEqual(result.returncode, 8)
        self.assertEqual(result.stdout.count('SQL|'), 1)
        self.assertEqual(result.stdout.count('FILE|'), 1)
        self.assertNotIn('VERIFIED', result.stdout)

    def test_both_real_entrypoints_use_only_the_shared_matrix(self):
        calls = re.findall(r'^run_repeat_matrix "\$\{(local_db|central_db)\}" (local|central)$',
                           self.source, re.MULTILINE)
        self.assertEqual(calls, [('local_db', 'local'), ('central_db', 'central')])
        self.assertEqual(self.source.count('../Tests/Runtime/RepeatCurrent.Contract.sql'), 1)
        self.assertIn('set_compatibility_level "${local_db}" "${level}"', self.source)
        for guard in ('trap cleanup EXIT', "trap 'exit 130' INT", "trap 'exit 143' TERM",
                      'W6D_CI_CLEANUP_VERIFIED', 'W6D_CI_CLEANUP_UNVERIFIED'):
            self.assertIn(guard, self.source)

    def test_complete_bash_syntax(self):
        result = subprocess.run([str(BASH), '-n', str(SOURCE)], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()

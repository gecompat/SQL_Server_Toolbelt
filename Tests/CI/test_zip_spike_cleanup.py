"""Execute the actual workflow cleanup with fake Docker and real Bash signals."""
from pathlib import Path
import os
import shlex
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
BASH = str(Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Git/bin/bash.exe') if os.name == 'nt' else 'bash'


class CleanupTests(unittest.TestCase):
    def test_owned_absent_failure_and_signal_paths(self):
        source = (ROOT / '.github/workflows/sql-clr-zip-spike.yml').read_text(encoding='utf-8-sig')
        lines = [line[10:] for line in source.splitlines()]
        start = lines.index('cleanup() {')
        end = lines.index("trap 'exit 143' TERM", start)
        actual = '\n'.join(lines[start:end + 1])
        for case, expected, removed in (
            ('owned', 0, True), ('absent', 0, False), ('foreign', 1, False),
            ('daemon', 1, False), ('remove_fail', 1, True), ('residue', 1, True),
            ('primary_failure', 7, True), ('term', 143, True), ('int', 130, True),
            ('escalates', 130, True),
        ):
            with self.subTest(case=case), tempfile.TemporaryDirectory(prefix='zip-cleanup-') as folder:
                marker = Path(folder) / 'removed'
                script = f'''set -euo pipefail
container_name=synthetic-zip
container_owner={'a' * 32}
marker={shlex.quote(marker.as_posix())}
case_name={case}
present=true
[[ "$case_name" != absent ]] || present=false
docker() {{
  if [[ "$1 $2" == "container ls" ]]; then
    [[ "$case_name" != escalates ]] || kill -TERM $$
    [[ "$case_name" != daemon ]] || return 125
    if [[ "$present" == true ]]; then printf '%s\\n' "$container_name"; fi
  elif [[ "$1" == inspect ]]; then
    printf '%s %s\\n' '{'b' * 64}' "$([[ "$case_name" == foreign ]] && printf '{'c' * 32}' || printf '%s' "$container_owner")"
  elif [[ "$1" == rm ]]; then
    [[ "$#" == 4 && "$2" == --force && "$3" == --volumes && "$4" == '{'b' * 64}' ]] || return 97
    : > "$marker"
    [[ "$case_name" != remove_fail ]] || return 125
    [[ "$case_name" == residue ]] || present=false
  else return 97
  fi
}}
{actual}
[[ "$case_name" != primary_failure ]] || exit 7
[[ "$case_name" != term ]] || kill -TERM $$
[[ "$case_name" != int ]] || kill -INT $$
[[ "$case_name" != escalates ]] || kill -INT $$
exit 0
'''
                path = Path(folder) / 'check.sh'
                path.write_text(script, encoding='utf-8', newline='\n')
                result = subprocess.run([BASH, path.as_posix()], capture_output=True, timeout=10)
                self.assertEqual(expected, result.returncode, result.stderr.decode(errors='replace'))
                self.assertEqual(removed, marker.exists())


if __name__ == '__main__':
    unittest.main()

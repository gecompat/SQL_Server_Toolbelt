from pathlib import Path
import hashlib
import os
import shlex
import subprocess
import tempfile
import time

# Die tatsächlichen getrennten Workflowsteps laufen nur mit synthetischen
# Docker-/OpenSSL-Antworten. Keine Ports, Container, SQL-Verbindungen oder Labziele.
root = Path.cwd().resolve()
workflow = root / '.github/workflows/external-queue-worker.yml'
inputs = (workflow, Path(__file__).resolve())
pins = {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
source = workflow.read_text(encoding='utf-8-sig')


def block(name):
    marker = '      - name: ' + name + '\n'
    assert source.count(marker) == 1, 'WORKER_CI_STEP_BOUNDARY'
    lines = source.split(marker, 1)[1].splitlines()
    start = lines.index('        run: |') + 1
    code = []
    for line in lines[start:]:
        if line and not line.startswith('          '):
            break
        code.append(line[10:] if line else '')
    assert code, 'WORKER_CI_STEP_EMPTY'
    return '\n'.join(code) + '\n'


startup = block('Start disposable synthetic SQL target')
cleanup = block('Cleanup owned synthetic target')
assert '        if: always()' in source.split('      - name: Cleanup owned synthetic target\n', 1)[1]
assert 'run: python Workers/ExternalQueue/Tests/CiTarget.Contract.py' in source
assert startup.index('TBX_WORKER_CI_NAME=') < startup.index('docker run')
assert '--label "tbx.external-worker.ci.owner=${container_owner}"' in startup
bash = 'bash'
if os.name == 'nt':
    bash = str(Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Git/bin/bash.exe')
    assert Path(bash).is_file(), 'WORKER_CI_GIT_BASH_REQUIRED'
runtime = root / '.runtime'
runtime.mkdir(exist_ok=True)
deadline = time.monotonic() + 45
count = 0


def execute(code, scenario, expected, setup):
    global count
    remaining = deadline - time.monotonic()
    assert remaining > 0, 'WORKER_CI_TEST_BUDGET'
    with tempfile.TemporaryDirectory(prefix='worker-ci-target-', dir=runtime) as directory:
        path = Path(directory).resolve()
        assert path.is_relative_to(runtime.resolve())
        prefix = 'state=' + shlex.quote(path.relative_to(root).as_posix()) + '\n'
        prefix += 'scenario=' + shlex.quote(scenario) + '\n'
        script = path / 'case.sh'
        script.write_text(prefix + setup + code, encoding='utf-8', newline='\n')
        result = subprocess.run([bash, script.relative_to(root).as_posix()], cwd=root,
                                capture_output=True, text=True, encoding='utf-8', errors='strict',
                                timeout=min(5, remaining), check=False)
        assert not (path / 'invalid').exists(), 'WORKER_CI_ARGV:' + scenario
        assert result.returncode == expected, 'WORKER_CI_EXIT:' + scenario
        # Caller-Orakel werden vor dem tatsächlichen temporären Cleanup ausgeführt.
        check(scenario, (path, result))
    count += 1
    print('PASS: worker_ci_target ' + scenario)


cleanup_setup = r'''
export TBX_WORKER_CI_NAME=tbx-external-worker-123-2
export TBX_WORKER_CI_OWNER=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
if [[ "$scenario" == invalid_name ]]; then TBX_WORKER_CI_NAME=foreign; fi
if [[ "$scenario" == invalid_owner ]]; then TBX_WORKER_CI_OWNER=BAD; fi
docker() {
  printf '%s\n' "$1" >> "$state/calls"
  if [[ "$1" == container ]]; then
    [[ "$#" == 7 && "$2" == ls && "$3" == --all && "$4" == --filter && "$5" == name=^/tbx-external-worker-123-2$ && "$6" == --format && "$7" == '{{.Names}}' ]] || { touch "$state/invalid"; return 2; }
    if [[ -f "$state/list" ]]; then
      [[ "$scenario" != post_list_fail ]] || { printf 'SYNTHETIC_DOCKER_RAW_DIAGNOSTIC\n' >&2; return 17; }
      if [[ "$scenario" == remains || "$scenario" == replaced ]]; then printf '%s\n' "$TBX_WORKER_CI_NAME"; fi
    else
      touch "$state/list"
      [[ "$scenario" != daemon ]] || { printf 'SYNTHETIC_DOCKER_RAW_DIAGNOSTIC\n' >&2; return 17; }
      [[ "$scenario" != absent ]] || return 0
      printf '%s\n' "$TBX_WORKER_CI_NAME"
      [[ "$scenario" != extra_names ]] || printf '%s\n' foreign
    fi
  elif [[ "$1" == inspect ]]; then
    [[ "$#" == 4 && "$2" == --format && "$3" == '{{.Id}} {{ index .Config.Labels "tbx.external-worker.ci.owner" }}' && "$4" == "$TBX_WORKER_CI_NAME" ]] || { touch "$state/invalid"; return 2; }
    [[ "$scenario" != inspect_fail ]] || { printf 'SYNTHETIC_DOCKER_RAW_DIAGNOSTIC\n' >&2; return 17; }
    id=$(printf 'b%.0s' {1..64})
    owner=$TBX_WORKER_CI_OWNER
    [[ "$scenario" != foreign ]] || owner=cccccccccccccccccccccccccccccccc
    [[ "$scenario" != invalid_id ]] || id=bad
    printf '%s %s' "$id" "$owner"
    [[ "$scenario" != extra_fields ]] || printf ' extra'
    printf '\n'
  elif [[ "$1" == rm ]]; then
    [[ "$#" == 3 && "$2" == -f && "$3" == $(printf 'b%.0s' {1..64}) ]] || { touch "$state/invalid"; return 2; }
    touch "$state/removed"
    [[ "$scenario" != remove_fail ]] || return 17
  else
    touch "$state/invalid"; return 2
  fi
}
'''


def check(scenario, observed):
    path, result = observed
    if scenario.startswith('start_'):
        expected_error = ('WORKER_CI_IDENTITY_INVALID\n' if scenario in {'start_invalid_run', 'start_invalid_attempt'}
                          else 'WORKER_CI_OWNER_INVALID\n' if scenario == 'start_owner_invalid' else '')
        assert result.stderr == expected_error, 'WORKER_CI_START_STDERR:' + scenario
        env = (path / 'env').read_text(encoding='utf-8') if (path / 'env').exists() else ''
        mutation = scenario in {'start_success', 'start_failure'}
        assert (path / 'docker').exists() == mutation
        if mutation:
            assert env.startswith('TBX_WORKER_CI_NAME=tbx-external-worker-123-2\nTBX_WORKER_CI_OWNER=' + 'a' * 32 + '\n')
        else:
            assert not env
        return
    removed = scenario in {'owned', 'remove_fail', 'post_list_fail', 'remains', 'replaced'}
    assert (path / 'removed').exists() == removed, 'WORKER_CI_REMOVAL:' + scenario
    passing = scenario in {'owned', 'absent'}
    assert result.stdout == ('WORKER_CI_CLEANUP_VERIFIED\n' if passing else '')
    assert result.stderr == ('' if passing else 'WORKER_CI_CLEANUP_UNVERIFIED\n')
    if scenario in {'invalid_name', 'invalid_owner'}:
        assert not (path / 'calls').exists()


for scenario in ('owned', 'absent', 'foreign', 'daemon', 'inspect_fail', 'remove_fail',
                 'post_list_fail', 'remains', 'replaced', 'invalid_id', 'extra_fields',
                 'extra_names', 'invalid_name', 'invalid_owner'):
    execute(cleanup, scenario, 0 if scenario in {'owned', 'absent'} else 1, cleanup_setup)

startup_setup = r'''
GITHUB_RUN_ID=123
GITHUB_RUN_ATTEMPT=2
GITHUB_ENV="$state/env"
if [[ "$scenario" == start_invalid_run ]]; then GITHUB_RUN_ID=bad; fi
if [[ "$scenario" == start_invalid_attempt ]]; then GITHUB_RUN_ATTEMPT=bad; fi
openssl() {
  [[ "$1" == rand && "$2" == -hex && "$#" == 3 ]] || { touch "$state/invalid"; return 2; }
  if [[ "$3" == 16 ]]; then
    [[ "$scenario" != start_owner_failure ]] || return 7
    [[ "$scenario" != start_owner_invalid ]] || { printf BAD; return 0; }
    printf 'a%.0s' {1..32}
  elif [[ "$3" == 18 ]]; then printf 'd%.0s' {1..36}
  else touch "$state/invalid"; return 2; fi
}
docker() {
  # Die bestehenden Credential-/Port-/Imageargumente bleiben exakt erhalten.
  [[ "$#" == 15 && "$1" == run && "$2" == -d && "$3" == --name && "$4" == tbx-external-worker-123-2 && "$5" == --label && "$6" == tbx.external-worker.ci.owner=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa && "$7" == -e && "$8" == ACCEPT_EULA=Y && "$9" == -e && "${10}" == MSSQL_PID=Developer && "${11}" == -e && "${12}" == MSSQL_SA_PASSWORD=Tbx!*Aa1 && "${13}" == -p && "${14}" == 127.0.0.1:1433:1433 && "${15}" == mcr.microsoft.com/mssql/server:2019-latest ]] || { touch "$state/invalid"; return 2; }
  touch "$state/docker"
  [[ "$scenario" != start_failure ]] || return 23
}
'''
for scenario, expected in (('start_success', 0), ('start_failure', 23), ('start_invalid_run', 1),
                           ('start_invalid_attempt', 1), ('start_owner_invalid', 1), ('start_owner_failure', 7)):
    execute(startup, scenario, expected, startup_setup)
for path, pin in pins.items():
    assert hashlib.sha256(path.read_bytes()).hexdigest() == pin, 'WORKER_CI_SOURCE_CHANGED'
    print('PASS: source byte pin ' + path.relative_to(root).as_posix() + ' sha256=' + pin)
print('PASS: worker_ci_target cases=' + str(count) + ' sourcepins=' + str(len(pins)))

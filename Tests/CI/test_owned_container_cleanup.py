from pathlib import Path
import argparse
import hashlib
import os
import shlex
import subprocess
import tempfile

# Nur die echte Cleanup-Funktion wird mit synthetischen Dockerantworten geprüft.
# Kein Container, Port, SQL-Server oder Labziel wird angelegt oder angesprochen.
root = Path.cwd().resolve()
modules = {
    "pointer": ("run-json-pointer-linux.sh", "JSON_POINTER_CI_CLEANUP_UNVERIFIED", "tbx.json-pointer.ci.owner"),
    "safe_cast": ("run-safe-cast-linux.sh", "SAFE_CAST_CI_CLEANUP_UNVERIFIED", "tbx.safe-cast.ci.owner"),
    "json_constructors": ("run-json-constructors-linux.sh", "JSON_CONSTRUCTORS_CI_CLEANUP_UNVERIFIED", "tbx.json-constructors.ci.owner"),
    "table_clone": ("run-table-clone-linux.sh", "TABLE_CLONE_CI_CLEANUP_UNVERIFIED", "tbx.table-clone.ci.owner"),
    "deterministic": ("run-deterministic-linux.sh", "DETERMINISTIC_CI_CLEANUP_UNVERIFIED", "tbx.deterministic.ci.owner"),
    "regex": ("run-regex-linux.sh", "REGEX_CI_CLEANUP_UNVERIFIED", "tbx.regex.ci.owner"),
    "result_table": ("run-result-table-linux.sh", "RESULT_TABLE_CI_CLEANUP_UNVERIFIED", "tbx.result-table.ci.owner"),
    "w4a": ("run-w4a-execution-foundations-linux.sh", "W4A_CI_CLEANUP_UNVERIFIED", "tbx.w4a.ci.owner"),
    "work_queue": ("run-work-queue-linux.sh", "WORK_QUEUE_CI_CLEANUP_UNVERIFIED", "tbx.work-queue.ci.owner"),
}
parser = argparse.ArgumentParser(description="Synthetische Prüfung der echten Owned-Cleanup-Funktionen ohne Dockerzugriff.")
parser.add_argument("--module", choices=tuple(modules), action="append",
                    help="Nur dieses Modul prüfen; wiederholbar, standardmäßig alle neun Adapter.")
selected = tuple(dict.fromkeys(parser.parse_args().module or modules))
# Windows verwendet ausschließlich das vorhandene Git-Bash. Das gleichnamige
# System32-Programm würde WSL starten und gehört nicht zu dieser Offlineprobe.
bash = "bash"
if os.name == "nt":
    bash = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
    if not bash.is_file():
        raise SystemExit("OWNED_CLEANUP_TEST_GIT_BASH_REQUIRED")
# Die ausgeführte Harnessdatei und alle gewählten Adapter bleiben bytegenau
# eingefroren. LF-Normalisierung dient nur der Funktionsgrenzensuche.
paths = (Path(__file__).resolve(),) + tuple(root / "Tests/CI" / modules[module][0] for module in selected)
source_bytes = {path: path.read_bytes() for path in paths}
pins = {path: hashlib.sha256(value).hexdigest() for path, value in source_bytes.items()}
runtime = (root / ".runtime").resolve()
if not runtime.is_relative_to(root):
    raise SystemExit("OWNED_CLEANUP_TEST_RUNTIME_SCOPE_INVALID")
runtime.mkdir(exist_ok=True)

cases = (
    ("owned", 0, True),
    ("foreign", 1, False),
    ("daemon", 1, False),
    ("remove_fail", 1, True),
    ("absent", 0, False),
    ("original_failure", 7, True),
    ("inspect_fail", 1, False),
    ("post_list_fail", 1, True),
    ("remains", 1, True),
)

total = 0
for module in selected:
    filename, diagnostic, owner_label = modules[module]
    script = root / "Tests/CI" / filename
    source = source_bytes[script].decode("utf-8-sig").replace("\r\n", "\n")
    try:
        begin = source.index("cleanup() {\n")
        end = source.index("\n}\n", begin) + 2
        if not source[end:].lstrip().startswith("trap cleanup EXIT"):
            raise ValueError("Cleanup trap fehlt")
    except ValueError as exc:
        raise SystemExit(f"OWNED_CLEANUP_TEST_SOURCE_BOUNDARY_INVALID:{module}") from exc
    cleanup_function = source[begin:end]

    identity_cases = (
        ("name_replaced", 1, True),
        ("invalid_id", 1, False),
        ("invalid_owner", 1, False),
        ("extra_fields", 1, False),
    )
    module_cases = cases + identity_cases if module in {"pointer", "safe_cast", "json_constructors", "table_clone", "deterministic", "regex", "result_table", "w4a", "work_queue"} else cases
    if module in {"table_clone", "regex", "result_table", "w4a", "work_queue"}:
        module_cases += (
            ("lab_success", 0, True),
            ("lab_original_failure", 7, True),
        )
    if module == "work_queue":
        module_cases += (("lab_sql_success", 0, True), ("lab_sql_original_failure", 7, True),
                         ("lab_sql_drop_failure", 7, True), ("lab_private_remove_fail", 1, True))
    inspection_format = '{{ index .Config.Labels "' + owner_label + '" }}'
    if module in {"pointer", "safe_cast", "json_constructors", "table_clone", "deterministic", "regex", "result_table", "w4a", "work_queue"}:
        inspection_format = '{{.Id}} ' + inspection_format
    for scenario, expected_code, expected_remove in module_cases:
        with tempfile.TemporaryDirectory(prefix="owned-cleanup-", dir=runtime) as base:
            base_path = Path(base).resolve()
            if not base_path.is_relative_to(runtime):
                raise SystemExit("OWNED_CLEANUP_TEST_TEMP_SCOPE_INVALID")
            private_path = base_path / "private"
            lab_case = scenario.startswith("lab_")
            if not lab_case or module == "work_queue":
                private_path.mkdir()
                if module == "work_queue":
                    for output in ("dependency", "collision", "uninstall", "upgrade-blocked"):
                        (private_path / ("work-queue-" + output + ".out")).write_text("synthetic", encoding="utf-8")
            marker_path = base_path / "remove-called"
            invalid_path = base_path / "invalid-argv"
            inspect_path = base_path / "inspect-called"
            replacement_path = base_path / "replacement-name"
            expected_identity = "b" * 64 if module in {"pointer", "safe_cast", "json_constructors", "table_clone", "deterministic", "regex", "result_table", "w4a", "work_queue"} and not lab_case else "tbx-synthetic-owned-cleanup"
            shell = f"""
set -euo pipefail
TBX_SQL_TARGET=runner
container_name=tbx-synthetic-owned-cleanup
container_owner={'a' * 32}
synthetic_container_id={'b' * 64}
private_dir={shlex.quote(private_path.relative_to(root).as_posix())}
marker_file={shlex.quote(marker_path.relative_to(root).as_posix())}
invalid_file={shlex.quote(invalid_path.relative_to(root).as_posix())}
inspect_file={shlex.quote(inspect_path.relative_to(root).as_posix())}
replacement_file={shlex.quote(replacement_path.relative_to(root).as_posix())}
module={module}
sqlcmd_path=/synthetic/sqlcmd
sa_password=synthetic
local_db=tbx_work_queue_local
central_db=tbx_work_queue_central
consumer_db=tbx_work_queue_consumer
dependency_db=tbx_work_queue_dependency
collision_db=tbx_work_queue_collision
upgrade_db=tbx_work_queue_upgrade
upgrade_blocked_db=tbx_work_queue_upgrade_blocked
lab_sql_file={shlex.quote((base_path / "lab-sql-called").relative_to(root).as_posix())}
expected_identity={expected_identity}
expected_inspection_format={shlex.quote(inspection_format)}
scenario={scenario}
present=true
list_calls=0
collision_log=""
r2a_trust_before=0
r2a_hash=0x{'d' * 128}
# Im Runner darf Cleanup keine SQL-Abfrage über einen ungeprüften Namen senden.
run_query() {{ invalid_argv; return 2; }}
if [[ "$scenario" == absent ]]; then present=false; fi
# Der Lab-Frühzweig benötigt keine Runneridentität. Nur WorkQueue besitzt
# hier eine eigene Ausgabeablage; die übrigen Labadapter bleiben No-op.
if [[ "$scenario" == lab_* ]]; then
    TBX_SQL_TARGET=lab
    unset container_owner
    if [[ "$module" != work_queue ]]; then unset private_dir; fi
    if [[ "$scenario" != lab_sql_* ]]; then sqlcmd_path=""; fi
    r2a_trust_before=""
    r2a_hash=""
fi
invalid_argv() {{ : > "$invalid_file"; return 2; }}
rm() {{
    if [[ "$scenario" == lab_private_remove_fail ]]; then
        [[ "$#" == 3 && "$1" == -rf && "$2" == -- && "$3" == "$private_dir" ]] || invalid_argv
        return 1
    fi
    command rm "$@"
}}
docker() {{
    if [[ "$TBX_SQL_TARGET" == lab ]]; then
        if [[ "$module" == work_queue && "$1" == exec ]]; then
            if [[ "$#" != 15 || "$2" != "$container_name" || "$3" != /synthetic/sqlcmd || "$4" != -S || "$5" != localhost || "$6" != -U || "$7" != sa || "$8" != -P || "$9" != synthetic || "${{10}}" != -C || "${{11}}" != -b || "${{12}}" != -d || "${{13}}" != master || "${{14}}" != -Q ]]; then invalid_argv; return 2; fi
            printf '%s\\n' "${{15}}" >> "$lab_sql_file"
            [[ "$scenario" != lab_sql_drop_failure ]] || return 1
            return 0
        fi
        if [[ "$#" != 3 || "$1" != rm || "$2" != -f || "$3" != "$container_name" ]]; then invalid_argv; return 2; fi
        shift
        printf '%s\\n' "$*" >> "$marker_file"
        return 0
    fi
    if [[ "$1" == container && "$2" == ls ]]; then
        if [[ "$#" != 7 || "$3" != --all || "$4" != --filter || "$5" != "name=^/${{container_name}}$" || "$6" != --format || "$7" != '{{{{.Names}}}}' ]]; then invalid_argv; return 2; fi
        list_calls=$((list_calls+1))
        [[ "$scenario" != daemon ]] || return 1
        [[ "$scenario" != post_list_fail || "$list_calls" != 2 ]] || return 1
        if [[ "$present" == true || -f "$replacement_file" ]]; then printf '%s\\n' "$container_name"; fi
    elif [[ "$1" == inspect ]]; then
        printf '%s\\n' inspect >> "$inspect_file"
        if [[ "$#" != 4 || "$2" != --format || "$3" != "$expected_inspection_format" || "$4" != "$container_name" ]]; then invalid_argv; return 2; fi
        [[ "$scenario" != inspect_fail ]] || return 1
        if [[ "$module" == pointer || "$module" == safe_cast || "$module" == json_constructors || "$module" == table_clone || "$module" == deterministic || "$module" == regex || "$module" == result_table || "$module" == w4a || "$module" == work_queue ]]; then
            if [[ "$scenario" == invalid_id ]]; then printf '%s ' not-a-64-hex-id;
            else printf '%s ' "$synthetic_container_id"; fi
        fi
        if [[ "$scenario" == foreign ]]; then
            printf '%s' {'c' * 32}
        elif [[ "$scenario" == invalid_owner ]]; then
            printf '%s' ''
        else
            printf '%s' "$container_owner"
        fi
        if [[ "$scenario" == extra_fields ]]; then printf ' extra-token'; fi
        printf '\\n'
        # inspect läuft in Command-Substitution. Der Marker trägt deshalb den
        # synthetischen Namensaustausch über diese Subshellgrenze hinweg.
        if [[ "$scenario" == name_replaced ]]; then : > "$replacement_file"; fi
    elif [[ "$1" == rm ]]; then
        shift
        printf '%s\\n' "$*" >> "$marker_file"
        if [[ "$#" != 2 || "$1" != -f || "$2" != "$expected_identity" ]]; then invalid_argv; return 2; fi
        [[ "$scenario" != remove_fail ]] || return 1
        if [[ "$scenario" != remains ]]; then present=false; fi
    else
        invalid_argv; return 2
    fi
}}
{cleanup_function}
trap cleanup EXIT
if [[ "$scenario" == original_failure || "$scenario" == lab_original_failure || "$scenario" == lab_sql_original_failure || "$scenario" == lab_sql_drop_failure ]]; then exit 7; fi
exit 0
"""
            harness_path = base_path / "harness.sh"
            harness_path.write_text(shell, encoding="utf-8", newline="\n")
            completed = subprocess.run(
                [str(bash), harness_path.relative_to(root).as_posix()], cwd=root, text=True,
                encoding="utf-8", errors="strict", capture_output=True, env=os.environ.copy(),
                check=False, timeout=10,
            )
            lab_sql_path = base_path / "lab-sql-called"
            actual_sql = lab_sql_path.read_text(encoding="utf-8").splitlines() if lab_sql_path.exists() else []
            dbs = ("consumer", "central", "local", "dependency", "collision", "upgrade", "upgrade_blocked")
            expected_sql = ["IF DB_ID(N'tbx_work_queue_" + db + "') IS NOT NULL BEGIN ALTER DATABASE [tbx_work_queue_" + db + "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [tbx_work_queue_" + db + "]; END;" for db in dbs] if scenario.startswith("lab_sql_") else []
            if actual_sql != expected_sql:
                raise SystemExit(f"OWNED_CLEANUP_TEST_LAB_SQL_MISMATCH:{module}:{scenario}")
            if invalid_path.exists():
                raise SystemExit(f"OWNED_CLEANUP_TEST_ARGV_MISMATCH:{module}:{scenario}")
            if completed.returncode != expected_code:
                raise SystemExit(f"OWNED_CLEANUP_TEST_EXIT_MISMATCH:{module}:{scenario}")
            if marker_path.exists() != expected_remove:
                raise SystemExit(f"OWNED_CLEANUP_TEST_REMOVAL_MISMATCH:{module}:{scenario}")
            if expected_remove and marker_path.read_text(encoding="utf-8").splitlines() != ["-f " + expected_identity]:
                raise SystemExit(f"OWNED_CLEANUP_TEST_REMOVAL_TARGET_MISMATCH:{module}:{scenario}")
            expected_inspections = 0 if scenario in {"daemon", "absent"} or lab_case else 1
            inspections = inspect_path.read_text(encoding="utf-8").splitlines() if inspect_path.exists() else []
            if len(inspections) != expected_inspections:
                raise SystemExit(f"OWNED_CLEANUP_TEST_INSPECTION_MISMATCH:{module}:{scenario}")
            if replacement_path.exists() != (scenario == "name_replaced"):
                raise SystemExit(f"OWNED_CLEANUP_TEST_REPLACEMENT_MISMATCH:{module}:{scenario}")
            if private_path.exists() != (scenario == "lab_private_remove_fail"):
                raise SystemExit(f"OWNED_CLEANUP_TEST_PRIVATE_REMAINS:{module}:{scenario}")
            expected_diagnostic = scenario not in {"owned", "absent", "original_failure"} and not lab_case
            if scenario == "lab_private_remove_fail":
                expected_diagnostic = True
                diagnostic = "WORK_QUEUE_LAB_CLEANUP_UNVERIFIED"
            if completed.stderr != (diagnostic + "\n" if expected_diagnostic else ""):
                raise SystemExit(f"OWNED_CLEANUP_TEST_DIAGNOSTIC_MISMATCH:{module}:{scenario}")
            expected_stdout = diagnostic.replace("UNVERIFIED", "VERIFIED") + "\n" if module in {"pointer", "safe_cast", "json_constructors", "table_clone", "deterministic", "regex", "result_table", "w4a", "work_queue"} and not expected_diagnostic and not lab_case else ""
            if completed.stdout != expected_stdout:
                raise SystemExit(f"OWNED_CLEANUP_TEST_SUCCESS_WITNESS_MISMATCH:{module}:{scenario}")
        print(f"PASS: {module} {scenario}")
        total += 1

for path, expected_hash in pins.items():
    if hashlib.sha256(path.read_bytes()).hexdigest() != expected_hash:
        raise SystemExit("OWNED_CLEANUP_TEST_SOURCE_CHANGED")
    print(f"PASS: source byte pin {path.relative_to(root).as_posix()} sha256={expected_hash}")
print(f"PASS: owned_cleanup modules={','.join(selected)} cases={total} sourcepins={len(pins)}")

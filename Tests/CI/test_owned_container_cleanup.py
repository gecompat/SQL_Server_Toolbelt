from pathlib import Path
import os
import subprocess
import tempfile

# Nur die echte Cleanup-Funktion wird mit synthetischen Dockerantworten geprüft.
# Kein Container, Port, SQL-Server oder Labziel wird angelegt oder angesprochen.
root = Path.cwd().resolve()
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
)

for module, script in (
    ("pointer", root / "Tests/CI/run-json-pointer-linux.sh"),
    ("safe_cast", root / "Tests/CI/run-safe-cast-linux.sh"),
    ("json_constructors", root / "Tests/CI/run-json-constructors-linux.sh"),
):
    source = script.read_text(encoding="utf-8")
    try:
        begin = source.index("cleanup() {\n")
        end = source.index("\n}\n", begin) + 2
        if not source[end:].lstrip().startswith("trap cleanup EXIT"):
            raise ValueError("Cleanup trap fehlt")
    except ValueError as exc:
        raise SystemExit(f"OWNED_CLEANUP_TEST_SOURCE_BOUNDARY_INVALID:{module}") from exc
    cleanup_function = source[begin:end]

    for scenario, expected_code, expected_remove in cases:
        with tempfile.TemporaryDirectory(prefix="owned-cleanup-", dir=runtime) as base:
            base_path = Path(base).resolve()
            if not base_path.is_relative_to(runtime):
                raise SystemExit("OWNED_CLEANUP_TEST_TEMP_SCOPE_INVALID")
            private_path = base_path / "private"
            private_path.mkdir()
            marker_path = base_path / "remove-called"
            shell = f"""
set -euo pipefail
container_name=tbx-synthetic-owned-cleanup
container_owner=expected-owner
private_dir={private_path.relative_to(root).as_posix()}
marker_file={marker_path.relative_to(root).as_posix()}
scenario={scenario}
present=true
if [[ "$scenario" == absent ]]; then present=false; fi
docker() {{
    if [[ "$1" == container && "$2" == ls ]]; then
        [[ "$scenario" != daemon ]] || return 1
        [[ "$present" != true ]] || printf '%s\\n' "$container_name"
    elif [[ "$1" == inspect ]]; then
        if [[ "$scenario" == foreign ]]; then
            printf '%s\\n' foreign-owner
        else
            printf '%s\\n' "$container_owner"
        fi
    elif [[ "$1" == rm ]]; then
        : > "$marker_file"
        [[ "$scenario" != remove_fail ]] || return 1
        present=false
    else
        return 2
    fi
}}
{cleanup_function}
trap cleanup EXIT
if [[ "$scenario" == original_failure ]]; then exit 7; fi
exit 0
"""
            harness_path = base_path / "harness.sh"
            harness_path.write_text(shell, encoding="utf-8", newline="\n")
            completed = subprocess.run(
                ["bash", harness_path.relative_to(root).as_posix()], cwd=root, text=True,
                capture_output=True, env=os.environ.copy(), check=False,
            )
            if completed.returncode != expected_code:
                raise SystemExit(f"OWNED_CLEANUP_TEST_EXIT_MISMATCH:{module}:{scenario}")
            if marker_path.exists() != expected_remove:
                raise SystemExit(f"OWNED_CLEANUP_TEST_REMOVAL_MISMATCH:{module}:{scenario}")
            if private_path.exists():
                raise SystemExit(f"OWNED_CLEANUP_TEST_PRIVATE_REMAINS:{module}:{scenario}")
            expected_diagnostic = scenario in {"foreign", "daemon", "remove_fail"}
            diagnostic = {
                "pointer": "JSON_POINTER_CI_CLEANUP_UNVERIFIED",
                "safe_cast": "SAFE_CAST_CI_CLEANUP_UNVERIFIED",
                "json_constructors": "JSON_CONSTRUCTORS_CI_CLEANUP_UNVERIFIED",
            }[module]
            if (diagnostic in completed.stderr) != expected_diagnostic:
                raise SystemExit(f"OWNED_CLEANUP_TEST_DIAGNOSTIC_MISMATCH:{module}:{scenario}")
        print(f"PASS: {module} {scenario}")

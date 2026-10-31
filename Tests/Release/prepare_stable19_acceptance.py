"""Bindet aktuelle Stable-19-Exporte und vorhandene Help-Orakel; kein SQL-Zugriff."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT / "Tests/Documentation"), str(ROOT / "Scripts/Release")]
import new_parameter_help_cases
import generate_api_catalog


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def prepare(directory):
    directory = Path(directory).resolve(strict=True)
    if not directory.is_relative_to(ROOT / ".runtime") or directory.is_symlink():
        raise ValueError("Private directory required")
    selection = json.loads((directory / "private-selection.json").read_text(encoding="utf-8-sig"))
    plan = json.loads((ROOT / "Releases/1.0.0/release-plan.json").read_text())
    modules = [m for m in plan["modules"] if m["proposed_channel"] == "stable"]
    ids = {m["module_id"] for m in modules}
    if len(modules) != len(ids) or len(ids) != 19:
        raise ValueError("Exact stable cohort required")
    paths = {"Releases/1.0.0/release-plan.json", "Deployment/Deploy-All.ps1",
             "Tests/Release/prepare_stable19_acceptance.py",
             "Tests/Release/Invoke-Stable19AcceptanceLab.ps1",
             "Tests/Release/Invoke-StablePackageLab.ps1",
             "Tests/Release/Invoke-ApiQualificationLab.ps1",
             "Tests/Release/Runtime/Invoke-ParameterHelpCases.ps1",
             "Tests/CI/run-lab-local.ps1", "Tests/CI/LabQualifiedContract.ps1",
             "Tests/Documentation/new_parameter_help_cases.py", "Tests/Documentation/generate_api_catalog.py",
             "Scripts/Documentation/generate_parameter_help.py", "Scripts/Release/parameter_help_transition.py",
             "Scripts/Release/new_parameter_help_package.py", "Documentation/Reference/api_examples.json",
             "Documentation/Reference/usp_help.json"}
    uninstall = {}

    def closure(path):
        path = path.resolve(strict=True)
        if not path.is_relative_to(ROOT) or path.is_symlink():
            raise ValueError("Source outside repository")
        relative = path.relative_to(ROOT).as_posix()
        if relative in uninstall:
            return
        uninstall[relative] = str(path)
        paths.add(relative)
        for include in re.findall(r"(?im)^\s*:r\s+([^\r\n]+)", path.read_text(encoding="utf-8-sig")):
            closure(path.parent / include.strip().strip("\"'"))

    versions = {}
    for module in modules:
        ident = module["module_id"]
        manifest = ROOT / "Modules" / ident / "module.yaml"
        text = manifest.read_text(encoding="utf-8-sig")
        scalar = lambda key: re.search(r"(?m)^" + key + r":\s*(.+)$", text)[1].strip('"\'')
        if scalar("validation_status") != "validated" or scalar("release_status") != "unreleased":
            raise ValueError("Cohort status changed")
        versions[ident] = scalar("version")
        paths.update(subprocess.check_output(
            ["git", "ls-files", "--", "Modules/" + ident], cwd=ROOT, text=True).splitlines())
        closure(manifest.parent / "Deployment/Uninstall.sql")
    exports = {}
    for mode in ("local", "central"):
        output = directory / ("Install-Stable19-" + mode + ".sql")
        args = ["pwsh", "-NoProfile", "-NonInteractive", "-Command",
                "& './Deployment/Deploy-All.ps1' -DeploymentMode " + mode
                + " -ModuleId @(" + ",".join("'" + i + "'" for i in sorted(ids))
                + ") -OutputSqlFile '" + str(output).replace("'", "''") + "'"]
        result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True,
                                timeout=90, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        if result.returncode or result.stderr:
            raise ValueError("Current exporter failed; inspect private preparation")
        marked = re.findall(r"(?m)^-- BEGIN MODULE (\S+)$", output.read_text(encoding="utf-8-sig"))
        if len(marked) != 19 or set(marked) != ids:
            raise ValueError("Export cohort differs")
        exports[mode] = str(output)
    cases = [c for c in new_parameter_help_cases.cases() if c["module"] in ids]
    fixture = directory / "Stable19.Help.json"
    fixture.write_bytes(encoded(cases))
    public = [{k: o[k] for k in ("module", "schema", "name", "type")}
              for o in generate_api_catalog.objects(ROOT) if o["module"] in ids]
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    public_pins = {p: sha((ROOT / p).read_bytes()) for p in sorted(paths)}
    # Jede versionierte Test-/Produktquelle muss wirklich aus dem angegebenen Commit stammen.
    for relative, digest in public_pins.items():
        data = subprocess.check_output(["git", "show", commit + ":" + relative], cwd=ROOT)
        if sha(data) != digest:
            raise ValueError("Uncommitted qualification input: " + relative)
    private_paths = set(exports.values()) | {str(fixture), str(directory / "private-selection.json")}
    private_paths |= {selection[k] for k in ("contract_path", "schema_path", "prompt_path")}
    pins = [{"path": str(ROOT / p), "sha256": d} for p, d in public_pins.items()]
    pins += [{"path": p, "sha256": sha(Path(p).read_bytes())} for p in sorted(private_paths)]
    record = dict(schema_version="toolbelt-stable19-acceptance/v1", source_commit=commit,
                  cases=selection["cases"], modules=[dict(module_id=k, module_version=v)
                  for k, v in sorted(versions.items())], public_objects=public,
                  exports=exports, fixture=str(fixture), uninstall_files=uninstall, pins=pins,
                  contract_sha256=sha(Path(selection["contract_path"]).read_bytes()),
                  schema_sha256=sha(Path(selection["schema_path"]).read_bytes()),
                  prompt_sha256=sha(Path(selection["prompt_path"]).read_bytes()))
    (directory / "runset.json").write_bytes(encoded(record))
    (directory / "public-inputs.json").write_bytes(encoded(dict(source_commit=commit,
        source_sha256=public_pins, exports_sha256={m: sha(Path(p).read_bytes()) for m, p in exports.items()},
        help_fixture_sha256=sha(fixture.read_bytes()), modules=record["modules"], public_objects=public)))
    print("PASS prepared 19 current modules, two exports and pinned installed-Help oracles; no SQL")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    prepare(parser.parse_args().directory)

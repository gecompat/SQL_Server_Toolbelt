"""Aktuellen Windows-CLR-Provider bauen und seine private Eingabebindung prüfen.

Ein Manifest ist ein Integritätsvertrag für vertrauenswürdige lokale Buildinputs,
keine Signatur, Rechtefreigabe oder native Qualifikation.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
MODULE = "toolbelt.filesystem.windows"
DLL = "Toolbelt.Filesystem.Windows.dll"
MANIFEST = "Toolbelt.Filesystem.Windows.build.json"
SCHEMA = "toolbelt-filesystem-build/v1"


def require(value, message):
    if not value:
        raise ValueError("FILESYSTEM_BUILD: " + message)


def digest(value, algorithm="sha256"):
    return hashlib.new(algorithm, value).hexdigest()


def sources(root):
    sys.path.insert(0, str(root / "Scripts/Metadata"))
    import clr_usage_skills
    import usage_skills
    folder = root / "Modules" / MODULE / "Clr"
    clr_usage_skills.generate(root, MODULE, "Toolbelt.Filesystem.Windows",
                              folder / "UsageSkillsGenerated.cs", check=True)
    paths = {p for p in folder.rglob("*") if p.suffix in (".cs", ".csproj")
             and not {"bin", "obj"} & set(p.parts)}
    paths.update(root / p for p in ("Scripts/Install/filesystem_build.py",
                 "Scripts/Metadata/clr_usage_skills.py", "Scripts/Metadata/usage_skills.py",
                 "Modules/toolbelt.filesystem.windows/module.yaml"))
    paths.update(usage_skills.source_file(root, s.metadata["schema_name"], s.metadata["object_name"])
                 for s in clr_usage_skills.module_records(root, MODULE))
    require(all(p.resolve().is_relative_to(root.resolve()) and not p.is_symlink() for p in paths), "source boundary")
    return {p.relative_to(root).as_posix(): digest(p.read_bytes().replace(b"\r\n", b"\n")) for p in sorted(paths)}


def admit(root, directory):
    manifest = json.loads((directory / MANIFEST).read_text(encoding="utf-8"))
    require(set(manifest) == {"schema", "moduleId", "binaryFile", "binarySha256", "binarySha512",
                             "sourceFiles", "build", "sqlExecuted"}, "manifest fields")
    require(manifest["schema"] == SCHEMA and manifest["moduleId"] == MODULE
            and manifest["binaryFile"] == DLL and manifest["sqlExecuted"] is False, "manifest identity")
    require(manifest["sourceFiles"] == sources(root), "current source binding")
    build = manifest["build"]
    require(isinstance(build, dict) and set(build) == {"configuration", "deterministic", "debugType", "msbuildSha256"}
            and build["configuration"] == "Release" and build["deterministic"] is True
            and build["debugType"] == "None" and isinstance(build["msbuildSha256"], str)
            and len(build["msbuildSha256"]) == 64
            and all(c in "0123456789abcdef" for c in build["msbuildSha256"]), "build contract")
    payload = (directory / DLL).read_bytes()
    require(payload.startswith(b"MZ") and digest(payload) == manifest["binarySha256"]
            and digest(payload, "sha512") == manifest["binarySha512"], "binary binding")
    return payload


def build(root, output, msbuild):
    require(os.name == "nt", "Windows build required")
    require(output.resolve().is_relative_to((root / ".runtime").resolve()), "private build boundary")
    require(not output.exists(), "new private output required")
    require(msbuild.is_file() and msbuild.suffix.casefold() == ".exe", "MSBuild executable required")
    before = sources(root)
    compiler = digest(msbuild.read_bytes())
    output.mkdir(parents=True)
    project = root / "Modules" / MODULE / "Clr/Toolbelt.Filesystem.Windows.csproj"
    # No SQL, trust, file-provider operation or downloaded build dependency.
    args = [str(msbuild), str(project), "/nologo", "/v:minimal", "/t:Rebuild", "/nr:false", "/m:1",
            "/p:Configuration=Release", "/p:Deterministic=true", "/p:DebugType=None", "/p:DebugSymbols=false",
            "/p:UseSharedCompilation=false",
            "/p:OutputPath=" + str(output.resolve()) + "/",
            "/p:BaseIntermediateOutputPath=" + str((output / "obj").resolve()) + "/"]
    with (output / "Build.stdout.private.bin").open("xb") as stdout, (output / "Build.stderr.private.bin").open("xb") as stderr:
        with subprocess.Popen(args, cwd=root, stdout=stdout, stderr=stderr) as process:
            try:
                status = process.wait(timeout=180)
            except subprocess.TimeoutExpired:
                # Positive ownership is the live Popen handle. Never enumerate
                # other MSBuild/compiler processes or kill by executable name.
                if process.poll() is None:
                    subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15)
                process.wait(timeout=15)
                raise ValueError("FILESYSTEM_BUILD: owned project build timed out")
    require(status == 0, "project build failed; private capture retained")
    require(before == sources(root) and compiler == digest(msbuild.read_bytes()), "build input drift")
    payload = (output / DLL).read_bytes()
    manifest = dict(schema=SCHEMA, moduleId=MODULE, binaryFile=DLL, binarySha256=digest(payload),
                    binarySha512=digest(payload, "sha512"), sourceFiles=before,
                    build=dict(configuration="Release", deterministic=True, debugType="None", msbuildSha256=compiler),
                    sqlExecuted=False)
    (output / MANIFEST).write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="utf-8", newline="\n")
    require(admit(root, output) == payload, "postbuild admission")
    return len(before)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--msbuild", type=Path, required=True)
    args = parser.parse_args()
    print("FILESYSTEM_SOURCE_BUILD_PASS sources=" + str(build(ROOT, args.output, args.msbuild))
          + "; SQL_NOT_EXECUTED; NATIVE_HELP_NOT_QUALIFIED")

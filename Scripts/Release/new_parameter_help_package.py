"""Compose current fresh-install SQL with complete parameter Help; no SQL access.

Frozen baseline packages/evidence are inputs, never overwritten or requalified.
The SSIS provider must be rebuilt reproducibly with its existing release builder.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Documentation"))
import generate_parameter_help as helpgen

OUTPUT = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Parameter-Help.zip"
BASELINE = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Maintenance.zip"
SSIS = "Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-Current-Install-Windows.zip"
WINDOWS_ONLY = {"toolbelt.archive.zip-files", "toolbelt.filesystem.windows", "toolbelt.tsql.script-parser", "toolbelt.tsql.ssis-debug"}
LOCAL_ONLY = {"toolbelt.archive.zip-files", "toolbelt.filesystem.windows"}
NOTICE_SOURCES = {
    **{"ThirdParty/ScriptDom-180.117.0/" + name: "ThirdParty/ScriptDom-180.117.0/" + name
       for name in ("LICENSE", "NOTICE.txt", "ORIGIN.txt", "README.md", "package.nuspec")},
    **{"ThirdParty/ApacheCommonsCodec/" + name: "Sources/Modules/toolbelt.string.phonetic/ThirdParty/ApacheCommonsCodec/" + name
       for name in ("LICENSE.txt", "NOTICE.txt", "README.md")},
}


def sha(data, algorithm="sha256"):
    return hashlib.new(algorithm, data).hexdigest()


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()


def package_readme(root=ROOT):
    # The ZIP does not contain a repository checkout. Resolve the two source-page
    # link prefixes to public repository pages instead of shipping broken ../ links.
    data = (Path(root) / "Releases/1.0.0/PARAMETER-HELP.md").read_bytes()
    base = b"https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/"
    return data.replace(b"(../../", b"(" + base).replace(b"(InstallPackages/", b"(" + base + b"Releases/1.0.0/InstallPackages/")


def notices(root=ROOT):
    with zipfile.ZipFile(Path(root)/BASELINE) as archive:
        prefix="SQL-Server-Toolbelt-1.0.0-CLR-Install/"
        return {target:archive.read(prefix+source) for target,source in NOTICE_SOURCES.items()}


def pre_followup_payload(payload, root=ROOT):
    """Undo exact guidance/attribution additions; installer/build bytes unchanged."""
    previous = dict(payload)
    for name,data in notices(root).items():
        if previous.pop(name) != data: raise ValueError("Existing third-party attribution differs")
    previous["START-HERE.md"] = (Path(root) / "Releases/1.0.0/PARAMETER-HELP.md").read_bytes()
    metadata = json.loads(previous["PACKAGE.json"])
    for name in NOTICE_SOURCES: metadata["files"].pop(name)
    metadata["files"]["START-HERE.md"] = sha(previous["START-HERE.md"])
    previous["PACKAGE.json"] = encoded(metadata)
    previous["SHA256SUMS"] = "".join(sha(b) + "  " + p + "\n" for p,b in sorted(previous.items()) if p != "SHA256SUMS").encode()
    return previous


def source_closure(path, result):
    path = path.resolve(strict=True)
    if not path.is_relative_to(ROOT) or path.is_symlink():
        raise ValueError("Source outside repository")
    relative = path.relative_to(ROOT).as_posix()
    if relative in result: return
    data = path.read_bytes().replace(b"\r\n", b"\n")
    result[relative] = sha(data)
    for include in re.findall(r'^\s*:r\s+([^\r\n]+)', data.decode("utf-8-sig"), re.M | re.I):
        source_closure(path.parent / include.strip().strip('"\''), result)


def build(release_directory, work_directory):
    helpgen.generate()
    release_directory, work = Path(release_directory).resolve(), Path(work_directory).resolve()
    if not work.is_relative_to(ROOT / ".runtime") or work.exists():
        raise ValueError("New private .runtime work directory required")
    work.mkdir(parents=True)
    with zipfile.ZipFile(ROOT / BASELINE) as archive:
        prefix = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"
        artifacts = json.loads(archive.read(prefix + "CLR-PACKAGE.json"))["artifacts"]
        binaries = {}
        for a in artifacts:
            data = archive.read(prefix + "Binaries/" + a["file"])
            if sha(data, "sha512") != a["sha512"].lower(): raise ValueError("Baseline binary differs")
            binaries[a["file"]] = data
    with zipfile.ZipFile(ROOT / SSIS) as archive:
        for name in ("Toolbelt.Tsql.ScriptParser.dll", "Microsoft.SqlServer.TransactSql.ScriptDom.dll"):
            matches = [n for n in archive.namelist() if n.endswith("/toolbelt.tsql.script-parser/Artifacts/" + name)]
            if len(matches) != 1: raise ValueError("Pinned parser input missing")
            binaries[name] = archive.read(matches[0])
    manifest = json.loads((release_directory / "Toolbelt.Tsql.SsisDebug.trust-manifest.json").read_text(encoding="utf-8-sig"))
    binary = (release_directory / "Toolbelt.Tsql.SsisDebug.dll").read_bytes()
    if not manifest["reproducedBuild"] or sha(binary, "sha512") != manifest["sha512"].lower():
        raise ValueError("Reproducible SSIS release required")
    for entry in manifest["sourceFiles"]:
        path, digest = entry.rsplit(":", 1)
        data = (ROOT / "Modules/toolbelt.tsql.ssis-debug" / path).read_bytes()
        if sha(data).upper() != digest: raise ValueError("SSIS build source differs")
    binaries["Toolbelt.Tsql.SsisDebug.dll"] = binary
    by_module = {a["module_id"]: a for a in artifacts if a["module_id"]}
    modules = sorted(p.parent.name for p in (ROOT / "Modules").glob("*/module.yaml"))
    sources, profiles = {}, []
    for platform in ("Windows", "Portable"):
        for mode in ("local", "central"):
            selected = [m for m in modules if not (platform == "Portable" and m in WINDOWS_ONLY)
                        and not (mode == "central" and m in LOCAL_ONLY)]
            variables = {}
            for module in selected:
                closure = {}
                source_closure(ROOT / "Modules" / module / "Deployment/Deploy.sql", closure)
                sources.update(closure)
                names = set()
                for path in closure:
                    names.update(re.findall(r'\$\(([A-Za-z][A-Za-z0-9_]*)\)', (ROOT / path).read_text(encoding="utf-8-sig")))
                values = {}
                for name in names - {"DeploymentMode", "PublicProcedureSql", "InternalProcedureSql"}:
                    if name == "AssemblyBits": value = "0x" + binaries[by_module[module]["file"]].hex()
                    elif name == "ScriptDomAssemblyBits": value = "0x" + binaries["Microsoft.SqlServer.TransactSql.ScriptDom.dll"].hex()
                    elif name == "ExpectedComparisonAssemblyHash": value = "0x" + sha(binaries["Toolbelt.String.EditDistance.dll"], "sha512")
                    elif name == "ExpectedAssemblySha512": value = "0x" + sha(binaries[by_module[module]["file"]], "sha512")
                    elif name == "ExpectedInstalledAssemblyHash": value = "0x"
                    else: raise ValueError("Unbound deployment variable: " + module + "/" + name)
                    values[name] = value
                if values: variables[module] = values
            profiles.append(dict(name=platform + "-" + mode, platform=platform, mode=mode, modules=selected,
                                 variables=variables, output=str(work / ("Install-" + platform + "-" + mode + ".sql"))))
    inputs = work / "export-inputs.json"
    inputs.write_bytes(encoded(dict(profiles=profiles)))
    command = ["pwsh", "-NoProfile", "-File", str(ROOT / "Scripts/Release/New-ParameterHelpExport.ps1"), "-InputsFile", str(inputs)]
    kwargs = {"creationflags": subprocess.CREATE_NO_WINDOW} if sys.platform == "win32" else {}
    result = subprocess.run(command, cwd=ROOT, timeout=180, capture_output=True, **kwargs)
    (work / "export-private.log").write_bytes(result.stdout + result.stderr)
    if result.returncode:
        raise ValueError("Deployment export failed; inspect private export-private.log")
    payload = {Path(p["output"]).name: Path(p["output"]).read_bytes() for p in profiles}
    payload["LICENSE.md"] = (ROOT / "LICENSE.md").read_bytes()
    payload.update(notices())
    payload["START-HERE.md"] = package_readme()
    payload["SSIS-BUILD.json"] = (release_directory / "Toolbelt.Tsql.SsisDebug.trust-manifest.json").read_bytes()
    payload["Trust-Windows.sql"] = ("USE [master];\nGO\n" + "\n".join(
        "IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x" + sha(data, "sha512") + ") EXEC sys.sp_add_trusted_assembly @hash=0x" + sha(data, "sha512") + ",@description=N'Toolbelt Parameter Help " + name + "';"
        for name, data in sorted(binaries.items())) + "\nGO\n").encode()
    portable_names = {a["file"] for a in artifacts if a["module_id"] and a["module_id"] not in WINDOWS_ONLY}
    payload["Trust-Portable.sql"] = ("USE [master];\nGO\n" + "\n".join(
        "IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x" + sha(binaries[name], "sha512") + ") EXEC sys.sp_add_trusted_assembly @hash=0x" + sha(binaries[name], "sha512") + ",@description=N'Toolbelt Parameter Help " + name + "';"
        for name in sorted(portable_names)) + "\nGO\n").encode()
    record = dict(schema_version="toolbelt-parameter-help-package/v1", scope="CURRENT_FRESH_INSTALL_HELP_CONTRACT",
                  native_qualification="separate evidence; no full business requalification", publication_authorized=False,
                  predecessor_packages={p: sha((ROOT / p).read_bytes()) for p in (BASELINE, SSIS)},
                  profiles=[{k: p[k] for k in ("name", "platform", "mode", "modules")} for p in profiles],
                  source_sha256=sources, binary_sha512={n: sha(b, "sha512") for n, b in binaries.items()},
                  editorial_sha256={p: sha((ROOT / p).read_bytes()) for p in ("Documentation/Reference/api_examples.json",helpgen.METADATA)},
                  files={p: sha(b) for p,b in payload.items()})
    payload["PACKAGE.json"] = encoded(record)
    payload["SHA256SUMS"] = "".join(sha(b) + "  " + p + "\n" for p,b in sorted(payload.items())).encode()
    output = ROOT / OUTPUT
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payload.items()):
            info = zipfile.ZipInfo(name, (2026,10,30,0,0,0)); info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644 << 16
            archive.writestr(info, data)
    output.with_suffix(".zip.sha256").write_text(sha(output.read_bytes()) + "  " + output.name + "\n", encoding="ascii")
    print("Current parameter Help fresh-install package generated; native verification remains separate.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ssis-release", required=True)
    parser.add_argument("--work-directory", required=True)
    args = parser.parse_args()
    build(args.ssis_release, args.work_directory)

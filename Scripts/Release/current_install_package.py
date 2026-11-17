"""Gemeinsamer aktueller Fresh-Install-Satz; historische Lieferungen bleiben erhalten."""
from __future__ import annotations
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile
import new_parameter_help_package as base

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Current-Install.zip"
SSIS = "Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-SecurityCorrected-Install-Windows.zip"
REGISTRY = "Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json"
GUIDE = "Releases/1.0.0/CURRENT-INSTALL.md"
RECORD = "Releases/1.0.0/CURRENT-INSTALL-QUALIFICATION.json"
PARSER_SHA512 = "f2213559fa9085bdac9b6a4c1954d7be18eaae9bfbf950e2a29cc0121d8b36d6838d4366327d3a6b0c9ed655179acbe898e2887d917aa0d0c2b7c243c891c16a"
REPLACED = {"toolbelt.json.constructors", "toolbelt.tsql.script-parser", "toolbelt.tsql.ssis-debug"}


def require(value, message):
    if not value:
        raise ValueError("CURRENT_INSTALL: " + message)


def compiled_sources():
    return {p.relative_to(ROOT).as_posix(): base.sha(p.read_bytes().replace(b"\r\n", b"\n"))
            for p in (ROOT / "Modules").glob("*/Clr/**/*")
            if p.suffix in (".cs", ".csproj") and not {"bin", "obj"} & set(p.parts)}


def checked_inputs(inputs):
    """Exakte bekannte Bytes und ihre aktuellen Compilerquellen prüfen, nichts neu vertrauen."""
    inputs = Path(inputs)
    with zipfile.ZipFile(ROOT / base.BASELINE) as archive:
        prefix = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"
        metadata = json.loads(archive.read(prefix + "CLR-PACKAGE.json"))
        for artifact in metadata["artifacts"]:
            data = archive.read(prefix + "Binaries/" + artifact["file"])
            require(base.sha(data, "sha512") == artifact["sha512"].lower(), "baseline binary drift")
        for name in archive.namelist():
            source_prefix = prefix + "Sources/"
            if not name.startswith(source_prefix):
                continue
            relative = name[len(source_prefix):]
            parts = Path(relative).parts
            if "/Clr/" in relative and relative.endswith((".cs", ".csproj")) and parts[1] not in REPLACED:
                require(archive.read(name).replace(b"\r\n", b"\n") == (ROOT / relative).read_bytes().replace(b"\r\n", b"\n"), "unchanged compiler input drift: " + relative)
    registry = json.loads((ROOT / REGISTRY).read_bytes())
    fields = next(a["Fields"] for a in registry["artifacts"] if a["Fields"]["moduleId"] == "toolbelt.json.constructors")
    constructor = (inputs / "Toolbelt.JsonConstructors.dll").read_bytes()
    require(base.sha(constructor) == fields["binarySha256"] and base.sha(constructor, "sha512") == fields["binarySha512"], "constructor binary drift")
    require(base.sha((ROOT / "Modules/toolbelt.json.constructors/Clr/Toolbelt.JsonConstructors.csproj").read_bytes()) == fields["projectSha256"], "constructor project drift")
    for name, expected in fields.items():
        if name.startswith("source/"):
            require(base.sha((ROOT / "Modules/toolbelt.json.constructors/Clr" / name[7:]).read_bytes()) == expected, "constructor compiler input drift: " + name)
    parser = (inputs / "parser/Toolbelt.Tsql.ScriptParser.dll").read_bytes()
    parser_manifest = json.loads((inputs / "parser/Toolbelt.Tsql.ScriptParser.trust-manifest.json").read_bytes())
    require(base.sha(parser, "sha512") == parser_manifest["sha512"].lower() == PARSER_SHA512, "parser binary drift")
    for entry in parser_manifest["sourceFiles"]:
        name, expected = entry.rsplit(":", 1)
        require(base.sha((ROOT / "Modules/toolbelt.tsql.script-parser" / name).read_bytes()).upper() == expected, "parser compiler input drift: " + name)
    native = json.loads((ROOT / "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.ZipSsms.20261116.json").read_bytes())
    require(native["package"]["path"] == SSIS and base.sha((ROOT / SSIS).read_bytes()) == native["package"]["sha256"], "qualified SSIS archive drift")
    ssis = (inputs / "ssis/Toolbelt.Tsql.SsisDebug.dll").read_bytes()
    with zipfile.ZipFile(ROOT / SSIS) as archive:
        names = [n for n in archive.namelist() if n.endswith("/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.dll")]
        require(len(names) == 1 and ssis == archive.read(names[0]), "SSIS qualified package binary drift")
    overrides = {"Toolbelt.JsonConstructors.dll": constructor, "Toolbelt.Tsql.ScriptParser.dll": parser}
    return overrides, {"registry": REGISTRY, "registry_sha256": base.sha((ROOT / REGISTRY).read_bytes()),
                       "compiled_source_sha256": compiled_sources(),
                       "parser_build": parser_manifest,
                       "binary_sha256": {**{n: base.sha(b) for n, b in overrides.items()}, "Toolbelt.Tsql.SsisDebug.dll": base.sha(ssis)}}


def build(inputs, work, output=OUTPUT):
    overrides, provenance = checked_inputs(inputs)
    target = ROOT / output
    require(not target.exists() and not Path(str(target) + ".sha256").exists(), "new output required")
    readme = (ROOT / GUIDE).read_bytes().replace(b"(../../", b"(https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/")
    base.build(Path(inputs) / "ssis", work, binary_overrides=overrides, output_path=output,
               ssis_package=SSIS, readme=readme, generate_help=False)
    with zipfile.ZipFile(target) as archive:
        payload = {n: archive.read(n) for n in archive.namelist()}
    payload["BINARY-PROVENANCE.json"] = base.encoded(provenance)
    metadata = json.loads(payload["PACKAGE.json"])
    metadata["scope"] = "CURRENT_COMBINED_FRESH_INSTALL"
    metadata["files"]["BINARY-PROVENANCE.json"] = base.sha(payload["BINARY-PROVENANCE.json"])
    payload["PACKAGE.json"] = base.encoded(metadata)
    payload["SHA256SUMS"] = "".join(base.sha(b) + "  " + n + "\n" for n, b in sorted(payload.items()) if n != "SHA256SUMS").encode()
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payload.items()):
            info = zipfile.ZipInfo(name, (2026, 11, 17, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    Path(str(target) + ".sha256").write_text(base.sha(target.read_bytes()) + "  " + target.name + "\n", encoding="ascii")
    validate(target)


def validate(path):
    path = Path(path)
    require(Path(str(path) + ".sha256").read_text(encoding="ascii").split() == [base.sha(path.read_bytes()), path.name], "archive checksum")
    with zipfile.ZipFile(path) as archive:
        require(len(archive.namelist()) == len(set(archive.namelist())), "duplicate entries")
        payload = {n: archive.read(n) for n in archive.namelist()}
    return validate_payload(payload)


def validate_payload(payload):
    """Auch selbstkonsistent neu gehashte falsche Profile/Binaries zurückweisen."""
    metadata = json.loads(payload["PACKAGE.json"])
    require(metadata["scope"] == "CURRENT_COMBINED_FRESH_INSTALL" and metadata["publication_authorized"] is False, "scope")
    require(metadata["files"] == {n: base.sha(b) for n, b in payload.items() if n not in ("PACKAGE.json", "SHA256SUMS")}, "file manifest")
    require(payload["SHA256SUMS"] == "".join(base.sha(b) + "  " + n + "\n" for n, b in sorted(payload.items()) if n != "SHA256SUMS").encode(), "entry checksums")
    require(payload["LICENSE.md"] == (ROOT / "LICENSE.md").read_bytes(), "license")
    require(json.loads(payload["BINARY-PROVENANCE.json"])["compiled_source_sha256"] == compiled_sources(), "current compiler closure")
    for name, expected in metadata["source_sha256"].items():
        require(base.sha((ROOT / name).read_bytes().replace(b"\r\n", b"\n")) == expected, "deployment/source drift: " + name)
    require(metadata["predecessor_packages"] == {p: base.sha((ROOT / p).read_bytes()) for p in (base.BASELINE, SSIS)}, "predecessor drift")
    baseline = zipfile.ZipFile(ROOT / base.BASELINE)
    artifacts = json.loads(baseline.read("SQL-Server-Toolbelt-1.0.0-CLR-Install/CLR-PACKAGE.json"))["artifacts"]
    baseline.close()
    expected_hashes = {a["file"]: a["sha512"].lower() for a in artifacts}
    ctor = next(a["Fields"] for a in json.loads((ROOT / REGISTRY).read_bytes())["artifacts"] if a["Fields"]["moduleId"] == "toolbelt.json.constructors")
    ssis_record = json.loads((ROOT / "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.ZipSsms.20261116.json").read_bytes())
    expected_hashes.update({"Toolbelt.JsonConstructors.dll": ctor["binarySha512"], "Toolbelt.Tsql.ScriptParser.dll": PARSER_SHA512, "Toolbelt.Tsql.SsisDebug.dll": ssis_record["package"]["provider_sha512"]})
    require(metadata["binary_sha512"] == expected_hashes, "qualified binary set")
    modules = sorted(p.parent.name for p in (ROOT / "Modules").glob("*/module.yaml"))
    closure = {}
    for module in modules:
        base.source_closure(ROOT / "Modules" / module / "Deployment/Deploy.sql", closure)
    require(metadata["source_sha256"] == closure, "complete deployment closure")
    require(len(metadata["profiles"]) == 4 and {p["name"] for p in metadata["profiles"]} == {p+"-"+m for p in ("Windows", "Portable") for m in ("local", "central")}, "four profiles required")
    for profile in metadata["profiles"]:
        require(profile["platform"] in ("Windows", "Portable") and profile["mode"] in ("local", "central") and profile["name"] == profile["platform"]+"-"+profile["mode"], "profile identity")
        selected = [m for m in modules if not (profile["platform"] == "Portable" and m in base.WINDOWS_ONLY)
                    and not (profile["mode"] == "central" and m in base.LOCAL_ONLY)]
        require(profile["modules"] == selected, "profile dependency set")
        data = payload["Install-" + profile["name"] + ".sql"]
        require(b":ON ERROR EXIT" in data and b"$(" not in data, "incomplete standalone export")
        import re
        actual_hashes = {base.sha(bytes.fromhex(blob.decode()), "sha512") for blob in re.findall(rb"0x(4[dD]5[aA][0-9a-fA-F]{512,})", data)}
        expected_profile = {expected_hashes[a["file"]] for a in artifacts if a["module_id"] in selected or (a["module_id"] is None and profile["platform"] == "Windows")}
        require(actual_hashes == expected_profile, "embedded binary set: " + profile["name"])
    return metadata, payload


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inputs")
    parser.add_argument("--work")
    parser.add_argument("--output", default=OUTPUT)
    parser.add_argument("--verify", type=Path)
    args = parser.parse_args()
    if args.verify:
        validate(args.verify)
    else:
        require(args.inputs and args.work, "inputs and work required")
        build(args.inputs, args.work, args.output)
    print("CURRENT_COMBINED_INSTALL_INTEGRITY_PASS; no publication or full business requalification")

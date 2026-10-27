"""Prüft die Parserlieferung und extrahiert nur die gebundenen DLL-Bytes."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import zipfile

PACKAGE = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
SIDECAR = PACKAGE + ".sha256"
QUALIFICATION = "Releases/1.0.0/clr-qualification.json"
PACKAGE_SHA256 = "896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287"
QUALIFICATION_SHA256 = "d484d87d8e5322b8ab55dbf8ee8901626df7ff4cb066f48b0bdd2dd90486936d"
ROOT_IN_ZIP = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"
MANIFEST = ROOT_IN_ZIP + "CLR-PACKAGE.json"
PROVIDER = ROOT_IN_ZIP + "Binaries/Toolbelt.Tsql.ScriptParser.dll"
SCRIPTDOM = ROOT_IN_ZIP + "Binaries/Microsoft.SqlServer.TransactSql.ScriptDom.dll"
PROVIDER_SHA256 = "51dcb066f373d8a91c61320c04139c62332c9ad1b1e2db4d42bea6e703e7e75f"
SCRIPTDOM_SHA256 = "c467c638ed53caba55ec1a4ae534990326ac1811046ef12775f5bbd46478b7cb"


class PackageError(ValueError):
    """Ein Archiv oder eine seiner festen Binärbindungen ist ungültig."""


def sha(data: bytes, algorithm: str = "sha256") -> str:
    return hashlib.new(algorithm, data).hexdigest()


def read_archive(data: bytes) -> dict[str, bytes]:
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            seen: set[str] = set()
            files: dict[str, bytes] = {}
            infos = archive.infolist()
            if len(infos) > 10000 or sum(item.file_size for item in infos) > 256 * 1024 * 1024:
                raise PackageError("SCRIPT_PARSER_ARCHIVE_LIMIT")
            for item in infos:
                name = item.filename
                path = PurePosixPath(name.rstrip("/"))
                if (not name or "\\" in name or ":" in name or path.is_absolute()
                        or any(part in ("", ".", "..") for part in path.parts)
                        or name.casefold() in seen):
                    raise PackageError("SCRIPT_PARSER_ARCHIVE_PATH")
                seen.add(name.casefold())
                if item.flag_bits & 1:
                    raise PackageError("SCRIPT_PARSER_ARCHIVE_ENCRYPTED")
                if not item.is_dir():
                    files[name] = archive.read(item)
            if archive.testzip() is not None:
                raise PackageError("SCRIPT_PARSER_ARCHIVE_CRC")
            return files
    except (OSError, zipfile.BadZipFile, RuntimeError, UnicodeError) as exc:
        raise PackageError("SCRIPT_PARSER_ARCHIVE_INVALID") from exc


def inspect(archive_bytes: bytes, sidecar: bytes, qualification_bytes: bytes) -> tuple[dict, bytes, bytes]:
    digest = sha(archive_bytes)
    if digest != PACKAGE_SHA256:
        raise PackageError("SCRIPT_PARSER_PACKAGE_SHA256")
    if sha(qualification_bytes) != QUALIFICATION_SHA256:
        raise PackageError("SCRIPT_PARSER_QUALIFICATION_SHA256")
    if sidecar != f"{digest}  {Path(PACKAGE).name}\n".encode("ascii"):
        raise PackageError("SCRIPT_PARSER_SIDECAR")
    files = read_archive(archive_bytes)
    try:
        manifest = json.loads(files[MANIFEST])
        qualification = json.loads(qualification_bytes)
        provider = files[PROVIDER]
        scriptdom = files[SCRIPTDOM]
    except (KeyError, UnicodeError, json.JSONDecodeError) as exc:
        raise PackageError("SCRIPT_PARSER_METADATA") from exc
    artifacts = [a for a in manifest.get("artifacts", [])
                 if a.get("module_id") == "toolbelt.tsql.script-parser"]
    if len(artifacts) != 1:
        raise PackageError("SCRIPT_PARSER_ARTIFACT_COUNT")
    artifact = artifacts[0]
    if (manifest.get("schema_version") != "1.0" or manifest.get("publication_authorized") is not False
            or artifact.get("file") != "Toolbelt.Tsql.ScriptParser.dll"
            or artifact.get("origin") != "existing_qualified_ssis_package"):
        raise PackageError("SCRIPT_PARSER_ARTIFACT_IDENTITY")
    pins = qualification.get("binary_sha512", {})
    provider_sha512 = sha(provider, "sha512")
    scriptdom_sha512 = sha(scriptdom, "sha512")
    if (len(provider) != 20992 or len(scriptdom) != 6970680
            or sha(provider) != PROVIDER_SHA256 or sha(scriptdom) != SCRIPTDOM_SHA256
            or artifact.get("sha256") != PROVIDER_SHA256
            or artifact.get("sha512") != provider_sha512
            or pins.get("Binaries/Toolbelt.Tsql.ScriptParser.dll") != provider_sha512
            or pins.get("Binaries/Microsoft.SqlServer.TransactSql.ScriptDom.dll") != scriptdom_sha512):
        raise PackageError("SCRIPT_PARSER_BINARY_BINDING")
    result = {"package_sha256": digest,
              "provider": {"file": "Toolbelt.Tsql.ScriptParser.dll", "size": len(provider), "sha256": sha(provider)},
              "scriptdom": {"file": "Microsoft.SqlServer.TransactSql.ScriptDom.dll", "size": len(scriptdom), "sha256": sha(scriptdom)}}
    return result, provider, scriptdom


def prepare(root: Path, output: Path) -> dict:
    root = root.resolve(strict=True)
    runtime = root / ".runtime"
    output = output if output.is_absolute() else root / output
    if output.parent != runtime or output.exists() or output.is_symlink():
        raise PackageError("SCRIPT_PARSER_OUTPUT_SCOPE")
    if runtime.is_symlink() or (runtime.exists() and not runtime.is_dir()):
        raise PackageError("SCRIPT_PARSER_RUNTIME_SCOPE")
    archive, sidecar, qualification = ((root / name).read_bytes() for name in (PACKAGE, SIDECAR, QUALIFICATION))
    record, provider, scriptdom = inspect(archive, sidecar, qualification)
    runtime.mkdir(exist_ok=True)
    if runtime.is_symlink() or not runtime.is_dir() or output.exists():
        raise PackageError("SCRIPT_PARSER_OUTPUT_SCOPE")
    output.mkdir()
    output.joinpath("Toolbelt.Tsql.ScriptParser.dll").write_bytes(provider)
    output.joinpath("Microsoft.SqlServer.TransactSql.ScriptDom.dll").write_bytes(scriptdom)
    for key, name in (("provider", "Toolbelt.Tsql.ScriptParser.dll"),
                      ("scriptdom", "Microsoft.SqlServer.TransactSql.ScriptDom.dll")):
        written = output.joinpath(name).read_bytes()
        if sha(written) != record[key]["sha256"] or len(written) != record[key]["size"]:
            raise PackageError("SCRIPT_PARSER_EXTRACTED_DRIFT")
    print(json.dumps(record, separators=(",", ":")))
    return record


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    prepare(args.root, args.output)


if __name__ == "__main__":
    main()

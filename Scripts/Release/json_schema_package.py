"""Prüft die Paketbindung der vorhandenen JSON-Schema-Assembly."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
from typing import Any
import zipfile

import json_constructor_package as constructor_gate


PACKAGE_REL = constructor_gate.PACKAGE_REL
PACKAGE_NAME = PACKAGE_REL.name
PREFIX = constructor_gate.PREFIX
MANIFEST = constructor_gate.MANIFEST
PREDECESSOR_COMMIT = "e559896b4f9e4f496a09bfa7b7c5d690512bc433"
PREDECESSOR_REPORT = Path("Releases/1.0.0/JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.json")
PREDECESSOR_REPORT_SHA256 = "db60ada56c46f5930196c4b5ab339c6cd7cb20cd7969ea518beb51ed3e320c75"
SCHEMA_DLL = "Toolbelt.JsonSchema.dll"
CORE_DLL = "Toolbelt.JsonCore.dll"
CONSTRUCTOR_DLL = "Toolbelt.JsonConstructors.dll"
EXPECTED_FRAMEWORK_SCOPE = "OFFLINE_SOURCE_FRAMEWORK_ONLY"
EXPECTED_WITNESSES = {
    "CompileCore": "",
    "Compile-Toolbelt.JsonConstructors": "",
    "Compile-Toolbelt.JsonSchema": "",
    "IL-Toolbelt.JsonCore": "PASS JSON_SHARED_PRODUCT_IL",
    "IL-Toolbelt.JsonConstructors": "PASS JSON_SHARED_PRODUCT_IL",
    "IL-Toolbelt.JsonSchema": "PASS JSON_SHARED_PRODUCT_IL",
    "Compile-ProductHarness": "",
    "Compile-TokenHarness": "",
    "Compile-WorkBudgetHarness": "",
    "Compile-NumberHarness": "",
    "Compile-SchemaHarness": "",
    "Compile-BridgeHarness": "",
    "Constructors-en-US": "PASS PRODUCT_FRAMEWORK SMALL en-US ROWS 37 ASSERTIONS 960",
    "Numbers-en-US": "PASS SCHEMA_NUMBERS CASES 854 ASSERTIONS 6830",
    "Schema-en-US": "PASS SCHEMA_PROFILE cases=169 assertions=1275 culture=en-US",
    "Bridge-en-US": "PASS SCHEMA_BRIDGE assertions=120 culture=en-US",
    "Constructors-de-DE": "PASS PRODUCT_FRAMEWORK SMALL de-DE ROWS 37 ASSERTIONS 960",
    "Numbers-de-DE": "PASS SCHEMA_NUMBERS CASES 854 ASSERTIONS 6830",
    "Schema-de-DE": "PASS SCHEMA_PROFILE cases=169 assertions=1275 culture=de-DE",
    "Bridge-de-DE": "PASS SCHEMA_BRIDGE assertions=120 culture=de-DE",
    "Constructors-tr-TR": "PASS PRODUCT_FRAMEWORK SMALL tr-TR ROWS 37 ASSERTIONS 960",
    "Numbers-tr-TR": "PASS SCHEMA_NUMBERS CASES 854 ASSERTIONS 6830",
    "Schema-tr-TR": "PASS SCHEMA_PROFILE cases=169 assertions=1275 culture=tr-TR",
    "Bridge-tr-TR": "PASS SCHEMA_BRIDGE assertions=120 culture=tr-TR",
    "ConstructorLarge": "PASS PRODUCT_FRAMEWORK LARGE invariant ROWS 3 ASSERTIONS 67",
    "Tokens": "PASS CORE_TOKENS CASES 37 ASSERTIONS 95",
    "Budget": "PASS CORE_BUDGET ASSERTIONS 10",
}
EXPECTED_PHASES = tuple(EXPECTED_WITNESSES)
EXPECTED_BINARIES = {
    "Toolbelt.JsonCore.dll", "Toolbelt.JsonConstructors.dll", "Toolbelt.JsonSchema.dll",
    "ProductHarness.exe", "TokenHarness.exe", "WorkBudgetHarness.exe",
    "NumberHarness.exe", "SchemaHarness.exe", "BridgeHarness.exe",
}
EXPECTED_OUTPUTS = {
    SCHEMA_DLL: "Toolbelt.JsonSchema.dll",
    CORE_DLL: "Toolbelt.JsonCore.dll",
    CONSTRUCTOR_DLL: "Toolbelt.JsonConstructors.dll",
}
HEX_SHA256 = re.compile(r"[0-9a-f]{64}\Z")


class SchemaPackageError(ValueError):
    """Abgewiesene oder unvollständige Paket- und Frameworkbindung."""


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _repo_path(root: Path, relative: str) -> Path:
    if not isinstance(relative, str) or "\\" in relative:
        raise SchemaPackageError("FRAMEWORK_INPUT_PATH_INVALID")
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != "Modules":
        raise SchemaPackageError("FRAMEWORK_INPUT_PATH_INVALID")
    resolved = (root / path).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError as exc:
        raise SchemaPackageError("FRAMEWORK_INPUT_PATH_INVALID") from exc
    return resolved


def validate_predecessor(root: Path) -> tuple[dict[str, Any], bytes]:
    """Bindet die historischen Berichtsbytes an den festgelegten Main-Commit."""
    root = root.resolve()
    try:
        historic = (root / PREDECESSOR_REPORT).read_bytes()
    except OSError as exc:
        raise SchemaPackageError("PREDECESSOR_REPORT_UNAVAILABLE") from exc
    if sha256(historic) != PREDECESSOR_REPORT_SHA256:
        raise SchemaPackageError("PREDECESSOR_REPORT_DRIFT")
    try:
        report = json.loads(historic)
    except json.JSONDecodeError as exc:
        raise SchemaPackageError("PREDECESSOR_REPORT_INVALID") from exc
    if (report.get("status") != "PASS" or report.get("package", {}).get("sha256") is None
            or report.get("package", {}).get("path") != PACKAGE_REL.as_posix()
            or report.get("framework", {}).get("completed_phases") != len(EXPECTED_PHASES)
            or report.get("framework", {}).get("post_pins") is not True
            or report.get("framework", {}).get("source_binaries_match_package") is not True
            or report.get("framework", {}).get("schema_binary_package_bound") is not False):
        raise SchemaPackageError("PREDECESSOR_REPORT_SCOPE_INVALID")
    package_hash = report["package"]["sha256"]
    if not isinstance(package_hash, str) or not HEX_SHA256.fullmatch(package_hash):
        raise SchemaPackageError("PREDECESSOR_PACKAGE_HASH_INVALID")
    return report, historic


def validate_source_pins(root: Path, report: dict[str, Any]) -> dict[str, str]:
    """Prüft die im Vorgängerbericht gebundenen, festen Frameworkeingaben."""
    pins = report.get("framework_input_pins")
    if not isinstance(pins, dict) or len(pins) != 38:
        raise SchemaPackageError("FRAMEWORK_PUBLIC_INPUT_SET_INVALID")
    for relative, expected in pins.items():
        if not isinstance(expected, str) or not HEX_SHA256.fullmatch(expected):
            raise SchemaPackageError("FRAMEWORK_PUBLIC_INPUT_HASH_INVALID")
        path = _repo_path(root, relative)
        try:
            actual = sha256(path.read_bytes())
        except OSError as exc:
            raise SchemaPackageError("FRAMEWORK_PUBLIC_INPUT_MISSING") from exc
        if actual != expected:
            raise SchemaPackageError("FRAMEWORK_PUBLIC_INPUT_DRIFT")
    return pins


def validate_framework_receipt(
    root: Path,
    framework_root: Path,
    public_pins: dict[str, str],
    receipt: Any,
    frozen_inputs: Any,
    schema_il: Any,
) -> dict[str, dict[str, Any]]:
    """Prüft den erfolgreichen privaten 27-Phasenlauf samt frischen Eingaben."""
    if (not isinstance(receipt, dict) or set(receipt) != {"binaryPins", "phases", "postPins", "scope", "status"}
            or receipt.get("status") != "COMPLETE" or receipt.get("scope") != EXPECTED_FRAMEWORK_SCOPE
            or receipt.get("postPins") is not True):
        raise SchemaPackageError("FRAMEWORK_RECEIPT_INVALID")
    phases = receipt.get("phases")
    if (not isinstance(phases, list) or len(phases) != len(EXPECTED_PHASES)
            or tuple(p.get("name") for p in phases if isinstance(p, dict)) != EXPECTED_PHASES
            or any(set(p) != {"name", "exitCode", "captureComplete", "emptyStderr", "witness"}
                   or p.get("exitCode") != 0 or p.get("captureComplete") is not True
                   or p.get("emptyStderr") is not True
                   or p.get("witness") != EXPECTED_WITNESSES[p.get("name")] for p in phases)):
        raise SchemaPackageError("FRAMEWORK_PHASES_INCOMPLETE")
    if (not isinstance(schema_il, dict) or schema_il.get("status") != "PASS"
            or schema_il.get("scope") != "own product and pinned shared Core calls only"
            or schema_il.get("unknown") != []):
        raise SchemaPackageError("FRAMEWORK_SCHEMA_SOURCE_IL_INVALID")

    if not isinstance(frozen_inputs, list) or len(frozen_inputs) != 43:
        raise SchemaPackageError("FRAMEWORK_FROZEN_INPUT_SET_INVALID")
    input_paths: set[str] = set()
    public_seen: dict[str, str] = {}
    for item in frozen_inputs:
        if (not isinstance(item, dict) or set(item) != {"path", "sha256"}
                or not isinstance(item["path"], str) or not isinstance(item["sha256"], str)
                or not HEX_SHA256.fullmatch(item["sha256"].lower())):
            raise SchemaPackageError("FRAMEWORK_FROZEN_INPUT_INVALID")
        raw_path = Path(item["path"])
        if not raw_path.is_absolute():
            raw_path = (root / raw_path).resolve()
        key = str(raw_path.resolve()).casefold()
        if key in input_paths:
            raise SchemaPackageError("FRAMEWORK_FROZEN_INPUT_DUPLICATE")
        input_paths.add(key)
        try:
            actual = sha256(raw_path.read_bytes())
        except OSError as exc:
            raise SchemaPackageError("FRAMEWORK_FROZEN_INPUT_MISSING") from exc
        if actual != item["sha256"].lower():
            raise SchemaPackageError("FRAMEWORK_FROZEN_INPUT_DRIFT")
        try:
            relative = raw_path.resolve().relative_to(root.resolve()).as_posix()
        except ValueError:
            continue
        if relative in public_pins:
            if item["sha256"].lower() != public_pins[relative]:
                raise SchemaPackageError("FRAMEWORK_FROZEN_PUBLIC_PIN_MISMATCH")
            public_seen[relative] = item["sha256"].lower()
    if public_seen != public_pins:
        raise SchemaPackageError("FRAMEWORK_PUBLIC_PIN_NOT_IN_RECEIPT")

    binary_pins = receipt.get("binaryPins")
    if not isinstance(binary_pins, list) or len(binary_pins) != len(EXPECTED_BINARIES):
        raise SchemaPackageError("FRAMEWORK_BINARY_PIN_SET_INVALID")
    pinned: dict[str, dict[str, Any]] = {}
    for item in binary_pins:
        if (not isinstance(item, dict) or set(item) != {"fileName", "sha256"}
                or not isinstance(item["fileName"], str) or Path(item["fileName"]).name != item["fileName"]
                or not isinstance(item["sha256"], str) or not HEX_SHA256.fullmatch(item["sha256"].lower())):
            raise SchemaPackageError("FRAMEWORK_BINARY_PIN_INVALID")
        name = item["fileName"]
        if name in pinned or name not in EXPECTED_BINARIES:
            raise SchemaPackageError("FRAMEWORK_BINARY_PIN_SET_INVALID")
        path = framework_root / name
        try:
            actual = sha256(path.read_bytes())
        except OSError as exc:
            raise SchemaPackageError("FRAMEWORK_BINARY_OUTPUT_MISSING") from exc
        if actual != item["sha256"].lower():
            raise SchemaPackageError("FRAMEWORK_BINARY_OUTPUT_DRIFT")
        pinned[name] = {"sha256": actual, "size": path.stat().st_size}
    if set(pinned) != EXPECTED_BINARIES:
        raise SchemaPackageError("FRAMEWORK_BINARY_PIN_SET_INVALID")
    return pinned


def validate_package_bytes(data: bytes, expected_sha256: str) -> tuple[dict[str, Any], dict[str, bytes]]:
    """Validiert das Paket aus genau einem bereits gelesenen Archivpuffer."""
    previous, outputs = constructor_gate._validate_archive(data, expected_sha256)
    from io import BytesIO

    try:
        with zipfile.ZipFile(BytesIO(data), "r") as archive:
            manifest = json.loads(archive.read(MANIFEST))
            files = manifest["files"]
            schema_entry = files.get("Binaries/Toolbelt.JsonSchema.dll")
            if not isinstance(schema_entry, dict) or set(schema_entry) != {"sha256", "size"}:
                raise SchemaPackageError("PACKAGE_SCHEMA_MANIFEST_INVALID")
            schema = archive.read(PREFIX + "Binaries/Toolbelt.JsonSchema.dll")
            core = outputs[CORE_DLL]
            if (schema_entry["sha256"] != sha256(schema) or schema_entry["size"] != len(schema)):
                raise SchemaPackageError("PACKAGE_SCHEMA_CONTENT_MISMATCH")
            schema_pin = {"sha256": sha256(schema), "size": len(schema)}
            return {
                "archive_sha256": previous["archive_sha256"],
                "schema": schema_pin,
                "core": previous["files"][CORE_DLL],
                "constructor": previous["files"][CONSTRUCTOR_DLL],
            }, {SCHEMA_DLL: schema, CORE_DLL: core, CONSTRUCTOR_DLL: outputs[CONSTRUCTOR_DLL]}
    except (zipfile.BadZipFile, KeyError, json.JSONDecodeError, AttributeError, TypeError) as exc:
        raise SchemaPackageError("PACKAGE_SCHEMA_ARCHIVE_INVALID") from exc


def inspect_package(root: Path, expected_sha256: str) -> tuple[dict[str, Any], dict[str, bytes]]:
    root = root.resolve()
    package = root / PACKAGE_REL
    sidecar = Path(str(package) + ".sha256")
    expected_sidecar = f"{expected_sha256}  {PACKAGE_NAME}\n".encode("ascii")
    try:
        if sidecar.read_bytes() != expected_sidecar:
            raise SchemaPackageError("PACKAGE_SIDECAR_MISMATCH")
        data = package.read_bytes()
    except OSError as exc:
        raise SchemaPackageError("PACKAGE_INPUT_MISSING") from exc
    return validate_package_bytes(data, expected_sha256)


def validate_source_package_match(
    framework_root: Path, package_binaries: dict[str, bytes], framework_pins: dict[str, dict[str, Any]],
) -> None:
    for dll_name in (SCHEMA_DLL, CORE_DLL, CONSTRUCTOR_DLL):
        if dll_name not in package_binaries or dll_name not in framework_pins:
            raise SchemaPackageError("PACKAGE_SOURCE_DLL_PIN_MISSING")
        output = framework_root / dll_name
        if output.read_bytes() != package_binaries[dll_name]:
            raise SchemaPackageError("PACKAGE_SOURCE_DLL_MISMATCH")


def _inside_private_root(root: Path, path: Path) -> Path:
    root = root.resolve()
    private = root / ".runtime"
    lexical_private = Path(os.path.abspath(private))
    candidate = Path(path)
    if not candidate.is_absolute():
        candidate = root / candidate
    candidate = Path(os.path.abspath(candidate))
    try:
        candidate.relative_to(lexical_private)
    except ValueError as exc:
        raise SchemaPackageError("PRIVATE_RUNTIME_SCOPE_INVALID") from exc
    if candidate == lexical_private or private.is_symlink():
        raise SchemaPackageError("PRIVATE_RUNTIME_SCOPE_INVALID")
    parent = candidate
    while parent != lexical_private:
        if parent.is_symlink():
            raise SchemaPackageError("PRIVATE_RUNTIME_SCOPE_INVALID")
        parent = parent.parent
    resolved = candidate.resolve()
    try:
        resolved.relative_to(private.resolve())
    except ValueError as exc:
        raise SchemaPackageError("PRIVATE_RUNTIME_SCOPE_INVALID") from exc
    return resolved


def _collect(root: Path, framework_root: Path) -> tuple[dict[str, Any], dict[str, bytes]]:
    root = root.resolve()
    framework_root = _inside_private_root(root, framework_root)
    report, report_bytes = validate_predecessor(root)
    public_pins = validate_source_pins(root, report)
    try:
        receipt_bytes = (framework_root / "Receipt.private.json").read_bytes()
        frozen_bytes = (framework_root / "FrozenInputs.private.json").read_bytes()
        schema_il_bytes = (framework_root / f"{SCHEMA_DLL.removesuffix('.dll')}.IL.private.json").read_bytes()
        receipt = json.loads(receipt_bytes)
        frozen = json.loads(frozen_bytes)
        schema_il = json.loads(schema_il_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise SchemaPackageError("FRAMEWORK_RECEIPT_MISSING_OR_INVALID") from exc
    framework_pins = validate_framework_receipt(
        root, framework_root, public_pins, receipt, frozen, schema_il,
    )
    package_record, package_binaries = inspect_package(root, report["package"]["sha256"])
    validate_source_package_match(framework_root, package_binaries, framework_pins)
    for name in (SCHEMA_DLL, CORE_DLL, CONSTRUCTOR_DLL):
        package_record[name] = dict(framework_pins[name])
    record = {
        "schema_version": 1,
        "status": "PREPARED",
        "scope": "JSON_SCHEMA_RELEASE_PACKAGE_DIRECT_IL",
        "predecessor_commit": PREDECESSOR_COMMIT,
        "predecessor_report_sha256": sha256(report_bytes),
        "package_sha256": package_record["archive_sha256"],
        "schema_sha256": package_record["schema"]["sha256"],
        "schema_size": package_record["schema"]["size"],
        "core_sha256": package_record["core"]["sha256"],
        "core_size": package_record["core"]["size"],
        "constructor_sha256": package_record["constructor"]["sha256"],
        "constructor_size": package_record["constructor"]["size"],
        "source_framework_status": receipt["status"],
        "source_framework_phases": len(receipt["phases"]),
        "source_framework_post_pins": receipt["postPins"],
        "source_framework_input_count": len(frozen),
        "public_source_input_count": len(public_pins),
        "source_framework_binary_count": len(framework_pins),
        "source_receipt_sha256": sha256(receipt_bytes),
        "source_frozen_inputs_sha256": sha256(frozen_bytes),
        "source_schema_il_evidence_sha256": sha256(schema_il_bytes),
        "source_framework_output_sha256": {name: value["sha256"] for name, value in framework_pins.items()},
        "source_schema_il_status": schema_il["status"],
        "source_schema_il_direct_package": False,
    }
    return record, package_binaries


def prepare(root: Path, framework_root: Path, output: Path) -> dict[str, Any]:
    root = root.resolve()
    output = _inside_private_root(root, output)
    (root / ".runtime").mkdir(exist_ok=True)
    if output.exists():
        raise SchemaPackageError("PRIVATE_OUTPUT_ALREADY_EXISTS")
    output.mkdir(parents=True, exist_ok=False)
    record, binaries = _collect(root, framework_root)
    package_dir = output / "package"
    package_dir.mkdir()
    for name in (SCHEMA_DLL, CORE_DLL):
        (package_dir / name).write_bytes(binaries[name])
    (output / "Binding.private.json").write_text(
        json.dumps(record, sort_keys=True, separators=(",", ":")), encoding="utf-8",
    )
    return record


def postvalidate(root: Path, framework_root: Path, output: Path) -> dict[str, Any]:
    root = root.resolve()
    output = _inside_private_root(root, output)
    framework_root = _inside_private_root(root, framework_root)
    try:
        prepared = json.loads((output / "Binding.private.json").read_bytes())
    except (OSError, json.JSONDecodeError) as exc:
        raise SchemaPackageError("PRIVATE_BINDING_RECEIPT_INVALID") from exc
    current, binaries = _collect(root, framework_root)
    if current != prepared:
        raise SchemaPackageError("PACKAGE_BINDING_CHANGED_DURING_IL")
    for name in (SCHEMA_DLL, CORE_DLL):
        path = output / "package" / name
        try:
            payload = path.read_bytes()
        except OSError as exc:
            raise SchemaPackageError("PACKAGE_EXTRACTED_BINARY_MISSING") from exc
        if payload != binaries[name]:
            raise SchemaPackageError("PACKAGE_EXTRACTED_BINARY_DRIFT")
    il_path = output / f"{SCHEMA_DLL.removesuffix('.dll')}.IL.private.json"
    try:
        il = json.loads(il_path.read_bytes())
    except (OSError, json.JSONDecodeError) as exc:
        raise SchemaPackageError("PACKAGE_SCHEMA_IL_EVIDENCE_INVALID") from exc
    if (not isinstance(il, dict) or il.get("status") != "PASS"
            or il.get("scope") != "own product and pinned shared Core calls only"
            or il.get("unknown") != []):
        raise SchemaPackageError("PACKAGE_SCHEMA_IL_EVIDENCE_INVALID")
    result = dict(current)
    result["status"] = "PASS"
    result["package_schema_il_status"] = il["status"]
    result["package_schema_il_direct_package"] = True
    result["package_schema_il_unknown_bindings"] = 0
    (output / "PostBinding.private.json").write_text(
        json.dumps(result, sort_keys=True, separators=(",", ":")), encoding="utf-8",
    )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--framework-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--postvalidate", action="store_true")
    args = parser.parse_args()
    try:
        record = (postvalidate(args.root, args.framework_root, args.output) if args.postvalidate
                  else prepare(args.root, args.framework_root, args.output))
    except SchemaPackageError as exc:
        print(str(exc))
        return 2
    print(json.dumps(record, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

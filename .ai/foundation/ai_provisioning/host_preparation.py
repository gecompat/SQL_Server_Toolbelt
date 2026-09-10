#!/usr/bin/env python3
"""Bounded, optional host discovery, provisioning, verification, and cost-evidence refresh."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Callable, Iterator


CONTRACT = "foundation-ai-host-preparation/v1"
WORK_CONTRACT = "foundation-ai-work/v1"
APPROVAL_CONTRACT = "foundation-provision-approval/v1"
EVIDENCE_CONTRACT = "foundation-resource-cost-evidence/v1"
SHA256_PREFIX = "sha256:"
MIN_REFRESH_SECONDS = 86400


class PreparationError(RuntimeError):
    def __init__(self, code: str, message: str, *, error_class: str = "CONTRACT") -> None:
        super().__init__(message)
        self.code = code
        self.error_class = error_class


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_datetime(value: Any, field: str) -> datetime:
    if not isinstance(value, str):
        raise PreparationError("INVALID_TIMESTAMP", f"{field} must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise PreparationError("INVALID_TIMESTAMP", f"{field} must be an ISO-8601 timestamp") from exc
    if parsed.tzinfo is None:
        raise PreparationError("INVALID_TIMESTAMP", f"{field} must include a timezone")
    return parsed.astimezone(timezone.utc)


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def digest(value: Any) -> str:
    return SHA256_PREFIX + hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()


def digest_bytes(value: bytes) -> str:
    return SHA256_PREFIX + hashlib.sha256(value).hexdigest()


def is_sha256(value: Any) -> bool:
    if not isinstance(value, str) or len(value) != 71 or not value.startswith(SHA256_PREFIX):
        return False
    try:
        int(value[7:], 16)
    except ValueError:
        return False
    return value[7:] == value[7:].lower()


def validated_source_uri(value: Any, field: str, *, allow_file: bool = True) -> urllib.parse.ParseResult:
    if not isinstance(value, str) or not value:
        raise PreparationError("INVALID_SOURCE_URI", f"{field} must be a non-empty URI")
    parsed = urllib.parse.urlparse(value)
    schemes = {"https", "file"} if allow_file else {"https"}
    if parsed.scheme not in schemes or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise PreparationError("INVALID_SOURCE_URI", f"{field} must be a credential-free approved URI")
    if parsed.scheme == "https":
        try:
            valid_https = bool(parsed.hostname) and parsed.port in {None, 443}
        except ValueError as exc:
            raise PreparationError("INVALID_SOURCE_URI", f"{field} contains an invalid port") from exc
        if not valid_https:
            raise PreparationError("INVALID_SOURCE_URI", f"{field} must use HTTPS on the default port")
    if parsed.scheme == "file":
        source_path = Path(urllib.request.url2pathname(parsed.path))
        if parsed.netloc not in {"", "localhost"} or not source_path.is_absolute():
            raise PreparationError("INVALID_SOURCE_URI", f"{field} file URI must identify an absolute local path")
    return parsed


def number(value: Any, field: str) -> Decimal:
    if isinstance(value, bool) or not isinstance(value, (int, float, Decimal)):
        raise PreparationError("INVALID_NUMBER", f"{field} must be numeric")
    try:
        result = Decimal(str(value))
    except (InvalidOperation, ValueError) as exc:
        raise PreparationError("INVALID_NUMBER", f"{field} must be numeric") from exc
    if not result.is_finite() or result < 0:
        raise PreparationError("INVALID_NUMBER", f"{field} must be finite and non-negative")
    return result


def exact_object(raw: Any, required: set[str], allowed: set[str], field: str) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise PreparationError("INVALID_INPUT", f"{field} must be an object")
    missing = required - set(raw)
    unknown = set(raw) - allowed
    if missing or unknown:
        raise PreparationError("INVALID_INPUT", f"{field} fields are invalid")
    return raw


def strings(raw: Any, field: str, *, nonempty: bool = False) -> list[str]:
    if not isinstance(raw, list) or (nonempty and not raw):
        raise PreparationError("INVALID_INPUT", f"{field} must be an array")
    if any(not isinstance(item, str) or not item for item in raw) or len(set(raw)) != len(raw):
        raise PreparationError("INVALID_INPUT", f"{field} must contain unique non-empty strings")
    return list(raw)


def find_git_root(path: Path) -> Path | None:
    resolved = path.resolve()
    for candidate in (resolved, *resolved.parents):
        if (candidate / ".git").exists():
            return candidate
    return None


def external_path(path: Path, field: str) -> Path:
    resolved = path.expanduser().resolve()
    repository = find_git_root(resolved)
    if repository is not None:
        raise PreparationError(
            "RUNTIME_STATE_IN_VERSION_CONTROL",
            f"{field} must remain outside version control; choose a location outside {repository}",
            error_class="PERMISSION",
        )
    return resolved


def default_state_dir() -> Path:
    configured = os.environ.get("AI_HOST_PREPARATION_HOME")
    if configured:
        return external_path(Path(configured), "host-preparation state")
    if os.name == "nt" and os.environ.get("LOCALAPPDATA"):
        return external_path(Path(os.environ["LOCALAPPDATA"]) / "ai-host-preparation", "host-preparation state")
    if sys.platform == "darwin":
        return external_path(Path.home() / "Library" / "Application Support" / "ai-host-preparation", "host-preparation state")
    return external_path(Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "ai-host-preparation", "host-preparation state")


def atomic_write(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(value, handle, indent=2, sort_keys=True, ensure_ascii=False)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        try:
            Path(temporary).unlink()
        except FileNotFoundError:
            pass


@contextlib.contextmanager
def file_lock(path: Path, timeout_seconds: float = 5.0) -> Iterator[None]:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open("a+b")
    if handle.seek(0, os.SEEK_END) == 0:
        handle.write(b"0")
        handle.flush()
    deadline = time.monotonic() + timeout_seconds
    while True:
        try:
            handle.seek(0)
            if os.name == "nt":
                import msvcrt

                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl

                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except OSError:
            if time.monotonic() >= deadline:
                handle.close()
                raise PreparationError("STATE_LOCK_TIMEOUT", "timed out waiting for runtime-state lock")
            time.sleep(0.05)
    try:
        yield
    finally:
        handle.seek(0)
        if os.name == "nt":
            import msvcrt

            msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            import fcntl

            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        handle.close()


def file_digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            hasher.update(chunk)
    return SHA256_PREFIX + hasher.hexdigest()


def default_runtime_definitions() -> list[dict[str, Any]]:
    candidates: dict[str, list[str]] = {"ollama": [], "lm-studio": []}
    environment_allowlist: list[str]
    if os.name == "nt":
        local = Path(os.environ.get("LOCALAPPDATA", "C:/nonexistent"))
        user = Path(os.environ.get("USERPROFILE", "C:/nonexistent"))
        candidates["ollama"] = [str(local / "Programs" / "Ollama" / "ollama.exe")]
        candidates["lm-studio"] = [
            str(user / ".lmstudio" / "bin" / "lms.exe"),
            str(local / "Programs" / "LM Studio" / "lms.exe"),
        ]
        environment_allowlist = ["SystemRoot", "WINDIR", "COMSPEC", "PATHEXT", "PATH", "USERPROFILE", "LOCALAPPDATA", "APPDATA", "TEMP", "TMP"]
    elif sys.platform == "darwin":
        candidates["ollama"] = ["/Applications/Ollama.app/Contents/Resources/ollama"]
        candidates["lm-studio"] = [str(Path.home() / ".lmstudio" / "bin" / "lms")]
        environment_allowlist = ["HOME", "PATH", "TMPDIR", "LANG", "LC_ALL"]
    else:
        candidates["ollama"] = ["/usr/local/bin/ollama", str(Path.home() / ".local" / "bin" / "ollama")]
        candidates["lm-studio"] = [str(Path.home() / ".lmstudio" / "bin" / "lms")]
        environment_allowlist = ["HOME", "PATH", "TMPDIR", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "LANG", "LC_ALL"]
    return [
        {
            "runtime_id": "ollama",
            "executable_names": ["ollama"],
            "search_paths": candidates["ollama"],
            "version_argv": ["{executable}", "--version"],
            "inventory_argv": ["{executable}", "list"],
            "inventory_format": "OLLAMA_TABLE",
            "environment_allowlist": environment_allowlist,
            "timeout_seconds": 15,
            "health_ttl_seconds": 300,
            "execution_boundary": "HOST",
        },
        {
            "runtime_id": "lm-studio",
            "executable_names": ["lms"],
            "search_paths": candidates["lm-studio"],
            "version_argv": ["{executable}", "--version"],
            "inventory_argv": ["{executable}", "ls", "--json"],
            "inventory_format": "JSON",
            "environment_allowlist": environment_allowlist,
            "timeout_seconds": 15,
            "health_ttl_seconds": 300,
            "execution_boundary": "HOST",
        },
    ]


def validate_runtime_definitions(raw: Any) -> list[dict[str, Any]]:
    values = raw.get("runtimes") if isinstance(raw, dict) and set(raw) == {"runtimes"} else raw
    if not isinstance(values, list) or not values:
        raise PreparationError("INVALID_RUNTIME_DEFINITIONS", "runtime definitions must be a non-empty array or runtimes object")
    result: list[dict[str, Any]] = []
    seen: set[str] = set()
    required = {
        "runtime_id", "executable_names", "search_paths", "version_argv", "inventory_argv",
        "inventory_format", "environment_allowlist", "timeout_seconds", "health_ttl_seconds", "execution_boundary",
    }
    for raw_item in values:
        item = exact_object(raw_item, required, required, "runtime definition")
        runtime_id = item["runtime_id"]
        if not isinstance(runtime_id, str) or not runtime_id or runtime_id in seen:
            raise PreparationError("INVALID_RUNTIME_DEFINITIONS", "runtime identifiers must be unique non-empty strings")
        names = strings(item["executable_names"], "executable_names", nonempty=True)
        paths = strings(item["search_paths"], "search_paths")
        for path in paths:
            if not Path(path).expanduser().is_absolute():
                raise PreparationError("INVALID_RUNTIME_DEFINITIONS", "runtime search paths must be absolute")
        version_argv = strings(item["version_argv"], "version_argv", nonempty=True)
        inventory_argv = strings(item["inventory_argv"], "inventory_argv", nonempty=True)
        if item["inventory_format"] not in {"JSON", "OLLAMA_TABLE", "NONE"}:
            raise PreparationError("INVALID_RUNTIME_DEFINITIONS", "inventory format is invalid")
        boundary = item["execution_boundary"]
        if boundary not in {"PROCESS", "HOST", "LOCAL_NETWORK", "REMOTE", "UNKNOWN"}:
            raise PreparationError("INVALID_RUNTIME_DEFINITIONS", "execution boundary is invalid")
        timeout = number(item["timeout_seconds"], "timeout_seconds")
        if timeout <= 0:
            raise PreparationError("INVALID_RUNTIME_DEFINITIONS", "timeout must be positive")
        health_ttl = number(item["health_ttl_seconds"], "health_ttl_seconds")
        if health_ttl <= 0 or health_ttl > 86400 or health_ttl != int(health_ttl):
            raise PreparationError("INVALID_RUNTIME_DEFINITIONS", "health TTL must be an integer from 1 through 86400")
        result.append({
            **item,
            "executable_names": names,
            "search_paths": paths,
            "version_argv": version_argv,
            "inventory_argv": inventory_argv,
            "environment_allowlist": strings(item["environment_allowlist"], "environment_allowlist"),
            "timeout_seconds": float(timeout),
            "health_ttl_seconds": int(health_ttl),
        })
        seen.add(runtime_id)
    return result


def locate_executable(definition: dict[str, Any]) -> tuple[Path | None, str]:
    for name in definition["executable_names"]:
        located = shutil.which(name)
        if located and Path(located).is_file():
            return Path(located).resolve(), "PATH"
    for item in definition["search_paths"]:
        candidate = Path(item).expanduser().resolve()
        if candidate.is_file():
            return candidate, "SEARCH_PATH"
        if candidate.is_dir():
            for name in definition["executable_names"]:
                child = candidate / name
                if child.is_file():
                    return child.resolve(), "SEARCH_PATH"
    return None, "NOT_FOUND"


def expand_argv(template: list[str], executable: Path, replacements: dict[str, str] | None = None) -> list[str]:
    values = {"{executable}": str(executable), **(replacements or {})}
    argv: list[str] = []
    for item in template:
        if "{" in item and item not in values:
            raise PreparationError("INVALID_ARGV_TEMPLATE", "placeholders must occupy a complete supported argument")
        argv.append(values.get(item, item))
    if not Path(argv[0]).is_absolute():
        raise PreparationError("EXECUTABLE_NOT_ABSOLUTE", "resolved executable must be absolute")
    return argv


def run_bounded(argv: list[str], environment_names: list[str], timeout_seconds: float) -> subprocess.CompletedProcess[bytes]:
    environment = {name: os.environ[name] for name in environment_names if name in os.environ}
    try:
        return subprocess.run(
            argv,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            timeout=timeout_seconds,
            shell=False,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise PreparationError("COMMAND_TIMEOUT", "runtime command timed out", error_class="TIMEOUT") from exc
    except OSError as exc:
        raise PreparationError("COMMAND_UNAVAILABLE", "runtime command is unavailable", error_class="AVAILABILITY") from exc


def redact_environment_values(value: str, environment_names: list[str]) -> str:
    redacted = value
    secrets = sorted(
        {os.environ[name] for name in environment_names if name in os.environ and len(os.environ[name]) >= 4},
        key=len,
        reverse=True,
    )
    for secret in secrets:
        redacted = redacted.replace(secret, "[REDACTED]")
    return redacted


def doctor(definitions_raw: Any, *, at: datetime | None = None) -> dict[str, Any]:
    definitions = validate_runtime_definitions(definitions_raw)
    observed = (at or utc_now()).astimezone(timezone.utc)
    runtimes: list[dict[str, Any]] = []
    for definition in definitions:
        executable, discovery = locate_executable(definition)
        record = {
            "runtime_id": definition["runtime_id"],
            "state": "UNAVAILABLE",
            "execution_boundary": definition["execution_boundary"],
            "discovery": discovery,
            "executable_path": None,
            "executable_sha256": None,
            "version": None,
            "reason_code": "EXECUTABLE_NOT_FOUND",
        }
        if executable is not None:
            record.update({
                "state": "DEGRADED",
                "executable_path": str(executable),
                "executable_sha256": file_digest(executable),
                "reason_code": "VERSION_PROBE_FAILED",
            })
            try:
                probe = run_bounded(
                    expand_argv(definition["version_argv"], executable),
                    definition["environment_allowlist"],
                    definition["timeout_seconds"],
                )
                if probe.returncode == 0:
                    version = redact_environment_values(
                        probe.stdout.decode("utf-8", errors="replace"),
                        definition["environment_allowlist"],
                    ).strip().replace("\r", " ").replace("\n", " ")[:512]
                    record.update({"state": "HEALTHY", "version": version or None, "reason_code": "VERSION_PROBE_SUCCEEDED"})
                else:
                    record["reason_code"] = "VERSION_PROBE_NONZERO"
            except PreparationError as exc:
                record["reason_code"] = exc.code
        runtimes.append(record)
    states = {item["state"] for item in runtimes}
    status = "COMPLETE" if states <= {"HEALTHY"} else "UNAVAILABLE" if states == {"UNAVAILABLE"} else "PARTIAL"
    return {
        "schema_version": 1,
        "contract": CONTRACT,
        "operation": "doctor",
        "observed_at": isoformat(observed),
        "expires_at": isoformat(observed + timedelta(seconds=min(item["health_ttl_seconds"] for item in definitions))),
        "status": status,
        "runtimes": runtimes,
    }


def parse_inventory(body: bytes, format_name: str) -> list[dict[str, Any]]:
    text = body.decode("utf-8", errors="strict")
    if format_name == "NONE":
        return []
    if format_name == "JSON":
        value = json.loads(text)
        values = value.get("artifacts", value.get("models", [])) if isinstance(value, dict) else value
        if not isinstance(values, list):
            raise ValueError("inventory JSON must contain an array")
        result = []
        for item in values:
            if isinstance(item, str) and item:
                result.append({"artifact_id": item})
            elif isinstance(item, dict):
                artifact_id = item.get("artifact_id", item.get("model", item.get("modelKey", item.get("id", item.get("name")))))
                if isinstance(artifact_id, str) and artifact_id:
                    result.append({"artifact_id": artifact_id})
        return result
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if len(lines) < 2:
        return []
    return [{"artifact_id": line.split()[0]} for line in lines[1:] if line.split()]


def inventory(definitions_raw: Any, doctor_raw: Any, *, at: datetime | None = None) -> dict[str, Any]:
    definitions = {item["runtime_id"]: item for item in validate_runtime_definitions(definitions_raw)}
    report_fields = {"schema_version", "contract", "operation", "observed_at", "expires_at", "status", "runtimes"}
    report = exact_object(doctor_raw, report_fields, report_fields, "doctor report")
    if report["contract"] != CONTRACT or report["operation"] != "doctor" or not isinstance(report["runtimes"], list):
        raise PreparationError("INVALID_DOCTOR_REPORT", "doctor report contract is invalid")
    observed = (at or utc_now()).astimezone(timezone.utc)
    if parse_datetime(report["expires_at"], "doctor.expires_at") <= observed:
        raise PreparationError("DOCTOR_REPORT_EXPIRED", "doctor report must be refreshed", error_class="AVAILABILITY")
    runtimes: list[dict[str, Any]] = []
    for runtime in report["runtimes"]:
        if not isinstance(runtime, dict):
            runtimes.append({"runtime_id": "unknown", "state": "UNAVAILABLE", "artifacts": [], "reason_code": "DOCTOR_RECORD_INVALID"})
            continue
        runtime_id = runtime.get("runtime_id")
        definition = definitions.get(runtime_id)
        path_value = runtime.get("executable_path") if isinstance(runtime, dict) else None
        entry = {"runtime_id": runtime_id or "unknown", "state": "UNAVAILABLE", "artifacts": [], "reason_code": "RUNTIME_UNAVAILABLE"}
        if definition is not None and runtime.get("state") in {"HEALTHY", "DEGRADED"} and isinstance(path_value, str):
            executable = Path(path_value).resolve()
            if executable.is_file() and file_digest(executable) == runtime.get("executable_sha256"):
                try:
                    process = run_bounded(
                        expand_argv(definition["inventory_argv"], executable),
                        definition["environment_allowlist"],
                        definition["timeout_seconds"],
                    )
                    if process.returncode == 0:
                        artifacts = parse_inventory(process.stdout, definition["inventory_format"])
                        for artifact in artifacts:
                            artifact["artifact_id"] = redact_environment_values(artifact["artifact_id"], definition["environment_allowlist"])
                            cloud_tag = definition["runtime_id"] == "ollama" and (
                                artifact["artifact_id"].endswith(":cloud") or artifact["artifact_id"].endswith("-cloud")
                            )
                            artifact["execution_boundary"] = "REMOTE" if cloud_tag else "UNKNOWN"
                            artifact["boundary_reason"] = "CLOUD_TAG_REQUIRES_REMOTE" if cloud_tag else "MODEL_EXECUTION_NOT_ATTESTED"
                        entry.update({"state": "HEALTHY", "artifacts": artifacts, "reason_code": "INVENTORY_SUCCEEDED"})
                    else:
                        entry["reason_code"] = "INVENTORY_NONZERO"
                except (PreparationError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
                    entry["reason_code"] = exc.code if isinstance(exc, PreparationError) else "INVENTORY_INVALID"
            else:
                entry["reason_code"] = "EXECUTABLE_EVIDENCE_CHANGED"
        runtimes.append(entry)
    states = {item["state"] for item in runtimes}
    status = "COMPLETE" if states <= {"HEALTHY"} else "UNAVAILABLE" if states == {"UNAVAILABLE"} else "PARTIAL"
    return {
        "schema_version": 1,
        "contract": CONTRACT,
        "operation": "inventory",
        "observed_at": isoformat(observed),
        "expires_at": isoformat(observed + timedelta(seconds=min(item["health_ttl_seconds"] for item in definitions.values()))),
        "status": status,
        "runtimes": runtimes,
    }


def validate_provision_request(raw: Any) -> dict[str, Any]:
    fields = {"schema_version", "contract", "request_id", "artifact_id", "target_runtime", "target_path", "valid_for_seconds", "limits", "authorization"}
    value = exact_object(raw, fields, fields, "provision request")
    if value["schema_version"] != 1 or value["contract"] != CONTRACT:
        raise PreparationError("INVALID_PROVISION_REQUEST", "provision request contract is invalid")
    for field in ("request_id", "artifact_id", "target_runtime", "target_path"):
        if not isinstance(value[field], str) or not value[field]:
            raise PreparationError("INVALID_PROVISION_REQUEST", f"{field} must be a non-empty string")
    target = external_path(Path(value["target_path"]), "provision target")
    valid_for = number(value["valid_for_seconds"], "valid_for_seconds")
    if valid_for <= 0 or valid_for > 86400 or valid_for != int(valid_for):
        raise PreparationError("INVALID_PROVISION_REQUEST", "valid_for_seconds must be an integer from 1 through 86400")
    limits = exact_object(value["limits"], {"max_download_mb", "max_disk_mb", "max_memory_mb", "max_cost_usd"}, {"max_download_mb", "max_disk_mb", "max_memory_mb", "max_cost_usd"}, "provision limits")
    normalized_limits = {name: float(number(item, f"limits.{name}")) for name, item in limits.items()}
    authorization = exact_object(value["authorization"], {"network_authorized", "allowed_network_destinations", "environment_allowlist"}, {"network_authorized", "allowed_network_destinations", "environment_allowlist"}, "provision authorization")
    if not isinstance(authorization["network_authorized"], bool):
        raise PreparationError("INVALID_PROVISION_REQUEST", "network_authorized must be boolean")
    return {
        **value,
        "target_path": str(target),
        "valid_for_seconds": int(valid_for),
        "limits": normalized_limits,
        "authorization": {
            "network_authorized": authorization["network_authorized"],
            "allowed_network_destinations": strings(authorization["allowed_network_destinations"], "allowed_network_destinations"),
            "environment_allowlist": strings(authorization["environment_allowlist"], "environment_allowlist"),
        },
    }


def validate_recipes(raw: Any) -> list[dict[str, Any]]:
    values = raw.get("recipes") if isinstance(raw, dict) and set(raw) == {"recipes"} else raw
    if not isinstance(values, list):
        raise PreparationError("INVALID_RECIPES", "recipes must be an array or recipes object")
    required = {
        "recipe_id", "artifact_id", "target_runtime", "source", "source_sha256", "download_mb",
        "expected_disk_mb", "expected_memory_mb", "license_notice", "license_source", "network_destination",
        "max_cost_usd", "install_argv", "verify_argv", "environment_names", "idempotent_install",
        "install_network_access",
    }
    result = []
    seen = set()
    for raw_item in values:
        item = exact_object(raw_item, required, required, "provision recipe")
        for field in ("recipe_id", "artifact_id", "target_runtime", "source", "license_notice", "license_source", "network_destination"):
            if not isinstance(item[field], str) or not item[field]:
                raise PreparationError("INVALID_RECIPES", f"recipe {field} must be a non-empty string")
        if item["recipe_id"] in seen or not is_sha256(item["source_sha256"]):
            raise PreparationError("INVALID_RECIPES", "recipe identifiers and source hashes are invalid")
        parsed = validated_source_uri(item["source"], "recipe source")
        validated_source_uri(item["license_source"], "recipe license source")
        if parsed.scheme == "https" and parsed.hostname != item["network_destination"]:
            raise PreparationError("INVALID_RECIPES", "HTTPS source host must equal network_destination")
        if parsed.scheme == "file" and item["network_destination"] != "NONE":
            raise PreparationError("INVALID_RECIPES", "file sources must use network_destination NONE")
        if not isinstance(item["idempotent_install"], bool):
            raise PreparationError("INVALID_RECIPES", "idempotent_install must be boolean")
        if item["install_network_access"] != "DENY":
            raise PreparationError("INVALID_RECIPES", "reference install commands must declare network access DENY")
        install = strings(item["install_argv"], "install_argv")
        verify = strings(item["verify_argv"], "verify_argv")
        for argv in (install, verify):
            if argv and not Path(argv[0]).is_absolute():
                raise PreparationError("INVALID_RECIPES", "install and verify executables must be absolute")
        result.append({
            **item,
            "download_mb": float(number(item["download_mb"], "download_mb")),
            "expected_disk_mb": float(number(item["expected_disk_mb"], "expected_disk_mb")),
            "expected_memory_mb": float(number(item["expected_memory_mb"], "expected_memory_mb")),
            "max_cost_usd": float(number(item["max_cost_usd"], "max_cost_usd")),
            "install_argv": install,
            "verify_argv": verify,
            "environment_names": strings(item["environment_names"], "environment_names"),
        })
        seen.add(item["recipe_id"])
    return result


def plan_provision(request_raw: Any, recipes_raw: Any, *, at: datetime | None = None) -> dict[str, Any]:
    request = validate_provision_request(request_raw)
    matches = [
        item for item in validate_recipes(recipes_raw)
        if item["artifact_id"] == request["artifact_id"] and item["target_runtime"] == request["target_runtime"]
    ]
    if len(matches) != 1:
        raise PreparationError("PROVISION_RECIPE_UNAVAILABLE", "exactly one matching provision recipe is required", error_class="AVAILABILITY")
    recipe = matches[0]
    limits = request["limits"]
    comparisons = {
        "download_mb": "max_download_mb",
        "expected_disk_mb": "max_disk_mb",
        "expected_memory_mb": "max_memory_mb",
        "max_cost_usd": "max_cost_usd",
    }
    if any(Decimal(str(recipe[value])) > Decimal(str(limits[limit])) for value, limit in comparisons.items()):
        raise PreparationError("PROVISION_LIMIT_EXCEEDED", "recipe exceeds a hard provision limit", error_class="BUDGET")
    parsed = urllib.parse.urlparse(recipe["source"])
    if parsed.scheme == "https":
        auth = request["authorization"]
        if not auth["network_authorized"] or recipe["network_destination"] not in auth["allowed_network_destinations"]:
            raise PreparationError("PROVISION_NETWORK_NOT_AUTHORIZED", "recipe network destination is not authorized", error_class="PERMISSION")
    if not set(recipe["environment_names"]) <= set(request["authorization"]["environment_allowlist"]):
        raise PreparationError("PROVISION_ENVIRONMENT_NOT_AUTHORIZED", "recipe environment names exceed the request allowlist", error_class="PERMISSION")
    created = (at or utc_now()).astimezone(timezone.utc)
    action = {
        "source": recipe["source"],
        "artifact_id": recipe["artifact_id"],
        "license_notice": recipe["license_notice"],
        "download_mb": recipe["download_mb"],
        "expected_disk_mb": recipe["expected_disk_mb"],
        "expected_memory_mb": recipe["expected_memory_mb"],
        "target_runtime": recipe["target_runtime"],
        "network_destination": recipe["network_destination"],
        "max_cost_usd": recipe["max_cost_usd"],
        "verification_sha256": recipe["source_sha256"],
        "recipe_id": recipe["recipe_id"],
        "target_path": request["target_path"],
        "license_source": recipe["license_source"],
        "install_argv": recipe["install_argv"],
        "verify_argv": recipe["verify_argv"],
        "environment_names": recipe["environment_names"],
        "idempotent_install": recipe["idempotent_install"],
        "install_network_access": recipe["install_network_access"],
    }
    material = {
        "request": request,
        "created_at": isoformat(created),
        "action": action,
    }
    plan = {
        "schema_version": 1,
        "contract": WORK_CONTRACT,
        "provision_id": digest(material),
        "created_at": isoformat(created),
        "expires_at": isoformat(created + timedelta(seconds=request["valid_for_seconds"])),
        "actions": [action],
        "rollback": ["remove only the staged or target artifact created by this plan after verifying its exact digest"],
        "recovery": ["rerun verify; resume only an idempotent or not-yet-started action; otherwise reconcile manually"],
    }
    return {**plan, "plan_hash": digest(plan)}


def validate_plan(raw: Any, *, at: datetime | None = None, require_unexpired: bool = True) -> dict[str, Any]:
    fields = {"schema_version", "contract", "provision_id", "created_at", "expires_at", "actions", "rollback", "recovery", "plan_hash"}
    value = exact_object(raw, fields, fields, "provision plan")
    if value["schema_version"] != 1 or value["contract"] != WORK_CONTRACT or not isinstance(value["actions"], list) or len(value["actions"]) != 1:
        raise PreparationError("INVALID_PROVISION_PLAN", "provision plan contract is invalid")
    unsealed = {key: item for key, item in value.items() if key != "plan_hash"}
    if value["plan_hash"] != digest(unsealed) or not is_sha256(value["provision_id"]):
        raise PreparationError("INVALID_PROVISION_PLAN", "provision plan hash or identifier is invalid")
    created = parse_datetime(value["created_at"], "plan.created_at")
    expires = parse_datetime(value["expires_at"], "plan.expires_at")
    if expires <= created or (require_unexpired and expires <= (at or utc_now()).astimezone(timezone.utc)):
        raise PreparationError("PROVISION_PLAN_EXPIRED", "provision plan is expired")
    validate_plan_action(value["actions"][0])
    strings(value["rollback"], "rollback", nonempty=True)
    strings(value["recovery"], "recovery", nonempty=True)
    return json.loads(canonical_json(value))
def validate_plan_action(raw: Any) -> dict[str, Any]:
    fields = {
        "source", "artifact_id", "license_notice", "download_mb", "expected_disk_mb", "expected_memory_mb",
        "target_runtime", "network_destination", "max_cost_usd", "verification_sha256", "recipe_id", "target_path",
        "license_source", "install_argv", "verify_argv", "environment_names", "idempotent_install",
        "install_network_access",
    }
    value = exact_object(raw, fields, fields, "provision action")
    if not is_sha256(value["verification_sha256"]) or not isinstance(value["idempotent_install"], bool):
        raise PreparationError("INVALID_PROVISION_PLAN", "provision action verification or idempotency is invalid")
    for field in ("artifact_id", "license_notice", "target_runtime", "network_destination", "recipe_id", "target_path"):
        if not isinstance(value[field], str) or not value[field]:
            raise PreparationError("INVALID_PROVISION_PLAN", f"plan action {field} must be non-empty")
    source = validated_source_uri(value["source"], "plan action source")
    validated_source_uri(value["license_source"], "plan action license source")
    if source.scheme == "https" and source.hostname != value["network_destination"]:
        raise PreparationError("INVALID_PROVISION_PLAN", "plan source host and network destination differ")
    if source.scheme == "file" and value["network_destination"] != "NONE":
        raise PreparationError("INVALID_PROVISION_PLAN", "local plan source must use network destination NONE")
    if value["install_network_access"] != "DENY":
        raise PreparationError("INVALID_PROVISION_PLAN", "reference installs must remain network-denied")
    external_path(Path(value["target_path"]), "provision target")
    for field in ("download_mb", "expected_disk_mb", "expected_memory_mb", "max_cost_usd"):
        number(value[field], f"action.{field}")
    for field in ("install_argv", "verify_argv", "environment_names"):
        strings(value[field], field)
    for argv_field in ("install_argv", "verify_argv"):
        if value[argv_field] and not Path(value[argv_field][0]).is_absolute():
            raise PreparationError("INVALID_PROVISION_PLAN", "plan executables must be absolute")
    return value


def validate_approval(raw: Any, plan: dict[str, Any], at: datetime) -> dict[str, Any]:
    fields = {"schema_version", "contract", "receipt_id", "provision_id", "plan_hash", "authority", "approved_at", "expires_at"}
    value = exact_object(raw, fields, fields, "provision approval")
    if value["schema_version"] != 1 or value["contract"] != APPROVAL_CONTRACT:
        raise PreparationError("INVALID_PROVISION_APPROVAL", "provision approval contract is invalid")
    if not isinstance(value["receipt_id"], str) or not value["receipt_id"]:
        raise PreparationError("INVALID_PROVISION_APPROVAL", "approval receipt identifier must be non-empty")
    if value["provision_id"] != plan["provision_id"] or value["plan_hash"] != plan["plan_hash"] or value["authority"] != "approve:provision":
        raise PreparationError("INVALID_PROVISION_APPROVAL", "approval is not bound to this exact plan and authority")
    approved = parse_datetime(value["approved_at"], "approval.approved_at")
    expires = parse_datetime(value["expires_at"], "approval.expires_at")
    if approved > at or expires <= at or expires <= approved or expires > parse_datetime(plan["expires_at"], "plan.expires_at"):
        raise PreparationError("PROVISION_APPROVAL_EXPIRED", "provision approval is not currently valid")
    return dict(value)


class ProvisionStore:
    def __init__(self, root: Path | None = None) -> None:
        self.root = external_path(root or default_state_dir(), "host-preparation state")

    def checkpoint_path(self, provision_id: str) -> Path:
        return self.root / "provisions" / (digest(provision_id)[7:] + ".json")

    def lock_path(self, provision_id: str) -> Path:
        return self.root / "locks" / (digest(provision_id)[7:] + ".lock")

    def staging_path(self, provision_id: str) -> Path:
        return self.root / "staging" / (digest(provision_id)[7:] + ".artifact")

    def load(self, provision_id: str) -> dict[str, Any] | None:
        path = self.checkpoint_path(provision_id)
        if not path.is_file():
            return None
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint is unreadable") from exc
        integrity = value.get("integrity_sha256") if isinstance(value, dict) else None
        payload = {key: item for key, item in value.items() if key != "integrity_sha256"} if isinstance(value, dict) else {}
        if integrity != digest(payload) or payload.get("provision_id") != provision_id:
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint integrity is invalid")
        required = {
            "schema_version", "contract", "provision_id", "plan_hash", "operation_id", "status",
            "downloaded_bytes", "artifact_sha256", "reason_code", "updated_at",
        }
        if set(payload) != required or payload.get("schema_version") != 1 or payload.get("contract") != CONTRACT:
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint shape is invalid")
        if payload.get("status") not in {"PREPARED", "IN_PROGRESS", "COMPLETED", "FAILED", "MANUAL_REQUIRED"}:
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint status is invalid")
        if not is_sha256(payload.get("plan_hash")) or not is_sha256(payload.get("operation_id")):
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint digests are invalid")
        if isinstance(payload.get("downloaded_bytes"), bool) or not isinstance(payload.get("downloaded_bytes"), int) or payload["downloaded_bytes"] < 0:
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint byte count is invalid")
        artifact_hash = payload.get("artifact_sha256")
        if artifact_hash is not None and not is_sha256(artifact_hash):
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint artifact digest is invalid")
        if payload.get("reason_code") is not None and (not isinstance(payload["reason_code"], str) or not payload["reason_code"]):
            raise PreparationError("PROVISION_CHECKPOINT_CORRUPT", "provision checkpoint reason is invalid")
        parse_datetime(payload.get("updated_at"), "checkpoint.updated_at")
        return value

    def save(self, value: dict[str, Any]) -> None:
        payload = {key: item for key, item in value.items() if key != "integrity_sha256"}
        atomic_write(self.checkpoint_path(payload["provision_id"]), {**payload, "integrity_sha256": digest(payload)})


def download(action: dict[str, Any], destination: Path, timeout_seconds: float = 30.0) -> int:
    maximum = int(Decimal(str(action["download_mb"])) * Decimal(1024 * 1024))
    parsed = urllib.parse.urlparse(action["source"])
    try:
        if parsed.scheme == "file":
            source = Path(urllib.request.url2pathname(parsed.path)).resolve()
            stream: Any = source.open("rb")
        else:
            request = urllib.request.Request(action["source"], headers={"User-Agent": "AI-Repository-Foundation/host-preparation"})
            stream = urllib.request.urlopen(request, timeout=timeout_seconds)
            final = urllib.parse.urlparse(stream.geturl())
            if final.scheme != "https" or final.hostname != action["network_destination"]:
                stream.close()
                raise PreparationError("PROVISION_REDIRECT_REFUSED", "download redirect crossed the planned origin", error_class="PERMISSION")
            length = stream.headers.get("Content-Length")
            if length is not None and int(length) > maximum:
                stream.close()
                raise PreparationError("PROVISION_DOWNLOAD_LIMIT_EXCEEDED", "declared content length exceeds the approved plan", error_class="BUDGET")
    except PreparationError:
        raise
    except (OSError, ValueError) as exc:
        raise PreparationError("PROVISION_SOURCE_UNAVAILABLE", "planned source is unavailable", error_class="AVAILABILITY") from exc
    destination.parent.mkdir(parents=True, exist_ok=True)
    observed = 0
    try:
        with stream, destination.open("wb") as output:
            while True:
                chunk = stream.read(min(1024 * 1024, maximum - observed + 1))
                if not chunk:
                    break
                observed += len(chunk)
                if observed > maximum:
                    raise PreparationError("PROVISION_DOWNLOAD_LIMIT_EXCEEDED", "download exceeded the approved plan", error_class="BUDGET")
                output.write(chunk)
            output.flush()
            os.fsync(output.fileno())
    except Exception as exc:
        try:
            destination.unlink()
        except FileNotFoundError:
            pass
        if isinstance(exc, PreparationError):
            raise
        if isinstance(exc, (OSError, ValueError)):
            raise PreparationError("PROVISION_SOURCE_UNAVAILABLE", "planned source became unavailable", error_class="AVAILABILITY") from exc
        raise
    if file_digest(destination) != action["verification_sha256"]:
        destination.unlink(missing_ok=True)
        raise PreparationError("PROVISION_HASH_MISMATCH", "downloaded artifact does not match the approved hash")
    return observed


def planned_argv(template: list[str], action: dict[str, Any], staging: Path, operation_id: str) -> list[str]:
    replacements = {"{artifact_path}": str(staging), "{target_path}": action["target_path"], "{operation_id}": operation_id}
    argv = []
    for item in template:
        if "{" in item and item not in replacements:
            raise PreparationError("INVALID_ARGV_TEMPLATE", "provision placeholders must occupy a complete supported argument")
        argv.append(replacements.get(item, item))
    return argv


def provision(plan_raw: Any, approval_raw: Any, *, store: ProvisionStore, at: datetime | None = None) -> dict[str, Any]:
    now = (at or utc_now()).astimezone(timezone.utc)
    plan = validate_plan(plan_raw, at=now)
    validate_approval(approval_raw, plan, now)
    action = plan["actions"][0]
    operation_id = digest({"provision_id": plan["provision_id"], "recipe_id": action["recipe_id"]})
    with file_lock(store.lock_path(plan["provision_id"])):
        state = store.load(plan["provision_id"])
        if state is None:
            state = {
                "schema_version": 1,
                "contract": CONTRACT,
                "provision_id": plan["provision_id"],
                "plan_hash": plan["plan_hash"],
                "operation_id": operation_id,
                "status": "PREPARED",
                "downloaded_bytes": 0,
                "artifact_sha256": None,
                "reason_code": None,
                "updated_at": isoformat(now),
            }
            store.save(state)
        if state["plan_hash"] != plan["plan_hash"] or state["operation_id"] != operation_id:
            raise PreparationError("PROVISION_CHECKPOINT_SCOPE_MISMATCH", "checkpoint does not match the exact plan")
        if state["status"] == "COMPLETED":
            return provision_report(plan, state, "RESUMED_COMPLETED_REPORT")
        if state["status"] in {"FAILED", "MANUAL_REQUIRED"}:
            return provision_report(plan, state, "TERMINAL_CHECKPOINT_REQUIRES_NEW_PLAN")
        if state["status"] == "IN_PROGRESS" and action["install_argv"] and not action["idempotent_install"]:
            state.update({"status": "MANUAL_REQUIRED", "reason_code": "AMBIGUOUS_NON_IDEMPOTENT_INSTALL", "updated_at": isoformat(now)})
            store.save(state)
            return provision_report(plan, state, state["reason_code"])
        target = external_path(Path(action["target_path"]), "provision target")
        if target.is_file() and file_digest(target) == action["verification_sha256"]:
            state.update({"status": "COMPLETED", "artifact_sha256": action["verification_sha256"], "reason_code": "TARGET_ALREADY_VERIFIED", "updated_at": isoformat(now)})
            store.save(state)
            return provision_report(plan, state, state["reason_code"])
        if target.exists():
            raise PreparationError("PROVISION_TARGET_CONFLICT", "target exists with different content", error_class="CONFLICT")
        target.parent.mkdir(parents=True, exist_ok=True)
        if shutil.disk_usage(target.parent).free < int(Decimal(str(action["expected_disk_mb"])) * Decimal(1024 * 1024)):
            raise PreparationError("PROVISION_DISK_LIMIT_UNAVAILABLE", "available disk does not satisfy the approved plan", error_class="RESOURCE")
        staging = store.staging_path(plan["provision_id"])
        state.update({"status": "IN_PROGRESS", "reason_code": None, "updated_at": isoformat(now)})
        store.save(state)
        try:
            downloaded = download(action, staging)
            state.update({"downloaded_bytes": downloaded, "artifact_sha256": action["verification_sha256"]})
            store.save(state)
            if action["install_argv"]:
                process = run_bounded(planned_argv(action["install_argv"], action, staging, operation_id), action["environment_names"], 300)
                if process.returncode != 0:
                    raise PreparationError("PROVISION_INSTALL_FAILED", "planned offline install command returned non-zero")
            else:
                os.replace(staging, target)
            if action["verify_argv"]:
                verified = run_bounded(planned_argv(action["verify_argv"], action, staging, operation_id), action["environment_names"], 60)
                if verified.returncode != 0:
                    raise PreparationError("PROVISION_VERIFY_FAILED", "planned verification command returned non-zero")
            elif not target.is_file() or file_digest(target) != action["verification_sha256"]:
                raise PreparationError("PROVISION_VERIFY_FAILED", "target artifact verification failed")
            try:
                staging.unlink()
            except FileNotFoundError:
                pass
            state.update({"status": "COMPLETED", "reason_code": "PROVISION_VERIFIED", "updated_at": isoformat(at or utc_now())})
            store.save(state)
            return provision_report(plan, state, state["reason_code"])
        except (PreparationError, OSError) as exc:
            reason = exc.code if isinstance(exc, PreparationError) else "PROVISION_LOCAL_IO_FAILED"
            if state["status"] != "MANUAL_REQUIRED":
                state.update({"status": "FAILED", "reason_code": reason, "updated_at": isoformat(at or utc_now())})
                store.save(state)
            try:
                staging.unlink()
            except FileNotFoundError:
                pass
            return provision_report(plan, state, reason)


def provision_report(plan: dict[str, Any], state: dict[str, Any], reason: str) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "contract": CONTRACT,
        "operation": "provision",
        "provision_id": plan["provision_id"],
        "plan_hash": plan["plan_hash"],
        "status": state["status"],
        "operation_id": state["operation_id"],
        "downloaded_bytes": state["downloaded_bytes"],
        "artifact_sha256": state["artifact_sha256"],
        "cost_upper_bound_usd": sum(float(item["max_cost_usd"]) for item in plan["actions"]),
        "reason_codes": [reason],
        "recovery": plan["recovery"] if state["status"] != "COMPLETED" else [],
    }


def verify(plan_raw: Any, *, store: ProvisionStore, at: datetime | None = None) -> dict[str, Any]:
    plan = validate_plan(plan_raw, at=at, require_unexpired=False)
    state = store.load(plan["provision_id"])
    if state is None:
        return {"schema_version": 1, "contract": CONTRACT, "operation": "verify", "provision_id": plan["provision_id"], "status": "UNAVAILABLE", "reason_codes": ["CHECKPOINT_UNAVAILABLE"]}
    action = plan["actions"][0]
    try:
        target = external_path(Path(action["target_path"]), "provision target")
        passed = target.is_file() and file_digest(target) == action["verification_sha256"]
        if action["verify_argv"]:
            staging = store.staging_path(plan["provision_id"])
            process = run_bounded(planned_argv(action["verify_argv"], action, staging, state["operation_id"]), action["environment_names"], 60)
            passed = process.returncode == 0
        status = "PASSED" if passed else "FAILED"
        reason = "TARGET_VERIFIED" if passed else "TARGET_VERIFICATION_FAILED"
    except PreparationError as exc:
        status = "UNAVAILABLE" if exc.error_class in {"AVAILABILITY", "TIMEOUT"} else "FAILED"
        reason = exc.code
    except OSError:
        status = "UNAVAILABLE"
        reason = "TARGET_VERIFICATION_UNAVAILABLE"
    return {"schema_version": 1, "contract": CONTRACT, "operation": "verify", "provision_id": plan["provision_id"], "status": status, "reason_codes": [reason]}


def _source_state_paths(root: Path, source_id: str) -> tuple[Path, Path]:
    name = digest(source_id)[7:]
    return root / "cost-evidence" / (name + ".json"), root / "locks" / ("cost-" + name + ".lock")


def validate_cost_sources(raw: Any) -> list[dict[str, Any]]:
    values = raw.get("sources") if isinstance(raw, dict) and set(raw) == {"sources"} else raw
    if not isinstance(values, list) or not values:
        raise PreparationError("INVALID_COST_SOURCES", "cost sources must be a non-empty array or sources object")
    required = {"source_id", "url", "json_path", "subject", "currency", "unit", "provenance", "valid_for_seconds", "refresh_seconds", "normalized_attempt_cost"}
    result = []
    seen = set()
    for raw_item in values:
        item = exact_object(raw_item, required, required, "cost source")
        if not isinstance(item["source_id"], str) or not item["source_id"] or item["source_id"] in seen:
            raise PreparationError("INVALID_COST_SOURCES", "cost source identifiers must be unique")
        validated_source_uri(item["url"], "cost source URL")
        path = strings(item["json_path"], "json_path", nonempty=True)
        subject = exact_object(item["subject"], {"kind", "subject_id"}, {"kind", "subject_id"}, "cost subject")
        if subject["kind"] not in {"PROVIDER_PRICE", "ELECTRICITY_TARIFF", "HARDWARE_AMORTIZATION", "RESOURCE_MEASUREMENT", "OTHER"}:
            raise PreparationError("INVALID_COST_SOURCES", "cost subject kind is invalid")
        if item["provenance"] not in {"MEASURED", "CONFIGURED", "PROVIDER_QUOTED", "RESEARCH_VERIFIED"}:
            raise PreparationError("INVALID_COST_SOURCES", "cost provenance is invalid")
        for field in ("currency", "unit"):
            if not isinstance(item[field], str) or not item[field]:
                raise PreparationError("INVALID_COST_SOURCES", f"cost source {field} must be non-empty")
        if not isinstance(subject["subject_id"], str) or not subject["subject_id"]:
            raise PreparationError("INVALID_COST_SOURCES", "cost subject identifier must be non-empty")
        valid_for = int(number(item["valid_for_seconds"], "valid_for_seconds"))
        refresh = int(number(item["refresh_seconds"], "refresh_seconds"))
        if valid_for <= 0 or refresh < MIN_REFRESH_SECONDS:
            raise PreparationError("INVALID_COST_SOURCES", "cost validity must be positive and refresh at least 24 hours")
        normalized = item["normalized_attempt_cost"]
        if normalized is not None:
            normalized = exact_object(normalized, {"usd", "method", "source"}, {"usd", "method", "source"}, "normalized attempt cost")
            for field in ("method", "source"):
                if not isinstance(normalized[field], str) or not normalized[field]:
                    raise PreparationError("INVALID_COST_SOURCES", f"normalized attempt cost {field} must be non-empty")
            normalized = {**normalized, "usd": float(number(normalized["usd"], "normalized_attempt_cost.usd"))}
        result.append({**item, "json_path": path, "valid_for_seconds": valid_for, "refresh_seconds": refresh, "normalized_attempt_cost": normalized})
        seen.add(item["source_id"])
    return result


def fetch_bytes(url: str, timeout_seconds: float = 20.0) -> bytes:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme == "file":
        return Path(urllib.request.url2pathname(parsed.path)).read_bytes()
    request = urllib.request.Request(url, headers={"User-Agent": "AI-Repository-Foundation/cost-evidence"})
    with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
        final = urllib.parse.urlparse(response.geturl())
        if final.scheme != "https" or final.hostname != parsed.hostname:
            raise PreparationError("COST_SOURCE_REDIRECT_REFUSED", "cost source redirect crossed origin", error_class="PERMISSION")
        return response.read(4 * 1024 * 1024 + 1)


def refresh_cost_evidence(sources_raw: Any, *, state_root: Path, network_authorized: bool, at: datetime | None = None, fetch: Callable[[str], bytes] = fetch_bytes) -> dict[str, Any]:
    sources = validate_cost_sources(sources_raw)
    root = external_path(state_root, "cost-evidence state")
    observed = (at or utc_now()).astimezone(timezone.utc)
    records = []
    for source in sources:
        parsed = urllib.parse.urlparse(source["url"])
        path, lock = _source_state_paths(root, source["source_id"])
        with file_lock(lock):
            existing = None
            if path.is_file():
                try:
                    existing = json.loads(path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError):
                    existing = None
            if isinstance(existing, dict) and set(existing) == {"contract", "source_id", "last_attempt_at", "next_allowed_at", "evidence"} and existing.get("contract") == CONTRACT and existing.get("source_id") == source["source_id"]:
                try:
                    next_allowed = parse_datetime(existing["next_allowed_at"], "next_allowed_at")
                except PreparationError:
                    existing = None
            if isinstance(existing, dict):
                evidence = existing["evidence"]
                try:
                    usable = isinstance(evidence, dict) and parse_datetime(evidence["valid_until"], "valid_until") > observed
                except (PreparationError, KeyError, TypeError):
                    usable = False
                if parsed.scheme == "https" and not network_authorized:
                    records.append({"source_id": source["source_id"], "status": "CACHED" if usable else "BLOCKED", "reason_code": "NETWORK_NOT_AUTHORIZED", "evidence": evidence if usable else None})
                    continue
                if observed < next_allowed:
                    status = "CACHED" if usable else "DEFERRED"
                    records.append({"source_id": source["source_id"], "status": status, "reason_code": "REFRESH_RATE_LIMIT", "evidence": evidence if usable else None})
                    continue
            elif parsed.scheme == "https" and not network_authorized:
                records.append({"source_id": source["source_id"], "status": "BLOCKED", "reason_code": "NETWORK_NOT_AUTHORIZED", "evidence": None})
                continue
            try:
                body = fetch(source["url"])
                if len(body) > 4 * 1024 * 1024:
                    raise PreparationError("COST_SOURCE_TOO_LARGE", "cost source exceeds four MiB")
                payload = json.loads(body.decode("utf-8"))
                value: Any = payload
                for key in source["json_path"]:
                    value = value[int(key)] if isinstance(value, list) else value[key]
                amount = float(number(value, "cost source value"))
                refresh_at = observed + timedelta(seconds=source["refresh_seconds"])
                evidence = {
                    "schema_version": 1,
                    "contract": EVIDENCE_CONTRACT,
                    "evidence_id": digest({"source_id": source["source_id"], "observed_at": isoformat(observed), "content": digest_bytes(body)}),
                    "subject": source["subject"],
                    "amount": amount,
                    "currency": source["currency"],
                    "unit": source["unit"],
                    "provenance": source["provenance"],
                    "source": {"kind": "PRIMARY_API" if parsed.scheme == "https" else "PROJECT_CONFIGURATION", "locator": source["url"]},
                    "observed_at": isoformat(observed),
                    "valid_until": isoformat(observed + timedelta(seconds=source["valid_for_seconds"])),
                    "content_sha256": digest_bytes(body),
                    "refresh": {
                        "last_attempt_at": isoformat(observed),
                        "maximum_frequency_seconds": source["refresh_seconds"],
                        "next_allowed_at": isoformat(refresh_at),
                        "suggested_after": isoformat(refresh_at),
                    },
                }
                if source["normalized_attempt_cost"] is not None:
                    normalized = source["normalized_attempt_cost"]
                    evidence["normalized_attempt_cost_usd"] = normalized["usd"]
                    evidence["normalized_cost_provenance"] = {"method": normalized["method"], "source": normalized["source"]}
                atomic_write(path, {
                    "contract": CONTRACT,
                    "source_id": source["source_id"],
                    "last_attempt_at": isoformat(observed),
                    "next_allowed_at": isoformat(refresh_at),
                    "evidence": evidence,
                })
                records.append({"source_id": source["source_id"], "status": "REFRESHED", "reason_code": "PRIMARY_SOURCE_VERIFIED", "evidence": evidence})
            except (PreparationError, OSError, UnicodeError, json.JSONDecodeError, KeyError, IndexError, ValueError, TypeError) as exc:
                previous = existing.get("evidence") if isinstance(existing, dict) else None
                try:
                    fallback = previous if isinstance(previous, dict) and parse_datetime(previous["valid_until"], "valid_until") > observed else None
                except (PreparationError, KeyError, TypeError):
                    fallback = None
                next_allowed = observed + timedelta(seconds=source["refresh_seconds"])
                atomic_write(path, {
                    "contract": CONTRACT,
                    "source_id": source["source_id"],
                    "last_attempt_at": isoformat(observed),
                    "next_allowed_at": isoformat(next_allowed),
                    "evidence": fallback,
                })
                records.append({"source_id": source["source_id"], "status": "CACHED" if fallback else "UNAVAILABLE", "reason_code": exc.code if isinstance(exc, PreparationError) else "SOURCE_REFRESH_FAILED", "evidence": fallback})
    statuses = {item["status"] for item in records}
    status = "COMPLETE" if statuses <= {"REFRESHED", "CACHED"} else "UNAVAILABLE" if statuses <= {"UNAVAILABLE", "DEFERRED", "BLOCKED"} else "PARTIAL"
    return {"schema_version": 1, "contract": CONTRACT, "operation": "refresh-cost-evidence", "observed_at": isoformat(observed), "status": status, "records": records}


def load_json(path: str, field: str) -> Any:
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PreparationError("INPUT_UNREADABLE", f"{field} is unavailable or invalid") from exc


def write_result(value: dict[str, Any]) -> int:
    print(json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False))
    return 0 if value.get("status", "COMPLETE") in {"COMPLETE", "COMPLETED", "PASSED"} else 3


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    doctor_parser = subparsers.add_parser("doctor")
    doctor_parser.add_argument("--definitions")
    inventory_parser = subparsers.add_parser("inventory")
    inventory_parser.add_argument("--definitions")
    inventory_parser.add_argument("--doctor", required=True)
    plan_parser = subparsers.add_parser("plan-provision")
    plan_parser.add_argument("--request", required=True)
    plan_parser.add_argument("--recipes", required=True)
    provision_parser = subparsers.add_parser("provision")
    provision_parser.add_argument("--plan", required=True)
    provision_parser.add_argument("--approval", required=True)
    provision_parser.add_argument("--state-dir")
    verify_parser = subparsers.add_parser("verify")
    verify_parser.add_argument("--plan", required=True)
    verify_parser.add_argument("--state-dir")
    refresh_parser = subparsers.add_parser("refresh-cost-evidence")
    refresh_parser.add_argument("--sources", required=True)
    refresh_parser.add_argument("--state-dir")
    refresh_parser.add_argument("--network-authorized", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.command == "doctor":
            definitions = load_json(args.definitions, "runtime definitions") if args.definitions else default_runtime_definitions()
            return write_result(doctor(definitions))
        if args.command == "inventory":
            definitions = load_json(args.definitions, "runtime definitions") if args.definitions else default_runtime_definitions()
            return write_result(inventory(definitions, load_json(args.doctor, "doctor report")))
        if args.command == "plan-provision":
            return write_result(plan_provision(load_json(args.request, "provision request"), load_json(args.recipes, "provision recipes")))
        state = ProvisionStore(Path(args.state_dir) if args.state_dir else None)
        if args.command == "provision":
            return write_result(provision(load_json(args.plan, "provision plan"), load_json(args.approval, "provision approval"), store=state))
        if args.command == "verify":
            return write_result(verify(load_json(args.plan, "provision plan"), store=state))
        return write_result(refresh_cost_evidence(load_json(args.sources, "cost sources"), state_root=state.root, network_authorized=args.network_authorized))
    except PreparationError as exc:
        print(json.dumps({"contract": CONTRACT, "status": "BLOCKED", "error": {"class": exc.error_class, "code": exc.code, "message": str(exc)}}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""External runtime connection store and interactive configuration assistant."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import os
import re
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Iterator

from adapter_protocol import AdapterError
from reference_adapters import OllamaAdapter, OpenAICompatibleAdapter, canonical_json


CONTRACT = "foundation-ai-runtime-configuration/v1"
DATA_CLASSES = {"PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"}
BOUNDARIES = {"HOST", "LOCAL_NETWORK", "REMOTE", "UNKNOWN"}
ADAPTERS = {"ollama", "openai-compatible"}
SELECTION_MODES = {"MANUAL", "PINNED", "ROUTER"}
CONNECTION_ID = re.compile(r"^[a-z0-9][a-z0-9._-]{0,63}$")
ENVIRONMENT_NAME = re.compile(r"^[A-Z_][A-Z0-9_]*$")
DOTENV_KEY = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
MAX_CONFIG_BYTES = 1024 * 1024
DEFAULT_OLLAMA_ENDPOINT = "http://127.0.0.1:11434"


class ConfigurationError(RuntimeError):
    """A content-free, user-actionable configuration failure."""

    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def config_digest(value: dict[str, Any]) -> str:
    return "sha256:" + hashlib.sha256(canonical_json(value)).hexdigest()


def empty_configuration() -> dict[str, Any]:
    return {"schema_version": 1, "contract": CONTRACT, "updated_at": utc_now(), "connections": {}}


def default_state_dir() -> Path:
    override = os.environ.get("AI_RUNTIME_ADAPTER_HOME")
    if override:
        path = Path(override)
        if not path.is_absolute():
            raise ConfigurationError("STATE_PATH_NOT_ABSOLUTE", "AI_RUNTIME_ADAPTER_HOME must be absolute")
        return path
    if os.name == "nt":
        # Packaged Windows clients may virtualize LOCALAPPDATA differently per host.
        # The user profile is stable across Codex, IDEs, terminals, and MCP clients.
        return Path.home() / ".ai-repository-foundation" / "ai-runtime-adapters"
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "AIRepositoryFoundation" / "ai-runtime-adapters"
    xdg = os.environ.get("XDG_STATE_HOME")
    return (Path(xdg) if xdg else Path.home() / ".local" / "state") / "ai-repository-foundation" / "ai-runtime-adapters"


def default_config_path() -> Path:
    return default_state_dir() / "runtime-connections.json"


def _inside_git_worktree(path: Path) -> bool:
    current = path.resolve()
    if not current.exists():
        current = current.parent
    for parent in (current, *current.parents):
        if (parent / ".git").exists():
            return True
    return False


def _require_exact_keys(value: dict[str, Any], required: set[str], allowed: set[str], label: str) -> None:
    missing = sorted(required - set(value))
    unknown = sorted(set(value) - allowed)
    if missing:
        raise ConfigurationError("MISSING_FIELD", f"{label} is missing: {', '.join(missing)}")
    if unknown:
        raise ConfigurationError("UNKNOWN_FIELD", f"{label} has unknown fields: {', '.join(unknown)}")


def _absolute_roots(value: Any, field: str) -> list[str]:
    if not isinstance(value, list) or not value:
        raise ConfigurationError("INVALID_ROOTS", f"{field} must contain at least one absolute path")
    result: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item or not Path(item).is_absolute():
            raise ConfigurationError("INVALID_ROOTS", f"{field} must contain only absolute paths")
        normalized = str(Path(item).resolve())
        if normalized not in result:
            result.append(normalized)
    return result


def validate_credential(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ConfigurationError("INVALID_CREDENTIAL_REFERENCE", "credential must be an object")
    source = value.get("source")
    if source == "NONE":
        _require_exact_keys(value, {"source"}, {"source"}, "credential")
    elif source == "ENVIRONMENT":
        _require_exact_keys(value, {"source", "source_name", "export_as"}, {"source", "source_name", "export_as"}, "credential")
        if not isinstance(value["source_name"], str) or not ENVIRONMENT_NAME.fullmatch(value["source_name"]):
            raise ConfigurationError("INVALID_ENVIRONMENT_NAME", "credential source_name is invalid")
        if not isinstance(value["export_as"], str) or not ENVIRONMENT_NAME.fullmatch(value["export_as"]):
            raise ConfigurationError("INVALID_ENVIRONMENT_NAME", "credential export_as is invalid")
    elif source == "DOTENV_REFERENCE":
        _require_exact_keys(value, {"source", "path", "key", "export_as"}, {"source", "path", "key", "export_as"}, "credential")
        if not isinstance(value["path"], str) or not Path(value["path"]).is_absolute():
            raise ConfigurationError("DOTENV_PATH_NOT_ABSOLUTE", "dotenv reference path must be absolute")
        if not isinstance(value["key"], str) or not DOTENV_KEY.fullmatch(value["key"]):
            raise ConfigurationError("INVALID_DOTENV_KEY", "dotenv key is invalid")
        if not isinstance(value["export_as"], str) or not ENVIRONMENT_NAME.fullmatch(value["export_as"]):
            raise ConfigurationError("INVALID_ENVIRONMENT_NAME", "credential export_as is invalid")
    else:
        raise ConfigurationError("INVALID_CREDENTIAL_SOURCE", "credential source must be NONE, ENVIRONMENT, or DOTENV_REFERENCE")
    return deepcopy(value)


def validate_connection(connection_id: str, value: Any) -> dict[str, Any]:
    if not CONNECTION_ID.fullmatch(connection_id):
        raise ConfigurationError("INVALID_CONNECTION_ID", "connection id must use lowercase letters, digits, dot, dash, or underscore")
    if not isinstance(value, dict):
        raise ConfigurationError("INVALID_CONNECTION", "connection must be an object")
    required = {
        "label", "adapter", "endpoint", "execution_boundary", "trust_loopback_host", "network_authorized",
        "allowed_data_classes", "remote_data_classes", "allow_remote_models", "credential", "read_roots",
        "write_roots", "timeout_seconds", "health_ttl_seconds", "catalog_ttl_seconds", "model_selection",
    }
    _require_exact_keys(value, required, required, f"connection {connection_id}")
    result = deepcopy(value)
    if not isinstance(result["label"], str) or not result["label"].strip():
        raise ConfigurationError("INVALID_LABEL", "connection label must be non-empty")
    if result["adapter"] not in ADAPTERS:
        raise ConfigurationError("INVALID_ADAPTER", "adapter is invalid")
    endpoint = result["endpoint"]
    if not isinstance(endpoint, str):
        raise ConfigurationError("INVALID_ENDPOINT", "endpoint must be a credential-free HTTP(S) origin")
    parsed = urllib.parse.urlparse(endpoint)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ConfigurationError("INVALID_ENDPOINT", "endpoint must be a credential-free HTTP(S) origin")
    if parsed.path not in {"", "/"}:
        raise ConfigurationError("INVALID_ENDPOINT", "endpoint must not contain an API path")
    result["endpoint"] = endpoint.rstrip("/")
    if result["execution_boundary"] not in BOUNDARIES:
        raise ConfigurationError("INVALID_BOUNDARY", "execution boundary is invalid")
    for field in ("trust_loopback_host", "network_authorized", "allow_remote_models"):
        if not isinstance(result[field], bool):
            raise ConfigurationError("INVALID_BOOLEAN", f"{field} must be boolean")
    loopback = parsed.hostname.lower() in {"localhost", "127.0.0.1", "::1"}
    if result["execution_boundary"] == "HOST" and loopback and not result["trust_loopback_host"]:
        raise ConfigurationError("UNPROVEN_LOOPBACK_BOUNDARY", "HOST for loopback requires explicit trust_loopback_host confirmation")
    for field in ("allowed_data_classes", "remote_data_classes"):
        classes = result[field]
        if not isinstance(classes, list) or any(not isinstance(item, str) for item in classes) or not set(classes) <= DATA_CLASSES:
            raise ConfigurationError("INVALID_DATA_CLASSES", f"{field} contains an invalid data class")
        result[field] = list(dict.fromkeys(classes))
    result["credential"] = validate_credential(result["credential"])
    result["read_roots"] = _absolute_roots(result["read_roots"], "read_roots")
    result["write_roots"] = _absolute_roots(result["write_roots"], "write_roots")
    for field, minimum, maximum in (
        ("timeout_seconds", 0.1, 600), ("health_ttl_seconds", 1, 3600), ("catalog_ttl_seconds", 1, 86400)
    ):
        number = result[field]
        if isinstance(number, bool) or not isinstance(number, (int, float)) or number < minimum or number > maximum:
            raise ConfigurationError("INVALID_TIMEOUT", f"{field} is out of bounds")
    selection = result["model_selection"]
    if not isinstance(selection, dict):
        raise ConfigurationError("INVALID_MODEL_SELECTION", "model_selection must be an object")
    _require_exact_keys(selection, {"mode", "default_model"}, {"mode", "default_model"}, "model_selection")
    if selection["mode"] not in SELECTION_MODES:
        raise ConfigurationError("INVALID_MODEL_SELECTION", "model selection mode is invalid")
    default_model = selection["default_model"]
    if default_model is not None and (not isinstance(default_model, str) or not default_model):
        raise ConfigurationError("INVALID_MODEL_SELECTION", "default_model must be null or non-empty")
    if selection["mode"] == "PINNED" and default_model is None:
        raise ConfigurationError("PINNED_MODEL_REQUIRED", "PINNED model selection requires default_model")
    if selection["mode"] != "PINNED" and default_model is not None:
        raise ConfigurationError("UNEXPECTED_DEFAULT_MODEL", "default_model is allowed only for PINNED selection")
    return result


def validate_configuration(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ConfigurationError("INVALID_CONFIGURATION", "configuration must be an object")
    required = {"schema_version", "contract", "updated_at", "connections"}
    _require_exact_keys(value, required, required, "configuration")
    if value["schema_version"] != 1 or value["contract"] != CONTRACT:
        raise ConfigurationError("UNSUPPORTED_CONFIGURATION", "configuration contract is unsupported")
    if not isinstance(value["updated_at"], str) or not value["updated_at"]:
        raise ConfigurationError("INVALID_UPDATED_AT", "updated_at must be a timestamp")
    if not isinstance(value["connections"], dict):
        raise ConfigurationError("INVALID_CONNECTIONS", "connections must be an object")
    result = deepcopy(value)
    result["connections"] = {
        connection_id: validate_connection(connection_id, connection)
        for connection_id, connection in value["connections"].items()
    }
    return result


def atomic_write_json(path: Path, value: dict[str, Any]) -> None:
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
        with contextlib.suppress(FileNotFoundError):
            Path(temporary).unlink()


class ConfigurationStore:
    def __init__(self, path: Path | None = None) -> None:
        self.path = (path or default_config_path()).resolve()
        self.backup_path = self.path.with_suffix(self.path.suffix + ".rollback")

    def load_raw(self) -> dict[str, Any]:
        if not self.path.exists():
            return empty_configuration()
        try:
            if self.path.stat().st_size > MAX_CONFIG_BYTES:
                raise ConfigurationError("CONFIGURATION_TOO_LARGE", "configuration exceeds the size limit")
            value = json.loads(self.path.read_text(encoding="utf-8"))
        except ConfigurationError:
            raise
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise ConfigurationError("CONFIGURATION_UNREADABLE", "configuration is unavailable or invalid JSON") from exc
        if not isinstance(value, dict):
            raise ConfigurationError("INVALID_CONFIGURATION", "configuration must be an object")
        return value

    def load(self) -> dict[str, Any]:
        return validate_configuration(self.load_raw())

    def load_for_edit(self) -> dict[str, Any]:
        """Load a supported document while isolating validation to each edited connection."""
        raw = self.load_raw()
        required = {"schema_version", "contract", "updated_at", "connections"}
        _require_exact_keys(raw, required, required, "configuration")
        if raw["schema_version"] != 1 or raw["contract"] != CONTRACT:
            raise ConfigurationError("UNSUPPORTED_CONFIGURATION", "configuration contract is unsupported")
        if not isinstance(raw["updated_at"], str) or not raw["updated_at"] or not isinstance(raw["connections"], dict):
            raise ConfigurationError("INVALID_CONFIGURATION", "configuration header is invalid")
        return deepcopy(raw)

    def load_connection(self, connection_id: str) -> dict[str, Any]:
        raw = self.load_raw()
        if raw.get("schema_version") != 1 or raw.get("contract") != CONTRACT or not isinstance(raw.get("connections"), dict):
            raise ConfigurationError("UNSUPPORTED_CONFIGURATION", "configuration header is invalid")
        if connection_id not in raw["connections"]:
            raise ConfigurationError("CONNECTION_NOT_FOUND", f"connection is not configured: {connection_id}")
        return validate_connection(connection_id, raw["connections"][connection_id])

    def connection_statuses(self) -> list[dict[str, Any]]:
        raw = self.load_raw()
        connections = raw.get("connections")
        if raw.get("schema_version") != 1 or raw.get("contract") != CONTRACT or not isinstance(connections, dict):
            raise ConfigurationError("UNSUPPORTED_CONFIGURATION", "configuration header is invalid")
        rows = []
        for connection_id, value in sorted(connections.items()):
            try:
                connection = validate_connection(connection_id, value)
            except ConfigurationError as exc:
                rows.append({"connection_id": connection_id, "status": "INVALID", "reason_code": exc.code})
                continue
            rows.append(public_connection(connection_id, connection))
        return rows

    def save(self, value: dict[str, Any]) -> dict[str, Any]:
        if _inside_git_worktree(self.path):
            raise ConfigurationError("STATE_INSIDE_GIT", "runtime configuration must be stored outside a Git worktree")
        normalized = validate_configuration(value)
        normalized["updated_at"] = utc_now()
        # Preserve the exact previous document even when one connection is invalid,
        # so that replacing or removing that isolated entry remains possible.
        previous = self.load_raw() if self.path.exists() else empty_configuration()
        previous_hash = config_digest(previous)
        applied_hash = config_digest(normalized)
        backup = {
            "schema_version": 1,
            "contract": "foundation-ai-runtime-configuration-rollback/v1",
            "created_at": utc_now(),
            "previous_hash": previous_hash,
            "applied_hash": applied_hash,
            "previous_configuration": previous,
        }
        atomic_write_json(self.backup_path, backup)
        atomic_write_json(self.path, normalized)
        return {"status": "SAVED", "path": str(self.path), "previous_hash": previous_hash, "configuration_hash": applied_hash}

    def rollback(self) -> dict[str, Any]:
        if not self.backup_path.exists():
            raise ConfigurationError("ROLLBACK_UNAVAILABLE", "no rollback record is available")
        try:
            backup = json.loads(self.backup_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise ConfigurationError("ROLLBACK_INVALID", "rollback record is unavailable or invalid") from exc
        required = {"schema_version", "contract", "created_at", "previous_hash", "applied_hash", "previous_configuration"}
        if not isinstance(backup, dict) or set(backup) != required or backup.get("contract") != "foundation-ai-runtime-configuration-rollback/v1":
            raise ConfigurationError("ROLLBACK_INVALID", "rollback record has an invalid contract")
        current = self.load()
        if config_digest(current) != backup["applied_hash"]:
            raise ConfigurationError("ROLLBACK_CONFLICT", "configuration changed after the saved plan; rollback refused")
        previous = backup["previous_configuration"]
        if not isinstance(previous, dict):
            raise ConfigurationError("ROLLBACK_INVALID", "rollback configuration is invalid")
        if config_digest(previous) != backup["previous_hash"]:
            raise ConfigurationError("ROLLBACK_INVALID", "rollback record hash does not match its content")
        atomic_write_json(self.path, previous)
        self.backup_path.unlink()
        return {"status": "ROLLED_BACK", "configuration_hash": backup["previous_hash"]}


def public_connection(connection_id: str, connection: dict[str, Any]) -> dict[str, Any]:
    credential = connection["credential"]
    credential_summary = {"source": credential["source"]}
    if credential["source"] != "NONE":
        credential_summary["export_as"] = credential["export_as"]
    return {
        "connection_id": connection_id,
        "status": "CONFIGURED",
        "label": connection["label"],
        "adapter": connection["adapter"],
        "endpoint": connection["endpoint"],
        "execution_boundary": connection["execution_boundary"],
        "allow_remote_models": connection["allow_remote_models"],
        "allowed_data_classes": connection["allowed_data_classes"],
        "remote_data_classes": connection["remote_data_classes"],
        "model_selection": connection["model_selection"],
        "credential": credential_summary,
    }


def read_dotenv_value(path: Path, key: str) -> str:
    try:
        if path.stat().st_size > MAX_CONFIG_BYTES:
            raise ConfigurationError("DOTENV_TOO_LARGE", "dotenv file exceeds the size limit")
        lines = path.read_text(encoding="utf-8").splitlines()
    except ConfigurationError:
        raise
    except (OSError, UnicodeError) as exc:
        raise ConfigurationError("DOTENV_UNREADABLE", "dotenv reference is unavailable or invalid UTF-8") from exc
    matches: list[str] = []
    pattern = re.compile(rf"^(?:export\s+)?{re.escape(key)}\s*=\s*(.*)$")
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = pattern.fullmatch(stripped)
        if not match:
            continue
        value = match.group(1).strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        matches.append(value)
    if len(matches) != 1 or not matches[0]:
        raise ConfigurationError("DOTENV_KEY_UNAVAILABLE", "dotenv key must exist exactly once and be non-empty")
    return matches[0]


@contextlib.contextmanager
def credential_environment(connection: dict[str, Any]) -> Iterator[None]:
    credential = connection["credential"]
    source = credential["source"]
    if source == "NONE":
        yield
        return
    if source == "ENVIRONMENT":
        value = os.environ.get(credential["source_name"])
        if not value:
            raise ConfigurationError("CREDENTIAL_UNAVAILABLE", "referenced environment credential is unavailable")
    else:
        value = read_dotenv_value(Path(credential["path"]), credential["key"])
    target = credential["export_as"]
    previous = os.environ.get(target)
    os.environ[target] = value
    try:
        yield
    finally:
        if previous is None:
            os.environ.pop(target, None)
        else:
            os.environ[target] = previous


def adapter_configuration(connection: dict[str, Any]) -> dict[str, Any]:
    credential = connection["credential"]
    exported = credential.get("export_as") if credential["source"] != "NONE" else None
    return {
        "provider": connection["label"],
        "endpoint": connection["endpoint"],
        "execution_boundary": connection["execution_boundary"],
        "trust_loopback_host": connection["trust_loopback_host"],
        "network_authorized": connection["network_authorized"],
        "credential_env": exported,
        "environment_allowlist": [exported] if exported else [],
        "allowed_data_classes": connection["allowed_data_classes"],
        "remote_data_classes": connection["remote_data_classes"],
        "read_roots": connection["read_roots"],
        "write_roots": connection["write_roots"],
        "timeout_seconds": connection["timeout_seconds"],
        "health_ttl_seconds": connection["health_ttl_seconds"],
        "catalog_ttl_seconds": connection["catalog_ttl_seconds"],
        "allow_remote_models": connection["allow_remote_models"],
    }


def create_adapter(connection: dict[str, Any]) -> Any:
    config = adapter_configuration(connection)
    return OllamaAdapter(config) if connection["adapter"] == "ollama" else OpenAICompatibleAdapter(config)


def execute_adapter(connection: dict[str, Any], operation: str, arguments: dict[str, Any]) -> dict[str, Any]:
    with credential_environment(connection):
        adapter = create_adapter(connection)
        method = getattr(adapter, operation, None)
        if method is None:
            raise ConfigurationError("OPERATION_UNSUPPORTED", f"adapter does not support {operation}")
        return method(arguments)


def _probe_candidate(endpoint: str, timeout: float) -> dict[str, Any]:
    checked_at = utc_now()
    request = urllib.request.Request(endpoint.rstrip("/") + "/api/version", headers={"Accept": "application/json"})
    try:
        with urllib.request.build_opener().open(request, timeout=timeout) as response:
            payload = json.loads(response.read())
        version = payload.get("version") if isinstance(payload, dict) else None
        return {"adapter": "ollama", "endpoint": endpoint, "state": "HEALTHY", "checked_at": checked_at, "version": version}
    except (OSError, TimeoutError, urllib.error.URLError, json.JSONDecodeError):
        return {"adapter": "ollama", "endpoint": endpoint, "state": "UNAVAILABLE", "checked_at": checked_at, "version": None}


def discover_candidates(*, probe: bool, timeout: float = 0.75) -> list[dict[str, Any]]:
    candidates: list[tuple[str, str]] = []
    configured = os.environ.get("OLLAMA_HOST")
    if configured:
        if "://" not in configured:
            configured = "http://" + configured
        candidates.append((configured.rstrip("/"), "OLLAMA_HOST"))
    candidates.append((DEFAULT_OLLAMA_ENDPOINT, "SAFE_LOOPBACK_DEFAULT"))
    seen: set[str] = set()
    result = []
    for endpoint, source in candidates:
        if endpoint in seen:
            continue
        seen.add(endpoint)
        parsed = urllib.parse.urlparse(endpoint)
        loopback = (parsed.hostname or "").lower() in {"localhost", "127.0.0.1", "::1"}
        row = _probe_candidate(endpoint, timeout) if probe and loopback else {
            "adapter": "ollama", "endpoint": endpoint, "state": "NOT_PROBED", "checked_at": None, "version": None
        }
        if probe and not loopback:
            row["state"] = "AUTHORIZATION_REQUIRED"
        row["source"] = source
        row["proposal_only"] = True
        row["requires_confirmation"] = ["execution_boundary", "network_authorized", "data_classes", "remote_models"]
        result.append(row)
    return result


def _ask(input_fn: Callable[[str], str], prompt: str, default: str) -> str:
    answer = input_fn(f"{prompt} [{default}]: ").strip()
    return answer or default


def _ask_bool(input_fn: Callable[[str], str], prompt: str, default: bool) -> bool:
    marker = "J/n" if default else "j/N"
    while True:
        answer = input_fn(f"{prompt} [{marker}]: ").strip().lower()
        if not answer:
            return default
        if answer in {"j", "ja", "y", "yes"}:
            return True
        if answer in {"n", "nein", "no"}:
            return False


def _ask_choice(input_fn: Callable[[str], str], prompt: str, choices: list[str], default: str) -> str:
    rendered = "/".join(choices)
    while True:
        answer = _ask(input_fn, f"{prompt} ({rendered})", default).upper()
        matches = [item for item in choices if answer == item or answer == item[0]]
        if len(matches) == 1:
            return matches[0]


def _csv_classes(raw: str) -> list[str]:
    values = [item.strip().upper() for item in raw.split(",") if item.strip()]
    if not set(values) <= DATA_CLASSES:
        raise ConfigurationError("INVALID_DATA_CLASSES", "data classes must be PUBLIC, INTERNAL, CONFIDENTIAL, or RESTRICTED")
    return list(dict.fromkeys(values))


def _connection_defaults(state_dir: Path, endpoint: str) -> dict[str, Any]:
    handles = (state_dir / "handles").resolve()
    return {
        "label": "Ollama local",
        "adapter": "ollama",
        "endpoint": endpoint,
        "execution_boundary": "UNKNOWN",
        "trust_loopback_host": False,
        "network_authorized": True,
        "allowed_data_classes": ["PUBLIC"],
        "remote_data_classes": [],
        "allow_remote_models": False,
        "credential": {"source": "NONE"},
        "read_roots": [str(handles / "input")],
        "write_roots": [str(handles / "output")],
        "timeout_seconds": 30,
        "health_ttl_seconds": 30,
        "catalog_ttl_seconds": 300,
        "model_selection": {"mode": "ROUTER", "default_model": None},
    }


def ask_connection(
    connection_id: str,
    current: dict[str, Any],
    input_fn: Callable[[str], str],
    output_fn: Callable[[str], None],
) -> dict[str, Any]:
    value = deepcopy(current)
    value["label"] = _ask(input_fn, "Anzeigename", value["label"])
    value["adapter"] = _ask_choice(input_fn, "Runtime-Typ", ["OLLAMA", "OPENAI-COMPATIBLE"], value["adapter"].upper()).lower()
    value["endpoint"] = _ask(input_fn, "Adresse (Schema://Hostname/IP:Port)", value["endpoint"])
    value["execution_boundary"] = _ask_choice(input_fn, "Ausführungsgrenze", ["HOST", "LOCAL_NETWORK", "REMOTE", "UNKNOWN"], value["execution_boundary"])
    parsed = urllib.parse.urlparse(value["endpoint"])
    loopback = (parsed.hostname or "").lower() in {"localhost", "127.0.0.1", "::1"}
    value["trust_loopback_host"] = value["execution_boundary"] == "HOST" and loopback and _ask_bool(
        input_fn, "Bestätigst du, dass dieser Loopback-Dienst wirklich auf diesem Host läuft?", value["trust_loopback_host"]
    )
    value["network_authorized"] = _ask_bool(input_fn, "HTTP-Zugriff auf genau diesen Endpunkt erlauben?", value["network_authorized"])
    while True:
        try:
            value["allowed_data_classes"] = _csv_classes(_ask(input_fn, "Erlaubte Datenklassen, komma-separiert", ",".join(value["allowed_data_classes"])))
            break
        except ConfigurationError as exc:
            output_fn(str(exc))
    value["allow_remote_models"] = _ask_bool(input_fn, "Ollama-Cloud-Tags grundsätzlich zulassen?", value["allow_remote_models"])
    if value["allow_remote_models"] or value["execution_boundary"] in {"LOCAL_NETWORK", "REMOTE", "UNKNOWN"}:
        while True:
            try:
                default_remote = ",".join(value["remote_data_classes"]) or "PUBLIC"
                value["remote_data_classes"] = _csv_classes(_ask(input_fn, "Datenklassen über diese Grenze", default_remote))
                break
            except ConfigurationError as exc:
                output_fn(str(exc))
    else:
        value["remote_data_classes"] = []
    selection = _ask_choice(input_fn, "Modellwahl", ["ROUTER", "MANUAL", "PINNED"], value["model_selection"]["mode"])
    model = None
    if selection == "PINNED":
        model = _ask(input_fn, "Festes Modell", value["model_selection"].get("default_model") or "")
        if not model:
            raise ConfigurationError("PINNED_MODEL_REQUIRED", "a pinned model cannot be empty")
    value["model_selection"] = {"mode": selection, "default_model": model}
    value["timeout_seconds"] = float(_ask(input_fn, "Timeout in Sekunden", str(value["timeout_seconds"])))
    value["read_roots"] = [str(Path(_ask(input_fn, "Ordner für Eingabe-Handles", value["read_roots"][0])).resolve())]
    value["write_roots"] = [str(Path(_ask(input_fn, "Ordner für Ausgabe-Handles", value["write_roots"][0])).resolve())]
    source = _ask_choice(input_fn, "Credential-Quelle", ["NONE", "ENVIRONMENT", "DOTENV_REFERENCE"], value["credential"]["source"])
    if source == "NONE":
        value["credential"] = {"source": "NONE"}
    elif source == "ENVIRONMENT":
        source_name = _ask(input_fn, "Name der bestehenden Umgebungsvariable", value["credential"].get("source_name", "OLLAMA_API_KEY"))
        export_as = _ask(input_fn, "Für Adapter bereitstellen als", value["credential"].get("export_as", "OLLAMA_API_KEY"))
        value["credential"] = {"source": source, "source_name": source_name, "export_as": export_as}
    else:
        dotenv_path = _ask(input_fn, "Absoluter Pfad zur .env-Datei", value["credential"].get("path", ""))
        if not dotenv_path:
            raise ConfigurationError("DOTENV_PATH_REQUIRED", "dotenv reference path cannot be empty")
        key = _ask(input_fn, "Schlüssel in der .env-Datei", value["credential"].get("key", "OLLAMA"))
        export_as = _ask(input_fn, "Für Adapter bereitstellen als", value["credential"].get("export_as", "OLLAMA_API_KEY"))
        value["credential"] = {"source": source, "path": str(Path(dotenv_path).resolve()), "key": key, "export_as": export_as}
    return validate_connection(connection_id, value)


def interactive_configure(
    store: ConfigurationStore,
    *,
    input_fn: Callable[[str], str] = input,
    output_fn: Callable[[str], None] = print,
) -> dict[str, Any]:
    configuration = store.load_for_edit()
    if not configuration["connections"]:
        output_fn("Keine Runtime konfiguriert. Ich prüfe sichere lokale Standardadressen read-only.")
    discoveries = discover_candidates(probe=True)
    healthy = next((row for row in discoveries if row["state"] == "HEALTHY"), None)
    endpoint = healthy["endpoint"] if healthy else DEFAULT_OLLAMA_ENDPOINT
    if healthy:
        output_fn(f"Gefunden: Ollama {healthy.get('version') or 'Version unbekannt'} unter {endpoint}")
    else:
        output_fn(f"Kein erreichbarer lokaler Dienst gefunden; Vorschlag bleibt {endpoint}.")
    existing_ids = ", ".join(sorted(configuration["connections"])) or "keine"
    connection_id = _ask(input_fn, f"Verbindungs-ID (vorhanden: {existing_ids})", "ollama-local")
    if not CONNECTION_ID.fullmatch(connection_id):
        raise ConfigurationError("INVALID_CONNECTION_ID", "connection id is invalid")
    existing = configuration["connections"].get(connection_id)
    try:
        current = validate_connection(connection_id, existing) if existing is not None else _connection_defaults(store.path.parent, endpoint)
    except ConfigurationError as exc:
        output_fn(f"Vorhandene Verbindung {connection_id} ist ungültig ({exc.code}); sichere Standardwerte werden zur Reparatur vorgeschlagen.")
        current = _connection_defaults(store.path.parent, endpoint)
    while True:
        candidate = ask_connection(connection_id, current, input_fn, output_fn)
        output_fn(json.dumps(public_connection(connection_id, candidate), indent=2, ensure_ascii=False))
        while True:
            action = _ask_choice(input_fn, "Aktion", ["TEST", "SAVE", "BACK", "ABORT"], "TEST")
            if action == "TEST":
                result = execute_adapter(candidate, "probe", {})
                output_fn(json.dumps(result, indent=2, ensure_ascii=False))
                if result.get("health", {}).get("state") == "HEALTHY":
                    catalog = execute_adapter(candidate, "catalog", {})
                    names = sorted(
                        name for fragment in catalog.get("fragments", []) for name in fragment.get("models", {})
                    )
                    output_fn(f"Katalog erreichbar: {len(names)} Modelle" + (f" ({', '.join(names)})" if len(names) <= 12 else ""))
                continue
            if action == "SAVE":
                updated = deepcopy(configuration)
                updated["connections"][connection_id] = candidate
                return store.save(updated)
            if action == "BACK":
                current = candidate
                break
            return {"status": "ABORTED"}


def noninteractive_connection(args: argparse.Namespace, store: ConfigurationStore) -> dict[str, Any]:
    existing = store.load_for_edit()
    raw_current = existing["connections"].get(args.connection_id)
    try:
        current = validate_connection(args.connection_id, raw_current) if raw_current is not None else _connection_defaults(store.path.parent, args.endpoint or DEFAULT_OLLAMA_ENDPOINT)
    except ConfigurationError:
        current = _connection_defaults(store.path.parent, args.endpoint or DEFAULT_OLLAMA_ENDPOINT)
    value = deepcopy(current)
    for name in ("label", "adapter", "endpoint", "execution_boundary", "timeout_seconds"):
        supplied = getattr(args, name, None)
        if supplied is not None:
            value[name] = supplied
    if args.trust_loopback_host is not None:
        value["trust_loopback_host"] = args.trust_loopback_host
    if args.network_authorized is not None:
        value["network_authorized"] = args.network_authorized
    if args.allow_remote_models is not None:
        value["allow_remote_models"] = args.allow_remote_models
    if args.allowed_data_classes is not None:
        value["allowed_data_classes"] = args.allowed_data_classes
    if args.remote_data_classes is not None:
        value["remote_data_classes"] = args.remote_data_classes
    if args.read_root:
        value["read_roots"] = [str(Path(item).resolve()) for item in args.read_root]
    if args.write_root:
        value["write_roots"] = [str(Path(item).resolve()) for item in args.write_root]
    if args.selection:
        value["model_selection"] = {"mode": args.selection, "default_model": args.default_model}
    if args.credential_dotenv:
        value["credential"] = {
            "source": "DOTENV_REFERENCE", "path": str(Path(args.credential_dotenv).resolve()),
            "key": args.credential_key, "export_as": args.credential_export_as,
        }
    elif args.credential_environment:
        value["credential"] = {
            "source": "ENVIRONMENT", "source_name": args.credential_environment,
            "export_as": args.credential_export_as,
        }
    connection = validate_connection(args.connection_id, value)
    updated = deepcopy(existing)
    updated["connections"][args.connection_id] = connection
    return store.save(updated)


def output(value: Any) -> None:
    print(json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=None, help="External configuration path")
    sub = parser.add_subparsers(dest="command")
    sub.add_parser("status")
    sub.add_parser("list")
    sub.add_parser("discover").add_argument("--probe", action="store_true")
    configure = sub.add_parser("configure")
    configure.add_argument("--yes", action="store_true", help="Apply provided values without questions")
    configure.add_argument("--connection-id", default="ollama-local")
    configure.add_argument("--label")
    configure.add_argument("--adapter", choices=sorted(ADAPTERS))
    configure.add_argument("--endpoint")
    configure.add_argument("--execution-boundary", choices=sorted(BOUNDARIES))
    configure.add_argument("--trust-loopback-host", action=argparse.BooleanOptionalAction, default=None)
    configure.add_argument("--network-authorized", action=argparse.BooleanOptionalAction, default=None)
    configure.add_argument("--allow-remote-models", action=argparse.BooleanOptionalAction, default=None)
    configure.add_argument("--allowed-data-classes", nargs="+", choices=sorted(DATA_CLASSES))
    configure.add_argument("--remote-data-classes", nargs="*", choices=sorted(DATA_CLASSES))
    configure.add_argument("--read-root", action="append")
    configure.add_argument("--write-root", action="append")
    configure.add_argument("--timeout-seconds", type=float)
    configure.add_argument("--selection", choices=sorted(SELECTION_MODES))
    configure.add_argument("--default-model")
    configure.add_argument("--credential-environment")
    configure.add_argument("--credential-dotenv")
    configure.add_argument("--credential-key", default="OLLAMA")
    configure.add_argument("--credential-export-as", default="OLLAMA_API_KEY")
    for name in ("probe", "catalog"):
        command = sub.add_parser(name)
        command.add_argument("connection_id")
    remove = sub.add_parser("remove")
    remove.add_argument("connection_id")
    remove.add_argument("--yes", action="store_true")
    sub.add_parser("rollback")
    sub.add_parser("mcp")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    store = ConfigurationStore(args.config)
    command = args.command or "configure"
    try:
        if command == "configure":
            result = noninteractive_connection(args, store) if getattr(args, "yes", False) else interactive_configure(store)
        elif command == "status":
            statuses = store.connection_statuses()
            result = {
                "status": "CONFIGURED" if any(item["status"] == "CONFIGURED" for item in statuses) else "CONFIGURATION_REQUIRED",
                "configuration_path": str(store.path),
                "connections": statuses,
                "proposals": [] if any(item["status"] == "CONFIGURED" for item in statuses) else discover_candidates(probe=False),
            }
        elif command == "list":
            result = {"connections": store.connection_statuses()}
        elif command == "discover":
            result = {"status": "PROPOSALS_ONLY", "candidates": discover_candidates(probe=args.probe)}
        elif command in {"probe", "catalog"}:
            connection = store.load_connection(args.connection_id)
            result = execute_adapter(connection, command, {})
        elif command == "remove":
            configuration = store.load_for_edit()
            if args.connection_id not in configuration["connections"]:
                raise ConfigurationError("CONNECTION_NOT_FOUND", "connection is not configured")
            if not args.yes and input(f"Verbindung {args.connection_id} entfernen? [j/N]: ").strip().lower() not in {"j", "ja", "y", "yes"}:
                result = {"status": "ABORTED"}
            else:
                del configuration["connections"][args.connection_id]
                result = store.save(configuration)
        elif command == "rollback":
            result = store.rollback()
        else:
            from runtime_mcp import serve
            return serve(store)
        output(result)
        return 0
    except (AdapterError, ConfigurationError, OSError, ValueError) as exc:
        code = getattr(exc, "code", "OPERATION_FAILED")
        print(json.dumps({"status": "ERROR", "reason_code": code, "message": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

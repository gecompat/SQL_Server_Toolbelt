#!/usr/bin/env python3
"""Ollama, OpenAI-compatible HTTP, and shell-free command reference adapters."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import socket
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from adapter_protocol import AdapterError, serve


ROUTER_CONTRACT = "foundation-model-router/v2"
BOUNDARIES = {"PROCESS", "HOST", "LOCAL_NETWORK", "REMOTE", "UNKNOWN"}
DATA_CLASSES = {"PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"}


def now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def digest_bytes(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def digest(value: Any) -> str:
    return digest_bytes(canonical_json(value))


def required_keys(arguments: dict[str, Any], required: set[str], allowed: set[str]) -> None:
    missing = sorted(required - set(arguments))
    unknown = sorted(set(arguments) - allowed)
    if missing or unknown:
        detail = "missing=" + ",".join(missing) if missing else "unknown=" + ",".join(unknown)
        raise AdapterError("CONTRACT", "INVALID_ARGUMENTS", detail)


def safe_path(raw: Any, roots: list[Path], field: str) -> Path:
    if not isinstance(raw, str) or not raw:
        raise AdapterError("CONTRACT", "INVALID_HANDLE", f"{field} must be a non-empty file path")
    path = Path(raw).resolve()
    if not any(path == root or root in path.parents for root in roots):
        raise AdapterError("PERMISSION", "HANDLE_OUTSIDE_ALLOWED_ROOT", f"{field} is outside configured roots")
    return path


def atomic_write(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        try:
            Path(temporary).unlink()
        except FileNotFoundError:
            pass


def is_cloud_tag(name: str) -> bool:
    lowered = name.lower()
    return lowered.endswith("-cloud") or lowered.endswith(":cloud") or ":cloud-" in lowered


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req: Any, fp: Any, code: int, msg: str, headers: Any, newurl: str) -> None:
        return None


class HttpAdapter:
    def __init__(self, config: dict[str, Any]) -> None:
        allowed = {
            "provider", "endpoint", "execution_boundary", "trust_loopback_host", "network_authorized",
            "credential_env", "environment_allowlist", "allowed_data_classes", "read_roots", "write_roots",
            "remote_data_classes", "timeout_seconds", "health_ttl_seconds", "catalog_ttl_seconds", "allow_remote_models",
        }
        required_keys(config, {"provider", "endpoint", "execution_boundary", "network_authorized", "allowed_data_classes", "remote_data_classes", "read_roots", "write_roots"}, allowed)
        parsed = urllib.parse.urlparse(config["endpoint"])
        if parsed.scheme not in {"http", "https"} or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
            raise AdapterError("CONFIGURATION", "INVALID_ENDPOINT", "endpoint must be a credential-free HTTP(S) origin or path")
        self.endpoint = config["endpoint"].rstrip("/")
        self.origin = (parsed.scheme.lower(), parsed.hostname.lower(), parsed.port)
        boundary = config["execution_boundary"]
        if boundary not in BOUNDARIES:
            raise AdapterError("CONFIGURATION", "INVALID_BOUNDARY", "execution_boundary is invalid")
        loopback = parsed.hostname.lower() in {"localhost", "127.0.0.1", "::1"}
        if loopback and boundary == "HOST" and not config.get("trust_loopback_host", False):
            raise AdapterError("CONFIGURATION", "UNPROVEN_LOOPBACK_BOUNDARY", "loopback requires explicit host-boundary evidence")
        self.boundary = boundary
        self.provider = str(config["provider"])
        self.network_authorized = config["network_authorized"] is True
        self.credential_env = config.get("credential_env")
        env_allowlist = config.get("environment_allowlist", [])
        if not isinstance(env_allowlist, list) or any(not isinstance(item, str) or not item for item in env_allowlist):
            raise AdapterError("CONFIGURATION", "INVALID_ENV_ALLOWLIST", "environment_allowlist must be a string array")
        if self.credential_env is not None and self.credential_env not in env_allowlist:
            raise AdapterError("CONFIGURATION", "CREDENTIAL_NOT_ALLOWLISTED", "credential environment name is not allowlisted")
        if self.credential_env is not None and parsed.scheme != "https" and not (
            loopback and boundary == "HOST" and config.get("trust_loopback_host", False)
        ):
            raise AdapterError("CONFIGURATION", "INSECURE_CREDENTIAL_ENDPOINT", "credentials require HTTPS or an explicitly trusted host-local endpoint")
        data_classes = config["allowed_data_classes"]
        if not isinstance(data_classes, list) or not set(data_classes) <= DATA_CLASSES:
            raise AdapterError("CONFIGURATION", "INVALID_DATA_CLASSES", "allowed_data_classes is invalid")
        self.allowed_data_classes = set(data_classes)
        remote_classes = config["remote_data_classes"]
        if not isinstance(remote_classes, list) or not set(remote_classes) <= DATA_CLASSES:
            raise AdapterError("CONFIGURATION", "INVALID_REMOTE_DATA_CLASSES", "remote_data_classes is invalid")
        self.remote_data_classes = set(remote_classes)
        self.read_roots = [Path(item).resolve() for item in config["read_roots"]]
        self.write_roots = [Path(item).resolve() for item in config["write_roots"]]
        self.timeout = float(config.get("timeout_seconds", 15))
        self.health_ttl = int(config.get("health_ttl_seconds", 30))
        self.catalog_ttl = int(config.get("catalog_ttl_seconds", 300))
        self.allow_remote_models = config.get("allow_remote_models", False) is True
        self.opener = urllib.request.build_opener(NoRedirect)

    def _headers(self) -> dict[str, str]:
        headers = {"Accept": "application/json", "Content-Type": "application/json"}
        if self.credential_env:
            value = os.environ.get(self.credential_env)
            if not value:
                raise AdapterError("CREDENTIAL", "CREDENTIAL_UNAVAILABLE", "allowlisted credential is unavailable")
            headers["Authorization"] = "Bearer " + value
        return headers

    def _request(self, path: str, payload: dict[str, Any] | None = None) -> Any:
        if not self.network_authorized:
            raise AdapterError("PERMISSION", "NETWORK_NOT_AUTHORIZED", "HTTP adapter network access is not authorized")
        url = self.endpoint + path
        target = urllib.parse.urlparse(url)
        if (target.scheme.lower(), target.hostname.lower() if target.hostname else None, target.port) != self.origin:
            raise AdapterError("PERMISSION", "CROSS_ORIGIN_REQUEST", "adapter request escaped the configured endpoint origin")
        data = canonical_json(payload) if payload is not None else None
        request = urllib.request.Request(url, data=data, headers=self._headers(), method="POST" if data is not None else "GET")
        try:
            with self.opener.open(request, timeout=self.timeout) as response:
                body = response.read()
        except urllib.error.HTTPError as exc:
            error_class = "CREDENTIAL" if exc.code in {401, 403} else "PROTOCOL"
            raise AdapterError(error_class, f"HTTP_{exc.code}", "adapter endpoint returned an HTTP error", retryable=exc.code >= 500) from exc
        except (TimeoutError, socket.timeout) as exc:
            raise AdapterError("TIMEOUT", "HTTP_TIMEOUT", "adapter endpoint timed out", retryable=True) from exc
        except urllib.error.URLError as exc:
            if isinstance(exc.reason, (TimeoutError, socket.timeout)):
                raise AdapterError("TIMEOUT", "HTTP_TIMEOUT", "adapter endpoint timed out", retryable=True) from exc
            raise AdapterError("AVAILABILITY", "ENDPOINT_UNAVAILABLE", "adapter endpoint is unavailable", retryable=True) from exc
        try:
            return json.loads(body)
        except json.JSONDecodeError as exc:
            raise AdapterError("PROTOCOL", "INVALID_JSON_RESPONSE", "adapter endpoint returned invalid JSON") from exc

    def probe(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, set(), set())
        checked = now()
        try:
            self._probe_request()
        except AdapterError as exc:
            return {
                "health": {"state": "UNAVAILABLE", "checked_at": isoformat(checked), "expires_at": isoformat(checked + timedelta(seconds=self.health_ttl)), "reason_code": exc.code},
                "execution_boundary": self.boundary,
            }
        return {
            "health": {"state": "HEALTHY", "checked_at": isoformat(checked), "expires_at": isoformat(checked + timedelta(seconds=self.health_ttl)), "reason_code": "PROBE_SUCCEEDED"},
            "execution_boundary": self.boundary,
        }

    def cancel(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, {"operation_id"}, {"operation_id"})
        return {"operation_id": arguments["operation_id"], "status": "NOT_ACTIVE", "reason_code": "NO_MATCHING_IN_PROCESS_OPERATION"}

    def provision(self, arguments: dict[str, Any]) -> dict[str, Any]:
        raise AdapterError("CAPABILITY", "PROVISION_UNSUPPORTED", "this adapter does not provision runtimes")

    def _invoke_common(self, arguments: dict[str, Any], payload: dict[str, Any]) -> dict[str, Any]:
        required_keys(
            arguments,
            {"operation_id", "model", "data_class", "input_path", "output_path"},
            {"operation_id", "model", "data_class", "input_path", "output_path", "remote_authorized"},
        )
        if arguments["data_class"] not in self.allowed_data_classes:
            raise AdapterError("PERMISSION", "DATA_CLASS_NOT_AUTHORIZED", "data class is not authorized for this adapter")
        if self.boundary in {"LOCAL_NETWORK", "REMOTE", "UNKNOWN"} and arguments["data_class"] not in self.remote_data_classes:
            raise AdapterError("PERMISSION", "REMOTE_DATA_CLASS_NOT_AUTHORIZED", "data class is not authorized across this execution boundary")
        input_path = safe_path(arguments["input_path"], self.read_roots, "input_path")
        output_path = safe_path(arguments["output_path"], self.write_roots, "output_path")
        try:
            text = input_path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            raise AdapterError("INPUT", "INPUT_UNREADABLE", "input handle is unavailable or not UTF-8") from exc
        payload["model"] = arguments["model"]
        payload["messages"] = [{"role": "user", "content": text}]
        result = self._request(self.invoke_path, payload)
        body = canonical_json(result) + b"\n"
        atomic_write(output_path, body)
        actual_model = result.get("model") if isinstance(result, dict) else None
        if not isinstance(actual_model, str) or not actual_model:
            actual_model = None
        requested_model = arguments["model"]
        return {
            "status": "COMPLETED",
            "operation_id": arguments["operation_id"],
            "requested_model": requested_model,
            "actual_model": actual_model,
            "dispatch_status": (
                "REQUESTED_NOT_ATTESTED" if actual_model is None
                else "ACTUAL_MODEL_ATTESTED" if actual_model == requested_model
                else "ACTUAL_MODEL_DIFFERS"
            ),
            "output_sha256": digest_bytes(body),
            "output_bytes": len(body),
        }


class OllamaAdapter(HttpAdapter):
    invoke_path = "/api/chat"

    def _probe_request(self) -> Any:
        return self._request("/api/version")

    def catalog(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, set(), set())
        observed = now()
        payload = self._request("/api/tags")
        rows = payload.get("models") if isinstance(payload, dict) else None
        if not isinstance(rows, list):
            raise AdapterError("PROTOCOL", "INVALID_OLLAMA_CATALOG", "Ollama catalog has no models array")
        local: dict[str, Any] = {}
        cloud: dict[str, Any] = {}
        for row in rows:
            name = row.get("name") if isinstance(row, dict) else None
            if not isinstance(name, str) or not name:
                continue
            remote = is_cloud_tag(name)
            target = cloud if remote else local
            target[name] = {
                "model_id": name,
                "availability": "MISSING_PRICE" if remote else "AVAILABLE",
                "assessment": "UNASSESSED",
                "capabilities": ["text"],
                "context_window": None,
                "quality_prior": {"*": 0.5},
                "quality_provenance": "UNKNOWN",
                "supported_tiers": ["ECONOMICAL", "BALANCED", "FRONTIER"],
                "reasoning_efforts": ["low", "medium", "high"],
                "resource_estimate": {},
                "resource_provenance": "UNKNOWN",
                "pricing": None if remote else {"currency": "USD", "unit_tokens": 1000000, "base": {"input": 0, "cached_input": 0, "output": 0}, "schedules": []},
            }
        fragments = []
        for provider, boundary, models in (
            (self.provider + "-local", self.boundary, local),
            (self.provider + "-cloud-tags", "REMOTE", cloud),
        ):
            if not models:
                continue
            fragments.append(self._fragment(provider, boundary, observed, models))
        return {"fragments": fragments, "cloud_tags_never_local": True}

    def _fragment(self, provider: str, boundary: str, observed: datetime, models: dict[str, Any]) -> dict[str, Any]:
        return {
            "schema_version": 2,
            "contract": ROUTER_CONTRACT,
            "provider": provider,
            "adapter": "ollama-native/v1",
            "execution_boundary": boundary,
            "generated_at": isoformat(observed),
            "valid_until": isoformat(observed + timedelta(seconds=self.catalog_ttl)),
            "pricing_epoch": digest({name: item["pricing"] for name, item in models.items()}),
            "health": {"state": "HEALTHY", "checked_at": isoformat(observed), "expires_at": isoformat(observed + timedelta(seconds=self.health_ttl)), "reason_code": "CATALOG_SUCCEEDED"},
            "provenance": {"source": self.endpoint + "/api/tags", "observed_at": isoformat(observed)},
            "models": models,
        }

    def invoke(self, arguments: dict[str, Any]) -> dict[str, Any]:
        model_name = arguments.get("model")
        if isinstance(model_name, str) and is_cloud_tag(model_name):
            if (
                not self.allow_remote_models
                or arguments.get("remote_authorized") is not True
                or arguments.get("data_class") not in self.remote_data_classes
            ):
                raise AdapterError("PERMISSION", "OLLAMA_CLOUD_NOT_AUTHORIZED", "Ollama cloud-tag invocation requires explicit remote authorization")
        return self._invoke_common(arguments, {"stream": False})


class OpenAICompatibleAdapter(HttpAdapter):
    invoke_path = "/v1/chat/completions"

    def _probe_request(self) -> Any:
        return self._request("/v1/models")

    def catalog(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, set(), set())
        observed = now()
        payload = self._request("/v1/models")
        rows = payload.get("data") if isinstance(payload, dict) else None
        if not isinstance(rows, list):
            raise AdapterError("PROTOCOL", "INVALID_OPENAI_CATALOG", "OpenAI-compatible catalog has no data array")
        remote = self.boundary in {"LOCAL_NETWORK", "REMOTE", "UNKNOWN"}
        models: dict[str, Any] = {}
        for row in rows:
            model_id = row.get("id") if isinstance(row, dict) else None
            if not isinstance(model_id, str) or not model_id:
                continue
            models[model_id] = {
                "model_id": model_id,
                "availability": "MISSING_PRICE" if remote else "AVAILABLE",
                "assessment": "UNASSESSED",
                "capabilities": ["text"],
                "context_window": None,
                "quality_prior": {"*": 0.5},
                "quality_provenance": "UNKNOWN",
                "supported_tiers": ["ECONOMICAL", "BALANCED", "FRONTIER"],
                "reasoning_efforts": ["low", "medium", "high"],
                "resource_estimate": {},
                "resource_provenance": "UNKNOWN",
                "pricing": None if remote else {"currency": "USD", "unit_tokens": 1000000, "base": {"input": 0, "cached_input": 0, "output": 0}, "schedules": []},
            }
        fragment = {
            "schema_version": 2,
            "contract": ROUTER_CONTRACT,
            "provider": self.provider,
            "adapter": "openai-compatible-http/v1",
            "execution_boundary": self.boundary,
            "generated_at": isoformat(observed),
            "valid_until": isoformat(observed + timedelta(seconds=self.catalog_ttl)),
            "pricing_epoch": digest({name: item["pricing"] for name, item in models.items()}),
            "health": {"state": "HEALTHY", "checked_at": isoformat(observed), "expires_at": isoformat(observed + timedelta(seconds=self.health_ttl)), "reason_code": "CATALOG_SUCCEEDED"},
            "provenance": {"source": self.endpoint + "/v1/models", "observed_at": isoformat(observed)},
            "models": models,
        }
        return {"fragments": [fragment]}

    def invoke(self, arguments: dict[str, Any]) -> dict[str, Any]:
        return self._invoke_common(arguments, {"stream": False})


class CommandAdapter:
    def __init__(self, config: dict[str, Any]) -> None:
        allowed = {
            "provider", "execution_boundary", "probe_argv", "catalog_argv", "invoke_argv", "environment_allowlist",
            "timeout_seconds", "allowed_data_classes", "read_roots", "write_roots", "cwd",
        }
        required_keys(config, {"provider", "execution_boundary", "probe_argv", "catalog_argv", "invoke_argv", "environment_allowlist", "allowed_data_classes", "read_roots", "write_roots"}, allowed)
        if config["execution_boundary"] not in {"PROCESS", "HOST"}:
            raise AdapterError("CONFIGURATION", "INVALID_COMMAND_BOUNDARY", "command adapter boundary must be PROCESS or HOST")
        self.provider = config["provider"]
        self.boundary = config["execution_boundary"]
        self.probe_argv = self._argv(config["probe_argv"], "probe_argv")
        self.catalog_argv = self._argv(config["catalog_argv"], "catalog_argv")
        self.invoke_argv = self._argv(config["invoke_argv"], "invoke_argv")
        allowlist = config["environment_allowlist"]
        if not isinstance(allowlist, list) or any(not isinstance(item, str) or not item for item in allowlist):
            raise AdapterError("CONFIGURATION", "INVALID_ENV_ALLOWLIST", "environment_allowlist must contain names")
        self.environment = {name: os.environ[name] for name in allowlist if name in os.environ}
        self.data_classes = set(config["allowed_data_classes"])
        if not self.data_classes <= DATA_CLASSES:
            raise AdapterError("CONFIGURATION", "INVALID_DATA_CLASSES", "allowed_data_classes is invalid")
        self.read_roots = [Path(item).resolve() for item in config["read_roots"]]
        self.write_roots = [Path(item).resolve() for item in config["write_roots"]]
        self.timeout = float(config.get("timeout_seconds", 15))
        self.cwd = Path(config["cwd"]).resolve() if config.get("cwd") else None

    @staticmethod
    def _argv(value: Any, field: str) -> list[str]:
        if not isinstance(value, list) or not value or any(not isinstance(item, str) or not item for item in value):
            raise AdapterError("CONFIGURATION", "INVALID_ARGV", f"{field} must be a non-empty string array")
        if not Path(value[0]).is_absolute():
            raise AdapterError("CONFIGURATION", "EXECUTABLE_NOT_ABSOLUTE", f"{field} executable must be an absolute path")
        return list(value)

    def _run(self, argv: list[str], *, stdin: Any = subprocess.DEVNULL, stdout: Any = subprocess.PIPE) -> subprocess.CompletedProcess[bytes]:
        try:
            return subprocess.run(argv, stdin=stdin, stdout=stdout, stderr=subprocess.PIPE, cwd=self.cwd, env=self.environment, timeout=self.timeout, check=False, shell=False)
        except subprocess.TimeoutExpired as exc:
            raise AdapterError("TIMEOUT", "COMMAND_TIMEOUT", "command adapter timed out", retryable=True) from exc
        except OSError as exc:
            raise AdapterError("AVAILABILITY", "COMMAND_UNAVAILABLE", "command adapter executable is unavailable", retryable=True) from exc

    def probe(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, set(), set())
        checked = now()
        result = self._run(self.probe_argv)
        state = "HEALTHY" if result.returncode == 0 else "UNAVAILABLE"
        return {"health": {"state": state, "checked_at": isoformat(checked), "expires_at": isoformat(checked + timedelta(seconds=30)), "reason_code": "EXIT_0" if result.returncode == 0 else "NONZERO_EXIT"}, "execution_boundary": self.boundary}

    def catalog(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, set(), set())
        result = self._run(self.catalog_argv)
        if result.returncode != 0:
            raise AdapterError("PROTOCOL", "CATALOG_COMMAND_FAILED", "catalog command returned non-zero")
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise AdapterError("PROTOCOL", "INVALID_CATALOG_JSON", "catalog command returned invalid JSON") from exc
        if not isinstance(payload, dict) or set(payload) != {"fragments"} or not isinstance(payload["fragments"], list):
            raise AdapterError("PROTOCOL", "INVALID_CATALOG_SHAPE", "catalog command must return only a fragments array")
        return payload

    def invoke(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, {"operation_id", "data_class", "input_path", "output_path"}, {"operation_id", "data_class", "input_path", "output_path", "model"})
        if arguments["data_class"] not in self.data_classes:
            raise AdapterError("PERMISSION", "DATA_CLASS_NOT_AUTHORIZED", "data class is not authorized for this command")
        input_path = safe_path(arguments["input_path"], self.read_roots, "input_path")
        output_path = safe_path(arguments["output_path"], self.write_roots, "output_path")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        descriptor, temporary = tempfile.mkstemp(prefix=output_path.name + ".", suffix=".tmp", dir=output_path.parent)
        os.close(descriptor)
        try:
            replacements = {
                "{input_path}": str(input_path),
                "{output_path}": temporary,
                "{model}": str(arguments.get("model", "")),
                "{operation_id}": str(arguments["operation_id"]),
            }
            argv = []
            for item in self.invoke_argv:
                if "{" in item and item not in replacements:
                    raise AdapterError("CONFIGURATION", "PARTIAL_PLACEHOLDER", "command placeholders must occupy a whole argument")
                argv.append(replacements.get(item, item))
            with input_path.open("rb") as source, Path(temporary).open("wb") as destination:
                result = self._run(argv, stdin=source, stdout=destination)
            if result.returncode != 0:
                raise AdapterError("PROTOCOL", "INVOKE_COMMAND_FAILED", "invoke command returned non-zero")
            os.replace(temporary, output_path)
        except Exception:
            try:
                Path(temporary).unlink()
            except FileNotFoundError:
                pass
            raise
        body = output_path.read_bytes()
        return {"status": "COMPLETED", "operation_id": arguments["operation_id"], "output_sha256": digest_bytes(body), "output_bytes": len(body)}

    def cancel(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, {"operation_id"}, {"operation_id"})
        return {"operation_id": arguments["operation_id"], "status": "NOT_ACTIVE", "reason_code": "NO_MATCHING_IN_PROCESS_OPERATION"}

    def provision(self, arguments: dict[str, Any]) -> dict[str, Any]:
        raise AdapterError("CAPABILITY", "PROVISION_UNSUPPORTED", "command adapter does not provision runtimes")


def load_config(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise AdapterError("CONFIGURATION", "CONFIG_UNREADABLE", "adapter config is unavailable or invalid") from exc
    if not isinstance(value, dict):
        raise AdapterError("CONFIGURATION", "CONFIG_INVALID", "adapter config must be an object")
    return value


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("adapter", choices=["ollama", "openai-compatible", "command"])
    parser.add_argument("--config", required=True)
    args = parser.parse_args(argv)
    try:
        config = load_config(Path(args.config))
        adapter = OllamaAdapter(config) if args.adapter == "ollama" else OpenAICompatibleAdapter(config) if args.adapter == "openai-compatible" else CommandAdapter(config)
        return serve(adapter)
    except AdapterError as exc:
        print(json.dumps({"status": "ERROR", "error": {"class": exc.error_class, "code": exc.code, "message": str(exc)}}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Bounded, shell-free client for explicitly configured JSONL adapter programs."""

from __future__ import annotations

import json
import os
import subprocess
import threading
import time
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from adapter_protocol import AdapterError, CONTRACT, OPERATIONS, _content_free
from reference_adapters import canonical_json, isoformat, now, required_keys


MAX_FRAME_BYTES = 1024 * 1024
MAX_STDERR_BYTES = 64 * 1024
MAX_REQUEST_BYTES = 64 * 1024
MAX_HANDLE_BYTES = 64 * 1024 * 1024


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate key")
        result[key] = value
    return result


def _reject_constant(value: str) -> None:
    raise ValueError("non-finite JSON number")


class StdioAdapter:
    """Transport boundaries are assertions about the backend, not a process sandbox."""

    def __init__(self, config: dict[str, Any]) -> None:
        self.config = config
        self.argv = config["argv"]
        self.boundary = config["execution_boundary"]
        self.timeout = float(config["timeout_seconds"])
        self.read_roots = [Path(item).resolve() for item in config["read_roots"]]
        self.write_roots = [Path(item).resolve() for item in config["write_roots"]]

    def _call(self, operation: str, arguments: dict[str, Any]) -> dict[str, Any]:
        if operation not in OPERATIONS:
            raise AdapterError("CONTRACT", "INVALID_OPERATION", "operation is unsupported")
        if self.boundary != "HOST" and not self.config["network_authorized"]:
            raise AdapterError("PERMISSION", "NETWORK_NOT_AUTHORIZED", "backend network access is not authorized")
        request_id = str(uuid.uuid4())
        frame = canonical_json({"protocol": CONTRACT, "request_id": request_id, "operation": operation, "arguments": arguments}) + b"\n"
        if len(frame) > MAX_REQUEST_BYTES:
            raise AdapterError("CONTRACT", "REQUEST_TOO_LARGE", "control request exceeds the size limit")
        environment = {name: os.environ[name] for name in self.config["environment_allowlist"] if name in os.environ}
        deadline = time.monotonic() + self.timeout
        try:
            process = subprocess.Popen(self.argv, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, env=environment, cwd=self.config.get("cwd"))
        except OSError as exc:
            raise AdapterError("AVAILABILITY", "PROGRAM_UNAVAILABLE", "configured program could not be started") from exc
        output = bytearray()
        overflow = threading.Event()
        io_failed = threading.Event()

        def read_pipe(pipe: Any, limit: int, target: bytearray | None) -> None:
            count = 0
            try:
                while True:
                    chunk = pipe.read1(min(8192, limit - count + 1))
                    if not chunk:
                        break
                    count += len(chunk)
                    if count > limit:
                        overflow.set()
                        break
                    if target is not None:
                        target.extend(chunk)
            except (OSError, ValueError):
                io_failed.set()
            finally:
                pipe.close()

        def write_frame() -> None:
            try:
                process.stdin.write(frame)
                process.stdin.close()
            except (OSError, ValueError):
                io_failed.set()

        workers = [threading.Thread(target=read_pipe, args=(process.stdout, MAX_FRAME_BYTES, output), daemon=True),
                   threading.Thread(target=read_pipe, args=(process.stderr, MAX_STDERR_BYTES, None), daemon=True),
                   threading.Thread(target=write_frame, daemon=True)]
        for worker in workers:
            worker.start()
        failure: AdapterError | None = None
        while process.poll() is None or any(worker.is_alive() for worker in workers):
            if overflow.is_set():
                failure = AdapterError("PROTOCOL", "OUTPUT_TOO_LARGE", "adapter control output exceeds the size limit")
                break
            if time.monotonic() >= deadline:
                failure = AdapterError("TIMEOUT", "STDIO_TIMEOUT", "adapter program timed out; reconcile any operation before retry")
                break
            time.sleep(0.01)
        if failure is not None:
            if process.poll() is None:
                process.kill()
            process.wait()
            for worker in workers:
                worker.join(0.1)
            raise failure
        if overflow.is_set():
            raise AdapterError("PROTOCOL", "OUTPUT_TOO_LARGE", "adapter control output exceeds the size limit")
        if process.returncode != 0 or io_failed.is_set():
            raise AdapterError("PROTOCOL", "PROGRAM_FAILED", "adapter program failed; operation outcome may be ambiguous")
        try:
            lines = bytes(output).decode("utf-8").splitlines()
            if len(lines) != 1:
                raise ValueError("expected one frame")
            response = json.loads(lines[0], object_pairs_hook=_unique_object, parse_constant=_reject_constant)
            if not isinstance(response, dict) or response.get("protocol") != CONTRACT or response.get("request_id") != request_id:
                raise ValueError("frame identity mismatch")
            if response.get("status") == "ERROR":
                error = response.get("error")
                if set(response) != {"protocol", "request_id", "status", "error"} or not isinstance(error, dict) or set(error) != {"class", "code", "message", "retryable"}:
                    raise ValueError("invalid error envelope")
                # A child error does not prove invocation never happened. Do not relay child text.
                raise AdapterError("PROTOCOL", "ADAPTER_REPORTED_ERROR", "adapter reported an error; reconcile any operation before retry")
            result = response.get("result")
            if response.get("status") != "OK" or set(response) != {"protocol", "request_id", "status", "result"} or not isinstance(result, dict):
                raise ValueError("invalid success envelope")
            if not _content_free(result):
                raise AdapterError("PROTOCOL", "CONTENT_IN_CONTROL_PLANE", "adapter returned payload fields in control output")
            return result
        except (UnicodeError, ValueError, RecursionError) as exc:
            raise AdapterError("PROTOCOL", "INVALID_RESPONSE", "adapter returned an invalid or mismatched JSONL frame") from exc

    def probe(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, set(), set())
        result = self._call("probe", {})
        health = result.get("health")
        if not isinstance(health, dict) or not isinstance(health.get("state"), str) or health["state"] not in {"HEALTHY", "DEGRADED", "UNAVAILABLE", "UNKNOWN"}:
            raise AdapterError("PROTOCOL", "INVALID_HEALTH", "adapter health result is invalid")
        observed = now()
        return {"health": {"state": health["state"], "checked_at": isoformat(observed),
                           "expires_at": isoformat(observed + timedelta(seconds=self.config["health_ttl_seconds"])),
                           "reason_code": "STDIO_PROBE"}, "execution_boundary": self.boundary}

    def catalog(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, set(), set())
        result = self._call("catalog", {})
        fragments = result.get("fragments")
        if not isinstance(fragments, list) or any(not isinstance(item, dict) or not isinstance(item.get("models"), dict)
            or any(not isinstance(model, dict) for model in item["models"].values()) for item in fragments):
            raise AdapterError("PROTOCOL", "INVALID_CATALOG", "adapter catalog must contain model fragments")
        # Preserve stale expiry and unknown evidence; never promote backend locality.
        ranks = {"HOST": 0, "LOCAL_NETWORK": 1, "REMOTE": 2, "UNKNOWN": 3}
        observed = now()
        for fragment in fragments:
            boundary = fragment.get("execution_boundary")
            if not isinstance(boundary, str) or boundary not in ranks or ranks[boundary] > ranks[self.boundary]:
                raise AdapterError("PROTOCOL", "CATALOG_BOUNDARY_MISMATCH", "catalog backend exceeds the configured boundary; repair configuration")
            fragment["execution_boundary"] = self.boundary
            try:
                expiry = datetime.fromisoformat(fragment["valid_until"].replace("Z", "+00:00"))
                health = fragment["health"]
                health_expiry = datetime.fromisoformat(health["expires_at"].replace("Z", "+00:00"))
                fragment["valid_until"] = isoformat(min(expiry, observed + timedelta(seconds=self.config["catalog_ttl_seconds"])))
                health["expires_at"] = isoformat(min(health_expiry, observed + timedelta(seconds=self.config["health_ttl_seconds"])))
            except (KeyError, TypeError, ValueError, AttributeError) as exc:
                raise AdapterError("PROTOCOL", "INVALID_CATALOG", "catalog expiry or health metadata is invalid") from exc
        return {"fragments": fragments}

    def invoke(self, arguments: dict[str, Any]) -> dict[str, Any]:
        # SC-010 bleibt maßgeblich: die neue pfadbasierte IPC-Lane ist kein
        # gepinnter Handletransport. Vor jedem Handlezugriff/Dispatch ablehnen.
        raise AdapterError("CAPABILITY", "TOOLBELT_STDIO_INVOKE_UNAVAILABLE",
                           "Toolbelt requires a separately validated pinned-handle transport for Stdio invocation")

    def cancel(self, arguments: dict[str, Any]) -> dict[str, Any]:
        required_keys(arguments, {"operation_id"}, {"operation_id"})
        return self._call("cancel", arguments)

    def provision(self, arguments: dict[str, Any]) -> dict[str, Any]:
        raise AdapterError("CAPABILITY", "PROVISION_UNSUPPORTED", "use the separately authorized provisioning capability")

#!/usr/bin/env python3
"""Language-neutral JSONL/stdio protocol runner for optional AI work adapters."""

from __future__ import annotations

import json
import sys
import time
from dataclasses import dataclass
from typing import Any, TextIO


CONTRACT = "foundation-ai-adapter-jsonl/v1"
OPERATIONS = {"probe", "catalog", "invoke", "cancel", "provision"}
FORBIDDEN_RESULT_KEYS = {"prompt", "response", "content", "secret", "credential", "token"}


class AdapterError(RuntimeError):
    def __init__(self, error_class: str, code: str, message: str, *, retryable: bool = False) -> None:
        super().__init__(message)
        self.error_class = error_class
        self.code = code
        self.retryable = retryable


@dataclass
class CircuitBreaker:
    failure_threshold: int = 3
    cooldown_seconds: float = 30.0
    consecutive_failures: int = 0
    open_until: float = 0.0

    def before_call(self) -> None:
        if time.monotonic() < self.open_until:
            raise AdapterError("AVAILABILITY", "CIRCUIT_OPEN", "adapter circuit is temporarily open", retryable=True)

    def success(self) -> None:
        self.consecutive_failures = 0
        self.open_until = 0.0

    def failure(self) -> None:
        self.consecutive_failures += 1
        if self.consecutive_failures >= self.failure_threshold:
            self.open_until = time.monotonic() + self.cooldown_seconds


def _content_free(value: Any) -> bool:
    if isinstance(value, dict):
        return not (set(value) & FORBIDDEN_RESULT_KEYS) and all(_content_free(item) for item in value.values())
    if isinstance(value, list):
        return all(_content_free(item) for item in value)
    return True


class ProtocolServer:
    def __init__(self, adapter: Any, breaker: CircuitBreaker | None = None) -> None:
        self.adapter = adapter
        self.breaker = breaker or CircuitBreaker()

    @staticmethod
    def error(request_id: Any, exc: AdapterError) -> dict[str, Any]:
        return {
            "protocol": CONTRACT,
            "request_id": request_id if isinstance(request_id, str) else None,
            "status": "ERROR",
            "error": {
                "class": exc.error_class,
                "code": exc.code,
                "message": str(exc),
                "retryable": exc.retryable,
            },
        }

    def handle(self, frame: Any) -> dict[str, Any]:
        request_id = frame.get("request_id") if isinstance(frame, dict) else None
        try:
            if not isinstance(frame, dict) or set(frame) != {"protocol", "request_id", "operation", "arguments"}:
                raise AdapterError("CONTRACT", "INVALID_FRAME", "request must contain only protocol, request_id, operation, and arguments")
            if frame["protocol"] != CONTRACT:
                raise AdapterError("CONTRACT", "UNSUPPORTED_PROTOCOL", f"protocol must be {CONTRACT}")
            if not isinstance(frame["request_id"], str) or not frame["request_id"]:
                raise AdapterError("CONTRACT", "INVALID_REQUEST_ID", "request_id must be a non-empty string")
            operation = frame["operation"]
            arguments = frame["arguments"]
            if operation not in OPERATIONS or not isinstance(arguments, dict):
                raise AdapterError("CONTRACT", "INVALID_OPERATION", "operation or arguments is invalid")
            if operation not in {"cancel", "probe"}:
                self.breaker.before_call()
            method = getattr(self.adapter, operation, None)
            if method is None:
                raise AdapterError("CAPABILITY", "OPERATION_UNSUPPORTED", f"adapter does not support {operation}")
            result = method(arguments)
            if not isinstance(result, dict) or not _content_free(result):
                raise AdapterError("CONTRACT", "CONTENT_IN_CONTROL_PLANE", "adapter result must be a content-free object")
            if operation not in {"cancel", "probe"}:
                self.breaker.success()
            return {"protocol": CONTRACT, "request_id": frame["request_id"], "status": "OK", "result": result}
        except AdapterError as exc:
            operation = frame.get("operation") if isinstance(frame, dict) else None
            if operation not in {"cancel", "probe"}:
                if exc.error_class in {"AVAILABILITY", "TIMEOUT", "PROTOCOL"}:
                    self.breaker.failure()
            return self.error(request_id, exc)
        except Exception:
            self.breaker.failure()
            return self.error(request_id, AdapterError("INTERNAL", "ADAPTER_FAILURE", "adapter failed without exposing internal details", retryable=False))


def serve(adapter: Any, input_stream: TextIO = sys.stdin, output_stream: TextIO = sys.stdout) -> int:
    server = ProtocolServer(adapter)
    for line in input_stream:
        try:
            frame = json.loads(line)
        except json.JSONDecodeError:
            result = server.error(None, AdapterError("CONTRACT", "INVALID_JSON", "input line is not valid JSON"))
        else:
            result = server.handle(frame)
        output_stream.write(json.dumps(result, sort_keys=True, ensure_ascii=False) + "\n")
        output_stream.flush()
    return 0

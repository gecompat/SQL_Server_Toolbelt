#!/usr/bin/env python3
"""Failure-isolated stdio MCP bridge for configured AI runtime adapters."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from adapter_protocol import AdapterError
from runtime_configuration import (
    ConfigurationError,
    ConfigurationStore,
    discover_candidates,
    execute_adapter,
    public_connection,
)
from reference_adapters import is_cloud_tag


LATEST_PROTOCOL = "2025-06-18"
SUPPORTED_PROTOCOLS = {LATEST_PROTOCOL, "2025-03-26", "2024-11-05"}
SERVER_VERSION = "1.0.0"
MAX_MESSAGE_BYTES = 1024 * 1024


def response(request_id: Any, result: dict[str, Any]) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def error_response(request_id: Any, code: int, message: str) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def tool_result(value: dict[str, Any]) -> dict[str, Any]:
    rendered = json.dumps(value, sort_keys=True, ensure_ascii=False)
    return {"content": [{"type": "text", "text": rendered}], "structuredContent": value, "isError": False}


def tool_error(code: str, message: str) -> dict[str, Any]:
    value = {"status": "ERROR", "reason_code": code, "message": message}
    return {
        "content": [{"type": "text", "text": json.dumps(value, sort_keys=True, ensure_ascii=False)}],
        "structuredContent": value,
        "isError": True,
    }


def tools() -> list[dict[str, Any]]:
    connection_property = {"connection_id": {"type": "string", "description": "Configured runtime connection id"}}
    return [
        {
            "name": "runtime_configuration_status",
            "description": "List valid and invalid runtime connections. With no configuration, return safe unverified defaults and the external setup command; never writes configuration.",
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        {
            "name": "runtime_discover",
            "description": "Read-only bounded discovery of local Ollama defaults. Non-loopback OLLAMA_HOST values are not probed without separate authorization.",
            "inputSchema": {
                "type": "object",
                "properties": {"probe": {"type": "boolean", "default": True}},
                "additionalProperties": False,
            },
        },
        {
            "name": "runtime_probe",
            "description": "Probe one configured runtime without invoking a model.",
            "inputSchema": {
                "type": "object", "properties": connection_property,
                "required": ["connection_id"], "additionalProperties": False,
            },
        },
        {
            "name": "runtime_catalog",
            "description": "Read the model catalog of one configured runtime. Ollama cloud tags are always returned as REMOTE.",
            "inputSchema": {
                "type": "object", "properties": connection_property,
                "required": ["connection_id"], "additionalProperties": False,
            },
        },
        {
            "name": "runtime_invoke",
            "description": "Invoke an explicitly selected or pinned model through external input/output file handles. Generated content never enters the MCP control response.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    **connection_property,
                    "operation_id": {"type": "string"},
                    "model": {"type": "string", "description": "Explicit model from a router/manual choice; may be omitted only for a PINNED connection"},
                    "data_class": {"enum": ["PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"]},
                    "input_path": {"type": "string", "description": "UTF-8 input handle inside an allowlisted read root"},
                    "output_path": {"type": "string", "description": "Output handle inside an allowlisted write root"},
                    "remote_authorized": {"type": "boolean", "default": False},
                },
                "required": ["connection_id", "operation_id", "data_class", "input_path", "output_path"],
                "additionalProperties": False,
            },
        },
    ]


def _exact_arguments(arguments: dict[str, Any], required: set[str], allowed: set[str]) -> None:
    if set(arguments) - allowed or required - set(arguments):
        raise ConfigurationError("INVALID_ARGUMENTS", "tool arguments are missing or unknown")


def _configuration_status(store: ConfigurationStore) -> dict[str, Any]:
    statuses = store.connection_statuses()
    configured = any(item["status"] == "CONFIGURED" for item in statuses)
    return {
        "status": "CONFIGURED" if configured else "CONFIGURATION_REQUIRED",
        "configuration_path": str(store.path),
        "connections": statuses,
        "proposals": [] if configured else discover_candidates(probe=False),
        "next_action": None if configured else "RUN_CONFIGURATION_WIZARD",
        "configuration_command": None if configured else f'python "{Path(__file__).with_name("runtime_configuration.py")}" --config "{store.path}" configure',
    }


def call_tool(name: str, arguments: dict[str, Any], store: ConfigurationStore) -> dict[str, Any]:
    try:
        if name == "runtime_configuration_status":
            _exact_arguments(arguments, set(), set())
            return tool_result(_configuration_status(store))
        if name == "runtime_discover":
            _exact_arguments(arguments, set(), {"probe"})
            return tool_result({"status": "PROPOSALS_ONLY", "candidates": discover_candidates(probe=arguments.get("probe", True) is True)})
        if name in {"runtime_probe", "runtime_catalog"}:
            _exact_arguments(arguments, {"connection_id"}, {"connection_id"})
            connection = store.load_connection(arguments["connection_id"])
            operation = "probe" if name == "runtime_probe" else "catalog"
            value = execute_adapter(connection, operation, {})
            return tool_result({"connection_id": arguments["connection_id"], **value})
        if name == "runtime_invoke":
            required = {"connection_id", "operation_id", "data_class", "input_path", "output_path"}
            allowed = required | {"model", "remote_authorized"}
            _exact_arguments(arguments, required, allowed)
            connection_id = arguments["connection_id"]
            connection = store.load_connection(connection_id)
            selection = connection["model_selection"]
            model = arguments.get("model")
            selected_by = "EXPLICIT"
            if not isinstance(model, str) or not model:
                if selection["mode"] == "PINNED":
                    model = selection["default_model"]
                    selected_by = "PINNED_CONFIGURATION"
                else:
                    mode = selection["mode"]
                    raise ConfigurationError(
                        "MODEL_SELECTION_REQUIRED",
                        f"{mode} mode requires a router-selected or manually selected model",
                    )
            invocation = {
                "operation_id": arguments["operation_id"],
                "model": model,
                "data_class": arguments["data_class"],
                "input_path": arguments["input_path"],
                "output_path": arguments["output_path"],
                "remote_authorized": arguments.get("remote_authorized", False),
            }
            if connection["adapter"] == "ollama" and is_cloud_tag(model) and not arguments.get("remote_authorized", False):
                raise ConfigurationError("OLLAMA_CLOUD_NOT_AUTHORIZED", "cloud-tag invocation requires explicit remote_authorized=true")
            value = execute_adapter(connection, "invoke", invocation)
            return tool_result({"connection_id": connection_id, "selected_by": selected_by, **value})
        raise ConfigurationError("UNKNOWN_TOOL", "unknown runtime MCP tool")
    except (AdapterError, ConfigurationError, OSError, TypeError, ValueError) as exc:
        return tool_error(getattr(exc, "code", "OPERATION_FAILED"), str(exc))


def handle(message: dict[str, Any], store: ConfigurationStore) -> dict[str, Any] | None:
    if message.get("jsonrpc") != "2.0" or not isinstance(message.get("method"), str):
        return error_response(message.get("id"), -32600, "Invalid Request")
    request_id = message.get("id")
    if request_id is None:
        return None
    method = message["method"]
    if method == "initialize":
        params = message.get("params", {})
        requested = params.get("protocolVersion") if isinstance(params, dict) else None
        protocol = requested if requested in SUPPORTED_PROTOCOLS else LATEST_PROTOCOL
        return response(request_id, {
            "protocolVersion": protocol,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": "foundation-ai-runtime", "version": SERVER_VERSION},
            "instructions": "Discover and probe before invocation. Model, data boundary, handles, remote authority, and credentials remain explicit; run the wizard when configuration is required.",
        })
    if method == "ping":
        return response(request_id, {})
    if method == "tools/list":
        return response(request_id, {"tools": tools()})
    if method == "tools/call":
        params = message.get("params", {})
        if not isinstance(params, dict) or params.get("name") not in {item["name"] for item in tools()}:
            return error_response(request_id, -32602, "Invalid tools/call params")
        arguments = params.get("arguments", {})
        if not isinstance(arguments, dict):
            return error_response(request_id, -32602, "Tool arguments must be an object")
        return response(request_id, call_tool(params["name"], arguments, store))
    return error_response(request_id, -32601, "Method not found")


def serve(store: ConfigurationStore) -> int:
    """Serve MCP even when configuration is absent or a connection is invalid."""
    for raw_line in sys.stdin.buffer:
        if len(raw_line) > MAX_MESSAGE_BYTES:
            outgoing = error_response(None, -32700, "Message exceeds size limit")
        else:
            try:
                decoded = json.loads(raw_line.decode("utf-8"))
                outgoing = handle(decoded, store) if isinstance(decoded, dict) else error_response(None, -32600, "Invalid Request")
            except (UnicodeDecodeError, json.JSONDecodeError):
                outgoing = error_response(None, -32700, "Parse error")
            except Exception as exc:  # protocol containment; only exception class reaches stderr
                print(f"foundation-ai-runtime MCP internal error: {type(exc).__name__}", file=sys.stderr)
                outgoing = error_response(None, -32603, "Internal error")
        if outgoing is not None:
            sys.stdout.write(json.dumps(outgoing, separators=(",", ":"), ensure_ascii=False) + "\n")
            sys.stdout.flush()
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=None)
    args = parser.parse_args(argv)
    return serve(ConfigurationStore(args.config))


if __name__ == "__main__":
    raise SystemExit(main())

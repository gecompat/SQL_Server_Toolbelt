#!/usr/bin/env python3
"""Dependency-free MCP stdio adapter for the transport-neutral model router."""

from __future__ import annotations

import json
import sys
from decimal import Decimal
from pathlib import Path
from typing import Any

from model_router import ModelRouter, RouterError, RuntimeStore, decimal_value, load_json, validate_request


SERVER_VERSION = "1.0.0"
LATEST_PROTOCOL = "2025-11-25"
SUPPORTED_PROTOCOLS = {LATEST_PROTOCOL, "2025-06-18", "2025-03-26"}
MAX_MESSAGE_BYTES = 1024 * 1024


ROUTING_REQUEST_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "tier": {"type": "string", "enum": ["LOCAL", "ECONOMICAL", "BALANCED", "FRONTIER"]},
        "task_class": {"type": "string", "minLength": 1},
        "context_tokens": {"type": "integer", "minimum": 0},
        "cached_input_tokens": {"type": "integer", "minimum": 0},
        "expected_output_tokens": {"type": "integer", "minimum": 0},
        "required_capabilities": {"type": "array", "items": {"type": "string", "minLength": 1}, "uniqueItems": True},
        "allowed_providers": {"type": "array", "items": {"type": "string", "minLength": 1}, "uniqueItems": True},
        "allow_remote": {"type": "boolean", "default": False},
        "allow_evaluation": {"type": "boolean", "default": False},
        "allow_unknown_context": {"type": "boolean", "default": False},
        "quality_floor": {"type": "number", "minimum": 0, "maximum": 1},
        "max_cost_usd": {"type": "number", "minimum": 0},
        "failure_cost_usd": {"type": "number", "minimum": 0},
        "latency_value_usd_per_second": {"type": "number", "minimum": 0},
        "switching_cost_usd": {"type": "number", "minimum": 0},
        "session_id": {"type": "string", "minLength": 1},
        "current_provider": {"type": "string", "minLength": 1},
        "current_model": {"type": "string", "minLength": 1},
        "failed_models": {"type": "array", "items": {"type": "string", "minLength": 1}, "uniqueItems": True},
        "preferred_reasoning_effort": {"type": "string", "minLength": 1},
        "max_fallbacks": {"type": "integer", "minimum": 0},
        "at": {"type": "string", "format": "date-time"},
    },
    "required": ["tier", "task_class"],
    "additionalProperties": False,
}


def tools() -> list[dict[str, Any]]:
    return [
        {
            "name": "model_router_route",
            "title": "Choose a model route",
            "description": "Return a fresh provider-neutral route, budgets, fallback chain, and cost-of-success evidence without invoking a model.",
            "inputSchema": ROUTING_REQUEST_SCHEMA,
            "annotations": {"readOnlyHint": True, "idempotentHint": True, "openWorldHint": False},
        },
        {
            "name": "model_router_snapshot",
            "title": "Create an expiring routing snapshot",
            "description": "Return expiring LOCAL/ECONOMICAL/BALANCED/FRONTIER routes for clients that cannot call MCP later.",
            "inputSchema": ROUTING_REQUEST_SCHEMA,
            "annotations": {"readOnlyHint": True, "idempotentHint": True, "openWorldHint": False},
        },
        {
            "name": "model_router_plan_evaluation",
            "title": "Plan bounded model evaluation",
            "description": "Plan, and optionally reserve, cost-capped trials for newly discovered models; no model is invoked by this tool.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "request": ROUTING_REQUEST_SCHEMA,
                    "budget_usd": {"type": "number", "minimum": 0},
                    "max_candidates": {"type": "integer", "minimum": 1, "default": 1},
                    "task_set": {"type": "array", "items": {"type": "string", "minLength": 1}, "uniqueItems": True},
                    "planned_sample_count": {"type": "integer", "minimum": 1, "default": 1},
                    "stopping_rules": {"type": "object", "minProperties": 1},
                    "reserve": {"type": "boolean", "default": False},
                },
                "required": ["request", "budget_usd"],
                "additionalProperties": False,
            },
            "annotations": {"readOnlyHint": False, "idempotentHint": False, "openWorldHint": False},
        },
        {
            "name": "model_router_record_outcome",
            "title": "Record a routing outcome",
            "description": "Record success, cost, latency, and optional session affinity in the local non-versioned runtime store.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "provider": {"type": "string", "minLength": 1},
                    "model": {"type": "string", "minLength": 1},
                    "task_class": {"type": "string", "minLength": 1},
                    "success": {"type": "boolean"},
                    "actual_cost_usd": {"type": "number", "minimum": 0},
                    "latency_ms": {"type": "number", "minimum": 0},
                    "session_id": {"type": "string", "minLength": 1},
                    "context_tokens": {"type": "integer", "minimum": 0},
                    "pricing_epoch": {"type": "string", "minLength": 1},
                    "evaluation_id": {"type": "string", "minLength": 1},
                },
                "required": ["provider", "model", "task_class", "success"],
                "additionalProperties": False,
            },
            "annotations": {"readOnlyHint": False, "idempotentHint": False, "openWorldHint": False},
        },
    ]


def response(request_id: Any, result: Any) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def error_response(request_id: Any, code: int, message: str) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def tool_result(payload: dict[str, Any]) -> dict[str, Any]:
    compact = json.dumps(payload, sort_keys=True, ensure_ascii=False)
    return {
        "content": [{"type": "text", "text": compact}],
        "structuredContent": payload,
        "isError": False,
    }


def tool_error(message: str) -> dict[str, Any]:
    return {"content": [{"type": "text", "text": message}], "isError": True}


def call_tool(name: str, arguments: dict[str, Any], router: ModelRouter, store: RuntimeStore) -> dict[str, Any]:
    try:
        if name == "model_router_route":
            return tool_result(router.route(validate_request(arguments)))
        if name == "model_router_snapshot":
            return tool_result(router.snapshot(validate_request(arguments)))
        if name == "model_router_plan_evaluation":
            unknown = sorted(set(arguments) - {"request", "budget_usd", "max_candidates", "reserve", "task_set", "planned_sample_count", "stopping_rules"})
            if unknown:
                raise RouterError(f"unknown evaluation argument(s): {', '.join(unknown)}")
            request = arguments.get("request")
            if not isinstance(request, dict):
                raise RouterError("request must be an object")
            max_candidates = arguments.get("max_candidates", 1)
            if isinstance(max_candidates, bool) or not isinstance(max_candidates, int) or max_candidates < 1:
                raise RouterError("max_candidates must be a positive integer")
            budget = decimal_value(arguments.get("budget_usd"), "budget_usd", minimum=Decimal(0))
            reserve = arguments.get("reserve", False)
            if not isinstance(reserve, bool):
                raise RouterError("reserve must be boolean")
            return tool_result(
                router.plan_evaluation(
                    request,
                    budget_usd=budget,
                    max_candidates=max_candidates,
                    reserve=reserve,
                    task_set=arguments.get("task_set"),
                    planned_sample_count=arguments.get("planned_sample_count", 1),
                    stopping_rules=arguments.get("stopping_rules"),
                )
            )
        if name == "model_router_record_outcome":
            allowed = {
                "provider", "model", "task_class", "success", "actual_cost_usd", "latency_ms",
                "session_id", "context_tokens", "pricing_epoch", "evaluation_id",
            }
            unknown = sorted(set(arguments) - allowed)
            if unknown:
                raise RouterError(f"unknown outcome argument(s): {', '.join(unknown)}")
            required = ("provider", "model", "task_class", "success")
            if any(field not in arguments for field in required) or not isinstance(arguments["success"], bool):
                raise RouterError("provider, model, task_class, and boolean success are required")
            for field in ("provider", "model", "task_class"):
                if not isinstance(arguments[field], str) or not arguments[field]:
                    raise RouterError(f"{field} must be a non-empty string")
            for field in ("session_id", "pricing_epoch", "evaluation_id"):
                if field in arguments and (not isinstance(arguments[field], str) or not arguments[field]):
                    raise RouterError(f"{field} must be a non-empty string when provided")
            context_tokens = arguments.get("context_tokens", 0)
            if isinstance(context_tokens, bool) or not isinstance(context_tokens, int) or context_tokens < 0:
                raise RouterError("context_tokens must be a non-negative integer")
            cost = decimal_value(arguments.get("actual_cost_usd", 0), "actual_cost_usd", minimum=Decimal(0))
            latency = (
                decimal_value(arguments["latency_ms"], "latency_ms", minimum=Decimal(0))
                if "latency_ms" in arguments
                else None
            )
            row = store.record_outcome(
                provider=str(arguments["provider"]),
                model=str(arguments["model"]),
                task_class=str(arguments["task_class"]),
                success=arguments["success"],
                actual_cost_usd=cost,
                latency_ms=latency,
                session_id=arguments.get("session_id"),
                context_tokens=context_tokens,
                pricing_epoch=arguments.get("pricing_epoch"),
                evaluation_id=arguments.get("evaluation_id"),
            )
            return tool_result({"status": "RECORDED", "outcome": row})
        raise KeyError(name)
    except (ArithmeticError, OSError, RouterError, TypeError, ValueError) as exc:
        return tool_error(str(exc))


def handle(message: dict[str, Any], router: ModelRouter, store: RuntimeStore) -> dict[str, Any] | None:
    if message.get("jsonrpc") != "2.0" or not isinstance(message.get("method"), str):
        return error_response(message.get("id"), -32600, "Invalid Request")
    method = message["method"]
    request_id = message.get("id")
    if request_id is None:
        return None
    if method == "initialize":
        params = message.get("params", {})
        requested = params.get("protocolVersion") if isinstance(params, dict) else None
        protocol = requested if requested in SUPPORTED_PROTOCOLS else LATEST_PROTOCOL
        return response(
            request_id,
            {
                "protocolVersion": protocol,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": "ai-model-router", "version": SERVER_VERSION},
                "instructions": "Route only after project privacy/authorization checks. Prices and snapshots expire; do not treat them as durable policy.",
            },
        )
    if method == "ping":
        return response(request_id, {})
    if method == "tools/list":
        return response(request_id, {"tools": tools()})
    if method == "tools/call":
        params = message.get("params", {})
        if not isinstance(params, dict) or not isinstance(params.get("name"), str):
            return error_response(request_id, -32602, "Invalid tools/call params")
        arguments = params.get("arguments", {})
        if not isinstance(arguments, dict):
            return error_response(request_id, -32602, "Tool arguments must be an object")
        if params["name"] not in {row["name"] for row in tools()}:
            return error_response(request_id, -32602, f"Unknown tool: {params['name']}")
        return response(request_id, call_tool(params["name"], arguments, router, store))
    return error_response(request_id, -32601, f"Method not found: {method}")


def serve(*, catalog_path: Path, state_dir: Path) -> int:
    """Serve newline-delimited UTF-8 JSON-RPC; stdout is reserved for protocol frames."""
    try:
        store = RuntimeStore(state_dir)
        router = ModelRouter(load_json(catalog_path, "model catalog"), store)
        catalog_signature = (catalog_path.stat().st_mtime_ns, catalog_path.stat().st_size)
    except (OSError, RouterError) as exc:
        print(f"ai-model-router MCP startup failed: {exc}", file=sys.stderr)
        return 2
    for raw_line in sys.stdin.buffer:
        if len(raw_line) > MAX_MESSAGE_BYTES:
            outgoing = error_response(None, -32700, "Message exceeds size limit")
        else:
            try:
                decoded = json.loads(raw_line.decode("utf-8"))
                if not isinstance(decoded, dict):
                    outgoing = error_response(None, -32600, "Invalid Request")
                else:
                    if decoded.get("method") == "tools/call":
                        try:
                            current_signature = (catalog_path.stat().st_mtime_ns, catalog_path.stat().st_size)
                            if current_signature != catalog_signature:
                                router = ModelRouter(load_json(catalog_path, "model catalog"), store)
                                catalog_signature = current_signature
                        except (OSError, RouterError) as exc:
                            print(f"ai-model-router MCP catalog refresh rejected: {exc}", file=sys.stderr)
                    outgoing = handle(decoded, router, store)
            except (UnicodeDecodeError, json.JSONDecodeError):
                outgoing = error_response(None, -32700, "Parse error")
            except Exception as exc:  # bounded protocol containment; diagnostics remain on stderr
                print(f"ai-model-router MCP internal error: {type(exc).__name__}", file=sys.stderr)
                outgoing = error_response(None, -32603, "Internal error")
        if outgoing is not None:
            sys.stdout.write(json.dumps(outgoing, separators=(",", ":"), ensure_ascii=False) + "\n")
            sys.stdout.flush()
    return 0

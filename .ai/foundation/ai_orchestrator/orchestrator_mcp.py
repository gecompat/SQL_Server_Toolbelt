#!/usr/bin/env python3
"""Unconfigured-safe stdio MCP facade for the optional Foundation AI orchestrator."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from ai_orchestrator import OrchestrationError, default_state_dir, plan_or_execute, refresh_evidence


LATEST_PROTOCOL = "2025-06-18"
SUPPORTED_PROTOCOLS = {LATEST_PROTOCOL, "2025-03-26", "2024-11-05"}
MAX_MESSAGE_BYTES = 1024 * 1024


def tools() -> list[dict[str, Any]]:
    request = {"request": {"type": "object", "description": "foundation-ai-orchestration/v1 request with external content handles"}}
    return [
        {"name": "orchestration_status", "description": "Report external paths and optional configuration presence without probing or invoking anything.", "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}},
        {"name": "orchestration_plan", "description": "Refresh configured evidence when due, isolate live catalogs, and return a content-free route or truthful manual status.", "inputSchema": {"type": "object", "properties": request, "required": ["request"], "additionalProperties": False}},
        {"name": "orchestration_execute", "description": "Execute a routed bounded fallback chain through external handles and return only attestation, hashes, status, and validation metadata.", "inputSchema": {"type": "object", "properties": request, "required": ["request"], "additionalProperties": False}},
        {"name": "orchestration_refresh_evidence", "description": "Run exact configured evidence-source argv entries only when their at-most-daily limits permit.", "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}},
    ]


def tool_result(value: dict[str, Any], error: bool = False) -> dict[str, Any]:
    return {"content": [{"type": "text", "text": json.dumps(value, sort_keys=True, ensure_ascii=False)}], "structuredContent": value, "isError": error}


class Server:
    def __init__(self, *, config: Path | None, state_root: Path | None, evidence: Path | None, evidence_sources: Path | None) -> None:
        self.config = config.resolve() if config else None
        self.state_root = (state_root or default_state_dir()).resolve()
        self.evidence = evidence.resolve() if evidence else self.state_root / "model-runtime-evidence.json"
        self.evidence_sources = evidence_sources.resolve() if evidence_sources else None

    def call(self, name: str, arguments: dict[str, Any]) -> dict[str, Any]:
        try:
            if name == "orchestration_status" and not arguments:
                return tool_result({"status": "READY" if self.config and self.config.is_file() else "CONFIGURATION_REQUIRED", "runtime_configuration_path": str(self.config) if self.config else None, "evidence_path": str(self.evidence), "evidence_available": self.evidence.is_file(), "evidence_sources_path": str(self.evidence_sources) if self.evidence_sources else None, "evidence_sources_available": bool(self.evidence_sources and self.evidence_sources.is_file())})
            if name in {"orchestration_plan", "orchestration_execute"} and set(arguments) == {"request"}:
                return tool_result(plan_or_execute(arguments["request"], execute=name == "orchestration_execute", config_path=self.config, state_root=self.state_root, evidence_path=self.evidence, evidence_sources_path=self.evidence_sources))
            if name == "orchestration_refresh_evidence" and not arguments:
                if not self.evidence_sources:
                    raise OrchestrationError("EVIDENCE_SOURCES_UNAVAILABLE", "no external evidence source configuration is selected")
                return tool_result(refresh_evidence(self.evidence_sources, self.state_root))
            raise OrchestrationError("INVALID_ARGUMENTS", "tool arguments are missing or unknown")
        except (OrchestrationError, OSError, ValueError, TypeError) as exc:
            return tool_result({"status": "ERROR", "reason_code": getattr(exc, "code", "OPERATION_FAILED"), "message": str(exc)}, True)


def response(request_id: Any, result: dict[str, Any]) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def handle(message: dict[str, Any], server: Server) -> dict[str, Any] | None:
    if message.get("jsonrpc") != "2.0" or not isinstance(message.get("method"), str):
        return {"jsonrpc": "2.0", "id": message.get("id"), "error": {"code": -32600, "message": "Invalid Request"}}
    request_id = message.get("id")
    if request_id is None:
        return None
    if message["method"] == "initialize":
        params = message.get("params", {})
        requested = params.get("protocolVersion") if isinstance(params, dict) else None
        return response(request_id, {"protocolVersion": requested if requested in SUPPORTED_PROTOCOLS else LATEST_PROTOCOL, "capabilities": {"tools": {"listChanged": False}}, "serverInfo": {"name": "foundation-ai-orchestrator", "version": "1.0.0"}, "instructions": "Content uses external handles. Automatic routing requires fresh source-backed evidence; otherwise use the returned manual handoff."})
    if message["method"] == "ping":
        return response(request_id, {})
    if message["method"] == "tools/list":
        return response(request_id, {"tools": tools()})
    if message["method"] == "tools/call":
        params = message.get("params", {})
        if not isinstance(params, dict) or params.get("name") not in {item["name"] for item in tools()} or not isinstance(params.get("arguments", {}), dict):
            return {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32602, "message": "Invalid tools/call params"}}
        return response(request_id, server.call(params["name"], params.get("arguments", {})))
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32601, "message": "Method not found"}}


def serve(server: Server) -> int:
    for raw in sys.stdin.buffer:
        try:
            outgoing = handle(json.loads(raw.decode("utf-8")), server) if len(raw) <= MAX_MESSAGE_BYTES else {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Message exceeds size limit"}}
        except (UnicodeError, json.JSONDecodeError):
            outgoing = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Parse error"}}
        except Exception as exc:
            print(f"foundation-ai-orchestrator MCP internal error: {type(exc).__name__}", file=sys.stderr)
            outgoing = {"jsonrpc": "2.0", "id": None, "error": {"code": -32603, "message": "Internal error"}}
        if outgoing is not None:
            print(json.dumps(outgoing, separators=(",", ":"), ensure_ascii=False), flush=True)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path)
    parser.add_argument("--state-root", type=Path)
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--evidence-sources", type=Path)
    args = parser.parse_args(argv)
    return serve(Server(config=args.config, state_root=args.state_root, evidence=args.evidence, evidence_sources=args.evidence_sources))


if __name__ == "__main__":
    raise SystemExit(main())

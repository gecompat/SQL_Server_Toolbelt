#!/usr/bin/env python3
"""Optional end-to-end catalog, routing, invocation, validation, and fallback facade."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from copy import deepcopy
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


CONTRACT = "foundation-ai-orchestration/v1"
EVIDENCE_CONTRACT = "foundation-model-runtime-evidence/v1"
SOURCE_CONTRACT = "foundation-model-evidence-sources/v1"
PROFILE_FIELDS = {
    "assessment", "availability", "capabilities", "context_window", "latency_seconds_prior",
    "pricing", "quality_prior", "quality_provenance", "reasoning_efforts", "resource_cost",
    "resource_estimate", "resource_provenance", "supported_tiers",
}
STRONG_ALIAS_EVIDENCE = {"PROVIDER_DOCUMENTATION", "PROVIDER_SIGNED_METADATA"}
MIN_REFRESH_SECONDS = 86400
MAX_DOCUMENT_BYTES = 4 * 1024 * 1024


class OrchestrationError(RuntimeError):
    def __init__(self, code: str, message: str, error_class: str = "INPUT") -> None:
        super().__init__(message)
        self.code = code
        self.error_class = error_class


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_time(value: Any, field: str) -> datetime:
    if not isinstance(value, str):
        raise OrchestrationError("INVALID_EVIDENCE", f"{field} must be a timestamp")
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)
    except ValueError as exc:
        raise OrchestrationError("INVALID_EVIDENCE", f"{field} is invalid") from exc


def digest(value: Any) -> str:
    body = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return "sha256:" + hashlib.sha256(body).hexdigest()


def default_state_dir() -> Path:
    override = os.environ.get("AI_ORCHESTRATOR_HOME")
    if override:
        path = Path(override)
        if not path.is_absolute():
            raise OrchestrationError("STATE_PATH_NOT_ABSOLUTE", "AI_ORCHESTRATOR_HOME must be absolute")
        return path
    if os.name == "nt":
        return Path.home() / ".ai-repository-foundation" / "ai-orchestrator"
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "AIRepositoryFoundation" / "ai-orchestrator"
    root = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local" / "state")))
    return root / "ai-repository-foundation" / "ai-orchestrator"


def _inside_git(path: Path) -> bool:
    current = path.resolve()
    if not current.exists():
        current = current.parent
    return any((item / ".git").exists() for item in (current, *current.parents))


def external_root(path: Path) -> Path:
    value = path.resolve()
    if _inside_git(value):
        raise OrchestrationError("STATE_INSIDE_REPOSITORY", "orchestrator state must remain outside a Git worktree")
    value.mkdir(parents=True, exist_ok=True)
    return value


def atomic_json(path: Path, value: dict[str, Any]) -> None:
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


def _input_digest(path: Path) -> str:
    try:
        body = path.read_bytes()
    except OSError as exc:
        raise OrchestrationError("INPUT_UNREADABLE", "input handle is unavailable", "AVAILABILITY") from exc
    return "sha256:" + hashlib.sha256(body).hexdigest()


def _checkpoint_path(root: Path, orchestration_id: str) -> Path:
    return root / "checkpoints" / (hashlib.sha256(orchestration_id.encode("utf-8")).hexdigest() + ".json")


def _load_checkpoint(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    value = _load_json(path, "INVALID_CHECKPOINT")
    required = {"contract", "orchestration_id", "request_hash", "state", "report"}
    if set(value) != required or value.get("contract") != CONTRACT or value.get("state") not in {"PREPARED", "IN_PROGRESS", "TERMINAL"}:
        raise OrchestrationError("INVALID_CHECKPOINT", "orchestration checkpoint is invalid")
    return value


def _save_checkpoint(path: Path, request: dict[str, Any], request_hash: str, state: str, report: dict[str, Any] | None) -> None:
    atomic_json(path, {"contract": CONTRACT, "orchestration_id": request["orchestration_id"], "request_hash": request_hash, "state": state, "report": report})


def _load_json(path: Path, code: str) -> dict[str, Any]:
    try:
        if path.stat().st_size > MAX_DOCUMENT_BYTES:
            raise OrchestrationError(code, "document exceeds four MiB")
        value = json.loads(path.read_text(encoding="utf-8"))
    except OrchestrationError:
        raise
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise OrchestrationError(code, "document is unavailable or invalid") from exc
    if not isinstance(value, dict):
        raise OrchestrationError(code, "document root must be an object")
    return value


def validate_request(raw: Any) -> dict[str, Any]:
    fields = {"schema_version", "contract", "orchestration_id", "router_request", "input_handle", "output_handle", "remote_authorized", "max_attempts", "validation"}
    if not isinstance(raw, dict) or set(raw) != fields or raw.get("schema_version") != 1 or raw.get("contract") != CONTRACT:
        raise OrchestrationError("INVALID_ORCHESTRATION_REQUEST", "request has missing, unknown, or unsupported fields")
    if not isinstance(raw["orchestration_id"], str) or not raw["orchestration_id"]:
        raise OrchestrationError("INVALID_ORCHESTRATION_REQUEST", "orchestration_id must be non-empty")
    for field in ("input_handle", "output_handle"):
        if not isinstance(raw[field], str) or not Path(raw[field]).is_absolute():
            raise OrchestrationError("INVALID_ORCHESTRATION_REQUEST", f"{field} must be absolute")
    if not isinstance(raw["remote_authorized"], bool):
        raise OrchestrationError("INVALID_ORCHESTRATION_REQUEST", "remote_authorized must be boolean")
    attempts = raw["max_attempts"]
    if isinstance(attempts, bool) or not isinstance(attempts, int) or not 1 <= attempts <= 10:
        raise OrchestrationError("INVALID_ORCHESTRATION_REQUEST", "max_attempts must be from 1 through 10")
    validation = raw["validation"]
    if not isinstance(validation, dict) or set(validation) != {"mode"} or validation["mode"] not in {"NONE", "OUTPUT_NONEMPTY", "JSON_DOCUMENT", "MANUAL_REVIEW"}:
        raise OrchestrationError("INVALID_ORCHESTRATION_REQUEST", "validation mode is invalid")
    return deepcopy(raw)


def validate_evidence(raw: Any, at: datetime) -> dict[str, Any]:
    if not isinstance(raw, dict) or set(raw) != {"schema_version", "contract", "updated_at", "records", "aliases"}:
        raise OrchestrationError("INVALID_EVIDENCE", "evidence has missing or unknown fields")
    if raw.get("schema_version") != 1 or raw.get("contract") != EVIDENCE_CONTRACT:
        raise OrchestrationError("INVALID_EVIDENCE", "evidence contract is unsupported")
    parse_time(raw["updated_at"], "updated_at")
    for collection in ("records", "aliases"):
        if not isinstance(raw[collection], list):
            raise OrchestrationError("INVALID_EVIDENCE", f"{collection} must be an array")
    records = []
    for row in raw["records"]:
        try:
            required = {"connection_id", "model_id", "profile", "source", "observed_at", "valid_until"}
            if not isinstance(row, dict) or set(row) != required or any(not isinstance(row.get(field), str) or not row[field] for field in ("connection_id", "model_id")):
                raise OrchestrationError("INVALID_EVIDENCE", "model evidence record is invalid")
            _validate_profile(row["profile"])
            observed = parse_time(row["observed_at"], "record.observed_at")
            expiry = parse_time(row["valid_until"], "record.valid_until")
            _validate_source(row["source"])
            if expiry > observed and expiry > at:
                records.append(deepcopy(row))
        except OrchestrationError:
            continue
    aliases = []
    for row in raw["aliases"]:
        try:
            required = {"connection_id", "requested_model", "actual_model", "evidence_kind", "source", "observed_at", "valid_until"}
            if not isinstance(row, dict) or set(row) != required or row.get("evidence_kind") not in STRONG_ALIAS_EVIDENCE or any(not isinstance(row.get(field), str) or not row[field] for field in ("connection_id", "requested_model", "actual_model")):
                raise OrchestrationError("INVALID_EVIDENCE", "model alias evidence is invalid")
            observed = parse_time(row["observed_at"], "alias.observed_at")
            expiry = parse_time(row["valid_until"], "alias.valid_until")
            _validate_source(row["source"])
            if expiry > observed and expiry > at:
                aliases.append(deepcopy(row))
        except OrchestrationError:
            continue
    return {**deepcopy(raw), "records": records, "aliases": aliases}


def _validate_profile(value: Any) -> None:
    if not isinstance(value, dict) or set(value) - PROFILE_FIELDS:
        raise OrchestrationError("INVALID_EVIDENCE", "model profile is invalid")
    enums = {
        "assessment": {"UNASSESSED", "EVALUATING", "ASSESSED", "DISABLED"},
        "availability": {"AVAILABLE", "UNAVAILABLE", "MISSING_PRICE"},
        "quality_provenance": {"MEASURED", "CONFIGURED", "UNKNOWN"},
        "resource_provenance": {"MEASURED", "CONFIGURED", "UNKNOWN"},
    }
    if any(field in value and value[field] not in choices for field, choices in enums.items()):
        raise OrchestrationError("INVALID_EVIDENCE", "model profile enum is invalid")
    for field in ("capabilities", "reasoning_efforts", "supported_tiers"):
        if field in value and (not isinstance(value[field], list) or any(not isinstance(item, str) or not item for item in value[field])):
            raise OrchestrationError("INVALID_EVIDENCE", "model profile string array is invalid")
    context = value.get("context_window")
    if "context_window" in value and context is not None and (isinstance(context, bool) or not isinstance(context, int) or context < 1):
        raise OrchestrationError("INVALID_EVIDENCE", "model context window is invalid")
    priors = value.get("quality_prior")
    if priors is not None and (not isinstance(priors, dict) or any(isinstance(item, bool) or not isinstance(item, (int, float)) or not 0 <= item <= 1 for item in priors.values())):
        raise OrchestrationError("INVALID_EVIDENCE", "model quality prior is invalid")


def _validate_source(value: Any) -> None:
    if not isinstance(value, dict) or set(value) != {"kind", "locator", "content_sha256"}:
        raise OrchestrationError("INVALID_EVIDENCE", "evidence source is invalid")
    if value["kind"] not in {"MEASUREMENT", "PROJECT_CONFIGURATION", "PRIMARY_API", "PROVIDER_DOCUMENTATION", "VERIFIED_RESEARCH"}:
        raise OrchestrationError("INVALID_EVIDENCE", "evidence source kind is invalid")
    if not isinstance(value["locator"], str) or not value["locator"]:
        raise OrchestrationError("INVALID_EVIDENCE", "evidence locator is invalid")
    sha = value["content_sha256"]
    if not isinstance(sha, str) or len(sha) != 71 or not sha.startswith("sha256:"):
        raise OrchestrationError("INVALID_EVIDENCE", "evidence content hash is invalid")
    try:
        int(sha[7:], 16)
    except ValueError as exc:
        raise OrchestrationError("INVALID_EVIDENCE", "evidence content hash is invalid") from exc


def empty_evidence(at: datetime) -> dict[str, Any]:
    return {"schema_version": 1, "contract": EVIDENCE_CONTRACT, "updated_at": isoformat(at), "records": [], "aliases": []}


def refresh_evidence(sources_path: Path, state_root: Path, *, at: datetime | None = None) -> dict[str, Any]:
    observed = at or utc_now()
    sources = _load_json(sources_path, "INVALID_EVIDENCE_SOURCES")
    if set(sources) != {"schema_version", "contract", "sources"} or sources.get("schema_version") != 1 or sources.get("contract") != SOURCE_CONTRACT or not isinstance(sources["sources"], list):
        raise OrchestrationError("INVALID_EVIDENCE_SOURCES", "evidence sources contract is invalid")
    root = external_root(state_root)
    lkg_path = root / "model-runtime-evidence.json"
    refresh_path = root / "refresh-state.json"
    lkg = empty_evidence(observed)
    if lkg_path.is_file():
        try:
            lkg = validate_evidence(_load_json(lkg_path, "INVALID_EVIDENCE"), observed)
        except OrchestrationError:
            lkg = empty_evidence(observed)
    refresh_state = {"sources": {}}
    if refresh_path.is_file():
        try:
            candidate = _load_json(refresh_path, "INVALID_REFRESH_STATE")
            if set(candidate) == {"sources"} and isinstance(candidate["sources"], dict):
                refresh_state = candidate
        except OrchestrationError:
            pass
    records = []
    successful: list[dict[str, Any]] = []
    for source in sources["sources"]:
        required = {"source_id", "argv", "environment_allowlist", "timeout_seconds", "minimum_refresh_seconds"}
        if not isinstance(source, dict) or set(source) != required:
            raise OrchestrationError("INVALID_EVIDENCE_SOURCES", "evidence source has missing or unknown fields")
        source_id = source["source_id"]
        argv = source["argv"]
        allowlist = source["environment_allowlist"]
        interval = source["minimum_refresh_seconds"]
        timeout = source["timeout_seconds"]
        if not isinstance(source_id, str) or not source_id or not isinstance(argv, list) or not argv or any(not isinstance(item, str) or not item for item in argv) or not Path(argv[0]).is_absolute():
            raise OrchestrationError("INVALID_EVIDENCE_SOURCES", "source id and argv must be non-empty")
        if not isinstance(allowlist, list) or any(not isinstance(item, str) or not item for item in allowlist):
            raise OrchestrationError("INVALID_EVIDENCE_SOURCES", "environment allowlist is invalid")
        if isinstance(interval, bool) or not isinstance(interval, int) or interval < MIN_REFRESH_SECONDS:
            raise OrchestrationError("INVALID_EVIDENCE_SOURCES", "minimum refresh interval must be at least 24 hours")
        if isinstance(timeout, bool) or not isinstance(timeout, (int, float)) or not 0.1 <= timeout <= 600:
            raise OrchestrationError("INVALID_EVIDENCE_SOURCES", "source timeout is invalid")
        previous = refresh_state["sources"].get(source_id, {})
        next_allowed = parse_time(previous["next_allowed_at"], "next_allowed_at") if isinstance(previous, dict) and "next_allowed_at" in previous else None
        if next_allowed is not None and observed < next_allowed:
            records.append({"source_id": source_id, "status": "CACHED", "reason_code": "REFRESH_RATE_LIMIT"})
            continue
        refresh_state["sources"][source_id] = {"last_attempt_at": isoformat(observed), "next_allowed_at": isoformat(observed + timedelta(seconds=interval))}
        environment = {name: os.environ[name] for name in allowlist if name in os.environ}
        try:
            completed = subprocess.run(argv, shell=False, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, env=environment, timeout=float(timeout), check=False)
            if completed.returncode != 0 or len(completed.stdout) > MAX_DOCUMENT_BYTES:
                raise OrchestrationError("EVIDENCE_SOURCE_FAILED", "evidence source failed", "AVAILABILITY")
            candidate = validate_evidence(json.loads(completed.stdout.decode("utf-8")), observed)
            successful.append(candidate)
            records.append({"source_id": source_id, "status": "REFRESHED", "reason_code": "SOURCE_VERIFIED"})
        except (subprocess.TimeoutExpired, OSError, UnicodeError, json.JSONDecodeError, OrchestrationError):
            records.append({"source_id": source_id, "status": "CACHED", "reason_code": "SOURCE_REFRESH_FAILED"})
    if successful:
        merged_records = {(r["connection_id"], r["model_id"]): r for r in lkg["records"]}
        merged_aliases = {(r["connection_id"], r["requested_model"], r["actual_model"]): r for r in lkg["aliases"]}
        for item in successful:
            merged_records.update({(r["connection_id"], r["model_id"]): r for r in item["records"]})
            merged_aliases.update({(r["connection_id"], r["requested_model"], r["actual_model"]): r for r in item["aliases"]})
        lkg = {"schema_version": 1, "contract": EVIDENCE_CONTRACT, "updated_at": isoformat(observed), "records": list(merged_records.values()), "aliases": list(merged_aliases.values())}
        atomic_json(lkg_path, lkg)
    atomic_json(refresh_path, refresh_state)
    return {"status": "COMPLETE" if records and all(r["status"] in {"REFRESHED", "CACHED"} for r in records) else "UNAVAILABLE", "records": records, "evidence_path": str(lkg_path)}


def _dependencies(capability_root: Path) -> tuple[Any, Any]:
    router_dir = capability_root.parent / "model-router"
    runtime_dir = capability_root.parent / "ai-runtime-adapters"
    for directory in (str(router_dir), str(runtime_dir)):
        if directory not in sys.path:
            sys.path.insert(0, directory)
    try:
        import router_v2
        import runtime_configuration
        return router_v2, runtime_configuration
    except ImportError as exc:
        raise OrchestrationError("OPTIONAL_DEPENDENCY_UNAVAILABLE", "router or runtime adapter capability is unavailable", "AVAILABILITY") from exc


def _catalog(store: Any, runtime: Any) -> tuple[list[dict[str, Any]], dict[str, tuple[str, str]], list[dict[str, str]]]:
    fragments: list[dict[str, Any]] = []
    mapping: dict[str, tuple[str, str]] = {}
    statuses: list[dict[str, str]] = []
    for row in store.connection_statuses():
        connection_id = row["connection_id"]
        if row["status"] != "CONFIGURED":
            statuses.append({"connection_id": connection_id, "status": "INVALID", "reason_code": row.get("reason_code", "INVALID_CONFIGURATION")})
            continue
        try:
            connection = store.load_connection(connection_id)
            result = runtime.execute_adapter(connection, "catalog", {})
            count = 0
            for source in result.get("fragments", []):
                fragment = deepcopy(source)
                original = fragment.get("provider")
                if not isinstance(original, str) or not original:
                    continue
                qualified = connection_id + "::" + original
                fragment["provider"] = qualified
                mapping[qualified] = (connection_id, original)
                fragments.append(fragment)
                count += 1
            statuses.append({"connection_id": connection_id, "status": "AVAILABLE" if count else "UNAVAILABLE", "reason_code": "CATALOG_AVAILABLE" if count else "EMPTY_CATALOG"})
        except Exception as exc:
            statuses.append({"connection_id": connection_id, "status": "UNAVAILABLE", "reason_code": getattr(exc, "code", "CATALOG_UNAVAILABLE")})
    return fragments, mapping, statuses


def _overlay(fragments: list[dict[str, Any]], evidence: dict[str, Any]) -> list[dict[str, Any]]:
    profiles = {(row["connection_id"], row["model_id"]): row["profile"] for row in evidence["records"]}
    result = deepcopy(fragments)
    for fragment in result:
        connection_id = fragment["provider"].split("::", 1)[0]
        for model_id, model in fragment["models"].items():
            profile = profiles.get((connection_id, model_id))
            if profile:
                model.update(deepcopy(profile))
        fragment["pricing_epoch"] = digest({name: item.get("pricing") for name, item in fragment["models"].items()})
    return result


def _report(request: dict[str, Any], *, status: str, router_status: str, route: Any, catalogs: list[dict[str, str]], attempts: list[dict[str, Any]], validation: str, reasons: list[str], actions: list[str], at: datetime) -> dict[str, Any]:
    return {
        "schema_version": 1, "contract": CONTRACT, "orchestration_id": request["orchestration_id"],
        "status": status, "router_status": router_status, "route": route, "catalog_status": catalogs,
        "attempts": attempts, "validation_status": validation, "reason_codes": sorted(set(reasons)),
        "remaining_actions": list(dict.fromkeys(actions)), "finished_at": isoformat(at),
    }


def _load_evidence(path: Path, at: datetime) -> tuple[dict[str, Any], list[str]]:
    if not path.is_file():
        return empty_evidence(at), ["MODEL_EVIDENCE_UNAVAILABLE"]
    try:
        value = validate_evidence(_load_json(path, "INVALID_EVIDENCE"), at)
        return value, [] if value["records"] else ["MODEL_EVIDENCE_UNAVAILABLE"]
    except OrchestrationError as exc:
        return empty_evidence(at), [exc.code]


def plan_or_execute(raw: Any, *, execute: bool, config_path: Path | None = None, state_root: Path | None = None, evidence_path: Path | None = None, evidence_sources_path: Path | None = None, capability_root: Path | None = None, at: datetime | None = None) -> dict[str, Any]:
    request = validate_request(raw)
    observed = at or utc_now()
    root = external_root(state_root or default_state_dir())
    evidence_file = (evidence_path or root / "model-runtime-evidence.json").resolve()
    if _inside_git(evidence_file):
        raise OrchestrationError("EVIDENCE_INSIDE_REPOSITORY", "model runtime evidence must remain outside a Git worktree")
    request_hash: str | None = None
    checkpoint_path: Path | None = None
    if execute:
        try:
            request_hash = digest({"request": request, "input_sha256": _input_digest(Path(request["input_handle"]))})
            checkpoint_path = _checkpoint_path(root, request["orchestration_id"])
            checkpoint = _load_checkpoint(checkpoint_path)
        except OrchestrationError as exc:
            return _report(request, status="BLOCKED", router_status="UNAVAILABLE", route=None, catalogs=[], attempts=[], validation="UNAVAILABLE", reasons=[exc.code], actions=["REPAIR_INPUT_OR_EXTERNAL_CHECKPOINT"], at=observed)
        if checkpoint is not None:
            if checkpoint["orchestration_id"] != request["orchestration_id"] or checkpoint["request_hash"] != request_hash:
                return _report(request, status="BLOCKED", router_status="UNAVAILABLE", route=None, catalogs=[], attempts=[], validation="UNAVAILABLE", reasons=["ORCHESTRATION_ID_REUSE_MISMATCH"], actions=["USE_A_NEW_ORCHESTRATION_ID"], at=observed)
            if checkpoint["state"] == "TERMINAL" and isinstance(checkpoint["report"], dict):
                return deepcopy(checkpoint["report"])
            if checkpoint["state"] == "IN_PROGRESS":
                return _report(request, status="MANUAL_REQUIRED", router_status="UNAVAILABLE", route=None, catalogs=[], attempts=[], validation="INCONCLUSIVE", reasons=["AMBIGUOUS_PRIOR_INVOCATION"], actions=["RECONCILE_PROVIDER_OPERATION_BEFORE_RETRY"], at=observed)
    refresh_reasons: list[str] = []
    if evidence_sources_path is not None:
        try:
            refreshed = refresh_evidence(evidence_sources_path.resolve(), root, at=observed)
            refresh_reasons = [row["reason_code"] for row in refreshed["records"] if row["status"] not in {"REFRESHED", "CACHED"}]
        except OrchestrationError as exc:
            refresh_reasons = [exc.code]
    try:
        router, runtime = _dependencies(capability_root or Path(__file__).resolve().parent)
        store = runtime.ConfigurationStore(config_path)
        fragments, mapping, catalogs = _catalog(store, runtime)
    except OrchestrationError as exc:
        return _report(request, status="UNAVAILABLE", router_status="UNAVAILABLE", route=None, catalogs=[], attempts=[], validation="UNAVAILABLE", reasons=[exc.code], actions=["INSTALL_OPTIONAL_ROUTER_AND_RUNTIME_CAPABILITIES"], at=observed)
    evidence, evidence_reasons = _load_evidence(evidence_file, observed)
    fragments = _overlay(fragments, evidence)
    try:
        router_request = deepcopy(request["router_request"])
        if router_request.get("allowed_providers"):
            allowed = set(router_request["allowed_providers"])
            router_request["allowed_providers"] = sorted(provider for provider, pair in mapping.items() if provider in allowed or pair[0] in allowed or pair[1] in allowed)
        decision = router.route_v2(router_request, fragments, runtime_store=router.RuntimeStore(root / "router"), fragment_store=router.ProviderFragmentStore(root / "fragments"), at=observed)
    except Exception as exc:
        return _report(request, status="UNAVAILABLE", router_status="UNAVAILABLE", route=None, catalogs=catalogs, attempts=[], validation="UNAVAILABLE", reasons=[getattr(exc, "code", "ROUTER_UNAVAILABLE")], actions=["REVIEW_ROUTER_REQUEST_OR_RUNTIME_EVIDENCE"], at=observed)
    route = decision.get("v1_decision", {}).get("route")
    if decision["status"] == "LOCAL_ONLY":
        return _report(request, status="MANUAL_REQUIRED", router_status="LOCAL_ONLY", route=None, catalogs=catalogs, attempts=[], validation="NOT_REQUIRED", reasons=["DETERMINISTIC_TOOL_REQUIRED"], actions=["USE_A_DETERMINISTIC_TOOL"], at=observed)
    if decision["status"] != "ROUTED" or not route:
        reasons = refresh_reasons + evidence_reasons + decision.get("reason_codes", [])
        action = "ADD_FRESH_SOURCE_BACKED_MODEL_EVIDENCE" if evidence_reasons or any("PROVENANCE" in item for item in reasons) else "REVIEW_ROUTING_CONSTRAINTS"
        return _report(request, status="MANUAL_REQUIRED", router_status="NO_ROUTE", route=None, catalogs=catalogs, attempts=[], validation="UNAVAILABLE", reasons=reasons or ["NO_ROUTE"], actions=[action, "USE_MANUAL_MODEL_HANDOFF_IF_APPROPRIATE"], at=observed)
    public_route = {**route, "connection_id": mapping[route["provider"]][0], "runtime_provider": mapping[route["provider"]][1]}
    if not execute:
        return _report(request, status="PLANNED", router_status="ROUTED", route=public_route, catalogs=catalogs, attempts=[], validation="INCONCLUSIVE", reasons=refresh_reasons + decision.get("reason_codes", []), actions=["EXECUTE_APPROVED_PLAN"], at=observed)
    assert request_hash is not None and checkpoint_path is not None
    choices = [route] + decision.get("v1_decision", {}).get("fallbacks", [])
    attempts = []
    aliases = {(row["connection_id"], row["requested_model"], row["actual_model"]) for row in evidence["aliases"]}
    for index, choice in enumerate(choices[:request["max_attempts"]]):
        provider = choice["provider"]
        connection_id, original_provider = mapping[provider]
        try:
            _save_checkpoint(checkpoint_path, request, request_hash, "IN_PROGRESS", None)
            connection = store.load_connection(connection_id)
            invocation = runtime.execute_adapter(connection, "invoke", {
                "operation_id": request["orchestration_id"] + f"-attempt-{index + 1}", "model": choice["model"],
                "data_class": request["router_request"]["data_class"], "input_path": request["input_handle"],
                "output_path": request["output_handle"], "remote_authorized": request["remote_authorized"],
            })
            actual = invocation.get("actual_model")
            attested = actual == choice["model"] or (connection_id, choice["model"], actual) in aliases
            attempt = {"connection_id": connection_id, "provider": original_provider, "model": choice["model"], "actual_model": actual, "dispatch_status": "ALIAS_ATTESTED" if actual != choice["model"] and attested else invocation.get("dispatch_status", "REQUESTED_NOT_ATTESTED"), "status": "SUCCEEDED", "error_class": None, "reason_code": None, "output_sha256": invocation.get("output_sha256"), "output_bytes": int(invocation.get("output_bytes", 0))}
            attempts.append(attempt)
            if not attested:
                result = _report(request, status="MANUAL_REQUIRED", router_status="ROUTED", route=public_route, catalogs=catalogs, attempts=attempts, validation="INCONCLUSIVE", reasons=["ACTUAL_MODEL_NOT_ATTESTED"], actions=["VERIFY_PROVIDER_MODEL_IDENTITY_OR_ADD_STRONG_ALIAS_EVIDENCE"], at=observed)
                _save_checkpoint(checkpoint_path, request, request_hash, "TERMINAL", result)
                return result
            validation = _validate_output(Path(request["output_handle"]), request["validation"]["mode"])
            if validation == "PASSED" or validation == "NOT_REQUIRED":
                result = _report(request, status="COMPLETED", router_status="ROUTED", route=public_route, catalogs=catalogs, attempts=attempts, validation=validation, reasons=[], actions=[], at=observed)
                _save_checkpoint(checkpoint_path, request, request_hash, "TERMINAL", result)
                return result
            if validation == "INCONCLUSIVE":
                result = _report(request, status="MANUAL_REQUIRED", router_status="ROUTED", route=public_route, catalogs=catalogs, attempts=attempts, validation=validation, reasons=["MANUAL_VALIDATION_REQUIRED"], actions=["REVIEW_OUTPUT_HANDLE"], at=observed)
                _save_checkpoint(checkpoint_path, request, request_hash, "TERMINAL", result)
                return result
            attempts[-1]["status"] = "FAILED"
            attempts[-1]["error_class"] = "VALIDATION"
            attempts[-1]["reason_code"] = "OUTPUT_VALIDATION_FAILED"
            _save_checkpoint(checkpoint_path, request, request_hash, "PREPARED", None)
        except Exception as exc:
            error_class = getattr(exc, "error_class", "UNKNOWN")
            attempts.append({"connection_id": connection_id, "provider": original_provider, "model": choice["model"], "actual_model": None, "dispatch_status": "NOT_DISPATCHED", "status": "FAILED", "error_class": error_class, "reason_code": getattr(exc, "code", "INVOCATION_FAILED"), "output_sha256": None, "output_bytes": 0})
            if error_class in {"TIMEOUT", "PROTOCOL", "UNKNOWN"}:
                return _report(request, status="MANUAL_REQUIRED", router_status="ROUTED", route=public_route, catalogs=catalogs, attempts=attempts, validation="INCONCLUSIVE", reasons=["AMBIGUOUS_INVOCATION_RESULT"], actions=["RECONCILE_PROVIDER_OPERATION_BEFORE_RETRY"], at=observed)
            _save_checkpoint(checkpoint_path, request, request_hash, "PREPARED", None)
    result = _report(request, status="UNAVAILABLE", router_status="ROUTED", route=public_route, catalogs=catalogs, attempts=attempts, validation="FAILED", reasons=["FALLBACKS_EXHAUSTED"], actions=["CHANGE_INPUT_ADAPTER_OR_EVIDENCE_BEFORE_RETRY"], at=observed)
    _save_checkpoint(checkpoint_path, request, request_hash, "TERMINAL", result)
    return result


def _validate_output(path: Path, mode: str) -> str:
    if mode == "NONE":
        return "NOT_REQUIRED"
    if mode == "MANUAL_REVIEW":
        return "INCONCLUSIVE"
    try:
        body = path.read_bytes()
        if not body:
            return "FAILED"
        if mode == "JSON_DOCUMENT":
            json.loads(body.decode("utf-8"))
        return "PASSED"
    except (OSError, UnicodeError, json.JSONDecodeError):
        return "FAILED"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path)
    parser.add_argument("--state-root", type=Path)
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--evidence-sources", type=Path, help="Optional external exact-argv sources refreshed when due before planning")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("plan", "execute"):
        command = sub.add_parser(name)
        command.add_argument("request", type=Path)
    refresh = sub.add_parser("refresh-evidence")
    refresh.add_argument("sources", type=Path)
    args = parser.parse_args(argv)
    try:
        if args.command == "refresh-evidence":
            result = refresh_evidence(args.sources, args.state_root or default_state_dir())
        else:
            request = _load_json(args.request, "INVALID_ORCHESTRATION_REQUEST")
            result = plan_or_execute(request, execute=args.command == "execute", config_path=args.config, state_root=args.state_root, evidence_path=args.evidence, evidence_sources_path=args.evidence_sources)
        print(json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False))
        return 0 if result.get("status") in {"COMPLETE", "COMPLETED", "PLANNED"} else 3
    except OrchestrationError as exc:
        print(json.dumps({"status": "ERROR", "reason_code": exc.code, "message": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

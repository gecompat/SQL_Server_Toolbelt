#!/usr/bin/env python3
"""Dependency-free planner for the runtime-neutral foundation-ai-work/v1 contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timedelta, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any


CONTRACT = "foundation-ai-work/v1"
DATA_CLASSES = {"PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"}
RISKS = {"LOW", "MODERATE", "HIGH", "CRITICAL"}
BOUNDARIES = {"PROCESS", "HOST", "LOCAL_NETWORK", "REMOTE", "UNKNOWN", "HUMAN"}
CAPABILITY_KINDS = {
    "DETERMINISTIC_TOOL", "MODEL", "RETRIEVAL", "RENDERER", "VALIDATOR", "EXTERNAL_SERVICE", "HUMAN"
}
HEALTH_STATES = {"HEALTHY", "DEGRADED", "UNAVAILABLE", "UNKNOWN"}
EFFECTS = {"LOCAL_READ", "LOCAL_WRITE", "EXTERNAL_WRITE", "PUBLISH", "DATA_TRANSFER", "SPEND"}
EFFECT_AUTHORITIES = {
    "LOCAL_READ": "filesystem:read",
    "LOCAL_WRITE": "filesystem:write",
    "EXTERNAL_WRITE": "external:write",
    "PUBLISH": "publish",
    "DATA_TRANSFER": "data:transfer",
    "SPEND": "spend",
}
RESOURCE_LIMITS = {
    "cpu_seconds": "max_cpu_seconds",
    "ram_mb": "max_ram_mb",
    "vram_mb": "max_vram_mb",
    "disk_mb": "max_disk_mb",
    "network_mb": "max_network_mb",
    "gpu_seconds": "max_gpu_seconds",
    "energy_wh": "max_energy_wh",
}


class WorkError(RuntimeError):
    """A bounded contract or planning error safe to show to the caller."""


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_datetime(value: Any, field: str) -> datetime:
    if not isinstance(value, str):
        raise WorkError(f"{field} must be an ISO-8601 timestamp")
    try:
        result = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise WorkError(f"{field} must be an ISO-8601 timestamp") from exc
    if result.tzinfo is None:
        raise WorkError(f"{field} must include a timezone")
    return result.astimezone(timezone.utc)


def number(value: Any, field: str) -> Decimal:
    if isinstance(value, bool) or not isinstance(value, (int, float, Decimal)):
        raise WorkError(f"{field} must be numeric")
    try:
        result = Decimal(str(value))
    except (InvalidOperation, ValueError) as exc:
        raise WorkError(f"{field} must be numeric") from exc
    if not result.is_finite() or result < 0:
        raise WorkError(f"{field} must be finite and non-negative")
    return result


def strings(value: Any, field: str, *, nonempty: bool = False) -> list[str]:
    if not isinstance(value, list) or (nonempty and not value):
        raise WorkError(f"{field} must be {'a non-empty ' if nonempty else 'an '}array")
    if any(not isinstance(item, str) or not item for item in value) or len(set(value)) != len(value):
        raise WorkError(f"{field} must contain unique non-empty strings")
    return list(value)


def require_fields(value: Any, fields: set[str], allowed: set[str], name: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise WorkError(f"{name} must be an object")
    missing = sorted(fields - set(value))
    unknown = sorted(set(value) - allowed)
    if missing:
        raise WorkError(f"{name} missing required fields: {', '.join(missing)}")
    if unknown:
        raise WorkError(f"{name} has unknown fields: {', '.join(unknown)}")
    return value


def validate_handle(raw: Any, field: str) -> dict[str, Any]:
    value = require_fields(raw, {"handle_id", "kind"}, {"handle_id", "kind", "media_type", "content_sha256"}, field)
    if not isinstance(value["handle_id"], str) or not value["handle_id"]:
        raise WorkError(f"{field}.handle_id must be a non-empty string")
    if value["kind"] not in {"STDIN", "FILE", "EPHEMERAL", "OPAQUE"}:
        raise WorkError(f"{field}.kind is invalid")
    digest_value = value.get("content_sha256")
    if digest_value is not None and (
        not isinstance(digest_value, str) or len(digest_value) != 71 or not digest_value.startswith("sha256:")
    ):
        raise WorkError(f"{field}.content_sha256 must use sha256:<64 lowercase hex>")
    if digest_value is not None:
        try:
            int(digest_value[7:], 16)
        except ValueError as exc:
            raise WorkError(f"{field}.content_sha256 must use sha256:<64 lowercase hex>") from exc
    return dict(value)


def validate_request(raw: Any) -> dict[str, Any]:
    fields = {
        "schema_version", "contract", "work_id", "task_class", "data_class", "risk", "effects",
        "input_handles", "output", "required_capabilities", "allowed_execution_boundaries",
        "authorization", "quality", "limits", "validation",
    }
    value = require_fields(raw, fields, fields, "work request")
    if value["schema_version"] != 1 or value["contract"] != CONTRACT:
        raise WorkError(f"work request must use {CONTRACT}")
    for field in ("work_id", "task_class"):
        if not isinstance(value[field], str) or not value[field]:
            raise WorkError(f"{field} must be a non-empty string")
    if value["data_class"] not in DATA_CLASSES or value["risk"] not in RISKS:
        raise WorkError("data_class or risk is invalid")
    effects = set(strings(value["effects"], "effects"))
    if not effects <= EFFECTS:
        raise WorkError("effects contains an invalid value")
    required = strings(value["required_capabilities"], "required_capabilities", nonempty=True)
    boundaries = set(strings(value["allowed_execution_boundaries"], "allowed_execution_boundaries", nonempty=True))
    if not boundaries <= BOUNDARIES:
        raise WorkError("allowed_execution_boundaries contains an invalid value")
    if not isinstance(value["input_handles"], list):
        raise WorkError("input_handles must be an array")
    handles = [validate_handle(item, f"input_handles[{index}]") for index, item in enumerate(value["input_handles"])]
    output = require_fields(value["output"], {"format"}, {"format", "handle"}, "output")
    if not isinstance(output["format"], str) or not output["format"]:
        raise WorkError("output.format must be a non-empty string")
    normalized_output = {"format": output["format"]}
    if "handle" in output:
        normalized_output["handle"] = validate_handle(output["handle"], "output.handle")
    auth = require_fields(
        value["authorization"],
        {"granted_authorities", "remote_data_classes", "allow_local_adapter_synthesis"},
        {"granted_authorities", "remote_data_classes", "allow_local_adapter_synthesis"},
        "authorization",
    )
    granted = strings(auth["granted_authorities"], "authorization.granted_authorities")
    remote_classes = set(strings(auth["remote_data_classes"], "authorization.remote_data_classes"))
    if not remote_classes <= DATA_CLASSES or not isinstance(auth["allow_local_adapter_synthesis"], bool):
        raise WorkError("authorization contains invalid values")
    quality = require_fields(value["quality"], set(), {"minimum_success_probability"}, "quality")
    normalized_quality: dict[str, Any] = {}
    if "minimum_success_probability" in quality:
        floor = number(quality["minimum_success_probability"], "quality.minimum_success_probability")
        if floor > 1:
            raise WorkError("quality.minimum_success_probability must not exceed 1")
        normalized_quality["minimum_success_probability"] = float(floor)
    limits = require_fields(
        value["limits"],
        set(),
        set(RESOURCE_LIMITS.values()) | {"deadline", "max_cost_usd", "timeout_seconds", "max_attempts"},
        "limits",
    )
    normalized_limits: dict[str, Any] = {}
    for field, raw_number in limits.items():
        if field == "deadline":
            normalized_limits[field] = isoformat(parse_datetime(raw_number, "limits.deadline"))
        elif field == "max_attempts":
            if isinstance(raw_number, bool) or not isinstance(raw_number, int) or raw_number < 1:
                raise WorkError("limits.max_attempts must be a positive integer")
            normalized_limits[field] = raw_number
        else:
            normalized_limits[field] = float(number(raw_number, f"limits.{field}"))
    validation = require_fields(
        value["validation"],
        {"required_capabilities", "independent_required", "allow_human"},
        {"required_capabilities", "independent_required", "allow_human"},
        "validation",
    )
    validation_required = strings(validation["required_capabilities"], "validation.required_capabilities")
    if not isinstance(validation["independent_required"], bool) or not isinstance(validation["allow_human"], bool):
        raise WorkError("validation flags must be boolean")
    normalized = {
        **value,
        "effects": sorted(effects),
        "input_handles": handles,
        "output": normalized_output,
        "required_capabilities": required,
        "allowed_execution_boundaries": sorted(boundaries),
        "authorization": {
            "granted_authorities": granted,
            "remote_data_classes": sorted(remote_classes),
            "allow_local_adapter_synthesis": auth["allow_local_adapter_synthesis"],
        },
        "quality": normalized_quality,
        "limits": normalized_limits,
        "validation": {
            "required_capabilities": validation_required,
            "independent_required": validation["independent_required"],
            "allow_human": validation["allow_human"],
        },
    }
    return normalized


def validate_capability(raw: Any) -> dict[str, Any]:
    fields = {
        "schema_version", "contract", "capability_id", "kind", "protocol", "execution_boundary",
        "required_authorities", "health", "functions", "data_classes_allowed", "deterministic",
        "provenance", "quality", "resources", "cost_model",
    }
    value = require_fields(raw, fields, fields | {"execution"}, "capability descriptor")
    if value["schema_version"] != 1 or value["contract"] != CONTRACT:
        raise WorkError(f"capability descriptor must use {CONTRACT}")
    for field in ("capability_id", "protocol"):
        if not isinstance(value[field], str) or not value[field]:
            raise WorkError(f"capability {field} must be a non-empty string")
    if value["kind"] not in CAPABILITY_KINDS or value["execution_boundary"] not in BOUNDARIES:
        raise WorkError("capability kind or execution_boundary is invalid")
    if not isinstance(value["deterministic"], bool):
        raise WorkError("capability deterministic must be boolean")
    authorities = strings(value["required_authorities"], "capability.required_authorities")
    functions = strings(value["functions"], "capability.functions", nonempty=True)
    data_classes = set(strings(value["data_classes_allowed"], "capability.data_classes_allowed", nonempty=True))
    if not data_classes <= DATA_CLASSES:
        raise WorkError("capability data_classes_allowed contains an invalid value")
    health = require_fields(value["health"], {"state", "checked_at", "expires_at"}, {"state", "checked_at", "expires_at", "reason_code"}, "capability.health")
    if health["state"] not in HEALTH_STATES:
        raise WorkError("capability health state is invalid")
    checked = parse_datetime(health["checked_at"], "capability.health.checked_at")
    expires = parse_datetime(health["expires_at"], "capability.health.expires_at")
    if expires < checked:
        raise WorkError("capability health expires before it was checked")
    provenance = require_fields(value["provenance"], {"source", "observed_at"}, {"source", "observed_at"}, "capability.provenance")
    if not isinstance(provenance["source"], str) or not provenance["source"]:
        raise WorkError("capability provenance source must be non-empty")
    parse_datetime(provenance["observed_at"], "capability.provenance.observed_at")
    quality = require_fields(value["quality"], {"provenance", "observations"}, {"provenance", "observations", "predicted_success"}, "capability.quality")
    if quality["provenance"] not in {"MEASURED", "CONFIGURED", "UNKNOWN"}:
        raise WorkError("capability quality provenance is invalid")
    if isinstance(quality["observations"], bool) or not isinstance(quality["observations"], int) or quality["observations"] < 0:
        raise WorkError("capability quality observations must be a non-negative integer")
    normalized_quality = {"provenance": quality["provenance"], "observations": quality["observations"]}
    if "predicted_success" in quality:
        predicted = number(quality["predicted_success"], "capability.quality.predicted_success")
        if predicted > 1:
            raise WorkError("capability quality predicted_success must not exceed 1")
        normalized_quality["predicted_success"] = float(predicted)
    if quality["provenance"] == "UNKNOWN" and "predicted_success" in quality:
        raise WorkError("unknown quality provenance cannot carry a predicted success value")
    resources = require_fields(value["resources"], set(), set(RESOURCE_LIMITS), "capability.resources")
    normalized_resources = {field: float(number(item, f"capability.resources.{field}")) for field, item in resources.items()}
    cost = require_fields(value["cost_model"], {"provenance"}, {"provenance", "currency", "estimated_cost"}, "capability.cost_model")
    if cost["provenance"] not in {"MEASURED", "CONFIGURED", "PROVIDER_QUOTED", "UNKNOWN"}:
        raise WorkError("capability cost provenance is invalid")
    normalized_cost = {"provenance": cost["provenance"]}
    if "currency" in cost:
        if cost["currency"] != "USD":
            raise WorkError("only an evidenced USD cost may be compared")
        normalized_cost["currency"] = "USD"
    if "estimated_cost" in cost:
        normalized_cost["estimated_cost"] = float(number(cost["estimated_cost"], "capability.cost_model.estimated_cost"))
    if cost["provenance"] == "UNKNOWN" and "estimated_cost" in cost:
        raise WorkError("unknown cost provenance cannot carry an estimated monetary cost")
    execution = require_fields(
        value.get("execution", {}),
        set(),
        {"idempotency", "resume"},
        "capability.execution",
    )
    if execution.get("idempotency", "NONE") not in {"NONE", "IDEMPOTENT_REPLAY"}:
        raise WorkError("capability execution.idempotency is invalid")
    if execution.get("resume", "RESTART") not in {"RESTART", "QUERY", "UNSUPPORTED"}:
        raise WorkError("capability execution.resume is invalid")
    normalized = {
        **value,
        "required_authorities": authorities,
        "functions": functions,
        "data_classes_allowed": sorted(data_classes),
        "health": {**health, "checked_at": isoformat(checked), "expires_at": isoformat(expires)},
        "provenance": {**provenance, "observed_at": isoformat(parse_datetime(provenance["observed_at"], "capability.provenance.observed_at"))},
        "quality": normalized_quality,
        "resources": normalized_resources,
        "cost_model": normalized_cost,
    }
    if "execution" in value:
        normalized["execution"] = {
            "idempotency": execution.get("idempotency", "NONE"),
            "resume": execution.get("resume", "RESTART"),
        }
    return normalized


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def digest(value: Any) -> str:
    return "sha256:" + hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()


def _eligibility(request: dict[str, Any], capability: dict[str, Any], at: datetime) -> list[str]:
    reasons: list[str] = []
    health = capability["health"]
    if health["state"] not in {"HEALTHY", "DEGRADED"}:
        reasons.append("HEALTH_NOT_USABLE")
    if parse_datetime(health["expires_at"], "capability.health.expires_at") <= at:
        reasons.append("HEALTH_EXPIRED")
    if parse_datetime(health["checked_at"], "capability.health.checked_at") > at:
        reasons.append("HEALTH_NOT_YET_VALID")
    boundary = capability["execution_boundary"]
    if boundary not in request["allowed_execution_boundaries"]:
        reasons.append("BOUNDARY_NOT_ALLOWED")
    if request["data_class"] not in capability["data_classes_allowed"]:
        reasons.append("DATA_CLASS_NOT_SUPPORTED")
    if boundary in {"REMOTE", "UNKNOWN"} and request["data_class"] not in request["authorization"]["remote_data_classes"]:
        reasons.append("REMOTE_DATA_NOT_AUTHORIZED")
    granted = set(request["authorization"]["granted_authorities"])
    if not set(capability["required_authorities"]) <= granted:
        reasons.append("CAPABILITY_AUTHORITY_MISSING")
    limits = request["limits"]
    if "minimum_success_probability" in request["quality"]:
        quality = capability["quality"]
        if quality["provenance"] == "UNKNOWN" or "predicted_success" not in quality:
            reasons.append("QUALITY_UNKNOWN_UNDER_HARD_LIMIT")
        elif Decimal(str(quality["predicted_success"])) < Decimal(str(request["quality"]["minimum_success_probability"])):
            reasons.append("QUALITY_FLOOR_NOT_MET")
    cost = capability["cost_model"]
    if "max_cost_usd" in limits:
        if cost["provenance"] == "UNKNOWN" or "estimated_cost" not in cost:
            reasons.append("COST_UNKNOWN_UNDER_HARD_LIMIT")
        elif Decimal(str(cost["estimated_cost"])) > Decimal(str(limits["max_cost_usd"])):
            reasons.append("COST_LIMIT_EXCEEDED")
    for resource, limit_name in RESOURCE_LIMITS.items():
        if limit_name in limits:
            if resource not in capability["resources"]:
                reasons.append(f"{resource.upper()}_UNKNOWN_UNDER_HARD_LIMIT")
            elif Decimal(str(capability["resources"][resource])) > Decimal(str(limits[limit_name])):
                reasons.append(f"{resource.upper()}_LIMIT_EXCEEDED")
    return reasons


def _rank(request: dict[str, Any], capability: dict[str, Any]) -> tuple[Any, ...]:
    deterministic = 0 if capability["deterministic"] else 1
    cost = capability["cost_model"]
    cost_unknown = 1 if cost["provenance"] == "UNKNOWN" or "estimated_cost" not in cost else 0
    cost_value = Decimal(str(cost.get("estimated_cost", 0)))
    pressure = Decimal(0)
    for resource, limit_name in RESOURCE_LIMITS.items():
        if resource not in capability["resources"]:
            continue
        limit = request["limits"].get(limit_name)
        amount = Decimal(str(capability["resources"][resource]))
        pressure += amount / Decimal(str(limit)) if limit not in (None, 0) else amount
    boundary_order = {"PROCESS": 0, "HOST": 1, "LOCAL_NETWORK": 2, "REMOTE": 3, "UNKNOWN": 4, "HUMAN": 5}
    return deterministic, cost_unknown, cost_value, pressure, boundary_order[capability["execution_boundary"]], capability["capability_id"]


def validate_capabilities_isolated(capabilities_raw: Any) -> tuple[list[dict[str, Any]], list[dict[str, str]]]:
    if not isinstance(capabilities_raw, list):
        raise WorkError("capability catalog must be an array")
    valid: list[dict[str, Any]] = []
    invalid: list[dict[str, str]] = []
    for index, raw in enumerate(capabilities_raw):
        try:
            valid.append(validate_capability(raw))
        except WorkError:
            candidate_id = raw.get("capability_id") if isinstance(raw, dict) else None
            label = candidate_id if isinstance(candidate_id, str) and candidate_id else f"catalog-entry:{index}"
            invalid.append({"capability_id": label, "reason_code": "INVALID_DESCRIPTOR"})
    counts: dict[str, int] = {}
    for item in valid:
        counts[item["capability_id"]] = counts.get(item["capability_id"], 0) + 1
    duplicates = {key for key, count in counts.items() if count > 1}
    if duplicates:
        valid = [item for item in valid if item["capability_id"] not in duplicates]
        invalid.extend({"capability_id": key, "reason_code": "DUPLICATE_CAPABILITY_ID"} for key in sorted(duplicates))
    return valid, sorted(invalid, key=lambda item: (item["capability_id"], item["reason_code"]))


def plan(request_raw: Any, capabilities_raw: Any, *, at: datetime | None = None) -> dict[str, Any]:
    request = validate_request(request_raw)
    capabilities, invalid_descriptors = validate_capabilities_isolated(capabilities_raw)
    now = (at or utc_now()).astimezone(timezone.utc)
    granted = set(request["authorization"]["granted_authorities"])
    effect_authorities = {EFFECT_AUTHORITIES[effect] for effect in request["effects"]}
    missing_effect_authorities = sorted(effect_authorities - granted)
    deadline = parse_datetime(request["limits"]["deadline"], "limits.deadline") if "deadline" in request["limits"] else None
    reason_codes: list[str] = []
    status = "EXECUTABLE"
    if deadline is not None and deadline <= now:
        status = "BLOCKED"
        reason_codes.append("DEADLINE_EXPIRED")
    if missing_effect_authorities:
        status = "BLOCKED"
        reason_codes.extend(f"AUTHORITY_MISSING:{item}" for item in missing_effect_authorities)

    eligibility: dict[str, list[str]] = {item["capability_id"]: _eligibility(request, item, now) for item in capabilities}
    required = set(request["required_capabilities"])
    workers = [
        item for item in capabilities
        if required <= set(item["functions"]) and not eligibility[item["capability_id"]] and item["kind"] != "HUMAN"
    ]
    workers.sort(key=lambda item: _rank(request, item))
    validation_required = set(request["validation"]["required_capabilities"])
    validators = [
        item for item in capabilities
        if item["kind"] == "VALIDATOR"
        and validation_required <= set(item["functions"])
        and not eligibility[item["capability_id"]]
    ] if validation_required else []
    if request["validation"]["independent_required"] and workers:
        validators = [item for item in validators if item["capability_id"] != workers[0]["capability_id"]]
    validators.sort(key=lambda item: _rank(request, item))

    if status == "EXECUTABLE" and not workers:
        policy_reasons = {
            reason
            for item in capabilities
            if required <= set(item["functions"])
            for reason in eligibility[item["capability_id"]]
            if reason in {"REMOTE_DATA_NOT_AUTHORIZED", "CAPABILITY_AUTHORITY_MISSING", "BOUNDARY_NOT_ALLOWED", "DATA_CLASS_NOT_SUPPORTED"}
        }
        status = "BLOCKED" if policy_reasons else ("MANUAL_REQUIRED" if request["validation"]["allow_human"] else "UNAVAILABLE")
        reason_codes.extend(sorted(policy_reasons) or ["REQUIRED_CAPABILITY_UNAVAILABLE"])
    if status == "EXECUTABLE" and validation_required and not validators:
        status = "MANUAL_REQUIRED" if request["validation"]["allow_human"] else "UNAVAILABLE"
        reason_codes.append("INDEPENDENT_VALIDATION_UNAVAILABLE" if request["validation"]["independent_required"] else "REQUIRED_VALIDATOR_UNAVAILABLE")

    steps: list[dict[str, Any]] = []
    approval_points: list[dict[str, Any]] = []
    if status == "EXECUTABLE":
        worker = workers[0]
        output_handle = request["output"].get("handle", {}).get("handle_id", f"{request['work_id']}:output")
        steps.append({
            "step_id": "work",
            "capability_id": worker["capability_id"],
            "operation": request["task_class"],
            "depends_on": [],
            "alternatives": [item["capability_id"] for item in workers[1:]],
            "input_handles": [item["handle_id"] for item in request["input_handles"]],
            "output_handles": [output_handle],
        })
        if validation_required:
            validator = validators[0]
            steps.append({
                "step_id": "validate",
                "capability_id": validator["capability_id"],
                "operation": "validate",
                "depends_on": ["work"],
                "alternatives": [item["capability_id"] for item in validators[1:]],
                "input_handles": [output_handle],
                "output_handles": [f"{request['work_id']}:validation-evidence"],
            })
        gate_reasons = []
        if request["risk"] in {"HIGH", "CRITICAL"} and "approve:high_impact" not in granted:
            gate_reasons.append("HIGH_IMPACT")
        for effect in request["effects"]:
            if effect in {"PUBLISH", "EXTERNAL_WRITE", "DATA_TRANSFER", "SPEND"}:
                gate_reasons.append(effect)
        if gate_reasons:
            approval_points.append({
                "before_steps": ["work"],
                "authority_required": "approve:risk-boundary",
                "reasons": sorted(set(gate_reasons)),
            })
            if "approve:risk-boundary" not in granted:
                status = "MANUAL_REQUIRED"
                reason_codes.append("RISK_BOUNDARY_APPROVAL_REQUIRED")
    if status == "EXECUTABLE" and not reason_codes:
        reason_codes.append("COMPLETE_PLAN_AVAILABLE")
    elif status == "MANUAL_REQUIRED" and not reason_codes:
        reason_codes.append("MANUAL_CAPABILITY_REQUIRED")

    eligible_expiry = [
        parse_datetime(item["health"]["expires_at"], "capability.health.expires_at")
        for item in workers[:1] + validators[:1]
    ]
    valid_until = min([now + timedelta(minutes=5), *eligible_expiry]) if eligible_expiry else now + timedelta(minutes=5)
    if deadline is not None:
        valid_until = min(valid_until, deadline)
    identity_material = {
        "request": request,
        "selected": [item["capability_id"] for item in workers[:1] + validators[:1]],
        "at": isoformat(now),
    }
    return {
        "schema_version": 1,
        "contract": CONTRACT,
        "plan_id": digest(identity_material),
        "work_id": request["work_id"],
        "status": status,
        "generated_at": isoformat(now),
        "valid_until": isoformat(valid_until),
        "steps": steps,
        "approval_points": approval_points,
        "constraints": {
            "data_class": request["data_class"],
            "risk": request["risk"],
            "effects": request["effects"],
            "limits": request["limits"],
            "catalog_digest": digest(capabilities),
            "excluded_descriptors": invalid_descriptors,
        },
        "reason_codes": sorted(set(reason_codes)),
    }


def gap_report(request_raw: Any, capabilities_raw: Any, *, at: datetime | None = None) -> dict[str, Any]:
    request = validate_request(request_raw)
    capabilities, _invalid_descriptors = validate_capabilities_isolated(capabilities_raw)
    plan_value = plan(request, capabilities, at=at)
    available_functions = {function for item in capabilities for function in item["functions"]}
    missing = sorted(set(request["required_capabilities"]) - available_functions)
    if not missing and plan_value["status"] != "EXECUTABLE":
        missing = sorted(request["required_capabilities"])
    tested = sorted(item["capability_id"] for item in capabilities if set(request["required_capabilities"]) <= set(item["functions"]))
    remedy = None
    authorities: list[str] = []
    if missing:
        authorities.append("allow_local_adapter_synthesis")
        if request["authorization"]["allow_local_adapter_synthesis"]:
            remedy = {
                "description": "Generate an external least-privilege adapter and quarantine it until conformance passes.",
                "network_default": "DENY",
                "repository_write_default": "DENY",
                "conformance_required": True,
            }
    material = {"work_id": request["work_id"], "missing": missing, "tested": tested, "plan": plan_value["plan_id"]}
    return {
        "schema_version": 1,
        "contract": CONTRACT,
        "gap_id": digest(material),
        "work_id": request["work_id"],
        "missing_capabilities": missing or sorted(request["required_capabilities"]),
        "tested_alternatives": tested,
        "local_remedy": remedy,
        "required_authorities": authorities,
        "reason_codes": plan_value["reason_codes"],
    }


def load_json(path: str) -> Any:
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise WorkError(f"JSON file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise WorkError(f"invalid JSON file {path}: {exc}") from exc


def catalog_items(raw: Any) -> list[Any]:
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict) and set(raw) == {"capabilities"} and isinstance(raw["capabilities"], list):
        return raw["capabilities"]
    raise WorkError("capability catalog must be an array or an object containing only capabilities")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("plan", "gap"):
        command = sub.add_parser(name)
        command.add_argument("--request", required=True)
        command.add_argument("--capabilities", required=True)
        command.add_argument("--at", help="ISO-8601 planning time for deterministic replay")
    args = parser.parse_args(argv)
    try:
        request = load_json(args.request)
        capabilities = catalog_items(load_json(args.capabilities))
        at = parse_datetime(args.at, "--at") if args.at else None
        result = plan(request, capabilities, at=at) if args.command == "plan" else gap_report(request, capabilities, at=at)
        json.dump(result, sys.stdout, indent=2, sort_keys=True, ensure_ascii=False)
        sys.stdout.write("\n")
        return 0
    except WorkError as exc:
        print(json.dumps({"contract": CONTRACT, "status": "BLOCKED", "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

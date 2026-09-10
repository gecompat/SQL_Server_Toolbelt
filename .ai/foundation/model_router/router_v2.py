#!/usr/bin/env python3
"""Failure-isolated provider catalog aggregation and resource-aware router-v2 facade."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any

from model_router import (
    CONTRACT as CONTRACT_V1,
    DEFAULT_QUALITY_FLOORS,
    ModelRouter,
    REQUEST_FIELDS,
    RouterError,
    RuntimeStore,
    atomic_json_write,
    canonical_json,
    decimal_value,
    digest,
    ensure_runtime_location,
    isoformat,
    load_json,
    parse_datetime,
    validate_catalog,
    validate_request,
)


CONTRACT = "foundation-model-router/v2"
BOUNDARIES = {"PROCESS", "HOST", "LOCAL_NETWORK", "REMOTE", "UNKNOWN"}
DATA_CLASSES = {"PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"}
V2_FIELDS = {
    "schema_version", "contract", "data_class", "allowed_execution_boundaries", "remote_data_classes",
    "resource_limits", "max_latency_seconds",
}
RESOURCE_LIMITS = {
    "cpu_seconds": "max_cpu_seconds",
    "disk_mb": "max_disk_mb",
    "energy_wh": "max_energy_wh",
    "gpu_seconds": "max_gpu_seconds",
    "network_mb": "max_network_mb",
    "ram_mb": "max_ram_mb",
    "vram_mb": "max_vram_mb",
}


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def unique_strings(value: Any, field: str) -> list[str]:
    if not isinstance(value, list) or not value or any(not isinstance(item, str) or not item for item in value):
        raise RouterError(f"{field} must be a non-empty array of strings")
    if len(set(value)) != len(value):
        raise RouterError(f"{field} must contain unique values")
    return list(value)


def validate_v2_request(raw: Any) -> tuple[dict[str, Any], dict[str, Any]]:
    if not isinstance(raw, dict):
        raise RouterError("router-v2 request must be an object")
    if raw.get("schema_version") != 2 or raw.get("contract") != CONTRACT:
        raise RouterError(f"router-v2 request must use schema_version=2 and contract={CONTRACT}")
    allowed_fields = REQUEST_FIELDS | V2_FIELDS
    unknown = sorted(set(raw) - allowed_fields)
    if unknown:
        raise RouterError(f"unknown router-v2 request field(s): {', '.join(unknown)}")
    data_class = raw.get("data_class")
    if data_class not in DATA_CLASSES:
        raise RouterError("router-v2 data_class is invalid")
    boundaries = unique_strings(raw.get("allowed_execution_boundaries"), "allowed_execution_boundaries")
    if not set(boundaries) <= BOUNDARIES:
        raise RouterError("allowed_execution_boundaries contains an invalid boundary")
    remote_classes = raw.get("remote_data_classes")
    if not isinstance(remote_classes, list) or any(item not in DATA_CLASSES for item in remote_classes) or len(set(remote_classes)) != len(remote_classes):
        raise RouterError("remote_data_classes must contain unique Foundation data classes")
    limits = raw.get("resource_limits")
    if not isinstance(limits, dict) or set(limits) - set(RESOURCE_LIMITS.values()):
        raise RouterError("resource_limits contains an unknown limit")
    normalized_limits = {
        field: float(decimal_value(value, f"resource_limits.{field}", minimum=Decimal(0)))
        for field, value in limits.items()
    }
    max_latency = raw.get("max_latency_seconds")
    normalized_latency = (
        float(decimal_value(max_latency, "max_latency_seconds", minimum=Decimal(0)))
        if max_latency is not None
        else None
    )
    v1 = {key: value for key, value in raw.items() if key not in V2_FIELDS}
    return validate_request(v1), {
        "data_class": data_class,
        "allowed_execution_boundaries": sorted(boundaries),
        "remote_data_classes": sorted(remote_classes),
        "resource_limits": normalized_limits,
        "max_latency_seconds": normalized_latency,
    }


def validate_fragment(raw: Any) -> dict[str, Any]:
    fields = {
        "schema_version", "contract", "provider", "adapter", "execution_boundary", "generated_at",
        "valid_until", "pricing_epoch", "health", "provenance", "models",
    }
    if not isinstance(raw, dict) or set(raw) != fields:
        raise RouterError("catalog fragment has missing or unknown fields")
    if raw["schema_version"] != 2 or raw["contract"] != CONTRACT:
        raise RouterError(f"catalog fragment must use {CONTRACT}")
    for field in ("provider", "adapter", "pricing_epoch"):
        if not isinstance(raw[field], str) or not raw[field]:
            raise RouterError(f"catalog fragment {field} must be non-empty")
    if raw["execution_boundary"] not in BOUNDARIES:
        raise RouterError("catalog fragment execution_boundary is invalid")
    generated = parse_datetime(raw["generated_at"], "fragment.generated_at")
    valid_until = parse_datetime(raw["valid_until"], "fragment.valid_until")
    if valid_until <= generated:
        raise RouterError("catalog fragment expiry must follow generation")
    health = raw["health"]
    if not isinstance(health, dict) or not {"state", "checked_at", "expires_at"} <= set(health):
        raise RouterError("catalog fragment health is incomplete")
    if set(health) - {"state", "checked_at", "expires_at", "reason_code"}:
        raise RouterError("catalog fragment health has unknown fields")
    if health["state"] not in {"HEALTHY", "DEGRADED", "UNAVAILABLE", "UNKNOWN"}:
        raise RouterError("catalog fragment health state is invalid")
    checked = parse_datetime(health["checked_at"], "fragment.health.checked_at")
    health_expiry = parse_datetime(health["expires_at"], "fragment.health.expires_at")
    if health_expiry <= checked:
        raise RouterError("catalog fragment health expiry must follow check")
    provenance = raw["provenance"]
    if not isinstance(provenance, dict) or set(provenance) != {"source", "observed_at"}:
        raise RouterError("catalog fragment provenance is invalid")
    if not isinstance(provenance["source"], str) or not provenance["source"]:
        raise RouterError("catalog fragment provenance source must be non-empty")
    parse_datetime(provenance["observed_at"], "fragment.provenance.observed_at")
    if not isinstance(raw["models"], dict):
        raise RouterError("catalog fragment models must be an object")
    provider_catalog = {
        "schema_version": 1,
        "contract": CONTRACT_V1,
        "generated_at": raw["generated_at"],
        "valid_until": raw["valid_until"],
        "pricing_epoch": raw["pricing_epoch"],
        "catalog_epoch": digest({"provider": raw["provider"], "models": raw["models"]}),
        "providers": {
            raw["provider"]: {
                "adapter": raw["adapter"],
                "remote": raw["execution_boundary"] in {"LOCAL_NETWORK", "REMOTE", "UNKNOWN"},
                "execution_boundary": raw["execution_boundary"],
                "models": raw["models"],
            }
        },
    }
    validate_catalog(provider_catalog)
    return json.loads(canonical_json(raw))


class ProviderFragmentStore:
    """Per-provider last-known-good fragments outside version control."""

    def __init__(self, root: Path) -> None:
        self.root = ensure_runtime_location(root) / "provider-fragments-v2"
        self.index_path = self.root / "index.json"

    def _path(self, provider: str) -> Path:
        return self.root / (digest(provider)[7:] + ".json")

    def providers(self) -> list[str]:
        if not self.index_path.exists():
            return []
        raw = load_json(self.index_path, "provider fragment index")
        values = raw.get("providers", [])
        return sorted(item for item in values if isinstance(item, str) and item)

    def load(self, provider: str) -> dict[str, Any] | None:
        path = self._path(provider)
        if not path.exists():
            return None
        try:
            fragment = validate_fragment(load_json(path, "last-known-good provider fragment"))
        except RouterError:
            return None
        return fragment if fragment["provider"] == provider else None

    def write(self, fragment: dict[str, Any]) -> None:
        validated = validate_fragment(fragment)
        atomic_json_write(self._path(validated["provider"]), validated)
        providers = sorted(set(self.providers()) | {validated["provider"]})
        atomic_json_write(self.index_path, {"schema_version": 1, "providers": providers})


def _fragment_usable(fragment: dict[str, Any], at: datetime) -> tuple[bool, str]:
    health = fragment["health"]
    if health["state"] not in {"HEALTHY", "DEGRADED"}:
        return False, f"HEALTH_{health['state']}"
    if parse_datetime(health["checked_at"], "fragment.health.checked_at") > at:
        return False, "HEALTH_NOT_YET_VALID"
    if parse_datetime(health["expires_at"], "fragment.health.expires_at") <= at:
        return False, "HEALTH_EXPIRED"
    if parse_datetime(fragment["valid_until"], "fragment.valid_until") <= at:
        return False, "CATALOG_EXPIRED"
    return True, "USABLE"


def aggregate_fragments(
    raw_fragments: Any,
    *,
    at: datetime,
    store: ProviderFragmentStore | None = None,
) -> tuple[dict[str, Any], list[dict[str, str]], dict[str, dict[str, Any]]]:
    if not isinstance(raw_fragments, list):
        raise RouterError("provider fragments must be an array")
    current: dict[str, dict[str, Any]] = {}
    statuses: list[dict[str, str]] = []
    invalid_providers: set[str] = set()
    for index, raw in enumerate(raw_fragments):
        provider_hint = raw.get("provider") if isinstance(raw, dict) and isinstance(raw.get("provider"), str) else f"fragment:{index}"
        try:
            fragment = validate_fragment(raw)
        except RouterError:
            invalid_providers.add(provider_hint)
            statuses.append({"provider": provider_hint, "source": "EXCLUDED", "execution_boundary": "UNKNOWN", "reason_code": "INVALID_FRAGMENT"})
            continue
        previous = current.get(fragment["provider"])
        if previous is None or parse_datetime(fragment["generated_at"], "fragment.generated_at") > parse_datetime(previous["generated_at"], "fragment.generated_at"):
            current[fragment["provider"]] = fragment

    providers = set(current) | invalid_providers | (set(store.providers()) if store else set())
    selected: dict[str, dict[str, Any]] = {}
    selected_source: dict[str, str] = {}
    for provider in sorted(providers):
        fragment = current.get(provider)
        if fragment is not None:
            usable, reason = _fragment_usable(fragment, at)
            if usable:
                selected[provider] = fragment
                selected_source[provider] = "CURRENT"
                if store:
                    store.write(fragment)
            else:
                statuses.append({"provider": provider, "source": "EXCLUDED", "execution_boundary": fragment["execution_boundary"], "reason_code": reason})
        if provider not in selected and store:
            fallback = store.load(provider)
            if fallback is not None:
                usable, reason = _fragment_usable(fallback, at)
                if usable:
                    selected[provider] = fallback
                    selected_source[provider] = "LAST_KNOWN_GOOD"
                elif not any(item["provider"] == provider for item in statuses):
                    statuses.append({"provider": provider, "source": "EXCLUDED", "execution_boundary": fallback["execution_boundary"], "reason_code": reason})

    for provider, fragment in sorted(selected.items()):
        statuses.append(
            {
                "provider": provider,
                "source": selected_source[provider],
                "execution_boundary": fragment["execution_boundary"],
                "reason_code": "USABLE",
            }
        )
    expiries = [parse_datetime(item["valid_until"], "fragment.valid_until") for item in selected.values()]
    valid_until = min(expiries) if expiries else at + timedelta(minutes=5)
    combined = {
        "schema_version": 1,
        "contract": CONTRACT_V1,
        "generated_at": isoformat(at),
        "valid_until": isoformat(valid_until),
        "pricing_epoch": digest({provider: item["pricing_epoch"] for provider, item in sorted(selected.items())}),
        "catalog_epoch": digest(selected),
        "router_defaults": {
            "tier_quality_floors": DEFAULT_QUALITY_FLOORS,
            "quality_prior_strength": 4,
            "minimum_evaluation_trials": 3,
            "daily_evaluation_budget_usd": 0,
            "failure_cost_usd": 0,
            "latency_value_usd_per_second": 0,
            "switching_cost_usd": 0,
        },
        "providers": {
            provider: {
                "adapter": fragment["adapter"],
                "remote": fragment["execution_boundary"] in {"LOCAL_NETWORK", "REMOTE", "UNKNOWN"},
                "execution_boundary": fragment["execution_boundary"],
                "models": fragment["models"],
            }
            for provider, fragment in sorted(selected.items())
        },
    }
    validate_catalog(combined)
    return combined, sorted(statuses, key=lambda item: (item["provider"], item["source"], item["reason_code"])), selected


def _resource_reasons(model: dict[str, Any], limits: dict[str, float]) -> list[str]:
    estimate = model.get("resource_estimate")
    if not isinstance(estimate, dict):
        return ["RESOURCE_ESTIMATE_UNKNOWN"] if limits else []
    if limits and model.get("resource_provenance", "UNKNOWN") not in {"MEASURED", "CONFIGURED"}:
        return ["RESOURCE_PROVENANCE_UNKNOWN"]
    reasons: list[str] = []
    for resource, limit_name in RESOURCE_LIMITS.items():
        if limit_name not in limits:
            continue
        if resource not in estimate:
            reasons.append(f"{resource.upper()}_UNKNOWN")
        elif decimal_value(estimate[resource], f"resource_estimate.{resource}", minimum=Decimal(0)) > Decimal(str(limits[limit_name])):
            reasons.append(f"{resource.upper()}_LIMIT_EXCEEDED")
    return reasons


def _resource_economics(
    model: dict[str, Any], limits: dict[str, float], at: datetime
) -> tuple[Decimal, Decimal]:
    estimate = model.get("resource_estimate", {})
    pressure = Decimal(0)
    for resource, limit_name in RESOURCE_LIMITS.items():
        if limit_name not in limits or resource not in estimate:
            continue
        limit = Decimal(str(limits[limit_name]))
        value = decimal_value(estimate[resource], f"resource_estimate.{resource}", minimum=Decimal(0))
        if limit > 0:
            pressure += value / limit

    configured = model.get("resource_cost")
    if configured is None:
        return Decimal(0), pressure
    required = {"currency", "estimated_cost", "provenance", "evidence_id", "source", "observed_at", "valid_until"}
    if not isinstance(configured, dict) or set(configured) != required:
        raise RouterError("resource_cost has an invalid evidence shape")
    if configured["currency"] != "USD" or configured["provenance"] not in {"MEASURED", "CONFIGURED"}:
        raise RouterError("resource_cost requires USD and measured or configured provenance")
    for field in ("evidence_id", "source"):
        if not isinstance(configured[field], str) or not configured[field]:
            raise RouterError(f"resource_cost {field} must be non-empty")
    observed = parse_datetime(configured["observed_at"], "resource_cost.observed_at")
    valid_until = parse_datetime(configured["valid_until"], "resource_cost.valid_until")
    if observed > at or valid_until <= observed:
        raise RouterError("resource_cost evidence interval is invalid")
    if valid_until <= at:
        raise RouterError("resource_cost evidence is expired")
    return decimal_value(configured["estimated_cost"], "resource_cost.estimated_cost", minimum=Decimal(0)), pressure


def route_v2(
    raw_request: Any,
    raw_fragments: Any,
    *,
    runtime_store: RuntimeStore,
    fragment_store: ProviderFragmentStore | None = None,
    at: datetime | None = None,
) -> dict[str, Any]:
    v1_request, constraints = validate_v2_request(raw_request)
    now = at or (parse_datetime(v1_request["at"], "request.at") if v1_request.get("at") else utc_now())
    catalog, fragment_status, selected = aggregate_fragments(raw_fragments, at=now, store=fragment_store)
    exclusions: list[dict[str, str]] = []
    for provider, fragment in list(selected.items()):
        boundary = fragment["execution_boundary"]
        if boundary not in constraints["allowed_execution_boundaries"]:
            catalog["providers"].pop(provider, None)
            exclusions.append({"provider": provider, "source": "EXCLUDED", "execution_boundary": boundary, "reason_code": "BOUNDARY_NOT_ALLOWED"})
            continue
        if boundary in {"LOCAL_NETWORK", "REMOTE", "UNKNOWN"} and constraints["data_class"] not in constraints["remote_data_classes"]:
            catalog["providers"].pop(provider, None)
            exclusions.append({"provider": provider, "source": "EXCLUDED", "execution_boundary": boundary, "reason_code": "REMOTE_DATA_NOT_AUTHORIZED"})
            continue
        for model_id, model in list(catalog["providers"][provider]["models"].items()):
            resource_reasons = _resource_reasons(model, constraints["resource_limits"])
            latency_limit = constraints["max_latency_seconds"]
            if latency_limit is not None:
                if "latency_seconds_prior" not in model:
                    resource_reasons.append("LATENCY_UNKNOWN")
                elif decimal_value(
                    model["latency_seconds_prior"],
                    f"{provider}/{model_id}.latency_seconds_prior",
                    minimum=Decimal(0),
                ) > Decimal(str(latency_limit)):
                    resource_reasons.append("LATENCY_LIMIT_EXCEEDED")
            quality_provenance = model.get("quality_provenance", "UNKNOWN")
            if quality_provenance not in {"MEASURED", "CONFIGURED"}:
                resource_reasons.append("QUALITY_PROVENANCE_UNKNOWN")
            if resource_reasons:
                catalog["providers"][provider]["models"].pop(model_id)
                for reason in resource_reasons:
                    exclusions.append({"provider": provider, "source": "EXCLUDED", "execution_boundary": boundary, "reason_code": f"{model_id}:{reason}"})
                continue
            try:
                resource_cost, resource_pressure = _resource_economics(model, constraints["resource_limits"], now)
            except RouterError as exc:
                catalog["providers"][provider]["models"].pop(model_id)
                exclusions.append(
                    {
                        "provider": provider,
                        "source": "EXCLUDED",
                        "execution_boundary": boundary,
                        "reason_code": f"{model_id}:{'RESOURCE_COST_EXPIRED' if str(exc) == 'resource_cost evidence is expired' else 'RESOURCE_COST_INVALID'}",
                    }
                )
                continue
            model["fixed_attempt_cost_usd"] = float(resource_cost)
            model["resource_pressure"] = float(resource_pressure)
    catalog["catalog_epoch"] = digest(catalog["providers"])
    validate_catalog(catalog)
    decision = ModelRouter(catalog, runtime_store).route(v1_request)
    route = decision.get("route")
    provider = route.get("provider") if isinstance(route, dict) else None
    fragment = selected.get(provider) if provider else None
    boundary = fragment["execution_boundary"] if fragment else ("NONE" if decision["status"] == "LOCAL_ONLY" else "UNKNOWN")
    resource_evidence = None
    if provider and isinstance(route, dict):
        model = catalog["providers"][provider]["models"][route["model"]]
        resource_evidence = {
            "estimate": model.get("resource_estimate", {}),
            "provenance": model.get("resource_provenance", "UNKNOWN"),
            "limits": constraints["resource_limits"],
        }
    statuses = [item for item in fragment_status if item["provider"] not in {row["provider"] for row in exclusions}] + exclusions
    reasons = sorted(set(decision.get("reason_codes", [])) | {item["reason_code"] for item in exclusions})
    return {
        "schema_version": 2,
        "contract": CONTRACT,
        "status": decision["status"],
        "generated_at": decision["generated_at"],
        "valid_until": decision["valid_until"],
        "execution_boundary": boundary,
        "resource_evidence": resource_evidence,
        "catalog_fragments": sorted(statuses, key=lambda item: (item["provider"], item["source"], item["reason_code"])),
        "reason_codes": reasons,
        "v1_decision": decision,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--request", required=True)
    parser.add_argument("--fragments", required=True)
    parser.add_argument("--state-dir")
    parser.add_argument("--at")
    args = parser.parse_args(argv)
    try:
        request = load_json(Path(args.request), "router-v2 request")
        fragments_doc = load_json(Path(args.fragments), "provider fragments")
        fragments = fragments_doc.get("fragments")
        if set(fragments_doc) != {"fragments"} or not isinstance(fragments, list):
            raise RouterError("provider fragments file must contain only a fragments array")
        runtime = RuntimeStore(Path(args.state_dir) if args.state_dir else None)
        fragment_store = ProviderFragmentStore(runtime.root)
        result = route_v2(
            request,
            fragments,
            runtime_store=runtime,
            fragment_store=fragment_store,
            at=parse_datetime(args.at, "--at") if args.at else None,
        )
        print(json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False))
        return 0
    except RouterError as exc:
        print(json.dumps({"contract": CONTRACT, "status": "NO_ROUTE", "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

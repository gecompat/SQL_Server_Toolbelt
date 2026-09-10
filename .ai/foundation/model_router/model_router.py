#!/usr/bin/env python3
"""Dependency-free, provider-neutral, cost-of-success model router and CLI."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import itertools
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Callable, Iterator


CONTRACT = "foundation-model-router/v1"
TIERS = ("LOCAL", "ECONOMICAL", "BALANCED", "FRONTIER")
DEFAULT_QUALITY_FLOORS = {
    "ECONOMICAL": 0.45,
    "BALANCED": 0.65,
    "FRONTIER": 0.82,
}
DEFAULT_TIER_EFFORT = {
    "ECONOMICAL": "low",
    "BALANCED": "medium",
    "FRONTIER": "high",
}
VALIDATION_STRATEGIES = {
    "LOCAL": "deterministic_local_validation",
    "ECONOMICAL": "focused_deterministic_validation",
    "BALANCED": "affected_regression_and_deterministic_validation",
    "FRONTIER": "independent_review_and_full_validation",
}
CHAIN_MATERIAL_BENEFIT_RATIO = Decimal("0.001")
CHAIN_MATERIAL_BENEFIT_ABSOLUTE_USD = Decimal("0.000000000001")
REQUEST_FIELDS = {
    "tier",
    "task_class",
    "context_tokens",
    "cached_input_tokens",
    "expected_output_tokens",
    "required_capabilities",
    "allowed_providers",
    "allow_remote",
    "allow_evaluation",
    "allow_unknown_context",
    "quality_floor",
    "max_cost_usd",
    "failure_cost_usd",
    "latency_value_usd_per_second",
    "switching_cost_usd",
    "session_id",
    "current_provider",
    "current_model",
    "failed_models",
    "preferred_reasoning_effort",
    "max_fallbacks",
    "at",
}
ASSESSMENTS = {"ASSESSED", "UNASSESSED", "DISABLED"}
AVAILABILITY = {"AVAILABLE", "PRICED_NOT_DISCOVERED", "MISSING_PRICE", "UNAVAILABLE"}
ROUTER_DEFAULT_FIELDS = {
    "tier_quality_floors",
    "quality_prior_strength",
    "minimum_evaluation_trials",
    "daily_evaluation_budget_usd",
    "failure_cost_usd",
    "latency_value_usd_per_second",
    "switching_cost_usd",
}


class RouterError(RuntimeError):
    """A bounded, user-actionable router failure."""


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_datetime(value: str, field: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (TypeError, ValueError) as exc:
        raise RouterError(f"{field} must be an ISO-8601 timestamp") from exc
    if parsed.tzinfo is None:
        raise RouterError(f"{field} must include a timezone")
    return parsed.astimezone(timezone.utc)


def decimal_value(value: Any, field: str, *, minimum: Decimal | None = None) -> Decimal:
    if isinstance(value, bool) or not isinstance(value, (int, float, Decimal)):
        raise RouterError(f"{field} must be numeric")
    try:
        result = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError) as exc:
        raise RouterError(f"{field} must be numeric") from exc
    if not result.is_finite() or (minimum is not None and result < minimum):
        raise RouterError(f"{field} is outside its permitted range")
    return result


def number(value: Decimal) -> float:
    return float(value.quantize(Decimal("0.000000000001")))


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def digest(value: Any) -> str:
    return "sha256:" + hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()


def load_json(path: Path, description: str = "JSON file") -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise RouterError(f"{description} not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise RouterError(f"invalid {description} {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RouterError(f"{description} root must be an object: {path}")
    return value


def find_git_root(start: Path) -> Path | None:
    current = start.resolve()
    for candidate in (current, *current.parents):
        if (candidate / ".git").exists():
            return candidate
    return None


def default_state_dir() -> Path:
    override = os.environ.get("AI_MODEL_ROUTER_HOME")
    if override:
        return Path(override).expanduser().resolve()
    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA")
        if base:
            return (Path(base) / "ai-model-router").resolve()
    if sys.platform == "darwin":
        return (Path.home() / "Library" / "Application Support" / "ai-model-router").resolve()
    base = os.environ.get("XDG_STATE_HOME")
    return ((Path(base).expanduser() if base else Path.home() / ".local" / "state") / "ai-model-router").resolve()


def ensure_runtime_location(state_dir: Path) -> Path:
    resolved = state_dir.expanduser().resolve()
    repo = find_git_root(resolved)
    if repo is not None:
        raise RouterError(
            f"runtime state must remain outside version control; choose a state directory outside {repo}"
        )
    return resolved


@contextlib.contextmanager
def exclusive_lock(path: Path, timeout_seconds: float = 5.0) -> Iterator[None]:
    deadline = time.monotonic() + timeout_seconds
    path.parent.mkdir(parents=True, exist_ok=True)
    fd: int | None = None
    while fd is None:
        try:
            fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            os.write(fd, f"pid={os.getpid()}\n".encode("ascii"))
            os.fsync(fd)
        except FileExistsError:
            if time.monotonic() >= deadline:
                raise RouterError(f"timed out waiting for runtime-state lock: {path}")
            time.sleep(0.05)
    try:
        yield
    finally:
        if fd is not None:
            os.close(fd)
        try:
            path.unlink()
        except FileNotFoundError:
            pass


def atomic_json_write(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    fd, temporary = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        try:
            Path(temporary).unlink()
        except FileNotFoundError:
            pass


class RuntimeStore:
    """Local non-versioned outcomes, session affinity, and evaluation reservations."""

    def __init__(self, state_dir: Path | None = None) -> None:
        self.root = ensure_runtime_location(state_dir or default_state_dir())
        self.catalog_path = self.root / "catalog.json"
        self.state_path = self.root / "runtime-state.json"
        self.lock_path = self.root / "runtime-state.lock"

    @staticmethod
    def empty_state() -> dict[str, Any]:
        return {
            "schema_version": 1,
            "contract": CONTRACT,
            "outcomes": {},
            "sessions": {},
            "evaluation": {"spend_by_utc_date": {}, "reservations": {}, "pairs": {}},
        }

    def load(self) -> dict[str, Any]:
        if not self.state_path.exists():
            return self.empty_state()
        state = load_json(self.state_path, "runtime state")
        if state.get("schema_version") != 1 or state.get("contract") != CONTRACT:
            raise RouterError(f"unsupported runtime state contract: {self.state_path}")
        return state

    def mutate(self, callback: Callable[[dict[str, Any]], Any]) -> Any:
        with exclusive_lock(self.lock_path):
            state = self.load()
            result = callback(state)
            atomic_json_write(self.state_path, state)
            return result

    def write_catalog(self, catalog: dict[str, Any]) -> None:
        lock = self.root / "catalog.lock"
        with exclusive_lock(lock):
            atomic_json_write(self.catalog_path, catalog)

    @staticmethod
    def session_key(session_id: str) -> str:
        return hashlib.sha256(session_id.encode("utf-8")).hexdigest()

    def record_outcome(
        self,
        *,
        provider: str,
        model: str,
        task_class: str,
        success: bool,
        actual_cost_usd: Decimal,
        latency_ms: Decimal | None = None,
        session_id: str | None = None,
        context_tokens: int = 0,
        pricing_epoch: str | None = None,
        evaluation_id: str | None = None,
        recorded_at: datetime | None = None,
    ) -> dict[str, Any]:
        for field, value in (("provider", provider), ("model", model), ("task_class", task_class)):
            if not isinstance(value, str) or not value:
                raise RouterError(f"{field} must be a non-empty string")
        if not actual_cost_usd.is_finite() or actual_cost_usd < 0:
            raise RouterError("actual_cost_usd must be non-negative")
        if latency_ms is not None and (not latency_ms.is_finite() or latency_ms < 0):
            raise RouterError("latency_ms must be non-negative")
        if isinstance(context_tokens, bool) or not isinstance(context_tokens, int) or context_tokens < 0:
            raise RouterError("context_tokens must be a non-negative integer")
        if session_id and not pricing_epoch:
            raise RouterError("pricing_epoch is required when recording session affinity")
        now = recorded_at or utc_now()
        key = canonical_json([provider, model, task_class])

        def update(state: dict[str, Any]) -> dict[str, Any]:
            reservation: dict[str, Any] | None = None
            if evaluation_id:
                reservation = state.setdefault("evaluation", {}).setdefault("reservations", {}).get(evaluation_id)
                if not isinstance(reservation, dict):
                    raise RouterError("evaluation_id is not an active reservation")
                if reservation.get("provider") != provider or reservation.get("model") != model:
                    raise RouterError("evaluation reservation does not match provider/model")
                if parse_datetime(reservation["expires_at"], "evaluation.expires_at") <= now:
                    raise RouterError("evaluation reservation has expired")
                if pricing_epoch != reservation.get("pricing_epoch"):
                    raise RouterError("evaluation pricing_epoch does not match the reservation")
            outcomes = state.setdefault("outcomes", {})
            row = outcomes.setdefault(
                key,
                {
                    "provider": provider,
                    "model": model,
                    "task_class": task_class,
                    "successes": 0,
                    "failures": 0,
                    "actual_cost_usd": 0.0,
                    "latency_ms_ema": None,
                },
            )
            row["successes" if success else "failures"] += 1
            row["actual_cost_usd"] = number(
                decimal_value(row.get("actual_cost_usd", 0), "stored actual cost", minimum=Decimal(0))
                + actual_cost_usd
            )
            if latency_ms is not None:
                previous = row.get("latency_ms_ema")
                row["latency_ms_ema"] = number(
                    latency_ms if previous is None else Decimal("0.25") * latency_ms + Decimal("0.75") * Decimal(str(previous))
                )
            row["last_recorded_at"] = isoformat(now)

            if session_id:
                state.setdefault("sessions", {})[self.session_key(session_id)] = {
                    "provider": provider,
                    "model": model,
                    "context_tokens": context_tokens,
                    "pricing_epoch": pricing_epoch,
                    "expires_at": isoformat(now + timedelta(hours=12)),
                }

            if evaluation_id:
                evaluation = state.setdefault("evaluation", {})
                reservation = evaluation.setdefault("reservations", {}).pop(evaluation_id, None)
                utc_date = now.date().isoformat()
                spend = evaluation.setdefault("spend_by_utc_date", {})
                spend[utc_date] = number(Decimal(str(spend.get(utc_date, 0))) + actual_cost_usd)
                row["last_evaluation_id"] = evaluation_id
                if reservation is not None:
                    row["last_evaluation_reserved_usd"] = reservation.get("reserved_usd")
                    pair_id = reservation.get("pair_id")
                    arm = reservation.get("arm")
                    if pair_id and arm:
                        pair = evaluation.setdefault("pairs", {}).get(pair_id)
                        if not isinstance(pair, dict) or pair.get("status") != "ACTIVE":
                            raise RouterError("evaluation pair is not active")
                        arm_state = pair.setdefault("arms", {}).get(arm)
                        if not isinstance(arm_state, dict) or arm_state.get("settled"):
                            raise RouterError("evaluation arm is not active")
                        arm_state.update(
                            {
                                "settled": True,
                                "actual_cost_usd": number(actual_cost_usd),
                                "success": success,
                                "settled_at": isoformat(now),
                            }
                        )
                        if all(bool(item.get("settled")) for item in pair["arms"].values()):
                            candidate = pair["candidate"]
                            candidate_key = canonical_json(
                                [candidate["provider"], candidate["model"], candidate["task_class"]]
                            )
                            candidate_row = outcomes.get(candidate_key)
                            if not isinstance(candidate_row, dict):
                                raise RouterError("completed evaluation pair has no candidate outcome")
                            candidate_row["evaluation_observations"] = int(
                                candidate_row.get("evaluation_observations", 0)
                            ) + 1
                            candidate_row["last_evaluation_pair_id"] = pair_id
                            pair["status"] = "COMPLETED"
                            pair["completed_at"] = isoformat(now)
                    else:
                        row["evaluation_observations"] = int(row.get("evaluation_observations", 0)) + 1
            return dict(row)

        return self.mutate(update)

    def reserve_evaluations(
        self,
        trials: list[dict[str, Any]],
        *,
        daily_budget_usd: Decimal,
        now: datetime,
    ) -> list[dict[str, Any]]:
        def update(state: dict[str, Any]) -> list[dict[str, Any]]:
            evaluation = state.setdefault("evaluation", {})
            reservations = evaluation.setdefault("reservations", {})
            pairs = evaluation.setdefault("pairs", {})
            for evaluation_id, reservation in list(reservations.items()):
                try:
                    expired = parse_datetime(reservation["expires_at"], "evaluation.expires_at") <= now
                except (KeyError, RouterError):
                    expired = True
                if not expired:
                    continue
                reservations.pop(evaluation_id, None)
                pair = pairs.get(reservation.get("pair_id"))
                if isinstance(pair, dict) and pair.get("status") == "ACTIVE":
                    pair["status"] = "EXPIRED"
                    pair["expired_at"] = isoformat(now)
            date_key = now.date().isoformat()
            actual = Decimal(str(evaluation.setdefault("spend_by_utc_date", {}).get(date_key, 0)))
            reserved = sum(
                Decimal(str(row.get("reserved_usd", 0)))
                for row in reservations.values()
                if row.get("utc_date") == date_key
            )
            accepted: list[dict[str, Any]] = []
            for trial in trials:
                amount = Decimal(str(trial["estimated_cost_usd"]))
                if actual + reserved + amount > daily_budget_usd:
                    continue
                pair_id = "pair-" + uuid.uuid4().hex
                arm_specs = [
                    (
                        "candidate",
                        trial["provider"],
                        trial["model"],
                        Decimal(str(trial["trial_cost_usd"])),
                        trial["pricing_epoch"],
                    )
                ]
                if trial.get("incumbent"):
                    incumbent = trial["incumbent"]
                    arm_specs.append(
                        (
                            "incumbent",
                            incumbent["provider"],
                            incumbent["model"],
                            Decimal(str(trial["incumbent_cost_usd"])),
                            incumbent["pricing_epoch"],
                        )
                    )
                pair_arms: dict[str, Any] = {}
                returned_arms: list[dict[str, Any]] = []
                for arm, provider, model, arm_cost, pricing_epoch in arm_specs:
                    evaluation_id = "eval-" + uuid.uuid4().hex
                    stored = {
                        "utc_date": date_key,
                        "provider": provider,
                        "model": model,
                        "reserved_usd": number(arm_cost),
                        "pricing_epoch": pricing_epoch,
                        "pair_id": pair_id,
                        "arm": arm,
                        "created_at": isoformat(now),
                        "expires_at": isoformat(now + timedelta(hours=24)),
                    }
                    reservations[evaluation_id] = stored
                    pair_arms[arm] = {"evaluation_id": evaluation_id, "settled": False}
                    returned_arms.append(
                        {
                            "arm": arm,
                            "evaluation_id": evaluation_id,
                            "provider": provider,
                            "model": model,
                            "reserved_usd": number(arm_cost),
                            "pricing_epoch": pricing_epoch,
                        }
                    )
                pairs[pair_id] = {
                    "status": "ACTIVE",
                    "created_at": isoformat(now),
                    "expires_at": isoformat(now + timedelta(hours=24)),
                    "candidate": {
                        "provider": trial["provider"],
                        "model": trial["model"],
                        "task_class": trial["task_class"],
                    },
                    "arms": pair_arms,
                }
                reserved += amount
                accepted.append(
                    {
                        **trial,
                        "evaluation_pair_id": pair_id,
                        "evaluation_id": pair_arms["candidate"]["evaluation_id"],
                        "incumbent_evaluation_id": pair_arms.get("incumbent", {}).get("evaluation_id"),
                        "arms": returned_arms,
                        "reserved": True,
                    }
                )
            return accepted

        return self.mutate(update)


def validate_router_defaults(defaults: dict[str, Any]) -> None:
    if not isinstance(defaults, dict):
        raise RouterError("catalog.router_defaults must be an object")
    unknown = sorted(set(defaults) - ROUTER_DEFAULT_FIELDS)
    if unknown:
        raise RouterError(f"unknown router default(s): {', '.join(unknown)}")
    floors = defaults.get("tier_quality_floors", {})
    if not isinstance(floors, dict) or any(tier not in TIERS[1:] for tier in floors):
        raise RouterError("tier_quality_floors must contain only remote Foundation tiers")
    for tier, value in floors.items():
        probability = decimal_value(value, f"tier_quality_floors.{tier}", minimum=Decimal(0))
        if probability > 1:
            raise RouterError(f"tier_quality_floors.{tier} cannot exceed 1")
    if "quality_prior_strength" in defaults:
        decimal_value(defaults["quality_prior_strength"], "quality_prior_strength", minimum=Decimal("0.01"))
    trials = defaults.get("minimum_evaluation_trials", 1)
    if isinstance(trials, bool) or not isinstance(trials, int) or trials < 1:
        raise RouterError("minimum_evaluation_trials must be a positive integer")
    for field in (
        "daily_evaluation_budget_usd",
        "failure_cost_usd",
        "latency_value_usd_per_second",
        "switching_cost_usd",
    ):
        if field in defaults:
            decimal_value(defaults[field], field, minimum=Decimal(0))


def validate_catalog(catalog: dict[str, Any]) -> None:
    if catalog.get("schema_version") != 1 or catalog.get("contract") != CONTRACT:
        raise RouterError(f"catalog must use schema_version=1 and contract={CONTRACT}")
    for field in ("generated_at", "valid_until", "catalog_epoch", "pricing_epoch"):
        if not isinstance(catalog.get(field), str) or not catalog[field]:
            raise RouterError(f"catalog.{field} is required")
    generated = parse_datetime(catalog["generated_at"], "catalog.generated_at")
    valid_until = parse_datetime(catalog["valid_until"], "catalog.valid_until")
    if valid_until <= generated:
        raise RouterError("catalog.valid_until must be after generated_at")
    providers = catalog.get("providers")
    if not isinstance(providers, dict):
        raise RouterError("catalog.providers must be an object")
    if "router_defaults" in catalog:
        validate_router_defaults(catalog["router_defaults"])
    for provider_name, provider in providers.items():
        if not isinstance(provider_name, str) or not provider_name or not isinstance(provider, dict):
            raise RouterError("catalog provider entries must be named objects")
        if not isinstance(provider.get("remote"), bool) or not isinstance(provider.get("models"), dict):
            raise RouterError(f"provider {provider_name} requires remote and models")
        for model_key, model in provider["models"].items():
            if not isinstance(model, dict) or model.get("model_id") != model_key:
                raise RouterError(f"model key/model_id mismatch for {provider_name}/{model_key}")
            if model.get("assessment") not in ASSESSMENTS:
                raise RouterError(f"invalid assessment for {provider_name}/{model_key}")
            if model.get("availability") not in AVAILABILITY:
                raise RouterError(f"invalid availability for {provider_name}/{model_key}")
            capabilities = model.get("capabilities")
            if (
                not isinstance(capabilities, list)
                or any(not isinstance(item, str) or not item for item in capabilities)
                or len(capabilities) != len(set(capabilities))
            ):
                raise RouterError(f"invalid capabilities for {provider_name}/{model_key}")
            supported_tiers = model.get("supported_tiers")
            if (
                not isinstance(supported_tiers, list)
                or any(tier not in TIERS[1:] for tier in supported_tiers)
                or len(supported_tiers) != len(set(supported_tiers))
            ):
                raise RouterError(f"invalid supported_tiers for {provider_name}/{model_key}")
            efforts = model.get("reasoning_efforts")
            if (
                not isinstance(efforts, list)
                or any(not isinstance(item, str) or not item for item in efforts)
                or len(efforts) != len(set(efforts))
            ):
                raise RouterError(f"invalid reasoning_efforts for {provider_name}/{model_key}")
            context_window = model.get("context_window")
            if context_window is not None and (
                isinstance(context_window, bool) or not isinstance(context_window, int) or context_window < 1
            ):
                raise RouterError(f"invalid context_window for {provider_name}/{model_key}")
            priors = model.get("quality_prior")
            if not isinstance(priors, dict):
                raise RouterError(f"invalid quality_prior for {provider_name}/{model_key}")
            for task_class, value in priors.items():
                if not isinstance(task_class, str) or not task_class:
                    raise RouterError(f"invalid quality_prior key for {provider_name}/{model_key}")
                probability = decimal_value(value, f"{provider_name}/{model_key}.quality_prior", minimum=Decimal(0))
                if probability > 1:
                    raise RouterError(f"quality_prior cannot exceed 1 for {provider_name}/{model_key}")
            decimal_value(
                model.get("latency_seconds_prior", 0),
                f"{provider_name}/{model_key}.latency_seconds_prior",
                minimum=Decimal(0),
            )
            for field in ("fixed_attempt_cost_usd", "resource_pressure"):
                if field in model:
                    decimal_value(
                        model[field],
                        f"{provider_name}/{model_key}.{field}",
                        minimum=Decimal(0),
                    )
            pricing = model.get("pricing")
            if pricing is not None:
                if (
                    not isinstance(pricing, dict)
                    or pricing.get("currency") != "USD"
                    or pricing.get("unit_tokens") != 1_000_000
                ):
                    raise RouterError(f"invalid pricing for {provider_name}/{model_key}")
                rates = pricing.get("base")
                if not isinstance(rates, dict):
                    raise RouterError(f"base pricing is required for {provider_name}/{model_key}")
                for rate in ("input", "output"):
                    decimal_value(rates.get(rate), f"{provider_name}/{model_key}.{rate}", minimum=Decimal(0))
                if rates.get("cached_input") is not None:
                    decimal_value(
                        rates["cached_input"], f"{provider_name}/{model_key}.cached_input", minimum=Decimal(0)
                    )
                schedules = pricing.get("schedules")
                if not isinstance(schedules, list):
                    raise RouterError(f"pricing schedules must be an array for {provider_name}/{model_key}")
                schedule_ids: set[str] = set()
                for schedule in schedules:
                    if not isinstance(schedule, dict) or not isinstance(schedule.get("id"), str) or not schedule["id"]:
                        raise RouterError(f"pricing schedules require an id for {provider_name}/{model_key}")
                    if schedule["id"] in schedule_ids:
                        raise RouterError(f"duplicate pricing schedule id for {provider_name}/{model_key}")
                    schedule_ids.add(schedule["id"])
                    priority = schedule.get("priority", 0)
                    if isinstance(priority, bool) or not isinstance(priority, int):
                        raise RouterError(f"pricing schedule priority must be an integer for {provider_name}/{model_key}")
                    days = schedule.get("days_utc", list(range(7)))
                    if (
                        not isinstance(days, list)
                        or any(isinstance(day, bool) or not isinstance(day, int) or not 0 <= day <= 6 for day in days)
                        or len(days) != len(set(days))
                    ):
                        raise RouterError(f"invalid UTC schedule days for {provider_name}/{model_key}")
                    parse_clock(schedule.get("start_utc", "00:00"))
                    parse_clock(schedule.get("end_utc", "00:00"))
                    schedule_rates = schedule.get("rates")
                    if not isinstance(schedule_rates, dict):
                        raise RouterError(f"pricing schedules require rates for {provider_name}/{model_key}")
                    for rate in ("input", "output"):
                        decimal_value(
                            schedule_rates.get(rate),
                            f"{provider_name}/{model_key}.schedule.{rate}",
                            minimum=Decimal(0),
                        )
                    if schedule_rates.get("cached_input") is not None:
                        decimal_value(
                            schedule_rates["cached_input"],
                            f"{provider_name}/{model_key}.schedule.cached_input",
                            minimum=Decimal(0),
                        )


def validate_request(raw: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise RouterError("routing request must be an object")
    request = dict(raw)
    unknown = sorted(set(request) - REQUEST_FIELDS)
    if unknown:
        raise RouterError(f"unknown routing request field(s): {', '.join(unknown)}")
    tier = str(request.get("tier", "")).upper()
    if tier not in TIERS:
        raise RouterError(f"request.tier must be one of {', '.join(TIERS)}")
    request["tier"] = tier
    task_class = request.get("task_class")
    if not isinstance(task_class, str) or not task_class.strip():
        raise RouterError("request.task_class must be a non-empty string")
    request["task_class"] = task_class.strip()
    integer_defaults = {
        "context_tokens": 0,
        "cached_input_tokens": 0,
        "expected_output_tokens": 0,
        "max_fallbacks": 1,
    }
    for field, default in integer_defaults.items():
        value = request.get(field, default)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise RouterError(f"request.{field} must be a non-negative integer")
        request[field] = value
    if request["cached_input_tokens"] > request["context_tokens"]:
        raise RouterError("request.cached_input_tokens cannot exceed context_tokens")
    for field in ("required_capabilities", "allowed_providers", "failed_models"):
        value = request.get(field, [])
        if not isinstance(value, list) or any(not isinstance(item, str) or not item for item in value):
            raise RouterError(f"request.{field} must be an array of non-empty strings")
        request[field] = sorted(set(value))
    for field, default in (
        ("allow_remote", False),
        ("allow_evaluation", False),
        ("allow_unknown_context", False),
    ):
        value = request.get(field, default)
        if not isinstance(value, bool):
            raise RouterError(f"request.{field} must be boolean")
        request[field] = value
    for field in (
        "quality_floor",
        "max_cost_usd",
        "failure_cost_usd",
        "latency_value_usd_per_second",
        "switching_cost_usd",
    ):
        value = request.get(field)
        if field in request and value is None:
            raise RouterError(f"request.{field} must be a non-negative number when provided")
        if value is not None:
            parsed = decimal_value(value, f"request.{field}", minimum=Decimal(0))
            if field == "quality_floor" and parsed > 1:
                raise RouterError("request.quality_floor cannot exceed 1")
            request[field] = number(parsed)
    for field in ("session_id", "current_provider", "current_model", "preferred_reasoning_effort"):
        value = request.get(field)
        if field in request and (not isinstance(value, str) or not value):
            raise RouterError(f"request.{field} must be a non-empty string when provided")
    if bool(request.get("current_provider")) != bool(request.get("current_model")):
        raise RouterError("request.current_provider and request.current_model must be provided together")
    if request["cached_input_tokens"] and not request.get("current_model"):
        raise RouterError("cached_input_tokens requires current_provider and current_model")
    if "at" in request:
        parse_datetime(request["at"], "request.at")
    return request


def quality_prior(model: dict[str, Any], task_class: str) -> Decimal:
    values = model.get("quality_prior", {"*": 0.5})
    if not isinstance(values, dict):
        raise RouterError(f"quality_prior must be an object for {model.get('model_id')}")
    candidates = [task_class]
    parts = task_class.split(".")
    candidates.extend(".".join(parts[:index]) for index in range(len(parts) - 1, 0, -1))
    candidates.append("*")
    for candidate in candidates:
        if candidate in values:
            result = decimal_value(values[candidate], f"quality_prior.{candidate}", minimum=Decimal(0))
            if result > 1:
                raise RouterError("quality priors cannot exceed 1")
            return result
    return Decimal("0.5")


def outcome_key(provider: str, model: str, task_class: str) -> str:
    return canonical_json([provider, model, task_class])


def observation(state: dict[str, Any], provider: str, model: str, task_class: str) -> dict[str, Any]:
    outcomes = state.get("outcomes", {})
    return outcomes.get(outcome_key(provider, model, task_class), {}) if isinstance(outcomes, dict) else {}


def predicted_success(
    model: dict[str, Any],
    observed: dict[str, Any],
    task_class: str,
    prior_strength: Decimal,
) -> Decimal:
    prior = quality_prior(model, task_class)
    successes = Decimal(int(observed.get("successes", 0)))
    failures = Decimal(int(observed.get("failures", 0)))
    return (prior * prior_strength + successes) / (prior_strength + successes + failures)


def parse_clock(value: str) -> tuple[int, int]:
    try:
        hour_text, minute_text = value.split(":", 1)
        hour, minute = int(hour_text), int(minute_text)
    except (AttributeError, TypeError, ValueError) as exc:
        raise RouterError(f"invalid UTC schedule clock: {value!r}") from exc
    if not (0 <= hour <= 23 and 0 <= minute <= 59):
        raise RouterError(f"invalid UTC schedule clock: {value!r}")
    return hour, minute


def schedule_active(schedule: dict[str, Any], now: datetime) -> bool:
    days = schedule.get("days_utc", list(range(7)))
    if not isinstance(days, list):
        return False
    start = parse_clock(schedule.get("start_utc", "00:00"))
    end = parse_clock(schedule.get("end_utc", "00:00"))
    current = (now.hour, now.minute)
    if start < end:
        return now.weekday() in days and start <= current < end
    previous_day = (now.weekday() - 1) % 7
    return (now.weekday() in days and current >= start) or (current < end and previous_day in days)


def next_schedule_boundary(schedules: list[dict[str, Any]], now: datetime) -> datetime | None:
    boundaries: list[datetime] = []
    base_date = now.date()
    for offset in range(-1, 9):
        day = base_date + timedelta(days=offset)
        for schedule in schedules:
            days = schedule.get("days_utc", list(range(7)))
            if day.weekday() not in days:
                continue
            start = parse_clock(schedule.get("start_utc", "00:00"))
            end = parse_clock(schedule.get("end_utc", "00:00"))
            start_at = datetime(day.year, day.month, day.day, *start, tzinfo=timezone.utc)
            end_day = day + timedelta(days=1) if end <= start else day
            end_at = datetime(end_day.year, end_day.month, end_day.day, *end, tzinfo=timezone.utc)
            for candidate in (start_at, end_at):
                if candidate > now:
                    boundaries.append(candidate)
    return min(boundaries) if boundaries else None


def effective_rates(
    model: dict[str, Any], catalog_pricing_epoch: str, now: datetime
) -> tuple[dict[str, Decimal], str, datetime | None]:
    pricing = model.get("pricing")
    if not isinstance(pricing, dict):
        raise RouterError("missing pricing")
    base = pricing.get("base")
    if not isinstance(base, dict):
        raise RouterError("missing base pricing")
    schedules = pricing.get("schedules", [])
    if not isinstance(schedules, list):
        raise RouterError("pricing schedules must be an array")
    active = [row for row in schedules if isinstance(row, dict) and schedule_active(row, now)]
    selected = max(active, key=lambda row: (int(row.get("priority", 0)), str(row.get("id", "")))) if active else None
    raw_rates = selected.get("rates", {}) if selected else base
    rates: dict[str, Decimal] = {}
    for key in ("input", "cached_input", "output"):
        raw = raw_rates.get(key)
        if raw is None and key == "cached_input":
            raw = raw_rates.get("input", base.get("input"))
        if raw is None:
            raw = base.get(key)
        rates[key] = decimal_value(raw, f"pricing.{key}", minimum=Decimal(0))
    epoch = f"{catalog_pricing_epoch}/{selected.get('id') if selected else 'base'}"
    return rates, epoch, next_schedule_boundary(schedules, now)


def select_reasoning_effort(model: dict[str, Any], request: dict[str, Any]) -> str | None:
    supported = model.get("reasoning_efforts", [])
    if not isinstance(supported, list) or not supported:
        return None
    preferred = request.get("preferred_reasoning_effort") or DEFAULT_TIER_EFFORT[request["tier"]]
    if preferred in supported:
        return preferred
    order = ["none", "minimal", "low", "medium", "high", "xhigh", "max", "ultra"]
    ranked = {name: index for index, name in enumerate(order)}
    target = ranked.get(preferred, ranked[DEFAULT_TIER_EFFORT[request["tier"]]])
    return min((str(value) for value in supported), key=lambda value: (abs(ranked.get(value, target) - target), value))


@dataclass
class Candidate:
    provider: str
    model: str
    predicted_success: Decimal
    estimated_cost: Decimal
    usage_cost: Decimal
    resource_cost: Decimal
    resource_pressure: Decimal
    switching_cost: Decimal
    latency_seconds: Decimal
    score: Decimal
    rates: dict[str, Decimal]
    pricing_epoch: str
    valid_until: datetime
    cached_input_tokens: int
    reasoning_effort: str | None
    assessment: str
    observations: int

    def summary(self) -> dict[str, Any]:
        return {
            "provider": self.provider,
            "model": self.model,
            "assessment": self.assessment,
            "observations": self.observations,
            "predicted_success": number(self.predicted_success),
            "estimated_cost_usd": number(self.estimated_cost),
            "usage_cost_usd": number(self.usage_cost),
            "resource_cost_usd": number(self.resource_cost),
            "resource_pressure": number(self.resource_pressure),
            "switching_cost_usd": number(self.switching_cost),
            "standalone_cost_of_success_usd": number(self.score),
            "pricing_epoch": self.pricing_epoch,
            "reasoning_effort": self.reasoning_effort,
        }


def math_permutations(count: int, length: int) -> int:
    result = 1
    for value in range(count - length + 1, count + 1):
        result *= value
    return result


def chain_economics(
    chain: tuple[Candidate, ...] | list[Candidate],
    *,
    failure_cost: Decimal,
    latency_value: Decimal,
) -> dict[str, Decimal]:
    expected_spend = Decimal(0)
    expected_resource_cost = Decimal(0)
    expected_resource_pressure = Decimal(0)
    expected_switching_cost = Decimal(0)
    expected_latency = Decimal(0)
    reach = Decimal(1)
    for candidate in chain:
        expected_spend += reach * candidate.estimated_cost
        expected_resource_cost += reach * candidate.resource_cost
        expected_resource_pressure += reach * candidate.resource_pressure
        expected_switching_cost += reach * candidate.switching_cost
        expected_latency += reach * candidate.latency_seconds
        reach *= Decimal(1) - candidate.predicted_success
    chain_success = Decimal(1) - reach
    expected_total = expected_spend + expected_switching_cost + reach * failure_cost
    cost_of_success = expected_total / max(chain_success, Decimal("0.01")) + expected_latency * latency_value
    return {
        "expected_spend": expected_spend,
        "expected_resource_cost": expected_resource_cost,
        "expected_resource_pressure": expected_resource_pressure,
        "expected_switching_cost": expected_switching_cost,
        "expected_latency": expected_latency,
        "chain_success": chain_success,
        "cost_of_success": cost_of_success,
    }


class ModelRouter:
    """Transport-neutral deterministic routing and evaluation planning."""

    def __init__(self, catalog: dict[str, Any], store: RuntimeStore, now: Callable[[], datetime] = utc_now) -> None:
        validate_catalog(catalog)
        self.catalog = catalog
        self.store = store
        self.now = now

    def _request_time(self, request: dict[str, Any]) -> datetime:
        return parse_datetime(request["at"], "request.at") if request.get("at") else self.now()

    def _quality_floor(self, request: dict[str, Any]) -> Decimal:
        if request.get("quality_floor") is not None:
            return Decimal(str(request["quality_floor"]))
        defaults = self.catalog.get("router_defaults", {}).get("tier_quality_floors", DEFAULT_QUALITY_FLOORS)
        return decimal_value(defaults.get(request["tier"], DEFAULT_QUALITY_FLOORS[request["tier"]]), "quality floor", minimum=Decimal(0))

    def _session(self, state: dict[str, Any], request: dict[str, Any], now: datetime) -> dict[str, Any] | None:
        session_id = request.get("session_id")
        if not session_id:
            return None
        row = state.get("sessions", {}).get(self.store.session_key(session_id))
        if not isinstance(row, dict):
            return None
        try:
            if parse_datetime(row["expires_at"], "session.expires_at") <= now:
                return None
        except (KeyError, RouterError):
            return None
        return row

    def _candidates(
        self,
        request: dict[str, Any],
        state: dict[str, Any],
        now: datetime,
        *,
        evaluation_scan: bool = False,
    ) -> tuple[list[Candidate], list[dict[str, str]], list[datetime]]:
        rejected: list[dict[str, str]] = []
        candidates: list[Candidate] = []
        reevaluation_boundaries: list[datetime] = []
        defaults = self.catalog.get("router_defaults", {})
        prior_strength = decimal_value(defaults.get("quality_prior_strength", 4), "quality prior strength", minimum=Decimal("0.01"))
        minimum_trials = int(defaults.get("minimum_evaluation_trials", 3))
        quality_floor = self._quality_floor(request)
        catalog_expiry = parse_datetime(self.catalog["valid_until"], "catalog.valid_until")
        catalog_fresh = now < catalog_expiry
        session = self._session(state, request, now)
        required = set(request["required_capabilities"])
        allowed = set(request["allowed_providers"])
        failed = set(request["failed_models"])
        max_cost = Decimal(str(request["max_cost_usd"])) if request.get("max_cost_usd") is not None else None
        failure_cost = Decimal(str(request.get("failure_cost_usd", defaults.get("failure_cost_usd", 0))))
        latency_value = Decimal(str(request.get("latency_value_usd_per_second", defaults.get("latency_value_usd_per_second", 0))))
        switching_cost = Decimal(str(request.get("switching_cost_usd", defaults.get("switching_cost_usd", 0))))

        def reject(provider: str, model: str, code: str) -> None:
            rejected.append({"provider": provider, "model": model, "code": code})

        for provider_name in sorted(self.catalog["providers"]):
            provider = self.catalog["providers"][provider_name]
            if allowed and provider_name not in allowed:
                for model_id in sorted(provider["models"]):
                    reject(provider_name, model_id, "PROVIDER_NOT_ALLOWED")
                continue
            for model_id in sorted(provider["models"]):
                model = provider["models"][model_id]
                identity = f"{provider_name}/{model_id}"
                if identity in failed or model_id in failed:
                    reject(provider_name, model_id, "PREVIOUS_ATTEMPT_FAILED")
                    continue
                if model.get("availability") != "AVAILABLE":
                    reject(provider_name, model_id, str(model.get("availability")))
                    continue
                if model.get("assessment") == "DISABLED":
                    reject(provider_name, model_id, "MODEL_DISABLED")
                    continue
                if provider.get("remote") and not request["allow_remote"]:
                    reject(provider_name, model_id, "REMOTE_NOT_AUTHORIZED")
                    continue
                if not catalog_fresh:
                    reject(provider_name, model_id, "PRICING_EXPIRED")
                    continue
                if not required.issubset(set(model.get("capabilities", []))):
                    reject(provider_name, model_id, "CAPABILITY_MISMATCH")
                    continue
                context_window = model.get("context_window")
                if context_window is None and request["context_tokens"] and not request["allow_unknown_context"]:
                    reject(provider_name, model_id, "CONTEXT_WINDOW_UNKNOWN")
                    continue
                if isinstance(context_window, int) and request["context_tokens"] + request["expected_output_tokens"] > context_window:
                    reject(provider_name, model_id, "CONTEXT_WINDOW_EXCEEDED")
                    continue
                supported_tiers = model.get("supported_tiers", list(TIERS[1:]))
                if not evaluation_scan and request["tier"] not in supported_tiers:
                    reject(provider_name, model_id, "TIER_NOT_SUPPORTED")
                    continue
                observed = observation(state, provider_name, model_id, request["task_class"])
                observations = int(observed.get("successes", 0)) + int(observed.get("failures", 0))
                evaluation_observations = int(observed.get("evaluation_observations", 0))
                assessed = model.get("assessment") == "ASSESSED" or evaluation_observations >= minimum_trials
                if evaluation_scan and assessed:
                    continue
                if not evaluation_scan and not assessed:
                    reject(provider_name, model_id, "EVALUATION_REQUIRED")
                    continue
                probability = predicted_success(model, observed, request["task_class"], prior_strength)
                if not evaluation_scan and probability < quality_floor:
                    reject(provider_name, model_id, "QUALITY_FLOOR_NOT_MET")
                    continue
                try:
                    rates, price_epoch, boundary = effective_rates(model, self.catalog["pricing_epoch"], now)
                except RouterError:
                    reject(provider_name, model_id, "PRICE_UNKNOWN")
                    continue
                reevaluation_boundaries.append(min(catalog_expiry, boundary) if boundary else catalog_expiry)
                current_match = (
                    request.get("current_provider") == provider_name and request.get("current_model") == model_id
                )
                cached_tokens = request["cached_input_tokens"] if current_match else 0
                session_match = bool(
                    session
                    and session.get("provider") == provider_name
                    and session.get("model") == model_id
                    and session.get("pricing_epoch") == price_epoch
                )
                if session_match:
                    cached_tokens = max(cached_tokens, min(request["context_tokens"], int(session.get("context_tokens", 0))))
                uncached_tokens = request["context_tokens"] - cached_tokens
                usage_cost = (
                    Decimal(uncached_tokens) * rates["input"]
                    + Decimal(cached_tokens) * rates["cached_input"]
                    + Decimal(request["expected_output_tokens"]) * rates["output"]
                ) / Decimal(1_000_000)
                resource_cost = decimal_value(
                    model.get("fixed_attempt_cost_usd", 0),
                    f"{provider_name}/{model_id}.fixed_attempt_cost_usd",
                    minimum=Decimal(0),
                )
                resource_pressure = decimal_value(
                    model.get("resource_pressure", 0),
                    f"{provider_name}/{model_id}.resource_pressure",
                    minimum=Decimal(0),
                )
                cost = usage_cost + resource_cost
                if max_cost is not None and cost > max_cost:
                    reject(provider_name, model_id, "COST_BUDGET_EXCEEDED")
                    continue
                latency_raw = observed.get("latency_ms_ema")
                if latency_raw is not None:
                    latency_seconds = Decimal(str(latency_raw)) / Decimal(1000)
                else:
                    latency_seconds = Decimal(str(model.get("latency_seconds_prior", 0)))
                switch_penalty = Decimal(0) if current_match or session_match or not (request.get("current_model") or session) else switching_cost
                score = (cost + switch_penalty + (Decimal(1) - probability) * failure_cost) / max(
                    probability, Decimal("0.01")
                )
                score += latency_seconds * latency_value
                valid_until = min(catalog_expiry, boundary) if boundary else catalog_expiry
                candidates.append(
                    Candidate(
                        provider=provider_name,
                        model=model_id,
                        predicted_success=probability,
                        estimated_cost=cost,
                        usage_cost=usage_cost,
                        resource_cost=resource_cost,
                        resource_pressure=resource_pressure,
                        switching_cost=switch_penalty,
                        latency_seconds=latency_seconds,
                        score=score,
                        rates=rates,
                        pricing_epoch=price_epoch,
                        valid_until=valid_until,
                        cached_input_tokens=cached_tokens,
                        reasoning_effort=select_reasoning_effort(model, request),
                        assessment="ASSESSED" if assessed else "UNASSESSED",
                        observations=observations,
                    )
                )
        candidates.sort(
            key=lambda row: (row.score, row.resource_pressure, -row.predicted_success, row.provider, row.model)
        )
        return candidates, rejected, reevaluation_boundaries

    def route(self, raw_request: dict[str, Any]) -> dict[str, Any]:
        request = validate_request(raw_request)
        now = self._request_time(request)
        if request["tier"] == "LOCAL":
            return {
                "schema_version": 1,
                "contract": CONTRACT,
                "status": "LOCAL_ONLY",
                "decision_id": digest(
                    {"request": request, "at": isoformat(now), "catalog": self.catalog["catalog_epoch"]}
                ),
                "generated_at": isoformat(now),
                "valid_until": isoformat(now + timedelta(minutes=5)),
                "pricing_epoch": None,
                "route": None,
                "fallbacks": [],
                "execution": {
                    "reasoning_effort": None,
                    "context_budget_tokens": request["context_tokens"],
                    "output_budget_tokens": request["expected_output_tokens"],
                    "cache_strategy": "not_applicable",
                    "validation_strategy": VALIDATION_STRATEGIES["LOCAL"],
                },
                "reason_codes": ["DETERMINISTIC_LOCAL_PROCESSING_REQUIRED"],
                "rejected_candidates": [],
            }
        state = self.store.load()
        candidates, rejected, reevaluation_boundaries = self._candidates(request, state, now)
        decision_base = {
            "schema_version": 1,
            "contract": CONTRACT,
            "generated_at": isoformat(now),
            "decision_id": digest(
                {"request": request, "at": isoformat(now), "catalog": self.catalog["catalog_epoch"], "runtime": state}
            ),
        }
        if not candidates:
            codes = sorted({row["code"] for row in rejected}) or ["CATALOG_EMPTY"]
            return {
                **decision_base,
                "status": "NO_ROUTE",
                "valid_until": isoformat(min(reevaluation_boundaries)) if reevaluation_boundaries else self.catalog["valid_until"],
                "pricing_epoch": None,
                "route": None,
                "fallbacks": [],
                "execution": {
                    "reasoning_effort": None,
                    "context_budget_tokens": request["context_tokens"],
                    "output_budget_tokens": request["expected_output_tokens"],
                    "cache_strategy": "unavailable",
                    "validation_strategy": VALIDATION_STRATEGIES[request["tier"]],
                },
                "reason_codes": codes,
                "rejected_candidates": rejected,
            }

        max_cost = Decimal(str(request["max_cost_usd"])) if request.get("max_cost_usd") is not None else None
        defaults = self.catalog.get("router_defaults", {})
        failure_cost = Decimal(str(request.get("failure_cost_usd", defaults.get("failure_cost_usd", 0))))
        latency_value = Decimal(str(request.get("latency_value_usd_per_second", defaults.get("latency_value_usd_per_second", 0))))
        maximum_length = min(len(candidates), request["max_fallbacks"] + 1)
        search_size = sum(math_permutations(len(candidates), length) for length in range(1, maximum_length + 1))
        if search_size > 250_000:
            return {
                **decision_base,
                "status": "NO_ROUTE",
                "valid_until": isoformat(min(reevaluation_boundaries)),
                "pricing_epoch": None,
                "route": None,
                "fallbacks": [],
                "execution": {
                    "reasoning_effort": None,
                    "context_budget_tokens": request["context_tokens"],
                    "output_budget_tokens": request["expected_output_tokens"],
                    "cache_strategy": "unavailable",
                    "validation_strategy": VALIDATION_STRATEGIES[request["tier"]],
                },
                "reason_codes": ["CHAIN_SEARCH_BOUND_EXCEEDED"],
                "rejected_candidates": rejected,
            }
        evaluated: list[tuple[Decimal, Decimal, int, tuple[str, ...], list[Candidate], dict[str, Decimal]]] = []
        for length in range(1, maximum_length + 1):
            for sequence in itertools.permutations(candidates, length):
                economics = chain_economics(sequence, failure_cost=failure_cost, latency_value=latency_value)
                if max_cost is not None and economics["expected_spend"] > max_cost:
                    continue
                if length > 1:
                    prefix = chain_economics(sequence[:-1], failure_cost=failure_cost, latency_value=latency_value)
                    material = max(
                        CHAIN_MATERIAL_BENEFIT_ABSOLUTE_USD,
                        prefix["cost_of_success"] * CHAIN_MATERIAL_BENEFIT_RATIO,
                    )
                    if prefix["cost_of_success"] - economics["cost_of_success"] < material:
                        continue
                identity = tuple(f"{row.provider}/{row.model}" for row in sequence)
                evaluated.append(
                    (
                        economics["cost_of_success"],
                        economics["expected_resource_pressure"],
                        length,
                        identity,
                        list(sequence),
                        economics,
                    )
                )
        if not evaluated:
            return {
                **decision_base,
                "status": "NO_ROUTE",
                "valid_until": isoformat(min(reevaluation_boundaries)),
                "pricing_epoch": None,
                "route": None,
                "fallbacks": [],
                "execution": {
                    "reasoning_effort": None,
                    "context_budget_tokens": request["context_tokens"],
                    "output_budget_tokens": request["expected_output_tokens"],
                    "cache_strategy": "unavailable",
                    "validation_strategy": VALIDATION_STRATEGIES[request["tier"]],
                },
                "reason_codes": ["CHAIN_COST_BUDGET_EXCEEDED"],
                "rejected_candidates": rejected,
            }
        evaluated.sort(key=lambda item: (item[0], item[1], item[2], item[3]))
        _objective, _pressure, _length, _identity, chain, economics = evaluated[0]
        primary = chain[0]
        expected_spend = economics["expected_spend"]
        expected_latency = economics["expected_latency"]
        expected_switching_cost = economics["expected_switching_cost"]
        chain_success = economics["chain_success"]
        cost_of_success = economics["cost_of_success"]
        # Any eligible candidate's rate transition can change the winner, even
        # when that candidate is not currently in the selected fallback chain.
        valid_until = min(reevaluation_boundaries)
        route = primary.summary()
        route.update(
            {
                "estimated_uncached_input_tokens": request["context_tokens"] - primary.cached_input_tokens,
                "estimated_cached_input_tokens": primary.cached_input_tokens,
                "effective_rates_per_million": {key: number(value) for key, value in primary.rates.items()},
            }
        )
        return {
            **decision_base,
            "status": "ROUTED",
            "valid_until": isoformat(valid_until),
            "pricing_epoch": primary.pricing_epoch,
            "route": route,
            "fallbacks": [row.summary() for row in chain[1:]],
            "economics": {
                "expected_chain_spend_usd": number(expected_spend),
                "expected_resource_cost_usd": number(economics["expected_resource_cost"]),
                "expected_resource_pressure": number(economics["expected_resource_pressure"]),
                "expected_switching_cost_usd": number(expected_switching_cost),
                "chain_success_probability": number(chain_success),
                "failure_cost_usd": number(failure_cost),
                "expected_latency_seconds": number(expected_latency),
                "cost_of_success_usd": number(cost_of_success),
            },
            "execution": {
                "reasoning_effort": primary.reasoning_effort,
                "context_budget_tokens": request["context_tokens"],
                "output_budget_tokens": request["expected_output_tokens"],
                "cache_strategy": "preserve_session_affinity" if primary.cached_input_tokens else "no_confirmed_cache_affinity",
                "validation_strategy": VALIDATION_STRATEGIES[request["tier"]],
            },
            "reason_codes": ["MINIMUM_EXPECTED_COST_OF_SUCCESS", "FRESH_PRICE_EPOCH"],
            "chain_search": {"complete": True, "evaluated_chains": len(evaluated), "maximum_attempts": maximum_length},
            "candidates_considered": [row.summary() for row in candidates[:10]],
            "rejected_candidates": rejected,
        }

    def plan_evaluation(
        self,
        raw_request: dict[str, Any],
        *,
        budget_usd: Decimal,
        max_candidates: int,
        reserve: bool,
        task_set: list[str] | None = None,
        planned_sample_count: int = 1,
        stopping_rules: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        budget_usd = decimal_value(budget_usd, "evaluation budget", minimum=Decimal(0))
        if isinstance(max_candidates, bool) or not isinstance(max_candidates, int) or max_candidates < 1:
            raise RouterError("max_candidates must be a positive integer")
        if not isinstance(reserve, bool):
            raise RouterError("reserve must be boolean")
        request = validate_request({**raw_request, "allow_evaluation": False})
        task_set = list(task_set) if task_set is not None else [request["task_class"]]
        if not task_set or any(not isinstance(item, str) or not item for item in task_set) or len(set(task_set)) != len(task_set):
            raise RouterError("task_set must contain unique non-empty task classes")
        if isinstance(planned_sample_count, bool) or not isinstance(planned_sample_count, int) or planned_sample_count < 1:
            raise RouterError("planned_sample_count must be a positive integer")
        if stopping_rules is None:
            stopping_rules = {
                "minimum_valid_pairs": planned_sample_count,
                "stop_on_budget_exhausted": True,
                "stop_on_contract_failure": True,
            }
        if not isinstance(stopping_rules, dict) or not stopping_rules:
            raise RouterError("stopping_rules must be a non-empty object")
        if request["tier"] == "LOCAL":
            raise RouterError("LOCAL work does not require model evaluation")
        now = self._request_time(request)
        state = self.store.load()
        unknown, rejected, _boundaries = self._candidates(request, state, now, evaluation_scan=True)
        incumbent = self.route(request)
        incumbent_cost = Decimal(0)
        if incumbent["status"] == "ROUTED":
            incumbent_cost = Decimal(str(incumbent["route"]["estimated_cost_usd"]))
        defaults = self.catalog.get("router_defaults", {})
        daily_limit = decimal_value(
            defaults.get("daily_evaluation_budget_usd", budget_usd),
            "daily evaluation budget",
            minimum=Decimal(0),
        )
        limit = min(budget_usd, daily_limit)
        remaining = limit
        trials: list[dict[str, Any]] = []
        for candidate in sorted(unknown, key=lambda row: (row.estimated_cost, row.provider, row.model))[:max_candidates]:
            paired_cost = candidate.estimated_cost + incumbent_cost
            for sample_index in range(planned_sample_count):
                if paired_cost > remaining:
                    break
                trials.append(
                    {
                        "trial_id": digest(
                            {
                                "provider": candidate.provider,
                                "model": candidate.model,
                                "sample_index": sample_index,
                                "tasks": task_set,
                                "at": isoformat(now),
                            }
                        ),
                        "provider": candidate.provider,
                        "model": candidate.model,
                        "task_class": request["task_class"],
                        "task_set": task_set,
                        "sample_index": sample_index,
                        "estimated_cost_usd": number(paired_cost),
                        "trial_cost_usd": number(candidate.estimated_cost),
                        "incumbent_cost_usd": number(incumbent_cost),
                        "incumbent": incumbent.get("route"),
                        "pricing_epoch": candidate.pricing_epoch,
                        "valid_until": isoformat(candidate.valid_until),
                        "method": "paired_trial_against_incumbent" if incumbent_cost else "bounded_single_trial",
                        "reserved": False,
                    }
                )
                remaining -= paired_cost
        if reserve and trials:
            trials = self.store.reserve_evaluations(trials, daily_budget_usd=limit, now=now)
        return {
            "schema_version": 1,
            "contract": CONTRACT,
            "status": "EVALUATION_PLANNED" if trials else "NO_EVALUATION",
            "generated_at": isoformat(now),
            "budget_usd": number(limit),
            "spend_ceiling_usd": number(limit),
            "reserved": reserve,
            "task_set": task_set,
            "planned_sample_count": planned_sample_count,
            "stopping_rules": stopping_rules,
            "incumbent": incumbent.get("route"),
            "trials": trials,
            "rejected_candidates": rejected,
        }

    def snapshot(self, raw_request: dict[str, Any]) -> dict[str, Any]:
        template = validate_request(raw_request)
        decisions: dict[str, Any] = {}
        valid_until: datetime | None = None
        epochs: set[str] = set()
        for tier in TIERS:
            decision = self.route({**template, "tier": tier})
            decisions[tier] = {
                "status": decision["status"],
                "route": decision.get("route"),
                "fallbacks": decision.get("fallbacks", []),
                "execution": decision.get("execution"),
                "reason_codes": decision.get("reason_codes", []),
            }
            expiry = parse_datetime(decision["valid_until"], "decision.valid_until")
            valid_until = expiry if valid_until is None else min(valid_until, expiry)
            if decision.get("pricing_epoch"):
                epochs.add(decision["pricing_epoch"])
        now = self._request_time(template)
        return {
            "schema_version": 1,
            "contract": CONTRACT,
            "generated_at": isoformat(now),
            "valid_until": isoformat(valid_until or now),
            "catalog_epoch": self.catalog["catalog_epoch"],
            "pricing_epochs": sorted(epochs),
            "runtime_only": True,
            "routes": decisions,
        }


def load_request_argument(value: str | None) -> dict[str, Any]:
    if value is None:
        return {}
    if value == "-":
        text = sys.stdin.read()
    elif value.startswith("@"):
        text = Path(value[1:]).read_text(encoding="utf-8")
    else:
        candidate = Path(value)
        text = candidate.read_text(encoding="utf-8") if candidate.is_file() else value
    try:
        result = json.loads(text)
    except json.JSONDecodeError as exc:
        raise RouterError(f"invalid routing request JSON: {exc}") from exc
    if not isinstance(result, dict):
        raise RouterError("routing request JSON root must be an object")
    return result


def request_from_args(args: argparse.Namespace) -> dict[str, Any]:
    request = load_request_argument(getattr(args, "request", None))
    mapping = {
        "tier": "tier",
        "task_class": "task_class",
        "context_tokens": "context_tokens",
        "cached_input_tokens": "cached_input_tokens",
        "output_tokens": "expected_output_tokens",
        "quality_floor": "quality_floor",
        "max_cost_usd": "max_cost_usd",
        "failure_cost_usd": "failure_cost_usd",
        "session_id": "session_id",
        "current_provider": "current_provider",
        "current_model": "current_model",
        "preferred_reasoning_effort": "preferred_reasoning_effort",
        "max_fallbacks": "max_fallbacks",
    }
    for source, target in mapping.items():
        value = getattr(args, source, None)
        if value is not None:
            request[target] = value
    if getattr(args, "required_capability", None):
        request["required_capabilities"] = args.required_capability
    if getattr(args, "allowed_provider", None):
        request["allowed_providers"] = args.allowed_provider
    if getattr(args, "failed_model", None):
        request["failed_models"] = args.failed_model
    for flag in ("allow_remote", "allow_evaluation", "allow_unknown_context"):
        if getattr(args, flag, False):
            request[flag] = True
    return validate_request(request)


def router_from_args(args: argparse.Namespace) -> tuple[ModelRouter, RuntimeStore]:
    store = RuntimeStore(Path(args.state_dir) if args.state_dir else None)
    catalog_path = ensure_runtime_location(Path(args.catalog)) if getattr(args, "catalog", None) else store.catalog_path
    catalog = load_json(catalog_path, "model catalog")
    return ModelRouter(catalog, store), store


def print_json(value: Any) -> None:
    print(json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False))


def add_request_options(parser: argparse.ArgumentParser, *, tier_required: bool = False) -> None:
    parser.add_argument("--request", help="JSON text, a JSON file path, @file, or - for stdin")
    parser.add_argument("--tier", choices=TIERS, required=tier_required)
    parser.add_argument("--task-class")
    parser.add_argument("--context-tokens", type=int)
    parser.add_argument("--cached-input-tokens", type=int)
    parser.add_argument("--output-tokens", type=int)
    parser.add_argument("--required-capability", action="append")
    parser.add_argument("--allowed-provider", action="append")
    parser.add_argument("--quality-floor", type=float)
    parser.add_argument("--max-cost-usd", type=float)
    parser.add_argument("--failure-cost-usd", type=float)
    parser.add_argument("--session-id")
    parser.add_argument("--current-provider")
    parser.add_argument("--current-model")
    parser.add_argument("--failed-model", action="append")
    parser.add_argument("--preferred-reasoning-effort")
    parser.add_argument("--max-fallbacks", type=int)
    parser.add_argument("--allow-remote", action="store_true")
    parser.add_argument("--allow-evaluation", action="store_true")
    parser.add_argument("--allow-unknown-context", action="store_true")


def install_launcher(source: Path, bin_dir: Path) -> dict[str, Any]:
    destination = ensure_runtime_location(bin_dir)
    destination.mkdir(parents=True, exist_ok=True)
    python = Path(sys.executable).resolve()
    if os.name == "nt":
        target = destination / "ai-model-router.cmd"
        content = f'@"{python}" "{source.resolve()}" %*\r\n'
        target.write_text(content, encoding="utf-8", newline="")
    else:
        target = destination / "ai-model-router"
        content = f'#!/bin/sh\nexec "{python}" "{source.resolve()}" "$@"\n'
        target.write_text(content, encoding="utf-8", newline="\n")
        target.chmod(target.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return {"status": "INSTALLED", "launcher": str(target), "add_to_path": str(destination)}


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(prog="ai-model-router", description=__doc__)
    root.add_argument("--state-dir", help="local runtime directory; defaults outside the repository")
    sub = root.add_subparsers(dest="command", required=True)

    route = sub.add_parser("route", help="produce a transport-neutral routing decision")
    route.add_argument("--catalog")
    add_request_options(route)

    sync = sub.add_parser("sync-ollama", help="discover Ollama Cloud models and current time-dependent prices")
    sync.add_argument("--profiles", help="optional operator profile overlay JSON")
    sync.add_argument("--model-url", default="https://ollama.com/api/tags")
    sync.add_argument("--pricing-url", default="https://ollama.com/pricing")
    sync.add_argument("--ttl-hours", type=int, default=24)
    sync.add_argument("--timeout-seconds", type=float, default=15.0)
    sync.add_argument("--output", help="write catalog here instead of the runtime store")

    outcome = sub.add_parser("record-outcome", help="record empirical success/cost/latency in local runtime state")
    outcome.add_argument("--provider", required=True)
    outcome.add_argument("--model", required=True)
    outcome.add_argument("--task-class", required=True)
    outcome_result = outcome.add_mutually_exclusive_group(required=True)
    outcome_result.add_argument("--success", action="store_true")
    outcome_result.add_argument("--failure", action="store_true")
    outcome.add_argument("--actual-cost-usd", type=float, default=0.0)
    outcome.add_argument("--latency-ms", type=float)
    outcome.add_argument("--session-id")
    outcome.add_argument("--context-tokens", type=int, default=0)
    outcome.add_argument("--pricing-epoch")
    outcome.add_argument("--evaluation-id")

    evaluation = sub.add_parser("plan-evaluation", help="plan or reserve bounded trials for newly discovered models")
    evaluation.add_argument("--catalog")
    add_request_options(evaluation)
    evaluation.add_argument("--budget-usd", type=float, required=True)
    evaluation.add_argument("--max-candidates", type=int, default=1)
    evaluation.add_argument("--evaluation-task", action="append")
    evaluation.add_argument("--planned-sample-count", type=int, default=1)
    evaluation.add_argument("--stopping-rules", help="JSON object containing explicit stopping rules")
    evaluation.add_argument("--reserve", action="store_true")

    snapshot = sub.add_parser("snapshot", help="emit an expiring runtime routing snapshot for tool-less clients")
    snapshot.add_argument("--catalog")
    snapshot.add_argument("--output")
    add_request_options(snapshot)

    launch = sub.add_parser("launch", help="route, substitute placeholders, and start a client without a shell")
    launch.add_argument("--catalog")
    add_request_options(launch)
    launch.add_argument("client_command", nargs=argparse.REMAINDER)

    mcp = sub.add_parser("mcp", help="run the newline-delimited JSON-RPC MCP stdio adapter")
    mcp.add_argument("--catalog")

    launcher = sub.add_parser("install-launcher", help="create a local ai-model-router launcher outside the repository")
    launcher.add_argument("--bin-dir")

    sub.add_parser("state-path", help="show the resolved local runtime paths")
    return root


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "state-path":
            store = RuntimeStore(Path(args.state_dir) if args.state_dir else None)
            print_json({"state_dir": str(store.root), "catalog": str(store.catalog_path), "runtime_state": str(store.state_path)})
            return 0
        if args.command == "install-launcher":
            store = RuntimeStore(Path(args.state_dir) if args.state_dir else None)
            bin_dir = Path(args.bin_dir).resolve() if args.bin_dir else store.root / "bin"
            print_json(install_launcher(Path(__file__), bin_dir))
            return 0
        if args.command == "sync-ollama":
            from ollama_cloud import sync_ollama_catalog

            store = RuntimeStore(Path(args.state_dir) if args.state_dir else None)
            previous_path = ensure_runtime_location(Path(args.output)) if args.output else store.catalog_path
            previous = load_json(previous_path, "previous model catalog") if previous_path.exists() else None
            profiles = load_json(Path(args.profiles).resolve(), "model profile overlay") if args.profiles else None
            catalog = sync_ollama_catalog(
                model_url=args.model_url,
                pricing_url=args.pricing_url,
                timeout_seconds=args.timeout_seconds,
                ttl_hours=args.ttl_hours,
                previous=previous,
                profiles=profiles,
            )
            if args.output:
                atomic_json_write(previous_path, catalog)
            else:
                store.write_catalog(catalog)
            print_json(catalog)
            return 0
        if args.command == "record-outcome":
            store = RuntimeStore(Path(args.state_dir) if args.state_dir else None)
            row = store.record_outcome(
                provider=args.provider,
                model=args.model,
                task_class=args.task_class,
                success=args.success,
                actual_cost_usd=decimal_value(args.actual_cost_usd, "actual cost", minimum=Decimal(0)),
                latency_ms=decimal_value(args.latency_ms, "latency", minimum=Decimal(0)) if args.latency_ms is not None else None,
                session_id=args.session_id,
                context_tokens=args.context_tokens,
                pricing_epoch=args.pricing_epoch,
                evaluation_id=args.evaluation_id,
            )
            print_json({"status": "RECORDED", "outcome": row})
            return 0
        if args.command == "mcp":
            from mcp_stdio import serve

            store = RuntimeStore(Path(args.state_dir) if args.state_dir else None)
            catalog_path = ensure_runtime_location(Path(args.catalog)) if args.catalog else store.catalog_path
            return serve(catalog_path=catalog_path, state_dir=store.root)

        router, _store = router_from_args(args)
        request = request_from_args(args)
        if args.command == "route":
            print_json(router.route(request))
            return 0
        if args.command == "plan-evaluation":
            if args.max_candidates < 1:
                raise RouterError("max-candidates must be positive")
            plan = router.plan_evaluation(
                request,
                budget_usd=decimal_value(args.budget_usd, "evaluation budget", minimum=Decimal(0)),
                max_candidates=args.max_candidates,
                reserve=args.reserve,
                task_set=args.evaluation_task,
                planned_sample_count=args.planned_sample_count,
                stopping_rules=load_request_argument(args.stopping_rules) if args.stopping_rules else None,
            )
            print_json(plan)
            return 0
        if args.command == "snapshot":
            payload = router.snapshot(request)
            if args.output:
                atomic_json_write(ensure_runtime_location(Path(args.output)), payload)
            print_json(payload)
            return 0
        if args.command == "launch":
            decision = router.route(request)
            if decision["status"] != "ROUTED":
                print_json(decision)
                return 3
            command = list(args.client_command)
            if command and command[0] == "--":
                command = command[1:]
            if not command:
                raise RouterError("launch requires a client command after --")
            route = decision["route"]
            replacements = {
                "{provider}": route["provider"],
                "{model}": route["model"],
                "{reasoning_effort}": decision["execution"].get("reasoning_effort") or "",
                "{context_budget}": str(decision["execution"]["context_budget_tokens"]),
                "{output_budget}": str(decision["execution"]["output_budget_tokens"]),
            }
            resolved = [replacements.get(part, part) for part in command]
            environment = dict(os.environ)
            environment.update(
                {
                    "AI_ROUTED_PROVIDER": route["provider"],
                    "AI_ROUTED_MODEL": route["model"],
                    "AI_ROUTED_REASONING_EFFORT": decision["execution"].get("reasoning_effort") or "",
                    "AI_ROUTING_DECISION_ID": decision["decision_id"],
                }
            )
            return subprocess.run(resolved, env=environment, check=False).returncode
        raise RouterError(f"unsupported command: {args.command}")
    except (OSError, RouterError, ValueError) as exc:
        print_json({"status": "ERROR", "error": str(exc)})
        return 2


if __name__ == "__main__":
    sys.exit(main())

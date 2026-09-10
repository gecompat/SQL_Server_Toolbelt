#!/usr/bin/env python3
"""Optional resumable, authority-preserving executor for foundation-ai-work/v1 plans."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Callable, Iterator


CONTRACT = "foundation-ai-work/v1"
CHECKPOINT_CONTRACT = "foundation-ai-executor-checkpoint/v1"
ADAPTER_PROTOCOL = "foundation-ai-adapter-jsonl/v1"
APPROVAL_CONTRACT = "foundation-ai-approval/v1"
EXTERNAL_EFFECTS = {"EXTERNAL_WRITE", "PUBLISH", "DATA_TRANSFER", "SPEND"}
RESOURCE_LIMITS = {
    "cpu_seconds": "max_cpu_seconds",
    "ram_mb": "max_ram_mb",
    "vram_mb": "max_vram_mb",
    "disk_mb": "max_disk_mb",
    "network_mb": "max_network_mb",
    "gpu_seconds": "max_gpu_seconds",
    "energy_wh": "max_energy_wh",
}
PEAK_RESOURCES = {"ram_mb", "vram_mb"}
FORBIDDEN_CONTROL_KEYS = {"prompt", "response", "content", "secret", "credential", "token"}


def _load_planner() -> Any:
    here = Path(__file__).resolve().parent
    candidates = [
        here.parent / "ai-work" / "ai_work.py",
        here.parent / "ai_work" / "ai_work.py",
    ]
    source = next((item for item in candidates if item.is_file()), None)
    if source is None:
        raise RuntimeError("the ai-work planner capability is required")
    spec = importlib.util.spec_from_file_location("foundation_ai_work_for_executor", source)
    if spec is None or spec.loader is None:
        raise RuntimeError("the ai-work planner capability cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ai_work = _load_planner()


class ExecutionError(RuntimeError):
    """A bounded control-plane error safe to return without payload or secret detail."""

    def __init__(self, code: str, message: str, *, error_class: str = "CONTRACT") -> None:
        super().__init__(message)
        self.code = code
        self.error_class = error_class


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_datetime(value: Any, field: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError as exc:
        raise ExecutionError("INVALID_TIMESTAMP", f"{field} must be an ISO-8601 timestamp") from exc
    if parsed.tzinfo is None:
        raise ExecutionError("INVALID_TIMESTAMP", f"{field} must include a timezone")
    return parsed.astimezone(timezone.utc)


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def digest(value: Any) -> str:
    return "sha256:" + hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()


def nonnegative(value: Any, field: str) -> Decimal:
    if isinstance(value, bool) or not isinstance(value, (int, float, Decimal)):
        raise ExecutionError("INVALID_NUMBER", f"{field} must be numeric")
    try:
        result = Decimal(str(value))
    except (InvalidOperation, ValueError) as exc:
        raise ExecutionError("INVALID_NUMBER", f"{field} must be numeric") from exc
    if not result.is_finite() or result < 0:
        raise ExecutionError("INVALID_NUMBER", f"{field} must be finite and non-negative")
    return result


def content_free(value: Any) -> bool:
    if isinstance(value, dict):
        keys = {str(key).lower() for key in value}
        if any(fragment in key for key in keys for fragment in FORBIDDEN_CONTROL_KEYS):
            return False
        return all(content_free(item) for item in value.values())
    if isinstance(value, list):
        return all(content_free(item) for item in value)
    return True


def find_git_root(path: Path) -> Path | None:
    resolved = path.resolve()
    for candidate in (resolved, *resolved.parents):
        if (candidate / ".git").exists():
            return candidate
    return None


def default_state_dir() -> Path:
    override = os.environ.get("AI_WORK_EXECUTOR_HOME")
    if override:
        return Path(override).expanduser().resolve()
    if os.name == "nt" and os.environ.get("LOCALAPPDATA"):
        return (Path(os.environ["LOCALAPPDATA"]) / "ai-work-executor").resolve()
    if sys.platform == "darwin":
        return (Path.home() / "Library" / "Application Support" / "ai-work-executor").resolve()
    base = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    return (base / "ai-work-executor").expanduser().resolve()


def ensure_external(path: Path) -> Path:
    resolved = path.expanduser().resolve()
    repository = find_git_root(resolved)
    if repository is not None:
        raise ExecutionError(
            "RUNTIME_STATE_IN_VERSION_CONTROL",
            f"executor runtime state must remain outside version control; choose a location outside {repository}",
            error_class="PERMISSION",
        )
    return resolved


@contextlib.contextmanager
def file_lock(path: Path, timeout_seconds: float = 5.0) -> Iterator[None]:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open("a+b")
    handle.seek(0, os.SEEK_END)
    if handle.tell() == 0:
        handle.write(b"0")
        handle.flush()
    deadline = time.monotonic() + timeout_seconds
    locked = False
    while not locked:
        try:
            handle.seek(0)
            if os.name == "nt":
                import msvcrt

                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl

                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            locked = True
        except (OSError, BlockingIOError):
            if time.monotonic() >= deadline:
                handle.close()
                raise ExecutionError("STATE_LOCK_TIMEOUT", "timed out waiting for executor state lock")
            time.sleep(0.05)
    try:
        yield
    finally:
        handle.seek(0)
        if os.name == "nt":
            import msvcrt

            msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            import fcntl

            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        handle.close()


def atomic_write(path: Path, value: dict[str, Any]) -> None:
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


class CheckpointStore:
    def __init__(self, root: Path | None = None) -> None:
        self.root = ensure_external(root or default_state_dir())

    def path(self, plan_id: str) -> Path:
        return self.root / "checkpoints" / (digest(plan_id)[7:] + ".json")

    def lock_path(self, plan_id: str) -> Path:
        return self.root / "locks" / (digest(plan_id)[7:] + ".lock")

    def cancel_path(self, plan_id: str) -> Path:
        return self.root / "cancellations" / (digest(plan_id)[7:] + ".json")

    @staticmethod
    def seal(value: dict[str, Any]) -> dict[str, Any]:
        payload = {key: item for key, item in value.items() if key != "integrity_sha256"}
        return {**payload, "integrity_sha256": digest(payload)}

    def load(self, plan_id: str) -> dict[str, Any] | None:
        path = self.path(plan_id)
        if not path.exists():
            return None
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint is unreadable") from exc
        if not isinstance(value, dict) or value.get("integrity_sha256") != self.seal(value)["integrity_sha256"]:
            raise ExecutionError("CHECKPOINT_INTEGRITY_FAILURE", "executor checkpoint integrity check failed")
        validate_checkpoint(value, plan_id)
        return value

    def save(self, value: dict[str, Any]) -> dict[str, Any]:
        sealed = self.seal(value)
        validate_checkpoint(sealed, sealed.get("plan_id"))
        atomic_write(self.path(sealed["plan_id"]), sealed)
        return sealed

    def request_cancel(self, plan: dict[str, Any], at: datetime) -> None:
        atomic_write(
            self.cancel_path(plan["plan_id"]),
            {
                "contract": CHECKPOINT_CONTRACT,
                "plan_id": plan["plan_id"],
                "scope_sha256": digest(plan),
                "requested_at": isoformat(at),
            },
        )

    def cancellation_requested(self, plan: dict[str, Any]) -> bool:
        path = self.cancel_path(plan["plan_id"])
        if not path.is_file():
            return False
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ExecutionError("CANCELLATION_MARKER_INVALID", "cancellation marker is unreadable") from exc
        expected = {"contract", "plan_id", "scope_sha256", "requested_at"}
        if (
            not isinstance(value, dict)
            or set(value) != expected
            or value.get("contract") != CHECKPOINT_CONTRACT
            or value.get("plan_id") != plan["plan_id"]
            or value.get("scope_sha256") != digest(plan)
        ):
            raise ExecutionError("CANCELLATION_MARKER_INVALID", "cancellation marker does not match this exact plan")
        parse_datetime(value.get("requested_at"), "cancellation.requested_at")
        return True


def validate_checkpoint(raw: Any, plan_id: Any) -> None:
    fields = {
        "schema_version", "contract", "plan_id", "work_id", "request_sha256", "state",
        "created_at", "updated_at", "attempts", "evidence", "integrity_sha256",
    }
    if (
        not isinstance(raw, dict)
        or set(raw) != fields
        or raw.get("schema_version") != 1
        or raw.get("contract") != CHECKPOINT_CONTRACT
        or not isinstance(plan_id, str)
        or raw.get("plan_id") != plan_id
        or raw.get("state") not in {"ACTIVE", "COMPLETED", "FAILED", "CANCELLED", "MANUAL_REQUIRED", "UNAVAILABLE", "BLOCKED"}
    ):
        raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint has an invalid contract shape")
    if not isinstance(raw.get("work_id"), str) or not raw["work_id"]:
        raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint work identifier is invalid")
    if not isinstance(raw.get("request_sha256"), str) or not _is_sha256(raw["request_sha256"]):
        raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint request digest is invalid")
    if not isinstance(raw.get("integrity_sha256"), str) or not _is_sha256(raw["integrity_sha256"]):
        raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint integrity digest is invalid")
    parse_datetime(raw.get("created_at"), "checkpoint.created_at")
    parse_datetime(raw.get("updated_at"), "checkpoint.updated_at")
    if not isinstance(raw.get("attempts"), list) or not isinstance(raw.get("evidence"), list) or not content_free(raw):
        raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint contains invalid control-plane data")
    attempt_fields = {
        "step_id", "capability_id", "operation_key", "status", "started_at", "ended_at",
        "error_class", "actual_cost_usd", "resource_usage", "output_sha256",
    }
    active = 0
    for attempt in raw["attempts"]:
        if not isinstance(attempt, dict) or set(attempt) != attempt_fields:
            raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint contains an invalid attempt")
        if attempt.get("status") not in {"PREPARED", "IN_PROGRESS", "SUCCEEDED", "FAILED", "CANCELLED", "UNKNOWN"}:
            raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint attempt status is invalid")
        if attempt["status"] in {"PREPARED", "IN_PROGRESS"}:
            active += 1
        for field in ("step_id", "capability_id", "operation_key"):
            if not isinstance(attempt.get(field), str) or not attempt[field]:
                raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint attempt identifier is invalid")
        parse_datetime(attempt.get("started_at"), "checkpoint.attempt.started_at")
        if attempt.get("ended_at") is not None:
            parse_datetime(attempt["ended_at"], "checkpoint.attempt.ended_at")
        nonnegative(attempt.get("actual_cost_usd"), "checkpoint.attempt.actual_cost_usd")
        if not isinstance(attempt.get("resource_usage"), dict) or set(attempt["resource_usage"]) - set(RESOURCE_LIMITS):
            raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint resource usage is invalid")
        for name, value in attempt["resource_usage"].items():
            nonnegative(value, f"checkpoint.attempt.resource_usage.{name}")
        if attempt.get("output_sha256") is not None and not _is_sha256(attempt["output_sha256"]):
            raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint output digest is invalid")
    if active > 1:
        raise ExecutionError("CHECKPOINT_CORRUPT", "executor checkpoint contains multiple active attempts")


def _is_sha256(value: Any) -> bool:
    if not isinstance(value, str) or len(value) != 71 or not value.startswith("sha256:"):
        return False
    try:
        int(value[7:], 16)
    except ValueError:
        return False
    return value[7:] == value[7:].lower()


def validate_plan(raw: Any) -> dict[str, Any]:
    fields = {
        "schema_version", "contract", "plan_id", "work_id", "status", "generated_at", "valid_until",
        "steps", "approval_points", "constraints", "reason_codes",
    }
    if not isinstance(raw, dict) or set(raw) != fields or raw.get("schema_version") != 1 or raw.get("contract") != CONTRACT:
        raise ExecutionError("INVALID_PLAN", "execution plan has an invalid contract shape")
    if raw.get("status") not in {"EXECUTABLE", "MANUAL_REQUIRED", "UNAVAILABLE", "BLOCKED"}:
        raise ExecutionError("INVALID_PLAN", "execution plan status is invalid")
    generated = parse_datetime(raw.get("generated_at"), "plan.generated_at")
    expires = parse_datetime(raw.get("valid_until"), "plan.valid_until")
    if expires <= generated:
        raise ExecutionError("INVALID_PLAN", "execution plan expiry must follow generation")
    if not isinstance(raw.get("steps"), list) or not isinstance(raw.get("approval_points"), list):
        raise ExecutionError("INVALID_PLAN", "execution plan steps and approval points must be arrays")
    ids: set[str] = set()
    complete: set[str] = set()
    for step in raw["steps"]:
        required = {"step_id", "capability_id", "operation", "depends_on", "alternatives", "input_handles", "output_handles"}
        if not isinstance(step, dict) or set(step) != required or not isinstance(step.get("step_id"), str):
            raise ExecutionError("INVALID_PLAN", "execution plan contains an invalid step")
        if step["step_id"] in ids or not set(step["depends_on"]) <= complete:
            raise ExecutionError("INVALID_PLAN_DAG", "execution plan steps must be unique and topologically ordered")
        for field in ("depends_on", "alternatives", "input_handles", "output_handles"):
            if not isinstance(step[field], list) or any(not isinstance(item, str) or not item for item in step[field]):
                raise ExecutionError("INVALID_PLAN", f"step {field} must contain strings")
        ids.add(step["step_id"])
        complete.add(step["step_id"])
    for point in raw["approval_points"]:
        if not isinstance(point, dict) or set(point) != {"before_steps", "authority_required", "reasons"}:
            raise ExecutionError("INVALID_PLAN", "execution plan contains an invalid approval point")
        if not set(point["before_steps"]) <= ids:
            raise ExecutionError("INVALID_PLAN", "approval point refers to an unknown step")
    return json.loads(canonical_json(raw))


def validate_bindings(raw: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(raw, dict) or set(raw) != {"bindings"} or not isinstance(raw["bindings"], dict):
        raise ExecutionError("INVALID_BINDINGS", "bindings must contain only a bindings object")
    result: dict[str, dict[str, Any]] = {}
    allowed = {"argv", "environment_allowlist", "timeout_seconds", "model", "remote_authorized"}
    for capability_id, binding in raw["bindings"].items():
        if not isinstance(capability_id, str) or not capability_id or not isinstance(binding, dict) or set(binding) - allowed:
            raise ExecutionError("INVALID_BINDINGS", "adapter binding shape is invalid")
        argv = binding.get("argv")
        if not isinstance(argv, list) or not argv or any(not isinstance(item, str) or not item for item in argv):
            raise ExecutionError("INVALID_BINDINGS", "binding argv must contain non-empty strings")
        if not Path(argv[0]).is_absolute():
            raise ExecutionError("INVALID_BINDINGS", "binding executable must be an absolute path")
        names = binding.get("environment_allowlist", [])
        if not isinstance(names, list) or any(not isinstance(item, str) or not item for item in names):
            raise ExecutionError("INVALID_BINDINGS", "binding environment_allowlist is invalid")
        timeout = nonnegative(binding.get("timeout_seconds", 30), "binding.timeout_seconds")
        if timeout <= 0:
            raise ExecutionError("INVALID_BINDINGS", "binding timeout_seconds must be positive")
        if "remote_authorized" in binding and not isinstance(binding["remote_authorized"], bool):
            raise ExecutionError("INVALID_BINDINGS", "binding remote_authorized must be boolean")
        if "model" in binding and (not isinstance(binding["model"], str) or not binding["model"]):
            raise ExecutionError("INVALID_BINDINGS", "binding model must be a non-empty string")
        result[capability_id] = {**binding, "argv": list(argv), "environment_allowlist": list(names), "timeout_seconds": float(timeout)}
    return result


def validate_handles(raw: Any, required: set[str]) -> dict[str, str]:
    if not isinstance(raw, dict) or set(raw) != {"handles"} or not isinstance(raw["handles"], dict):
        raise ExecutionError("INVALID_HANDLES", "handles must contain only a handles object")
    values: dict[str, str] = {}
    for handle_id, path in raw["handles"].items():
        if not isinstance(handle_id, str) or not handle_id or not isinstance(path, str) or not path:
            raise ExecutionError("INVALID_HANDLES", "handle mappings must use non-empty strings")
        values[handle_id] = str(Path(path).expanduser().resolve())
    missing = sorted(required - set(values))
    if missing:
        raise ExecutionError("MISSING_HANDLE", "required handle mapping is unavailable")
    return values


def validate_approvals(raw: Any, plan: dict[str, Any], at: datetime) -> dict[str, str]:
    if raw is None:
        return {}
    if not isinstance(raw, dict) or set(raw) != {"approvals"} or not isinstance(raw["approvals"], list):
        raise ExecutionError("INVALID_APPROVAL", "approval file must contain only an approvals array")
    expected = {digest(point): point["authority_required"] for point in plan["approval_points"]}
    accepted: dict[str, str] = {}
    receipt_ids: set[str] = set()
    for receipt in raw["approvals"]:
        fields = {"schema_version", "contract", "receipt_id", "plan_id", "approval_key", "scope_sha256", "authority", "approved_at", "expires_at"}
        if not isinstance(receipt, dict) or set(receipt) != fields or receipt.get("schema_version") != 1 or receipt.get("contract") != APPROVAL_CONTRACT:
            raise ExecutionError("INVALID_APPROVAL", "approval receipt has an invalid contract shape")
        if receipt["plan_id"] != plan["plan_id"] or receipt["scope_sha256"] != digest(plan):
            raise ExecutionError("INVALID_APPROVAL_SCOPE", "approval receipt does not match this exact plan")
        for field in ("receipt_id", "approval_key", "authority"):
            if not isinstance(receipt[field], str) or not receipt[field]:
                raise ExecutionError("INVALID_APPROVAL", f"approval {field} must be a non-empty string")
        required_authority = expected.get(receipt["approval_key"])
        if required_authority is None or receipt["authority"] != required_authority:
            raise ExecutionError("INVALID_APPROVAL_AUTHORITY", "approval authority does not satisfy this approval point")
        if receipt["receipt_id"] in receipt_ids or receipt["approval_key"] in accepted:
            raise ExecutionError("INVALID_APPROVAL", "approval receipts must have unique identifiers and approval points")
        approved = parse_datetime(receipt["approved_at"], "approval.approved_at")
        expires = parse_datetime(receipt["expires_at"], "approval.expires_at")
        if approved > at or expires <= at or expires <= approved:
            raise ExecutionError("APPROVAL_EXPIRED", "approval receipt is not currently valid")
        accepted[receipt["approval_key"]] = receipt["authority"]
        receipt_ids.add(receipt["receipt_id"])
    return accepted


def adapter_call(binding: dict[str, Any], frame: dict[str, Any]) -> dict[str, Any]:
    environment = {name: os.environ[name] for name in binding["environment_allowlist"] if name in os.environ}
    try:
        process = subprocess.run(
            binding["argv"],
            input=(canonical_json(frame) + "\n").encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            timeout=binding["timeout_seconds"],
            shell=False,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise ExecutionError("ADAPTER_TIMEOUT", "adapter process timed out", error_class="TIMEOUT") from exc
    except OSError as exc:
        raise ExecutionError("ADAPTER_UNAVAILABLE", "adapter process is unavailable", error_class="AVAILABILITY") from exc
    if process.returncode != 0:
        raise ExecutionError("ADAPTER_PROCESS_FAILED", "adapter process returned non-zero", error_class="AVAILABILITY")
    lines = [line for line in process.stdout.decode("utf-8", errors="replace").splitlines() if line.strip()]
    if len(lines) != 1:
        raise ExecutionError("INVALID_ADAPTER_RESPONSE", "adapter must return exactly one JSONL response", error_class="PROTOCOL")
    try:
        response = json.loads(lines[0])
    except json.JSONDecodeError as exc:
        raise ExecutionError("INVALID_ADAPTER_RESPONSE", "adapter returned invalid JSON", error_class="PROTOCOL") from exc
    if not isinstance(response, dict) or response.get("protocol") != ADAPTER_PROTOCOL or response.get("request_id") != frame["request_id"]:
        raise ExecutionError("INVALID_ADAPTER_RESPONSE", "adapter response does not match the request", error_class="PROTOCOL")
    if response.get("status") == "ERROR":
        error = response.get("error", {})
        raise ExecutionError(str(error.get("code", "ADAPTER_ERROR")), "adapter reported a bounded error", error_class=str(error.get("class", "ADAPTER")))
    result = response.get("result")
    if response.get("status") != "OK" or not isinstance(result, dict) or not content_free(result):
        raise ExecutionError("INVALID_ADAPTER_RESULT", "adapter result is invalid or contains payload content", error_class="PROTOCOL")
    return result


def validate_evidence(raw: Any, *, capability_id: str, subject_sha256: str, at: datetime) -> dict[str, Any]:
    fields = {"schema_version", "contract", "evidence_id", "subject_sha256", "scope", "method", "producer_capability_id", "independent", "result", "provenance", "observed_at"}
    if not isinstance(raw, dict) or set(raw) != fields or raw.get("schema_version") != 1 or raw.get("contract") != CONTRACT:
        raise ExecutionError("INVALID_VALIDATION_EVIDENCE", "validator evidence has an invalid contract shape")
    if raw["producer_capability_id"] != capability_id or raw["subject_sha256"] != subject_sha256:
        raise ExecutionError("INVALID_VALIDATION_EVIDENCE", "validator evidence does not match producer or subject")
    if raw["method"] not in {"DETERMINISTIC", "SOURCE_CHECK", "INDEPENDENT_REVIEW", "HUMAN_REVIEW"} or raw["result"] not in {"PASSED", "FAILED", "INCONCLUSIVE", "UNAVAILABLE"}:
        raise ExecutionError("INVALID_VALIDATION_EVIDENCE", "validator evidence method or result is invalid")
    if not isinstance(raw["independent"], bool) or not isinstance(raw["provenance"], list) or any(not isinstance(item, str) or not item for item in raw["provenance"]):
        raise ExecutionError("INVALID_VALIDATION_EVIDENCE", "validator evidence metadata is invalid")
    if parse_datetime(raw["observed_at"], "evidence.observed_at") > at:
        raise ExecutionError("INVALID_VALIDATION_EVIDENCE", "validator evidence is from the future")
    return json.loads(canonical_json(raw))


class Executor:
    def __init__(
        self,
        request_raw: Any,
        plan_raw: Any,
        capabilities_raw: Any,
        bindings_raw: Any,
        handles_raw: Any,
        *,
        store: CheckpointStore,
        approvals_raw: Any = None,
        clock: Callable[[], datetime] = utc_now,
        invoke: Callable[[dict[str, Any], dict[str, Any]], dict[str, Any]] = adapter_call,
    ) -> None:
        try:
            self.request = ai_work.validate_request(request_raw)
            self.capabilities, invalid = ai_work.validate_capabilities_isolated(capabilities_raw)
        except ai_work.WorkError as exc:
            raise ExecutionError("INVALID_WORK_INPUT", str(exc)) from exc
        if invalid:
            raise ExecutionError("INVALID_CAPABILITY_CATALOG", "executor requires the exact valid planning catalog")
        self.plan = validate_plan(plan_raw)
        if self.request["work_id"] != self.plan["work_id"]:
            raise ExecutionError("PLAN_REQUEST_MISMATCH", "plan and request work identifiers differ")
        try:
            expected = ai_work.plan(
                self.request,
                self.capabilities,
                at=ai_work.parse_datetime(self.plan["generated_at"], "plan.generated_at"),
            )
        except ai_work.WorkError as exc:
            raise ExecutionError("PLAN_REVALIDATION_FAILED", str(exc)) from exc
        if expected != self.plan:
            raise ExecutionError("PLAN_REVALIDATION_FAILED", "plan does not match the request and capability catalog")
        self.clock = clock
        now = clock().astimezone(timezone.utc)
        if parse_datetime(self.plan["valid_until"], "plan.valid_until") <= now:
            raise ExecutionError("PLAN_EXPIRED", "execution plan is expired")
        self.bindings = validate_bindings(bindings_raw)
        required_handles = {
            handle_id
            for step in self.plan["steps"]
            for handle_id in step["input_handles"] + step["output_handles"]
        }
        self.handles = validate_handles(handles_raw, required_handles)
        self.approvals = validate_approvals(approvals_raw, self.plan, now)
        self.store = store
        self.invoke = invoke
        self.by_capability = {item["capability_id"]: item for item in self.capabilities}
        self.request_sha256 = digest(self.request)

    def _initial_state(self, at: datetime) -> dict[str, Any]:
        timestamp = isoformat(at)
        return self.store.seal(
            {
                "schema_version": 1,
                "contract": CHECKPOINT_CONTRACT,
                "plan_id": self.plan["plan_id"],
                "work_id": self.plan["work_id"],
                "request_sha256": self.request_sha256,
                "state": "ACTIVE",
                "created_at": timestamp,
                "updated_at": timestamp,
                "attempts": [],
                "evidence": [],
            }
        )

    def _save(self, state: dict[str, Any]) -> dict[str, Any]:
        state["updated_at"] = isoformat(self.clock().astimezone(timezone.utc))
        return self.store.save(state)

    def _approval_missing(self, step_id: str) -> bool:
        for point in self.plan["approval_points"]:
            key = digest(point)
            if step_id in point["before_steps"] and self.approvals.get(key) != point["authority_required"]:
                return True
        return False

    @staticmethod
    def _successful(state: dict[str, Any], step_id: str) -> dict[str, Any] | None:
        return next((item for item in reversed(state["attempts"]) if item["step_id"] == step_id and item["status"] == "SUCCEEDED"), None)

    def _totals(self, state: dict[str, Any]) -> tuple[Decimal, dict[str, Decimal]]:
        cost = sum((Decimal(str(item["actual_cost_usd"])) for item in state["attempts"]), Decimal(0))
        resources: dict[str, Decimal] = {}
        for attempt in state["attempts"]:
            for name, value in attempt["resource_usage"].items():
                observed = Decimal(str(value))
                if name in PEAK_RESOURCES:
                    resources[name] = max(resources.get(name, Decimal(0)), observed)
                else:
                    resources[name] = resources.get(name, Decimal(0)) + observed
        return cost, resources

    def _preflight_budget(self, state: dict[str, Any], capability: dict[str, Any]) -> str | None:
        limits = self.request["limits"]
        cost, resources = self._totals(state)
        estimate = capability["cost_model"].get("estimated_cost")
        if "max_cost_usd" in limits:
            if estimate is None or capability["cost_model"]["provenance"] == "UNKNOWN":
                return "COST_UNKNOWN_UNDER_HARD_LIMIT"
            if cost + Decimal(str(estimate)) > Decimal(str(limits["max_cost_usd"])):
                return "COST_LIMIT_EXCEEDED"
        for resource, limit_name in RESOURCE_LIMITS.items():
            if limit_name not in limits:
                continue
            if resource not in capability["resources"]:
                return f"{resource.upper()}_UNKNOWN_UNDER_HARD_LIMIT"
            estimate = Decimal(str(capability["resources"][resource]))
            projected = max(resources.get(resource, Decimal(0)), estimate) if resource in PEAK_RESOURCES else resources.get(resource, Decimal(0)) + estimate
            if projected > Decimal(str(limits[limit_name])):
                return f"{resource.upper()}_LIMIT_EXCEEDED"
        return None

    def _new_attempt(self, step: dict[str, Any], capability_id: str, index: int, at: datetime) -> dict[str, Any]:
        operation_key = digest(
            {"plan_id": self.plan["plan_id"], "step_id": step["step_id"], "capability_id": capability_id, "attempt": index}
        )
        return {
            "step_id": step["step_id"],
            "capability_id": capability_id,
            "operation_key": operation_key,
            "status": "PREPARED",
            "started_at": isoformat(at),
            "ended_at": None,
            "error_class": None,
            "actual_cost_usd": 0,
            "resource_usage": {},
            "output_sha256": None,
        }

    def _frame(self, step: dict[str, Any], attempt: dict[str, Any], binding: dict[str, Any]) -> dict[str, Any]:
        if len(step["input_handles"]) != 1 or len(step["output_handles"]) != 1:
            raise ExecutionError("REFERENCE_BINDING_ARITY", "reference executor bindings require one input and one output handle")
        arguments: dict[str, Any] = {
            "operation_id": attempt["operation_key"],
            "data_class": self.request["data_class"],
            "input_path": self.handles[step["input_handles"][0]],
            "output_path": self.handles[step["output_handles"][0]],
        }
        if binding.get("model") is not None:
            arguments["model"] = binding["model"]
        if binding.get("remote_authorized") is not None:
            arguments["remote_authorized"] = binding["remote_authorized"]
        return {
            "protocol": ADAPTER_PROTOCOL,
            "request_id": attempt["operation_key"],
            "operation": "invoke",
            "arguments": arguments,
        }

    def _recover_ambiguous(self, state: dict[str, Any]) -> dict[str, Any] | None:
        active = [item for item in state["attempts"] if item["status"] in {"PREPARED", "IN_PROGRESS"}]
        if not active:
            return None
        if len(active) != 1:
            raise ExecutionError("CHECKPOINT_CORRUPT", "checkpoint contains multiple active attempts")
        ambiguous = active[0]
        if ambiguous["status"] == "PREPARED":
            return None
        capability = self.by_capability.get(ambiguous["capability_id"])
        external = bool(set(self.request["effects"]) & EXTERNAL_EFFECTS)
        idempotency = capability.get("execution", {}).get("idempotency", "NONE") if capability is not None else "NONE"
        if external and idempotency != "IDEMPOTENT_REPLAY":
            ambiguous["status"] = "UNKNOWN"
            ambiguous["ended_at"] = isoformat(self.clock())
            ambiguous["error_class"] = "AMBIGUOUS_EXTERNAL_OUTCOME"
            state["state"] = "MANUAL_REQUIRED"
            self._save(state)
            return self._report(state, "MANUAL_REQUIRED", ["AMBIGUOUS_EXTERNAL_OUTCOME"], ["reconcile the external operation before retrying"])
        ambiguous["status"] = "PREPARED"
        ambiguous["ended_at"] = None
        ambiguous["error_class"] = None
        self._save(state)
        return None

    def _effective_binding(self, binding: dict[str, Any]) -> dict[str, Any]:
        ceilings = [float(binding["timeout_seconds"])]
        request_timeout = self.request["limits"].get("timeout_seconds")
        if request_timeout is not None:
            ceilings.append(float(request_timeout))
        deadline = self.request["limits"].get("deadline")
        if deadline is not None:
            remaining = (parse_datetime(deadline, "limits.deadline") - self.clock()).total_seconds()
            if remaining <= 0:
                raise ExecutionError("DEADLINE_EXPIRED", "execution deadline has expired", error_class="BUDGET")
            ceilings.append(remaining)
        return {**binding, "timeout_seconds": max(0.001, min(ceilings))}

    def _runtime_eligible(self, capability: dict[str, Any]) -> bool:
        return not ai_work._eligibility(self.request, capability, self.clock().astimezone(timezone.utc))

    def _verify_output(self, step: dict[str, Any], output_sha256: str, output_bytes: Any = None) -> None:
        output_path = Path(self.handles[step["output_handles"][0]])
        try:
            body = output_path.read_bytes()
            observed = "sha256:" + hashlib.sha256(body).hexdigest()
        except OSError as exc:
            raise ExecutionError("OUTPUT_UNAVAILABLE", "adapter output handle is unavailable", error_class="PROTOCOL") from exc
        if observed != output_sha256:
            raise ExecutionError("OUTPUT_HASH_MISMATCH", "adapter output digest does not match the output handle", error_class="PROTOCOL")
        if output_bytes is not None and nonnegative(output_bytes, "result.output_bytes") != len(body):
            raise ExecutionError("OUTPUT_SIZE_MISMATCH", "adapter output size does not match the output handle", error_class="PROTOCOL")

    def _invoke_attempt(self, state: dict[str, Any], step: dict[str, Any], attempt: dict[str, Any], capability: dict[str, Any]) -> bool:
        binding = self.bindings.get(attempt["capability_id"])
        if binding is None:
            attempt.update({"status": "FAILED", "ended_at": isoformat(self.clock()), "error_class": "ADAPTER_BINDING_UNAVAILABLE"})
            self._save(state)
            return False
        attempt["status"] = "IN_PROGRESS"
        self._save(state)
        try:
            effective_binding = self._effective_binding(binding)
            result = self.invoke(effective_binding, self._frame(step, attempt, effective_binding))
            if not isinstance(result, dict) or not content_free(result):
                raise ExecutionError("INVALID_ADAPTER_RESULT", "adapter result is invalid or contains payload content", error_class="PROTOCOL")
            allowed_result = {
                "status", "operation_id", "output_sha256", "output_bytes",
                "actual_cost_usd", "resource_usage", "validation_evidence",
            }
            if set(result) - allowed_result:
                raise ExecutionError("INVALID_ADAPTER_RESULT", "adapter result contains unsupported fields", error_class="PROTOCOL")
            if result.get("status", "COMPLETED") != "COMPLETED" or result.get("operation_id", attempt["operation_key"]) != attempt["operation_key"]:
                raise ExecutionError("INVALID_ADAPTER_RESULT", "adapter completion does not match the operation", error_class="PROTOCOL")
            actual_cost = nonnegative(result.get("actual_cost_usd", capability["cost_model"].get("estimated_cost", 0)), "result.actual_cost_usd")
            usage_raw = result.get("resource_usage", capability["resources"])
            if not isinstance(usage_raw, dict) or set(usage_raw) - set(RESOURCE_LIMITS):
                raise ExecutionError("INVALID_RESOURCE_USAGE", "adapter resource usage must be an object", error_class="PROTOCOL")
            usage = {name: float(nonnegative(value, f"resource_usage.{name}")) for name, value in usage_raw.items()}
            output_hash = result.get("output_sha256")
            if not _is_sha256(output_hash):
                raise ExecutionError("OUTPUT_HASH_REQUIRED", "adapter must return an output SHA-256", error_class="PROTOCOL")
            self._verify_output(step, output_hash, result.get("output_bytes"))
            attempt.update(
                {
                    "status": "SUCCEEDED",
                    "ended_at": isoformat(self.clock()),
                    "error_class": None,
                    "actual_cost_usd": float(actual_cost),
                    "resource_usage": usage,
                    "output_sha256": output_hash,
                }
            )
            if step["operation"] == "validate":
                raw_evidence = result.get("validation_evidence")
                evidence_items = raw_evidence if isinstance(raw_evidence, list) else [raw_evidence]
                if not evidence_items:
                    raise ExecutionError("INVALID_VALIDATION_EVIDENCE", "validator returned no validation evidence")
                subject_sha256 = self._subject_hash(state, step)
                required_scopes = set(self.request["validation"]["required_capabilities"])
                known_ids = {item["evidence_id"] for item in state["evidence"]}
                for raw_item in evidence_items:
                    evidence = validate_evidence(
                        raw_item,
                        capability_id=attempt["capability_id"],
                        subject_sha256=subject_sha256,
                        at=self.clock(),
                    )
                    if evidence["scope"] not in required_scopes or evidence["evidence_id"] in known_ids:
                        raise ExecutionError("INVALID_VALIDATION_EVIDENCE", "validation evidence scope or identifier is invalid")
                    if self.request["validation"]["independent_required"]:
                        worker = self._successful(state, "work")
                        if not evidence["independent"] or (worker and worker["capability_id"] == evidence["producer_capability_id"]):
                            raise ExecutionError("INDEPENDENT_VALIDATION_REQUIRED", "validation evidence is not independent")
                    state["evidence"].append(evidence)
                    known_ids.add(evidence["evidence_id"])
            self._save(state)
            return True
        except ExecutionError as exc:
            attempt.update({"status": "FAILED", "ended_at": isoformat(self.clock()), "error_class": exc.error_class})
            self._save(state)
            return False
        except Exception:
            attempt.update({"status": "FAILED", "ended_at": isoformat(self.clock()), "error_class": "ADAPTER_UNHANDLED"})
            self._save(state)
            return False

    def _subject_hash(self, state: dict[str, Any], step: dict[str, Any]) -> str:
        dependencies = [self._successful(state, dependency) for dependency in step["depends_on"]]
        hashes = [item["output_sha256"] for item in dependencies if item]
        if len(hashes) != 1:
            raise ExecutionError("VALIDATION_SUBJECT_UNAVAILABLE", "validation step has no single completed subject")
        return hashes[0]

    def _actual_limits(self, state: dict[str, Any]) -> list[str]:
        cost, resources = self._totals(state)
        limits = self.request["limits"]
        failures: list[str] = []
        if "max_cost_usd" in limits and cost > Decimal(str(limits["max_cost_usd"])):
            failures.append("ACTUAL_COST_LIMIT_EXCEEDED")
        for resource, limit_name in RESOURCE_LIMITS.items():
            if limit_name in limits and resources.get(resource, Decimal(0)) > Decimal(str(limits[limit_name])):
                failures.append(f"ACTUAL_{resource.upper()}_LIMIT_EXCEEDED")
        return failures

    def _validation_status(self, state: dict[str, Any]) -> str:
        required = set(self.request["validation"]["required_capabilities"])
        if not required:
            return "NOT_REQUIRED"
        if not state["evidence"]:
            return "UNAVAILABLE"
        relevant = [item for item in state["evidence"] if item["scope"] in required]
        results = [item["result"] for item in relevant]
        if "FAILED" in results:
            return "FAILED"
        covered = {item["scope"] for item in relevant if item["result"] == "PASSED"}
        if covered == required:
            return "PASSED"
        return "INCONCLUSIVE" if "INCONCLUSIVE" in results else "UNAVAILABLE"

    def _report(self, state: dict[str, Any], status: str, reasons: list[str], remaining: list[str]) -> dict[str, Any]:
        cost, resources = self._totals(state)
        attempts = [
            {
                "step_id": item["step_id"],
                "capability_id": item["capability_id"],
                "operation_key": item["operation_key"],
                "status": "UNKNOWN" if item["status"] in {"PREPARED", "IN_PROGRESS"} else item["status"],
                "started_at": item["started_at"],
                "ended_at": item["ended_at"] or isoformat(self.clock()),
                "error_class": item["error_class"],
                "actual_cost_usd": item["actual_cost_usd"],
                "resource_usage": item["resource_usage"],
                "output_sha256": item["output_sha256"],
            }
            for item in state["attempts"]
        ]
        validation_status = self._validation_status(state)
        material = {"plan_id": self.plan["plan_id"], "attempts": attempts, "validation": validation_status, "status": status}
        return {
            "schema_version": 1,
            "contract": CONTRACT,
            "report_id": digest(material),
            "plan_id": self.plan["plan_id"],
            "work_id": self.plan["work_id"],
            "status": status,
            "finished_at": isoformat(self.clock()),
            "attempts": attempts,
            "validation_evidence_ids": sorted({item["evidence_id"] for item in state["evidence"]}),
            "validation_status": validation_status,
            "resource_usage": {"cost_usd": float(cost), **{name: float(value) for name, value in sorted(resources.items())}},
            "reason_codes": sorted(set(reasons)),
            "remaining_actions": remaining,
        }

    def execute(self) -> dict[str, Any]:
        with file_lock(self.store.lock_path(self.plan["plan_id"])):
            state = self.store.load(self.plan["plan_id"]) or self._initial_state(self.clock())
            if state["request_sha256"] != self.request_sha256 or state["work_id"] != self.plan["work_id"]:
                raise ExecutionError("CHECKPOINT_SCOPE_MISMATCH", "checkpoint does not belong to this request")
            if state["state"] == "COMPLETED":
                return self._report(state, "COMPLETED", ["RESUMED_COMPLETED_REPORT"], [])
            if any(
                item["status"] == "UNKNOWN" and item["error_class"] == "AMBIGUOUS_EXTERNAL_OUTCOME"
                for item in state["attempts"]
            ):
                return self._report(
                    state,
                    "MANUAL_REQUIRED",
                    ["AMBIGUOUS_EXTERNAL_OUTCOME"],
                    ["reconcile the external operation and obtain a new plan"],
                )
            if state["state"] in {"BLOCKED", "UNAVAILABLE", "FAILED", "CANCELLED"}:
                status = state["state"]
                return self._report(
                    state,
                    status,
                    [f"RESUMED_{status}_REPORT"],
                    [] if status == "CANCELLED" else ["obtain a new plan after changing inputs, evidence, capability, or authority"],
                )
            if self.store.cancellation_requested(self.plan):
                state["state"] = "CANCELLED"
                self._save(state)
                return self._report(state, "CANCELLED", ["CANCELLATION_REQUESTED"], [])
            recovered = self._recover_ambiguous(state)
            if recovered is not None:
                return recovered
            if self.plan["status"] in {"UNAVAILABLE", "BLOCKED"} or not self.plan["steps"]:
                status = self.plan["status"]
                state["state"] = status
                self._save(state)
                return self._report(state, status, self.plan["reason_codes"], ["obtain a new executable plan"])
            max_attempts = int(self.request["limits"].get("max_attempts", len(self.plan["steps"]) * 4 or 1))
            deadline = parse_datetime(self.request["limits"]["deadline"], "limits.deadline") if "deadline" in self.request["limits"] else None
            for step in self.plan["steps"]:
                if self._successful(state, step["step_id"]):
                    continue
                if self._approval_missing(step["step_id"]):
                    state["state"] = "MANUAL_REQUIRED"
                    self._save(state)
                    return self._report(state, "MANUAL_REQUIRED", ["GROUPED_APPROVAL_REQUIRED"], ["supply a matching unexpired approval receipt"])
                if deadline is not None and self.clock() >= deadline:
                    state["state"] = "BLOCKED"
                    self._save(state)
                    return self._report(state, "BLOCKED", ["DEADLINE_EXPIRED"], ["obtain a new plan"])
                candidates = [step["capability_id"], *step["alternatives"]]
                succeeded = False
                pending = next(
                    (item for item in state["attempts"] if item["step_id"] == step["step_id"] and item["status"] == "PREPARED"),
                    None,
                )
                if pending is not None:
                    capability = self.by_capability.get(pending["capability_id"])
                    if capability is None:
                        raise ExecutionError("CHECKPOINT_CAPABILITY_UNAVAILABLE", "pending capability is no longer in the exact catalog")
                    if not self._runtime_eligible(capability):
                        pending.update({"status": "FAILED", "ended_at": isoformat(self.clock()), "error_class": "CAPABILITY_NO_LONGER_ELIGIBLE"})
                        self._save(state)
                    else:
                        budget_failure = self._preflight_budget(state, capability)
                        if budget_failure:
                            state["state"] = "BLOCKED"
                            self._save(state)
                            return self._report(state, "BLOCKED", [budget_failure], ["obtain a plan within remaining limits"])
                        succeeded = self._invoke_attempt(state, step, pending, capability)
                        if self.store.cancellation_requested(self.plan):
                            state["state"] = "CANCELLED"
                            self._save(state)
                            return self._report(state, "CANCELLED", ["CANCELLATION_REQUESTED"], [])
                tried = {
                    item["capability_id"]
                    for item in state["attempts"]
                    if item["step_id"] == step["step_id"] and item["status"] != "PREPARED"
                }
                for capability_id in candidates:
                    if succeeded:
                        break
                    if capability_id in tried:
                        continue
                    if len(state["attempts"]) >= max_attempts:
                        break
                    capability = self.by_capability.get(capability_id)
                    if capability is None or not self._runtime_eligible(capability):
                        continue
                    budget_failure = self._preflight_budget(state, capability)
                    if budget_failure:
                        state["state"] = "BLOCKED"
                        self._save(state)
                        return self._report(state, "BLOCKED", [budget_failure], ["obtain a plan within remaining limits"])
                    attempt = self._new_attempt(step, capability_id, len(state["attempts"]) + 1, self.clock())
                    state["attempts"].append(attempt)
                    self._save(state)
                    if self._invoke_attempt(state, step, attempt, capability):
                        succeeded = True
                        break
                    if self.store.cancellation_requested(self.plan):
                        state["state"] = "CANCELLED"
                        self._save(state)
                        return self._report(state, "CANCELLED", ["CANCELLATION_REQUESTED"], [])
                if not succeeded:
                    state["state"] = "UNAVAILABLE"
                    self._save(state)
                    return self._report(state, "UNAVAILABLE", ["STEP_ALTERNATIVES_EXHAUSTED"], [f"provide new evidence or another capability for {step['step_id']}"])
                limit_failures = self._actual_limits(state)
                if limit_failures:
                    state["state"] = "BLOCKED"
                    self._save(state)
                    return self._report(state, "BLOCKED", limit_failures, ["review measured overrun before further execution"])
            validation = self._validation_status(state)
            if validation in {"FAILED", "INCONCLUSIVE", "UNAVAILABLE"}:
                status = "FAILED" if validation == "FAILED" else "MANUAL_REQUIRED"
                state["state"] = status
                self._save(state)
                return self._report(state, status, [f"VALIDATION_{validation}"], ["supply passing required validation evidence"])
            state["state"] = "COMPLETED"
            self._save(state)
            return self._report(state, "COMPLETED", ["EXECUTION_AND_VALIDATION_COMPLETE"], [])


def load_json(path: str, description: str) -> Any:
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ExecutionError("INPUT_UNREADABLE", f"{description} is unavailable or invalid") from exc


def list_items(raw: Any, key: str) -> list[Any]:
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict) and set(raw) == {key} and isinstance(raw[key], list):
        return raw[key]
    raise ExecutionError("INVALID_INPUT", f"input must be an array or contain only {key}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--request")
    parser.add_argument("--plan", required=True)
    parser.add_argument("--capabilities")
    parser.add_argument("--bindings")
    parser.add_argument("--handles")
    parser.add_argument("--approvals")
    parser.add_argument("--state-dir")
    parser.add_argument("--cancel", action="store_true", help="write a scoped cancellation marker and exit")
    args = parser.parse_args(argv)
    try:
        plan = load_json(args.plan, "execution plan")
        store = CheckpointStore(Path(args.state_dir) if args.state_dir else None)
        if args.cancel:
            validated_plan = validate_plan(plan)
            store.request_cancel(validated_plan, utc_now())
            print(json.dumps({"contract": CONTRACT, "plan_id": validated_plan["plan_id"], "status": "CANCELLED"}, sort_keys=True))
            return 0
        missing = [name for name in ("request", "capabilities", "bindings", "handles") if getattr(args, name) is None]
        if missing:
            raise ExecutionError("INPUT_REQUIRED", "execution requires request, capabilities, bindings, and handles")
        request = load_json(args.request, "work request")
        capabilities = list_items(load_json(args.capabilities, "capability catalog"), "capabilities")
        bindings = load_json(args.bindings, "adapter bindings")
        handles = load_json(args.handles, "handle map")
        approvals = load_json(args.approvals, "approval receipts") if args.approvals else None
        report = Executor(
            request,
            plan,
            capabilities,
            bindings,
            handles,
            store=store,
            approvals_raw=approvals,
        ).execute()
        print(json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False))
        return 0 if report["status"] == "COMPLETED" else 3
    except ExecutionError as exc:
        print(json.dumps({"contract": CONTRACT, "status": "BLOCKED", "error": {"class": exc.error_class, "code": exc.code, "message": str(exc)}}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

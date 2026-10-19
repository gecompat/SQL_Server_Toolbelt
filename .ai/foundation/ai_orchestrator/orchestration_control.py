"""Optional deterministic job control. Client effects and observations belong to the host."""

from __future__ import annotations

import json
import re
from copy import deepcopy
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from ai_orchestrator import (
    OrchestrationError, _dependencies, _inside_git, _shared_runtime, digest,
    empty_evidence, external_root, isoformat, parse_time, plan_or_execute, utc_now, validate_evidence,
)

CONTRACT = "foundation-orchestrator-control/v1"
STATES = {"READY", "RUNNING", "WAITING", "NEEDS_INPUT", "PAUSED", "COMPLETED", "CANCELLED"}
EVENTS = {"REGISTER", "STATUS", "HEARTBEAT", "EVENT", "PAUSE", "CANCEL", "RESUME", "ROTATE", "SOURCE_FAILED", "ACCEPT_EVIDENCE"}
CAPABILITIES = {"STATUS", "PRE_MODEL_CHECK", "START_SESSION", "RESUME_SESSION", "SUCCESSOR_SESSION", "NOTIFY", "RESEARCH"}
REF = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.:/@-]{0,159}$")
MAX_BYTES = 4 * 1024 * 1024


def fail(code: str) -> None:
    raise OrchestrationError(code, "control input or trusted state requires reconciliation")


def keys(value: Any, required: set[str], optional: set[str] = frozenset()) -> None:
    if not isinstance(value, dict) or not required <= set(value) or set(value) - required - optional:
        fail("INVALID_CONTROL_FIELDS")


def ref(value: Any, nullable: bool = False) -> None:
    if nullable and value is None:
        return
    if not isinstance(value, str) or not REF.fullmatch(value):
        fail("INVALID_CONTROL_REFERENCE")


def integer(value: Any, minimum: int = 0) -> None:
    if type(value) is not int or value < minimum:
        fail("INVALID_CONTROL_INTEGER")


def boolean(value: Any) -> None:
    if type(value) is not bool:
        fail("INVALID_CONTROL_BOOLEAN")


def timestamp(value: Any) -> datetime:
    if not isinstance(value, str) or not (value.endswith("Z") or re.search(r"[+-]\d\d:\d\d$", value)):
        fail("INVALID_CONTROL_TIME")
    return parse_time(value, "control time")


def external_file(value: Any) -> Path:
    if not isinstance(value, str) or not Path(value).is_absolute() or _inside_git(Path(value)):
        fail("CONTROL_FILE_NOT_EXTERNAL")
    return Path(value).resolve()


def read(path: Path) -> dict:
    def unique(pairs: list[tuple[str, Any]]) -> dict:
        result = {}
        for name, value in pairs:
            if name in result:
                fail("DUPLICATE_CONTROL_KEY")
            result[name] = value
        return result
    try:
        with path.open("rb") as stream:
            raw = stream.read(MAX_BYTES + 1)
        if len(raw) > MAX_BYTES:
            fail("CONTROL_DOCUMENT_TOO_LARGE")
        value = json.loads(raw.decode("utf-8"), object_pairs_hook=unique,
                           parse_constant=lambda _: fail("NONFINITE_CONTROL_NUMBER"))
        if not isinstance(value, dict):
            fail("INVALID_CONTROL_DOCUMENT")
        return value
    except (OSError, UnicodeError, ValueError, RecursionError) as exc:
        raise OrchestrationError("CONTROL_DOCUMENT_UNAVAILABLE", "external control document is unavailable") from exc


def configuration(path: Path) -> dict:
    value = read(external_file(str(path)))
    keys(value, {"schema_version", "contract", "job_id", "work_ref", "authorization_ref",
                 "completion_ref", "budget_ref", "bootstrap_ref", "state_root", "client"},
         {"autonomy", "max_dispatches", "heartbeat_seconds", "action_timeout_seconds", "budget_request_path",
          "start_request", "research_ref", "notification_target", "external_notifications_authorized"})
    if value["schema_version"] != 1 or type(value["schema_version"]) is not int or value["contract"] != CONTRACT:
        fail("INVALID_CONTROL_CONTRACT")
    for name in ("job_id", "work_ref", "authorization_ref", "completion_ref", "budget_ref", "bootstrap_ref"):
        ref(value[name])
    external_file(value["state_root"])
    value.setdefault("autonomy", False)
    value.setdefault("max_dispatches", None)
    value.setdefault("heartbeat_seconds", 1800)
    value.setdefault("action_timeout_seconds", 300)
    value.setdefault("budget_request_path", None)
    value.setdefault("start_request", None)
    value.setdefault("research_ref", None)
    value.setdefault("notification_target", "CLIENT")
    value.setdefault("external_notifications_authorized", False)
    boolean(value["autonomy"])
    boolean(value["external_notifications_authorized"])
    integer(value["heartbeat_seconds"], 1)
    integer(value["action_timeout_seconds"], 1)
    if value["action_timeout_seconds"] > 86400:
        fail("INVALID_ACTION_TIMEOUT")
    if value["max_dispatches"] is not None:
        integer(value["max_dispatches"], 1)
    if value["budget_request_path"] is not None:
        external_file(value["budget_request_path"])
    if value["autonomy"] and value["max_dispatches"] is None and value["budget_request_path"] is None:
        fail("FINITE_AUTONOMY_BOUND_REQUIRED")
    ref(value["research_ref"], True)
    ref(value["notification_target"])
    client = value["client"]
    keys(client, {"client_id", "source_ref", "valid_until", "capabilities", "observation_path"})
    ref(client["client_id"])
    ref(client["source_ref"])
    timestamp(client["valid_until"])
    external_file(client["observation_path"])
    caps = client["capabilities"]
    if not isinstance(caps, list) or any(not isinstance(item, str) or item not in CAPABILITIES for item in caps) or len(caps) != len(set(caps)):
        fail("INVALID_CLIENT_CAPABILITIES")
    return value


def observation(cfg: dict, at: datetime) -> dict:
    if timestamp(cfg["client"]["valid_until"]) <= at or "STATUS" not in cfg["client"]["capabilities"]:
        fail("CLIENT_STATUS_UNAVAILABLE")
    value = read(external_file(cfg["client"]["observation_path"]))
    keys(value, {"schema_version", "contract", "job_id", "client_id", "observed_at", "valid_until",
                 "generation", "owner_session_id", "execution", "work_remaining", "executable",
                 "checkpoint_ref", "completion_verified"},
         {"ack", "lifecycle_request", "handoff", "source_failure", "verification", "operator_resume", "models", "progress"})
    if type(value["schema_version"]) is not int or value["schema_version"] != 1 or value["contract"] != CONTRACT:
        fail("INVALID_CONTROL_CONTRACT")
    if value["job_id"] != cfg["job_id"] or value["client_id"] != cfg["client"]["client_id"]:
        fail("CLIENT_OBSERVATION_MISMATCH")
    if not timestamp(value["observed_at"]) <= at < timestamp(value["valid_until"]):
        fail("CLIENT_OBSERVATION_EXPIRED")
    integer(value["generation"])
    ref(value["owner_session_id"], True)
    ref(value["checkpoint_ref"], True)
    if value["execution"] not in {"IDLE", "RUNNING", "WAITING", "UNKNOWN"}:
        fail("INVALID_EXECUTION_STATUS")
    for name in ("work_remaining", "executable", "completion_verified"):
        boolean(value[name])
    boolean(value.get("operator_resume", False))
    if "progress" in value:
        keys(value["progress"], {"checkpoint_ref", "previous_checkpoint_ref", "progress_ref"})
        ref(value["progress"]["checkpoint_ref"], True)
        ref(value["progress"]["previous_checkpoint_ref"], True)
        ref(value["progress"]["progress_ref"])
    if value.get("models") is not None:
        if not isinstance(value["models"], list) or len(value["models"]) > 1000:
            fail("INVALID_CLIENT_MODELS")
        for model in value["models"]:
            keys(model, {"connection_id", "model_id"})
            ref(model["connection_id"])
            ref(model["model_id"])
    return value


def _planner() -> Any:
    import importlib.util
    here = Path(__file__).resolve().parent
    path = next((item for item in (here.parent / "ai-work" / "ai_work.py",
                                  here.parent / "ai_work" / "ai_work.py") if item.is_file()), None)
    if path is None:
        fail("SESSION_PLANNER_UNAVAILABLE")
    spec = importlib.util.spec_from_file_location("foundation_control_planner", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def accept_evidence(proof: dict, root: Path, at: datetime, io: Any) -> None:
    """A host verification binds the exact candidate, not an AI's confidence label."""
    keys(proof, {"candidate_path", "candidate_sha256", "verifier_ref", "producer_ref", "source_ref",
                 "units_ref", "model_mapping_ref", "verified"})
    for name in ("verifier_ref", "producer_ref", "source_ref", "units_ref", "model_mapping_ref"):
        ref(proof[name])
    boolean(proof["verified"])
    if not proof["verified"] or proof["verifier_ref"] == proof["producer_ref"]:
        fail("INDEPENDENT_SOURCE_VERIFICATION_REQUIRED")
    raw = read(external_file(proof["candidate_path"]))
    if type(raw.get("schema_version")) is not int:
        fail("INVALID_VERIFIED_EVIDENCE")
    if digest(raw) != proof["candidate_sha256"]:
        fail("VERIFIED_CANDIDATE_CHANGED")
    candidate = validate_evidence(raw, at)
    if (candidate != raw or not candidate["records"] and not candidate["aliases"]
            or timestamp(candidate["updated_at"]) > at):
        fail("INVALID_VERIFIED_EVIDENCE")
    router, _ = _dependencies(Path(__file__).resolve().parent)
    for row in candidate["records"]:
        if timestamp(row["observed_at"]) > at:
            fail("INVALID_VERIFIED_EVIDENCE")
        # Reuse the router's complete price/unit/resource checks, with unknown defaults.
        model = {"model_id": row["model_id"], "availability": "AVAILABLE", "assessment": "UNASSESSED",
                 "capabilities": [], "context_window": None, "quality_prior": {}, "quality_provenance": "UNKNOWN",
                 "supported_tiers": [], "reasoning_efforts": [], "resource_estimate": {},
                 "resource_provenance": "UNKNOWN", "pricing": None, **row["profile"]}
        router.validate_fragment({"schema_version": 2, "contract": "foundation-model-router/v2",
            "provider": row["connection_id"], "adapter": "verified-evidence/v1", "execution_boundary": "UNKNOWN",
            "generated_at": row["observed_at"], "valid_until": row["valid_until"], "pricing_epoch": proof["candidate_sha256"],
            "health": {"state": "UNKNOWN", "checked_at": row["observed_at"], "expires_at": row["valid_until"]},
            "provenance": {"source": row["source"]["locator"], "observed_at": row["observed_at"]},
            "models": {row["model_id"]: model}})
        router._resource_economics(model, {}, at)
    path = root / "model-runtime-evidence.json"
    with io.file_lock(root / "evidence.lock"):
        previous = validate_evidence(read(path), at) if path.is_file() else empty_evidence(at)
        merged = empty_evidence(at)
        for collection, identity in (("records", ("connection_id", "model_id")),
                                     ("aliases", ("connection_id", "requested_model", "actual_model"))):
            incoming = {}
            existing = {tuple(row[k] for k in identity): row for row in previous[collection]}
            for row in candidate[collection]:
                if timestamp(row["observed_at"]) > at:
                    fail("INVALID_VERIFIED_EVIDENCE")
                key = tuple(row[k] for k in identity)
                if key in incoming and incoming[key] != row:
                    fail("CONFLICTING_VERIFIED_EVIDENCE")
                if key in existing and timestamp(row["observed_at"]) < timestamp(existing[key]["observed_at"]):
                    fail("STALE_VERIFIED_EVIDENCE")
                incoming[key] = row
            existing.update(incoming)
            merged[collection] = list(existing.values())
        io.atomic_write(path, merged)


def control(raw: Any, *, control_config: Path | None, state_root: Path | None = None,
            config_path: Path | None = None, evidence_path: Path | None = None,
            evidence_sources_path: Path | None = None, at: datetime | None = None) -> dict:
    """Reserve decisions only. Trusted host snapshots acknowledge actual client effects."""
    keys(raw, {"schema_version", "contract", "job_id", "event"})
    if type(raw["schema_version"]) is not int or raw["schema_version"] != 1 or raw["contract"] != CONTRACT or not isinstance(raw["event"], str) or raw["event"] not in EVENTS:
        fail("INVALID_CONTROL_REQUEST")
    ref(raw["job_id"])
    if control_config is None:
        return {"schema_version": 1, "contract": CONTRACT, "status": "CONFIGURATION_REQUIRED", "state": None, "actions": [],
                "reason_code": "CONTROL_CONFIGURATION_REQUIRED", "model_calls": 0}
    cfg = configuration(control_config)
    if raw["job_id"] != cfg["job_id"]:
        fail("CONTROL_JOB_MISMATCH")
    observed = at or utc_now()
    root = external_root(Path(cfg["state_root"]))
    if state_root is not None and external_root(state_root) != root:
        fail("CONTROL_STATE_ROOT_MISMATCH")
    state_path = root / "control" / "state.json"
    io = _shared_runtime("state_io")
    with io.file_lock(root / "control" / "state.lock"):
        store = read(state_path) if state_path.is_file() else {"jobs": {}, "budgets": {}}
        keys(store, {"jobs", "budgets"}, {"integrity_sha256"})
        if state_path.is_file():
            expected = store.pop("integrity_sha256", None)
            if expected != digest(store):
                fail("CONTROL_STATE_CORRUPT")
        before = digest(store)
        jobs, budgets = store["jobs"], store["budgets"]
        if not isinstance(jobs, dict) or not isinstance(budgets, dict):
            fail("CONTROL_STATE_CORRUPT")
        job = jobs.get(cfg["job_id"])
        if job is None:
            if raw["event"] != "REGISTER":
                fail("CONTROL_JOB_NOT_REGISTERED")
            job = {"config_hash": digest(cfg), "state": "READY", "reason": "REGISTERED",
                   "owner": None, "generation": 0, "checkpoint": None, "pending": {},
                   "last_resume_key": None, "last_tick": None, "sequence": 0,
                   "notifications": [], "research_keys": [], "quiescent": False, "last_lifecycle_key": None,
                   "resume_checkpoint": None, "progress_ref": None}
            jobs[cfg["job_id"]] = job
        if job["config_hash"] != digest(cfg) or job["state"] not in STATES:
            fail("CONTROL_CONFIGURATION_CHANGED")
        ledger = budgets.setdefault(cfg["budget_ref"], {"limit": cfg["max_dispatches"], "used": 0, "reservations": {}})
        if ledger["limit"] != cfg["max_dispatches"]:
            fail("SHARED_BUDGET_LIMIT_MISMATCH")
        actions: list[dict] = []
        rejected = None
        caps = cfg["client"]["capabilities"]

        def emit(kind: str, **fields: Any) -> dict:
            job["sequence"] += 1
            action = {"action_id": digest([cfg["job_id"], job["generation"], job["sequence"], kind]),
                      "kind": kind, "generation": job["generation"], "issued_at": isoformat(observed),
                      "valid_until": isoformat(min(timestamp(cfg["client"]["valid_until"]),
                          observed + timedelta(seconds=cfg["action_timeout_seconds"]))), **fields}
            job["pending"][action["action_id"]] = action
            actions.append(deepcopy(action))
            return action

        def notify(reason: str) -> None:
            key = digest([job["state"], reason, job["checkpoint"]])
            if key in job["notifications"]:
                return
            if "NOTIFY" in caps and timestamp(cfg["client"]["valid_until"]) > observed and (cfg["notification_target"] == "CLIENT" or cfg["external_notifications_authorized"]):
                message = (f"Work {cfg['work_ref']} completed." if reason == "COMPLETED"
                           else f"Work {cfg['work_ref']} needs attention: {reason}.")
                emit("NOTIFY", target_ref=cfg["notification_target"], template=reason, work_ref=cfg["work_ref"], message=message)
                job["notifications"] = (job["notifications"] + [key])[-32:]

        def manual(reason: str) -> None:
            job["state"], job["reason"] = "NEEDS_INPUT", reason
            notify(reason)

        def reserve(kind: str, **fields: Any) -> dict | None:
            if ledger["limit"] is not None and ledger["used"] >= ledger["limit"]:
                manual("DISPATCH_BOUND_REACHED")
                return None
            cost = 0
            if cfg["budget_request_path"]:
                budget = read(external_file(cfg["budget_request_path"]))
                if budget.get("wave_id") != cfg["budget_ref"] or budget.get("hard_limit") is None:
                    manual("BUDGET_BINDING_UNVERIFIED")
                    return None
                _shared_runtime("processing_efficiency").budget_decision(budget)
                entries = {entry["invocation_id"]: entry for entry in budget["entries"]}
                for action_id, pending in ledger["reservations"].items():
                    if action_id not in entries:
                        budget["entries"].append({"invocation_id": action_id, "actor": "ORCHESTRATOR",
                                                  "consumed": None if pending["settlement_required"] else 0,
                                                  "reserved": pending["amount"],
                                                  "provenance": "UNKNOWN" if pending["settlement_required"] else "MEASURED"})
                ledger["reservations"] = {key: value for key, value in ledger["reservations"].items() if key not in entries}
                decision = _shared_runtime("processing_efficiency").budget_decision(budget)
                if decision["action"] != "ALLOW_NEW_WORK":
                    manual(decision["action"])
                    return None
                cost = budget["next_reservation"]
            action = emit(kind, **fields)
            ledger["used"] += 1
            if cfg["budget_request_path"]:
                ledger["reservations"][action["action_id"]] = {"amount": cost, "settlement_required": False}
            return action

        def route_start(successor: bool = False) -> None:
            if "START_SESSION" not in caps or (successor and "SUCCESSOR_SESSION" not in caps) or cfg["start_request"] is None or not snapshot.get("models"):
                manual("START_MODEL_SELECTION_REQUIRED")
                return
            start = deepcopy(cfg["start_request"])
            start["router_request"].setdefault("tier", "BALANCED")
            eligible = {(m["connection_id"], m["model_id"]) for m in snapshot["models"]}
            report = plan_or_execute(start, execute=False, config_path=config_path, state_root=root,
                                     evidence_path=evidence_path,
                                     eligible_models=eligible, at=observed)
            if report["status"] != "PLANNED":
                manual("START_MODEL_EVIDENCE_REQUIRED")
                return
            next_generation = job["generation"] + 1
            action = reserve("START_SESSION", next_generation=next_generation, route=report["route"],
                             work_ref=cfg["work_ref"], bootstrap_ref=cfg["bootstrap_ref"],
                             budget_ref=cfg["budget_ref"], successor=successor,
                             **({"handoff_ref": job["handoff_ref"]} if successor else {}))
            if action:
                job["state"], job["reason"] = "RUNNING", "START_RESERVED"

        def resume_or_start() -> None:
            if job["owner"] is None:
                route_start()
            elif "RESUME_SESSION" not in caps:
                manual("MANUAL_CONTINUATION_REQUIRED")
            else:
                key = digest([job["generation"], job["checkpoint"]])
                if job["last_resume_key"] != key:
                    if job["last_resume_key"] is not None:
                        progress = snapshot.get("progress")
                        if (progress is None or progress["checkpoint_ref"] != job["checkpoint"]
                                or progress["previous_checkpoint_ref"] != job["resume_checkpoint"]
                                or progress["progress_ref"] == job["progress_ref"]):
                            fail("PROGRESS_EVIDENCE_REQUIRED")
                    action = reserve("RESUME_SESSION", message="HEARTBEAT", owner_session_id=job["owner"],
                                     work_ref=cfg["work_ref"], budget_ref=cfg["budget_ref"])
                    if action:
                        job["last_resume_key"] = key
                        job["resume_checkpoint"] = job["checkpoint"]
                        job["progress_ref"] = snapshot.get("progress", {}).get("progress_ref")
                        job["state"], job["reason"] = "RUNNING", "CONTINUATION_RESERVED"
                else:
                    job["state"], job["reason"] = "READY", "UNCHANGED_CHECKPOINT"

        def acknowledge(snapshot: dict) -> None:
            ack = snapshot.get("ack")
            if ack is None:
                return
            keys(ack, {"action_id", "outcome"}, {"session_id", "receipt", "checkpoint_ref", "handoff_ref", "predecessor_retired"})
            action = job["pending"].get(ack["action_id"])
            if action is None:
                return
            if ack["outcome"] not in {"SUCCEEDED", "FAILED", "UNKNOWN", "NOT_STARTED"}:
                fail("INVALID_ACTION_OUTCOME")
            if action["kind"] == "NOTIFY":
                job["pending"].pop(ack["action_id"])
                return
            if ack["action_id"] in ledger["reservations"]:
                ledger["reservations"][ack["action_id"]]["settlement_required"] = True
            if ack["outcome"] == "NOT_STARTED" and snapshot.get("operator_resume"):
                job["pending"].pop(ack["action_id"])
                return
            if ack["outcome"] != "SUCCEEDED":
                manual("AMBIGUOUS_ACTION" if ack["outcome"] == "UNKNOWN" else "CLIENT_ACTION_FAILED")
                return
            if action["kind"] == "START_SESSION":
                receipt = ack.get("receipt", {})
                keys(receipt, {"requested_model", "actual_model", "issuer", "evidence_kind"})
                if (receipt["issuer"] != cfg["client"]["client_id"] or receipt["evidence_kind"] not in {"HOST_EXECUTION", "HOST_RESPONSE_METADATA"}
                        or receipt["requested_model"] != action["route"]["model"] or receipt["actual_model"] != receipt["requested_model"]):
                    manual("ACTUAL_MODEL_NOT_ATTESTED")
                    return
                ref(ack.get("session_id"))
                if snapshot["owner_session_id"] != ack["session_id"] or snapshot["generation"] != action["next_generation"]:
                    fail("SUCCESSOR_ACK_MISMATCH")
                job["owner"], job["generation"] = ack["session_id"], action["next_generation"]
                job["last_resume_key"] = digest([job["generation"], snapshot["checkpoint_ref"]])
                job["resume_checkpoint"] = snapshot["checkpoint_ref"]
                job["quiescent"] = False
            elif action["kind"] == "PREPARE_HANDOFF":
                ref(ack.get("checkpoint_ref"))
                ref(ack.get("handoff_ref"))
                if ack.get("predecessor_retired") is not True or snapshot["execution"] != "IDLE" or snapshot["checkpoint_ref"] != ack["checkpoint_ref"]:
                    manual("PREDECESSOR_NOT_QUIESCENT")
                    return
                handoff = snapshot.get("handoff")
                keys(handoff, {"schema_version", "contract", "handoff_id", "predecessor_session_id",
                               "successor_role", "checkpoint_id", "created_at", "durable_state_refs",
                               "changed_state_refs", "current_work_refs", "unresolved_refs", "delta_handle"})
                for name in ("durable_state_refs", "changed_state_refs", "current_work_refs", "unresolved_refs"):
                    if not isinstance(handoff[name], list) or len(handoff[name]) > 1000:
                        fail("INVALID_HANDOFF_REFERENCES")
                    for item in handoff[name]:
                        ref(item)
                    if len(set(handoff[name])) != len(handoff[name]):
                        fail("INVALID_HANDOFF_REFERENCES")
                preserved = {cfg["authorization_ref"], cfg["budget_ref"], cfg["bootstrap_ref"], cfg["completion_ref"]}
                if (handoff["schema_version"] != 1 or handoff["contract"] != "foundation-session-handoff/v1"
                        or handoff["handoff_id"] != ack["handoff_ref"] or handoff["checkpoint_id"] != ack["checkpoint_ref"]
                        or handoff["predecessor_session_id"] != job["owner"] or handoff["successor_role"] != "ORCHESTRATOR"
                        or cfg["work_ref"] not in handoff["current_work_refs"] or not preserved <= set(handoff["durable_state_refs"])
                        or timestamp(handoff["created_at"]) > observed):
                    fail("HANDOFF_SCOPE_MISMATCH")
                if handoff["delta_handle"] is not None:
                    keys(handoff["delta_handle"], {"handle_id", "kind", "content_sha256"})
                    ref(handoff["delta_handle"]["handle_id"])
                    if handoff["delta_handle"]["kind"] not in {"FILE", "EPHEMERAL", "OPAQUE"}:
                        fail("INVALID_HANDOFF_HANDLE")
                    sha = handoff["delta_handle"]["content_sha256"]
                    if sha is not None and (not isinstance(sha, str) or not re.fullmatch(r"sha256:[0-9a-f]{64}", sha)):
                        fail("INVALID_HANDOFF_HANDLE")
                job["checkpoint"], job["quiescent"] = ack["checkpoint_ref"], True
                job["handoff_ref"] = ack["handoff_ref"]
            job["pending"].pop(ack["action_id"])

        event = raw["event"]
        if event == "STATUS":
            if "STATUS" in caps and timestamp(cfg["client"]["valid_until"]) > observed and not job["pending"] and job["state"] not in {"PAUSED", "COMPLETED", "CANCELLED"}:
                emit("CHECK_STATUS", work_ref=cfg["work_ref"])
        elif event in {"PAUSE", "CANCEL"}:
            job["state"] = "PAUSED" if event == "PAUSE" else "CANCELLED"
            job["reason"] = event
        elif job["state"] in {"COMPLETED", "CANCELLED"}:
            pass
        elif event == "HEARTBEAT" and (not cfg["autonomy"] or "PRE_MODEL_CHECK" not in caps):
            job["reason"] = "PERIODIC_WAKE_DISABLED"
        elif event == "HEARTBEAT" and job["state"] in {"PAUSED", "NEEDS_INPUT"}:
            pass
        elif event == "HEARTBEAT" and job["last_tick"] and observed < timestamp(job["last_tick"]) + timedelta(seconds=cfg["heartbeat_seconds"]):
            pass
        else:
            try:
                if event == "REGISTER" and cfg["autonomy"] and cfg["max_dispatches"] is None:
                    budget = read(external_file(cfg["budget_request_path"]))
                    if budget.get("wave_id") != cfg["budget_ref"] or budget.get("hard_limit") is None:
                        fail("BUDGET_BINDING_UNVERIFIED")
                    decision = _shared_runtime("processing_efficiency").budget_decision(budget)
                    if decision["action"] != "ALLOW_NEW_WORK":
                        fail(decision["action"])
                snapshot = observation(cfg, observed)
                pending_start = next((a for a in job["pending"].values() if a["kind"] == "START_SESSION"), None)
                generations = {job["generation"]}
                if pending_start:
                    generations.add(pending_start["next_generation"])
                adopting = event == "REGISTER" and job["owner"] is None and not job["pending"]
                if not adopting and (snapshot["generation"] not in generations or (snapshot["generation"] == job["generation"] and job["owner"] is not None and snapshot["owner_session_id"] != job["owner"])):
                    fail("STALE_OWNER_OBSERVATION")
                acknowledge(snapshot)
                if job["quiescent"] and snapshot["generation"] == job["generation"] and snapshot["execution"] != "IDLE":
                    fail("PREDECESSOR_REACTIVATED")
                if job["state"] not in {"PAUSED", "NEEDS_INPUT"}:
                    if event == "REGISTER" and job["owner"] is None and snapshot["owner_session_id"]:
                        job["owner"], job["generation"] = snapshot["owner_session_id"], snapshot["generation"]
                    job["checkpoint"] = snapshot["checkpoint_ref"]
                if event == "RESUME":
                    if not snapshot.get("operator_resume") or any(a["kind"] != "NOTIFY" for a in job["pending"].values()):
                        fail("OPERATOR_RECONCILIATION_REQUIRED")
                    job["state"], job["reason"] = "READY", "OPERATOR_RESUMED"
                    job["checkpoint"] = snapshot["checkpoint_ref"]
                if event == "HEARTBEAT":
                    job["last_tick"] = isoformat(observed)
                active = any(a["kind"] != "NOTIFY" for a in job["pending"].values())
                if any(a["kind"] != "NOTIFY" and timestamp(a["valid_until"]) <= observed for a in job["pending"].values()):
                    manual("ACTION_ACK_TIMEOUT")
                if job["state"] == "PAUSED" or active:
                    pass
                elif snapshot["completion_verified"] and not snapshot["work_remaining"] and snapshot["execution"] == "IDLE":
                    job["state"], job["reason"] = "COMPLETED", "COMPLETED"
                    notify("COMPLETED")
                elif job["state"] == "NEEDS_INPUT" and event not in {"SOURCE_FAILED", "ACCEPT_EVIDENCE"}:
                    pass
                elif snapshot["execution"] == "UNKNOWN":
                    manual("EXECUTION_UNKNOWN")
                elif snapshot["execution"] in {"RUNNING", "WAITING"}:
                    job["state"] = snapshot["execution"]
                    job["reason"] = "CLIENT_ACTIVE" if snapshot["execution"] == "RUNNING" else "WAITING"
                elif not snapshot["work_remaining"] or not snapshot["executable"]:
                    manual("COMPLETION_OR_NEXT_STEP_REQUIRED")
                elif not cfg["autonomy"]:
                    job["state"], job["reason"] = "READY", "AUTONOMY_DISABLED"
                elif event == "SOURCE_FAILED":
                    failure = snapshot.get("source_failure")
                    keys(failure, {"source_id", "failure_ref"})
                    ref(failure["source_id"])
                    ref(failure["failure_ref"])
                    key = digest(failure)
                    if key not in job["research_keys"]:
                        if cfg["research_ref"] is None or "RESEARCH" not in caps:
                            manual("SOURCE_RESEARCH_UNAVAILABLE")
                        elif reserve("RESEARCH", request_ref=cfg["research_ref"], failure_ref=failure["failure_ref"]):
                            job["research_keys"].append(key)
                elif event == "ACCEPT_EVIDENCE":
                    accept_evidence(snapshot.get("verification"), root, observed, io)
                    job["reason"] = "VERIFIED_EVIDENCE_ACCEPTED"
                elif event == "ROTATE" or snapshot.get("lifecycle_request") or job["quiescent"]:
                    lifecycle = snapshot.get("lifecycle_request")
                    if job["quiescent"]:
                        route_start(True)
                    elif lifecycle is None:
                        manual("LIFECYCLE_METADATA_REQUIRED")
                    else:
                        if lifecycle["session_id"] != job["owner"]:
                            fail("LIFECYCLE_OWNER_MISMATCH")
                        decision = _planner().session_lifecycle(lifecycle)
                        if decision["action"] in {"ROTATE_REQUIRED", "ROTATE_AT_BOUNDARY"}:
                            if "SUCCESSOR_SESSION" not in caps or lifecycle["successor_session_capability"] != "AUTOMATIC":
                                manual("MANUAL_SUCCESSOR_REQUIRED")
                            else:
                                emit("PREPARE_HANDOFF", work_ref=cfg["work_ref"], authorization_ref=cfg["authorization_ref"],
                                     completion_ref=cfg["completion_ref"], budget_ref=cfg["budget_ref"], bootstrap_ref=cfg["bootstrap_ref"])
                                job["state"], job["reason"] = "RUNNING", "HANDOFF_RESERVED"
                        elif decision["action"] == "CHECKPOINT":
                            key = digest(lifecycle)
                            if job["last_lifecycle_key"] != key:
                                emit("CHECKPOINT", work_ref=cfg["work_ref"])
                                job["last_lifecycle_key"] = key
                        else:
                            resume_or_start()
                else:
                    resume_or_start()
            except (RuntimeError, ValueError, KeyError, TypeError) as exc:
                reason = getattr(exc, "code", "CLIENT_CONTROL_UNAVAILABLE")
                if reason == "STALE_OWNER_OBSERVATION":
                    rejected = reason
                else:
                    manual(reason)
        if digest(store) != before:
            if len(json.dumps(store)) > MAX_BYTES:
                fail("CONTROL_STATE_TOO_LARGE")
            store["integrity_sha256"] = digest(store)
            io.atomic_write(state_path, store)
        return {"schema_version": 1, "contract": CONTRACT, "job_id": cfg["job_id"], "status": "REJECTED" if rejected else "MANUAL_REQUIRED" if job["state"] == "NEEDS_INPUT" else "OK",
                "state": job["state"], "reason_code": rejected or job["reason"], "generation": job["generation"],
                "owner_session_id": job["owner"], "actions": actions, "pending_action_ids": list(job["pending"]),
                "budget_ref": cfg["budget_ref"], "controller_dispatches": ledger["used"],
                "model_calls": 0, "provider_limit_enforced": False}

#!/usr/bin/env python3
"""Offline simulated host roundtrip. No model, scheduler or real client is invoked."""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path


def main() -> int:
    module = Path(__file__).with_name("ai_orchestrator.py")
    now = datetime.now(timezone.utc)
    with tempfile.TemporaryDirectory(prefix="foundation-control-example-") as temporary:
        root = Path(temporary)
        config = root / "config.json"
        observation = root / "observation.json"
        request = root / "event.json"
        value = {"schema_version": 1, "contract": "foundation-orchestrator-control/v1", "job_id": "example-job",
                 "work_ref": "example-work", "authorization_ref": "example-scope", "completion_ref": "example-acceptance",
                 "budget_ref": "example-bound", "bootstrap_ref": "current-project-rules", "autonomy": True,
                 "state_root": str(root / "state"),
                 "max_dispatches": 2, "client": {"client_id": "ExampleClient", "source_ref": "synthetic-host",
                 "valid_until": (now + timedelta(days=1)).isoformat(),
                 "capabilities": ["STATUS", "PRE_MODEL_CHECK", "RESUME_SESSION", "NOTIFY"], "observation_path": str(observation)}}
        config.write_text(json.dumps(value), encoding="utf-8")
        snapshot = {"schema_version": 1, "contract": value["contract"], "job_id": value["job_id"], "client_id": "ExampleClient",
                    "observed_at": now.isoformat(), "valid_until": (now + timedelta(minutes=10)).isoformat(),
                    "generation": 0, "owner_session_id": "manually-selected-chat", "execution": "RUNNING",
                    "work_remaining": True, "executable": True, "checkpoint_ref": "checkpoint-1", "completion_verified": False}

        def call(event: str) -> dict:
            observation.write_text(json.dumps(snapshot), encoding="utf-8")
            request.write_text(json.dumps({"schema_version": 1, "contract": value["contract"],
                                          "job_id": value["job_id"], "event": event}), encoding="utf-8")
            result = subprocess.run([sys.executable, str(module), "--control-config", str(config), "--state-root",
                                     str(root / "state"), "control", str(request)], capture_output=True, text=True, check=True)
            report = json.loads(result.stdout)
            print(json.dumps({"event": event, "state": report["state"],
                              "actions": [a["kind"] for a in report["actions"]], "model_calls": report["model_calls"]}))
            return report

        call("REGISTER")
        snapshot["execution"] = "IDLE"
        first = call("HEARTBEAT")
        assert len(first["actions"]) == 1 and first["actions"][0]["message"] == "HEARTBEAT"
        assert call("HEARTBEAT")["actions"] == []
        # A real host would re-check the grant, deduplicate its ID, deliver, then acknowledge.
        snapshot["ack"] = {"action_id": first["actions"][0]["action_id"], "outcome": "SUCCEEDED"}
        snapshot.update(work_remaining=False, executable=False, completion_verified=True)
        completed = call("EVENT")
        assert completed["state"] == "COMPLETED" and completed["actions"][0]["kind"] == "NOTIFY"
        assert call("HEARTBEAT")["actions"] == []
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

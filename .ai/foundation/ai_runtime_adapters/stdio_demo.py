#!/usr/bin/env python3
"""Explicitly configured offline demonstration; never contacts or attests an AI model."""
from __future__ import annotations

from datetime import timedelta
from pathlib import Path
from typing import Any

from adapter_protocol import serve
from reference_adapters import atomic_write, canonical_json, digest_bytes, isoformat, now


class DemoAdapter:
    def probe(self, arguments: dict[str, Any]) -> dict[str, Any]:
        return {"health": {"state": "HEALTHY"}}

    def catalog(self, arguments: dict[str, Any]) -> dict[str, Any]:
        observed = now()
        timestamp = isoformat(observed)
        expiry = isoformat(observed + timedelta(seconds=300))
        return {"fragments": [{"schema_version": 2, "contract": "foundation-model-router/v2",
            "provider": "Example provider", "adapter": "offline-demo/v1", "execution_boundary": "HOST",
            "generated_at": timestamp, "valid_until": expiry, "pricing_epoch": "unknown",
            "health": {"state": "HEALTHY", "checked_at": timestamp, "expires_at": expiry},
            "provenance": {"source": "offline-synthetic-demo", "observed_at": timestamp},
            "models": {"synthetic-demo": {"model_id": "synthetic-demo", "availability": "AVAILABLE",
                "assessment": "UNASSESSED", "capabilities": ["text"], "context_window": None,
                "quality_prior": {"*": 0.5}, "quality_provenance": "UNKNOWN", "supported_tiers": ["ECONOMICAL"],
                "reasoning_efforts": ["low"], "resource_estimate": {}, "resource_provenance": "UNKNOWN", "pricing": None}}
        }]}

    def invoke(self, arguments: dict[str, Any]) -> dict[str, Any]:
        # The configured bridge performs permission/root checks. This demo is not a sandbox.
        body = canonical_json({"demo": "fixed synthetic output; no AI model invoked"}) + b"\n"
        atomic_write(Path(arguments["output_path"]), body)
        return {"status": "COMPLETED", "operation_id": arguments["operation_id"],
            "requested_model": arguments["model"], "actual_model": None,
            "output_sha256": digest_bytes(body), "output_bytes": len(body)}


if __name__ == "__main__":
    raise SystemExit(serve(DemoAdapter()))

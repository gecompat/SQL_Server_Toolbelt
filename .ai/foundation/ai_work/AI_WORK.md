# AI work planner capability

Status: OPTIONAL REFERENCE CAPABILITY

`ai_work.py` is a dependency-free reference planner for `foundation-ai-work/v1`. It validates a content-free `WorkRequest` and expiring `CapabilityDescriptor` catalog, filters hard privacy/authority/health/resource limits, prefers an adequate deterministic tool, and emits an `ExecutionPlan`. It never invokes a tool or model, reads a payload, persists runtime state, sends network traffic, provisions software, or expands authority.

Install it only when a Python reference client is useful:

```text
python tools/install_foundation.py TARGET --capabilities ai-work --apply
```

Another implementation language is equally valid. Foundation policy and schemas remain functional without Python or this capability.

## Plan and gap report

```text
python .ai/foundation/ai_work/ai_work.py plan --request work-request.json --capabilities capabilities.json
python .ai/foundation/ai_work/ai_work.py gap --request work-request.json --capabilities capabilities.json
```

The catalog may be a JSON array or `{ "capabilities": [...] }`. Use `--at` for deterministic replay. Health and plan expiry are enforced; an expired descriptor is excluded without invalidating other entries.

The planner returns `EXECUTABLE`, `MANUAL_REQUIRED`, `UNAVAILABLE`, or `BLOCKED`. A plan marked `MANUAL_REQUIRED` can contain a proposed step but cannot execute until its grouped approval point is satisfied. A gap report remains stdout/local data; the planner never creates a repository issue or work item.

## Payload separation

Input and output fields are handles only. The planner does not dereference them. Keep prompts, retrieved content, responses, credentials, endpoint configuration, live inventories, and reports outside version control unless the target project explicitly authorizes a narrower retention rule.

## Runtime evidence boundary

The included examples contain only synthetic deterministic capabilities. They prove contract mechanics, not the presence, trust boundary, quality, cost, or fitness of any installed runtime. Provider adapters, execution, provisioning, and client configuration are separate optional layers.

Capability descriptors may optionally declare `execution.idempotency` and `execution.resume`. Omitting that object preserves the original v1 representation and is treated as no idempotency attestation plus restart semantics. Work requests may optionally bound `limits.max_attempts`. These fields do not turn the planner into an executor.

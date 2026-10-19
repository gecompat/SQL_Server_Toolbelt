# Optional AI Orchestrator

Status: OPTIONAL REFERENCE CAPABILITY

This capability joins live runtime discovery, router v2, content-handle invocation, deterministic validation, fallback, and a content-free report. It is optional: Foundation rules, installation, validation, and manual work remain valid without Python, this capability, MCP, a runtime, network, credentials, evidence, or any model.

The control contract is `foundation-ai-orchestration/v1`. Prompts and generated answers stay in absolute input/output handles and never enter the orchestration report. The runtime connection store and all orchestration state remain outside Git.

Optional job control uses the separate `foundation-orchestrator-control/v1` [schema](../schemas/orchestrator-control.schema.json). It connects startup, continuation, session handoff and fixed notifications without invoking a model. Normative requirements are in the installed `AI_WORK_ORCHESTRATION_POLICY.md` (source: `Documentation/Standards/AI_WORK_ORCHESTRATION_POLICY.md`); this guide describes the reference implementation.

Provider names are data. The shared runtime store supports Ollama HTTP, OpenAI-compatible HTTP and explicit JSONL Stdio programs; no provider SDK/account is required by this facade. Stdio metadata is unattested by default unless the target trusts the reviewed adapter's observed backend identity, and missing identity still requires manual handling. Protocol failures, child-reported invocation errors and timeouts are ambiguous; checkpoints prevent automatic retry/fallback until reconciled. A local wrapper process does not establish a local model boundary.

## Install and configure

Select the facade explicitly during Foundation installation:

```text
python tools/install_foundation.py TARGET --capabilities ai-orchestrator --apply
```

The manifest also selects its `ai-work`, `ai-runtime-adapters`, and `model-router` dependencies. Installation supplies only contracts and reference code. It does not create a runtime connection, enable MCP, load credentials, authorize remote data, select a model, or grant spend/execution authority.

Configure runtime connections with the separately installed question/answer assistant, or provide an existing external configuration file:

```text
python TARGET/.ai/foundation/ai_runtime_adapters/runtime_configuration.py configure
```

An absent configuration and absent model evidence are valid startup states. Planning then returns a truthful manual/unavailable result and the MCP status remains callable. The default orchestration state directory is `%USERPROFILE%/.ai-repository-foundation/ai-orchestrator` on Windows, `~/Library/Application Support/AIRepositoryFoundation/ai-orchestrator` on macOS, and `$XDG_STATE_HOME/ai-repository-foundation/ai-orchestrator` (or `~/.local/state/...`) on Linux. `AI_ORCHESTRATOR_HOME` or `--state-root` may select another absolute directory outside every Git worktree.

## Evidence before automatic routing

Runtime catalogs prove availability only. They do not prove quality, context size, resource use, price, or model aliases. `model-runtime-evidence.json` may overlay those fields only when a record is fresh and has a locator plus content hash. A requested/actual model mismatch is accepted only with fresh `PROVIDER_DOCUMENTATION` or `PROVIDER_SIGNED_METADATA`; a successful response by itself never creates an alias.

Optional evidence sources use `foundation-model-evidence-sources/v1`. Each source is an exact argv array executed without a shell, receives only allowlisted environment variables, and returns the strict evidence contract on stdout. Successful evidence becomes last-known-good external state. Every attempt, including a failed one, is rate-limited for at least 86,400 seconds. A source may internally perform governed research or use an AI service, but its output still requires explicit provenance and expiry. No scheduler is required: clients can call `refresh-evidence` before planning; fresh state is reused offline.

## Commands

```text
python .ai/foundation/ai_orchestrator/ai_orchestrator.py [--config ABSOLUTE_RUNTIME_CONFIG] [--state-root ABSOLUTE_EXTERNAL_DIR] plan REQUEST.json
python .ai/foundation/ai_orchestrator/ai_orchestrator.py [--config ...] [--state-root ...] execute REQUEST.json
python .ai/foundation/ai_orchestrator/ai_orchestrator.py [--state-root ...] refresh-evidence SOURCES.json
python .ai/foundation/ai_orchestrator/ai_orchestrator.py --control-config ABSOLUTE_HOST_CONFIG --state-root ABSOLUTE_EXTERNAL_DIR control EVENT.json
python .ai/foundation/ai_orchestrator/orchestrator_mcp.py [--config ...] [--state-root ...] [--evidence-sources ...]
```

`LOCAL` never invokes a model and returns `DETERMINISTIC_TOOL_REQUIRED`. Missing or insufficient evidence returns `MANUAL_REQUIRED` with a manual-handoff action. Catalog and invocation failures are isolated per connection and per fallback. `remote_authorized` is passed through but never adds permission beyond the selected connection's own data-class and remote-model policy.

Validation modes are `NONE`, `OUTPUT_NONEMPTY`, `JSON_DOCUMENT`, and `MANUAL_REVIEW`. Structural checks are deterministic; semantic correctness is never fabricated. A retry occurs only through a different route already present in the router's bounded fallback chain.

Before invocation the reference writes a content-free external checkpoint bound to the complete request and input hash. A terminal identical run returns its prior report without invoking again. An `IN_PROGRESS` restart or timeout/protocol ambiguity requires manual provider reconciliation; only a definite pre-invocation availability/permission failure or deterministic validation failure may continue to a different bounded fallback.

## Host control configuration

MCP exposes `orchestration_control` with the same request as CLI. Select `--control-config ABSOLUTE_HOST_CONFIG` at server startup. Without configuration it returns `CONFIGURATION_REQUIRED`. The controller does not install a scheduler or implement any vendor's chat API.

The external configuration binds `job_id`, `work_ref`, `authorization_ref`, `completion_ref`, `budget_ref` and `bootstrap_ref` to reviewed project artifacts and selects one absolute external `state_root`. Caller overrides must match that root; changing directories cannot reset the job's grant history. All clients sharing a budget must use this same protected state authority. `autonomy` defaults to false. When enabled, configure `max_dispatches` or an external `budget_request_path` containing a valid `foundation-processing-budget/v1` hard budget with matching `wave_id`. Both may be used. `max_dispatches` counts startup, continuation and research grants across jobs sharing that budget and state authority. It does not measure money, tokens, subscription charges or descendant work. A measured budget needs settled actual entries under action IDs before another grant; unknown post-call consumption blocks a required hard budget. Targets enforce the full work/descendant envelope themselves.

`client` identifies a trusted host, capability `source_ref`, expiry, capability names and an absolute `observation_path` outside every Git tree. These files must be protected from model writes by the host. Merely putting them outside Git provides no authentication or sandbox. Do not expose them as model-writable content handles. Capability names are `STATUS`, `PRE_MODEL_CHECK`, `START_SESSION`, `RESUME_SESSION`, `SUCCESSOR_SESSION`, `NOTIFY`, `RESEARCH`; omit unsupported ones. A capability source must actually establish the corresponding operation, rather than merely advertise a product name.

The host writes fresh, bounded snapshots with job/client identity, owner session/generation, checkpoint, `IDLE`/`RUNNING`/`WAITING`/`UNKNOWN` execution status, remaining-work/executable flags and verified completion. It may supply the existing lifecycle request and handoff, available connection/model pairs, acknowledgments or independent evidence verification.

Further continuation needs a `progress` observation binding `previous_checkpoint_ref`, `checkpoint_ref` and a new `progress_ref` to an actually verified change in durable work. A renamed checkpoint without progress is insufficient. A handoff acknowledgment must explicitly attest `predecessor_retired: true`; an idle chat alone is not retirement.

Public control requests contain exactly:

```json
{"schema_version":1,"contract":"foundation-orchestrator-control/v1","job_id":"example-job","event":"HEARTBEAT"}
```

Events are `REGISTER`, `STATUS`, `HEARTBEAT`, `EVENT`, `PAUSE`, `CANCEL`, `RESUME`, `ROTATE`, `SOURCE_FAILED`, `ACCEPT_EVIDENCE`. `STATUS` requests one deduplicated deterministic `CHECK_STATUS` action; `EVENT` consumes host observations and acknowledgments. `HEARTBEAT` is a scheduler check request, distinct from the exact `HEARTBEAT` message inside a granted `RESUME_SESSION` action. Periodic checks default to 1,800 seconds and are disabled without `PRE_MODEL_CHECK`. Ordinary active/waiting/unchanged observations cause no model work. Explicit `RESUME` requires host-confirmed operator reconciliation. Frozen configuration changes require a newly authorized job; sharing `budget_ref` retains its counter.

An optional `start_request` supplies the existing orchestration planning request; omitted tier defaults to BALANCED. Startup intersects live runtime discovery with the host's available model pairs and fresh profile evidence. Worker catalog caches cannot enlarge that client list. Missing support/evidence requires manual model selection. Control never runs configured source collectors; refresh them separately under their existing authority and at-most-daily limits. Ordinary worker `plan`/`execute` retain their previous refresh behavior.

## Reserved actions and recovery

Reports expose state, reason, owner/generation, new actions, pending IDs, a shared dispatch count and `model_calls: 0`. Empty `actions` means do nothing. Actions have a stable ID, generation, issuance and expiry; the default acknowledgment deadline is 300 seconds (`action_timeout_seconds`, at most one day). They request status check, start, resume, checkpoint/handoff, authorized research or notification. Notification messages use fixed short templates and default to `CLIENT`. Set an external target reference only with explicit `external_notifications_authorized` authority; no external delivery transport is supplied.

The host re-checks the current grant, authorization, generation and expiry before executing an action, then deduplicates its ID and acknowledges `SUCCEEDED`, `FAILED` or `UNKNOWN`. A start receipt must identify requested and actual model plus the configured host issuer; matching owner/session and next generation confirm ownership. A handoff success requires an idle predecessor and a valid existing handoff preserving work, instructions, authorization, acceptance, budget and unresolved references. Successor startup follows that quiescence confirmation. The successor reloads current rules and project truth.

Actions are persisted atomically before being returned. A lost first response exposes only a pending ID on subsequent calls, never a second execution grant. Failed/unknown effects and missing acknowledgments require manual reconciliation; timeouts do not prove cancellation. An operator may confirm `NOT_STARTED`, then explicitly resume, but checkpoint deduplication and spent grants remain. A late predecessor snapshot is rejected without stopping the successor. Pause/cancel prohibit new automatic grants but cannot reverse an already dispatched effect. No guaranteed wake, delivery, exactly-once execution or provider budget cap is claimed.

`SOURCE_FAILED` may grant one pre-authorized bounded `research_ref` per host-confirmed source/failure pair. `ACCEPT_EVIDENCE` consumes an independent host verification bound to the candidate's canonical JSON SHA-256, producer/verifier identities and source/unit/model-mapping check references. The full candidate must be fresh and structurally valid; routing prices use the existing USD-per-million-token normalization. Changed, self-approved, expired, invalid or contradictory evidence is rejected. Accepted records merge into the shared last-known-good cache; unrelated providers remain. No collector program is repaired automatically.

External `control/state.json` stores only references, bounded action metadata, checkpoints, shared accounting and deduplication hashes. The SHA-256 detects accidental corruption, not malicious modification. Deleting this file destroys no-replay/accounting evidence; it is not a reset procedure. Keep the configured host state protected and reconcile unknown history before restoring work.

Run the executable [offline example](control.example.py) after installation:

```text
python .ai/foundation/ai_orchestrator/control.example.py
```

It creates temporary synthetic configuration and simulates a manually selected active chat, one idle continuation, duplicate suppression and completion notification. No real model/client/scheduler is called and all files are removed on exit. Replacing synthetic host observations with real protected evidence is a target integration task.

# Optional AI Orchestrator

Status: OPTIONAL REFERENCE CAPABILITY

This capability joins live runtime discovery, router v2, content-handle invocation, deterministic validation, fallback, and a content-free report. It is optional: Foundation rules, installation, validation, and manual work remain valid without Python, this capability, MCP, a runtime, network, credentials, evidence, or any model.

The control contract is `foundation-ai-orchestration/v1`. Prompts and generated answers stay in absolute input/output handles and never enter the orchestration report. The runtime connection store and all orchestration state remain outside Git.

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
python .ai/foundation/ai_orchestrator/orchestrator_mcp.py [--config ...] [--state-root ...] [--evidence-sources ...]
```

`LOCAL` never invokes a model and returns `DETERMINISTIC_TOOL_REQUIRED`. Missing or insufficient evidence returns `MANUAL_REQUIRED` with a manual-handoff action. Catalog and invocation failures are isolated per connection and per fallback. `remote_authorized` is passed through but never adds permission beyond the selected connection's own data-class and remote-model policy.

Validation modes are `NONE`, `OUTPUT_NONEMPTY`, `JSON_DOCUMENT`, and `MANUAL_REVIEW`. Structural checks are deterministic; semantic correctness is never fabricated. A retry occurs only through a different route already present in the router's bounded fallback chain.

Before invocation the reference writes a content-free external checkpoint bound to the complete request and input hash. A terminal identical run returns its prior report without invoking again. An `IN_PROGRESS` restart or timeout/protocol ambiguity requires manual provider reconciliation; only a definite pre-invocation availability/permission failure or deterministic validation failure may continue to a different bounded fallback.

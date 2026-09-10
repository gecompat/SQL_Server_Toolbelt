# Dynamic model-router capability

Status: OPTIONAL REFERENCE CAPABILITY

This capability keeps `foundation-model-router/v1` compatible and adds the `foundation-model-router/v2` facade without third-party Python packages. The router core is provider-neutral. MCP, CLI, process-launch, runtime-snapshot, provider-fragment aggregation, and Ollama Cloud discovery are adapters over the decision contracts.

It decides; it does not invoke a model. Model invocation remains owned by the selected client/provider integration. This keeps credentials out of router state and makes the same decision usable by Codex, Visual Studio with GitHub Copilot, the GitHub Copilot app/CLI, scripts, and clients without MCP.

When the optional `ai-runtime-adapters` capability is also selected, its separate stdio MCP bridge can probe configured Ollama/OpenAI-compatible endpoints, expose their current catalogs, and invoke the exact model chosen here through external content handles. It also provides a question/answer configuration assistant. Neither capability depends on the other: routing still degrades to manual handoff, and the runtime bridge still permits explicit manual/pinned model selection.

The optional `ai-orchestrator` capability can perform the complete catalog -> evidence -> route -> invoke -> validate -> fallback sequence. It preserves this separation internally: router v2 remains pure, runtime adapters retain their own permissions, payloads stay in external handles, and the orchestrator returns `MANUAL_REQUIRED` when quality/cost evidence or requested/actual model attestation is insufficient.

## Safety and authority boundary

Routing runs only after the project's privacy, authorization, and provider-eligibility rules. A remote model is excluded unless the request explicitly sets `allow_remote: true`. Capability, context-window, quality, cost, freshness, and prior-failure constraints are applied before cost optimization.

Current model names, prices, quality estimates, account limits, and availability are runtime facts. They are not Foundation policy. An expired or unparsable price catalog produces `NO_ROUTE`; the router does not invent a current price. API keys are read only from the provider's documented environment variable and are never written to the catalog, outcome store, snapshots, logs, or MCP results.

## Install and initialize

Select the capability during Foundation installation:

```text
python tools/install_foundation.py TARGET --capabilities model-router --apply
```

From the target repository, create a local launcher outside version control:

```text
python .ai/foundation/model_router/model_router.py install-launcher
```

Add the returned directory to `PATH`. Re-run this command if the repository or Python executable moves. The resulting `ai-model-router` command contains only a local path and is not committed.

Discover the current Ollama Cloud inventory and official pricing:

```text
ai-model-router sync-ollama
```

Set `OLLAMA_API_KEY` in the process environment before the sync, following Ollama's authentication documentation. Do not put it in a command line, profile, URL, MCP file, or repository. The adapter sends that variable only to the official HTTPS `ollama.com` inventory endpoint and refuses credential-bearing/query URLs or cross-origin credential redirects.

The default runtime location is `%LOCALAPPDATA%/ai-model-router` on Windows, `~/Library/Application Support/ai-model-router` on macOS, and `$XDG_STATE_HOME/ai-model-router` or `~/.local/state/ai-model-router` on Linux. `AI_MODEL_ROUTER_HOME` may select another authorized location outside the repository. In-repository runtime-state paths are rejected.

## Model assessment profiles

Discovery deliberately does not infer quality, context size, modalities, or suitable tiers from a model name. Newly discovered models are `UNASSESSED` and unavailable for ordinary routing until either:

- an operator profile marks them `ASSESSED`; or
- the local outcome store contains the configured minimum number of bounded evaluation observations.

Copy and edit `profiles.example.json` using model identifiers from `sync-ollama`, then resynchronize:

```text
ai-model-router sync-ollama --profiles path/to/profiles.json
```

Profiles may be project-owned configuration when their content is appropriate for version control. Observations, session keys, evaluation reservations, live prices, and generated catalogs remain local runtime state.

## Route by CLI

```text
ai-model-router route --tier BALANCED --task-class coding.repository --context-tokens 45000 --output-tokens 3000 --required-capability tools --allow-remote
```

The result includes the primary route, useful fallbacks, effective token rates, predicted success, expected chain spend, cost-of-success, reasoning effort, context/output budgets, cache strategy, validation strategy, `pricing_epoch`, and `valid_until`. Input context plus expected output must fit the context window. The reference implementation exhaustively compares every ordered chain within `max_fallbacks`; it returns `CHAIN_SEARCH_BOUND_EXCEEDED` if the declared search would exceed 250,000 sequences. A fallback must improve the preceding chain's cost-of-success by at least the greater of USD `0.000000000001` and `0.1%`.

The ranking objective is expected cost of a successful outcome, not the cheapest token. Empirical successes/failures update a Bayesian success estimate. Failure-recovery cost, latency value, session/cache affinity, switching cost, output volume, time-dependent prices, and fallback reach probability can all change the ranking.

After the caller validates a result, record it:

```text
ai-model-router record-outcome --provider PROVIDER --model MODEL --task-class coding.repository --success --actual-cost-usd 0.01 --latency-ms 1200 --session-id SESSION --context-tokens 45000 --pricing-epoch EPOCH
```

Session identifiers are stored only as SHA-256 lookup keys. Outcomes contain aggregate counts/cost/latency, not prompts or responses.

## Bounded evaluation of new models

`plan-evaluation` selects the cheapest compatible unassessed candidates and, when an incumbent exists, pairs each trial with that incumbent. The plan explicitly records the task set, sample count, spend ceiling, and stopping rules. The command never calls a model. `--reserve` atomically reserves separate linked candidate and incumbent arms against the smaller of the requested and configured daily evaluation budgets. A plan without `--reserve` is preview-only. Actual spend is settled to its own arm; only a completed pair increments candidate evaluation evidence.

```text
ai-model-router plan-evaluation --tier ECONOMICAL --task-class extraction --context-tokens 4000 --output-tokens 300 --allow-remote --allow-unknown-context --budget-usd 0.10 --max-candidates 2 --evaluation-task extraction --planned-sample-count 3 --reserve
```

Pass each returned `evaluation_id` and `pricing_epoch` to `record-outcome`. The reservation must match the provider/model. After the configured minimum reserved observations, empirical evidence can graduate the model for normal routing. A project may still explicitly disable it.

## Router v2 and provider fragments

`router_v2.py` accepts an array of provider-owned `foundation-model-router/v2` fragments. Each has its own boundary, health TTL, catalog expiry, provenance, and price epoch. A malformed, unhealthy, or expired provider is excluded independently; an unexpired provider-specific last-known-good fragment may be reused from the external runtime store. Other healthy providers continue normally.

```text
python .ai/foundation/model_router/router_v2.py --request REQUEST_V2.json --fragments FRAGMENTS.json --state-dir PATH_OUTSIDE_REPOSITORY
```

V2 applies data-class/remote-transfer permission, boundary, quality provenance, context, money, latency, and RAM/VRAM/CPU/GPU/disk/network/evidenced-energy constraints before routing. Measured or configured per-attempt resource costs with a source may join monetary cost; otherwise normalized resource pressure only breaks an economic tie. Host-executed models remain model tiers, never `LOCAL`.

## MCP pull routing

The dependency-free stdio server uses newline-delimited UTF-8 JSON-RPC and currently supports the MCP `2025-11-25`, `2025-06-18`, and `2025-03-26` handshakes:

```text
ai-model-router mcp
```

It exposes deterministic tools for routing, runtime snapshots, bounded evaluation planning, and outcome recording. Standard output is reserved for protocol frames; diagnostics go to standard error.

The server notices atomic catalog-file replacement before tool calls and adopts only a catalog that passes the core validation contract. If a refresh is invalid, it keeps the last loaded catalog; its existing expiry still applies.

Visual Studio and GitHub Copilot currently use different `.mcp.json` top-level shapes. Do not combine or blindly overwrite an existing project configuration. Merge the relevant entry from:

- `mcp.visual-studio.json` for Visual Studio's `servers` format;
- `mcp.github-copilot.json` for GitHub Copilot's `mcpServers` format.

Both launch the same local `ai-model-router mcp` command and contain no credential or machine-specific path.

## Graceful degradation

Use the strongest integration available in this order:

1. MCP pull routing (`model_router_route`);
2. CLI pull routing (`ai-model-router route`);
3. push routing with `launch`, which substitutes whole-argument placeholders and starts the client without a shell;
4. an expiring runtime snapshot for a client that cannot call tools;
5. an expiring privacy-safe manual handoff that tells the user which tier/capabilities and, only with fresh eligible evidence, which concrete model to select;
6. the Foundation tier semantics only, without inventing a current concrete model or price.

Requesting a model does not prove that a client or subagent used it. Preserve requested and actual model separately, require matching host execution/response metadata from an explicitly trusted issuer for `ATTESTED`, and otherwise report `REQUESTED_NOT_ATTESTED`. The optional `ai-client-integration` capability implements this receipt check and the `MANUAL_DISPATCH_REQUIRED` fallback; it remains separate from routing so the router stays decision-only.

Example push routing:

```text
ai-model-router launch --tier BALANCED --task-class coding.repository --context-tokens 45000 --output-tokens 3000 --allow-remote -- codex --model {model}
```

Available whole-argument placeholders are `{provider}`, `{model}`, `{reasoning_effort}`, `{context_budget}`, and `{output_budget}`. The child also receives `AI_ROUTED_PROVIDER`, `AI_ROUTED_MODEL`, `AI_ROUTED_REASONING_EFFORT`, and `AI_ROUTING_DECISION_ID`. No shell is used.

Generate a runtime-only snapshot with `snapshot`, for example `ai-model-router snapshot --tier BALANCED --task-class coding.repository --allow-remote --output PATH_OUTSIDE_REPOSITORY`. Store it outside version control and honor `valid_until` and every included price epoch. A snapshot is not a durable model ranking or Foundation rule. Explicit catalog and snapshot output paths inside any Git worktree are rejected.

## Ollama Cloud adapter evidence

The adapter follows the official interfaces verified on 2026-09-07:

- model discovery: `GET https://ollama.com/api/tags`, documented at https://docs.ollama.com/cloud and https://docs.ollama.com/api/tags;
- prices and UTC peak windows: https://ollama.com/pricing;
- direct cloud authentication: `OLLAMA_API_KEY`, documented at https://docs.ollama.com/api/authentication.

Ollama does not currently document a structured pricing API. The adapter therefore parses the narrowly identified official pricing tables, requires their expected headers and UTC schedule sentence, hashes normalized price material into `pricing_epoch`, and leaves the previous catalog untouched on any fetch or parse failure.

## Validation ownership

Capability tests prove deterministic filtering, price-window invalidation, cost-of-success ranking, fallback economics, session affinity, evaluation budgets, atomic local state, Ollama parsing/discovery reconciliation, CLI/launch behavior, and MCP framing. They do not prove that an operator's quality profile is correct, that a provider will remain available, or that a selected model will solve a real task. Those remain `PROJECT_SEMANTIC` and `RUNTIME_EMPIRICAL` responsibilities.

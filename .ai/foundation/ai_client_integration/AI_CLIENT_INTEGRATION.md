# Optional AI client integration and manual dispatch

`client_integration.py` is a dependency-free reference for semantic client configuration, truthful model-dispatch evidence, manual model selection, and governed local adapter materialization. It is optional. Foundation rules remain valid when the client, router, MCP, Python, adapters, models, or network are unavailable.

## Client configuration lifecycle

Every change follows `detect -> plan -> apply -> verify -> rollback`:

```text
python .ai/foundation/ai_client_integration/client_integration.py detect --request <external-request.json>
python .ai/foundation/ai_client_integration/client_integration.py plan --request <external-request.json> --detection <external-detection.json>
python .ai/foundation/ai_client_integration/client_integration.py apply --request <external-request.json> --plan <external-plan.json> --state-dir <external-state-directory>
python .ai/foundation/ai_client_integration/client_integration.py verify --request <external-request.json> --plan <external-plan.json> --state-dir <external-state-directory>
python .ai/foundation/ai_client_integration/client_integration.py rollback --request <external-request.json> --plan <external-plan.json> --state-dir <external-state-directory>
```

The request names an absolute router executable and exact credential-free arguments, client kind, configuration path, preferred/supported transports, validity, and read/write/repository-write authority. Credential flags and credential-bearing URLs are rejected; credentials belong only in a separately allowlisted execution environment. Detection hashes the executable and existing configuration for five minutes. The plan contains only the intended namespaced entry and hashes, not the complete configuration.

Apply rereads the file, refuses concurrent or unrelated changes, and merges one entry into the appropriate object. It never replaces the complete file. An existing different entry is `MANUAL_REQUIRED`. Backups and state remain outside Git and may contain the target's original configuration; protect that directory accordingly. Rollback restores exact prior bytes only while the applied digest still matches, so it cannot silently erase a later user edit.

Reference paths are intentionally distinct:

- Codex uses repository policy plus CLI, launcher, or expiring snapshot. No Codex configuration file is invented.
- Visual Studio MCP uses the `servers` object and a `stdio` entry.
- GitHub Copilot MCP uses the `mcpServers` object and a `local` entry with explicit tools.
- Generic clients use their declared CLI, launcher, snapshot, MCP, policy, or manual capabilities. Unknown shapes remain manual.

Use an absolute executable in applied configuration. Installing this capability does not start a server, enable MCP, alter an IDE, select a model, or grant remote transfer.

## Native Visual Studio Code role and subagent model plans

Current VS Code supports a `model` string or prioritized model list in `.github/agents/*.agent.md`, an explicit model parameter on a subagent call, `user-invocable`/`disable-model-invocation` plus coordinator allowlists for subagent access, and separate settings for plan, implementation, utility, and small-utility models. The documented subagent precedence is explicit invocation model, custom-agent `model`, then the parent model. The host may still reject a request above the main model's allowed cost tier. These are preferred native dispatch capabilities when present; MCP invocation and manual handoff remain independent fallbacks.

The read-only command below consumes an external, expiring model inventory, a fresh `foundation-client-model-routing-capability/v1` descriptor, and target-owned role bindings. It emits `foundation-vscode-model-routing-plan/v1` with only currently observed model names, a hash binding it to the capability observation, an exact settings patch using documented keys, custom-agent frontmatter, subagent parameters, unavailable bindings, and host constraints. It never edits `.vscode/settings.json` or `.github/agents`, and it never treats the requested model as actual execution evidence.

```text
python .ai/foundation/ai_client_integration/client_integration.py plan-vscode-models --request EXTERNAL_RUNTIME_REQUEST.json
```

The supported built-in setting surfaces are `chat.planAgent.defaultModel`, `github.copilot.chat.implementAgent.model`, `chat.utilityModel`, and `chat.utilitySmallModel`. Research, terminal, review, documentation, or arbitrary project roles use `CUSTOM_AGENT` or an explicit `SUBAGENT_PARAMETER`; the Foundation does not invent undocumented per-role JSON settings. Concrete model names remain external runtime facts and are rejected when absent from the supplied fresh inventory. Applying any returned patch still follows detect/plan/apply/verify/rollback with explicit configuration/repository authority.

Primary VS Code references (rechecked 2026-09-09):

- https://code.visualstudio.com/docs/agent-customization/custom-agents
- https://code.visualstudio.com/docs/agents/run/subagents
- https://code.visualstudio.com/docs/agents/run/planning
- https://code.visualstudio.com/docs/agent-customization/language-models

## Other native client model-routing surfaces

VS Code is not unique. Current official client documentation shows several distinct native mechanisms. The Foundation records these as expiring runtime observations under `foundation-client-model-routing-capability/v1`; it does not turn product-specific syntax into universal policy.

| Client | Verified native surface | Foundation classification |
| --- | --- | --- |
| Codex | default subagent model/reasoning, custom role configuration files, and explicit spawn overrides | `AGENT_PROFILE` / `SUBAGENT_PARAMETER`; explicit spawn wins |
| GitHub Copilot CLI | per-invocation/session model, custom-agent model/reasoning, and per-agent settings overrides | `INVOCATION_ARGUMENT` / `AGENT_PROFILE`; an unavailable choice may fall back to the session, and an `Auto` session makes subagents inherit its resolved model |
| Claude Code | project/user/CLI subagent definitions with model, tools, permissions, MCP, effort, and limits | `AGENT_PROFILE`; model resolution has documented precedence |
| Gemini CLI | project/user agent definitions with model and tools plus `agents.overrides` | `AGENT_PROFILE` / `ROLE_SETTING`; absent model inherits |
| Continue | `config.yaml` model roles such as chat, autocomplete, edit, apply, embed, and rerank | `ROLE_SETTING` / `PER_TASK_CLASS` |
| JetBrains AI Assistant | Core, Instant-helper, and AI-completion assignments; local and OpenAI-compatible providers | `ROLE_SETTING`; unsupported features can become unavailable or use a documented fallback |
| Cursor | CLI/API model per invocation and chat/session selection | `INVOCATION_ARGUMENT` / `SESSION_SELECTION`; no universal per-task-role assumption |
| Aider | main, weak, and editor model options via CLI, environment, or YAML | `ROLE_SETTING` / `INVOCATION_ARGUMENT`; limited fixed roles |

The portable decision order is:

1. consume a fresh, source-backed client capability descriptor and live model inventory;
2. use the narrowest native role, agent, or invocation surface that can honor the route;
3. require actual-model evidence when the host can silently inherit or fall back;
4. otherwise use MCP/CLI/launcher; and
5. emit an expiring manual-selection handoff when no automatic path is both supported and verifiable.

`client-model-routing-capability.schema.json` describes the native surfaces, binding scope, authority, fallback semantics, actual-model evidence, provenance, and expiry without naming a vendor or model. Product adapters may translate a descriptor into exact settings only through `detect -> plan -> apply -> verify -> rollback`. A documentation claim alone never authorizes writing user or repository configuration.

Primary product references (rechecked 2026-09-09):

- Codex: https://developers.openai.com/codex/config-reference and https://developers.openai.com/codex/multi-agent
- GitHub Copilot CLI and custom agents: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference and https://docs.github.com/en/copilot/reference/custom-agents-configuration
- Claude Code: https://code.claude.com/docs/en/sub-agents
- Gemini CLI: https://geminicli.com/docs/core/subagents/
- Continue: https://docs.continue.dev/customize/model-roles/00-intro
- JetBrains AI Assistant: https://www.jetbrains.com/help/ai-assistant/use-custom-models.html
- Cursor: https://cursor.com/docs/cli/reference/parameters
- Aider: https://aider.chat/docs/config/options.html

## Automatic model dispatch evidence

A model recommendation and an actual model switch are different facts. A catalog, error-message model list, configuration, or requested subagent parameter can prove that a model name was considered or advertised; it does not prove which model executed the task.

After an automatic/subagent dispatch, the client integration accepts a `foundation-model-dispatch-receipt/v1` record containing the requested and actual model, issuer, time, and evidence kind. `ATTESTED` is retained only when host execution/response metadata identifies the actual model, it matches the model selected for that dispatch, and the issuer appears in the target runtime's explicit trust set. The `evidence_kind` string alone is not evidence or authority. Missing, untrusted, or mismatching evidence becomes `REQUESTED_NOT_ATTESTED`. User observation and model self-report cannot upgrade a claimed automatic switch to attested execution. If a manual selection differs from the earlier recommendation, the receipt records that difference without preventing valid actual-model attestation.

Pass each trusted runtime issuer explicitly, for example `verify-dispatch ... --trusted-issuer <configured-host-adapter-id>`. Do not derive this allowlist from receipt content. A project with no configured trusted issuer cannot produce `ATTESTED` through this reference verifier and continues safely with validation/manual evidence.

This closes the failure seen in clients that silently keep the chat's original model: the system never reports a successful switch merely because the request parameter was accepted.

## Manual model-selection fallback

Manual selection is the required fallback when automatic switching is unavailable or cannot produce an execution receipt. It is not a failure of the routing design; it is a truthful change of dispatch mechanism.

```text
python .ai/foundation/ai_client_integration/client_integration.py manual-handoff --request <external-manual-request.json>
```

The command reads the task prompt from one handle/file, writes the complete handoff prompt to a caller-selected external file, and prints only a content-free `foundation-manual-dispatch/v1` record. The generated prompt includes task/data/risk classification, tier, capabilities, acceptance criteria, and validation requirements. The handoff tells the user which model to select only when a fresh concrete runtime record exists. Otherwise it recommends the portable tier and capabilities. Even a prior execution receipt proves only runtime evidence for the recommendation, never execution of the new handoff. `LOCAL` never names a model.

For non-public data without remote-transfer authority, remote or unknown-boundary concrete recommendations are removed and the prompt explicitly forbids pasting content into a remote/unknown client. The handoff expires. After the manual run, record the actually observed model and verify the receipt before treating the requested model as used.

## Capability gaps

Use the `ai-work` capability's `gap` operation to produce the existing `GapReport`. It contains capability identifiers, tested alternatives, least-privilege remedy and required authority, but no prompt/response content. Without repository write, Registration Authority, push, or PR permission, retain the report in external runtime state or stdout only. Creating an issue/work item, commit, branch, push, PR, or publication is a separate authorized action.

## Governed local adapter materialization

`synthesize-adapter` is available only when the request contains explicit `allow_local_adapter_synthesis: true`. The reference operation materializes the Foundation's reviewed command-adapter sources and a caller-supplied exact configuration into an empty directory outside Git. It refuses network access, credentials, repository writes, non-absolute commands, non-local boundaries, and version-controlled write roots. The initial report is always `QUARANTINED` and includes source/configuration hashes.

```text
python .ai/foundation/ai_client_integration/client_integration.py synthesize-adapter --request <external-synthesis-request.json>
python .ai/foundation/ai_client_integration/client_integration.py verify-synthesized --directory <external-adapter-directory> --fixture-input <external-or-authorized-input> --fixture-output <new-external-output>
```

Verification compares the materialized sources byte-for-byte with the installed trusted references, revalidates least privilege, then exercises `probe`, `catalog`, `invoke`, and `cancel` over JSONL using explicit conformance handles. Only a fully successful run changes the report to `VERIFIED`; failure leaves it quarantined. The output fixture must not already exist. This is conformance evidence for the adapter protocol and exact command configuration, not proof of task quality.

The reference cannot impose an operating-system network sandbox on the configured child command. Therefore only audited commands known to be offline may be used; a stronger sandboxed adapter is required otherwise. Permanent repository adoption remains a separate authorized contribution and cannot be inferred from local conformance.

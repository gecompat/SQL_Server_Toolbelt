# Optional AI host preparation

`host_preparation.py` is a dependency-free Python reference for `doctor`, `inventory`, `plan-provision`, `provision`, `verify`, and locally cached cost evidence. It is optional. Foundation policy and schemas remain usable when Python, this capability, every model runtime, and the network are absent.

The component discovers and reports; it does not grant network, credential, spend, install, repository, push, pull-request, or publication authority. Ollama and LM Studio are example runtime definitions, not prerequisites or preferred providers. Custom definitions may describe any shell-free executable inventory.

## Runtime state and payload boundary

By default, state is stored below the operating system's per-user state directory. Override it with `AI_HOST_PREPARATION_HOME` or `--state-dir`. The resolved state directory and every provision target must be outside a Git worktree. Never commit plans, approvals, inventory, host paths, cached evidence, credentials, downloaded artifacts, or checkpoints.

All commands emit JSON. A partial or unavailable optional runtime does not invalidate other runtime records. Non-success results use a nonzero exit code and a truthful `status`/`reason_code`.

## Diagnose and inventory

Built-in definitions check `PATH` and documented common installation paths:

```text
python .ai/foundation/ai_provisioning/host_preparation.py doctor
python .ai/foundation/ai_provisioning/host_preparation.py inventory --doctor <external-doctor-report.json>
```

Use `--definitions <external-runtime-definitions.json>` for other systems. A definition contains a runtime identifier, executable names, absolute search paths, exact version/inventory argument arrays, an output format (`JSON`, `OLLAMA_TABLE`, or `NONE`), an environment-name allowlist, a timeout, a health TTL, and an evidenced executable boundary. Commands are executed directly with `shell=false`; unresolved placeholders, stale diagnosis, and non-absolute resolved executables fail closed. Allowlisted environment values are redacted from emitted version/inventory fields.

Discovery is not trust. A product name, process, or loopback endpoint does not prove that model execution is host-local. Inventory artifacts therefore remain `UNKNOWN` until a later probe attests execution; Ollama artifact identifiers ending in `:cloud` or `-cloud` are explicitly `REMOTE` and can never inherit the local client's process boundary. Feed the resulting evidence through the normal capability and boundary checks.

## Create and approve a provision plan

First create an external provision request and an independently maintained recipe catalog. The request sets the artifact/runtime/target and hard download, disk, memory, cost, network-destination, environment, and expiry limits. A recipe must name one exact credential-free `file:` or HTTPS source, expected SHA-256, artifact identifier, target runtime, license/use notice and source, resource bounds, exact argument arrays, and idempotency semantics.

The reference provisioner supports only install commands declaring `install_network_access: "DENY"`. It does not provide an operating-system network sandbox, so projects must allow only audited installers that consume the already verified staged artifact without opening the network. Use a stronger sandboxed implementation where this cannot be established.

```text
python .ai/foundation/ai_provisioning/host_preparation.py plan-provision --request <external-request.json> --recipes <external-recipes.json>
```

Review the complete emitted plan before approval:

- source URI, artifact/model identifier and target runtime;
- license/use notice and evidence URI;
- download, disk, memory, destination, environment and monetary ceiling;
- target path, install/verify command arrays, digest and expiry;
- rollback and recovery instructions.

Approve once by creating an external `foundation-provision-approval/v1` receipt containing a unique receipt ID, `approve:provision`, the exact `provision_id` and `plan_hash`, and an approval/expiry interval no wider than the plan. On-demand provisioning is just a previously approved plan with a short, explicit scope; there is no wildcard approval.

```text
python .ai/foundation/ai_provisioning/host_preparation.py provision --plan <external-plan.json> --approval <external-approval.json>
python .ai/foundation/ai_provisioning/host_preparation.py verify --plan <external-plan.json>
```

Only the single source and action sealed into the plan can run. Redirects across origins, excess bytes, digest drift, environment expansion, target overwrite, expired plans/approvals, and in-repository destinations fail closed. The downloaded artifact is hash-checked before installation. Verification may be repeated after plan expiry because it performs no download or install.

## Failure, recovery, and cleanup

Checkpoints are atomic, integrity-protected, and keyed to the exact plan. A completed plan returns its prior result without downloading again. A crash during a not-yet-installed download can safely resume. A crash around a non-idempotent installer becomes `MANUAL_REQUIRED`; it is never replayed blindly. A `FAILED` or `MANUAL_REQUIRED` checkpoint is terminal for that plan: reconcile it, change the inputs/evidence, create a new plan, and approve the new hash.

On failure the component removes only its exact staging artifact. It never deletes an existing target. Follow the plan's recovery text, inspect the target and checkpoint, run `verify`, then remove only artifacts whose identity and digest you have established. Partial work is never reported as complete.

## Cost-evidence refresh

Cost research is useful as a bounded refresh process, not as a live dependency of every route. Configure external source definitions that point to a machine-readable primary source or a project-controlled file and specify a JSON path, subject, unit, currency, provenance, validity and refresh interval:

```text
python .ai/foundation/ai_provisioning/host_preparation.py refresh-cost-evidence --sources <external-sources.json>
```

Add `--network-authorized` only when the exact HTTPS sources are allowed. Each source has isolated state and is contacted at most once per 24 hours, including after a failed attempt. A fresh last-known-good value remains available when refresh fails; expired evidence is not used as money. AI may help discover candidate sources, but its prose is not evidence: the source, units, extraction path, and any conversion must be independently verified and explicitly configured. This makes cached costs locally queryable without requiring AI or network access.

## Fully manual alternative

When this Python reference is unavailable:

1. Inventory installed runtimes with their native tools and record the command, executable identity/hash, observation time, boundary evidence, and failures separately.
2. Prepare the same `ProvisionPlan` fields without downloading anything. Obtain the artifact identifier, exact source, digest, license/use notice, download and resource bounds from authoritative sources.
3. Review and approve the complete plan hash and expiry once. Do not approve a mutable URL, wildcard destination, unspecified cost, or unbounded download.
4. Download only the approved source within its limits, verify the exact hash, and run only the reviewed offline installation command.
5. Verify the installed target independently. Record `COMPLETED` only after verification; otherwise record `FAILED` or `MANUAL_REQUIRED` with recovery actions.
6. Keep all host evidence, content and credentials outside the repository. Submit a repository change only through a separately authorized durable process.

If no safe plan can be produced, leave the runtime unavailable. The correct degradation result is a deterministic alternative, a manual handoff, or `UNAVAILABLE`/`BLOCKED`—never an invented installation or model choice.

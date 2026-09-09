# AI work executor capability

Status: OPTIONAL REFERENCE CAPABILITY

`ai_executor.py` is a dependency-free reference executor for exact `foundation-ai-work/v1` plans. It revalidates the request, complete capability catalog, plan identity, expiry, authority constraints, and handles before invocation. It is separate from the decision-only planner and from runtime adapters. Selecting `ai-executor` installs its `ai-work` planner dependency, but no adapter implementation is mandatory.

The executor:

- invokes only explicit absolute adapter `argv` arrays with `shell=false` and an environment-name allowlist;
- keeps payload bytes behind externally supplied file handles and never persists their paths or content in its checkpoint;
- stores content-free, integrity-checked checkpoints atomically outside every Git worktree;
- uses stable operation keys and will not blindly repeat an ambiguous non-idempotent external effect;
- retries only an unused alternative capability, or replays the same operation key when the descriptor explicitly attests `IDEMPOTENT_REPLAY`;
- enforces request deadline, timeout, attempt, money, CPU/GPU, disk, network, energy, peak RAM, and peak VRAM limits;
- accepts grouped approval receipts only for the exact plan hash, approval point, required authority, and validity window;
- requires complete, scoped validation evidence and checks independent-validation claims against the producing work capability;
- reports measured attempts, spend/resources, validation, constraints, and remaining action without treating absence or uncertainty as success.

Python and this executor remain optional. Another executor is conforming when it enforces at least the same public contracts and authority boundaries.

## Execute and resume

```text
python .ai/foundation/ai_executor/ai_executor.py \
  --request work-request.json \
  --plan execution-plan.json \
  --capabilities capabilities.json \
  --bindings adapter-bindings.json \
  --handles handle-map.json \
  --approvals approval-receipts.json
```

Re-running that exact command resumes the content-addressed checkpoint. `--state-dir` may select another local directory, but the executor rejects a location in any Git worktree. Otherwise it uses the platform user-state location or `AI_WORK_EXECUTOR_HOME`.

Bindings and handles are local runtime configuration and must not be committed. A binding has this shape:

```json
{
  "bindings": {
    "capability-id": {
      "argv": ["/absolute/path/to/adapter", "--config", "/outside/repository/config.json"],
      "environment_allowlist": ["NAME_OF_REQUIRED_CREDENTIAL"],
      "timeout_seconds": 30,
      "model": "runtime-model-id",
      "remote_authorized": false
    }
  }
}
```

The executor passes one JSONL `invoke` frame to that adapter. It verifies that the returned output hash matches the actual output-handle bytes. The reference path currently supports one input and one output handle per step; a different executor may support richer handle topologies without changing the public plan contract.

## Approval receipt

An approval receipt conforms to `foundation-ai-approval/v1`. Its `scope_sha256` is the digest of the complete canonical plan and its `approval_key` is the digest of the exact approval-point object. Approval is therefore grouped at one risk boundary without authorizing unrelated steps or a modified plan. Supplying a receipt never expands the request, project, adapter, or environment authority.

## Cancellation and recovery

```text
python .ai/foundation/ai_executor/ai_executor.py --plan execution-plan.json --cancel
```

Cancellation writes a plan-scoped marker outside the repository. It is observed before invocation and between bounded adapter calls. An active subprocess remains bounded by the effective minimum of adapter timeout, request timeout, and remaining deadline; the executor does not pretend that an uncooperative process stopped early.

After a crash, `PREPARED` means invocation had not started. `IN_PROGRESS` means the outcome may be ambiguous. For external effects, a capability without `IDEMPOTENT_REPLAY` stops as `MANUAL_REQUIRED`; an operator must reconcile the stable operation key before any new attempt. An idempotent capability is replayed with the same operation key. This prevents the executor from claiming exactly-once delivery that the target system cannot prove.

## Limits and evidence

Actual cost and cumulative resources count even for attempts that later fail validation. RAM and VRAM are enforced as peak values; time, disk, network, GPU, and energy are cumulative. Unknown estimates fail closed under a matching hard limit.

A validator may return one evidence object or an array under `validation_evidence`. Every required validation capability must have passing evidence. A failed result remains failed; missing, inconclusive, unavailable, unscoped, duplicate, self-produced, or malformed evidence never becomes a pass.

Checkpoints and reports contain IDs, hashes, statuses, timestamps, bounded error classes, costs, resources, and evidence metadata only. They contain no prompt, response, retrieved content, secret, credential, environment dump, or host path.

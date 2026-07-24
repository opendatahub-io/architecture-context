# arch-query: CLI Query Interface for Architecture Context

**Date**: 2026-05-03
**Status**: Design
**Problem Reference**: `docs/arch-context-consumption-problem.md`
**Data Reference**: `docs/arch-context-gaps.md` (2026-05-03 usage analysis section)
**Slack Context**: `docs/arch-context-gaps-2026-05-03.md` (comprehensive Slack discussion analysis)

---

## Motivation

LLM agents consume architecture-context via filesystem tools (Read, Bash). Trace data from 15,696 tool call spans shows they spend 54% of their tool calls on navigation (`ls`, `grep` for filenames) and read entire 300-line docs to extract ~50 lines of structured facts. 20% of traces fail to read any architecture content at all.

Agents already run 7,369 Bash commands against architecture-context. They're using the command line as their query interface — they're just doing it with `ls | grep`, which is a poor query tool.

`arch-query` replaces `ls | grep` with a purpose-built CLI that works with agent behavior instead of trying to change it. The script controls the output format and size, guaranteeing concise, relevant results regardless of how the agent decides to use it.

---

## Prior Art & Slack Context

This idea has precedent in team discussions (see `docs/arch-context-gaps-2026-05-03.md` for full Slack analysis):

- **Jason Greene proposed helper scripts** (April 2026, `#wg-rhai-ai-first-steering-committee`): After Luca reported hallucination issues with markdown-based context, Jason suggested "helper scripts generating markdown deterministically from YAML/CSV inputs." `arch-query` is a direct implementation of this idea.

- **Jessica proposed YAML for deterministic data** (same thread): Structured formats for API lists, version tables, CRD inventories — data that shouldn't be subject to LLM interpretation. `arch-query` serves this role by extracting structured facts from prose and returning them in a controlled format.

- **The LATEST_VERSION file workaround** (@astefanu, `#wg-rhai-rfe-builder`): When 10/20 feasibility agents failed to use architecture-context because Bash tool was denied and they couldn't `ls` to discover files, the fix was writing a `LATEST_VERSION` file for Read-based discovery. This is a manual, one-off version of what `arch-query` does systematically — give agents a deterministic entry point that doesn't depend on directory exploration.

- **"Claude got feisty"** (@Jessica, `#wg-rhai-rfe-builder`): Agents gave up waiting for full repo clones, leading to sparse checkout — which then broke symlinks, which caused 20% of traces to read nothing. Each fix introduced a new problem. `arch-query` breaks the chain by abstracting away the filesystem entirely.

- **Architecture-context is a "1-day POC now foundational"** (jtanner, `#wg-rhai-ai-first-steering-committee`): The markdown-directory format was never designed for agent consumption at scale. Eder Ignatowicz immediately noted: "Well, it's the brain that strat and rfe uses to generate content." The gap between the format's origin and its current role is the core problem.

### Why Not a Structured Index File?

The initial instinct (shared by ChatGPT's analysis and our own early thinking) was to add YAML index files (INDEX.yaml, per-component YAML fact sheets). The problem: agents are probabilistic, not deterministic. Trace data shows they converge on the same 6-step `ls | grep | cat` pattern not because it's optimal, but because it's what an LLM does when pointed at a directory. An INDEX.yaml doesn't change that behavior unless the skill prompt says "read INDEX.yaml first" — and if you're modifying the prompt anyway, a CLI tool is strictly better because it controls the output regardless of how the agent invokes it.

### Why Not Pre-Inject Context into Prompts?

The orchestrator could pre-resolve relevant components from Jira metadata and inject context directly into agent prompts. This is the most deterministic option but removes agent autonomy — the agent can't go deeper if it needs to, and the orchestrator must predict what's relevant before the agent has analyzed the issue. `arch-query` preserves agent-driven exploration while controlling the cost.

### Scope: Architecture Only, Not Organizational

Jira "components" are team labels, not architectural components. A Jira component like "AI Hub" maps to 15 repos, and a repo like `rhods-operator` touches multiple Jira components. There is no meaningful mapping between Jira components and architecture-context components (@andrewballantyne, @Dana Gutride, and jtanner discussed this extensively in `#wg-rhai-strat-refine-review`). The Jira-to-repo mapping is an organizational context problem being addressed separately by @khowell's org-context repo. `arch-query` stays scoped to architectural facts derived from source code — things the generator actually knows.

---

## Design Principles

1. **Work with agent behavior** — Agents naturally use Bash. Don't require them to learn a new access pattern or remember to read a specific file first. One tool, one interface.
2. **Control the output** — The script decides what comes back, not the agent's file-reading strategy. Same query, same result, every time.
3. **Don't replace the source** — Markdown docs remain the source of truth. The generator doesn't change. `arch-query` is a read-only query layer.
4. **Minimal skill prompt change** — One line: "Use `arch-query` to look up architecture context." No directory structure explanations, no file naming conventions.
5. **Fail informatively** — When something doesn't exist, say so clearly. "Not found in RHOAI component inventory" is more useful than empty `ls` output.
6. **Reduce hallucination surface** — Returning 50 lines of structured facts instead of 300 lines of prose gives the agent less material to misinterpret. Luca's hallucination reports and strategies that violated architectural principles (mmortari's "proxy sidecar doing business logic" incident) trace back to agents extrapolating from prose. Structured output constrains interpretation.

---

## Version Handling

Architecture context is version-specific. The PVC mounted at `/app/.context` contains 21 version directories (rhoai-2.6 through rhoai.next) and 5 semantic symlinks (`current-ga` → rhoai-3.3, `early-access` → rhoai-3.4-ea.2, `future-ga` → rhoai-3.4, `latest-released` → rhoai-3.4-ea.1, `newest` → rhoai-3.4).

Today, agents discover versions by `ls`-ing the directory — part of the 54% navigation overhead. The markov workflow (`batch-rfe-pipeline.yaml`) does not pass a version parameter to agents; they figure it out themselves.

### Default version: auto-detect

`arch-query` auto-detects the default version by reading symlinks and sorting version directories. The default is `rhoai.next` (the most complete, forward-looking version). No env var or orchestrator involvement required.

### `--version` flag

Any subcommand accepts `--version` to query a specific version:

```bash
arch-query --version rhoai-3.3 component kserve
arch-query --version current-ga component kserve    # symlink aliases work
```

### Multi-version for upgrade issues

Upgrade-related issues (e.g., "migrating from 3.3 to 3.4") need to compare what changed across versions. Rather than reading two full 300-line docs and manually spotting differences, agents use `arch-query diff`:

```bash
arch-query diff kserve rhoai-3.3 rhoai-3.4          # single component
arch-query diff --all rhoai-3.3 rhoai-3.4            # platform-wide
```

This keeps version handling in `arch-query` rather than forcing the orchestrator or skill prompts to parameterize it. The agent decides which version(s) are relevant based on the issue content — same autonomy as today, but without the filesystem navigation.

---

## Data Source

`arch-query` reads the existing markdown files at invocation time (or reads a pre-built JSON cache for performance). The data pipeline is:

```
generator → markdown files (source of truth) → arch-query parses → structured responses
```

The pre-built cache (optional) would be generated by a one-time parse step:

```
markdown files → arch-query --build-cache → .arch-query-cache.json → fast queries
```

---

## Subcommands

Derived from the actual agent behavior observed in trace data (7,369 Bash spans, 8,327 Read spans).

### `arch-query search <term>`

Fuzzy component search. Replaces `ls rhoai-3.4-ea.2/ | grep -i <term>`.

```bash
$ arch-query search vllm
Found 5 components matching "vllm":
  vllm            - GPU-accelerated LLM inference (CUDA)
  vllm-cpu        - CPU-optimized LLM inference
  vllm-gaudi      - Intel Gaudi HPU-optimized LLM inference
  vllm-rocm       - AMD ROCm GPU-optimized LLM inference
  vllm-spyre      - IBM Spyre accelerator-optimized LLM inference

$ arch-query search trusty
Found 2 components matching "trusty":
  trustyai-explainability    - AI explainability, fairness metrics, and drift detection
  trustyai-service-operator  - Manages TrustyAI, LMEval, GuardrailsOrchestrator, EvalHub

$ arch-query search kagenti
No components matching "kagenti" in RHOAI inventory.
```

Matches against: component names, aliases, keywords from purpose descriptions. Case-insensitive, substring matching.

### `arch-query component <name>`

Component fact sheet. Replaces reading a full 300-line markdown doc. Returns only the structured facts agents actually extract (~40-60 lines).

```bash
$ arch-query component kserve
# kserve
Purpose: Model serving platform with CRDs for ML/LLM inference
Type: operator
Repository: red-hat-data-services/kserve
Language: Go, Python

## CRDs
  serving.kserve.io/v1beta1    InferenceService         Namespaced
  serving.kserve.io/v1alpha1   InferenceGraph            Namespaced
  serving.kserve.io/v1alpha1   ServingRuntime             Namespaced
  serving.kserve.io/v1alpha1   ClusterServingRuntime      Cluster
  serving.kserve.io/v1alpha2   LLMInferenceService        Namespaced
  serving.kserve.io/v1alpha2   LLMInferenceServiceConfig  Namespaced
  ...

## Ports
  8080/HTTP    controller metrics
  8443/HTTPS   webhook

## Dependencies
  Requires: cert-manager, Istio, Gateway API CRDs
  Used by: odh-model-controller, llm-d-inference-scheduler

## Overlays
  None active.

Full doc: architecture/rhoai-3.4-ea.2/kserve.md (336 lines)
```

### `arch-query component <name> --full`

Returns the full markdown doc. Escape hatch for deep-dive questions.

### `arch-query list`

List all components. Replaces reading PLATFORM.md (870 lines) just to get the component inventory.

```bash
$ arch-query list
70 components in RHOAI rhoai.next:

Platform Control:
  rhods-operator              Operator    Platform operator managing full lifecycle
  odh-dashboard               Frontend    Web management console
  kube-auth-proxy             Service     OAuth2/OIDC authentication proxy
  ...

Model Serving:
  kserve                      Operator    Model serving platform with CRDs
  odh-model-controller        Operator    Extends KServe with OpenShift ingress
  vllm                        Service     GPU-accelerated LLM inference (CUDA)
  vllm-cpu                    Service     CPU-optimized LLM inference
  ...

(grouped by functional domain)
```

### `arch-query list --names-only`

Just component names, one per line. For scripting or when the agent just needs to check existence.

### `arch-query deps <name>`

Dependency graph for a component. Replaces reading multiple full docs to trace cross-component relationships.

```bash
$ arch-query deps kserve
kserve depends on:
  cert-manager         (TLS certificate management)
  istio                (service mesh, ingress)
  Gateway API CRDs     (HTTPRoute, Gateway)

kserve is used by:
  odh-model-controller (extends KServe with OpenShift ingress, NIM support)
  llm-d-inference-scheduler (Gateway API InferencePool endpoint picker)
  models-as-a-service  (multi-tenant LLM inference gateway)
```

### `arch-query crds [component]`

CRD index. Without a component name, lists all CRDs across the platform. With a component name, lists CRDs for that component.

```bash
$ arch-query crds | grep InferenceService
  serving.kserve.io/v1beta1    InferenceService         kserve          Namespaced
  serving.kserve.io/v1alpha2   LLMInferenceService      kserve          Namespaced
  serving.kserve.io/v1alpha2   LLMInferenceServiceConfig kserve         Namespaced
```

### `arch-query ports [component]`

Port index. Same pattern as `crds`.

```bash
$ arch-query ports vllm-cpu
vllm-cpu:
  8000/HTTP    OpenAI-compatible inference API
  8033/gRPC    TGIS-compatible gRPC API
```

### `arch-query platform`

Condensed platform summary. Replaces reading the full 870-line PLATFORM.md. Returns the platform metadata, functional domain table, and key architectural decisions (~80 lines).

### `arch-query overlays`

List active overlays and what they affect.

```bash
$ arch-query overlays
4 active overlays:
  0001  KFP SDK updated to 2.16 in RHOAI 3.4    affects: data-science-pipelines, notebooks
  0002  MLflow Go SDK                             affects: mlflow
  0003  Llama Stack renamed to OGX                affects: llama-stack-distribution
  0004  CodeFlare SDK missing from inventory      affects: codeflare-sdk
```

### `arch-query exists <name>`

Quick existence check. Returns exit code 0 if found, 1 if not.

```bash
$ arch-query exists kagenti
Not found in RHOAI component inventory.
Closest matches: none.
Note: RHOAI architecture context covers only the OpenShift AI platform.
Components from RHEL AI, RHAIIS, or upstream-only projects are not included.

$ arch-query exists kserve
kserve exists in RHOAI inventory.
Type: operator | Tier: optional_platform | Doc: architecture/rhoai-3.4-ea.2/kserve.md
```

### `arch-query versions`

List available versions with symlink aliases. Replaces `ls architecture/` and the 14 lines of directory structure explanation currently in skill prompts.

```bash
$ arch-query versions
21 versions available:

  rhoai.next                          (74 components)
  rhoai-3.4-ea.2   [early-access]     (68 components)
  rhoai-3.4         [future-ga,newest] (70 components)
  rhoai-3.4-ea.1   [latest-released]  (66 components)
  rhoai-3.3         [current-ga]       (58 components)
  rhoai-3.2                           (55 components)
  rhoai-3.0                           (48 components)
  rhoai-2.25                          (45 components)
  ...

Default: rhoai.next
```

### `arch-query diff <component> <version-a> <version-b>`

Structured diff of a component between two versions. For upgrade-related issues where agents need to understand what changed. Parses both version docs and diffs the extracted facts — not a raw text diff.

```bash
$ arch-query diff kserve rhoai-3.3 rhoai-3.4
kserve: rhoai-3.3 → rhoai-3.4

  Added CRDs:
    serving.kserve.io/v1alpha2  LLMInferenceService
    serving.kserve.io/v1alpha2  LLMInferenceServiceConfig

  Added dependencies:
    llm-d-inference-scheduler

  Removed dependencies:
    (none)

  Changed ports:
    (none)

  New constraints:
    - Gateway API support requires Istio 1.22+
    - LLMInferenceService CRD is alpha, schema may change
```

### `arch-query diff --all <version-a> <version-b>`

Platform-wide diff. Shows added/removed components and summarizes changes across all components that exist in both versions.

```bash
$ arch-query diff --all rhoai-3.3 rhoai-3.4
rhoai-3.3 → rhoai-3.4

  Added components (12):
    ai-gateway-payload-processing, codeflare-sdk, kueue, llm-d-inference-scheduler,
    llm-d-routing-sidecar, models-as-a-service, vllm-rocm, vllm-spyre, ...

  Removed components:
    (none)

  Changed (18 components):
    kserve             +2 CRDs, +1 dependency
    odh-model-controller  +3 CRDs
    vllm               +1 port, new constraints
    ...

  Unchanged (40 components)
```

---

## Expected Impact

Based on the trace data analysis:

| Current Behavior | With arch-query | Improvement |
|-----------------|-----------------|-------------|
| 6-step navigation loop | 1-2 Bash calls | ~70% fewer tool calls |
| 54% of calls are navigation | ~0% navigation | Eliminated |
| 20% of traces read nothing | Informative error messages | ~0% silent failures |
| Read 870-line PLATFORM.md | `arch-query list` (~50 lines) | ~95% fewer tokens |
| Read 300-line component doc | `arch-query component` (~50 lines) | ~80% fewer tokens |
| Read 3 docs for cross-component question | `arch-query deps` (~15 lines) | ~95% fewer tokens |
| Read 2 full docs to compare versions | `arch-query diff` (~20 lines) | ~95% fewer tokens, structured |
| `ls` to discover version directories | `arch-query versions` or `--version` flag | Eliminated |
| Median 30-40K tokens on architecture context | Estimated 3-5K tokens | ~85-90% reduction |

---

## Skill Prompt Integration

Current skill prompts reference architecture-context via directory paths. The change is minimal:

**Before** (implicit in skill behavior — agents discover on their own):
```
Architecture context is available in .context/architecture-context/
```

**After**:
```
Use `arch-query` to look up architecture context. Do not ls or grep the architecture directory. Examples:
  arch-query search <term>                      - find components
  arch-query component <name>                   - get component facts (CRDs, ports, deps)
  arch-query deps <name>                        - dependency graph
  arch-query diff <name> <ver-a> <ver-b>        - what changed between versions
  arch-query versions                           - list available versions
  arch-query --version <ver> component <name>   - query a specific version
  arch-query component <name> --full            - full doc when needed
```

---

## Implementation Notes

- **Language**: Python (already in the pipeline's dependency set)
- **Parsing**: Extract structured sections from markdown using heading-based splitting. The component docs follow a consistent template (Metadata, Purpose, Architecture Components, APIs Exposed, Dependencies, etc.) generated by the same LLM, so parsing is reliable.
- **Cache**: Optional JSON cache for faster repeated queries. Regenerated when markdown files change.
- **Alias table**: Built from component names + common abbreviations observed in trace data (`trusty` → `trustyai-*`, `dash` → `odh-dashboard`, `vllm` → all vllm variants, etc.)
- **Installation**: Placed in the architecture-context directory or the pipeline's `scripts/` directory. Available on `$PATH` in agent containers.
- **No external dependencies**: Uses only Python stdlib (argparse, json, re, pathlib). No vector DB, no embeddings.

---

## Consumers Beyond the Pipeline

Slack discussions reveal at least 6 teams/workflows that consume or want to consume architecture-context (`docs/arch-context-gaps-2026-05-03.md`, Section 9). `arch-query` would serve all of them:

| Consumer | Current Access | arch-query Benefit |
|----------|---------------|-------------------|
| **RFE review pipeline** (rfe-creator skills) | Sparse checkout + filesystem exploration | Eliminates navigation, reduces tokens |
| **Strategy pipeline** (strat-creator skills) | Same sparse checkout | Same benefits; strategy-review sub-skills are the heaviest consumers |
| **Doc pipeline** (@mmortari, @Matthew Stratton) | Plans to use arch-context as "grounding" | `arch-query component` provides structured grounding without prose overhead |
| **Autofix pipeline** (@Steven Huels, @stobin) | Needs repo-to-component mapping | `arch-query component <name>` returns repo URL; `arch-query search` finds the right component |
| **CVE/security review** (@russellb) | Manual reference to GitHub repo | `arch-query component --full` provides architectural context for reachability analysis |
| **Team bug triage prompts** (@Ugo Giordano, @sfroberg, @stobin) | "Consult architecture-context" in triage prompts | Replace with "Use `arch-query`" — deterministic, concise output |

The tool's value scales with the number of consumers. A single implementation serves all six, with no per-consumer customization needed.

---

## Relationship to Stale Data Problem

`arch-query` does not solve the staleness problem (Section 2 of the Slack analysis). EvalHub code running ahead of arch-context, KFP SDK version being out of date, 3.4 not regenerated — these are generator cadence issues. `arch-query` faithfully returns whatever the markdown files contain, stale or not.

However, it could make staleness *visible*. Options:
- Include the `Generated On` date from each component doc's metadata in query output
- `arch-query stale` subcommand that lists components where `Generated On` is older than N days
- Include version/date in the `arch-query component` header so agents (and humans) can see how fresh the data is

The overlay system (the "hack" per @mmortari) remains the workaround for urgent corrections. `arch-query overlays` already surfaces these. Whether overlays should be pre-applied to query output or shown separately is an open question.

---

## Decisions from Review (2026-05-03)

Feedback from external review (ChatGPT analysis of the design + evaluation plan) resolved several open questions and added new requirements.

### 1. Output format: `--json` flag

Default output remains plain text (agents handle it well in traces). Add `--json` flag for structured output when needed:

```bash
$ arch-query component kserve --json
{
  "component": "kserve",
  "purpose": "Model serving platform with CRDs for ML/LLM inference",
  "type": "operator",
  "repository": "red-hat-data-services/kserve",
  "crds": [...],
  "ports": [...],
  "dependencies": {...},
  "constraints": [...]
}
```

JSON improves judge scoring (grounding, gap awareness) and makes extraction deterministic for downstream tooling. Plain text remains the default because agents in traces already parse it reliably and it's more readable in logs.

### 2. Constraints field

Component output includes a `constraints` section for caveats that would otherwise be lost when compressing 300-line prose to 50-line fact sheets. This directly addresses the Tier 3 (reasoning) risk — agents answering "yes, fully supported" when the real answer is "yes, but limited to specific modes."

```bash
$ arch-query component kserve
...
## Constraints
  - KEDA integration limited to external metrics
  - Gateway API support requires Istio 1.22+
  - LLMInferenceService CRD is alpha, schema may change
```

Constraints are extracted from prose sections that contain hedging language ("only supports", "limited to", "requires", "not yet", "alpha", "experimental"). The parser flags these during cache build.

### 3. Usage logging for MLflow

`arch-query` logs every invocation to a JSONL file (`arch-query-usage.log`) in the working directory:

```json
{"timestamp": "2026-05-03T14:22:01Z", "subcommand": "component", "args": ["kserve"], "flags": ["--json"], "result_lines": 48, "trace_id": "abc123"}
```

Fields tracked:
- `arch_query_calls_per_question` — how many CLI calls the agent makes per task
- `fallback_to_filesystem` — whether the agent also used `ls`/`grep` on the architecture directory (detected from co-occurring Bash spans in the same trace)

These metrics are the primary adoption signal. If agents ignore `arch-query` and still `ls | grep`, the tool has failed regardless of output quality. The MLflow experiment runner picks up this log and attaches metrics to the run.

### 4. Adoption risk mitigation

The highest risk is agents falling back to familiar `ls | grep` patterns. Mitigations:

1. **Skill prompt instruction** — One line in every skill that consumes architecture-context:
   ```
   Use `arch-query` to look up architecture context. Do not ls or grep the architecture directory.
   ```
   The negative instruction ("do not ls or grep") is important — agents default to filesystem exploration unless explicitly told not to.

2. **Informative errors** — If an agent does `ls .context/architecture-context/architecture/`, it gets 70+ files with no guidance. `arch-query search <term>` returns matches with descriptions. The CLI output is strictly more useful than `ls`, which helps natural adoption.

3. **Measurement** — The usage log (above) detects fallback behavior per-trace. If fallback rate exceeds 20% in the evaluation, investigate whether the CLI is missing queries agents need.

### 5. Overlay application: pre-apply by default

`arch-query component` returns base facts with active overlays pre-applied. Rationale: overlays exist to correct stale/wrong data. Returning un-patched data defeats the purpose. Agents shouldn't need to know about the overlay mechanism.

The overlay source is noted in output for transparency:

```bash
## Dependencies
  Requires: cert-manager, Istio, Gateway API CRDs
  Used by: odh-model-controller, llm-d-inference-scheduler
  [overlay 0001: KFP SDK updated to 2.16]
```

`arch-query overlays` still lists all overlays separately for audit purposes.

### 6. No `arch-query ask` — deterministic relationship commands instead

The review suggested a natural language command (`arch-query ask "Can KServe autoscale with KEDA?"`). This is out of scope. `arch-query` stays deterministic and retrieval-oriented — no embedded LLM calls, no prompt injection surface, no compounding non-determinism.

If Tier 3 (cross-component reasoning) remains weak after v1 evaluation, the escalation path is richer deterministic commands, not natural language:

```bash
$ arch-query relation kserve keda
$ arch-query supports kserve autoscaling
$ arch-query evidence kserve keda
```

These return structured, auditable output without an inner LLM:

```json
{
  "subject": "kserve",
  "object": "keda",
  "relationship": "integrates_with",
  "support_level": "partial",
  "constraints": [
    "Only documented for specific autoscaling paths"
  ],
  "sources": [
    "architecture/rhoai-3.4-ea.2/kserve.md#dependencies"
  ]
}
```

This gives Tier 3 better support while preserving the core design principle: same query, same result, every time. An LLM-backed `ask` interface is a last resort, considered only if deterministic relationship commands still can't close the reasoning gap.

---

## Remaining Open Questions

1. **Cache invalidation** — Should the cache be rebuilt every time the architecture-context is updated (git pull), or lazily on first query?
2. **Scope boundaries** — When an agent asks about a component that's RHEL AI or upstream-only, how verbose should the "not found" message be? Ann Marie's experience with Docling/Kagenti ("How do the bots know what's available?") suggests the message should explicitly state product scope and whether the component is known to exist outside RHOAI.
3. **Dev-Preview components** — Ann Marie noted the rule of thumb is to update arch-context between dev preview and tech preview. Should `arch-query` have a concept of component lifecycle stage (dev-preview, tech-preview, GA) and surface it in output?
4. **Upstream dependencies** — jtanner's gap analysis flagged missing Kubernetes operators, CRDs, Istio, and Kuadrant context. Should `arch-query` distinguish between "RHOAI component" and "platform dependency" in its responses, or is that out of scope?

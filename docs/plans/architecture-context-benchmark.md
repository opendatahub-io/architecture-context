# Architecture-Context Benchmark Design

**Generated**: 2026-05-03
**Purpose**: Define a corpus and evaluation framework for benchmarking the quality of `.context/architecture-context/` using MLflow experiment tracking and LLM-as-judge evaluation.
**Reference Data**: 9,260 traces / 102K+ spans from the pipeline's Elasticsearch indices, analyzed in `arch-context-bugs-2026-05-03.md`.

---

## Approach

The standard MLflow experiment pattern for evaluating LLM outputs:

1. Maintain a corpus of inputs (questions/tasks that depend on architecture-context)
2. Run agents against the corpus, recording outputs as MLflow traces
3. Have a judge agent score each response for quality
4. Track scores over time as architecture-context is updated

The trace data from production pipeline runs gives us something better than purely synthetic inputs — real agent queries with known outcomes (successes, failures, gap detections). The corpus is derived from these real interactions.

---

## Quality Signals in Trace Data

Architecture-context quality manifests in three measurable ways:

1. **Can the agent find what it's looking for?** — Path resolution, file existence, directory navigation
2. **Can the agent verify claims?** — Strategy and RFE assertions cross-referenced against component docs
3. **Does the agent flag gaps vs. hallucinate answers?** — Honest "not documented" vs. confabulated responses

---

## Corpus Structure

### Tier 1: Component Inventory Lookup (existence questions)

Tests whether the agent can correctly determine if a component is part of RHOAI.

Derived from the 45+ component docs on disk plus the 13 components agents flagged as missing in production traces.

**Example questions**:
- "Is InstructLab a RHOAI component?" (expected: no — it's RHEL AI)
- "Does RHOAI include a model registry?" (expected: yes — `model-registry.md`)
- "Is ai-gateway-payload-processing documented?" (expected: no)
- "Is CodeFlare SDK in the RHOAI 3.4-ea.2 component inventory?" (expected: no — overlay 0004 documents this gap)
- "Does the architecture context cover RHAIIS deployment tooling?" (expected: no — only OCP-based RHOAI)

**Ground truth source**: `ls *.md` in the version directory + `PLATFORM.md` component list.

**What it catches**: Inventory staleness, product scope confusion.

**Estimated size**: ~50 questions (one per existing component + one per known-missing component).

### Tier 2: Component Fact Extraction (detail questions)

Tests whether the agent can extract specific technical facts from component docs.

Derived from the 9 undocumented API/behavior gaps found in production traces, plus successful lookups where agents correctly extracted facts.

**Example questions**:
- "What port does vLLM expose metrics on?" (expected: 8000 — from `vllm-cpu.md`)
- "What CRDs does the rhods-operator manage?" (expected: list from `rhods-operator.md`)
- "Does trustyai-explainability document `trustyai_eval` metrics?" (expected: no — RHAISTRAT-662 gap)
- "Does odh-model-controller have RBAC for Jobs?" (expected: no — RHAISTRAT-124 finding)
- "What API groups does the Monitoring Controller manage?" (expected: `monitoring.rhobs`, `monitoring.coreos.com`, `perses.dev`)
- "What HTTP endpoints does the llama-stack-distribution expose on port 8321?" (expected: list from `llama-stack-distribution.md`)
- "Does eval-hub v0.2.0 define an Environment Card concept?" (expected: no — RHAISTRAT-210 gap)

**Ground truth source**: Extractable from component doc content. Requires one-time manual curation.

**What it catches**: Doc completeness within existing component files.

**Estimated size**: ~60 questions (mix of answerable + known-unanswerable).

### Tier 3: Cross-Component Integration (reasoning questions)

Tests whether the agent can reason across multiple component docs to validate architectural claims.

Derived from strategy review spans where agents had to cross-reference multiple docs to validate or refute strategy assertions.

**Example questions**:
- "Can KServe autoscale using KEDA custom metrics?" (requires reading `kserve.md` + checking for KEDA docs)
- "How does the monitoring controller discover PrometheusRules?" (requires `rhods-operator.md` + API group docs)
- "What's the request path from inference gateway through EPP to vLLM?" (requires `llm-d-inference-scheduler.md`, `kserve.md`, `vllm-cpu.md`)
- "Can Argo Workflows trigger data science pipeline runs?" (requires `argo-workflows.md` + `data-science-pipelines.md`)
- "Does the platform support AlertmanagerConfig CRDs for notification routing?" (requires checking all operator docs for RBAC — RHAISTRAT-410)
- "How do model registry and odh-model-controller interact for model deployment?" (requires `model-registry.md` + `odh-model-controller.md`)

**Ground truth source**: Requires manual curation from domain experts or validated strategy review outputs.

**What it catches**: Whether docs support multi-component reasoning, not just single-file lookups.

**Estimated size**: ~50 questions.

### Tier 4: Navigation & Structure (meta questions)

Tests whether the agent can navigate the architecture-context directory structure and find the right version of docs.

Derived directly from the 142 path-not-found errors in production traces.

**Example questions**:
- "Where are the current GA architecture docs?" (tests symlink resolution)
- "List all components in the latest released version" (tests version discovery)
- "What overlays modify the base architecture?" (tests overlay awareness)
- "What RHOAI versions have architecture docs available?" (tests directory enumeration)
- "Find the component doc for data-science-pipelines in the early-access version" (tests version + component lookup)

**Ground truth source**: The filesystem itself. Fully automatable.

**What it catches**: Broken symlinks, sparse-checkout gaps, directory convention confusion (e.g., the `components/` subdirectory that 53 agents tried but doesn't exist).

**Estimated size**: ~30 questions.

---

## Corpus Sourcing from Trace Data

Rather than inventing questions, the corpus should be mined from existing pipeline traces where we know the outcome.

| Source | How to Extract | Corpus Size | Tier |
|--------|---------------|-------------|------|
| 142 failed path lookups | Bash span `inputs` where `outputs` contained "not found" / "cannot access" / "DIR NOT FOUND" | ~30 unique navigation queries | Tier 4 |
| 42 "absent from" LLM findings | Sentences from LLM span `outputs` where agents flagged missing components | ~35 existence/detail queries | Tier 1, 2 |
| Successful `tool_Read` spans on architecture-context files | Extract the file path + what the agent looked for from surrounding LLM span context | ~100 fact extraction queries | Tier 2 |
| Strategy review outputs citing architecture docs | Claim-verification pairs from feasibility/architecture review sub-skills | ~50 integration queries | Tier 3 |

**Total estimated corpus size**: 200-215 questions with ground truth.

### Extraction Queries

```bash
# Tier 4: Failed path lookups
curl -s 'http://elasticsearch:9200/mlflow-spans/_search' \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 200,
    "query": {"bool": {"must": [
      {"term": {"name": "tool_Bash"}},
      {"match_phrase": {"inputs": "architecture-context"}},
      {"bool": {"should": [
        {"match_phrase": {"outputs": "No such file"}},
        {"match_phrase": {"outputs": "DIR NOT FOUND"}},
        {"match_phrase": {"outputs": "cannot access"}}
      ], "minimum_should_match": 1}}
    ]}},
    "_source": ["trace_id", "issue_keys", "inputs", "outputs"]
  }'

# Tier 1/2: Components flagged as absent
curl -s 'http://elasticsearch:9200/mlflow-spans/_search' \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 50,
    "query": {"bool": {"must": [
      {"term": {"name": "llm"}},
      {"bool": {"should": [
        {"match_phrase": {"outputs": "absent from"}},
        {"match_phrase": {"outputs": "not in the architecture"}},
        {"match_phrase": {"outputs": "not documented in"}},
        {"match_phrase": {"outputs": "not in RHOAI"}},
        {"match_phrase": {"outputs": "not in the component inventory"}}
      ]}}
    ]}},
    "_source": ["trace_id", "issue_keys", "outputs"]
  }'

# Tier 2: Successful reads of architecture-context files
curl -s 'http://elasticsearch:9200/mlflow-spans/_search' \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 200,
    "query": {"bool": {"must": [
      {"term": {"name": "tool_Read"}},
      {"match_phrase": {"inputs": "architecture-context"}}
    ], "must_not": [
      {"exists": {"field": "error"}}
    ]}},
    "_source": ["trace_id", "issue_keys", "inputs"]
  }'

# Tier 3: Architecture review sub-skill outputs
curl -s 'http://elasticsearch:9200/mlflow-spans/_search' \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 50,
    "query": {"bool": {"must": [
      {"term": {"name": "tool_Skill"}},
      {"match": {"inputs": "architecture-review"}}
    ]}},
    "_source": ["trace_id", "issue_keys", "inputs", "outputs"]
  }'
```

---

## Judge Rubric

For each corpus question, the judge agent scores the response on four dimensions (1-5 scale each):

### 1. Factual Accuracy (does the answer match the docs?)
- **5**: All facts correct, matches doc content exactly
- **4**: Minor imprecision but no wrong facts
- **3**: Mostly correct with one factual error
- **2**: Multiple factual errors
- **1**: Answer is substantially wrong

### 2. Grounding (does it cite specific sources?)
- **5**: Cites specific file path and section
- **4**: Cites file path but not specific section
- **3**: References "the architecture docs" generically
- **2**: No citation, but answer is consistent with docs
- **1**: Makes claims with no basis in available docs

### 3. Scope Awareness (does it distinguish product boundaries?)
- **5**: Correctly identifies which product/project a component belongs to (RHOAI vs. RHEL AI vs. upstream-only)
- **4**: Correct scope but doesn't explicitly state it
- **3**: Ambiguous on scope
- **2**: Conflates RHOAI with adjacent products
- **1**: Attributes non-RHOAI components to RHOAI or vice versa

### 4. Gap Acknowledgment (does it handle missing info honestly?)
- **5**: Explicitly states "not documented" and suggests where to look
- **4**: States "not documented" without further guidance
- **3**: Hedges ("may not be documented", "I couldn't find")
- **2**: Silently skips the gap
- **1**: Fabricates an answer for undocumented content

### Composite Score

`quality = (accuracy * 0.4) + (grounding * 0.2) + (scope * 0.2) + (gap_acknowledgment * 0.2)`

Weighted toward accuracy since that's the primary purpose of architecture-context.

---

## Experiment Tracking

Each benchmark run is an MLflow experiment:

- **Experiment name**: `arch-context-benchmark`
- **Run name**: `benchmark-{architecture-context-commit-hash}-{date}`
- **Logged metrics**: Per-question scores, per-tier aggregates, composite score
- **Logged artifacts**: Full question-answer-judgment triples, corpus version
- **Tags**: Architecture-context version, RHOAI version, corpus version

### What Improvement Looks Like

| Change to architecture-context | Expected Score Impact |
|-------------------------------|----------------------|
| Fix broken symlinks | Tier 4 scores jump from ~1 to ~5 |
| Add missing component docs (SDG Hub, Kagenti, etc.) | Tier 1 existence scores improve; Tier 2 detail scores improve for those components |
| Document undocumented APIs (trustyai metrics, OGX post-training) | Tier 2 detail scores improve for specific questions |
| Add cross-reference sections to component docs | Tier 3 integration scores improve |
| Add `components/` subdirectory or README convention note | Subset of Tier 4 navigation errors eliminated |

---

## Baseline Expectations

Based on the production trace analysis:

| Tier | Expected Baseline Score | Rationale |
|------|------------------------|-----------|
| Tier 1: Inventory | ~3.5/5 | 45 components documented, 13 missing — agents get most right but stumble on edge cases |
| Tier 2: Details | ~3.0/5 | Component docs exist but have undocumented APIs/behaviors (9 known gaps) |
| Tier 3: Integration | ~2.5/5 | Cross-component reasoning requires info scattered across files; some relationships undocumented |
| Tier 4: Navigation | ~2.0/5 | 4 of 6 symlinks broken, `components/` convention confusion widespread |
| **Overall** | **~2.8/5** | Dragged down by structural issues (Tier 4) and integration gaps (Tier 3) |

---

## Recommendations

### 1. Acknowledge Tier Cascade Dependencies

Tier 4 (navigation) scores lowest in the baseline yet is listed last. If the agent can't find the files, Tiers 1–3 results are meaningless. Either reorder tiers so navigation is evaluated first, or add an explicit note in the Approach section that Tier 4 failures cascade — a Tier 4 score below a threshold (e.g., 3.0) should flag the entire run as unreliable regardless of other tier scores.

### 2. Validate the LLM Judge

The rubric defines scoring anchors but does not specify:

- **Which model** serves as judge (should differ from the agent under test to avoid self-evaluation bias).
- **Human calibration**: Score a subset of 20–30 questions by hand and measure agreement with the judge. Report Cohen's kappa or percent agreement as a baseline.
- **Drift detection**: Re-run the human-scored subset periodically. If judge-human agreement drops below a threshold, recalibrate before trusting new benchmark results.

### 3. Separate Gap Detection from Remediation Guidance

The Gap Acknowledgment dimension (score of 5) currently requires both identifying a gap *and* suggesting where to look. These are independent capabilities. Suggested revision:

- **5**: Explicitly states "not documented"
- **4**: Hedges but clearly communicates uncertainty
- **3**: Silently skips the gap
- **2**: Fabricates a partial answer
- **1**: Fabricates a confident answer for undocumented content

Remediation guidance ("try the upstream repo", "check the RFE tracker") could be scored as a separate bonus dimension or tracked as a tag rather than penalizing agents that correctly identify gaps but have no basis for suggesting alternatives.

### 4. Define Corpus Maintenance Process

The document describes initial corpus construction but not ongoing maintenance. As architecture-context evolves:

- **Ground truth staleness**: When a component doc is added or a gap is filled, previously "expected: no" answers become "expected: yes". Define who reviews and updates ground truth, and how often (e.g., after each architecture-context release).
- **Corpus versioning**: Tag each corpus version alongside the architecture-context commit it was validated against. Log the corpus version as an MLflow tag (already mentioned) but also store the corpus in version control so diffs are reviewable.
- **Retirement criteria**: Questions derived from fixed bugs (e.g., broken symlinks) become trivially passing after the fix. Keep them as regression tests but don't let them inflate tier scores — consider separating "regression" questions from "capability" questions in score aggregation.

### 5. Require Ground Truth Access for the Judge

The judge must compare the agent's answer against the actual doc content, not evaluate plausibility in isolation. Without ground truth access, a confident hallucination can score 5 on accuracy. Each corpus entry should include:

- The question
- The expected answer (or "not documented" for gap questions)
- The source file path and relevant excerpt

The judge prompt should instruct: "Score accuracy by comparing against the provided ground truth, not by assessing whether the answer sounds reasonable."

### 6. Specify Deduplication for Corpus Extraction

The Tier 4 extraction query returns up to 200 spans but estimates ~30 unique questions. The dedup strategy should be explicit:

- Normalize file paths (strip leading `./`, resolve symlinks, collapse repeated separators).
- Group by target component name rather than exact path string — multiple agents hitting `/components/kserve/` vs. `/kserve.md` vs. `./architecture-context/components/kserve` are testing the same navigation failure.
- For Tier 2 successful reads, dedup by (component, fact extracted) to avoid 50 questions that all ask "what port does X use."

### 7. Document Benchmark Execution Environment

The experiment tracking section describes what gets logged but not how the benchmark runs. Specify:

- **Agent configuration**: Which model, system prompt, and tool set. Must match production or differences must be documented.
- **Architecture-context mount**: The agent should see the same directory structure as production agents (same symlinks, same sparse-checkout state).
- **Isolation**: Each question should be a fresh agent session to avoid context leakage between questions.
- **Reproducibility**: Pin the model version, temperature (0 for deterministic scoring), and any retrieval parameters.

### 8. Track Per-Tier Minimums as Quality Gates

The composite score can mask regressions — a Tier 4 collapse hidden behind Tier 1/2 improvements. In addition to the composite:

- Set per-tier minimum thresholds (e.g., no tier below 2.5 for a passing run).
- Track per-tier trends over time as separate MLflow metrics, not just the composite.
- Alert on any tier dropping more than 0.5 points between runs, even if the composite holds steady.

### 9. Clarify Cross-References

- The reference to `arch-context-bugs-2026-05-03.md` (line 6) should specify its location (e.g., `docs/arch-context-bugs-2026-05-03.md`) so readers can find the source data.
- Overlay references (e.g., "overlay 0004" in Tier 1 examples) should include the overlay path pattern (e.g., `overlays/0004-*.md`) for readers unfamiliar with the convention.
- The `components/` subdirectory finding (53 agents tried a path that doesn't exist) is valuable evidence — consider linking to the trace query or bug report that documents it.

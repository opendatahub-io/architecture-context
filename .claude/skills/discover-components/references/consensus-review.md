# Multi-Reviewer Consensus for Low-Confidence Repos

After Step 6, you will have repos that fall into **low or medium confidence** buckets — they have some signals suggesting they're shipped components but not enough for a definitive classification. Instead of making a single-pass decision on these borderline repos, use a **multi-reviewer consensus** process to reduce false positives and false negatives.

**When to trigger consensus review:**

In **breadcrumb mode** (no release payload signals): repos classified as "Low confidence" or "Medium confidence" in Step 6.

In **manifest mode**: repos in the `excluded` list that match ANY of these patterns:
- Repo name matches a container image referenced by an included operator (potential operand)
- Repo name suggests a runtime component (contains `server`, `runtime`, `gateway`, `proxy`, `scheduler`)
- Repo contains a Dockerfile/Containerfile AND Kubernetes manifests but wasn't in the manifest script
- Repo is in the same GitHub org as included components and has recent activity

**Skip consensus** for repos that are clearly non-components (docs-only, CI tooling, archived). Only spend reviewer cycles on genuinely ambiguous cases.

## Consensus Procedure

For each borderline repo, spawn **3 independent reviewer agents in parallel** using the Task tool with `subagent_type=Explore`. Each reviewer examines the same repo but through a different evaluation lens:

**Reviewer A — Structural Analysis:**
```
Examine the repo at {checkout_path}. Determine whether this repo is a shipped
platform component based on its STRUCTURE. Look for:
- Dockerfile/Containerfile (builds a container image?)
- Kubernetes manifests, Helm charts, kustomize overlays (deployed to a cluster?)
- Operator patterns: main.go/cmd/, controller-runtime imports, CRD definitions
- Service patterns: API server code, gRPC/REST endpoints, daemon entrypoints
- Asset patterns: static content only, no running code

Return a JSON object with exactly these fields:
{
  "vote": "include" | "exclude" | "unsure",
  "suggested_type": "operator" | "controller" | "service" | "ui" | "asset" | "shared_library" | "other",
  "rationale": "<one sentence explaining your reasoning>"
}
```

**Reviewer B — Relational Analysis:**
```
Examine the repo at {checkout_path}. Determine whether this repo is a shipped
platform component based on its RELATIONSHIPS to other components. Check:
- Is this repo's name referenced as a container image in any included operator's
  manifests, CSV, or source code? (Search the operator repos for image refs matching
  this repo name)
- Does this repo's go.mod / requirements.txt import or get imported by included components?
- Is this repo referenced in CI/CD configs of included components?
- Does this repo define CRDs that included operators reconcile?

The included operators are: {list of already-included component keys}

Return a JSON object with exactly these fields:
{
  "vote": "include" | "exclude" | "unsure",
  "suggested_type": "operator" | "controller" | "service" | "ui" | "asset" | "shared_library" | "other",
  "rationale": "<one sentence explaining your reasoning>",
  "referenced_by": ["<list of components that reference this repo, if any>"]
}
```

**Reviewer C — Functional Analysis:**
```
Examine the repo at {checkout_path}. Determine whether this repo is a shipped
platform component based on its FUNCTION — what does it actually do at runtime?
- Read the README, top-level docs, and main entrypoint to understand the repo's purpose
- Is this a production runtime workload (serves traffic, processes data, manages resources)?
- Is this a development/build tool (used during CI/CD but not deployed to production)?
- Is this a test utility, documentation repo, or helper script collection?
- Is this a serving runtime or model server (deployed by an operator on demand)?

Return a JSON object with exactly these fields:
{
  "vote": "include" | "exclude" | "unsure",
  "suggested_type": "operator" | "controller" | "service" | "ui" | "asset" | "shared_library" | "other",
  "rationale": "<one sentence explaining your reasoning>"
}
```

## Aggregating Votes

After all three reviewers return, aggregate their votes:

| Votes | Decision | Confidence |
|-------|----------|------------|
| 3/3 include | Include the repo | `"high"` |
| 3/3 exclude | Exclude the repo | `"high"` |
| 2/3 include | Include the repo | `"medium"` |
| 2/3 exclude | Exclude the repo | `"medium"` |
| 3-way split or all unsure | Include the repo, flag for human review | `"disputed"` |

For the `suggested_type`, use the majority type if 2+ reviewers agree. If all three suggest different types, prefer the structural reviewer's suggestion (Reviewer A) as the tiebreaker since it's based on concrete repo contents.

## Recording Consensus Results

For repos that go through consensus review, add a `consensus` field to their entry in the component map:

```json
{
  "confidence": "high|medium|disputed",
  "consensus": {
    "votes": {"include": 2, "exclude": 1},
    "reviewers": {
      "structural": {"vote": "include", "type": "service", "rationale": "Has Dockerfile and kustomize manifests for production deployment"},
      "relational": {"vote": "include", "type": "service", "rationale": "Image referenced by data-science-pipelines-operator CSV"},
      "functional": {"vote": "exclude", "type": "other", "rationale": "Operand binary only, no standalone deployment lifecycle"}
    }
  }
}
```

For repos excluded via consensus, move them to the `excluded` section but preserve the consensus data:

```json
"excluded": {
  "some-repo": {
    "reason": "consensus_exclude",
    "confidence": "medium",
    "consensus": {
      "votes": {"include": 1, "exclude": 2},
      "reviewers": {
        "structural": {"vote": "include", "type": "service", "rationale": "..."},
        "relational": {"vote": "exclude", "type": "other", "rationale": "..."},
        "functional": {"vote": "exclude", "type": "other", "rationale": "..."}
      }
    }
  }
}
```

Repos excluded with `"confidence": "disputed"` or `"medium"` should be highlighted in the Step 10 summary so the user knows to review them.

## Performance Notes

- Launch all 3 reviewers for a single repo in parallel (single message with 3 Task tool calls)
- If multiple repos need consensus review, batch them: review up to 3 repos concurrently (9 parallel agents total) to avoid excessive parallelism
- Use `model: "haiku"` for reviewer agents to minimize cost and latency — the structural/relational/functional checks are straightforward exploration tasks
- If the checkouts directory has more than 20 borderline repos, prioritize: review repos with names matching included operators' image references first, then repos with Dockerfiles + manifests, then the rest

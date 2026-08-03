# Task: Reduce MLflow Discovery Churn

## Goal

Reduce redundant bounded discovery calls during partial-route synthesis while
preserving source-backed gap coverage and evidence-gated output.

## Evidence

The MLflow replay at
`tmp/architecture-corpus-runs/rhoai.next-20260802T182238Z-2696509/logs/agents-mlflow-auth-contract/`
completed with valid output and zero merge rejections, but spent 25 targeted
discovery calls and exceeded the soft discovery budget 20 times. The agent
repeated equivalent searches for `app_name`, `app-name`, `kubernetes-auth`,
`mlflow.app`, and related patterns after relevant files had been identified.

## Plan

1. [x] Add a generic bounded discovery protocol to the summary skill.
2. [x] Add skill-contract regression assertions.
3. [x] Identify remaining search-call overhead and missing analyzer navigation
   context.
4. [x] Add a generic entrypoint/plugin selector candidate to the analyzer
   authentication gap index.
5. [x] Replay MLflow with `./custom-test.sh` and compare discovery calls,
   soft-budget hits, runtime, and merge correctness.
6. [x] Fix the authentication row-key migration contract, then rerun the
   targeted MLflow replay.

The corrected replay completed in 338.1 seconds with 17 targeted discovery
calls, 13 soft-budget hits, 7 targeted source reads, zero source-budget hits,
zero merge rejections/restorations, and a 1.0 source-read justification ratio.
This beats the original 25-call/20-hit baseline while preserving the intended
authentication split.

## Acceptance Criteria

- The agent uses a bounded search plan per declared gap.
- Equivalent searches are not repeated after the relevant evidence is found.
- The replay has zero merge rejections and valid source-read justifications.
- Discovery calls and soft-budget hits decline without reducing evidence quality.

## Status

Complete. The corrected MLflow replay satisfies the acceptance criteria and
validates the authentication split.

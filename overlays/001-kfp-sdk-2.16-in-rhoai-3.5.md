---
id: "001"
title: KFP SDK updated to 2.16 in RHOAI 3.5
status: active
created: 2026-04-20
affects:
  - data-science-pipelines
  - data-science-pipelines-operator
  - notebooks
release:
  - "3.5"
provenance:
  - https://github.com/opendatahub-io/data-science-pipelines-operator/pull/1007
superseded_by: null
---

## Fact

KFP SDK was updated from 2.15 to 2.16 in RHOAI 3.4, shipped in the data-science-pipelines-operator via PR #1007.

## Impact on Strategies

- Reference KFP SDK **2.16**, not 2.15, for RHOAI 3.5 strategies
- The v2beta1 REST API surface is unchanged; the SDK update is a client-side change
- Notebook images that bundle the KFP SDK (e.g., KALE workbench) should pin to 2.16
- Acceptance criteria referencing SDK version should specify 2.16

## Context

The architecture context docs were generated from rhoai-3.4 branches and still reference KFP SDK 2.15. The 3.5 branch has not been analyzed yet. This overlay bridges the gap until the architecture context is regenerated for 3.5.

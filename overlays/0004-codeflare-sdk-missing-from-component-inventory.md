---
id: "0004"
title: CodeFlare SDK missing from component inventory
status: active
created: 2026-05-01
affects:
  - platform
  - notebooks
release:
  - "3.4"
provenance:
  - https://github.com/opendatahub-io/architecture-context/issues/1
  - https://redhat.atlassian.net/browse/RHAIRFE-1542
author: Ana Biazetti
superseded_by: null
---

## Fact

CodeFlare SDK (codeflare-sdk) is a shipped RHOAI component that provides the Python API for submitting distributed training and inference jobs to Ray clusters managed by KubeRay. It is distributed as a pip dependency inside notebook workbench images. The PLATFORM.md component inventory does not list it, and no `codeflare-sdk.md` component architecture doc exists, because it lacks a standalone entry in `get_all_manifests.sh` — it ships as a transitive dependency inside notebook images rather than as its own operator or manifest component.

## Impact on Strategies

- Treat **codeflare-sdk** as a shipped RHOAI component, functionally related to KubeRay and Kueue (distributed training capabilities)
- RFEs targeting codeflare-sdk (e.g., multi-worker group support, Ray cluster configuration) should reference it as a first-class platform component, not an unowned library
- Feasibility and architecture reviewers should not flag codeflare-sdk ownership as unclear — it is shipped and supported
- The same pattern (SDK shipped as pip dependency in notebook images, absent from `get_all_manifests.sh` and the component inventory) may apply to other SDK components; absence from the inventory does not mean a component is unshipped

## Context

The architecture generation pipeline discovers components via three mechanisms: manifest parsing (`get_all_manifests.sh`), the operator itself, and adjacent repos in the checkout directory. codeflare-sdk has its own repo (`opendatahub-io/codeflare-sdk`) but is not declared in any manifest or controller, so the Phase 5 aggregation agent does not include it in the component inventory. The `notebooks.md` component doc mentions codeflare-sdk once as a network egress dependency but this does not propagate to the platform-level inventory. This caused a false warning in the rfe-creator feasibility review for RHAIRFE-1542, which flagged "CodeFlare SDK ownership is unclear (not listed as a shipped RHOAI component)."

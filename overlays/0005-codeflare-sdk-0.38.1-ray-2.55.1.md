---
id: "0005"
title: CodeFlare SDK 0.38.1 with Ray 2.55.1 in RHOAI 3.5
status: active
created: 2026-07-22
affects:
  - codeflare-sdk
  - notebooks
release:
  - "3.5"
provenance:
  - https://redhat.atlassian.net/browse/RHOAIENG-77841
author: Pat O Connor
superseded_by: null
---

## Fact

CodeFlare SDK 0.38.1 in RHOAI 3.5 GA includes a Ray runtime bump from 2.54.1 to 2.55.1, shipped via the notebook workbench images.

## Impact on Strategies

- Reference **codeflare-sdk 0.38.1** and **Ray 2.55.1** for RHOAI 3.5 strategies
- RFEs and architecture reviews targeting Ray capabilities should validate against Ray 2.55.1 APIs and behavior
- Notebook images in 3.5 will include the updated Ray runtime

## Context

The generated architecture context (rhoai-3.5) documents codeflare-sdk at v0.38.1 with Ray 2.55.1. The Ray version bump is complete and the released SDK will land in notebook images for the 3.5 GA milestone.

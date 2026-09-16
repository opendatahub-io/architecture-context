---
id: "0005"
title: CodeFlare SDK 0.39.1 with Ray 2.58.0 in RHOAI 3.6 EA2
status: active
created: 2026-09-16
affects:
  - codeflare-sdk
  - notebooks
release:
  - "3.6-ea2"
provenance:
  - https://redhat.atlassian.net/browse/RHOAIENG-93666
author: Pat O Connor
superseded_by: null
---

## Fact

CodeFlare SDK 0.39.1 in RHOAI 3.6 EA2 includes a Ray runtime bump from 2.55.1 to 2.58.0, shipped via the notebook workbench images.

## Impact on Strategies

- Reference **codeflare-sdk 0.39.1** and **Ray 2.58.0** for RHOAI 3.6 EA2 strategies
- RFEs and architecture reviews targeting Ray capabilities should validate against Ray 2.58.0 APIs and behavior
- Notebook images in 3.6 EA2 will include the updated Ray runtime

## Context

The generated architecture context (rhoai-3.6 EA2) documents codeflare-sdk at v0.39.1 with Ray 2.58.0. The Ray version bump is complete and the released SDK will land in notebook images for the 3.6 EA2 milestone.

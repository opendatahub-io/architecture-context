---
id: "0005"
title: CodeFlare SDK 0.38.0 with Ray 2.55.1 in RHOAI 3.5
status: active
created: 2026-05-12
affects:
  - codeflare-sdk
  - notebooks
release:
  - "3.5"
provenance:
  - https://redhat.atlassian.net/browse/RHOAIENG-60340
author: Bryan Keane
superseded_by: null
---

## Fact

CodeFlare SDK is updated from v0.37.0 to v0.38.0 in RHOAI 3.5. This includes a Ray runtime bump from 2.53.0 to 2.55.1, shipped via the notebook workbench images.

## Impact on Strategies

- Reference **codeflare-sdk 0.38.0** and **Ray 2.55.1** for RHOAI 3.5 strategies
- RFEs and architecture reviews targeting Ray capabilities should validate against Ray 2.55.1 APIs and behavior
- Notebook images in 3.5 will include the updated SDK and Ray runtime

## Context

The generated architecture context (rhoai-3.4) documents codeflare-sdk at v0.37.0 with Ray 2.53.0. The version bump is in progress across multiple PRs and will land for the 3.5-ea.1 milestone.

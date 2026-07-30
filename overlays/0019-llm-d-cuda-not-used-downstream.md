---
id: "0019"
title: llm-d-cuda image is replaced downstream, not shipped as-is
status: active
created: 2026-07-30
affects:
  - llm-d
  - kserve
  - vllm
release:
  - "all"
provenance:
  - https://github.com/red-hat-data-services/kserve/blob/main/config/overlays/odh/params.env
  - https://github.com/opendatahub-io/architecture-context (AIPCC ADR0120, ADR0144)
author: Kyle Lape
superseded_by: null
---

## Fact

Upstream `llm-d-cuda` builds its own vLLM + HPC libraries (nixl, DeepEP, DeepGEMM, NVSHMEM, UCX) from source. That
image is never deployed downstream: `red-hat-data-services/kserve`'s `config/overlays/odh/params.env` replaces the
`llm-d-cuda` reference with RHAIIS's own AIPCC-built image (`registry.redhat.io/rhaiis/vllm-cuda-rhel9`, and
per-accelerator equivalents for ROCm/Gaudi/Spyre) for every accelerator llm-d supports. RHAIIS's image already
bundles the same HPC libraries, tracked via their own ADR process (e.g. AIPCC ADR0144, "LLM-D v0.4 update for CUDA").

## Impact on Strategies

- Strategies proposing changes to the upstream `llm-d-cuda` Dockerfile (new build args, arch-list bumps, new build
  targets) are changing an artifact RHOAI doesn't ship. Route that work to RHAIIS's AIPCC build process instead.
- New-accelerator-support strategies for llm-d should scope the llm-d team's work as validating against the
  RHAIIS-built image, not building or productizing a container image.
- Konflux-pipeline-gap findings for `llm-d-cuda` are moot for RHOAI productization -- the image isn't in the
  downstream deploy path at all.

## Context

The generated architecture docs for `llm-d` describe the upstream Dockerfile build in isolation and don't capture
the downstream `params.env` substitution that replaces it. This gap led a strategy (RHAISTRAT-1485) to scope Vera
Rubin container-image work against the wrong artifact.

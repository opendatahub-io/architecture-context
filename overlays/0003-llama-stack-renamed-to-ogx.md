---
id: "0003"
title: Llama Stack renamed to OGX upstream and adopted in RHOAI 3.5
status: active
created: 2026-04-29
affects:
  - llama-stack-distribution
  - llama-stack-k8s-operator
  - llama-stack-provider-ragas
  - llama-stack-provider-trustyai-garak
release:
  - "3.5"
provenance:
  - https://ogx-ai.github.io/blog/from-llama-stack-to-ogx
author: Eder Ignatowicz
superseded_by: null
---

## Fact

Llama Stack has been renamed to OGX upstream. The rename reflects that the project supports 23 inference providers (not just Meta Llama models) and is an HTTP server with pluggable providers, not a framework library. RHOAI has already adopted the OGX naming for 3.5. Key changes: source dirs `llama_stack/` → `ogx/`, CLI `llama` → `ogx`, env vars `LLAMA_STACK_*` → `OGX_*`, HTTP headers `x-llamastack-*` → `x-ogx-*`, GitHub org moved to `ogx-ai`, package `llama-stack` → `ogx`. The HTTP API itself is unchanged.

## Impact on Strategies

- The technical content in the architecture context files (`llama-stack-distribution.md`, `llama-stack-k8s-operator.md`, etc.) remains accurate — APIs, provider architecture, and component interactions are unchanged
- When writing new strategies for RHOAI 3.5, use **OGX (formerly Llama Stack)** naming for component names, CLI references, and env vars. Keep "(formerly Llama Stack)" in parentheses on first mention to help readers during the transition
- Map naming in architecture context: `llama_stack/` → `ogx/`, `LLAMA_STACK_*` → `OGX_*`, CLI `llama` → `ogx`, headers `x-llamastack-*` → `x-ogx-*`
- GitHub references for upstream should use the `ogx-ai` organization
- The HTTP API is unchanged — REST endpoints (e.g., `/v1/chat/completions`) and their behavior remain valid as documented

## Context

The generated architecture context (rhoai-3.4-ea.2) documents four Llama Stack components using the pre-rename naming. The technical architecture described in those files is still correct; only the project and package naming has changed. This overlay provides the naming mapping so strategies use current terminology.

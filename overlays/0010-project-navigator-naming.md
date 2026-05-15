---
id: "0010"
title: Project Navigator naming history and repo mapping
status: active
created: 2026-05-14
affects:
  - rhoai-mcp
  - llm-d-planner
release:
  - "3.4"
  - "3.4-ea.2"
  - "3.5"
  - "3.5-ea.1"
  - "next"
provenance:
  - https://issues.redhat.com/browse/RHAIFIRST-23
author: James Tanner
superseded_by: null
---

## Fact

"Project Navigator" is a feature that has used several names during development:

| Name | Context |
|------|---------|
| NeuralNav | Original internal codename (still referenced in codebase) |
| Project Navigator | Jira component name and stakeholder-facing name |
| llm-d planner | Current product direction name |

The feature consists of two repositories:

| Repo | Org | Role |
|------|-----|------|
| rhoai-mcp | opendatahub-io | Frontend — MCP (Model Context Protocol) server for RHOAI |
| llm-d-planner | llm-d-incubation | Backend — planning and orchestration engine |

Neither repository has RHOAI release branches; both are cloned from `main` via `extra_repos`. The feature entered Developer Preview in RHOAI 3.4, is planned for Tech Preview in 3.5, and should be treated as Tech Preview for `next` unless superseded by a later overlay.

## Impact on Strategies

- All three names (NeuralNav, Project Navigator, llm-d planner) refer to the same feature — strategies should use **Project Navigator** as the primary name with "(also known as llm-d planner)" on first mention
- Architecture context for this feature is split across two repos; strategies should consider `rhoai-mcp` and `llm-d-planner` together as a single logical feature
- The feature is DP in 3.4 and planned TP in 3.5 — strategies should reflect the appropriate maturity level for each release

## Context

The rfe-creator bot could not find "Project Navigator" in the platform inventory because the component discovery pipeline indexes by repository name (`rhoai-mcp`, `llm-d-planner`), not by marketing or codename. This overlay bridges the naming gap so that queries using any of the three names can locate the correct architecture context.

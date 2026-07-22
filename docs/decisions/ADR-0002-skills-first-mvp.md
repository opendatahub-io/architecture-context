# ADR-0002: Use Claude Code Skills for MVP Instead of Custom Agents

## Status

Accepted

## Date

2026-03-12

## Context

The original proposal (ADR-0001) described building custom Python agents with the Anthropic SDK for component analysis, platform aggregation, and diagram generation. This would require significant infrastructure: agent frameworks, error handling, prompt engineering pipelines, and deployment tooling.

The proposal also identified a "Skills-Based MVP" alternative: use Claude Code's built-in skill system (prompt files in `.claude/skills/`) to prototype the pipeline before investing in custom agent infrastructure.

The key question was whether to start with production-grade agents or validate the approach first with minimal tooling.

## Decision

Start with Claude Code skills as the implementation layer. Create five skills:

1. `repo-to-architecture-summary` - Analyze a single component repo and generate structured markdown
2. `aggregate-platform-architecture` - Combine component summaries into platform-level docs
3. `discover-platform-components` - Auto-discover components from manifests and operators
4. `generate-architecture-diagrams` - Generate Mermaid, C4, and security diagrams from architecture docs
5. `analyze-running-cluster` - QA generated docs against a deployed cluster

Skills are prompt files (SKILL.md), not code. They leverage Claude Code's existing code analysis, file I/O, and git capabilities without requiring custom infrastructure.

## Consequences

Positive:
- Validated the approach in days, not months
- Generated real architecture docs for stakeholder review before committing to automation
- Skills are version-controlled, reviewable, and iterable
- Zero infrastructure to maintain during the prototype phase
- The skills themselves became the production implementation (never replaced by custom agents)

Negative:
- Manual invocation per component during early prototype (addressed later by the Python orchestrator, ADR-0003)
- Skills have limited programmatic control compared to custom agents (no structured error handling, retry logic)

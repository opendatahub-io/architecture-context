# ADR-0008: Pure Skill Invocation for Pipeline Phases

## Status

Accepted

## Date

2026-04-28

## Context

Pipeline phases initially constructed prompts by extracting sections from SKILL.md files, templating in runtime data, and passing the result as a raw prompt to the agent runner. This approach was fragile: it required manual prompt assembly, broke when SKILL.md structure changed, and couldn't leverage Claude Code's built-in skill features (tool access, file I/O patterns).

## Decision

Convert all pipeline phases to pure skill invocation: instead of extracting and templating SKILL.md content, invoke skills as slash commands (e.g., `/repo-to-architecture-summary`, `/aggregate-platform-architecture`) with `enable_skills=True` in the agent runner. Runtime context (component paths, build metadata, kustomize overlays) is passed as the prompt prefix, and the skill handles the rest.

Phases converted: architecture generation, platform aggregation, diagram generation, and discover-components.

## Consequences

Positive:
- Skills are the single source of truth for analysis logic (no duplicate prompt fragments in orchestrator code)
- Skills can be invoked manually via Claude Code for debugging or one-off analysis
- Skill updates automatically apply to pipeline runs without orchestrator changes
- Agents get full Claude Code tool access (file reads, grep, git) through the skill layer

Negative:
- Debugging requires understanding both the orchestrator's prompt prefix and the skill's instructions
- `enable_skills=True` increases agent startup time slightly

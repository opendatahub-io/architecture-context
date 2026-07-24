# Agent Work Ledger

A filesystem-native project management system designed for AI agents working on large projects.

## Goals

- Decompose large projects into durable work items.
- Allow multiple agents to collaborate asynchronously.
- Preserve reasoning, discoveries, and decisions.
- Make project state visible in git history.
- Reduce context-window pressure by storing state in files.
- Prevent agents from declaring success without recording evidence.

---

# Core Principles

## 1. PLAN.md is an Index

`PLAN.md` should not contain the entire project plan.

Instead, it acts as a navigation hub that links to phases, milestones, tasks, bugs, and architectural decisions.

## 2. Tasks are Files

Every meaningful task gets its own markdown file.

Benefits:

- Easy for agents to claim work.
- Easy to review in pull requests.
- Easy to move between states.
- Durable across sessions.

## 3. State is Represented by Location

Task status is determined by directory placement.

Example:

- tasks/pending/
- tasks/current/
- tasks/blocked/
- tasks/done/

Moving a file changes its state.

## 4. Decisions are Recorded

Architectural decisions should be captured as ADRs.

Never rely solely on chat history.

## 5. Bugs are First-Class Artifacts

Bugs discovered during implementation should be recorded immediately.

Even if not fixed.

---

# Recommended Layout

```text
AGENTS.md
PLAN.md

docs/
  plans/
    000-overview.md
    phase-01-foundation.md
    phase-02-core-loop.md
    phase-03-ui.md

  milestones/
    M1-bootstrap.md
    M2-runner-api.md
    M3-job-logs.md

  tasks/
    pending/
    current/
    blocked/
    done/

  bugs/
    open/
    fixed/
    wontfix/

  decisions/
    ADR-0001-example.md

  notes/
    session-log.md
```

---

# AGENTS.md

Contains repository-specific instructions.

Examples:

- coding standards
- testing requirements
- deployment procedures
- repository conventions
- ownership rules

This file is the operational handbook for agents.

---

# PLAN.md

Example:

```md
# Project Plan

## Current Milestone

- M2 Runner API

## Active Tasks

- docs/tasks/current/job-create-api.md
- docs/tasks/current/job-log-storage.md

## Open Bugs

- docs/bugs/open/stdout-timeout.md

## Decisions

- docs/decisions/ADR-0003-use-postgres.md
```

---

# Task Template

```md
# Task: Persist Execution Logs

## Goal

Store stdout, stderr, exit code, timestamps, and metadata.

## Context

Needed to verify execution actually occurred.

## Acceptance Criteria

- [ ] Logs stored
- [ ] Logs viewable
- [ ] Exit code persisted
- [ ] Tests added

## Files Likely Involved

- runner/api.go
- web/jobs.tsx

## Status

Current

## Notes

Append discoveries here.
```
---

# Bug Template

```md
# Bug: Runner Drops Stdout

## Summary

Runner loses stdout during timeout handling.

## Reproduction

1. Execute long-running job
2. Timeout after N seconds
3. Observe missing stdout

## Expected

Captured output retained.

## Actual

Output lost.

## Impact

Medium

## Related Tasks

- task-log-persistence.md
```
---

# ADR Template

```md
# ADR-0001: Use Go Binary

## Status

Accepted

## Context

Agent containers cannot reliably install packages.

## Decision

Implement as a standalone Go binary.

## Consequences

Positive:
- Simple deployment
- No runtime dependency installation

Negative:
- Additional build pipeline
```
---

# Session Log

Agents should append activity to a shared session log.

Example:

```md
## 2026-06-01

Agent: implementation-agent

Completed:
- Added job creation API

Discovered:
- Missing database index

Created:
- bug-db-index.md

Next:
- Implement log persistence
```
---

# Agent Workflow

1. Read AGENTS.md
2. Read PLAN.md
3. Select a task from pending/
4. Move task into current/
5. Execute work
6. Record discoveries
7. Create bug files when needed
8. Update ADRs if decisions are made
9. Move task to done/ or blocked/
10. Update PLAN.md

---

# Multi-Agent Workflow

Coordinator Agent:

- Maintains PLAN.md
- Creates milestones
- Decomposes work
- Assigns tasks

Worker Agents:

- Execute task files
- Record findings
- Create bugs
- Update status

Reviewer Agent:

- Verifies acceptance criteria
- Confirms tests
- Rejects incomplete work

---

# Success Criteria

A project is healthy when:

- Every active task exists as a file.
- Bugs are tracked immediately.
- Architectural decisions are documented.
- Project status can be understood without chat history.
- Agents can resume work after losing all context.
- Git history provides a complete project timeline.

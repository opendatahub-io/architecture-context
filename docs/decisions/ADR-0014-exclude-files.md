# ADR-0014: Declarative exclude_files for Sensitive Repo Content

## Status

Accepted

## Date

2026-05-14

## Context

Some component repositories contain confidential data (e.g., `models-perf-benchmark-data` with internal benchmark results) that must not leak into public architecture documentation. The architecture agents analyze all files in a checkout, so sensitive content would be included in generated docs unless filtered.

Options considered:
1. Arbitrary shell commands for post-checkout cleanup (flexible but dangerous)
2. Declarative file patterns in platforms.yaml (safe, auditable)

## Decision

Add a declarative `exclude_files` mechanism to `platforms.yaml` entries. After cloning a repository, the harness deletes matched files and directories before the architecture skill reads the repo. Patterns are glob-style and scoped to the component's checkout directory.

Security hardening:
- Path traversal prevention (patterns cannot escape the checkout directory)
- Symlinked repo roots are rejected
- Bare-string patterns are rejected (must be list items)

## Consequences

Positive:
- Sensitive data is removed before agents see it, preventing accidental inclusion in architecture docs
- Declarative patterns are auditable in PR review (vs opaque shell commands)
- Hardened against path traversal and other abuse vectors

Negative:
- Excluded files are invisible to the architecture agent, potentially creating gaps in the generated docs
- Pattern maintenance required as repos add/remove sensitive content

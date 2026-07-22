# ADR-0010: arch-query Go CLI for Structured Architecture Queries

## Status

Accepted

## Date

2026-05-03

## Context

Agents and humans consuming the generated architecture data relied on `ls`, `grep`, and `cat` to navigate markdown files. This was slow, error-prone, and required understanding the directory structure. Common queries (list all ports for a component, find cross-component dependencies, compare versions) required multi-step navigation.

The architecture data was already structured (consistent markdown tables and sections), but there was no tool to extract and query it programmatically.

## Decision

Build `arch-query`, a purpose-built Go CLI that parses component and platform markdown into structured types and provides 15+ subcommands:

- `versions`, `list`, `component`, `search`, `grep`, `exists` for navigation
- `deps`, `deps --tree` for dependency analysis
- `crds`, `ports`, `webhooks` for infrastructure queries
- `images` for container image inventory
- `platform-summary`, `watches`, `schemas` for platform-wide views
- `diff` for cross-version comparison with platform-wide change aggregation
- `--output text|json|raw` for flexible output formatting

Go was chosen for:
- Fast startup (sub-second queries vs. Python interpreter overhead)
- Single binary distribution (no runtime dependencies)
- Embedded binary support (architecture data baked into the binary for portable distribution via GitHub Releases)

## Consequences

Positive:
- Sub-second queries replaced multi-minute agent-driven navigation
- Structured JSON output enables programmatic consumption by other tools and agents
- Embedded binary can be distributed without the full repository
- Platform aggregation skill uses arch-query for static analysis, improving platform docs quality

Negative:
- Dual-language codebase (Python orchestrator + Go CLI) increases maintenance burden
- Markdown parser is tightly coupled to the generated doc format; schema changes require parser updates
- Embedded binary needs rebuilding when architecture data changes

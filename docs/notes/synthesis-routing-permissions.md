# Synthesis Routing and Source-Read Permissions

The architecture-agent policy now exposes the plan's explicit route contract:

- `synthesis`: sufficient analyzer baseline, no source files, no discovery
  tools, and source reads denied by the execution guard.
- `partial`: category-specific gaps, bounded source-file budget, and only
  targeted `Glob`/`Grep` discovery.
- `legacy`: unknown or insufficient readiness fallback with existing behavior.

The architecture phase pre-seeds and merges both restricted routes, preserving
analyzer-owned facts and reviewed changes. Prompt arguments include the change
record for both synthesis and partial routes. The guard restricts both routes;
the test suite covers source denial, partial budgets, discovery denial, phase
merging, and route selection.

Validation: 42 focused tests passed; ruff and `git diff --check` passed.

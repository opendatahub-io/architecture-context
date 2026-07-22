# ADR-0006: platforms.yaml as Declarative Platform Configuration

## Status

Accepted

## Date

2026-04-27

## Context

The pipeline originally hardcoded platform details (GitHub org names, branch patterns, component exclusions) in the Python orchestrator. Adding a new RHOAI version or ODH platform required modifying Python code. Multiple RHOAI versions (2.25, 3.0, 3.2, 3.3, 3.4, 3.4-ea.1, 3.4-ea.2, 3.5-ea.1) needed distinct configurations with shared defaults.

## Decision

Introduce `platforms.yaml` as the single declarative configuration file for all pipeline runs. Each platform version entry defines:

- `orgs` and `extra_orgs`: GitHub organizations to clone
- `extra_repos`: Additional individual repositories
- `excludes`: Repos to skip
- `branch` and `suffix`: Version branch patterns
- `component_overrides`: Per-component configuration
- `exclude_files`: Sensitive file patterns to remove post-checkout

YAML anchors (`_rhoai_3x_common`) share configuration across versioned entries, reducing duplication. The `--platform` and `--version` CLI flags select which entry to use.

## Consequences

Positive:
- Adding a new RHOAI version is a YAML edit, not a code change
- Configuration is reviewable, diffable, and validated by `lint_platforms.py`
- YAML anchors eliminate duplication across similar versions
- Schema validation catches config typos in CI

Negative:
- YAML anchor syntax can be confusing for new contributors
- Complex override logic (component_overrides, exclude_files) requires documentation

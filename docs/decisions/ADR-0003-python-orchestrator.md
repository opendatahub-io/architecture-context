# ADR-0003: Python Orchestrator for Multi-Phase Pipeline

## Status

Accepted

## Date

2026-03-13

## Context

The skills-first MVP (ADR-0002) required manual invocation of each skill per component repository. With 70+ component repos across multiple RHOAI versions, manual invocation was not sustainable. The pipeline had multiple sequential phases (fetch repos, parse manifests, generate component architecture, collect outputs, aggregate platform docs, generate diagrams) that needed orchestration.

Options considered:
1. Shell scripts chaining skill invocations
2. Python CLI orchestrating the full pipeline
3. GitHub Actions workflow

## Decision

Build a Python CLI (`main.py`) using `claude-agent-sdk` to orchestrate the pipeline. The CLI provides subcommands for each phase and an `all` command that runs the full pipeline. Key design choices:

- **Phase-based architecture**: Each phase (fetch, discover, architecture, collect, platform, diagrams) is a separate subcommand that can run independently or as part of the full pipeline
- **Concurrent agent execution**: Component-level phases (architecture, diagrams) run agents in parallel with `--max-concurrent` control
- **Python with uv**: Managed with `uv` for reproducible dependency resolution (Python 3.13+)
- **Modular lib/ package**: Orchestrator logic split into `cli.py`, `phases.py`, `agent_runner.py`, `manifest_parser.py`, `kustomize_context.py`, `build_info.py`

## Consequences

Positive:
- Full pipeline runs automated from a single command (`uv run main.py all --platform rhoai --version 3.4`)
- Concurrent agent execution reduced wall-clock time significantly
- Phase independence allows re-running individual phases without repeating the full pipeline
- Python's ecosystem made it easy to add features (rich progress bars, YAML parsing, manifest analysis)

Negative:
- Requires Python 3.13+ and uv toolchain
- Agent runner depends on `claude-agent-sdk` which is an evolving API
- Orchestrator grew complex over time (phases.py reached 1000+ lines before being refactored into a package)

# AGENTS.md

Operational handbook for AI agents working in this repository.

## Project Overview

Automated pipeline that generates architecture documentation for OpenDataHub (ODH) and Red Hat OpenShift AI (RHOAI). The pipeline fetches component repos, analyzes them with Claude Code skills, and produces structured architecture summaries, diagrams, and overlays.

See [README.md](README.md) for pipeline details and [AGENT_USAGE.md](AGENT_USAGE.md) for consuming the generated architecture data.

## Work Management

This project uses the **Agentic Work Ledger** methodology. See [docs/notes/agentic_work_ledger.md](docs/notes/agentic_work_ledger.md) for the full spec.

Key rules:

1. Read [PLAN.md](PLAN.md) before starting work.
2. Tasks live in `docs/tasks/` — pick from `pending/`, move to `current/`, then `done/` or `blocked/`.
3. Record architectural decisions as ADRs in `docs/decisions/`.
4. File bugs immediately in `docs/bugs/open/`.
5. Append session activity to `docs/notes/session-log.md`.

## Languages and Tools

- **Python 3.13+** — pipeline code in `main.py` and `lib/`. Managed with `uv`.
- **Go 1.25** — `arch-query` CLI in `src/arch-query/`. Linted with `golangci-lint`.
- **Claude Code skills** — `.claude/skills/` for component analysis, aggregation, and diagram generation.

## Coding Standards

### Python

- Linter: `ruff` with rules E, F, W, I. Run `make lint-python`.
- Tests: `pytest` with `asyncio_mode = "strict"`. Tests in `tests/`.
- No type stubs required but type hints are preferred.

### Go

- Linter: `golangci-lint` with errcheck, govet, staticcheck, unused. Run `make lint-go`.
- Tests: `make test`.

## Testing

Run all checks:

```bash
make lint          # Python + Go + overlays + platforms + architecture docs
make test          # Go tests
uv run pytest      # Python tests
```

## Repository Conventions

- **architecture/** — generated output, organized by platform and version. Do not hand-edit.
- **overlays/** — manually authored architecture updates between regeneration cycles. See AGENT_USAGE.md for format.
- **checkouts/** — gitignored, exists only during pipeline runs.
- **scripts/** — pipeline helper scripts and linters.
- **platforms.yaml** — platform/version configuration for the pipeline.

## Key Make Targets

| Target | Purpose |
|---|---|
| `make lint` | Run all linters |
| `make test` | Run Go tests |
| `make build` | Build arch-query CLI |
| `make build-embedded` | Build arch-query with embedded data |

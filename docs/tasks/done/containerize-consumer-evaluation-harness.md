# Task: Containerize Consumer Evaluation Harness

## Goal

Run the consumer evaluation harness inside a Podman container with a clean home
directory, no Claude memories, no CLAUDE.md project context, and controlled
dependencies. This eliminates host contamination from the benchmark results
and makes runs reproducible across machines.

## Motivation

The evaluation harness (`benchmark/consumer-v1/run_evaluation.py`) uses the
Claude SDK to spawn agent sessions. When run on a developer workstation, the
agent inherits:

- `~/.claude/` memories (user, feedback, project facts)
- CLAUDE.md files from the repo and parent directories
- Shell environment, git config, tool state

Any of these can leak domain knowledge into agent responses, defeating the
purpose of measuring what the agent can answer from the architecture documents
alone.

## Prerequisites

- [Build consumer evaluation harness](../done/build-consumer-evaluation-harness.md)
  must be complete (provides `run_evaluation.py`, `score_results.py`,
  `generate_report.py`).

## Existing Infrastructure

- `benchmark/consumer-v1/run_evaluation.py` — question runner using Claude SDK
  directly with `_EvalGuard` for read-only tool enforcement.
- `benchmark/consumer-v1/score_results.py` — deterministic scorer (pure Python,
  no SDK dependency).
- `benchmark/consumer-v1/generate_report.py` — report generator (pure Python).
- `lib/agent_runner.py` — imports `claude_agent_sdk` for model ID resolution.

## Work

### 1. Containerfile (`benchmark/consumer-v1/Containerfile`)

- Base image: `python:3.13-slim` (or similar minimal Python image).
- Install the **Claude Code CLI** via the official install script
  (`curl -fsSL https://claude.ai/install.sh | sh`) — the `claude-agent-sdk`
  Python package wraps the CLI, so both are needed. No Node.js required.
- Install `claude-agent-sdk` (pip) and `jsonschema` for validation.
- Copy `benchmark/consumer-v1/` scripts and `lib/` modules into the image.
- Set a clean `HOME=/home/evaluator` with no `.claude/` directory.
- Do NOT copy architecture trees into the image — they are mounted at
  runtime.
- Do NOT bake API keys or GCP credentials into the image.

### 2. Run script (`benchmark/consumer-v1/run_containerized.sh`)

- Uses `podman` for all container operations.
- Accepts the same arguments as `run_evaluation.py` plus `--build` to
  rebuild the image.
- Mounts `--tree-a` and `--tree-b` as read-only volumes inside the
  container (`:ro`).
- Bind-mounts GCP Application Default Credentials from the host
  (`~/.config/gcloud/application_default_credentials.json`) read-only
  into the container at the standard ADC path.
- Passes Vertex AI environment variables from the host:
  - `CLAUDE_CODE_USE_VERTEX` — enables Vertex backend
  - `ANTHROPIC_VERTEX_PROJECT_ID` — GCP project ID
  - `CLOUD_ML_REGION` — Vertex region
  - `ANTHROPIC_DEFAULT_OPUS_MODEL` — model override (if set)
- Mounts `--output-dir` as a writable volume so results persist on the
  host.
- Runs the full pipeline: `run_evaluation.py` then `score_results.py` then
  `generate_report.py`.
- Prints the report path on completion.

### 3. Isolation verification

- The container must have no `~/.claude/` directory (no memories).
- No CLAUDE.md files anywhere in the container filesystem.
- No git config or repo-level settings.
- `setting_sources` in `ClaudeAgentOptions` should be `None` or empty to
  prevent the SDK from scanning for project settings.
- Verify by adding a startup check in the runner that warns if any
  `.claude/` directory or `CLAUDE.md` file is found.

### 4. Update run_evaluation.py

- Add `setting_sources=None` to the `ClaudeAgentOptions` constructor to
  explicitly disable project/user settings loading even if `.claude/`
  somehow exists.
- Ensure the agent `cwd` is set to the mounted tree path inside the
  container, not a repo path.

## Negative Controls

- Architecture trees must be mounted read-only (`:ro`).
- No host `.claude/` directory mounted into the container.
- No CLAUDE.md files present in the container.
- GCP credentials must be bind-mounted read-only, not baked into the image.
- Vertex env vars must be passed at runtime, not hardcoded in the
  Containerfile.

## Acceptance Criteria

- [ ] `podman build` succeeds from `benchmark/consumer-v1/Containerfile`.
- [ ] `run_containerized.sh` runs at least 2 questions against both trees
  and produces `raw-results.json`, `scored-results.json`, and `report.md`.
- [ ] The container has no `.claude/` directory and no `CLAUDE.md` files
  (verified by startup check in the runner).
- [ ] `setting_sources=None` is set in `ClaudeAgentOptions`.
- [ ] Architecture trees are mounted read-only.
- [ ] Results written to the host output directory survive container exit.
- [ ] The task is moved to `docs/tasks/done/` and PLAN.md is updated.

## Status

Pending.

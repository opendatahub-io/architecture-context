# Task: Harden Claude Runner Podman Runtime Fallback

## Goal

Prevent recurring rootless Podman startup failures when the agent sandbox
cannot write to `/run/user/$UID/libpod`.

## Scope

- Detect whether the default rootless Podman runtime directory is writable
  before invoking Podman.
- Fall back to a stable per-user runtime directory under `/tmp` when the
  default runtime path is unavailable or read-only.
- Update the driver procedure so future task runs keep using the stable
  launcher command and static stdout files instead of treating the symptom as a
  task-specific approval issue.

## Execution record

- Added `configure_podman_runtime_dir()` to
  `scripts/run_claude_container.sh`.
- The launcher now probes `${XDG_RUNTIME_DIR:-/run/user/$UID}/libpod` and
  exports `XDG_RUNTIME_DIR` to
  `${CLAUDE_RUNNER_PODMAN_RUNTIME_DIR:-/tmp/claude-task-runner-podman-runtime-$UID}`
  when the probe cannot create a file.
- Updated `agent-driver.md` with the expected handling for the recurring
  `/run/user/.../libpod: read-only file system` failure.

## Validation

```bash
scripts/run_claude_container.sh --prompt-file tmp/claude-task-prompt.md --dry-run
```

The dry run completed without the `/run/user/$UID/libpod` chmod failure.
Actual container execution may still require normal Podman escalation in the
managed sandbox; this fix removes the misleading runtime-dir probe failure.

## Status

Completed 2026-07-28.

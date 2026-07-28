# Bug: Claude Runner Hits Read-Only Rootless Podman Runtime

## Summary

Repeated task-container launches failed before useful task execution with:

```text
Failed to obtain podman configuration: set sticky bit on: chmod /run/user/1000/libpod: read-only file system
```

## Cause

The launcher relied on the default rootless Podman runtime directory under
`/run/user/$UID`. In the managed agent sandbox, that path can be visible but
read-only, causing Podman configuration probing to fail before the normal
approval/escalation boundary is reached.

## Fix

`scripts/run_claude_container.sh` now probes the default runtime directory and
falls back to a writable per-user runtime directory under `/tmp` when needed.
`agent-driver.md` records the procedure so future driver runs keep the stable
launcher command and static stdout capture.

## Status

Fixed on 2026-07-28. Dry-run launcher validation completed without the
read-only `/run/user/$UID/libpod` failure. Full Podman execution in the managed
sandbox can still require standard command approval/escalation.

# Task: Add Local Claude OTel and Opt-In API Capture

## Goal

Make analyzer-assisted evaluation runs capture the token, cost, latency, tool,
and request telemetry needed by the architecture plan, while preserving a
safe local/offline default and keeping sensitive API content out of artifacts.

## Scope

- Update `scripts/run_claude_container.sh` to support explicit local telemetry
  output paths under `tmp/`, with Claude Code OTel enabled for metrics, logs,
  and traces as appropriate.
- Add an explicit opt-in API-dump mode for debugging/evaluation. API dumps must
  be written only to a caller-selected local file, be disabled by default, and
  redact API keys, authorization headers, cookies, credentials, and other
  obvious secrets before persistence.
- Preserve the existing JSONL stdout behavior and stable launcher invocation.
  Keep the launcher's existing authentication/configuration loading intact;
  telemetry must work with caller-exported variables and must not require an
  external collector, an external MLflow server, or network-side telemetry.
- Keep project context telemetry and local MLflow tracking compatible and
  document how the three telemetry layers correlate.
- Add focused tests for defaults, path handling, opt-in behavior, redaction,
  and failure-tolerant local writes. Update the relevant telemetry/run-script
  documentation.

## Explicit exclusions

- No production application behavior changes.
- No external OTLP endpoint or collector requirement.
- No default raw prompt, tool-detail, or raw API-body capture.
- Do not commit; do not modify architecture outputs, benchmark answers, or
  human-label fields.

## Acceptance criteria

- A normal launcher run remains functional with telemetry capture disabled or
  safely directed to local files, and the existing JSONL stdout contract is
  unchanged.
- A documented opt-in invocation captures Claude OTel data including token,
  cost, latency, model, and tool-call fields to local files.
- API dumps require an explicit flag, have deterministic file naming, and pass
  through robust secret redaction before being written.
- Invalid/unwritable telemetry paths fail safely without exposing secrets or
  blocking the agent run unless strict mode is explicitly requested.
- Focused tests, shell syntax checks, and `git diff --check` pass.
- Record exact commands, paths, redaction behavior, limitations, and whether
  token/cost fields were observed in the task evidence and session ledger.

## Implementation evidence

### Architecture: streaming redaction boundary

The capture pipeline uses a FIFO-based streaming filter so raw secrets
never reach disk:

```
Claude stderr → FIFO → python3 telemetry_redact.py → otel-console.log (redacted)
                                                   → terminal stderr (redacted)
```

The launcher creates a FIFO (`mkfifo`), starts `lib/telemetry_redact.py` as
a background filter reading from the FIFO, runs the main command with stderr
redirected to the FIFO, then `wait`s for the filter to finish. An EXIT trap
cleans up the FIFO. The filter redacts each line before writing to the
capture file and echoing to the terminal — content on disk is always
sanitized, even if the process is interrupted mid-stream.

### Artifacts created/modified

| File | Change |
|---|---|
| `lib/telemetry_redact.py` | Streaming filter (`stream_redact()`) + `__main__` CLI entry point; non-JSON text redaction; `UnicodeDecodeError` handling |
| `scripts/run_claude_container.sh` | `--otel [DIR]` and `--api-dump` flags; FIFO + streaming filter (no tee, no post-run redaction); `.env` sourcing preserved with caller-precedence |
| `tests/test_telemetry_redact.py` | 80 tests across 14 classes including streaming integration, path wiring, disabled defaults |
| `docs/notes/local-telemetry-capture.md` | Streaming redaction boundary documentation |
| `scripts/README.md` | OTel/API dump capture section |

### Redaction coverage

Sensitive key patterns: `api_key`, `auth`, `authorization`, `token`, `secret`, `password`, `credential`, `cookie`, `session_id`, `x-api-key`, `bearer`, `access_key`, `private_key`, `client_secret`, `refresh_token`.

Value patterns (regardless of key): `sk-ant-*`, `ghp_*`, `gho_*`, `xox[bprs]-*`, `ya29.*`, `Bearer <token>`.

Both JSON and non-JSON text lines are redacted by the streaming filter.

### .env sourcing

Preserved per task scope. The launcher sources `.env` (if present) for
authentication/configuration variables (e.g. Vertex). Caller-exported
variables take precedence over `.env` values. The `ENV_VARS` array and
env-arg passthrough to podman are unchanged.

### Limitations

- OTel console exporter output is semi-structured text, not JSONL spans; parsing requires text extraction.
- Token/cost fields are emitted by Claude Code's OTel layer, not by this module; actual field presence depends on the Claude Code version.

## Review history

### Driver review 1 — not accepted

- Fake `CLAUDE_API_DUMP_FILE` env var (nothing reads it).
- `tee` writes raw output, redaction runs post-capture (interruption-unsafe).
- `.env` sourcing conflict with task's no-`.env` requirement.

### Driver review 2 — refinement not accepted

- Removed fake env var, added EXIT trap + non-JSON redaction (69 tests).
- Core issue: `tee` still writes raw to disk; trap races with process substitution.
- `.env` sourcing kept per driver instruction; user later overrode.

### Current refinement — streaming boundary

Resolved all prior findings:
1. **No raw content on disk**: FIFO + streaming filter redacts before any file write. No `tee`.
2. **Interruption-safe**: filter processes each line inline; file only ever contains redacted content.
3. **`.env` preserved**: sourcing kept with caller-precedence per task scope.

### Test evidence

```
$ uv run pytest tests/test_telemetry_redact.py -v
80 passed in 0.17s
```

Test classes (14 total, 80 tests):
- `TestRedactValue` (18), `TestBearerPatterns` (2), `TestAPIKeyValuePatterns` (6)
- `TestRedactDict` (7), `TestRedactLine` (5), `TestRedactFile` (6)
- `TestDefaultBehavior` (2), `TestNonJsonRedaction` (5)
- `TestEndToEndApiDump` (3): synthetic OTel fixture
- `TestInterruptionSafety` (5): truncated, empty, binary, partial
- `TestStreamRedact` (8): file+echo, JSON/text secrets, empty, CLI entry point
- `TestPathWiring` (8): streaming filter, no tee, no post-run redaction, FIFO
- `TestDisabledDefaults` (4): OTEL=false, API_DUMP=false, gated, no .env
- `TestLauncherShellSyntax` (1)

```
$ bash -n scripts/run_claude_container.sh  # OK
$ uv run ruff check lib/telemetry_redact.py tests/test_telemetry_redact.py  # All checks passed
$ git diff --check  # clean
```

# Local Telemetry Capture

Two complementary telemetry layers are available for local/offline capture
without an external collector or server.

## Layer 1: Claude Code OTel export

Claude Code has built-in OpenTelemetry support activated by environment
variables. Console exporters write to stdout; redirect to a file for local
capture.

### Environment variables

| Variable | Values | Purpose |
|---|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` | Enable telemetry emission |
| `OTEL_METRICS_EXPORTER` | `console`, `otlp`, `none` | Metrics: tokens, cost, tool decisions |
| `OTEL_LOGS_EXPORTER` | `console`, `otlp`, `none` | Events: API requests, tool results |
| `OTEL_TRACES_EXPORTER` | `console`, `otlp`, `none` | Spans: LLM calls with model/latency/tokens, tool calls |

### Captured data

- Input/output/cache tokens per request
- Cost in USD per request and session total
- Session duration and turn count
- Tool call counts and latency
- Model name and request metadata

### Sensitive data controls

Content is excluded by default. Opt-in flags:

| Variable | Effect |
|---|---|
| `OTEL_LOG_USER_PROMPTS=1` | Include user prompt text |
| `OTEL_LOG_TOOL_DETAILS=1` | Include tool call arguments and results |
| `OTEL_LOG_RAW_API_BODIES=1` | Include raw API request/response bodies |

### CLI output formats

`--output-format json` includes `total_cost_usd` and per-model cost
breakdown in the final output. `--output-format stream-json` emits
newline-delimited JSON events during execution including partial message
chunks. Neither format produces OTel-structured spans directly; the OTel
exporter env vars provide that.

## Layer 2: Context-access telemetry (lib/context_telemetry.py)

The project's own instrumentation layer records architecture-context reads,
queries, denials, and quality signals during agent evaluation. This captures
*what the agent did with the architecture data*, not the underlying API
telemetry.

### Activation

| Variable | Purpose |
|---|---|
| `CONTEXT_TELEMETRY_JSONL_PATH` | Write OTel-compatible JSONL to this file |
| `CONTEXT_TELEMETRY_TRACE_ID` | Optional trace ID for correlation |
| `CONTEXT_TELEMETRY_SPAN_ID` | Optional span ID for correlation |

### Event kinds

`read.useful`, `read.navigation`, `read.denied`, `query.issued`,
`query.denied`, `signal.missing_context`, `signal.stale_context`,
`signal.unsupported_inference`

### Output format

Each line is a JSON record with: `export_version`, `contract_version`,
`timestamp` (UTC ISO 8601), `trace_id`, `span_id`, `event_kind`, `file`,
`component`, `route`, `detail`. Bounded by `max_events` (default 10,000).
Failure-tolerant: I/O errors never block agent execution.

See `lib/context_telemetry.py` and
`docs/tasks/done/add-otel-file-export-boundary.md` for implementation.

## Layer 3: Local MLflow tracking (lib/mlflow_tracking.py)

Experiment results (tags, metrics, artifact references) can be recorded to a
local directory using the MLflow SDK file store. No server required.

| Variable | Purpose |
|---|---|
| `MLFLOW_RUNS_DIR` | Local directory for MLflow file store |
| `MLFLOW_EXPERIMENT_NAME` | Experiment name (default: `analyzer-assisted-retrieval-v1`) |

The MLflow SDK (`mlflow==2.22.0`) is pinned only in `scripts/Dockerfile.claude`.
Path sanitization rejects traversal, symlinks outside the parent, and
non-writable targets.

See `lib/mlflow_tracking.py` and
`docs/tasks/current/enable-local-mlflow-tracking.md` for implementation.

## How the layers relate

| Layer | What it captures | When it fires |
|---|---|---|
| Claude Code OTel | API tokens, cost, latency, tool calls | Every Claude CLI invocation |
| Context telemetry | Architecture reads, queries, denials, signals | During evaluation agent execution |
| MLflow tracking | Scored results, provenance, condition identity | After evaluation, on result recording |

For task container runs, all three can be active simultaneously. The
launcher script provides `--otel` and `--api-dump` flags for Layer 1;
context telemetry and MLflow use their respective env vars.

## Container launcher flags

The `scripts/run_claude_container.sh` script provides opt-in flags for
local OTel and API dump capture:

```bash
# Capture OTel metrics/traces/logs to tmp/otel-capture/
scripts/run_claude_container.sh --otel "Run the task"

# Capture to a custom directory
scripts/run_claude_container.sh --otel /path/to/capture "Run the task"

# Also capture raw API bodies with secret redaction
scripts/run_claude_container.sh --otel --api-dump "Run the task"
```

`--otel [DIR]` sets `CLAUDE_CODE_ENABLE_TELEMETRY=1` and console exporters
for metrics, traces, and logs. OTel console output (stderr) is captured to
`otel-console.log` in the capture directory (default: `tmp/otel-capture/`).

`--api-dump` implies `--otel` and additionally sets
`OTEL_LOG_RAW_API_BODIES=1`, causing raw API request/response bodies to
appear in the same `otel-console.log` file.

### Streaming redaction boundary

Stderr is piped through `lib/telemetry_redact.py` as a streaming filter
via a FIFO. Content is redacted line-by-line *before* any persistent write,
so `otel-console.log` never contains raw secrets — even if the process is
interrupted mid-stream. Redaction covers:

- **JSON lines**: full recursive dict redaction (sensitive key patterns,
  Bearer tokens, API key value patterns)
- **Non-JSON text lines**: value-pattern redaction (Bearer tokens, sk-ant,
  ghp_, gho_, xoxb/p/r/s-, ya29.* patterns)

There is no separate API dump file; `otel-console.log` is the single
persisted capture path. The FIFO is cleaned up via an EXIT trap.

Both flags are disabled by default. A normal run without either flag
behaves identically to the original launcher. Authentication variables
are loaded from `.env` (if present) and the caller's exported
environment; caller exports take precedence.

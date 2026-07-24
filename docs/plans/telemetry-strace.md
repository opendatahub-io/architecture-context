# Telemetry Plan: strace Agent Calls

## Goal

Capture OS-level syscall traces (file I/O, network, subprocess spawns) for every
Claude agent invocation in the pipeline. This gives visibility into what the
agent process actually does at the kernel level — which files it reads/writes,
what network connections it opens, and what child processes it spawns.

## Why strace (and not OTEL / MLflow)

The existing logs in `logs/generate-architecture/*.log` already capture the full
agent message stream: every tool call, tool result, system message, timing, and
success/failure. This is the data that OTEL spans and MLflow runs would
duplicate. Adding those layers would mean new dependencies and infrastructure
for data we already have.

What we **don't** have is OS-level activity. strace fills that gap.

## Design

### Approach: Subclass `SubprocessCLITransport`

The Claude Agent SDK (`claude_agent_sdk`) spawns each agent as a subprocess via
`SubprocessCLITransport`. The transport builds a CLI command in
`_build_command()` and launches it with `anyio.open_process()` in `connect()`.

We subclass the transport to prepend `strace` to the command, then pass the
custom transport into `ClaudeSDKClient(transport=...)`.

### strace flags

```
strace -ffttv -s 1024 -e trace=file,network -o <output_path> -- <claude cmd>
```

| Flag | Purpose |
|------|---------|
| `-ff` | Follow forks, write each PID to a separate `<output>.<pid>` file |
| `-tt` | Absolute timestamps with microsecond precision |
| `-v` | Verbose — don't abbreviate struct arguments |
| `-s 1024` | Print up to 1024 bytes of string arguments (default 32 is too short) |
| `-e trace=file,network` | Only trace file and network syscalls (reduces noise) |
| `-o <path>` | Write trace output to file(s), not stderr |

### Implementation

#### 1. New module: `lib/strace_transport.py`

```python
from claude_agent_sdk._internal.transport.subprocess_cli import SubprocessCLITransport


class StracedTransport(SubprocessCLITransport):
    """Transport wrapper that runs the Claude CLI under strace."""

    def __init__(self, *args, strace_output_path=None, **kwargs):
        super().__init__(*args, **kwargs)
        self._strace_output_path = strace_output_path

    def _build_command(self):
        cmd = super()._build_command()
        if self._strace_output_path is None:
            return cmd
        return [
            "strace",
            "-ffttv",
            "-s", "1024",
            "-e", "trace=file,network",
            "-o", str(self._strace_output_path),
            "--",
        ] + cmd
```

#### 2. Modify `lib/agent_runner.py`

Add `strace_dir` parameter to `run_agent()`. When set, construct a
`StracedTransport` and pass it to `ClaudeSDKClient(transport=...)` instead
of letting the client create its own transport.

```python
async def run_agent(
    name, cwd, prompt, log_dir,
    model="opus", enable_skills=False,
    progress=None, strace_dir=None,
):
    ...
    transport = None

    if strace_dir is not None:
        strace_dir.mkdir(parents=True, exist_ok=True)
        strace_base = strace_dir / "trace"
        transport = StracedTransport(
            prompt=_empty_async_iter(),
            options=options,
            strace_output_path=strace_base,
        )

    async with ClaudeSDKClient(options=options, transport=transport) as client:
        ...
```

The `_empty_async_iter()` helper is needed because `SubprocessCLITransport.__init__`
requires a `prompt` argument, but the transport never reads it — the prompt is
sent through stdin by the SDK's Query layer.

```python
async def _empty_async_iter():
    return
    yield
```

#### 3. Wire `--strace` CLI flag

Add `--strace` to `lib/cli.py` argument parser. Thread it through orchestration
into `run_agent()` / `run_agents_concurrently()`.

Each phase constructs the strace directory path from context it already has:

```python
# In each phase runner (architecture.py, diagrams.py, etc.):
if args.strace:
    strace_dir = Path("logs/strace") / f"{args.platform}-{skill}-{component}"
else:
    strace_dir = None
```

#### 4. Output structure

The strace output path is `logs/strace/<platform>-<skill>-<component>/`,
adjusting for phases that don't have a component or have different context:

```
logs/strace/
  rhoai-3.5-ea.2-generate-architecture-codeflare-sdk/
    trace.12345                  # main process trace
    trace.12346                  # forked worker trace
    trace.12347                  # ...
  rhoai-3.5-ea.2-generate-architecture-kserve/
    trace.23456
    trace.23457
  rhoai-3.5-ea.2-generate-diagrams-codeflare-sdk/
    trace.34567
  rhoai-3.5-ea.2-generate-platform-architecture/
    trace.45678
  rhoai-3.5-ea.2-discover-components/
    trace.56789
```

The `-ff` flag causes strace to create one `trace.<pid>` file per process in
the tree. Each component/phase gets its own directory, keeping the per-PID
files contained and easy to correlate with the existing agent message logs.

### What to look for in strace output

- `openat()` / `read()` / `write()` — which files the agent touches
- `connect()` / `sendto()` / `recvfrom()` — API calls, network activity
- `clone()` / `execve()` — subprocess spawning (tool execution)
- Unexpected file access outside the working directory

### Future considerations

- **Structured log parsing**: Convert existing `.log` files into JSONL with
  consistent fields (component, phase, model, duration, tool calls, success)
  for queryability — no new dependencies needed.
- **OTEL**: The SDK already propagates `traceparent`/`tracestate` env vars to
  child processes (see `subprocess_cli.py:414-438`). If we ever want distributed
  tracing, the plumbing is already there.
- **strace filtering/analysis**: A post-processing script to extract unique
  file paths and network endpoints from strace output across all agents.

### Prerequisites

- `strace` must be installed on the host (`dnf install strace` on Fedora)
- The pipeline user must have permission to trace child processes
  (`/proc/sys/kernel/yama/ptrace_scope` must be 0 or 1, or run as root)

### Scope

This plan only covers **strace integration**. No OTEL, no MLflow, no new
observability infrastructure. The existing agent logs already cover the
application-level data. strace adds the OS-level layer we're missing.

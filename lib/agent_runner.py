"""Claude SDK agent launcher and model utilities."""

from __future__ import annotations

import asyncio
import time
from pathlib import Path
from typing import TYPE_CHECKING

from claude_agent_sdk import ClaudeAgentOptions, ClaudeSDKClient

from lib.strace_transport import StracedTransport, empty_async_iter

if TYPE_CHECKING:
    from lib.progress import AgentProgress


def get_model_display_name(model_shorthand: str) -> str:
    """
    Convert model shorthand to human-readable display name for generated files.

    Args:
        model_shorthand: Short name (sonnet, opus, haiku)

    Returns:
        Human-readable model name
    """
    display_names = {
        "sonnet": "Claude Sonnet 4.5",
        "opus": "Claude Opus 4.6",
        "haiku": "Claude Haiku 3.5",
    }
    return display_names.get(model_shorthand, model_shorthand)


def get_model_id(model_shorthand: str) -> str:
    """
    Convert model shorthand to full model ID.

    Args:
        model_shorthand: Short name (sonnet, opus, haiku)

    Returns:
        Full model ID string
    """
    # Model IDs without date suffixes -- the SDK resolves to the latest version
    model_mapping = {
        "sonnet": "claude-sonnet-4-5",
        "opus": "claude-opus-4-6",
        "haiku": "claude-haiku-3-5",
    }

    return model_mapping.get(model_shorthand, model_shorthand)


def format_duration(seconds: float) -> str:
    """Format seconds into a human-readable duration string."""
    total = int(seconds)
    h, remainder = divmod(total, 3600)
    m, s = divmod(remainder, 60)
    parts = []
    if h:
        parts.append(f"{h}h")
    if m:
        parts.append(f"{m}m")
    parts.append(f"{s}s")
    return " ".join(parts)


async def run_agent(
    name: str, cwd: str, prompt: str, log_dir: Path,
    model: str = "opus", enable_skills: bool = False,
    progress: AgentProgress | None = None,
    strace_dir: Path | None = None,
) -> dict:
    """
    Launch one independent Claude agent session.

    Args:
        name: Component name for identification
        cwd: Working directory for the agent
        prompt: Prompt to send to the agent
        log_dir: Directory to write log files
        model: Claude model to use (sonnet, opus, or haiku)
        enable_skills: If True, enable Skill tool and load skills from filesystem

    Returns:
        dict with 'name', 'success', 'log_file', and optional 'error' keys
    """
    # Create log file for this agent
    log_file = log_dir / f"{name.replace('/', '_')}.log"

    # Convert shorthand to full model ID
    model_id = get_model_id(model)

    allowed_tools = ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
    if enable_skills:
        allowed_tools.extend(["Skill", "Task"])

    options = ClaudeAgentOptions(
        cwd=cwd,
        allowed_tools=allowed_tools,
        permission_mode="bypassPermissions",
        model=model_id,
        setting_sources=["user", "project"] if enable_skills else None,
    )

    _log = progress.log if progress else print

    transport = None
    if strace_dir is not None:
        strace_dir.mkdir(parents=True, exist_ok=True)
        transport = StracedTransport(
            prompt=empty_async_iter(),
            options=options,
            strace_output_path=strace_dir / "trace",
        )

    _log(f"\n{'=' * 60}")
    _log(f"Starting agent: {name}")
    _log(f"Model: {model}")
    _log(f"Working directory: {cwd}")
    _log(f"Log file: {log_file}")
    if strace_dir is not None:
        _log(f"Strace output: {strace_dir}")
    _log(f"{'=' * 60}")

    # Write log header before try block so error handler always has context
    with open(log_file, 'w') as log:
        log.write(f"Agent: {name}\n")
        log.write(f"Model: {model}\n")
        log.write(f"Working directory: {cwd}\n")
        log.write(f"{'=' * 60}\n\n")
        log.write("PROMPT:\n")
        log.write(prompt)
        log.write(f"\n\n{'=' * 60}\n")
        log.write("AGENT OUTPUT:\n\n")

    start_time = time.monotonic()
    last_activity = start_time
    heartbeat_task = None

    if not progress:
        async def _heartbeat():
            """Print periodic status while the agent is working silently."""
            nonlocal last_activity
            while True:
                await asyncio.sleep(30)
                silence = time.monotonic() - last_activity
                elapsed = time.monotonic() - start_time
                if silence >= 30:
                    print(
                        f"[{name}] ... still running "
                        f"({format_duration(elapsed)} elapsed)"
                    )

        heartbeat_task = asyncio.create_task(_heartbeat())

    if progress:
        progress.agent_started(name)

    try:
        with open(log_file, 'a') as log:
            async with ClaudeSDKClient(options=options, transport=transport) as client:
                await client.query(prompt)

                async for msg in client.receive_response():
                    last_activity = time.monotonic()
                    _log(f"[{name}] {msg}")
                    log.write(f"{msg}\n")
                    log.flush()

        elapsed = time.monotonic() - start_time

        if progress:
            progress.agent_completed(name, success=True)
        _log(f"Completed: {name} ({format_duration(elapsed)})")

        return {
            "name": name,
            "success": True,
            "log_file": str(log_file),
            "duration_seconds": elapsed,
        }

    except BaseException as e:
        # Catch BaseException (not just Exception) because the Claude Code CLI
        # can crash on benign text patterns like [/path], causing anyio to cancel
        # concurrent sub-agent tasks. The resulting CancelledError exceptions are
        # wrapped in a BaseExceptionGroup, which is a BaseException — not caught
        # by `except Exception`.
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise

        elapsed = time.monotonic() - start_time

        if progress:
            progress.agent_completed(name, success=False)
        _log(f"Failed: {name} ({format_duration(elapsed)}) — {e}")

        with open(log_file, 'a') as log:
            log.write(f"\n\n{'=' * 60}\n")
            log.write(f"ERROR: {e}\n")

        return {
            "name": name,
            "success": False,
            "error": str(e),
            "log_file": str(log_file),
            "duration_seconds": elapsed,
        }

    finally:
        if heartbeat_task:
            heartbeat_task.cancel()
            try:
                await heartbeat_task
            except asyncio.CancelledError:
                pass


async def run_agents_concurrently(
    jobs: list,
    log_dir: Path,
    model: str,
    max_concurrent: int,
    enable_skills: bool = False,
    strace_prefix: str | None = None,
) -> list:
    """
    Run multiple agent jobs with a concurrency limit.

    Displays a rich progress panel pinned to the bottom of the terminal
    showing completion count, running agents, elapsed time, and ETA.

    Args:
        jobs: List of dicts with 'name', 'cwd', 'prompt' keys
        log_dir: Directory for agent log files
        model: Model shorthand (sonnet, opus, haiku)
        max_concurrent: Max agents running at once
        enable_skills: If True, enable Skill tool and load skills from filesystem

    Returns:
        List of result dicts (or Exceptions) in the same order as jobs
    """
    total = len(jobs)

    def _strace_dir_for(job_name: str) -> Path | None:
        if strace_prefix is None:
            return None
        safe_name = job_name.replace("/", "_")
        return Path("logs/strace") / f"{strace_prefix}-{safe_name}"

    # Single job: skip the progress panel — just run directly with heartbeat
    if total == 1:
        job = jobs[0]
        try:
            result = await run_agent(
                job["name"], job["cwd"], job["prompt"], log_dir, model,
                enable_skills=enable_skills,
                strace_dir=_strace_dir_for(job["name"]),
            )
        except BaseException as e:
            if isinstance(e, (KeyboardInterrupt, SystemExit)):
                raise
            result = {
                "name": job["name"],
                "success": False,
                "error": str(e),
                "log_file": str(
                    log_dir / f"{job['name'].replace('/', '_')}.log"
                ),
                "duration_seconds": 0,
            }
        return [result]

    from lib.progress import AgentProgress

    semaphore = asyncio.Semaphore(max_concurrent)
    progress = AgentProgress(total, max_concurrent)

    async def _run(index: int, job: dict):
        if semaphore.locked():
            progress.log(
                f"[{job['name']}] queued ({index + 1}/{total}), "
                f"waiting for slot ..."
            )
        try:
            async with semaphore:
                return await run_agent(
                    job["name"], job["cwd"], job["prompt"], log_dir, model,
                    enable_skills=enable_skills,
                    progress=progress,
                    strace_dir=_strace_dir_for(job["name"]),
                )
        except BaseException as e:
            if isinstance(e, (KeyboardInterrupt, SystemExit)):
                raise
            progress.agent_completed(job["name"], success=False)
            progress.log(f"Failed (outer): {job['name']} — {e}")
            return {
                "name": job["name"],
                "success": False,
                "error": str(e),
                "log_file": str(
                    log_dir / f"{job['name'].replace('/', '_')}.log"
                ),
                "duration_seconds": 0,
            }

    progress.log("Starting agent execution...\n")
    progress.start()
    try:
        results = await asyncio.gather(
            *(_run(i, job) for i, job in enumerate(jobs)),
            return_exceptions=True,
        )
    finally:
        progress.stop()

    return results

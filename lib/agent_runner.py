"""Claude SDK agent launcher and model utilities."""

import time
import asyncio
from pathlib import Path

from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions


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


async def run_agent(name: str, cwd: str, prompt: str, log_dir: Path, model: str = "sonnet") -> dict:
    """
    Launch one independent Claude agent session to generate architecture.

    Args:
        name: Component name for identification
        cwd: Working directory for the agent
        prompt: Prompt to send to the agent
        log_dir: Directory to write log files
        model: Claude model to use (sonnet, opus, or haiku)

    Returns:
        dict with 'name', 'success', 'log_file', and optional 'error' keys
    """
    # Create log file for this agent
    log_file = log_dir / f"{name.replace('/', '_')}.log"

    # Convert shorthand to full model ID
    model_id = get_model_id(model)

    options = ClaudeAgentOptions(
        cwd=cwd,
        allowed_tools=["Read", "Write", "Edit", "Bash", "Glob", "Grep"],
        permission_mode="bypassPermissions",
        model=model_id,
        # No max_turns - let agent run as long as needed for thorough analysis
    )

    print(f"\n{'=' * 60}")
    print(f"Starting agent: {name}")
    print(f"Model: {model}")
    print(f"Working directory: {cwd}")
    print(f"Log file: {log_file}")
    print(f"{'=' * 60}")

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

    async def _heartbeat():
        """Print periodic status while the agent is working silently."""
        nonlocal last_activity
        while True:
            await asyncio.sleep(30)
            silence = time.monotonic() - last_activity
            elapsed = time.monotonic() - start_time
            if silence >= 30:
                print(f"[{name}] ... still running ({format_duration(elapsed)} elapsed)")

    heartbeat_task = asyncio.create_task(_heartbeat())

    try:
        with open(log_file, 'a') as log:
            async with ClaudeSDKClient(options=options) as client:
                await client.query(prompt)

                async for msg in client.receive_response():
                    last_activity = time.monotonic()
                    # Print to console with component name prefix
                    print(f"[{name}] {msg}")
                    # Also write to log file
                    log.write(f"{msg}\n")
                    log.flush()

        elapsed = time.monotonic() - start_time

        print(f"\n{'=' * 60}")
        print(f"Completed: {name} ({format_duration(elapsed)})")
        print(f"{'=' * 60}")

        return {"name": name, "success": True, "log_file": str(log_file), "duration_seconds": elapsed}

    except Exception as e:
        elapsed = time.monotonic() - start_time

        print(f"\n{'=' * 60}")
        print(f"Failed: {name} ({format_duration(elapsed)})")
        print(f"Error: {e}")
        print(f"{'=' * 60}")

        # Log the error (header already written, so context is preserved)
        with open(log_file, 'a') as log:
            log.write(f"\n\n{'=' * 60}\n")
            log.write(f"ERROR: {e}\n")

        return {"name": name, "success": False, "error": str(e), "log_file": str(log_file), "duration_seconds": elapsed}

    finally:
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
) -> list:
    """
    Run multiple agent jobs with a concurrency limit.

    Logs queue position and slot acquisition so the user can see what's
    happening when agents are waiting for a slot.

    Args:
        jobs: List of dicts with 'name', 'cwd', 'prompt' keys
        log_dir: Directory for agent log files
        model: Model shorthand (sonnet, opus, haiku)
        max_concurrent: Max agents running at once

    Returns:
        List of result dicts (or Exceptions) in the same order as jobs
    """
    semaphore = asyncio.Semaphore(max_concurrent)
    total = len(jobs)

    async def _run(index: int, job: dict):
        if semaphore.locked():
            print(f"[{job['name']}] queued ({index + 1}/{total}), "
                  f"waiting for slot ...")
        async with semaphore:
            return await run_agent(
                job["name"], job["cwd"], job["prompt"], log_dir, model
            )

    print("Starting agent execution...\n")
    return await asyncio.gather(
        *(_run(i, job) for i, job in enumerate(jobs)),
        return_exceptions=True,
    )

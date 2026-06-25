#!/usr/bin/env python3
"""Proof-of-concept: run a Claude agent under strace via transport subclass."""

import asyncio
import os
import shutil
import sys
from pathlib import Path

import pytest
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Load .env before any SDK imports so credentials are available
_env_path = PROJECT_ROOT / ".env"
if _env_path.exists():
    load_dotenv(dotenv_path=_env_path)

sys.path.insert(0, str(PROJECT_ROOT))

_has_api_creds = bool(
    os.environ.get("ANTHROPIC_API_KEY")
    or os.environ.get("CLAUDE_CODE_USE_VERTEX")
)
_has_strace = shutil.which("strace") is not None

PLATFORM = "test"
SKILL = "strace-validation"
COMPONENT = "hello-agent"


@pytest.mark.skipif(not _has_api_creds, reason="no API credentials")
@pytest.mark.skipif(not _has_strace, reason="strace not installed")
@pytest.mark.asyncio
async def test_strace_agent():
    from claude_agent_sdk import (
        ClaudeAgentOptions,
        ClaudeSDKClient,
        ResultMessage,
        TextBlock,
    )

    from lib.strace_transport import StracedTransport, empty_async_iter

    strace_dir = (
        PROJECT_ROOT / "logs" / "strace"
        / f"{PLATFORM}-{SKILL}-{COMPONENT}"
    )

    if strace_dir.exists():
        shutil.rmtree(strace_dir)
    strace_dir.mkdir(parents=True)

    strace_base = strace_dir / "trace"

    options = ClaudeAgentOptions(
        model="claude-sonnet-4-5",
        permission_mode="bypassPermissions",
        allowed_tools=[],
        system_prompt="",
    )

    transport = StracedTransport(
        prompt=empty_async_iter(),
        options=options,
        strace_output_path=strace_base,
    )

    result_text = None
    got_result = False

    async def _run_agent():
        nonlocal result_text, got_result
        async with ClaudeSDKClient(
            options=options, transport=transport,
        ) as client:
            await client.query("Reply with the single word: hello")
            async for msg in client.receive_response():
                if isinstance(msg, ResultMessage):
                    got_result = True
                elif hasattr(msg, "content"):
                    for block in msg.content:
                        if isinstance(block, TextBlock):
                            result_text = block.text

    await asyncio.wait_for(_run_agent(), timeout=120)

    assert got_result, "never received ResultMessage"
    assert result_text is not None, "no text in agent response"

    strace_files = sorted(strace_dir.glob("trace.*"))
    total_bytes = sum(f.stat().st_size for f in strace_files)

    assert len(strace_files) > 0, "no strace output files found"
    assert total_bytes > 0, "strace files are empty"

    largest = max(strace_files, key=lambda f: f.stat().st_size)
    syscall_names = set()
    with open(largest) as f:
        for line in f:
            parts = line.split("(", 1)
            if len(parts) == 2:
                token = parts[0].rsplit(None, 1)
                if token:
                    syscall_names.add(token[-1])

    assert syscall_names, (
        "could not parse any syscall names from strace output"
    )

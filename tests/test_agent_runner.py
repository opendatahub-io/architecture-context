import sys
from pathlib import Path

import pytest
from claude_agent_sdk import ResultMessage

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib import agent_runner  # noqa: E402
from lib import progress as progress_module  # noqa: E402


class FakeClient:
    def __init__(self, *args, **kwargs):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, traceback):
        return False

    async def query(self, prompt):
        pass

    async def receive_response(self):
        yield "large-agent-message-" + ("x" * 10_000)


class FakeProgress:
    def __init__(self):
        self.messages = []
        self.completed = []

    def log(self, message):
        self.messages.append(message)

    def agent_started(self, name):
        pass

    def agent_completed(self, name, success):
        self.completed.append((name, success))


class FakeResultClient(FakeClient):
    async def receive_response(self):
        yield ResultMessage(
            subtype="success",
            duration_ms=1200,
            duration_api_ms=1100,
            is_error=False,
            num_turns=3,
            session_id="session",
            total_cost_usd=0.125,
            usage={"input_tokens": 100, "output_tokens": 250},
            model_usage={"test-model": {"outputTokens": 250}},
            permission_denials=[],
        )


@pytest.mark.asyncio
async def test_concurrent_agent_keeps_sdk_payload_out_of_progress_console(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(agent_runner, "ClaudeSDKClient", FakeClient)
    progress = FakeProgress()

    result = await agent_runner.run_agent(
        "example",
        str(tmp_path),
        "test prompt",
        tmp_path,
        progress=progress,
    )

    assert result["success"] is True
    assert progress.completed == [("example", True)]
    assert not any("large-agent-message" in message for message in progress.messages)
    assert "large-agent-message" in (tmp_path / "example.log").read_text()


def test_progress_log_ignores_nonblocking_stdout(
    monkeypatch: pytest.MonkeyPatch,
):
    def blocked_print(*args, **kwargs):
        raise BlockingIOError(11, "write could not complete without blocking")

    monkeypatch.setattr(progress_module.console, "print", blocked_print)
    tracker = progress_module.AgentProgress(total=1, max_concurrent=1)

    tracker.log("bounded progress message")


@pytest.mark.asyncio
async def test_agent_result_captures_sdk_usage_and_cost(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(agent_runner, "ClaudeSDKClient", FakeResultClient)

    result = await agent_runner.run_agent(
        "example",
        str(tmp_path),
        "test prompt",
        tmp_path,
    )

    telemetry = result["telemetry"]
    assert telemetry["duration_api_ms"] == 1100
    assert telemetry["num_turns"] == 3
    assert telemetry["total_cost_usd"] == 0.125
    assert telemetry["usage"] == {"input_tokens": 100, "output_tokens": 250}

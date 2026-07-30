import sys
from pathlib import Path

import pytest
from claude_agent_sdk import ResultMessage

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib import agent_runner  # noqa: E402
from lib import progress as progress_module  # noqa: E402


class FakeClient:
    last_options = None

    def __init__(self, *args, **kwargs):
        FakeClient.last_options = kwargs.get("options")
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


@pytest.mark.asyncio
async def test_run_agent_propagates_name_as_component_when_policy_omits_it(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(agent_runner, "ClaudeSDKClient", FakeClient)
    captured: dict = {}

    OrigGuard = agent_runner._AgentExecutionGuard

    class CapturingGuard(OrigGuard):
        def __init__(self, policy, checkout_path, **kwargs):
            captured["component"] = (policy or {}).get("component")
            super().__init__(policy, checkout_path, **kwargs)

    monkeypatch.setattr(agent_runner, "_AgentExecutionGuard", CapturingGuard)

    await agent_runner.run_agent(
        "my-component",
        str(tmp_path),
        "test prompt",
        tmp_path,
        agent_policy=None,
    )

    assert captured["component"] == "my-component"


# ── Execution guard clean-run isolation tests ──


@pytest.mark.asyncio
async def test_guard_blocks_reads_outside_checkout_on_synthesis_route(
    tmp_path: Path,
):
    """Synthesis agents must not read files outside their checkout directory,
    preventing access to prior architecture documents in architecture/."""
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    prior_docs = tmp_path / "architecture" / "rhoai.next"
    prior_docs.mkdir(parents=True)
    prior_doc = prior_docs / "example.md"
    prior_doc.write_text("prior architecture content")

    guard = agent_runner._AgentExecutionGuard(
        {"route": "synthesis", "readiness": "sufficient"},
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Read",
            "tool_input": {"file_path": str(prior_doc)},
        },
        "tool-use-1",
        {},
    )

    decision = result.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny", (
        f"Expected Read outside checkout to be denied, got: {decision}"
    )


@pytest.mark.asyncio
async def test_guard_allows_analyzer_navigation_files_inside_checkout(
    tmp_path: Path,
):
    """Synthesis agents may read analyzer navigation files (analyzer_architecture.md,
    component-architecture.json) inside the checkout—these are the approved context."""
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    (checkout / "analyzer_architecture.md").write_text("analyzer baseline")
    (checkout / "component-architecture.json").write_text("{}")

    guard = agent_runner._AgentExecutionGuard(
        {"route": "synthesis", "readiness": "sufficient"},
        checkout,
    )

    for nav_file in ("analyzer_architecture.md", "component-architecture.json"):
        result = await guard.pre_tool_use(
            {
                "tool_name": "Read",
                "tool_input": {"file_path": str(checkout / nav_file)},
            },
            f"tool-use-{nav_file}",
            {},
        )
        decision = result.get("hookSpecificOutput", {}).get("permissionDecision")
        assert decision != "deny", (
            f"Expected {nav_file} inside checkout to be allowed, got deny"
        )


@pytest.mark.asyncio
async def test_partial_route_allows_targeted_source_reads_for_sufficient_readiness(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    source = checkout / "src" / "server.go"
    source.parent.mkdir()
    source.write_text("package server\n")

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "sufficient",
            "file_budget": 1,
            "source_files": (),
        },
        checkout,
    )
    result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        "tool-use-partial-source",
        {},
    )
    assert result.get("hookSpecificOutput", {}).get("permissionDecision") != "deny"
    assert guard.source_reads == ["src/server.go"]


@pytest.mark.asyncio
async def test_restricted_run_agent_excludes_todowrite_from_allowed_tools(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(agent_runner, "ClaudeSDKClient", FakeClient)

    await agent_runner.run_agent(
        "example",
        str(tmp_path),
        "test prompt",
        tmp_path,
        enable_skills=True,
        agent_policy={
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "discovery_tools": ("Glob", "Grep"),
        },
        checkout_path=tmp_path,
    )

    assert FakeClient.last_options is not None
    assert "TodoWrite" not in FakeClient.last_options.allowed_tools
    assert "Task" not in FakeClient.last_options.allowed_tools
    assert "Bash" not in FakeClient.last_options.allowed_tools
    assert set(FakeClient.last_options.allowed_tools) == {
        "Read",
        "Write",
        "Edit",
        "Skill",
        "Glob",
        "Grep",
    }


@pytest.mark.asyncio
async def test_todowrite_denial_is_classified_as_workflow_noise(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "source_files": (),
        },
        checkout,
    )

    result = await guard.pre_tool_use(
        {"tool_name": "TodoWrite", "tool_input": {"todos": []}},
        "tool-use-todo",
        {},
    )

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "disabled for component generation" in (
        result["hookSpecificOutput"]["permissionDecisionReason"]
    )
    telemetry = guard.telemetry()
    assert telemetry["denied_tool_calls_by_name"] == {"TodoWrite": 1}
    assert telemetry["denied_tool_calls_by_category"] == {"workflow-noise": 1}
    assert telemetry["avoidable_workflow_denials"] == 1


@pytest.mark.asyncio
async def test_partial_route_bash_denial_suggests_allowed_discovery_tools(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "source_files": (),
            "discovery_tools": ("Glob", "Grep"),
        },
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Bash",
            "tool_input": {"command": f"ls {checkout}"},
        },
        "tool-use-bash",
        {},
    )

    reason = result["hookSpecificOutput"]["permissionDecisionReason"]
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "shell discovery is disabled" in reason
    assert "targeted Glob/Grep" in reason
    assert guard.telemetry()["denied_tool_calls_by_category"] == {
        "workflow-noise": 1
    }


@pytest.mark.asyncio
async def test_partial_route_denies_unbounded_large_source_read(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    source = checkout / "src" / "server.go"
    source.parent.mkdir()
    source.write_text("\n".join(f"line {i}" for i in range(450)))

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "source_files": (),
        },
        checkout,
    )

    result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        "tool-use-large-source",
        {},
    )

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "offset/limit" in result["hookSpecificOutput"]["permissionDecisionReason"]
    assert "offset=1, limit=120" in (
        result["hookSpecificOutput"]["permissionDecisionReason"]
    )
    assert guard.source_reads == []


@pytest.mark.asyncio
async def test_partial_route_allows_bounded_large_source_read(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    source = checkout / "src" / "server.go"
    source.parent.mkdir()
    source.write_text("\n".join(f"line {i}" for i in range(450)))

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "source_files": (),
        },
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Read",
            "tool_input": {
                "file_path": str(source),
                "offset": 25,
                "limit": 120,
            },
        },
        "tool-use-bounded-source",
        {},
    )

    assert result.get("hookSpecificOutput", {}).get("permissionDecision") != "deny"
    assert guard.source_reads == ["src/server.go"]


@pytest.mark.asyncio
async def test_partial_route_broad_glob_denial_suggests_targeted_patterns(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "source_files": (),
            "discovery_tools": ("Glob",),
        },
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Glob",
            "tool_input": {"path": str(checkout), "pattern": "*"},
        },
        "tool-use-broad-glob",
        {},
    )

    reason = result["hookSpecificOutput"]["permissionDecisionReason"]
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "not a full-checkout Glob" in reason
    assert "charts/**/values.yaml" in reason
    assert "components/**/kustomization.yaml" in reason
    assert guard.telemetry()["denied_tool_calls_by_category"] == {
        "broad-discovery": 1
    }


@pytest.mark.asyncio
async def test_preseeded_output_write_denial_suggests_edit(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    output = tmp_path / "architecture" / "rhoai.next" / "example.md"
    output.parent.mkdir(parents=True)
    output.write_text("# preseed\n")

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "source_files": (),
            "output_preseeded": True,
        },
        checkout,
        output_paths=(output,),
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Write",
            "tool_input": {
                "file_path": str(output),
                "content": "# replacement\n",
            },
        },
        "tool-use-write",
        {},
    )

    reason = result["hookSpecificOutput"]["permissionDecisionReason"]
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "targeted Edit" in reason
    assert "reserve Write for sidecar artifacts" in reason
    assert guard.telemetry()["denied_tool_calls_by_category"] == {
        "workflow-noise": 1
    }


@pytest.mark.asyncio
async def test_guard_reports_runtime_activity_categories(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    analyzer_root = tmp_path / "architecture" / "rhoai.next" / "example" / ".analyzer"
    generation_dir = (
        tmp_path / "architecture" / "rhoai.next" / "example" / ".generation"
    )
    checkout.mkdir(parents=True)
    analyzer_root.mkdir(parents=True)
    generation_dir.mkdir(parents=True)
    source = checkout / "src" / "server.go"
    source.parent.mkdir()
    source.write_text("package server\n")
    analyzer_file = analyzer_root / "analyzer_synthesis_context.md"
    analyzer_file.write_text("# analyzer context\n")
    output_file = tmp_path / "architecture" / "rhoai.next" / "example.md"
    change_file = generation_dir / "ARCHITECTURE_CHANGES.md"

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "partial",
            "readiness": "partial",
            "file_budget": 1,
            "source_files": (),
        },
        checkout,
        analyzer_root=analyzer_root,
        output_paths=(output_file, change_file),
    )

    await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(analyzer_file)}},
        "tool-use-analyzer",
        {},
    )
    await guard.pre_tool_use(
        {
            "tool_name": "Read",
            "tool_input": {
                "file_path": str(source),
                "offset": 1,
                "limit": 10,
            },
        },
        "tool-use-source",
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Edit", "tool_input": {"file_path": str(output_file)}},
        "tool-use-edit",
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "Write", "tool_input": {"file_path": str(change_file)}},
        "tool-use-sidecar",
        {},
    )
    await guard.pre_tool_use(
        {"tool_name": "TodoWrite", "tool_input": {"todos": []}},
        "tool-use-denied",
        {},
    )

    telemetry = guard.telemetry()
    assert telemetry["source_read_operations"] == 1
    assert telemetry["tool_calls_by_activity"] == {
        "analyzer_context_read": 1,
        "architecture_output_edit": 1,
        "denied_call": 1,
        "sidecar_write": 1,
        "targeted_source_read": 1,
    }


@pytest.mark.asyncio
async def test_synthesis_route_still_blocks_unlisted_source_reads(
    tmp_path: Path,
):
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    source = checkout / "src" / "server.go"
    source.parent.mkdir()
    source.write_text("package server\n")

    guard = agent_runner._AgentExecutionGuard(
        {
            "route": "synthesis",
            "readiness": "sufficient",
            "file_budget": 0,
            "source_files": (),
        },
        checkout,
    )
    result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(source)}},
        "tool-use-synthesis-source",
        {},
    )
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


@pytest.mark.asyncio
async def test_guard_blocks_write_outside_checkout_on_synthesis_route(
    tmp_path: Path,
):
    """Synthesis agents must not write outside their checkout directory."""
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)
    external_target = tmp_path / "architecture" / "example.md"

    guard = agent_runner._AgentExecutionGuard(
        {"route": "synthesis", "readiness": "sufficient"},
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Write",
            "tool_input": {"file_path": str(external_target)},
        },
        "tool-use-1",
        {},
    )

    decision = result.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny"


@pytest.mark.asyncio
async def test_guard_denies_bash_on_synthesis_preventing_prior_doc_access(
    tmp_path: Path,
):
    """Bash is disabled on synthesis route, preventing shell-based reads of
    prior architecture documents or broad filesystem discovery."""
    checkout = tmp_path / "checkout" / "example"
    checkout.mkdir(parents=True)

    guard = agent_runner._AgentExecutionGuard(
        {"route": "synthesis", "readiness": "sufficient"},
        checkout,
    )

    result = await guard.pre_tool_use(
        {
            "tool_name": "Bash",
            "tool_input": {"command": "cat ../architecture/example.md"},
        },
        "tool-use-1",
        {},
    )

    decision = result.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny"


# ── Phase label rendering tests ──


def _render_to_text(table) -> str:
    from io import StringIO

    from rich.console import Console as _Console

    buf = StringIO()
    _Console(file=buf, width=80, force_terminal=False).print(table)
    return buf.getvalue()


def test_progress_render_includes_phase_label():
    tracker = progress_module.AgentProgress(
        total=5,
        max_concurrent=2,
        phase_label="PHASE 3 · Component architecture synthesis",
    )
    text = _render_to_text(tracker._render())
    assert "PHASE 3" in text
    assert "Component architecture synthesis" in text


def test_progress_render_without_phase_label():
    tracker = progress_module.AgentProgress(total=3, max_concurrent=1)
    text = _render_to_text(tracker._render())
    assert "PHASE" not in text
    assert "0/3" in text


def test_progress_phase_label_defaults_to_empty():
    tracker = progress_module.AgentProgress(total=1, max_concurrent=1)
    assert tracker.phase_label == ""


@pytest.mark.asyncio
async def test_run_agents_concurrently_passes_phase_label(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(agent_runner, "ClaudeSDKClient", FakeClient)

    captured_labels: list[str] = []
    OrigProgress = progress_module.AgentProgress

    class CapturingProgress(OrigProgress):
        def __init__(self, total, max_concurrent, phase_label=""):
            captured_labels.append(phase_label)
            super().__init__(total, max_concurrent, phase_label=phase_label)

    monkeypatch.setattr(progress_module, "AgentProgress", CapturingProgress)

    jobs = [
        {"name": "a", "cwd": str(tmp_path), "prompt": "test"},
        {"name": "b", "cwd": str(tmp_path), "prompt": "test"},
    ]
    await agent_runner.run_agents_concurrently(
        jobs,
        tmp_path,
        "opus",
        2,
        phase_label="PHASE 5 · Platform architecture synthesis",
    )

    assert captured_labels == ["PHASE 5 · Platform architecture synthesis"]


@pytest.mark.asyncio
async def test_single_job_skips_progress_panel(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
):
    """Single-job path should not create an AgentProgress at all."""
    monkeypatch.setattr(agent_runner, "ClaudeSDKClient", FakeClient)

    created = []
    OrigProgress = progress_module.AgentProgress

    class TrackingProgress(OrigProgress):
        def __init__(self, *args, **kwargs):
            created.append(True)
            super().__init__(*args, **kwargs)

    monkeypatch.setattr(progress_module, "AgentProgress", TrackingProgress)

    jobs = [{"name": "solo", "cwd": str(tmp_path), "prompt": "test"}]
    await agent_runner.run_agents_concurrently(
        jobs,
        tmp_path,
        "opus",
        2,
        phase_label="PHASE 3 · Component architecture synthesis",
    )

    assert not created, "Single-job path should not create AgentProgress"


@pytest.mark.asyncio
async def test_restricted_guard_allows_skill_documentation_only(tmp_path: Path):
    checkout = tmp_path / "checkout"
    checkout.mkdir()
    skill_root = PROJECT_ROOT / ".claude" / "skills" / "repo-to-architecture-summary"
    skill_file = skill_root / "SKILL.md"
    template_file = skill_root / "templates" / "architecture-template.md"
    secret_file = PROJECT_ROOT / ".env"
    policy = {
        "route": "partial",
        "readiness": "partial",
        "gap_categories": [],
        "file_budget": 0,
        "discovery_tools": [],
    }
    guard = agent_runner._AgentExecutionGuard(policy, checkout)

    skill_result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(skill_file)}},
        None,
        {},
    )
    template_result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(template_file)}},
        None,
        {},
    )
    secret_result = await guard.pre_tool_use(
        {"tool_name": "Read", "tool_input": {"file_path": str(secret_file)}},
        None,
        {},
    )

    assert skill_result == {}
    assert template_result == {}
    assert secret_result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert guard.telemetry()["source_files_read"] == []
    assert guard.telemetry()["read_calls"] == 2

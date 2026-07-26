"""Focused offline tests for OTel API dump redaction.

Covers key-pattern matching, bearer tokens, API key values, recursive
dict redaction, JSONL file processing, failure tolerance, and edge cases.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.telemetry_redact import (  # noqa: E402
    REDACTED,
    redact_dict,
    redact_file,
    redact_line,
    redact_value,
    stream_redact,
)


class TestRedactValue:
    """Key-based redaction must catch sensitive keys regardless of casing."""

    def test_api_key(self):
        assert redact_value("api_key", "sk-ant-abc123") == REDACTED

    def test_api_key_camelcase(self):
        assert redact_value("apiKey", "some-value") == REDACTED

    def test_authorization(self):
        assert redact_value("Authorization", "Bearer xyz") == REDACTED

    def test_auth_header(self):
        assert redact_value("auth", "token-value") == REDACTED

    def test_token(self):
        assert redact_value("token", "abc") == REDACTED

    def test_secret(self):
        assert redact_value("client_secret", "s3cr3t") == REDACTED

    def test_password(self):
        assert redact_value("password", "p@ss") == REDACTED

    def test_credential(self):
        assert redact_value("credential", "cred") == REDACTED

    def test_cookie(self):
        assert redact_value("cookie", "session=abc") == REDACTED

    def test_session_id(self):
        assert redact_value("session_id", "sid123") == REDACTED

    def test_x_api_key(self):
        assert redact_value("x-api-key", "key") == REDACTED

    def test_refresh_token(self):
        assert redact_value("refresh_token", "rt_abc") == REDACTED

    def test_private_key(self):
        assert redact_value("private_key", "-----BEGIN") == REDACTED

    def test_access_key(self):
        assert redact_value("access_key", "AKIA...") == REDACTED

    def test_non_sensitive_key(self):
        assert redact_value("model", "claude-opus-4-6") == "claude-opus-4-6"

    def test_non_sensitive_numeric(self):
        assert redact_value("duration_ms", 1234) == 1234

    def test_non_string_value(self):
        assert redact_value("api_key", 42) == 42

    def test_empty_string(self):
        assert redact_value("api_key", "") == REDACTED


class TestBearerPatterns:
    """Bearer tokens in non-sensitive keys must still be redacted."""

    def test_bearer_in_value(self):
        result = redact_value("header_value", "Bearer sk-ant-abc123xyz")
        assert "Bearer" in result
        assert "sk-ant" not in result

    def test_bearer_case_insensitive(self):
        result = redact_value("header_value", "bearer my-token-here")
        assert "my-token-here" not in result


class TestAPIKeyValuePatterns:
    """Known API key patterns must be redacted even in non-sensitive keys."""

    def test_anthropic_key(self):
        result = redact_value("log_text", "key is sk-ant-abcdefghij1234567890")
        assert "sk-ant" not in result
        assert REDACTED in result

    def test_github_pat(self):
        result = redact_value("log_text", "used ghp_abcdefghijklmnopqrstuvwxyz012345")
        assert "ghp_" not in result

    def test_github_oauth(self):
        result = redact_value("log_text", "gho_abcdefghijklmnopqrstuvwxyz012345")
        assert "gho_" not in result

    def test_slack_token(self):
        result = redact_value("log_text", "xoxb-abc-def-ghijklmnop")
        assert "xoxb-" not in result

    def test_google_oauth(self):
        result = redact_value("log_text", "ya29.abcdefghijklmnopqrstuvwxyz0123456789")
        assert "ya29." not in result

    def test_safe_value_unchanged(self):
        result = redact_value("log_text", "just a normal log line")
        assert result == "just a normal log line"


class TestRedactDict:
    """Recursive dict redaction must handle nested structures."""

    def test_flat_dict(self):
        d = {"api_key": "sk-abc", "model": "opus"}
        result = redact_dict(d)
        assert result["api_key"] == REDACTED
        assert result["model"] == "opus"

    def test_nested_dict(self):
        d = {"headers": {"Authorization": "Bearer xyz", "Content-Type": "json"}}
        result = redact_dict(d)
        assert result["headers"]["Authorization"] == REDACTED
        assert result["headers"]["Content-Type"] == "json"

    def test_list_values(self):
        d = {"log_entries": ["sk-ant-abcdefghij1234567890", "safe-value"]}
        result = redact_dict(d)
        assert REDACTED in result["log_entries"][0]
        assert result["log_entries"][1] == "safe-value"

    def test_list_of_dicts(self):
        d = {"items": [{"api_key": "secret"}, {"name": "safe"}]}
        result = redact_dict(d)
        assert result["items"][0]["api_key"] == REDACTED
        assert result["items"][1]["name"] == "safe"

    def test_deeply_nested(self):
        d = {"a": {"b": {"c": {"password": "deep-secret"}}}}
        result = redact_dict(d)
        assert result["a"]["b"]["c"]["password"] == REDACTED

    def test_empty_dict(self):
        assert redact_dict({}) == {}

    def test_preserves_non_sensitive(self):
        d = {
            "model": "claude-opus-4-6",
            "input_tokens": 5000,
            "output_tokens": 200,
            "cost_usd": 0.05,
            "duration_ms": 1234,
        }
        result = redact_dict(d)
        assert result == d


class TestRedactLine:
    """JSONL line redaction must handle valid JSON, non-JSON, and edge cases."""

    def test_valid_json_line(self):
        line = json.dumps({"api_key": "secret", "model": "opus"}) + "\n"
        result = redact_line(line)
        parsed = json.loads(result)
        assert parsed["api_key"] == REDACTED
        assert parsed["model"] == "opus"

    def test_non_json_line(self):
        line = "not json at all\n"
        assert redact_line(line) == line

    def test_empty_line(self):
        assert redact_line("") == ""
        assert redact_line("\n") == "\n"

    def test_whitespace_only(self):
        assert redact_line("   \n") == "   \n"

    def test_json_with_nested_secrets(self):
        record = {
            "request": {
                "headers": {"Authorization": "Bearer sk-ant-xyz"},
                "body": {"model": "opus"},
            }
        }
        result = json.loads(redact_line(json.dumps(record)))
        assert result["request"]["headers"]["Authorization"] == REDACTED
        assert result["request"]["body"]["model"] == "opus"


class TestRedactFile:
    """File-level redaction must be atomic and failure-tolerant."""

    def test_redact_file_basic(self, tmp_path):
        f = tmp_path / "dump.jsonl"
        lines = [
            json.dumps({"api_key": "secret1", "model": "opus"}),
            json.dumps({"Authorization": "Bearer tok", "cost": 0.1}),
        ]
        f.write_text("\n".join(lines) + "\n")

        count = redact_file(f)
        assert count == 2

        result_lines = f.read_text().strip().split("\n")
        r0 = json.loads(result_lines[0])
        assert r0["api_key"] == REDACTED
        assert r0["model"] == "opus"
        r1 = json.loads(result_lines[1])
        assert r1["Authorization"] == REDACTED
        assert r1["cost"] == 0.1

    def test_redact_nonexistent_file(self, tmp_path):
        f = tmp_path / "missing.jsonl"
        assert redact_file(f) == 0

    def test_redact_empty_file(self, tmp_path):
        f = tmp_path / "empty.jsonl"
        f.write_text("")
        assert redact_file(f) == 0

    def test_redact_mixed_json_and_text(self, tmp_path):
        f = tmp_path / "mixed.jsonl"
        f.write_text(
            json.dumps({"api_key": "s"}) + "\n"
            "not json\n"
            + json.dumps({"model": "opus"}) + "\n"
        )
        count = redact_file(f)
        assert count == 3
        lines = f.read_text().strip().split("\n")
        assert json.loads(lines[0])["api_key"] == REDACTED
        assert lines[1] == "not json"
        assert json.loads(lines[2])["model"] == "opus"

    def test_redact_preserves_telemetry_fields(self, tmp_path):
        f = tmp_path / "telemetry.jsonl"
        record = {
            "model": "claude-opus-4-6",
            "input_tokens": 5000,
            "output_tokens": 200,
            "cost_usd": 0.05,
            "duration_ms": 1234,
            "tool_calls": {"Read": 4, "Grep": 2},
        }
        f.write_text(json.dumps(record) + "\n")
        redact_file(f)
        result = json.loads(f.read_text().strip())
        assert result["model"] == "claude-opus-4-6"
        assert result["input_tokens"] == 5000
        assert result["cost_usd"] == 0.05
        assert result["tool_calls"]["Read"] == 4

    def test_atomic_write(self, tmp_path):
        f = tmp_path / "atomic.jsonl"
        original = json.dumps({"api_key": "secret"}) + "\n"
        f.write_text(original)
        redact_file(f)
        assert f.exists()
        result = json.loads(f.read_text().strip())
        assert result["api_key"] == REDACTED


class TestDefaultBehavior:
    """Defaults must be safe: no capture unless explicitly enabled."""

    def test_redacted_constant(self):
        assert REDACTED == "[REDACTED]"

    def test_non_sensitive_passthrough(self):
        d = {
            "event_kind": "read.useful",
            "file": "comp-a/GENERATED_ARCHITECTURE.md",
            "component": "dashboard",
            "timestamp": "2026-07-26T12:00:00Z",
        }
        assert redact_dict(d) == d


class TestNonJsonRedaction:
    """Non-JSON text lines must have value-pattern secrets redacted."""

    def test_bearer_in_text_line(self):
        line = "header: Bearer sk-ant-abc123456789012345678901234567890\n"
        result = redact_line(line)
        assert "sk-ant" not in result
        assert REDACTED in result

    def test_api_key_in_text_line(self):
        line = "Using key sk-ant-api03-mysecretkey1234567890\n"
        result = redact_line(line)
        assert "sk-ant" not in result

    def test_github_pat_in_text_line(self):
        line = "token=ghp_abcdefghijklmnopqrstuvwxyz012345\n"
        result = redact_line(line)
        assert "ghp_" not in result

    def test_safe_text_unchanged(self):
        line = "ScopeMetrics #0: llm.tokens.input = 5000\n"
        assert redact_line(line) == line

    def test_otel_span_with_auth(self):
        line = "  -> authorization: Bearer sk-ant-secret12345678901234567890\n"
        result = redact_line(line)
        assert "sk-ant" not in result
        assert "authorization" in result


class TestEndToEndApiDump:
    """Synthetic OTel fixture proves end-to-end API-dump redaction path."""

    def test_synthetic_otel_console_output(self, tmp_path):
        """Mixed JSON and semi-structured text with secrets, simulating
        Claude Code OTel console output with OTEL_LOG_RAW_API_BODIES=1."""
        f = tmp_path / "otel-console.log"
        lines = [
            json.dumps({
                "request": {
                    "headers": {
                        "Authorization": "Bearer sk-ant-api03-secret1234567890",
                        "x-api-key": "sk-ant-api03-another-secret-key123",
                    },
                    "model": "claude-opus-4-6",
                    "max_tokens": 4096,
                },
            }),
            'Span #0 -> http.request.header.authorization: '
            'Bearer sk-ant-inline-secret1234567890',
            json.dumps({
                "response": {
                    "usage": {"input_tokens": 5000, "output_tokens": 200},
                    "model": "claude-opus-4-6",
                },
            }),
            'ScopeMetrics: llm.tokens.input = 5000',
            json.dumps({
                "api_key": "sk-ant-api03-leaked-key-1234567890abcdef",
                "cookie": "session=abc123",
                "model": "claude-opus-4-6",
                "cost_usd": 0.05,
            }),
        ]
        f.write_text("\n".join(lines) + "\n")

        count = redact_file(f)
        assert count == 5

        content = f.read_text()
        assert "sk-ant" not in content
        assert "session=abc" not in content
        assert "claude-opus-4-6" in content
        assert "5000" in content
        assert "0.05" in content

    def test_all_json_secrets_redacted(self, tmp_path):
        f = tmp_path / "otel-console.log"
        record = {
            "headers": {
                "Authorization": "Bearer sk-ant-abc123456789012345678901234567890",
                "Cookie": "session=secret123",
            },
            "body": {
                "password": "hunter2",
                "model": "opus",
            },
        }
        f.write_text(json.dumps(record) + "\n")
        redact_file(f)

        result = json.loads(f.read_text().strip())
        assert result["headers"]["Authorization"] == REDACTED
        assert result["headers"]["Cookie"] == REDACTED
        assert result["body"]["password"] == REDACTED
        assert result["body"]["model"] == "opus"

    def test_all_text_secrets_redacted(self, tmp_path):
        f = tmp_path / "otel-console.log"
        lines = [
            "auth: Bearer sk-ant-secret12345678901234567890",
            "key=ghp_abcdefghijklmnopqrstuvwxyz012345",
            "token: xoxb-1234-5678-abcdefghijklmn",
            "google: ya29.abcdefghijklmnopqrstuvwxyz0123456789",
            "safe metric line: input_tokens=5000",
        ]
        f.write_text("\n".join(lines) + "\n")
        redact_file(f)

        content = f.read_text()
        assert "sk-ant" not in content
        assert "ghp_" not in content
        assert "xoxb-" not in content
        assert "ya29." not in content
        assert "5000" in content


class TestInterruptionSafety:
    """Partial/interrupted capture files must still be redactable."""

    def test_truncated_json_with_secret(self, tmp_path):
        f = tmp_path / "partial.log"
        f.write_text('{"api_key": "sk-ant-secret1234567890123456"\n')
        count = redact_file(f)
        assert count == 1
        content = f.read_text()
        assert "sk-ant" not in content

    def test_empty_interrupted_file(self, tmp_path):
        f = tmp_path / "empty.log"
        f.write_text("")
        assert redact_file(f) == 0

    def test_single_newline(self, tmp_path):
        f = tmp_path / "newline.log"
        f.write_text("\n")
        assert redact_file(f) == 1

    def test_binary_content_does_not_crash(self, tmp_path):
        f = tmp_path / "binary.log"
        f.write_bytes(b"\x80\x81\x82\xff")
        count = redact_file(f)
        assert count == 0

    def test_partial_write_still_redacted(self, tmp_path):
        """Simulates a file with complete and incomplete lines."""
        f = tmp_path / "partial.log"
        f.write_text(
            json.dumps({"api_key": "sk-ant-complete1234567890"}) + "\n"
            'Bearer sk-ant-partialline12345678901234567890'
        )
        count = redact_file(f)
        assert count == 2
        content = f.read_text()
        assert "sk-ant" not in content


class TestStreamRedact:
    """Streaming redaction filter must sanitize before any persistent write."""

    def test_json_secrets_in_file_and_echo(self, tmp_path):
        from io import StringIO

        inp = StringIO(
            json.dumps({"api_key": "sk-ant-secret1234567890", "model": "opus"})
            + "\n"
        )
        out_file = tmp_path / "capture.log"
        echo = StringIO()

        count = stream_redact(inp, out_file, echo)
        assert count == 1

        file_result = json.loads(out_file.read_text().strip())
        assert file_result["api_key"] == REDACTED
        assert file_result["model"] == "opus"

        echo_result = json.loads(echo.getvalue().strip())
        assert echo_result["api_key"] == REDACTED
        assert echo_result["model"] == "opus"

    def test_text_secrets_redacted(self, tmp_path):
        from io import StringIO

        inp = StringIO("Bearer sk-ant-secret12345678901234567890\n")
        out_file = tmp_path / "capture.log"
        echo = StringIO()

        stream_redact(inp, out_file, echo)

        assert "sk-ant" not in out_file.read_text()
        assert "sk-ant" not in echo.getvalue()

    def test_safe_data_preserved(self, tmp_path):
        from io import StringIO

        inp = StringIO("ScopeMetrics: input_tokens = 5000\n")
        out_file = tmp_path / "capture.log"
        echo = StringIO()

        stream_redact(inp, out_file, echo)

        assert "5000" in out_file.read_text()
        assert "5000" in echo.getvalue()

    def test_mixed_json_and_text(self, tmp_path):
        """Realistic OTel console output with mixed content types."""
        from io import StringIO

        lines = [
            json.dumps({
                "request": {
                    "headers": {
                        "Authorization":
                            "Bearer sk-ant-key123456789012345678901234567890",
                    },
                    "model": "opus",
                },
            }) + "\n",
            "Span #0 -> auth: Bearer sk-ant-inline12345678901234567890\n",
            json.dumps({"usage": {"input_tokens": 5000}}) + "\n",
            "ScopeMetrics: value = 42\n",
        ]
        inp = StringIO("".join(lines))
        out_file = tmp_path / "capture.log"
        echo = StringIO()

        stream_redact(inp, out_file, echo)

        for content in [out_file.read_text(), echo.getvalue()]:
            assert "sk-ant" not in content
            assert "5000" in content
            assert "42" in content

    def test_interruption_only_redacted_on_disk(self, tmp_path):
        """Even partial input produces only redacted file content."""
        from io import StringIO

        lines = [
            json.dumps({"api_key": "sk-ant-secret1234567890"}) + "\n",
            json.dumps({"password": "hunter2"}) + "\n",
            "Bearer sk-ant-another-secret12345678901234567890\n",
        ]
        inp = StringIO("".join(lines))
        out_file = tmp_path / "capture.log"

        stream_redact(inp, out_file, None)

        content = out_file.read_text()
        assert "sk-ant" not in content
        assert "hunter2" not in content

    def test_no_file_without_path(self):
        """When no output path, only echo stream gets output."""
        from io import StringIO

        inp = StringIO("test line\n")
        echo = StringIO()

        count = stream_redact(inp, None, echo)
        assert count == 1
        assert echo.getvalue() == "test line\n"

    def test_empty_input(self, tmp_path):
        from io import StringIO

        out_file = tmp_path / "capture.log"
        count = stream_redact(StringIO(""), out_file, None)
        assert count == 0
        assert out_file.read_text() == ""

    def test_cli_entry_point_exists(self):
        """The module can be invoked as a script."""
        import subprocess

        result = subprocess.run(
            ["python3", "-c",
             f"import sys; sys.path.insert(0, '{PROJECT_ROOT}'); "
             "from lib.telemetry_redact import stream_redact; "
             "assert callable(stream_redact)"],
            capture_output=True, text=True,
        )
        assert result.returncode == 0, result.stderr


class TestPathWiring:
    """Launcher script path wiring must use streaming redaction."""

    def test_otel_dir_default(self):
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'tmp/otel-capture' in content

    def test_otel_log_in_otel_dir(self):
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'OTEL_LOG_FILE="${OTEL_DIR}/otel-console.log"' in content

    def test_uses_streaming_filter(self):
        """Launcher pipes stderr through telemetry_redact.py, not tee."""
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'telemetry_redact.py' in content
        assert 'FILTER_PID' in content

    def test_no_tee(self):
        """Raw tee is not used for capture."""
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'tee' not in content

    def test_no_post_run_redaction(self):
        """No post-run redact_file call — streaming handles it inline."""
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'redact_file' not in content

    def test_fifo_cleanup_trap(self):
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'mkfifo' in content
        assert '_cleanup_fifo' in content

    def test_no_fake_api_dump_env_var(self):
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'CLAUDE_API_DUMP_FILE' not in content

    def test_single_capture_path(self):
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'api-dump.jsonl' not in content


class TestDisabledDefaults:
    """Launcher defaults must keep capture disabled."""

    def test_otel_defaults_false(self):
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert '\nOTEL=false\n' in content

    def test_api_dump_defaults_false(self):
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert '\nAPI_DUMP=false\n' in content

    def test_telemetry_gated_by_otel_flag(self):
        """CLAUDE_CODE_ENABLE_TELEMETRY only appears inside if $OTEL blocks."""
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        lines = content.splitlines()
        in_otel_block = False
        for i, line in enumerate(lines, 1):
            if 'if $OTEL' in line:
                in_otel_block = True
            if 'CLAUDE_CODE_ENABLE_TELEMETRY' in line:
                assert in_otel_block or line.strip().startswith('#'), (
                    f"Line {i}: CLAUDE_CODE_ENABLE_TELEMETRY outside OTel block"
                )

    def test_env_sourcing_with_caller_precedence(self):
        """Launcher sources .env but caller-exported variables take precedence."""
        content = (PROJECT_ROOT / "scripts" / "run_claude_container.sh").read_text()
        assert 'source "$ROOT_DIR/.env"' in content
        assert "_SAVED_ENV" in content, "must save caller env before sourcing"
        assert "export" in content, "must restore caller env after sourcing"


class TestLauncherShellSyntax:
    """Launcher script must have valid shell syntax."""

    def test_shell_syntax(self):
        import subprocess

        result = subprocess.run(
            ["bash", "-n", str(PROJECT_ROOT / "scripts" / "run_claude_container.sh")],
            capture_output=True, text=True,
        )
        assert result.returncode == 0, f"Shell syntax error: {result.stderr}"

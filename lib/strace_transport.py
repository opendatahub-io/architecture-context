"""Strace-instrumented transport for Claude Agent SDK."""

from claude_agent_sdk._internal.transport.subprocess_cli import SubprocessCLITransport


class StracedTransport(SubprocessCLITransport):
    """Wraps the Claude CLI command with strace for syscall tracing."""

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


async def empty_async_iter():
    """Dummy async iterable — SubprocessCLITransport stores but never reads it."""
    return
    yield

"""Progress display for concurrent agent execution."""

import time

from rich.console import Console
from rich.live import Live
from rich.table import Table

console = Console()


def _format_duration(seconds: float) -> str:
    total = int(seconds)
    h, remainder = divmod(total, 3600)
    m, s = divmod(remainder, 60)
    if h:
        return f"{h}h {m}m {s}s"
    if m:
        return f"{m}m {s}s"
    return f"{s}s"


class AgentProgress:
    """Track and display progress for concurrent agent jobs.

    Uses rich.live.Live to pin a progress panel at the bottom of the terminal.
    Agent output printed via log() scrolls above it.
    """

    def __init__(self, total: int, max_concurrent: int):
        self.total = total
        self.max_concurrent = max_concurrent
        self.completed = 0
        self.failed = 0
        self.running: dict[str, float] = {}
        self.completion_times: list[float] = []
        self.start_time = time.monotonic()
        self.live = Live(
            self._render(),
            console=console,
            refresh_per_second=1,
            vertical_overflow="visible",
        )

    def _estimate_eta(self) -> str:
        if not self.completion_times:
            return "calculating..."
        avg = sum(self.completion_times) / len(self.completion_times)
        remaining = self.total - self.completed - self.failed
        if remaining <= 0:
            return "done"
        parallel = min(remaining, self.max_concurrent)
        batches = remaining / parallel
        eta_seconds = avg * batches
        return f"~{_format_duration(eta_seconds)}"

    def _render(self):
        elapsed = time.monotonic() - self.start_time
        done = self.completed + self.failed
        pct = int(done / self.total * 100) if self.total else 0
        bar_width = 20
        filled = int(bar_width * done / self.total) if self.total else 0
        bar = "█" * filled + "░" * (bar_width - filled)

        table = Table(
            show_header=False, show_edge=False, box=None,
            padding=(0, 1), min_width=60,
        )
        table.add_column(ratio=1)
        table.add_row(f"━" * 60)
        table.add_row(f" Progress: {done}/{self.total}  {bar}  {pct}%")

        running_names = list(self.running.keys())
        if running_names:
            display = ", ".join(running_names[:5])
            if len(running_names) > 5:
                display += f" (+{len(running_names) - 5})"
            table.add_row(f" Running: {display}")

        status_parts = [f"Elapsed: {_format_duration(elapsed)}"]
        if done < self.total:
            status_parts.append(f"ETA: {self._estimate_eta()}")
        if self.failed:
            status_parts.append(f"Failed: {self.failed}")
        table.add_row(f" {' | '.join(status_parts)}")
        table.add_row(f"━" * 60)

        return table

    def start(self):
        self.live.start()

    def stop(self):
        self.live.stop()

    def agent_started(self, name: str):
        self.running[name] = time.monotonic()
        self.live.update(self._render())

    def agent_completed(self, name: str, success: bool):
        start = self.running.pop(name, self.start_time)
        duration = time.monotonic() - start
        if success:
            self.completed += 1
        else:
            self.failed += 1
        self.completion_times.append(duration)
        self.live.update(self._render())

    def log(self, msg: str):
        """Print a message that scrolls above the progress panel."""
        console.print(msg, markup=False, highlight=False)

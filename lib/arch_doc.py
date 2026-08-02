"""Integration helpers for the repository-local arch-doc command."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ARCH_DOC_SOURCE = PROJECT_ROOT / "src" / "arch-doc"
ARCH_DOC_BINARY = PROJECT_ROOT / "bin" / "arch-doc"


def ensure_arch_doc_binary() -> Path:
    """Build and return arch-doc when the repository binary is not present."""

    configured = os.environ.get("ARCH_DOC_BIN")
    binary = Path(configured).expanduser().resolve() if configured else ARCH_DOC_BINARY
    if binary.is_file() and os.access(binary, os.X_OK) and not _source_is_newer(binary):
        return binary
    if not ARCH_DOC_SOURCE.is_dir():
        raise FileNotFoundError(
            f"arch-doc source directory not found: {ARCH_DOC_SOURCE}"
        )
    binary.parent.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment.setdefault("GOCACHE", "/tmp/arch-doc-gocache")
    completed = _run_process(
        ["go", "build", "-o", str(binary), "."],
        cwd=ARCH_DOC_SOURCE,
        env=environment,
    )
    if completed.returncode != 0:
        detail = (completed.stdout + completed.stderr).strip()
        raise RuntimeError(f"failed to build arch-doc: {detail}")
    return binary


def assemble_architecture_sections(base_text: str, candidate_text: str) -> str:
    """Assemble candidate synthesis sections onto a table-merged base."""

    binary = ensure_arch_doc_binary()
    with TemporaryDirectory(prefix="arch-doc-") as temporary:
        root = Path(temporary)
        base = root / "base.md"
        candidate = root / "candidate.md"
        output = root / "assembled.md"
        base.write_text(base_text)
        candidate.write_text(candidate_text)
        completed = _run_process(
            [
                str(binary),
                "assemble",
                "--base",
                str(base),
                "--candidate",
                str(candidate),
                "--output",
                str(output),
            ],
        )
        if completed.returncode != 0:
            detail = (completed.stdout + completed.stderr).strip()
            raise ValueError(f"arch-doc assemble failed: {detail}")
        return output.read_text()


def _run_process(command: list[str], **kwargs) -> subprocess.CompletedProcess[str]:
    """Run a process without using subprocess.run, which tests may patch globally."""

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        **kwargs,
    )
    stdout, stderr = process.communicate()
    return subprocess.CompletedProcess(command, process.returncode, stdout, stderr)


def _source_is_newer(binary: Path) -> bool:
    """Return whether a source or manifest file is newer than the binary."""

    binary_mtime = binary.stat().st_mtime
    source_files = list(ARCH_DOC_SOURCE.glob("*.go")) + [
        ARCH_DOC_SOURCE / "go.mod",
        ARCH_DOC_SOURCE / "section-manifest.json",
    ]
    return any(
        path.is_file() and path.stat().st_mtime > binary_mtime
        for path in source_files
    )

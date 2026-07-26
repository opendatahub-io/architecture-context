"""Streaming secret redaction for OTel telemetry capture.

Provides both a streaming filter (``stream_redact``) and a batch
file rewriter (``redact_file``).  The streaming filter is the primary
redaction boundary: content is sanitized line-by-line *before* any
persistent write, so capture files never contain raw secrets.

Redaction is deterministic and failure-tolerant: malformed lines get
value-pattern redaction, and I/O errors are surfaced but never crash
the caller.

CLI usage (streaming filter, used by the container launcher)::

    command 2>&1 | python3 lib/telemetry_redact.py output.log
"""

from __future__ import annotations

import json
import re
import tempfile
from pathlib import Path

REDACTED = "[REDACTED]"

_SENSITIVE_KEY_PATTERNS = re.compile(
    r"(api[_-]?key|auth(orization)?|token|secret|password|credential|cookie"
    r"|session[_-]?id|x-api-key|bearer|access[_-]?key|private[_-]?key"
    r"|client[_-]?secret|refresh[_-]?token)",
    re.IGNORECASE,
)

_BEARER_PATTERN = re.compile(
    r"(Bearer\s+)\S+", re.IGNORECASE,
)

_API_KEY_VALUE_PATTERNS = [
    re.compile(r"(sk-(?:ant-)?[a-zA-Z0-9_-]{10,})"),
    re.compile(r"(ghp_[a-zA-Z0-9]{30,})"),
    re.compile(r"(gho_[a-zA-Z0-9]{30,})"),
    re.compile(r"(xox[bprs]-[a-zA-Z0-9-]{10,})"),
    re.compile(r"(ya29\.[a-zA-Z0-9_-]{30,})"),
]


def redact_value(key: str, value: object) -> object:
    """Redact a single key-value pair if the key matches sensitive patterns."""
    if isinstance(value, str):
        if _SENSITIVE_KEY_PATTERNS.search(key):
            return REDACTED
        value = _BEARER_PATTERN.sub(rf"\1{REDACTED}", value)
        for pat in _API_KEY_VALUE_PATTERNS:
            value = pat.sub(REDACTED, value)
    return value


def redact_dict(d: dict) -> dict:
    """Recursively redact sensitive values in a dictionary."""
    result = {}
    for key, value in d.items():
        if isinstance(value, dict):
            result[key] = redact_dict(value)
        elif isinstance(value, list):
            result[key] = [
                redact_dict(item) if isinstance(item, dict)
                else redact_value(key, item)
                for item in value
            ]
        else:
            result[key] = redact_value(key, value)
    return result


def _redact_text(text: str) -> str:
    """Apply value-pattern redaction to a plain text string."""
    result = _BEARER_PATTERN.sub(rf"\1{REDACTED}", text)
    for pat in _API_KEY_VALUE_PATTERNS:
        result = pat.sub(REDACTED, result)
    return result


def redact_line(line: str) -> str:
    """Redact a single line. JSON lines get full dict redaction; non-JSON
    lines get value-pattern redaction for Bearer tokens and API keys."""
    stripped = line.strip()
    if not stripped:
        return line
    try:
        record = json.loads(stripped)
    except (json.JSONDecodeError, ValueError):
        return _redact_text(line)
    if isinstance(record, dict):
        record = redact_dict(record)
    return json.dumps(record, sort_keys=True) + "\n"


def redact_file(path: str | Path) -> int:
    """Redact an API dump JSONL file in place.

    Returns the number of lines processed.  Uses atomic write via a
    temporary file in the same directory to avoid partial output on
    failure.
    """
    p = Path(path)
    if not p.exists():
        return 0

    try:
        lines = p.read_text().splitlines(keepends=True)
    except (OSError, UnicodeDecodeError):
        return 0
    parent = p.parent

    redacted_lines = [redact_line(line) for line in lines]

    fd = tempfile.NamedTemporaryFile(
        mode="w", dir=parent, prefix=".redact-", suffix=".tmp",
        delete=False,
    )
    try:
        fd.writelines(redacted_lines)
        fd.flush()
        fd.close()
        Path(fd.name).replace(p)
    except OSError:
        Path(fd.name).unlink(missing_ok=True)
        raise

    return len(lines)


def stream_redact(input_stream, output_path=None, echo_stream=None):
    """Streaming redaction filter — the primary redaction boundary.

    Reads lines from *input_stream*, redacts each one, writes to
    *output_path* (when set) and echoes to *echo_stream* (when set).
    Every line is flushed immediately so content on disk is always
    sanitized, even if the process is interrupted mid-stream.

    Returns the number of lines processed.
    """
    count = 0
    output_fd = None
    try:
        if output_path is not None:
            output_fd = open(Path(output_path), "w")  # noqa: SIM115
        for line in input_stream:
            clean = redact_line(line)
            if output_fd is not None:
                output_fd.write(clean)
                output_fd.flush()
            if echo_stream is not None:
                echo_stream.write(clean)
                echo_stream.flush()
            count += 1
    finally:
        if output_fd is not None:
            output_fd.close()
    return count


if __name__ == "__main__":
    import sys as _sys

    _output = _sys.argv[1] if len(_sys.argv) > 1 else None
    stream_redact(_sys.stdin, _output, _sys.stdout)

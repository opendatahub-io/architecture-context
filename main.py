#!/usr/bin/env python3
"""Repository processing and analysis tool."""

import asyncio
import sys
import traceback
from pathlib import Path

from dotenv import load_dotenv

from lib.cli import parse_args
from lib.phases.orchestration import main

_AGENT_COMMANDS = frozenset({
    "discover-components",
    "generate-architecture",
    "generate-platform-architecture",
    "generate-diagrams",
    "all",
})
_AGENT_PHASES = frozenset({
    "discover-components",
    "generate-architecture",
    "generate-platform-architecture",
    "generate-diagrams",
})


def _uses_claude(args) -> bool:
    """Return whether this invocation will launch a Claude SDK agent."""
    if getattr(args, "harness", "claude") != "claude":
        return False
    if args.command in _AGENT_COMMANDS:
        return True
    if args.command == "pipeline":
        return bool(_AGENT_PHASES.intersection(getattr(args, "phase", ())))
    return False


def _load_agent_environment(args) -> None:
    """Load optional local secrets and enforce Claude's legacy requirement."""
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=env_path)
        return
    if _uses_claude(args):
        raise RuntimeError(
            f".env file not found at {env_path}; Claude agent phases require "
            "ANTHROPIC_API_KEY. Codex phases use the existing Codex login."
        )


if __name__ == "__main__":
    args = parse_args()
    try:
        _load_agent_environment(args)
        asyncio.run(main(args))
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        detail = str(e).strip() or "no exception message"
        print(
            f"\nError [{type(e).__name__}]: {detail}",
            file=sys.stderr,
            flush=True,
        )
        traceback.print_exc()
        sys.exit(1)

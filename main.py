#!/usr/bin/env python3
"""Repository processing and analysis tool."""

import sys
import asyncio
from pathlib import Path

from dotenv import load_dotenv

from lib.cli import parse_args
from lib.phases import main

# Load environment variables from .env file
env_path = Path(__file__).parent / ".env"
if not env_path.exists():
    print(
        "Error: .env file not found\n"
        "\n"
        f"Expected location: {env_path}\n"
        "\n"
        "Create a .env file with at minimum:\n"
        "\n"
        "  ANTHROPIC_API_KEY=sk-ant-...\n"
        "\n"
        "The Claude Agent SDK requires a valid API key to spawn agents.",
        file=sys.stderr,
    )
    sys.exit(1)
load_dotenv(dotenv_path=env_path)


if __name__ == "__main__":
    args = parse_args()
    try:
        asyncio.run(main(args))
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)

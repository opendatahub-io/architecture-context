import os
import asyncio
from pathlib import Path

from dotenv import load_dotenv
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions

# Load environment variables from .env file
load_dotenv()


# ---- REQUIRED ENV VARS FOR VERTEX ----
# export CLAUDE_CODE_USE_VERTEX=1
# export CLOUD_ML_REGION=global
# export ANTHROPIC_VERTEX_PROJECT_ID=your-gcp-project-id
#
# And authenticate with GCP first, for example:
# gcloud auth application-default login
#
# Docs: Claude Code / Agent SDK support Vertex auth via standard Google Cloud credentials.


def require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


async def run_agent(name: str, cwd: str, prompt: str) -> None:
    """
    Launch one independent Claude agent session.
    """
    options = ClaudeAgentOptions(
        cwd=cwd,
        allowed_tools=["Read", "Write", "Edit", "Bash"],
        permission_mode="acceptEdits",
        max_turns=8,
    )

    print(f"\n=== starting {name} in {cwd} ===")

    try:
        async with ClaudeSDKClient(options=options) as client:
            await client.query(prompt)

            async for msg in client.receive_response():
                # Super minimal output handling.
                # The SDK returns structured message objects; for a starter script
                # we just print the raw object.
                print(f"\n[{name}] {msg}")

    except Exception as e:
        print(f"\n[{name}] ERROR: {e}")


async def main() -> None:
    # Basic validation so failures are obvious.
    require_env("CLAUDE_CODE_USE_VERTEX")
    require_env("CLOUD_ML_REGION")
    require_env("ANTHROPIC_VERTEX_PROJECT_ID")

    cwd = os.getcwd()

    jobs = [
        {
            "name": "agent-1",
            "cwd": cwd,
            "prompt": "write a 20 word story and save it to story1.md",
        },
        {
            "name": "agent-2",
            "cwd": cwd,
            "prompt": "write a 20 word story and save it to story2.md",
        },
        {
            "name": "agent-3",
            "cwd": cwd,
            "prompt": "write a 20 word story and save it to story3.md",
        },
    ]

    await asyncio.gather(
        *(run_agent(job["name"], job["cwd"], job["prompt"]) for job in jobs)
    )


if __name__ == "__main__":
    asyncio.run(main())

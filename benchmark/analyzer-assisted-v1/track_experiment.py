#!/usr/bin/env python3
"""CLI for tracking analyzer-assisted experiment results to MLflow.

Maps validated result records to MLflow experiments and runs with
deterministic tags, metrics, provenance, and artifact references.
Uses only stdlib HTTP — no MLflow SDK dependency.

Usage:
    # Preflight check (no network required)
    python3 benchmark/analyzer-assisted-v1/track_experiment.py --preflight

    # Dry-run: show what would be logged without contacting MLflow
    python3 benchmark/analyzer-assisted-v1/track_experiment.py \
        --dry-run --result-file path/to/raw-results.json

    # Log a result (requires MLFLOW_TRACKING_URI)
    python3 benchmark/analyzer-assisted-v1/track_experiment.py \
        --result-file path/to/raw-results.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

from lib.mlflow_tracking import (  # noqa: E402
    TRACKING_CONTRACT_VERSION,
    TrackingConfig,
    preflight,
    track_result,
)


def cmd_preflight(args: argparse.Namespace) -> int:
    """Run preflight check and print status."""
    config = TrackingConfig.from_env(dry_run=args.dry_run)
    result = preflight(config)

    output = result.to_dict()
    output["tracking_contract_version"] = TRACKING_CONTRACT_VERSION
    json.dump(output, sys.stdout, indent=2)
    sys.stdout.write("\n")

    if not result.ok:
        for err in result.errors:
            print(f"  PREFLIGHT: {err}", file=sys.stderr)
        return 1
    return 0


def cmd_track(args: argparse.Namespace) -> int:
    """Track a result file to MLflow."""
    result_path = Path(args.result_file)
    if not result_path.exists():
        print(f"error: result file not found: {result_path}", file=sys.stderr)
        return 1

    with open(result_path) as f:
        result_data = json.load(f)

    config = TrackingConfig.from_env(dry_run=args.dry_run)

    if not args.dry_run:
        pf = preflight(config)
        if not pf.ok:
            print("Preflight check failed:", file=sys.stderr)
            for err in pf.errors:
                print(f"  {err}", file=sys.stderr)
            return 1

    tracking_result = track_result(result_data, config)

    json.dump(tracking_result.to_dict(), sys.stdout, indent=2)
    sys.stdout.write("\n")

    if not tracking_result.success:
        print(
            f"  TRACKING ERROR: {tracking_result.error}",
            file=sys.stderr,
        )
        return 1

    if args.dry_run:
        print("  DRY-RUN: no MLflow state created", file=sys.stderr)

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Track analyzer-assisted experiment results to MLflow.",
    )
    parser.add_argument(
        "--preflight",
        action="store_true",
        help="Run preflight check and exit.",
    )
    parser.add_argument(
        "--result-file",
        type=str,
        default=None,
        help="Path to a validated result JSON file to track.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help=(
            "Show tags, metrics, and artifact references that would be "
            "logged without contacting MLflow."
        ),
    )
    args = parser.parse_args()

    if args.preflight:
        return cmd_preflight(args)

    if args.result_file:
        return cmd_track(args)

    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())

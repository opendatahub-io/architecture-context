"""Phase 3: Generate component architecture documentation."""

import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

from lib.agent_runner import (
    format_duration,
    get_model_display_name,
    run_agents_concurrently,
)
from lib.architecture_merge import merge_architecture_files
from lib.architecture_routing import load_architecture_agent_policy
from lib.cli import resolve_distribution
from lib.component_discovery import (
    apply_component_selection,
    apply_platform_overrides,
    get_component_map_metadata,
    read_component_map,
)
from lib.fetch import load_platform_config

CHANGE_RECORD_FILENAME = "ARCHITECTURE_CHANGES.md"


async def run_generate_architecture_phase(args) -> None:
    """Run Phase 3: Generate architecture documentation."""
    print("\n" + "=" * 60)
    print("PHASE 3: Generating component architectures")
    print("=" * 60 + "\n")

    architecture_dir = getattr(args, "architecture_dir", "architecture")
    distribution = resolve_distribution(args.platform)

    # Load components from component-map.json
    components = read_component_map(args.platform, architecture_dir=architecture_dir)
    if components is None:
        print(f"ERROR: No component-map.json found for platform '{args.platform}'")
        print(f"Expected: {architecture_dir}/{args.platform}/component-map.json")
        print("\nRun discover-components first:")
        print(f"  uv run main.py discover-components --platform={args.platform}")
        return

    # Apply platform overrides (exclude_components, include_components, etc.)
    platform_config = load_platform_config(args.platform)
    if platform_config:
        checkouts_dir = getattr(args, "checkouts_dir", "checkouts")
        components = apply_platform_overrides(
            components,
            platform_config,
            checkouts_base=checkouts_dir,
        )
    components = apply_component_selection(
        components,
        get_component_map_metadata(args.platform, architecture_dir),
    )

    if not components:
        print("No components found with checkouts")
        return

    # Apply component filter if specified
    if args.component:
        if args.component in components:
            components = {args.component: components[args.component]}
            print(f"Filtered to single component: {args.component}\n")
        else:
            print(f"ERROR: Component '{args.component}' not found")
            print(f"Available components: {', '.join(sorted(components.keys()))}")
            return

    # Filter to components with actual checkouts on disk
    components = {
        k: v
        for k, v in components.items()
        if v.checkout_path and v.checkout_path.exists()
    }

    # Apply tier filter
    tier_filter = getattr(args, "tier", "all")
    if tier_filter == "significant":
        before = len(components)
        components = {
            k: v for k, v in components.items() if v.architecturally_significant
        }
        print(f"Tier filter 'significant': {before} -> {len(components)} components")
    elif tier_filter == "core":
        before = len(components)
        components = {
            k: v
            for k, v in components.items()
            if v.tier in ("core_platform", "optional_platform")
        }
        print(f"Tier filter 'core': {before} -> {len(components)} components")

    # Refresh has_architecture from filesystem (component-map may be stale)
    for component in components.values():
        arch_file = component.checkout_path / "GENERATED_ARCHITECTURE.md"
        component.has_architecture = arch_file.exists()

    # Handle --force: delete existing GENERATED_ARCHITECTURE.md files
    if args.force:
        print("Force mode: Deleting existing GENERATED_ARCHITECTURE.md files...\n")
        for component in components.values():
            arch_file = component.checkout_path / "GENERATED_ARCHITECTURE.md"
            if arch_file.exists():
                arch_file.unlink()
                print(f"  Deleted: {component.key}/GENERATED_ARCHITECTURE.md")
                component.has_architecture = False  # Update status
            if getattr(args, "evidence_gated_merge", False):
                change_file = component.checkout_path / CHANGE_RECORD_FILENAME
                if change_file.exists():
                    change_file.unlink()
        print()

    # Filter to components missing architecture
    # (unless --force, which already deleted them)
    missing_arch = [c for c in components.values() if not c.has_architecture]
    has_arch = [c for c in components.values() if c.has_architecture]

    print(f"Found {len(components)} components:")
    print(f"  Already documented: {len(has_arch)}")
    print(f"  Need architecture: {len(missing_arch)}")
    print()

    if not missing_arch:
        print("All components already have architecture documentation!")
        return

    # Prepare generation work. Analyzer-only entries never become agent jobs.
    model_display = get_model_display_name(args.model)
    readiness_routing = getattr(args, "evidence_gated_merge", False)
    work_items = []
    for component in sorted(missing_arch, key=lambda c: c.key):
        policy = load_architecture_agent_policy(
            component.checkout_path,
            readiness_routing=readiness_routing,
        )
        checkout_path = str(component.checkout_path.resolve())
        prompt = ""
        if not policy.analyzer_only:
            prompt = (
                f"/repo-to-architecture-summary {checkout_path}"
                f" --distribution={distribution}"
                f" --output=GENERATED_ARCHITECTURE.md"
                f" --generated-by={model_display}"
                f" {policy.prompt_arguments()}"
            )
            if policy.evidence_gated:
                prompt += f" --change-output={CHANGE_RECORD_FILENAME}"

        job = {
            "name": f"{component.key}",
            "cwd": ".",
            "prompt": prompt,
            "repo": f"{component.repo_org}/{component.repo_name}",
            "checkout_path": component.checkout_path,
            "agent_policy": policy.to_dict(),
        }
        work_items.append(job)

    # Apply limit if specified
    if args.limit:
        work_items = work_items[: args.limit]
        print(f"Limited to first {args.limit} component(s)\n")

    jobs = []
    analyzer_only_results = {}
    for item in work_items:
        policy = item["agent_policy"]
        analyzer_file = item["checkout_path"] / "ANALYZER_ARCHITECTURE.md"
        output_file = item["checkout_path"] / "GENERATED_ARCHITECTURE.md"
        if policy.get("route") == "analyzer-only":
            started = time.monotonic()
            try:
                shutil.copy2(analyzer_file, output_file)
                _validate_generated_architecture(output_file)
                result = {
                    "name": item["name"],
                    "success": True,
                    "duration_seconds": time.monotonic() - started,
                    "telemetry": {},
                    "merge": None,
                    "log_file": None,
                }
            except Exception as error:
                result = {
                    "name": item["name"],
                    "success": False,
                    "duration_seconds": time.monotonic() - started,
                    "error": f"analyzer-only generation failed: {error}",
                    "telemetry": {},
                    "merge": None,
                    "log_file": None,
                }
            result["routing"] = policy
            analyzer_only_results[item["name"]] = result
            continue
        if policy.get("route") == "evidence-gated":
            shutil.copy2(analyzer_file, output_file)
        jobs.append(item)

    # Display prepared jobs
    print(
        f"Prepared {len(jobs)} agent job(s) and "
        f"{len(analyzer_only_results)} analyzer-only document(s):\n"
    )
    for i, job in enumerate(jobs, 1):
        print(f"{i:2d}. {job['name']:30s} {job['repo']}")
        print(f"    cwd: {job['cwd']}")
        print()

    # Create logs directory
    log_dir = Path(getattr(args, "log_dir", "logs/generate-architecture"))
    log_dir.mkdir(parents=True, exist_ok=True)
    print(f"Logs will be written to: {log_dir}\n")

    print(f"{'=' * 60}")
    print(f"Ready to process {len(work_items)} component(s)")
    print(f"Max concurrent agents: {args.max_concurrent}")
    print(f"Model: {args.model}")
    print(f"{'=' * 60}\n")

    strace_prefix = (
        f"{args.platform}-generate-architecture"
        if getattr(args, "strace", False)
        else None
    )
    results = []
    if jobs:
        results = await run_agents_concurrently(
            jobs,
            log_dir,
            args.model,
            args.max_concurrent,
            enable_skills=True,
            strace_prefix=strace_prefix,
        )

    # Recover crashed agents that still produced output.
    # The CLI subprocess can crash on benign text patterns (e.g., [/path])
    # after the agent has already written the architecture file.
    # Handles both failed dicts (from run_agent's except block) and raw
    # Exception objects (from asyncio.gather return_exceptions=True).
    recovered = []
    for i, (job, result) in enumerate(zip(jobs, results)):
        if isinstance(result, dict) and result.get("success"):
            continue
        arch_file = job["checkout_path"] / "GENERATED_ARCHITECTURE.md"
        if arch_file.exists() and arch_file.stat().st_size > 1000:
            if isinstance(result, Exception):
                results[i] = {
                    "name": job["name"],
                    "success": True,
                    "recovered": True,
                    "error": str(result),
                    "log_file": str(log_dir / f"{job['name'].replace('/', '_')}.log"),
                    "duration_seconds": 0,
                }
            else:
                result["success"] = True
                result["recovered"] = True
            recovered.append(results[i])

    if recovered:
        print(
            f"\nRecovered {len(recovered)} agent(s) that crashed after writing output:"
        )
        for r in recovered:
            err = r.get("error", "")[:80]
            print(f"  ~ {r['name']}: crashed ({err}) but output file exists")

    for job, result in zip(jobs, results):
        if isinstance(result, dict):
            result["routing"] = job["agent_policy"]

    if readiness_routing:
        _merge_agent_outputs(jobs, results, log_dir)
    result_by_name = dict(analyzer_only_results)
    result_by_name.update(zip((job["name"] for job in jobs), results))
    all_results = [result_by_name[item["name"]] for item in work_items]
    _write_agent_run_reports(work_items, all_results, log_dir)

    # Summary
    successful = [r for r in all_results if isinstance(r, dict) and r.get("success")]
    failed = [r for r in all_results if isinstance(r, dict) and not r.get("success")]
    exceptions = [r for r in all_results if isinstance(r, Exception)]

    print("\n" + "=" * 60)
    print("ARCHITECTURE GENERATION COMPLETE")
    print("=" * 60)
    print(f"Total components: {len(work_items)}")
    print(f"Agent invocations: {len(jobs)}")
    print(f"Analyzer-only: {len(analyzer_only_results)}")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(failed)}")
    if exceptions:
        print(f"Exceptions: {len(exceptions)}")

    if failed:
        print("\nFailed components:")
        for r in failed:
            print(f"  x {r['name']}: {r.get('error', 'unknown error')}")
            if r.get("log_file"):
                print(f"    Log: {r['log_file']}")

    if exceptions:
        print("\nComponents with exceptions:")
        for i, exc in enumerate(exceptions):
            print(f"  x Exception {i + 1}: {exc}")

    # Inject generation duration into each successful component's architecture file
    for job, result in zip(work_items, all_results):
        if not isinstance(result, dict) or not result.get("success"):
            continue
        arch_file = job["checkout_path"] / "GENERATED_ARCHITECTURE.md"
        if not arch_file.exists():
            continue
        elapsed = result.get("duration_seconds", 0)
        duration_line = (
            f"\n---\n*Generated in {format_duration(elapsed)} ({elapsed:.0f}s total)*\n"
        )
        with open(arch_file, "a") as f:
            f.write(duration_line)

    print(f"\nAll generation logs available in: {log_dir}")
    print("=" * 60)


def _validate_generated_architecture(path: Path) -> None:
    """Validate a generated component document and raise on failure."""

    validator = (
        Path(__file__).resolve().parents[2]
        / ".claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py"
    )
    validation = subprocess.run(
        [sys.executable, str(validator), str(path)],
        check=False,
        capture_output=True,
        text=True,
    )
    if validation.returncode != 0:
        raise ValueError(
            "architecture validation failed: "
            + (validation.stdout + validation.stderr).strip()
        )


def _merge_agent_outputs(jobs, results, log_dir: Path) -> None:
    """Archive, evidence-gate, and validate successful agent candidates."""

    validator = (
        Path(__file__).resolve().parents[2]
        / ".claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py"
    )
    for job, result in zip(jobs, results):
        if not isinstance(result, dict) or not result.get("success"):
            continue
        if job.get("agent_policy", {}).get("route") != "evidence-gated":
            continue
        checkout = Path(job["checkout_path"])
        analyzer = checkout / "ANALYZER_ARCHITECTURE.md"
        candidate = checkout / "GENERATED_ARCHITECTURE.md"
        changes = checkout / CHANGE_RECORD_FILENAME
        name = str(job["name"]).replace("/", "_")
        raw_candidate = log_dir / f"{name}.candidate.md"
        archived_changes = log_dir / f"{name}.changes.md"
        report_json = log_dir / f"{name}.merge.json"
        report_markdown = log_dir / f"{name}.merge.md"
        merge_started = time.monotonic()
        try:
            if not analyzer.is_file():
                raise FileNotFoundError(f"missing analyzer baseline: {analyzer}")
            if not candidate.is_file():
                raise FileNotFoundError(f"missing agent candidate: {candidate}")
            shutil.copy2(candidate, raw_candidate)
            if changes.is_file():
                shutil.copy2(changes, archived_changes)
            merge_result = merge_architecture_files(
                analyzer,
                raw_candidate,
                candidate,
                changes=archived_changes if archived_changes.is_file() else None,
                report_json=report_json,
                report_markdown=report_markdown,
                component=job["name"],
                allowed_change_categories=tuple(
                    job.get("agent_policy", {}).get("gap_categories", ())
                ),
            )
            validation = subprocess.run(
                [sys.executable, str(validator), str(candidate)],
                check=False,
                capture_output=True,
                text=True,
            )
            if validation.returncode != 0:
                raise ValueError(
                    "merged architecture validation failed: "
                    + (validation.stdout + validation.stderr).strip()
                )
            result["merge"] = {
                "raw_candidate": str(raw_candidate),
                "changes": (
                    str(archived_changes) if archived_changes.is_file() else None
                ),
                "report_json": str(report_json),
                "report_markdown": str(report_markdown),
                "counts": merge_result.counts,
                "duration_seconds": time.monotonic() - merge_started,
            }
            print(
                f"Merged: {job['name']} "
                f"({json.dumps(merge_result.counts, sort_keys=True)})"
            )
        except Exception as error:
            result["success"] = False
            result["error"] = f"evidence-gated merge failed: {error}"
            result["merge"] = {
                "duration_seconds": time.monotonic() - merge_started,
                "error": str(error),
            }
            print(f"Merge failed: {job['name']}: {error}")


def _write_agent_run_reports(jobs, results, log_dir: Path) -> None:
    """Persist routing, usage, and merge telemetry for corpus aggregation."""

    for job, result in zip(jobs, results):
        if not isinstance(result, dict):
            continue
        name = str(job["name"]).replace("/", "_")
        report = {
            "schema_version": 1,
            "component": job["name"],
            "success": bool(result.get("success")),
            "error": result.get("error"),
            "duration_seconds": result.get("duration_seconds"),
            "routing": result.get("routing", job.get("agent_policy", {})),
            "telemetry": result.get("telemetry", {}),
            "merge": result.get("merge"),
            "log_file": result.get("log_file"),
        }
        (log_dir / f"{name}.run.json").write_text(
            json.dumps(report, indent=2, sort_keys=True) + "\n"
        )

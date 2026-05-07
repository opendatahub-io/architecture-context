"""Phase 2c: Run arch-analyzer static analysis on component repositories."""

import asyncio
from pathlib import Path

from lib.component_discovery import apply_platform_overrides, read_component_map
from lib.fetch import _ensure_arch_analyzer, load_platform_config


async def _run_extract(
    arch_analyzer_cmd: str,
    component_key: str,
    checkout_path: Path,
    force: bool = False,
) -> dict:
    """Run arch-analyzer extract on a single component."""
    result = {
        "name": component_key,
        "success": False,
        "extract_file": None,
        "error": None,
    }

    json_file = checkout_path / "component-architecture.json"

    if json_file.exists() and not force:
        result["success"] = True
        result["extract_file"] = str(json_file)
        result["skipped"] = True
        return result

    proc = await asyncio.create_subprocess_exec(
        arch_analyzer_cmd, "extract", ".",
        cwd=str(checkout_path),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await proc.communicate()

    if proc.returncode != 0:
        result["error"] = stderr.decode().strip()[:500]
        return result

    # arch-analyzer writes to output/component-architecture.json or CWD
    # Check both locations and move if needed
    output_subdir = checkout_path / "output" / "component-architecture.json"
    if output_subdir.exists() and not json_file.exists():
        output_subdir.rename(json_file)
        output_dir = checkout_path / "output"
        if output_dir.exists() and not any(output_dir.iterdir()):
            output_dir.rmdir()

    if not json_file.exists():
        result["error"] = "extract completed but component-architecture.json not found"
        return result

    result["success"] = True
    result["extract_file"] = str(json_file)
    return result


async def _run_extract_schema(
    arch_analyzer_cmd: str,
    component_key: str,
    checkout_path: Path,
    force: bool = False,
) -> dict:
    """Run arch-analyzer extract-schema on a single component."""
    result = {
        "name": component_key,
        "success": False,
        "schemas_dir": None,
        "schema_count": 0,
        "error": None,
    }

    # extract-schema writes to contracts/schemas/ by default
    schemas_dir = checkout_path / "contracts" / "schemas"

    if schemas_dir.exists() and any(schemas_dir.glob("*.json")) and not force:
        schema_count = len(list(schemas_dir.glob("*.json")))
        result["success"] = True
        result["schemas_dir"] = str(schemas_dir)
        result["schema_count"] = schema_count
        result["skipped"] = True
        return result

    proc = await asyncio.create_subprocess_exec(
        arch_analyzer_cmd, "extract-schema", ".",
        cwd=str(checkout_path),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await proc.communicate()

    if proc.returncode != 0:
        stderr_text = stderr.decode().strip()
        if "no CRD files found" in stderr_text.lower():
            result["success"] = True
            result["schema_count"] = 0
            return result
        result["error"] = stderr_text[:500]
        return result

    # Also check if schemas ended up in output/schemas/
    output_schemas = checkout_path / "output" / "schemas"
    if output_schemas.exists() and not schemas_dir.exists():
        schemas_dir.parent.mkdir(parents=True, exist_ok=True)
        output_schemas.rename(schemas_dir)

    # Count schemas from either location
    for candidate in [schemas_dir, checkout_path / "contracts" / "schemas"]:
        if candidate.exists():
            files = list(candidate.rglob("*.json"))
            if files:
                result["success"] = True
                result["schemas_dir"] = str(candidate)
                result["schema_count"] = len(files)
                return result

    result["success"] = True
    result["schema_count"] = 0
    return result


async def _analyze_component(
    arch_analyzer_cmd: str,
    component_key: str,
    checkout_path: Path,
    sem: asyncio.Semaphore,
    force: bool = False,
    skip_schemas: bool = False,
) -> dict:
    """Run extract and extract-schema on a single component."""
    async with sem:
        extract_result = await _run_extract(
            arch_analyzer_cmd, component_key, checkout_path, force,
        )

        schema_result = None
        if not skip_schemas:
            schema_result = await _run_extract_schema(
                arch_analyzer_cmd, component_key, checkout_path, force,
            )

        return {
            "name": component_key,
            "extract": extract_result,
            "schema": schema_result,
        }


async def run_static_analysis_phase(args) -> None:
    """Run Phase 2c: Static analysis via arch-analyzer."""
    print("\n" + "=" * 60)
    print("PHASE 2c: Static analysis (arch-analyzer)")
    print("=" * 60 + "\n")

    architecture_dir = getattr(args, 'architecture_dir', 'architecture')
    force = getattr(args, 'force', False)
    skip_schemas = getattr(args, 'skip_schemas', False)
    max_concurrent = getattr(args, 'max_concurrent', 10)

    # Load components from component-map.json
    components = read_component_map(args.platform, architecture_dir=architecture_dir)
    if components is None:
        print(f"ERROR: No component-map.json found for platform '{args.platform}'")
        print(f"Expected: {architecture_dir}/{args.platform}/component-map.json")
        print("\nRun discover-components first:")
        print(f"  uv run main.py discover-components --platform={args.platform}")
        return

    # Apply platform overrides
    platform_config = load_platform_config(args.platform)
    if platform_config:
        checkouts_dir = getattr(args, 'checkouts_dir', 'checkouts')
        components = apply_platform_overrides(
            components, platform_config, checkouts_base=checkouts_dir,
        )

    # Filter to components with checkouts
    components = {
        k: v for k, v in components.items()
        if v.checkout_path and v.checkout_path.exists()
    }

    if not components:
        print("No components found with checkouts")
        return

    # Apply component filter
    component_filter = getattr(args, 'component', None)
    if component_filter:
        if component_filter in components:
            components = {component_filter: components[component_filter]}
            print(f"Filtered to single component: {component_filter}\n")
        else:
            print(f"ERROR: Component '{component_filter}' not found")
            print(f"Available: {', '.join(sorted(components.keys()))}")
            return

    # Ensure arch-analyzer is available
    arch_analyzer_cmd = await _ensure_arch_analyzer()

    print(f"Components to analyze: {len(components)}")
    print(f"Max concurrent: {max_concurrent}")
    print(f"Force re-analyze: {force}")
    print(f"Skip schemas: {skip_schemas}")
    print()

    # Run analysis concurrently
    sem = asyncio.Semaphore(max_concurrent)
    tasks = []
    for key, comp in sorted(components.items()):
        tasks.append(
            _analyze_component(
                arch_analyzer_cmd, key, comp.checkout_path,
                sem, force, skip_schemas,
            )
        )

    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Summary
    extracted = 0
    skipped = 0
    failed = 0
    schemas_total = 0
    errors = []

    for r in results:
        if isinstance(r, Exception):
            failed += 1
            errors.append(("exception", str(r)))
            continue

        ext = r["extract"]
        if ext.get("skipped"):
            skipped += 1
        elif ext["success"]:
            extracted += 1
        else:
            failed += 1
            errors.append((r["name"], ext.get("error", "unknown")))

        if r.get("schema") and r["schema"]["success"]:
            schemas_total += r["schema"]["schema_count"]

    print("=" * 60)
    print("STATIC ANALYSIS COMPLETE")
    print("=" * 60)
    print(f"Total components: {len(results)}")
    print(f"Extracted: {extracted}")
    print(f"Skipped (already exists): {skipped}")
    print(f"Failed: {failed}")
    if not skip_schemas:
        print(f"CRD schemas extracted: {schemas_total}")

    if errors:
        print("\nFailed components:")
        for name, err in errors:
            print(f"  x {name}: {err[:120]}")

    print("=" * 60)

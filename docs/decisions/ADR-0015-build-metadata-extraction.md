# ADR-0015: Build Metadata Extraction from RHOAI Release Artifacts

## Status

Accepted

## Date

2026-05-06

## Context

Component architecture docs need to reference exact container images deployed in each RHOAI version. This information doesn't live in component source repos — it's in the RHOAI build configuration: `build-config.yaml`, `csv-patch.yaml`, `bundle-patch.yaml`, and Konflux snapshot files maintained in the RHOAI-Build-Config repository.

Without build metadata, generated architecture docs referenced generic image names without registry paths, tags, or SHA digests, making them unreliable for security review and incident response.

## Decision

Extract build metadata during the collect phase and produce `build-info.json` per platform version. Sources:

- `build-config.yaml`: Production image references with registry, repository, and tag
- `csv-patch.yaml`: ClusterServiceVersion image overrides
- `bundle-patch.yaml`: OLM bundle image references
- Konflux snapshot files: Build provenance with commit SHAs

Add `arch-query images` subcommand with `--filter` and `--category` flags for querying the extracted image inventory. Include build info in `platform-summary` JSON output and make it searchable via `arch-query grep`.

## Consequences

Positive:
- Architecture docs reference exact deployed images with full registry paths
- Security and compliance workflows can query the complete image inventory
- Build provenance (source commit → image SHA) enables supply chain verification

Negative:
- Depends on RHOAI-Build-Config repository structure; format changes require parser updates
- Build metadata is version-specific; stale data is misleading if not regenerated

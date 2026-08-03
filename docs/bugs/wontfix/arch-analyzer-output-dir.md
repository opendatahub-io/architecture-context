# Bug: arch-analyzer ignores --output-dir flag

## Status

Won't fix locally. Superseded on 2026-07-17 by the project-owned analyzer.

## Summary

`arch-analyzer full-analysis` ignores the `--output-dir` flag and writes all output to `output/` relative to the current working directory.

## Reproduction

```bash
mkdir -p /tmp/test
bin/arch-analyzer full-analysis checkouts/red-hat-data-services.next/models-as-a-service/ \
  --output-dir /tmp/test
```

**Expected:** Output files written to `/tmp/test/`.

**Actual:** Output files written to `./output/` in the current working directory. `/tmp/test/` remains empty.

## Files affected

All output from `full-analysis` lands in the wrong directory:

- `output/component-architecture.json`
- `output/code-graph.json`
- `output/security-findings.json`
- `output/build-config.json`
- `output/diagrams/` (component.mmd, dataflow.mmd, rbac.mmd, c4-context.dsl, security-network.txt, component-report.md)
- `output/schemas/` (extracted CRD JSON schemas)

## Version

```
arch-analyzer 0.2.0
```

## Upstream

https://github.com/ugiordan/architecture-analyzer

## Resolution

The production pipeline no longer invokes upstream `full-analysis`. The in-repository
`src/arch-analyzer` CLI has explicit `--output` arguments for extraction and rendering
and an explicit `--output-dir` argument for CRD schema extraction. Contract tests and
direct schema smoke tests verify those paths. This document is retained only as a
reference for the upstream implementation.

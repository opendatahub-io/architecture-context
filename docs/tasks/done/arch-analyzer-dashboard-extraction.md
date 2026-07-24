# Task: Implement arch-analyzer Dashboard Monorepo Extraction

## Goal

Prove that the deterministic analyzer can recover useful architecture facts from the
TypeScript and nested-Go-module dashboard repository at its recorded commit.

## Acceptance Criteria

- [x] Discover and analyze Go modules below the repository root without double
      scanning nested modules.
- [x] Parse npm workspace and package metadata with structured JSON decoding.
- [x] Recover source-defined frontend, backend, operator, BFF, and shared-library
      components with file evidence.
- [x] Normalize high-value runtime dependencies such as Node.js, Go, Fastify,
      React, PatternFly, Webpack Module Federation, controller-runtime,
      Kubernetes client, and Turborepo.
- [x] Recover source-backed dashboard and BFF HTTP surfaces and listening services.
- [x] Preserve file and line evidence and report explicit partial coverage.
- [x] Add focused fixtures and exact-commit dashboard comparison results.
- [x] Record extraction and rendering time independently.

## Status

Done on 2026-07-17.

## Boundaries

This pass targets statically declared package topology, literal routes, configuration,
and runtime defaults. It does not execute Node.js, resolve dynamic workspace plugins,
or reconstruct every frontend import relationship. It should favor a compact deployed
architecture view over emitting thousands of source packages or route implementation
details.

## Baseline

At dashboard commit `f1cdd9f22`, the manifest-only in-repo analyzer retains 8/292
baseline rows (2.74%) with no conflicts. The stored upstream analyzer JSON retains
35/292 rows (11.99%) with seven conflicts. The current analyzer finds four of five
CRDs and four of 120 source-file rows, but no architecture components, endpoints,
dependencies, services, or integrations.

## Results

The final exact-revision run takes approximately 0.42 seconds to extract and less
than 0.01 seconds to render. The generated Markdown passes structural validation and
retains 170/292 baseline rows (58.22%). Excluding curated recent history and the
agent's broad files-read inventory, it retains 141/165 structured identities (85.45%).

| Category | Retained |
|----------|---------:|
| Architecture components | 16/16 |
| CRDs | 5/5 |
| HTTP endpoints | 13/13 |
| External dependencies | 9/9 |
| Internal dependencies | 12/14 |
| Services | 9/9 |
| Ingress | 1/1 |
| Egress | 12/13 |
| Authentication | 7/7 |
| Integration points | 26/35 |

The stored upstream analyzer retained 35/292 rows. Most of the 47 populated-cell
conflicts are purpose prose for correctly matched architecture components or
source-backed protocol/version differences. The analyzer also identified that the
fixture's Prometheus/Thanos port and selected recent-commit dates do not match the
source checkout.

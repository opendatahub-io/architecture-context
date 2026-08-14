# Architecture Changes: odh-dashboard

No table-level architecture fact changes are proposed. The analyzer baseline tables for authentication, integration_points, internal_dependencies, and grpc_services are comprehensive and accurately reflect the source evidence.

## Change Records

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

## Synthesis Changes

The following synthesis sections were authored or rewritten (these are agent-owned sections, not table changes):

- **Purpose** (Short + Detailed): Rewritten from analyzer placeholder to describe the micro-frontend architecture, three-tier structure, and federated BFF sidecar pattern.
- **Architectural Analysis**: Authored synthesis covering micro-frontend architecture, operator reconciliation model, two-layer authentication, and Workspace controller integration.
- **Data Flows**: Rewritten from analyzer inventory bullets to describe user request path, BFF sidecar traffic routing, controller reconciliation flows, and external service interactions.
- **FIPS Compliance**: New subsection added under Security with build-time and application-level FIPS evidence (CGO_ENABLED=1, -tags strictfipsruntime for all Go binaries; UBI9 OpenSSL for Node.js).

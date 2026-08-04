# Architecture Changes: fms-guardrails-orchestrator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

No table-level changes are proposed. The analyzer baseline tables for authentication, integration_points, HTTP endpoints, services, egress, and secrets are accurate and complete. The gRPC services table remains correctly empty — `build.rs` confirms `build_server(false)` at line 9, meaning no gRPC server surface is compiled. The FIPS Compliance subsection is added under Security as authored synthesis rather than a table row change; it documents that the `ring` crypto provider (selected in Cargo.toml:33-34, 62-65, 81-83, 85-89) is not FIPS-validated and that OpenSSL was removed from the release image (Dockerfile.konflux:51-53).

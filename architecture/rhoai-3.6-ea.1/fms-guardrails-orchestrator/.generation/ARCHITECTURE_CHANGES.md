# Architecture Changes: fms-guardrails-orchestrator

## Change Records

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

No table-level changes are proposed. The analyzer baseline tables (HTTP endpoints, authentication, integration points, services, egress, dependencies) are accurate as extracted. The gRPC services table remains correctly empty: `build.rs` explicitly sets `build_server(false)`, confirming no gRPC server surface is exposed. The FIPS Compliance subsection is added under Security as a synthesis subsection, not as a table row change. Purpose, Data Flows, and Architectural Analysis are agent-authored synthesis sections rewritten from analyzer preseed placeholders.

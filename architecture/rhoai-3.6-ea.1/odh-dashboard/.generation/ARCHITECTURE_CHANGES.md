# Architecture Changes: odh-dashboard

## Change Record

No table-level additions, deletions, or updates to analyzer-owned architecture tables are proposed in this candidate. All gap-targeted source reads confirmed the existing analyzer evidence or added narrative-only synthesis (Purpose, Architectural Analysis, Data Flows, FIPS Compliance) that does not alter structured table rows.

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

## Synthesis Summary

The following synthesis-only sections were authored or rewritten from analyzer preseed placeholders:

- **Purpose (Short and Detailed)**: Rewritten from analyzer inventory prose into architecture narrative describing the three-tier architecture (operator, Node.js backend, Go BFF sidecars).
- **Architectural Analysis**: Authored synthesis covering federated BFF architecture, layered authentication model, operator reconciliation, FIPS build configuration, and integration surface.
- **Data Flows**: Rewritten from analyzer inventory bullets into four named flow descriptions (user request, BFF sidecar, operator reconciliation, security context).
- **FIPS Compliance**: New subsection under Security documenting per-component FIPS posture based on Dockerfile build flag evidence.

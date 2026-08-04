# Architecture Changes: model-registry

## Change Records

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

No table-level changes are proposed. The gap resolution confirmed that:

- **grpc_services**: No gRPC services exist; no `.proto` files or gRPC server registrations found in the repository. The `not-verified` coverage finding is now confirmed as absence.
- **authentication**: All 7 existing authentication rows are accurate. BFF auth-method flag verified at source with `internal` and `user_token` modes.
- **integration_points**: Existing 14 integration points are complete. The controller's model-registry API discovery via Service lookup is captured through the existing `/v1/Service` and `KServe InferenceService` rows.
- **internal_dependencies**: The 3 existing KServe InferenceService dependency rows accurately reflect the conditional controller watch and reconciliation pattern.
- **fips_compliance**: New FIPS Compliance subsection added under Security with build-time and application-level evidence. This is a synthesis section addition, not a table row change.

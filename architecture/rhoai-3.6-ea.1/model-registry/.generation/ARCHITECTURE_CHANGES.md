# Architecture Changes: model-registry

No table row additions, deletions, or updates are required. All existing table entries in the analyzer baseline are confirmed correct by source evidence. The FIPS Compliance subsection is an authored synthesis section under Security and does not require change-record authorization.

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

## Notes

- **grpc_services**: Confirmed empty. No `.proto` files exist in the repository. Grep for `grpc.Server`, `grpc.NewServer`, `RegisterServer`, and `.proto` returned no results. The component communicates exclusively via HTTP REST APIs.
- **authentication**: All 7 existing authentication rows verified against source. BFF auth-method validated at `clients/ui/bff/cmd/main.go:85` (must be `internal` or `user_token`). Controller metrics auth confirmed at `cmd/controller/main.go:99-104`.
- **internal_dependencies**: All 3 KServe InferenceService entries confirmed. Controller watch is conditional on `INFERENCE_SERVICE_CONTROLLER=managed` (cmd/controller/main.go:138). No additional platform-level dependencies identified beyond those already in the integration_points table.
- **integration_points**: All 14 integration point entries confirmed. Controller's OpenAPI client connection to model-registry service is a self-referential internal interaction, not an external integration point.
- **fips_compliance**: New FIPS Compliance subsection added under Security as an authored synthesis section based on `Dockerfile.konflux:23` and `internal/platform/tls/config.go:64-68`.

# Architecture Changes: odh-cli

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /sse | * | <empty> | <empty> | MCP server exposes SSE endpoint on port 8080 when invoked with --transport sse | cmd/mcp/mcp.go:33-34, cmd/mcp/mcp.go:64 |
| update | internal_dependencies | opendatahub-operator | Purpose | Use runtime packages from github.com/opendatahub-io/opendatahub-operator/pkg/clusterhealth | Use runtime packages from github.com/opendatahub-io/opendatahub-operator (clusterhealth, failureclassifier, mcptools) | Three sub-packages are imported, not just clusterhealth | pkg/diagnose/format.go:8, cmd/mcp/mcp.go:9 |
| add | integration_points | TrustYAI Service :: REST (HTTP client) | * | <empty> | <empty> | CLI connects to TrustYAI service routes via HTTPS for metrics backup/restore during migration | pkg/migrate/actions/trustyai/metrics/http.go:29-36, pkg/migrate/actions/trustyai/metrics/http.go:122-149 |

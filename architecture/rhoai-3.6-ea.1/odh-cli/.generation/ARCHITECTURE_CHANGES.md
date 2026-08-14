# Architecture Changes: odh-cli

## Change Records

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | TrustYAI Service :: HTTP (Route discovery + REST) | * | <empty> | <empty> | TrustYAI migration action discovers OpenShift Routes and performs HTTP GET/POST for metric backup/restore with Bearer token auth and TLS 1.2+ | pkg/migrate/actions/trustyai/metrics/http.go:29-36, pkg/migrate/actions/trustyai/metrics/http.go:122-149 |

## Notes

The following gap categories were investigated and resolved without table changes:

- **authentication**: The existing Kubernetes API authentication entry is accurate and complete. No additional authentication surfaces were found.
- **internal_dependencies**: The existing OLM and opendatahub-operator entries are accurate. The opendatahub-operator dependency spans three sub-packages (clusterhealth, failureclassifier, mcptools) but is correctly represented as a single platform dependency.
- **fips_compliance**: Build-time FIPS is properly configured. Application-level crypto findings documented in the FIPS Compliance subsection under Security.
- **http_endpoints**: The CLI does not expose persistent HTTP endpoints. The MCP SSE server is an optional, user-initiated localhost-only transport mode, not a production service endpoint.
- **services**: No Kubernetes Services are defined. This is a CLI tool / kubectl plugin, not a deployed service.

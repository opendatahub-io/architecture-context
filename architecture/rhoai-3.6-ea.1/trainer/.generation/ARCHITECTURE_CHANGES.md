# Architecture Changes: trainer

## Change Records

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | OpenShift Cluster TLS Configuration | * | <empty> | <empty> | Controller reads config.openshift.io/v1/apiservers at startup to resolve cluster TLS security profile for webhook and metrics servers; gracefully degrades on non-OpenShift clusters | pkg/tls/tls.go:104, cmd/trainer-controller-manager/main.go:120 |

## Narrative

The primary structural change is the addition of the OpenShift Cluster TLS Configuration as an internal platform dependency. The controller's `pkg/tls.Resolve()` function creates a dynamic client and reads the `config.openshift.io/v1/apiservers` resource (specifically the `cluster` instance) to extract the `tlsSecurityProfile`. This profile determines cipher suites and minimum TLS version applied to the webhook, metrics, and status servers. The dependency is optional: when the API is unavailable (non-OpenShift clusters), the controller falls back to hardened Intermediate defaults (TLS 1.2+, AEAD ciphers).

All other analyzer-seeded tables (authentication, integration_points, gRPC services) were confirmed accurate through source inspection and require no structural changes.

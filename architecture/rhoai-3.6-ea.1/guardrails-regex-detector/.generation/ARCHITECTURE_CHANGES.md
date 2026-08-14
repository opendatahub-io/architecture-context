# Architecture Changes: guardrails-regex-detector

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | /api/v1/*, /api/v2/* :: POST | * | <empty> | <empty> | Endpoint pattern incorrect: source has only /api/v1/text/contents, no /api/v2 routes; auth mechanism "Header passthrough" unsupported — no auth middleware in Axum router, only TraceLayer for tracing | src/main.rs:31-38 |
| add | authentication | /api/v1/text/contents :: POST | * | <empty> | <empty> | Source confirms single POST route with no authentication middleware or header filtering; security is delegated to platform infrastructure | src/main.rs:33, src/main.rs:31-38 |
| delete | authentication | /health, /info :: GET | * | <empty> | <empty> | Endpoint pattern incorrect: source has only /health route, no /info route exists in the Axum router | src/main.rs:31-32 |
| add | authentication | /health :: GET | * | <empty> | <empty> | Source confirms single GET health route returning static "healthy" string with no authentication | src/main.rs:32 |

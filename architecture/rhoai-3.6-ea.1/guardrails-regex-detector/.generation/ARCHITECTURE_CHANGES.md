# Architecture Changes: guardrails-regex-detector

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | /api/v1/*, /api/v2/* :: POST | * | <empty> | <empty> | Endpoint pattern is inaccurate: only /api/v1/text/contents exists; no /api/v2/* routes; no header passthrough or application-level filtering in source | src/main.rs:33, src/detectors.rs:96 |
| add | authentication | /api/v1/text/contents :: POST | * | <empty> | <empty> | Source confirms single POST endpoint with no authentication middleware or header inspection; platform-delegated security | src/main.rs:33, src/detectors.rs:96-98 |
| delete | authentication | /health, /info :: GET | * | <empty> | <empty> | Only /health endpoint exists; no /info route registered in the Axum router | src/main.rs:32 |
| add | authentication | /health :: GET | * | <empty> | <empty> | Health check route returns static string with no authentication | src/main.rs:32 |

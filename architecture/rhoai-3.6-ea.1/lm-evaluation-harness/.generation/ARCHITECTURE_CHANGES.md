# Architecture Changes: lm-evaluation-harness

No table-level additions, deletions, or updates were made to the analyzer-owned architecture tables. All routed gap categories (authentication, internal_dependencies, http_endpoints, services) were investigated and confirmed empty through source evidence:

- **authentication**: No inbound endpoints exist; authentication is exclusively outbound via environment variable API keys, already captured in the Secrets table. [source: lm_eval/models/openai_completions.py:104, lm_eval/models/anthropic_llms.py:178-179, lm_eval/models/ibm_watsonx_ai.py:59-62]
- **internal_dependencies**: No compile-time or runtime dependencies on other RHOAI platform components. The component is orchestrated by an external operator but has no reverse dependency.
- **http_endpoints**: No HTTP server frameworks found; the `api` optional dependency group contains only HTTP client libraries for outbound LLM API calls. [source: pyproject.toml:65-71]
- **services**: No Kubernetes manifests or Service definitions found in the repository. Deployment is delegated to the TrustyAI operator.
- **fips_compliance**: FIPS Compliance subsection added under Security as narrative evidence (not a table row).

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

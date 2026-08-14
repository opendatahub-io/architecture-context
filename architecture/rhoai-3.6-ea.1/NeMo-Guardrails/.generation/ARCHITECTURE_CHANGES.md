# Architecture Changes: NeMo-Guardrails

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Analyzer auth row references prompt_security/actions.py which describes outbound Prompt Security API calls, not server-level authentication; the FastAPI server has no built-in auth middleware | nemoguardrails/server/api.py:29, nemoguardrails/server/api.py:69-83, nemoguardrails/library/prompt_security/actions.py:37-43 |
| add | authentication | Guardrails Server API :: All | * | <empty> | <empty> | Server exposes all endpoints without built-in authentication; auth is delegated to Kubernetes infrastructure (ingress, proxy, service mesh) | nemoguardrails/server/api.py:69-83, nemoguardrails/server/api.py:231-253, nemoguardrails/server/checks.py:479-491 |
| add | authentication | LLM Provider (outbound) :: All | * | <empty> | <empty> | Header forwarding module maps inbound X-Authorization to outbound Authorization for LLM backends; inbound Authorization (K8s auth) is explicitly excluded from forwarding | nemoguardrails/header_forwarding.py:62-88, nemoguardrails/header_forwarding.py:102-126 |

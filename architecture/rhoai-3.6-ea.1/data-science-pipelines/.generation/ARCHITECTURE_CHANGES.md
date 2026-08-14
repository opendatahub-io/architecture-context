# Architecture Changes

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | Pipeline API (ml-pipeline) :: All | * | <empty> | <empty> | Source inspection confirms the apiserver authenticates requests via Kubernetes TokenReview and authorizes via SubjectAccessReview; this row represents the actual production authentication surface | backend/src/apiserver/auth/authenticator_token_review.go:47-57, backend/src/apiserver/resource/resource_manager.go:2323-2332 |

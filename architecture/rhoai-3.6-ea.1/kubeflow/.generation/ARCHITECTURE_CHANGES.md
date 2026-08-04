# Architecture Changes: kubeflow

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | Operator webhook :: CREATE | * | <empty> | <empty> | Replaced by two separate webhook entries distinguishing mutating and validating admission with their respective operations | components/odh-notebook-controller/controllers/notebook_mutating_webhook.go:54 |
| add | authentication | Operator webhook :: CREATE, UPDATE | * | <empty> | <empty> | Mutating admission webhook enforces kube-rbac-proxy sidecar injection, proxy env vars, and reconciliation lock on Notebook CREATE and UPDATE operations | components/odh-notebook-controller/controllers/notebook_mutating_webhook.go:54, components/odh-notebook-controller/config/webhook/manifests.yaml:2 |
| add | authentication | Operator webhook :: UPDATE | * | <empty> | <empty> | Validating admission webhook enforces update-time constraints on Notebook resources via ValidatingWebhookConfiguration | components/odh-notebook-controller/controllers/notebook_validating_webhook.go:31, components/odh-notebook-controller/config/webhook/manifests.yaml:28 |

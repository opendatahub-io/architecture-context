# Architecture Changes: models-as-a-service

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | internal_dependencies | KServe InferenceService :: Controller watch (conditional) | Purpose | Read model serving state | Read model serving state; dynamically registered when CRD appears | Source confirms conditional CRD check at startup with dynamic watch registration when CRD absent | maas-controller/pkg/controller/maas/maasmodelref_controller.go:517-559 |
| update | internal_dependencies | Gateway API (data-science-gateway) :: HTTPRoute | Component | Gateway API (data-science-gateway) | Gateway API (maas-default-gateway) | HTTPRoute parentRef names the gateway maas-default-gateway in openshift-ingress namespace, not data-science-gateway | deployment/base/maas-api/networking/httproute.yaml:7-8 |
| add | internal_dependencies | Kuadrant :: AuthPolicy CRUD | * | <empty> | <empty> | MaaSAuthPolicyReconciler programmatically creates kuadrant.io/v1/AuthPolicy resources for Gateway authentication | maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:777-835 |
| add | internal_dependencies | Kuadrant :: TokenRateLimitPolicy CRUD | * | <empty> | <empty> | MaaSSubscriptionReconciler creates kuadrant.io/v1alpha1/TokenRateLimitPolicy resources for rate limiting | maas-controller/pkg/controller/maas/maasauthpolicy_controller.go:777-835, maas-controller/pkg/controller/maas/maasmodelref_controller.go:517-559 |

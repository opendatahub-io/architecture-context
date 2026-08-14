# Architecture Changes: odh-gitops

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | architecture_components | rhai-on-openshift-chart | * | <empty> | <empty> | Primary Helm chart for RHOAI/ODH deployment on OpenShift | charts/rhai-on-openshift-chart/Chart.yaml:3 |
| add | architecture_components | rhai-on-xks-chart | * | <empty> | <empty> | Helm chart for non-OLM RHAI deployment on non-OpenShift Kubernetes | charts/rhai-on-xks-chart/Chart.yaml:3 |
| add | architecture_components | operator-subscriptions | * | <empty> | <empty> | Kustomize components providing OLM Subscription manifests for dependency operators | dependencies/operators/kustomization.yaml:4-13 |
| add | architecture_components | operator-configurations | * | <empty> | <empty> | Kustomize resources providing post-install configuration CRs | configurations/kustomization.yaml:4-7 |
| add | internal_dependencies | opendatahub-operator | * | <empty> | <empty> | Platform operator deployed and configured by this chart | charts/rhai-on-openshift-chart/values.yaml:38-62 |
| add | internal_dependencies | cert-manager-operator | * | <empty> | <empty> | TLS certificate management required by KServe, Kueue, Ray, and Trainer | charts/rhai-on-openshift-chart/values.yaml:183 |
| add | internal_dependencies | rhcl-operator | * | <empty> | <empty> | Kuadrant-based API policy management | components/operators/rhcl-operator/subscription.yaml:4-5 |
| add | internal_dependencies | sail-operator | * | <empty> | <empty> | Istio service mesh for Gateway API on non-OpenShift clusters | charts/rhai-on-xks-chart/values.yaml:168-171 |
| add | internal_dependencies | gateway-api | * | <empty> | <empty> | Kubernetes Gateway API CRDs for ingress routing | charts/rhai-on-xks-chart/values.yaml:162-163 |
| add | internal_dependencies | lws-operator | * | <empty> | <empty> | LeaderWorkerSet for distributed workloads (WideEP) | charts/rhai-on-xks-chart/values.yaml:164-167 |
| add | internal_dependencies | kueue-operator | * | <empty> | <empty> | Job queuing and resource quota management | dependencies/operators/kustomization.yaml:6 |
| add | internal_dependencies | job-set-operator | * | <empty> | <empty> | JobSet orchestration for training workloads | dependencies/operators/kustomization.yaml:10 |
| add | internal_dependencies | cluster-observability-operator | * | <empty> | <empty> | Platform monitoring infrastructure | dependencies/operators/kustomization.yaml:7 |
| add | internal_dependencies | opentelemetry-product | * | <empty> | <empty> | Distributed tracing instrumentation | dependencies/operators/kustomization.yaml:8 |
| add | internal_dependencies | tempo-product | * | <empty> | <empty> | Trace storage and query backend | dependencies/operators/kustomization.yaml:11 |
| add | internal_dependencies | custom-metrics-autoscaler | * | <empty> | <empty> | Autoscaling for KServe workload-variant-autoscaler | dependencies/operators/kustomization.yaml:12 |
| add | integration_points | OLM (Operator Lifecycle Manager) :: Subscription API | * | <empty> | <empty> | Operator deployment and lifecycle management on OpenShift | components/operators/rhcl-operator/subscription.yaml:1 |
| add | integration_points | OpenShift Gateway API :: Gateway/GatewayClass CRD | * | <empty> | <empty> | Ingress routing for KServe inference and MaaS endpoints | charts/rhai-on-openshift-chart/values.yaml:206-212 |
| add | integration_points | Kuadrant (RHCL) :: Kuadrant CRD | * | <empty> | <empty> | API policy management via kuadrant-system namespace | configurations/rhcl-operator/kuadrant.yaml:1-5 |
| add | integration_points | Authorino :: Gateway annotation | * | <empty> | <empty> | TLS bootstrap for authentication on Gateway resources | charts/rhai-on-openshift-chart/values.yaml:125 |
| add | integration_points | OpenShift Marketplace :: CatalogSource | * | <empty> | <empty> | Catalog source for OLM operator subscriptions | charts/rhai-on-openshift-chart/values.yaml:25-27 |
| add | authentication | KServe Inference Gateway :: All | * | <empty> | <empty> | Authorino TLS bootstrap via security.opendatahub.io annotation on Gateway | charts/rhai-on-openshift-chart/values.yaml:125 |
| add | authentication | MaaS Gateway :: All | * | <empty> | <empty> | Authorino TLS bootstrap via security.opendatahub.io annotation on Gateway | charts/rhai-on-openshift-chart/values.yaml:125 |

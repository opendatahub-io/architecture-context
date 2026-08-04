# Architecture Changes: must-gather

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | OpenShift API Server | * | <empty> | <empty> | must-gather uses oc adm inspect and kubectl get against the API server for all resource collection | collection-scripts/common.sh:25, collection-scripts/gather.sh:57 |
| add | internal_dependencies | rhods-operator | * | <empty> | <empty> | Collects operator namespace, CSV version, DSCInitialization, DataScienceCluster CRs from operator | collection-scripts/gather.sh:43, collection-scripts/common.sh:48-54 |
| add | internal_dependencies | opendatahub-io platform CRDs | * | <empty> | <empty> | Collects component CRs across all opendatahub.io API groups for diagnostics | collection-scripts/gather.sh:70-98 |
| add | authentication | Kubernetes API :: All | * | <empty> | <empty> | must-gather authenticates via kubeconfig credentials inherited from oc adm must-gather caller | collection-scripts/gather.sh:57, collection-scripts/common.sh:25 |
| add | integration_points | Kubernetes API Server :: REST | * | <empty> | <empty> | Primary integration: all resource collection, namespace inspection, and log retrieval via Kubernetes API | collection-scripts/common.sh:25, collection-scripts/gather.sh:57 |
| add | integration_points | Data Science Pipelines :: CRD read | * | <empty> | <empty> | Collects DSP resources and namespace logs for diagnostics | collection-scripts/gather.sh:129-130, collection-scripts/gather.sh:193 |
| add | integration_points | KServe :: CRD read | * | <empty> | <empty> | Collects InferenceService, ServingRuntime, and related serving resources | collection-scripts/gather_serving.sh:5-6, collection-scripts/gather.sh:133-134 |
| add | integration_points | Model Registry :: CRD read | * | <empty> | <empty> | Collects Model Registry resources from rhoai-model-registries namespace | collection-scripts/gather.sh:48, collection-scripts/gather.sh:61 |
| add | integration_points | llm-d :: CRD read | * | <empty> | <empty> | Collects LLMInferenceService, InferencePool, and llm-d resources | collection-scripts/gather_serving.sh:11, collection-scripts/gather.sh:173-174 |
| add | integration_points | Authorino :: CRD read | * | <empty> | <empty> | Collects AuthConfig and AuthPolicy resources for serving diagnostics | collection-scripts/gather_serving.sh:7 |
| add | integration_points | Kuadrant :: CRD read | * | <empty> | <empty> | Collects RateLimitPolicy and TokenRateLimitPolicy resources | collection-scripts/gather_serving.sh:13, collection-scripts/gather.sh:49 |
| add | integration_points | Gateway API :: CRD read | * | <empty> | <empty> | Collects Gateway, HTTPRoute, GRPCRoute resources from component namespaces | collection-scripts/common.sh:10-16 |
| add | integration_points | Helm :: CLI | * | <empty> | <empty> | Collects Helm release values and manifests from rhai-gitops namespace | collection-scripts/common.sh:78-86, collection-scripts/gather.sh:68 |

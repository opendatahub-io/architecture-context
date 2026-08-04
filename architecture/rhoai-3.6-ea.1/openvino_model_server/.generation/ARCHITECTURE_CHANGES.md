# Architecture Changes: openvino_model_server

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /v2/health/ready | * | <empty> | <empty> | KServe v2 health endpoint configured in both serving runtime definitions | extras/kserve/kserve-openvino.yaml:24, extras/openshift_AI/ServingRuntime.yaml:28 |
| add | http_endpoints | POST :: /v2/models/{model}/infer | * | <empty> | <empty> | KServe v2 inference endpoint implied by protocolVersions v2 support | extras/kserve/kserve-openvino.yaml:44-47, extras/openshift_AI/ServingRuntime.yaml:37-39 |
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Prometheus metrics endpoint declared via runtime annotations | extras/kserve/kserve-openvino.yaml:12-13, extras/openshift_AI/ServingRuntime.yaml:14-15 |
| add | authentication | REST API :: All | * | <empty> | <empty> | Core OVMS server has no built-in authentication; platform service mesh provides transport security | extras/kserve/kserve-openvino.yaml:14-19 |
| add | authentication | REST/gRPC API (mTLS sidecar) :: All | * | <empty> | <empty> | nginx-mtls-auth sidecar provides optional mTLS with TLSv1.2 client cert verification | extras/nginx-mtls-auth/model_server.conf.template:32-33 |
| add | internal_dependencies | KServe | * | <empty> | <empty> | OVMS registers as ClusterServingRuntime and ServingRuntime via serving.kserve.io API | extras/kserve/kserve-openvino.yaml:1-2, extras/openshift_AI/ServingRuntime.yaml:1-2 |
| add | internal_dependencies | OpenDataHub Dashboard | * | <empty> | <empty> | ServingRuntime labeled for dashboard visibility | extras/openshift_AI/ServingRuntime.yaml:9 |
| add | integration_points | KServe Control Plane :: ServingRuntime registration | * | <empty> | <empty> | Registers OVMS as a serving runtime for KServe InferenceService deployments | extras/kserve/kserve-openvino.yaml:1-9, extras/openshift_AI/ServingRuntime.yaml:1-10 |
| add | integration_points | Prometheus :: Metrics scraping | * | <empty> | <empty> | Metrics endpoint exposed via prometheus annotations on serving runtime pods | extras/kserve/kserve-openvino.yaml:12-13, extras/openshift_AI/ServingRuntime.yaml:14-15 |
| add | integration_points | Model Storage :: Volume mount | * | <empty> | <empty> | Models loaded from /mnt/models path specified in serving runtime container args | extras/kserve/kserve-openvino.yaml:18, extras/openshift_AI/ServingRuntime.yaml:21 |

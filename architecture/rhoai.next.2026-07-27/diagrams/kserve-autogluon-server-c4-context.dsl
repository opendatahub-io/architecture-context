workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using InferenceService and LLMInferenceService CRs"
        mlEngineer = person "ML Engineer" "Manages serving runtimes, model caching, and inference graphs"

        kserveAutogluon = softwareSystem "kserve-autogluon-server" "KServe operator managing ML model serving lifecycle with InferenceService, LLMInferenceService, InferenceGraph, and LocalModel controllers" {
            managerBinary = container "cmd/manager" "Core KServe controllers (InferenceService, TrainedModel, InferenceGraph) with admission webhooks" "Go Operator"
            llmisvcBinary = container "cmd/llmisvc" "LLMInferenceService controller with secure metrics, conversion webhooks, and storage version migration" "Go Controller"
            localmodelBinary = container "cmd/localmodel" "LocalModel controllers for node-level model caching with PV/PVC management" "Go Controller"
            routerBinary = container "cmd/router" "InferenceGraph routing engine supporting Splitter, Switch, Ensemble, and Sequence strategies" "Go Service"
            agentBinary = container "cmd/agent" "Sidecar reverse proxy with model pulling, request/response logging, and request batching" "Go Sidecar"
            webhookServer = container "Webhook Server" "Validates and mutates KServe CRDs via Kubernetes admission" "HTTPS 443/TCP"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes authorization proxy for metrics" "Go Proxy v0.18.0"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management via VirtualService" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform via Knative Service" "External"
        gatewayApi = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based traffic routing" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObject" "External"
        otel = softwareSystem "OpenTelemetry" "Observability platform via OpenTelemetryCollector" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        objectStorage = softwareSystem "Object Storage" "Model artifact storage (S3, GCS, Azure Blob)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        gatewayApiInference = softwareSystem "gateway-api-inference-extension" "Inference-specific Gateway API extensions (InferencePool, InferenceModel)" "External"
        llmdAutoscaler = softwareSystem "llm-d-workload-variant-autoscaler" "LLM workload variant autoscaling (VariantAutoscaling)" "External"

        dataScientist -> kserveAutogluon "Creates InferenceService / LLMInferenceService via kubectl"
        mlEngineer -> kserveAutogluon "Manages ServingRuntimes, LocalModelCaches, InferenceGraphs"

        kserveAutogluon -> k8sApi "Manages 12 CRDs, Deployments, Services, PV/PVCs" "HTTPS/6443"
        kserveAutogluon -> istio "Creates VirtualServices for traffic routing" "Kubernetes API"
        kserveAutogluon -> knative "Creates Knative Services for serverless autoscaling" "Kubernetes API"
        kserveAutogluon -> gatewayApi "Creates HTTPRoutes for LLMInferenceService routing" "HTTPS TLS 1.2+"
        kserveAutogluon -> keda "Creates ScaledObjects for custom autoscaling" "Kubernetes API"
        kserveAutogluon -> otel "Creates OpenTelemetryCollectors for observability" "Kubernetes API"
        kserveAutogluon -> objectStorage "Downloads model artifacts" "HTTPS"
        kserveAutogluon -> gatewayApiInference "Manages InferencePool and InferenceModel resources" "Kubernetes API"
        kserveAutogluon -> llmdAutoscaler "Creates VariantAutoscaling resources" "Kubernetes API"

        prometheus -> kserveAutogluon "Scrapes metrics" "HTTPS/8443"
        k8sApi -> kserveAutogluon "Sends admission webhook requests" "HTTPS/443"
        certManager -> kserveAutogluon "Provisions TLS certificates" "Kubernetes Secret"

        managerBinary -> webhookServer "Serves admission webhooks"
        managerBinary -> k8sApi "Reconciles InferenceService, TrainedModel, InferenceGraph"
        llmisvcBinary -> k8sApi "Reconciles LLMInferenceService"
        localmodelBinary -> k8sApi "Manages PV/PVCs and LocalModel resources"
        routerBinary -> managerBinary "Routes InferenceGraph requests"
        kubeRbacProxy -> managerBinary "Proxies metrics with authn/authz" "localhost 8443→8080"
    }

    views {
        systemContext kserveAutogluon "SystemContext" {
            include *
            autoLayout
        }

        container kserveAutogluon "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

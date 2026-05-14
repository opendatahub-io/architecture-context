workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates and deploys ML/AI models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and LLM deployments"
        securityTeam = person "Security Team" "Reviews and audits inference platform security posture"

        // KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native ML/AI model serving platform providing CRD-driven lifecycle management for inference services, LLM workloads, and local model caching" {
            kserveController = container "kserve-controller" "Main controller managing InferenceService, InferenceGraph, and TrainedModel CRDs with Knative, Istio, Gateway API, and KEDA integrations" "Go Operator" {
                isvcReconciler = component "InferenceService Reconciler" "Reconciles InferenceService CRDs into Deployments, Services, HPAs, VirtualServices, HTTPRoutes" "controller-runtime"
                igReconciler = component "InferenceGraph Reconciler" "Reconciles InferenceGraph CRDs into router Deployments and OpenShift Routes" "controller-runtime"
                tmReconciler = component "TrainedModel Reconciler" "Manages multi-model serving model registration" "controller-runtime"
                webhookServer = component "Webhook Server" "Validates/defaults CRDs and injects sidecars (storage-init, agent, logger)" "9443/TCP HTTPS"
                ingressFactory = component "Ingress Factory" "Selects between Istio VirtualService, Gateway API HTTPRoute, or K8s Ingress" "Factory Pattern"
            }

            llmisvcController = container "llmisvc-controller" "Dedicated controller for LLM inference workloads with multi-node, disaggregated P/D, Gateway API, InferencePool, and WVA scaling" "Go Operator" {
                llmReconciler = component "LLMInferenceService Reconciler" "Reconciles LLMInferenceService into workloads, schedulers, routing, scaling, monitoring" "controller-runtime"
                configMerger = component "Config Merger" "Resolves and pins LLMInferenceServiceConfig templates via WellKnownConfigResolver" "Go"
                tlsManager = component "TLS Manager" "Generates self-signed TLS certificates for LLM workload pods" "Go crypto/tls"
            }

            localmodelController = container "localmodel-controller" "Controller managing LocalModelCache and LocalModelNamespaceCache lifecycle, creating PVs/PVCs and LocalModelNode entries" "Go Operator"

            localmodelnodeAgent = container "localmodelnode-agent" "Per-node agent running LocalModelNode controller, launching download Jobs and managing local model storage" "Go Agent (DaemonSet)"

            kserveAgent = container "kserve-agent" "Injected sidecar handling model pulling (multi-model), request logging, and request batching" "Go Sidecar"

            kserveRouter = container "kserve-router" "HTTP router for InferenceGraph DAG-based inference pipelines with splitter/switch/ensemble/sequence patterns" "Go Service"

            storageInitializer = container "storage-initializer" "Init container downloading model artifacts from S3, GCS, Azure, HuggingFace, OCI, PVC" "Python 3.11 Init Container"
        }

        // External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.25+)" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform (scale-to-zero)" "External Optional"
        istio = softwareSystem "Istio / OSSM" "Service mesh for traffic routing, mTLS, VirtualServices, DestinationRules" "External Optional"
        gatewayAPI = softwareSystem "Gateway API" "Modern HTTPRoute-based ingress routing" "External Optional"
        keda = softwareSystem "KEDA" "External metrics-based autoscaling (ScaledObjects)" "External Optional"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics collection and export via OpenTelemetryCollector sidecars" "External Optional"
        prometheusOp = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for LLM engine and scheduler metrics" "External Optional"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node LLM workload orchestration (pipeline/data parallelism)" "External Optional"
        certManager = softwareSystem "cert-manager" "TLS certificate management (non-OpenShift)" "External Optional"
        llmdWVA = softwareSystem "LLM-D WVA" "Workload Variant Autoscaling for LLM cost-based replica management" "External Optional"

        // Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Deploys KServe controllers via kustomize overlays" "Internal ODH"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "TLS certificates for webhook servers (replaces cert-manager)" "Internal ODH"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication for inference endpoints via oauth-proxy sidecar" "Internal ODH"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Auth proxy for inference endpoint RBAC enforcement" "Internal ODH"
        vllm = softwareSystem "vLLM Runtime" "LLM inference runtime (CUDA/ROCm/Gaudi/Spyre variants)" "Internal ODH"
        llmdScheduler = softwareSystem "llm-d-inference-scheduler" "LLM request scheduler and load balancer for InferencePools" "Internal ODH"

        // External Storage
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External Storage"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Storage"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Storage"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External Storage"
        ociRegistries = softwareSystem "OCI Registries" "Container/artifact registries for model OCI artifacts" "External Storage"

        // Relationships - People
        dataScientist -> kserve "Creates InferenceService, LLMInferenceService via kubectl/API"
        mlEngineer -> kserve "Manages ServingRuntimes, LocalModelCaches, LLMInferenceServiceConfigs"
        securityTeam -> kserve "Reviews RBAC, network policies, TLS configuration"

        // Relationships - KServe to External
        kserve -> kubernetes "CRUD for Deployments, Services, HPAs, ConfigMaps, Secrets" "HTTPS/6443"
        kserve -> knativeServing "Creates Knative Services for serverless mode" "HTTPS/6443"
        kserve -> istio "Creates VirtualServices, DestinationRules for traffic routing" "HTTPS/6443"
        kserve -> gatewayAPI "Creates HTTPRoutes for modern ingress" "HTTPS/6443"
        kserve -> keda "Creates ScaledObjects for advanced autoscaling" "HTTPS/6443"
        kserve -> otelOperator "Creates OpenTelemetryCollectors for metrics" "HTTPS/6443"
        kserve -> prometheusOp "Creates PodMonitors, ServiceMonitors" "HTTPS/6443"
        kserve -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node LLM" "HTTPS/6443"
        kserve -> certManager "Uses for webhook TLS (non-OpenShift)" "HTTPS/6443"
        kserve -> llmdWVA "Creates VariantAutoscaling CRs" "HTTPS/6443"

        // Relationships - KServe to Internal Platform
        rhodsOperator -> kserve "Deploys via kustomize manifests"
        kserve -> openshiftServiceCA "Webhook TLS certificate injection"
        kserve -> openshiftOAuth "oauth-proxy sidecar for InferenceService auth"
        kserve -> kubeRBACProxy "RBAC proxy for inference endpoints"
        kserve -> vllm "LLM inference runtime containers"
        kserve -> llmdScheduler "Request scheduling for InferencePools" "gRPC"

        // Relationships - Storage
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443"
        kserve -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        kserve -> azureStorage "Downloads model artifacts" "HTTPS/443"
        kserve -> huggingface "Downloads pre-trained models" "HTTPS/443"
        kserve -> ociRegistries "Downloads OCI model artifacts" "HTTPS/443"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout
        }

        container kserve "Containers" {
            include *
            autoLayout
        }

        component kserveController "KServeControllerComponents" {
            include *
            autoLayout
        }

        component llmisvcController "LLMISVCControllerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

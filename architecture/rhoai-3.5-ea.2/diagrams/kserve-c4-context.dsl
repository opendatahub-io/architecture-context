workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"

        kserve = softwareSystem "KServe" "Kubernetes-native ML model serving platform with CRDs and controllers for deploying, scaling, and managing inference services" {
            controllerManager = container "kserve-controller-manager" "Primary controller managing InferenceService, TrainedModel, InferenceGraph CRDs; handles deployment, ingress, autoscaling, and webhook admission" "Go Operator (controller-runtime)" "Controller"
            llmisvcController = container "llmisvc-controller" "Dedicated LLM inference controller managing LLMInferenceService/Config CRDs with Gateway API routing, EPP scheduler, WVA autoscaling, and disaggregated serving" "Go Operator (controller-runtime)" "Controller"
            localmodelController = container "localmodel-controller" "Manages LocalModelCache and LocalModelNamespaceCache CRDs for cluster-wide and namespace-scoped model caching with PV/PVC provisioning" "Go Operator (controller-runtime)" "Controller"
            localmodelnodeAgent = container "localmodelnode-agent" "Node-level agent managing LocalModelNode CRDs, model download Jobs, and local storage" "Go Operator (controller-runtime)" "Agent"
            kserveAgent = container "kserve-agent" "In-pod request proxy providing model pulling, request/response logging, and request batching middleware" "Go Service (sidecar)" "Sidecar"
            inferenceGraphRouter = container "inference-graph-router" "HTTP request router for InferenceGraph DAG execution with optional TLS and Kubernetes token-based auth" "Go Service (sidecar)" "Sidecar"
            storageInitializer = container "storage-initializer" "Downloads model artifacts from S3, GCS, Azure, HuggingFace Hub, HTTP, and OCI sources into pod volumes" "Python 3.11 Init Container" "Init Container"
            moduleController = container "kserve-module-controller" "Platform-level ODH/RHOAI module that reconciles Kserve CR to deploy all KServe components via kustomize with dependency checking" "Go Operator (controller-runtime)" "Controller"
        }

        # External Dependencies
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh for traffic management and mTLS" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with external metrics" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute/Gateway routing" "External"
        inferenceGatewayExt = softwareSystem "Inference Gateway Extension" "EPP scheduler integration for LLM-optimized request routing" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Operator" "Multi-node distributed model serving orchestration" "External"
        cma = softwareSystem "Custom Metrics Autoscaler" "WVA-based autoscaling for LLMInferenceService" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "OTel collector sidecar for pod-level metrics" "External"

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that creates Kserve CR" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Platform UI for managing model serving" "Internal RHOAI"

        # External Storage Services
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External Service"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Service"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository with xet acceleration" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships - User
        user -> kserve "Creates InferenceService, LLMInferenceService, InferenceGraph via kubectl/API"
        platformAdmin -> rhodsOperator "Configures RHOAI platform"

        # Relationships - Platform
        rhodsOperator -> kserve "Creates Kserve CR for component lifecycle" "CRD Watch"
        odhDashboard -> kserve "UI-driven model serving management" "API"

        # Relationships - External Dependencies
        kserve -> istio "VirtualService routing and DestinationRule networking" "HTTPS/443"
        kserve -> knative "Knative Service for serverless autoscaling" "HTTPS/443"
        kserve -> certManager "TLS certificates for webhook servers" "CRD"
        kserve -> keda "ScaledObject for Prometheus-based autoscaling" "HTTPS/443"
        kserve -> gatewayAPI "HTTPRoute/Gateway for raw deployment ingress" "HTTPS/443"
        kserve -> inferenceGatewayExt "InferencePool/InferenceModel for EPP scheduler" "HTTPS/443"
        kserve -> leaderWorkerSet "Multi-node distributed serving orchestration" "HTTPS/443"
        kserve -> cma "WVA-based autoscaling for LLMInferenceService" "HTTPS/443"
        kserve -> otelOperator "OpenTelemetryCollector sidecar for metrics" "HTTPS/443"

        # Relationships - Storage
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443"
        kserve -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        kserve -> azureStorage "Downloads model artifacts" "HTTPS/443"
        kserve -> huggingface "Downloads models with xet acceleration" "HTTPS/443"

        # Relationships - Monitoring
        prometheus -> kserve "Scrapes controller and model metrics" "HTTP/8080, HTTPS/8443"

        # Container-level relationships
        controllerManager -> istio "Manages VirtualService CRs" "HTTPS/443"
        controllerManager -> knative "Manages Knative Service CRs" "HTTPS/443"
        controllerManager -> keda "Manages ScaledObject CRs" "HTTPS/443"
        controllerManager -> otelOperator "Manages OTelCollector CRs" "HTTPS/443"
        llmisvcController -> gatewayAPI "Manages HTTPRoute CRs" "HTTPS/443"
        llmisvcController -> inferenceGatewayExt "Creates InferencePool CRs" "HTTPS/443"
        llmisvcController -> istio "Manages DestinationRule CRs" "HTTPS/443"
        localmodelController -> localmodelnodeAgent "Coordinates model downloads" "CRD (LocalModelNode)"
        storageInitializer -> s3Storage "Downloads models" "HTTPS/443"
        storageInitializer -> gcsStorage "Downloads models" "HTTPS/443"
        storageInitializer -> azureStorage "Downloads models" "HTTPS/443"
        storageInitializer -> huggingface "Downloads models" "HTTPS/443"
        moduleController -> rhodsOperator "Watches Kserve CR" "CRD Watch"
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

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #50c878
                color #ffffff
            }
            element "Init Container" {
                background #9b59b6
                color #ffffff
            }
            element "Agent" {
                background #e67e22
                color #ffffff
            }
        }
    }
}

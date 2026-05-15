workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRDs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, ServingRuntimes, and LocalModelCache configuration"
        mlApp = person "ML Application" "Sends inference requests to deployed models"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform providing CRD-based lifecycle management for inference services" {
            isvcController = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, TrainedModel, ServingRuntime CRDs. Creates Deployments, Services, HPAs, VirtualServices, HTTPRoutes." "Go Operator (controller-runtime)" "Controller"
            llmisvcController = container "llmisvc-controller-manager" "Reconciles LLMInferenceService and LLMInferenceServiceConfig CRDs. Creates LeaderWorkerSets, InferencePools, VariantAutoscalings, HTTPRoutes." "Go Operator (controller-runtime)" "Controller"
            localmodelController = container "localmodel-controller-manager" "Reconciles LocalModelCache, LocalModelNamespaceCache CRDs. Creates PVs, PVCs, download Jobs." "Go Operator (controller-runtime)" "Controller"
            localmodelAgent = container "localmodelnode-agent" "Manages local model downloads on each node in a cache node group." "Go DaemonSet Agent" "Agent"
            storageInit = container "storage-initializer" "Downloads model artifacts from cloud storage into pods before model server startup." "Python Init Container" "Init Container"
            kserveAgent = container "kserve-agent" "Sidecar for model downloading and hot model updates in inference pods." "Go Sidecar" "Sidecar"
            router = container "kserve-router" "Handles multi-model traffic routing for InferenceGraph (Sequence, Splitter, Ensemble, Switch)." "Go Service" "Router"
            pythonSDK = container "kserve Python SDK" "Model serving framework providing FastAPI REST (v1/v2/OpenAI) and gRPC v2 servers." "Python Library (FastAPI + gRPC)" "SDK"
            webhookService = container "Webhook Services" "Validates and mutates KServe CRDs. Injects storage-initializer and agent sidecars into pods." "Admission Webhooks (TLS/mTLS)" "Webhook"
        }

        # External Dependencies
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for inference workloads" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for VirtualService routing, mTLS, DestinationRules" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress routing (RHOAI 3.x primary)" "External"
        keda = softwareSystem "KEDA" "Kubernetes event-driven autoscaling with Prometheus metrics" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks (non-OCP)" "External"
        promOperator = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for metrics collection" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node LLM workload orchestration" "External"
        wva = softwareSystem "WVA Controller (llmd.ai)" "Workload Variant Autoscaling for LLM replicas" "External"
        infExtAPI = softwareSystem "Inference Extension API" "InferencePool for Gateway API routing" "External"
        kuadrant = softwareSystem "Kuadrant" "AuthPolicy for authentication on OpenShift" "External"

        # Internal RHOAI Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys KServe via Kustomize manifests" "Internal RHOAI"
        odhOperator = softwareSystem "opendatahub-operator" "Community platform operator that deploys KServe" "Internal RHOAI"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "CA certificate for TLS certificate generation on OCP" "Internal RHOAI"

        # External Cloud Services
        s3 = softwareSystem "Amazon S3" "Model artifact storage" "Cloud Storage"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "Cloud Storage"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "Cloud Storage"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact download" "Cloud Storage"
        prometheus = softwareSystem "Prometheus" "Metrics and autoscaling queries" "Monitoring"

        # Relationships - Users
        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"
        platformAdmin -> kserve "Manages ServingRuntimes, LocalModelCache, platform configuration"
        mlApp -> kserve "Sends inference requests via REST (v1/v2/OpenAI) and gRPC" "HTTPS/443"

        # Relationships - External Dependencies
        kserve -> knative "Creates Knative Services for serverless mode" "HTTPS/443"
        kserve -> istio "Creates VirtualServices and DestinationRules" "HTTPS/443"
        kserve -> gatewayAPI "Creates HTTPRoutes for ingress" "HTTPS/443"
        kserve -> keda "Creates ScaledObjects for event-driven autoscaling" "HTTPS/443"
        kserve -> certManager "Creates Certificates for webhook TLS" "HTTPS/443"
        kserve -> promOperator "Creates PodMonitors/ServiceMonitors" "HTTPS/443"
        kserve -> lws "Creates LeaderWorkerSets for multi-node LLMs" "HTTPS/443"
        kserve -> wva "Creates VariantAutoscalings for LLM replicas" "HTTPS/443"
        kserve -> infExtAPI "Creates InferencePools for Gateway API routing" "HTTPS/443"
        kserve -> kuadrant "Checks AuthPolicy preconditions (OCP)" "HTTPS/443"

        # Relationships - Internal
        rhodsOperator -> kserve "Deploys via Kustomize manifests"
        odhOperator -> kserve "Deploys via Kustomize manifests"
        kserve -> openshiftServiceCA "Reads CA certificates for TLS (OCP)" "HTTPS/443"

        # Relationships - Cloud Storage
        kserve -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        kserve -> gcs "Downloads model artifacts" "HTTPS/443 ADC"
        kserve -> azure "Downloads model artifacts" "HTTPS/443 SP/SAS"
        kserve -> huggingface "Downloads model artifacts" "HTTPS/443 HF Token"
        kserve -> prometheus "Queries autoscaling metrics" "HTTPS Bearer Token"

        # Container relationships
        isvcController -> webhookService "Registers webhook configurations"
        llmisvcController -> webhookService "Registers webhook configurations"
        localmodelController -> webhookService "Registers webhook configurations"
        localmodelAgent -> localmodelController "Reports download status via LocalModelNode CRs"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Cloud Storage" {
                background #f5a623
                color #ffffff
            }
            element "Monitoring" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Agent" {
                background #50c878
                color #ffffff
            }
            element "Init Container" {
                background #50c878
                color #ffffff
            }
            element "Sidecar" {
                background #50c878
                color #ffffff
            }
            element "Router" {
                background #9b59b6
                color #ffffff
            }
            element "SDK" {
                background #e67e22
                color #ffffff
            }
            element "Webhook" {
                background #e1d5e7
                color #333333
            }
        }
    }
}

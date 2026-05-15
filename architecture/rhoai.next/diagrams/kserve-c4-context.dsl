workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys ML models as InferenceServices"
        mlEngineer = person "ML Engineer" "Deploys and manages LLM workloads via LLMInferenceService"
        platformAdmin = person "Platform Admin" "Manages KServe configuration and cluster resources"

        # KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for ML inference with serverless, raw deployment, and LLM-optimized modes" {
            kserveController = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, TrainedModel CRDs; manages deployments, services, ingress, autoscaling" "Go Operator (controller-runtime)" "Controller"
            llmisvcController = container "llmisvc-controller-manager" "Reconciles LLMInferenceService CRD; manages LLM workloads with P/D disaggregation, Gateway API routing, WVA autoscaling" "Go Operator (controller-runtime)" "Controller"
            localmodelController = container "localmodel-controller" "Reconciles LocalModelCache CRDs; manages PVs/PVCs and download jobs for node-local model caching" "Go Operator (controller-runtime)" "Controller"
            localmodelAgent = container "localmodelnode-agent" "DaemonSet managing local model downloads on each node" "Go Agent (controller-runtime)" "Agent"
            storageInitializer = container "storage-initializer" "Downloads model artifacts from cloud storage into serving containers" "Python 3.11 Init Container" "InitContainer"
            router = container "router" "Implements InferenceGraph routing: sequence, splitter, ensemble, switch patterns" "Go Service" "Router"
            agent = container "agent" "Sidecar for request logging and batching in inference pods" "Go Sidecar" "Sidecar"
            webhookServer = container "Webhook Server" "Validates and mutates InferenceService, LLMInferenceService, ServingRuntime CRDs; injects storage-initializer and agent sidecars" "Go Webhook (9443/TCP)" "Webhook"
        }

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Deploys KServe components via Kustomize manifests" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway (data-science-gateway)" "Platform Gateway for LLMInferenceService HTTPRoutes" "Internal RHOAI"

        # External Platform Dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External Platform"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform (v0.48.1)" "External Platform"
        istio = softwareSystem "Istio Service Mesh" "Traffic management, VirtualService, DestinationRule (v1.27.1)" "External Platform"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and Gateway management (v1.4.2)" "External Platform"
        inferenceGatewayExt = softwareSystem "Inference Gateway Extension" "InferencePool CRD for scheduler routing (v1.3.1)" "External Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External Platform"
        keda = softwareSystem "KEDA" "External metric autoscaling (v2.17.3)" "External Platform"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node workload orchestration (v0.8.0)" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and querying" "External Platform"
        kuadrant = softwareSystem "Kuadrant / Red Hat Connectivity Link" "AuthPolicy for LLMInferenceService" "External Platform"
        serviceCA = softwareSystem "OpenShift service-ca" "CA signing key for workload TLS certificates" "External Platform"

        # External Cloud Services
        s3 = softwareSystem "AWS S3" "Model artifact storage" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Cloud"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Cloud"
        huggingface = softwareSystem "HuggingFace Hub" "Public model repository" "External Cloud"
        ociRegistry = softwareSystem "OCI Container Registries" "Model image registries" "External Cloud"

        # Relationships - Users
        dataScientist -> kserve "Creates InferenceService via kubectl/API"
        mlEngineer -> kserve "Creates LLMInferenceService via kubectl/API"
        platformAdmin -> kserve "Configures ServingRuntimes, inferenceservice-config"

        # Relationships - Internal Platform
        rhodsOperator -> kserve "Deploys via Kustomize manifests"
        kserve -> rhoaiGateway "References as HTTPRoute parent" "Gateway API"

        # Relationships - External Platform
        kserveController -> k8sAPI "CRUD on Deployments, Services, Ingress" "HTTPS/6443 SA Token"
        llmisvcController -> k8sAPI "CRUD on LWS, HTTPRoutes, InferencePools" "HTTPS/6443 SA Token"
        localmodelController -> k8sAPI "CRUD on PVs, PVCs, Jobs" "HTTPS/6443 SA Token"
        kserveController -> knativeServing "Creates Knative Services" "via K8s API"
        kserveController -> istio "Creates VirtualServices" "via K8s API"
        llmisvcController -> istio "Creates DestinationRules (OCP)" "via K8s API"
        kserveController -> gatewayAPI "Creates HTTPRoutes" "via K8s API"
        llmisvcController -> gatewayAPI "Creates HTTPRoutes" "via K8s API"
        llmisvcController -> inferenceGatewayExt "Creates InferencePools" "via K8s API"
        kserve -> certManager "Provisions webhook TLS certs"
        kserveController -> keda "Creates ScaledObjects" "via K8s API"
        llmisvcController -> keda "Creates ScaledObjects" "via K8s API"
        llmisvcController -> leaderWorkerSet "Creates LeaderWorkerSets" "via K8s API"
        kserve -> prometheus "Exposes and queries metrics" "HTTPS Bearer Token"
        llmisvcController -> kuadrant "Checks AuthPolicy CRD availability" "via K8s API"
        llmisvcController -> serviceCA "Reads CA signing key" "via K8s API"

        # Relationships - Cloud Storage
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443 IAM"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443 SA JSON"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS/443 Azure ID"
        storageInitializer -> huggingface "Downloads model artifacts" "HTTPS/443 HF Token"
        storageInitializer -> ociRegistry "Pulls model images" "HTTPS/443 Registry creds"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
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
            element "Agent" {
                background #7b68ee
                color #ffffff
            }
            element "InitContainer" {
                background #e8a838
                color #ffffff
            }
            element "Router" {
                background #50c878
                color #ffffff
            }
            element "Sidecar" {
                background #e8a838
                color #ffffff
            }
            element "Webhook" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

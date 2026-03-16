workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and deployment pipelines"
        endUser = person "End User / Application" "Consumes inference predictions via API calls"

        // KServe System (Primary)
        kserve = softwareSystem "KServe" "Standardized serverless ML model serving platform with autoscaling, multi-framework support, and advanced deployment patterns" {
            controller = container "kserve-controller-manager" "Reconciles InferenceService lifecycle, manages Knative/Istio resources" "Go Operator" {
                reconciler = component "Reconciler" "Watches CRDs and reconciles desired state"
                resourceManager = component "Resource Manager" "Creates Knative Services, Deployments, VirtualServices"
            }

            webhook = container "kserve-webhook-server" "Validates and mutates InferenceServices, injects sidecars" "Go Admission Webhook" {
                validator = component "Validator" "Validates InferenceService, ServingRuntime, TrainedModel CRDs"
                mutator = component "Mutator" "Mutates resources, injects storage-initializer and agent sidecars"
            }

            modelPod = container "Model Server Pod" "Serves ML inference requests with framework-specific runtime" "Python/C++ Service" {
                storageInitializer = component "storage-initializer" "Downloads model artifacts from S3/GCS before server starts"
                modelServer = component "Model Server Runtime" "Framework-specific inference server (sklearn, tensorflow, pytorch, etc.)"
                agent = component "kserve-agent" "Logging, batching, and metrics aggregation sidecar"
                istioProxy = component "istio-proxy" "Envoy sidecar for mTLS and traffic management"
            }

            router = container "kserve-router" "Orchestrates multi-model inference pipelines" "Go Service"
        }

        // External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling and traffic routing platform" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and ingress" "External"
        certManager = softwareSystem "cert-manager" "Kubernetes certificate management and auto-renewal" "External"

        // Internal ODH/RHOAI Components
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, lineage, and versioning" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing InferenceServices and model deployments" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration with automated model deployment" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "OpenShift Service Mesh integration" "Internal ODH"

        // External Services
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage on GCP" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Service"

        // Relationships - Users
        dataScientist -> kserve "Creates InferenceService via kubectl/OpenShift Console"
        mlEngineer -> kserve "Manages ServingRuntimes and deployment configurations"
        endUser -> kserve "Sends inference requests via HTTPS API" "REST/gRPC"

        // Relationships - KServe Internal
        controller -> webhook "Coordinates admission control"
        controller -> modelPod "Creates and manages pods"
        webhook -> modelPod "Injects sidecars during pod creation"
        router -> modelPod "Routes requests in InferenceGraph pipelines"

        storageInitializer -> modelServer "Provides model artifacts via shared volume"
        agent -> modelServer "Proxies requests for logging and batching"
        istioProxy -> modelServer "Provides mTLS encryption and traffic management"

        // Relationships - KServe to External Dependencies
        kserve -> kubernetes "Manages CRDs, Deployments, Services" "K8s API / HTTPS:6443"
        kserve -> knativeServing "Creates Knative Services for autoscaling" "K8s API / HTTPS:6443"
        kserve -> istio "Creates VirtualServices for traffic routing and canary rollouts" "K8s API / HTTPS:6443"
        kserve -> certManager "Requests TLS certificates for webhook endpoints" "Certificate CRD"

        // Relationships - KServe to Internal ODH
        kserve -> modelRegistry "Fetches model metadata (future integration)" "REST API / HTTPS:443"
        odhDashboard -> kserve "Provides UI for InferenceService management" "K8s API"
        dsPipelines -> kserve "Deploys models from pipeline runs" "K8s API"
        kserve -> serviceMesh "Integrates with OpenShift Service Mesh" "ServiceMeshMember CRD"

        // Relationships - KServe to External Services
        kserve -> s3Storage "Downloads model artifacts" "S3 API / HTTPS:443"
        kserve -> gcsStorage "Downloads model artifacts" "GCS API / HTTPS:443"
        kserve -> prometheus "Exposes controller and model server metrics" "HTTP:8080 /metrics"

        // Reverse relationships
        endUser -> istio "Routes traffic through Istio Ingress Gateway" "HTTPS:443"
        istio -> kserve "Forwards requests to model servers"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autolayout lr
            title "[System Context] KServe ML Model Serving Platform"
            description "High-level view of KServe in the ODH/RHOAI ecosystem"
        }

        container kserve "KServeContainers" {
            include *
            autolayout lr
            title "[Container Diagram] KServe Internal Components"
            description "Internal containers and their interactions within KServe"
        }

        component controller "ControllerComponents" {
            include *
            autolayout lr
            title "[Component Diagram] KServe Controller Manager"
            description "Internal components of the controller manager"
        }

        component webhook "WebhookComponents" {
            include *
            autolayout lr
            title "[Component Diagram] KServe Webhook Server"
            description "Internal components of the webhook server"
        }

        component modelPod "ModelPodComponents" {
            include *
            autolayout lr
            title "[Component Diagram] Model Server Pod"
            description "Containers within a model server pod"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }

            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "Component" {
                background #85bbf0
                color #000000
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "Internal ODH" {
                background #7ed321
                color #000000
            }

            element "External Service" {
                background #f5a623
                color #000000
            }
        }

        themes default
    }

    configuration {
        scope softwaresystem
    }
}

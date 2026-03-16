workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference" "User"
        endUser = person "End User" "Consumes ML inference predictions via APIs" "External"

        # KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform with autoscaling, traffic management, and multi-framework support" {
            controller = container "KServe Controller" "Reconciles InferenceService CRDs and manages lifecycle" "Go Operator" {
                tags "Control Plane"
            }
            webhook = container "Webhook Server" "Validates and mutates InferenceService, TrainedModel, and Pod resources" "Go Admission Controller" {
                tags "Control Plane"
            }
            storageInitializer = container "Storage Initializer" "Downloads model artifacts from S3/GCS/HTTP to pod volumes" "Python Init Container" {
                tags "Data Plane"
            }
            agent = container "KServe Agent" "Request batching, logging, and health checking sidecar" "Go Sidecar Container" {
                tags "Data Plane"
            }
            router = container "InferenceGraph Router" "Orchestrates multi-step inference pipelines with routing logic" "Go Service" {
                tags "Data Plane"
            }
            modelServer = container "Model Server" "Serves ML models using framework-specific runtimes" "TensorFlow/PyTorch/SKLearn/etc" {
                tags "Data Plane"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "Infrastructure"
        }
        knativeServing = softwareSystem "Knative Serving" "Serverless platform for autoscaling and scale-to-zero" "External" {
            tags "Infrastructure"
        }
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic routing, mTLS, and authorization policies" "External" {
            tags "Infrastructure"
        }
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning for webhooks" "External" {
            tags "Infrastructure"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "Monitoring"
        }
        s3Storage = softwareSystem "S3 Compatible Storage" "Model artifact storage (AWS S3, Minio, etc.)" "External" {
            tags "Storage"
        }
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage for GCP deployments" "External" {
            tags "Storage"
        }
        cloudEventsSink = softwareSystem "CloudEvents Sink" "External logging service for inference request/response logs" "External" {
            tags "Logging"
        }

        # Internal ODH Dependencies
        odhModelController = softwareSystem "ODH Model Controller" "Creates InferenceServices from ODH ServingRuntime resources" "Internal ODH" {
            tags "ODH Component"
        }
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workloads and InferenceServices" "Internal ODH" {
            tags "ODH Component"
        }
        serviceMesh = softwareSystem "Service Mesh (OSSM)" "OpenShift Service Mesh for mTLS and network policies" "Internal ODH" {
            tags "ODH Component"
        }
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifact references" "Internal ODH" {
            tags "ODH Component"
        }

        # Relationships - User Interactions
        dataScientist -> odhDashboard "Manages InferenceServices via UI" "HTTPS"
        dataScientist -> kubernetes "Creates InferenceService CRs via kubectl" "HTTPS/6443"
        endUser -> istio "Sends inference requests" "HTTPS/443"

        # Relationships - KServe Internal
        controller -> webhook "Validates resources before admission" "HTTP/9443"
        agent -> modelServer "Proxies inference requests" "HTTP/8080 (localhost)"
        storageInitializer -> modelServer "Provides model files via shared volume" "EmptyDir Volume"
        router -> agent "Routes requests through InferenceGraph steps" "HTTP/80 (mTLS)"

        # Relationships - External Dependencies
        kserve -> kubernetes "Watches CRDs, creates Deployments/Services" "HTTPS/6443"
        controller -> knativeServing "Creates Knative Services for serverless" "Kubernetes API"
        controller -> istio "Creates VirtualServices for traffic routing" "Kubernetes API"
        controller -> certManager "Requests TLS certificates for webhooks" "Kubernetes API"
        kserve -> prometheus "Exposes metrics for scraping" "HTTP/8080"
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443 (AWS SigV4)"
        storageInitializer -> gcsStorage "Downloads model artifacts" "HTTPS/443 (GCP IAM)"
        agent -> cloudEventsSink "Sends request/response logs" "HTTP(S)"
        kubernetes -> webhook "Validates admission requests" "HTTPS/9443 (mTLS)"
        istio -> agent "Routes inference traffic with mTLS" "HTTP/8012"
        prometheus -> controller "Scrapes controller metrics" "HTTP/8080"
        prometheus -> modelServer "Scrapes model server metrics" "HTTP/8080"

        # Relationships - Internal ODH Dependencies
        odhModelController -> kserve "Creates InferenceService CRs" "Kubernetes API"
        odhDashboard -> kserve "Manages InferenceServices via Kubernetes API" "HTTPS/6443"
        serviceMesh -> agent "Enforces mTLS and AuthorizationPolicies" "Istio Envoy sidecar"
        modelServer -> modelRegistry "References model artifact locations" "Storage URI"

        # Relationships - End-to-end flow
        endUser -> istio "POST /v1/models/{model}:predict" "HTTPS/443"
        istio -> agent "Forwards request with mTLS" "HTTP/8012"
        agent -> modelServer "Inference request" "HTTP/8080"
        modelServer -> agent "Prediction result" "HTTP/8080"
        agent -> istio "Response" "HTTP/8012"
        istio -> endUser "JSON prediction" "HTTPS/443"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout
            description "System context diagram for KServe showing all external dependencies and integrations"
        }

        container kserve "KServeContainers" {
            include *
            autoLayout
            description "Container diagram showing KServe internal components and their interactions"
        }

        dynamic kserve "InferenceFlow" "End-to-end inference request flow" {
            endUser -> istio "1. Sends inference request"
            istio -> agent "2. Routes with mTLS"
            agent -> modelServer "3. Proxies to model server"
            modelServer -> agent "4. Returns prediction"
            agent -> istio "5. Sends response"
            istio -> endUser "6. Returns JSON result"
            autoLayout
        }

        dynamic kserve "DeploymentFlow" "InferenceService creation and deployment flow" {
            dataScientist -> kubernetes "1. Creates InferenceService CR"
            kubernetes -> webhook "2. Validates via webhook"
            webhook -> kubernetes "3. Admission approved"
            kubernetes -> controller "4. Notifies controller"
            controller -> knativeServing "5. Creates Knative Service"
            controller -> istio "6. Creates VirtualService"
            storageInitializer -> s3Storage "7. Downloads model"
            storageInitializer -> modelServer "8. Provides model files"
            modelServer -> kubernetes "9. Reports ready"
            autoLayout
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Infrastructure" {
                background #666666
                color #ffffff
            }
            element "Storage" {
                background #f5a623
                color #000000
            }
            element "Monitoring" {
                background #d0021b
                color #ffffff
            }
            element "Logging" {
                background #9013fe
                color #ffffff
            }
            element "Control Plane" {
                background #4a90e2
                color #ffffff
            }
            element "Data Plane" {
                background #50c878
                color #000000
            }
            element "ODH Component" {
                background #7ed321
                color #000000
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

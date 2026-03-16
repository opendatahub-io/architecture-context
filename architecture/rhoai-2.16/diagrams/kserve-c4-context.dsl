workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference serving"
        client = person "External Client" "Consumes ML model predictions via REST/gRPC APIs"

        kserve = softwareSystem "KServe" "Standardized serverless ML model serving platform on Kubernetes" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService CRs and manages model deployments" "Go Operator" {
                tags "Internal"
            }
            webhook = container "KServe Webhook Server" "Validates and mutates InferenceService CRs, injects storage initializer" "Go Service" {
                tags "Internal"
            }
            storageInit = container "Storage Initializer" "Downloads model artifacts from cloud storage to local volume" "Init Container" {
                tags "Internal"
            }
            agent = container "Agent Sidecar" "Handles request batching and logging to external systems" "Sidecar Container" {
                tags "Internal"
            }
            inferenceServer = container "Inference Server" "Framework-specific model server (sklearn, pytorch, tensorflow, huggingface)" "Python Runtime" {
                tags "Internal"
            }
            router = container "InferenceGraph Router" "Routes and orchestrates requests across multiple models" "Container" {
                tags "Internal"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform" {
            tags "External"
        }
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and observability" {
            tags "External"
        }
        knative = softwareSystem "Knative Serving" "Serverless deployment mode with autoscaling and scale-to-zero" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" {
            tags "External"
        }

        # Internal ODH Dependencies
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning information" {
            tags "Internal ODH"
        }
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Provides mTLS encryption and traffic policies for ODH components" {
            tags "Internal ODH"
        }

        # External Services
        s3 = softwareSystem "S3 Storage" "Cloud object storage for model artifacts (AWS S3, MinIO, Ceph)" {
            tags "External Service"
        }
        gcs = softwareSystem "GCS Storage" "Google Cloud Storage for model artifacts" {
            tags "External Service"
        }
        azure = softwareSystem "Azure Blob Storage" "Azure cloud storage for model artifacts" {
            tags "External Service"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "External"
        }

        # User interactions
        user -> kserve "Creates InferenceService CRs via kubectl/OpenShift Console" "HTTPS/6443"
        client -> kserve "Sends inference requests" "HTTPS/443 (v1/v2 REST/gRPC)"

        # Controller interactions
        controller -> kubernetes "Reconciles CRs, creates Deployments/Services" "HTTPS/6443"
        controller -> knative "Creates Knative Services for serverless deployments" "HTTPS/6443"
        controller -> istio "Creates VirtualServices for traffic routing" "HTTPS/6443"
        webhook -> kubernetes "Validates/mutates InferenceService CRs" "HTTPS/9443"
        webhook -> certManager "Obtains TLS certificates" "HTTPS/6443"

        # Model serving flow
        storageInit -> s3 "Downloads model artifacts" "HTTPS/443 (S3 API)"
        storageInit -> gcs "Downloads model artifacts" "HTTPS/443 (GCS API)"
        storageInit -> azure "Downloads model artifacts" "HTTPS/443 (Azure API)"
        storageInit -> inferenceServer "Initializes model files" "Filesystem"

        agent -> inferenceServer "Batches inference requests" "HTTP/8080"
        router -> inferenceServer "Routes multi-model inference requests" "HTTP/80 (mTLS)"

        # External integrations
        kserve -> serviceMesh "Uses for mTLS enforcement and traffic policies" "VirtualService CRs"
        kserve -> modelRegistry "Fetches model metadata (optional)" "gRPC/9090"
        inferenceServer -> prometheus "Exposes metrics" "HTTP/8080"

        # Traffic flow through mesh
        client -> istio "HTTPS requests" "443/TCP"
        istio -> knative "Routes to Knative Service" "80/TCP (mTLS)"
        knative -> inferenceServer "Activates pods, forwards requests" "8080/TCP (mTLS)"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout lr
        }

        container kserve "Containers" {
            include *
            autoLayout tb
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal" {
                background #4a90e2
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
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

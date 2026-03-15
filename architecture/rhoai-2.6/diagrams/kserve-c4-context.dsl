workspace {
    model {
        user = person "Data Scientist" "Creates and deploys machine learning models for inference"
        client = person "API Consumer" "External applications and clients consuming model predictions"

        kserve = softwareSystem "KServe" "Kubernetes-native platform for serving ML models with autoscaling and advanced deployment patterns" {
            controller = container "KServe Controller Manager" "Manages InferenceService lifecycle and creates serving infrastructure" "Go Operator" {
                tags "Controller"
            }
            webhook = container "Webhook Server" "Validates and mutates InferenceService and related resources" "Go Service" {
                tags "Controller"
            }
            agent = container "Agent Sidecar" "Provides request logging, batching, and model pulling capabilities" "Go Service" {
                tags "Runtime"
            }
            router = container "InferenceGraph Router" "Routes requests through multi-model pipeline nodes" "Go Service" {
                tags "Runtime"
            }
            storageInit = container "Storage Initializer" "Downloads model artifacts from cloud storage to local volumes" "Python Init Container" {
                tags "Runtime"
            }
            modelServer = container "Model Servers" "Framework-specific servers for serving predictions" "Python (sklearn/xgboost/tensorflow/pytorch/triton)" {
                tags "Runtime"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "External"
        }
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic routing, mTLS, and authorization" "External" {
            tags "External"
        }
        knative = softwareSystem "Knative Serving" "Serverless autoscaling and workload management" "External" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External" {
            tags "External"
        }

        # Internal ODH Dependencies
        serviceMesh = softwareSystem "ServiceMesh (Istio)" "Service mesh integration for RHOAI" "Internal ODH" {
            tags "Internal"
        }
        authorino = softwareSystem "Authorino" "External authorization for model endpoints" "Internal ODH" {
            tags "Internal"
        }
        s3Storage = softwareSystem "S3 Storage" "Object storage for trained model artifacts" "Internal ODH" {
            tags "Internal"
        }
        modelRegistry = softwareSystem "Model Registry" "Tracks model versions and metadata" "Internal ODH" {
            tags "Internal"
        }

        # External Services
        cloudStorage = softwareSystem "Cloud Storage" "S3/GCS/Azure storage for model artifacts" "External Service" {
            tags "ExternalService"
        }
        containerRegistry = softwareSystem "Container Registry" "Stores model server and runtime container images" "External Service" {
            tags "ExternalService"
        }
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External Service" {
            tags "ExternalService"
        }
        knativeEventing = softwareSystem "Knative Eventing" "Event broker for inference request/response logs" "External Service" {
            tags "ExternalService"
        }

        # User interactions
        user -> kserve "Creates InferenceService via kubectl or API"
        client -> kserve "Sends inference requests via HTTPS" "HTTPS/443 (TLS 1.3)"

        # KServe internal relationships
        controller -> webhook "Validates resources before creation"
        controller -> kubernetes "Watches CRDs and creates resources" "HTTPS/443 (ServiceAccount Token)"
        webhook -> kubernetes "Receives admission webhook requests" "HTTPS/443 (mTLS)"

        # Runtime container relationships
        storageInit -> cloudStorage "Downloads model artifacts" "HTTPS/443 (AWS IAM/GCP SA/Azure Key)"
        storageInit -> s3Storage "Downloads model artifacts from internal S3" "HTTPS/443 (AWS Signature v4)"
        agent -> modelServer "Forwards inference requests" "HTTP/8080 (localhost)"
        agent -> knativeEventing "Sends request/response logs" "HTTP/80 (CloudEvents)"
        router -> modelServer "Routes multi-model pipeline requests" "HTTP/80 (mTLS)"

        # External dependencies
        kserve -> kubernetes "Orchestrates containers and manages CRDs" "HTTPS/443"
        kserve -> istio "Uses for traffic routing and mTLS" "HTTPS/443"
        kserve -> knative "Uses for serverless autoscaling" "HTTPS/443"
        kserve -> certManager "Manages webhook TLS certificates" "HTTPS/443"

        # Internal ODH integrations
        kserve -> serviceMesh "Creates VirtualServices for routing" "HTTPS/443"
        kserve -> authorino "Configures external authorization policies" "HTTPS/443"
        kserve -> s3Storage "Stores and retrieves model artifacts" "HTTPS/443"
        kserve -> modelRegistry "Fetches model metadata" "gRPC/9090"

        # External services
        kserve -> containerRegistry "Pulls model server images" "HTTPS/443 (Pull Secret)"
        prometheus -> kserve "Scrapes metrics from controller and model servers" "HTTP/8080, HTTPS/8443"

        # Client flow
        client -> istio "Requests routed through Istio Ingress Gateway"
        istio -> kserve "Forwards to InferenceService pods"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "ExternalService" {
                background #f5a623
                color #000000
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #50e3c2
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

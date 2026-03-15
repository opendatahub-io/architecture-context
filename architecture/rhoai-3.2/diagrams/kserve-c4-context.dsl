workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models for inference"
        endUser = person "End User / Application" "Consumes inference predictions via API"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform providing standardized inference protocols, autoscaling, and advanced deployment features" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, and InferenceGraph CRDs, manages deployment lifecycle" "Go Operator" {
                tags "Controller"
            }
            webhook = container "Webhook Server" "Validates and mutates KServe CRDs with defaulting and injection logic" "Go Service" {
                tags "Webhook"
            }
            storageInitializer = container "Storage Initializer" "Downloads ML model artifacts from cloud storage before inference containers start" "Init Container (Python)" {
                tags "InitContainer"
            }
            agent = container "Agent Sidecar" "Provides request logging, batching, and model agent capabilities" "Sidecar Container (Python)" {
                tags "Sidecar"
            }
            router = container "Router Service" "Implements InferenceGraph multi-step routing with header propagation" "Go Service" {
                tags "Router"
            }
            localmodelManager = container "LocalModel Manager" "Manages local model caching on nodes for improved performance" "Go Controller" {
                tags "Controller"
            }
        }

        inferenceService = softwareSystem "Inference Service Pod" "Runtime pod serving ML model predictions" {
            tags "Runtime"
        }

        # External Dependencies - Required
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.28+)" {
            tags "External" "Required"
        }

        # External Dependencies - Optional
        knativeServing = softwareSystem "Knative Serving" "Serverless deployment with autoscaling and scale-to-zero (0.44.0)" {
            tags "External" "Optional"
        }
        istio = softwareSystem "Istio" "Service mesh for traffic routing, mTLS, and canary deployments (1.24+)" {
            tags "External" "Optional"
        }
        keda = softwareSystem "KEDA" "Event-driven autoscaling for raw deployments (2.16+)" {
            tags "External" "Optional"
        }
        certManager = softwareSystem "cert-manager" "TLS certificate management (latest)" {
            tags "External" "Optional"
        }
        gatewayAPI = softwareSystem "Gateway API" "Modern ingress routing (1.2.1)" {
            tags "External" "Optional"
        }

        # Internal ODH Dependencies
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Provides mTLS, traffic routing, and authorization policies for inference endpoints" {
            tags "Internal ODH"
        }
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and lineage information" {
            tags "Internal ODH"
        }
        authorino = softwareSystem "Authorino" "Token-based authorization for inference endpoints" {
            tags "Internal ODH"
        }
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing InferenceServices and monitoring deployments" {
            tags "Internal ODH"
        }
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Provides ServiceAccount tokens for authentication in multi-tenant environments" {
            tags "Internal ODH"
        }
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Automates model training and deployment workflows" {
            tags "Internal ODH"
        }

        # External Services
        s3Storage = softwareSystem "S3 Storage" "AWS S3 or S3-compatible storage (MinIO, Ceph) for model artifacts" {
            tags "External Service"
        }
        gcsStorage = softwareSystem "GCS Storage" "Google Cloud Storage for model artifacts" {
            tags "External Service"
        }
        containerRegistry = softwareSystem "Container Registries" "Stores model server container images (Quay, Docker Hub, ECR)" {
            tags "External Service"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "Monitoring"
        }

        # User interactions
        user -> kserve "Creates InferenceService via kubectl/OpenShift Console"
        user -> odhDashboard "Manages model deployments via web UI"
        endUser -> inferenceService "Sends inference requests via HTTPS" "Bearer Token (optional)"

        # KServe internal relationships
        kserve -> inferenceService "Provisions and manages" "Kubernetes API"
        controller -> webhook "Calls for validation/mutation" "HTTPS/9443 mTLS"
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443 AWS IAM"
        storageInitializer -> gcsStorage "Downloads model artifacts" "HTTPS/443 GCP Service Account"

        # KServe to external dependencies (required)
        kserve -> kubernetes "Orchestrates containers and manages CRDs" "HTTPS/6443 ServiceAccount Token"

        # KServe to external dependencies (optional)
        kserve -> knativeServing "Uses for serverless autoscaling" "Kubernetes API"
        kserve -> istio "Uses for traffic routing and mTLS" "CRD (VirtualService, DestinationRule)"
        kserve -> keda "Uses for event-driven autoscaling" "CRD (ScaledObject)"
        kserve -> certManager "Uses for TLS certificate provisioning" "Certificate injection"
        kserve -> gatewayAPI "Uses for modern ingress routing" "CRD (HTTPRoute)"

        # KServe to internal ODH dependencies
        kserve -> serviceMesh "Enforces mTLS and authorization policies" "Istio CRDs"
        kserve -> modelRegistry "Fetches model metadata and versions" "REST API / gRPC"
        kserve -> authorino "Validates bearer tokens" "AuthorizationPolicy"
        kserve -> openshiftOAuth "Authenticates via ServiceAccount tokens" "Token validation"
        odhDashboard -> kserve "Manages InferenceService lifecycle" "Kubernetes API"
        dataSciencePipelines -> kserve "Auto-deploys trained models" "Kubernetes API"

        # External service interactions
        inferenceService -> s3Storage "Loads model artifacts at runtime" "HTTPS/443"
        inferenceService -> gcsStorage "Loads model artifacts at runtime" "HTTPS/443"
        kubernetes -> containerRegistry "Pulls model server images" "HTTPS/443"

        # Monitoring
        prometheus -> kserve "Scrapes metrics" "HTTP/8080 (ServiceMonitor)"
        prometheus -> inferenceService "Scrapes inference metrics" "HTTP/8080 or 9090"

        # Ingress flow
        serviceMesh -> inferenceService "Routes traffic with mTLS" "HTTP/8080 mTLS"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #4a90e2
                color #ffffff
            }
            element "InitContainer" {
                background #50e3c2
                color #000000
            }
            element "Sidecar" {
                background #50e3c2
                color #000000
            }
            element "Router" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Required" {
                background #666666
                color #ffffff
            }
            element "Optional" {
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
            element "Monitoring" {
                background #9673a6
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

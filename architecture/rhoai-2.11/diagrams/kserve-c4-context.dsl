workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys machine learning models for inference"
        endUser = person "End User" "Consumes ML model predictions via applications"

        # KServe System
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform on Kubernetes" {
            controller = container "kserve-controller-manager" "Reconciles InferenceServices and manages lifecycle" "Go Operator" {
                tags "Operator"
            }

            webhook = container "kserve-webhook-server" "Validates and mutates InferenceService resources" "Go Webhook Server" {
                tags "Webhook"
            }

            agent = container "kserve-agent" "Sidecar for model pulling, logging, and batching" "Go Sidecar" {
                tags "Sidecar"
            }

            router = container "kserve-router" "Routes requests in InferenceGraphs for model chaining" "Go Router" {
                tags "Router"
            }

            storageInit = container "storage-initializer" "Downloads models from cloud storage to pods" "Python Init Container" {
                tags "Init"
            }

            modelServer = container "Model Servers" "Framework-specific inference servers" "Python (sklearn/xgboost/lgb/paddle)" {
                tags "Runtime"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "External"
        }

        knativeServing = softwareSystem "Knative Serving" "Serverless request-based autoscaling and revision management" "External" {
            tags "External"
        }

        istio = softwareSystem "Istio" "Service mesh for traffic routing, VirtualServices, and mTLS" "External" {
            tags "External"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "External"
        }

        # Internal ODH/RHOAI Dependencies
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Provides mTLS and traffic management for RHOAI" "Internal ODH" {
            tags "Internal"
        }

        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifact references" "Internal ODH" {
            tags "Internal"
        }

        s3Storage = softwareSystem "S3 Storage" "Object storage for model artifacts" "External Storage" {
            tags "Storage"
        }

        gcsStorage = softwareSystem "GCS Storage" "Google Cloud Storage for model artifacts" "External Storage" {
            tags "Storage"
        }

        azureStorage = softwareSystem "Azure Blob Storage" "Azure storage for model artifacts" "External Storage" {
            tags "Storage"
        }

        monitoring = softwareSystem "Monitoring (Prometheus)" "Cluster-wide monitoring and alerting" "Internal ODH" {
            tags "Internal"
        }

        # Relationships - User Interactions
        dataScientist -> kserve "Creates InferenceService via kubectl/UI"
        endUser -> kserve "Sends inference requests via REST/gRPC" "HTTPS/443"

        # Relationships - KServe Internal
        controller -> webhook "Validates resources before creation"
        controller -> modelServer "Creates and manages lifecycle"
        storageInit -> modelServer "Initializes with downloaded models"
        agent -> modelServer "Enhances with logging/batching (optional)"
        router -> modelServer "Routes requests in InferenceGraphs"

        # Relationships - KServe to External Dependencies
        kserve -> kubernetes "Deploys workloads and CRDs" "HTTPS/6443"
        kserve -> knativeServing "Uses for serverless autoscaling" "Kubernetes API"
        kserve -> istio "Uses for traffic routing and mTLS" "Kubernetes API"
        kserve -> certManager "Requests TLS certificates" "Kubernetes API"
        kserve -> prometheus "Exposes metrics" "HTTP/8080"

        # Relationships - KServe to Internal ODH
        kserve -> serviceMesh "Creates VirtualServices for routing" "Kubernetes API/6443"
        kserve -> modelRegistry "Fetches model metadata" "HTTPS/443"
        kserve -> monitoring "Pushes inference metrics" "HTTP/8080"

        # Relationships - KServe to Storage
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443 (AWS IAM)"
        kserve -> gcsStorage "Downloads model artifacts" "HTTPS/443 (GCP SA)"
        kserve -> azureStorage "Downloads model artifacts" "HTTPS/443 (Azure creds)"

        # Specific component relationships
        controller -> kubernetes "Watches and creates resources" "HTTPS/6443"
        webhook -> certManager "Gets TLS certificates" "Kubernetes API"
        storageInit -> s3Storage "Downloads models during init" "HTTPS/443"
        storageInit -> gcsStorage "Downloads models during init" "HTTPS/443"
        storageInit -> azureStorage "Downloads models during init" "HTTPS/443"
        modelServer -> prometheus "Exposes /metrics endpoint" "HTTP/8080"
        controller -> modelRegistry "References model artifacts (optional)" "HTTPS/443"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout
            title "KServe System Context Diagram"
            description "Shows KServe in the context of RHOAI ecosystem with external dependencies"
        }

        container kserve "KServeContainers" {
            include *
            autoLayout
            title "KServe Container Diagram"
            description "Internal components of KServe and their interactions"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "Internal" {
                background #7ed321
                color #ffffff
            }

            element "Storage" {
                background #f5a623
                color #ffffff
            }

            element "Operator" {
                background #4a90e2
                color #ffffff
            }

            element "Webhook" {
                background #4a90e2
                color #ffffff
            }

            element "Runtime" {
                background #bd10e0
                color #ffffff
            }

            element "Sidecar" {
                background #50e3c2
                color #000000
            }

            element "Router" {
                background #50e3c2
                color #000000
            }

            element "Init" {
                background #f8e71c
                color #000000
            }
        }

        theme default
    }
}

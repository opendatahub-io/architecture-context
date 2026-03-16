workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        appDeveloper = person "Application Developer" "Consumes model inference APIs"
        sre = person "SRE/Platform Admin" "Manages KServe infrastructure and serving runtimes"

        kserve = softwareSystem "KServe" "Model serving platform for deploying and managing machine learning models on Kubernetes with autoscaling, multi-framework support, and inference graphs" {
            controller = container "kserve-controller-manager" "Reconciles InferenceService, ServingRuntime, and related CRDs; manages model deployment lifecycle" "Go Operator" {
                tags "ControlPlane"
            }

            webhook = container "kserve-webhook-server" "Validates and mutates InferenceService resources; injects storage-initializer into pods" "Go Service" {
                tags "ControlPlane"
            }

            storageInitializer = container "storage-initializer" "Downloads models from cloud storage (S3, GCS, Azure, PVC) to local volumes" "Python InitContainer" {
                tags "DataPlane"
            }

            modelServers = container "Model Servers" "Runtime servers for specific ML frameworks (TensorFlow, PyTorch, SKLearn, XGBoost, etc.)" "Python/Java Servers" {
                tags "DataPlane"
            }

            agent = container "kserve-agent" "Provides logging, batching, and observability for model servers" "Go Sidecar" {
                tags "DataPlane"
            }

            router = container "kserve-router" "Implements InferenceGraph routing and orchestration for multi-step inference pipelines" "Go Service" {
                tags "DataPlane"
            }
        }

        // External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "External"
        }

        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and virtual services" "External" {
            tags "External"
        }

        knative = softwareSystem "Knative Serving" "Serverless deployment mode with autoscaling and scale-to-zero" "External" {
            tags "External"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External" {
            tags "External"
        }

        s3 = softwareSystem "S3 Storage" "Model artifact storage on AWS" "External Cloud" {
            tags "ExternalCloud"
        }

        gcs = softwareSystem "GCS Storage" "Model artifact storage on Google Cloud" "External Cloud" {
            tags "ExternalCloud"
        }

        azure = softwareSystem "Azure Blob Storage" "Model artifact storage on Azure" "External Cloud" {
            tags "ExternalCloud"
        }

        // Internal ODH/RHOAI Dependencies
        odhDashboard = softwareSystem "ODH Dashboard" "Model serving UI and endpoint discovery" "Internal ODH" {
            tags "InternalODH"
        }

        modelRegistry = softwareSystem "Model Registry" "Model versioning and lineage tracking" "Internal ODH" {
            tags "InternalODH"
        }

        serviceMesh = softwareSystem "Service Mesh" "Provides mTLS sidecars for secure communication" "Internal ODH" {
            tags "InternalODH"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH" {
            tags "InternalODH"
        }

        // Relationships - Users
        dataScientist -> kserve "Creates InferenceService, ServingRuntime via kubectl"
        appDeveloper -> kserve "Sends inference requests via HTTPS/gRPC" "HTTPS/443, gRPC/9000"
        sre -> kserve "Manages cluster-wide serving runtimes and configuration"

        dataScientist -> odhDashboard "Manages models via UI"
        odhDashboard -> kserve "Creates/manages InferenceService resources" "Kubernetes API"

        // Relationships - KServe Internal
        controller -> webhook "Validates InferenceService before creation" "HTTPS/9443 mTLS"
        controller -> modelServers "Creates and manages model server deployments"
        controller -> storageInitializer "Injects as init container"
        storageInitializer -> modelServers "Provides model artifacts on shared volume"
        agent -> modelServers "Observes requests/responses" "localhost HTTP"
        router -> modelServers "Routes inference requests in multi-step pipelines" "HTTP/8080 mTLS"

        // Relationships - KServe to External Dependencies
        kserve -> kubernetes "Manages CRDs and resources" "HTTPS/6443"
        controller -> kubernetes "Reconciles InferenceService, creates Deployments, Services, HPAs" "HTTPS/6443"
        webhook -> kubernetes "Admission webhooks for validation/mutation" "HTTPS/9443 mTLS"

        controller -> knative "Creates Knative Services for serverless deployments" "Kubernetes API/6443"
        controller -> istio "Creates Istio VirtualServices for traffic routing" "Kubernetes API/6443"
        controller -> certManager "Requests TLS certificates for webhooks" "Kubernetes API/6443"

        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443 GCP Service Account"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS/443 Azure SAS"

        istio -> modelServers "Routes external traffic to inference endpoints" "HTTP/8080 mTLS"
        knative -> modelServers "Autoscales based on request load"

        // Relationships - KServe to Internal ODH
        controller -> modelRegistry "Fetches model metadata and lineage" "gRPC/9090"
        serviceMesh -> modelServers "Provides mTLS sidecars"
        prometheus -> modelServers "Scrapes /metrics endpoint" "HTTP/8080"
        agent -> prometheus "Exports custom metrics"

        // External client traffic
        appDeveloper -> istio "Inference requests via Istio Ingress Gateway" "HTTPS/443"
        istio -> kserve "Routes to InferenceService endpoints"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout lr
        }

        container kserve "KServeContainers" {
            include *
            autoLayout tb
        }

        dynamic kserve "ModelDeploymentFlow" "Model deployment and serving flow" {
            dataScientist -> controller "1. Creates InferenceService"
            controller -> webhook "2. Validates InferenceService"
            controller -> knative "3. Creates Knative Service"
            controller -> istio "4. Creates VirtualService"
            controller -> modelServers "5. Creates Deployment"
            storageInitializer -> s3 "6. Downloads model from S3"
            storageInitializer -> modelServers "7. Provides model artifacts"
            appDeveloper -> istio "8. Sends inference request"
            istio -> modelServers "9. Routes to model server"
            modelServers -> appDeveloper "10. Returns prediction"
            autoLayout lr
        }

        dynamic kserve "InferenceGraphFlow" "Multi-step inference with InferenceGraph" {
            appDeveloper -> router "1. Sends inference request"
            router -> modelServers "2. Transformer pre-processing"
            router -> modelServers "3. Predictor inference"
            router -> modelServers "4. Post-processor (optional)"
            router -> appDeveloper "5. Returns final result"
            autoLayout lr
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }

            element "Container" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }

            element "ControlPlane" {
                background #0288d1
                color #ffffff
            }

            element "DataPlane" {
                background #50e3c2
                color #000000
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "ExternalCloud" {
                background #f5a623
                color #ffffff
            }

            element "InternalODH" {
                background #7ed321
                color #000000
            }

            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }

            relationship "Relationship" {
                thickness 2
                fontSize 24
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

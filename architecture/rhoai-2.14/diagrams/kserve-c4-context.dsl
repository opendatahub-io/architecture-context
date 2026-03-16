workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        externalClient = person "External Client" "Consumes inference API for predictions"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for production ML inference workloads" {
            controller = container "kserve-controller-manager" "Reconciles InferenceService lifecycle; creates Knative Services, Istio VirtualServices, K8s Deployments" "Go Operator" {
                tags "Control Plane"
            }
            webhook = container "kserve-webhook-server" "Validates and mutates KServe CRDs; injects storage-initializer and agent sidecars" "Go Webhook" {
                tags "Control Plane"
            }
            agent = container "kserve-agent" "Pulls models dynamically, logs requests/responses, batches inference requests" "Go Sidecar" {
                tags "Data Plane"
            }
            router = container "kserve-router" "Routes and orchestrates multi-step inference pipelines (InferenceGraph)" "Go Service" {
                tags "Data Plane"
            }
            storageInitializer = container "storage-initializer" "Downloads models from cloud storage (S3, GCS, Azure) at pod startup" "Python InitContainer" {
                tags "Data Plane"
            }
            modelServers = container "Model Serving Runtimes" "sklearn-server, xgboost-server, tensorflow-server, pytorch-server, triton-server, huggingface-server" "Python/Container Runtimes" {
                tags "Data Plane"
            }
        }

        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform with scale-to-zero capability" "External Dependency" {
            tags "External"
        }

        istio = softwareSystem "Istio" "Service mesh for traffic management, routing, and mTLS" "External Dependency" {
            tags "External"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External Dependency" {
            tags "External"
        }

        kubernetes = softwareSystem "Kubernetes" "Core platform for CRDs, operators, deployments, services" "External Dependency" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection from model servers and controller" "External Dependency" {
            tags "External"
        }

        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versioning, and lineage" "Internal ODH Dependency" {
            tags "Internal ODH"
        }

        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration; can deploy InferenceServices as outputs" "Internal ODH Dependency" {
            tags "Internal ODH"
        }

        authorino = softwareSystem "Authorino" "External authorization for inference endpoints" "Internal ODH Dependency" {
            tags "Internal ODH"
        }

        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS S3 or compatible)" "External Service" {
            tags "External Service"
        }

        gcs = softwareSystem "GCS Storage" "Model artifact storage (Google Cloud Storage)" "External Service" {
            tags "External Service"
        }

        azure = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External Service" {
            tags "External Service"
        }

        cloudEvents = softwareSystem "CloudEvents Broker" "Request/response logging destination" "External Service" {
            tags "External Service"
        }

        # Relationships - User interactions
        dataScientist -> kserve "Creates InferenceService, ServingRuntime, InferenceGraph, TrainedModel via kubectl" "HTTPS/6443 (Kubernetes API)"
        externalClient -> kserve "Sends inference requests for predictions" "HTTPS/443 (Istio Gateway)"

        # Relationships - KServe internal
        controller -> webhook "Validates CRDs via admission webhooks" "HTTPS/9443 mTLS"
        controller -> kubernetes "Creates/manages Knative Services, Istio VirtualServices, Deployments" "HTTPS/6443"
        webhook -> storageInitializer "Injects into InferenceService pods" "Pod mutation"
        webhook -> agent "Injects into InferenceService pods (optional)" "Pod mutation"
        agent -> modelServers "Proxies inference requests, manages model loading" "HTTP/8080"
        router -> modelServers "Orchestrates multi-step inference pipelines" "HTTP/80"
        storageInitializer -> modelServers "Downloads models to shared volume" "Local filesystem"

        # Relationships - External dependencies
        kserve -> knative "Uses for serverless autoscaling and scale-to-zero" "Kubernetes CRD API"
        kserve -> istio "Uses for traffic routing, VirtualServices, mTLS" "Kubernetes CRD API"
        kserve -> certManager "Uses for webhook TLS certificate provisioning" "Kubernetes CRD API"
        kserve -> kubernetes "Deploys on; uses CRDs, operators, services" "HTTPS/6443"
        kserve -> prometheus "Exposes metrics for scraping" "HTTP/8080"

        # Relationships - Internal ODH dependencies
        kserve -> modelRegistry "Fetches model metadata for versioning" "gRPC/9090 (optional)"
        dataSciencePipelines -> kserve "Deploys InferenceServices as pipeline outputs" "Kubernetes API"
        istio -> authorino "Delegates authorization for inference endpoints" "HTTP (optional)"

        # Relationships - External services
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443 (AWS IAM or Access Keys)"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443 (Service Account or JSON key)"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS/443 (Storage Keys or SAS)"
        agent -> s3 "Dynamically loads models for TrainedModel API" "HTTPS/443"
        agent -> gcs "Dynamically loads models for TrainedModel API" "HTTPS/443"
        agent -> cloudEvents "Sends request/response logs" "HTTP/80"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout
            description "System context diagram for KServe showing external users, dependencies, and integrations"
        }

        container kserve "KServeContainers" {
            include *
            autoLayout
            description "Container diagram for KServe showing internal components and their interactions"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Control Plane" {
                background #4a90e2
                color #ffffff
            }
            element "Data Plane" {
                background #82b366
                color #ffffff
            }
            relationship "Relationship" {
                thickness 2
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

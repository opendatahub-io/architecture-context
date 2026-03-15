workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and LLM deployments"
        apiClient = person "API Client" "Consumes model predictions via REST/gRPC APIs"

        kserve = softwareSystem "KServe" "Cloud-native model inference platform providing standardized serving for predictive and generative AI models on Kubernetes" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, and InferenceGraph CRDs; manages model serving lifecycle" "Go Operator" {
                reconciler = component "InferenceService Reconciler" "Creates Knative Services or Deployments based on deployment mode"
                llmReconciler = component "LLMInferenceService Reconciler" "Specialized reconciler for LLM deployments with vLLM/TGI"
                graphReconciler = component "InferenceGraph Reconciler" "Manages multi-model inference pipelines"
            }
            webhook = container "Webhook Server" "Validates and mutates KServe CRs; injects storage-initializer into pods" "Go Service, HTTPS 9443"
            router = container "InferenceGraph Router" "Intelligent request router for multi-model pipelines with DAG execution" "Go Service, HTTP 8080"
            storageInitializer = container "Storage Initializer" "Downloads model artifacts from S3, GCS, Azure, HuggingFace Hub" "Python Init Container"
            agent = container "KServe Agent" "Model server lifecycle management sidecar" "Go Sidecar"

            modelServers = container "Model Servers" "Runtime inference engines" "Python/Go Services" {
                huggingface = component "HuggingFace Server" "Transformers and LLM inference (vLLM, TGI, single/multi-node)"
                sklearn = component "Scikit-learn Server" "Scikit-learn model inference"
                xgboost = component "XGBoost Server" "XGBoost model inference"
            }
        }

        // External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.25+)" "External"
        istio = softwareSystem "Istio" "Service mesh for mTLS, traffic routing, and canary deployments (1.17+)" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling with scale-to-zero (1.8+)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks (1.0+)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring (2.x)" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for raw deployments (2.x)" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and telemetry (0.x)" "External"
        gatewayAPI = softwareSystem "Gateway API" "Alternative to Istio for traffic routing (v1beta1+)" "External"

        // Internal ODH/RHOAI Dependencies
        serviceMesh = softwareSystem "Service Mesh (Istio)" "mTLS enforcement and service identity for pod-to-pod communication" "Internal ODH"
        authorino = softwareSystem "Authorino" "Token-based authorization for inference endpoints (JWT validation)" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata, versioning, and lineage tracking" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration with automated model deployment" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Component lifecycle management via DataScienceCluster CRD" "Internal ODH"

        // External Services
        s3Storage = softwareSystem "S3 Storage" "Model artifact storage (AWS S3, MinIO)" "External Service"
        gcsStorage = softwareSystem "GCS Storage" "Model artifact storage (Google Cloud Storage)" "External Service"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage (Microsoft Azure)" "External Service"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model and tokenizer repository" "External Service"

        // User interactions
        dataScientist -> kserve "Creates InferenceService/LLMInferenceService via kubectl/UI"
        mlEngineer -> kserve "Configures ServingRuntimes, InferenceGraphs, and deployment modes"
        apiClient -> kserve "Sends inference requests via REST/gRPC (KServe V1/V2 protocols)"

        // KServe internal relationships
        kserve -> kubernetes "Manages Deployments, Services, ConfigMaps, Secrets via API Server (6443/TCP HTTPS)"
        controller -> webhook "Invokes for CR validation and mutation"
        controller -> kubernetes "Reconciles CRDs, creates resources"
        storageInitializer -> s3Storage "Downloads model artifacts (HTTPS 443, AWS SigV4)"
        storageInitializer -> gcsStorage "Downloads model artifacts (HTTPS 443, GCP Service Account)"
        storageInitializer -> azureBlob "Downloads model artifacts (HTTPS 443, Azure Storage Key)"
        storageInitializer -> huggingfaceHub "Downloads HuggingFace models (HTTPS 443, HF Token)"
        router -> modelServers "Routes inference requests in multi-model pipelines (HTTP 8080, mTLS)"
        agent -> modelServers "Manages model server lifecycle"

        // External dependencies
        kserve -> istio "Uses for traffic management, mTLS, and VirtualServices/DestinationRules"
        kserve -> knative "Uses for serverless autoscaling with scale-to-zero (default mode)"
        kserve -> certManager "Requests TLS certificates for webhook server"
        kserve -> prometheus "Exposes metrics for controller and model servers (8080/TCP, 8443/TCP)"
        kserve -> keda "Uses for event-driven autoscaling in raw deployment mode"
        kserve -> otelCollector "Exports distributed traces for inference requests (gRPC 4317)"
        kserve -> gatewayAPI "Alternative traffic routing without Istio dependency"

        // Internal ODH/RHOAI integrations
        kserve -> serviceMesh "Enforces mTLS for pod-to-pod communication (STRICT mode)"
        kserve -> authorino "Integrates for token-based authorization (JWT validation)"
        kserve -> modelRegistry "Fetches model metadata and versioning information (HTTP API 8080)"
        dsPipelines -> kserve "Automates model deployment at end of ML pipelines"
        odhOperator -> kserve "Manages KServe lifecycle via DataScienceCluster CRD"

        // Model server inference
        modelServers -> prometheus "Exposes inference metrics (latency, throughput, errors)"
        modelServers -> otelCollector "Sends distributed traces for request tracking"
    }

    views {
        systemContext kserve "KServeSystemContext" "System context diagram for KServe showing users, external dependencies, and integrations" {
            include *
            autoLayout
        }

        container kserve "KServeContainers" "Container diagram showing KServe internal components" {
            include *
            autoLayout
        }

        component controller "KServeControllerComponents" "Component diagram showing KServe controller internal structure" {
            include *
            autoLayout
        }

        component modelServers "ModelServerComponents" "Component diagram showing model server runtimes" {
            include *
            autoLayout
        }

        styles {
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
            element "Software System" {
                background #4a90e2
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

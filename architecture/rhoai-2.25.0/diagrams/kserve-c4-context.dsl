workspace {
    name "KServe Architecture"
    description "C4 Model for KServe - Serverless ML Inference Platform in RHOAI 2.25"

    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference" "User"
        admin = person "Platform Admin" "Manages KServe installation and cluster resources" "Admin"
        client = person "Application / End User" "Consumes ML model predictions via API" "Client"

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform for deploying and serving machine learning models on Kubernetes" "RHOAI Component" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, and other CRDs; orchestrates model deployments" "Go Operator" "Control Plane"
            webhook = container "Webhook Server" "Validates and mutates InferenceServices and TrainedModels; injects storage-initializer and agent sidecars" "Go Service, HTTPS :9443" "Control Plane"

            inferenceServicePod = container "InferenceService Pod" "Runs model inference workloads" "Kubernetes Pod" "Data Plane" {
                storageInitializer = component "storage-initializer" "Downloads model artifacts from S3/GCS/Azure storage" "Python Init Container"
                agent = component "agent" "Handles request batching, logging to event sinks, health probing" "Go Sidecar"
                modelServer = component "model-server" "Framework-specific inference server (MLServer, TensorFlow Serving, TorchServe, Triton, vLLM)" "Python/C++"
                envoy = component "Istio Envoy Sidecar" "mTLS enforcement, traffic management, telemetry" "C++ Proxy"
            }

            router = container "InferenceGraph Router" "Routes inference requests through multi-step pipelines with sequence, switch, ensemble patterns" "Go Service" "Data Plane"
            localModelController = container "LocalModel Controller" "Manages local model caching for edge/disconnected deployments" "Go Controller" "Control Plane"
        }

        # External Systems - Kubernetes Ecosystem
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform with scale-to-zero, traffic splitting, canary deployments" "External Dependency"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, observability, VirtualServices" "External Dependency"
        k8s = softwareSystem "Kubernetes" "Container orchestration platform; API server, etcd, scheduler" "Platform"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management for webhook server" "External Dependency"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with ScaledObjects for metrics-based scaling" "External Dependency"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "Observability"
        otel = softwareSystem "OpenTelemetry Collector" "Traces and metrics collection for LLM inference observability" "Observability"

        # Internal RHOAI Systems
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing InferenceServices, models, and RHOAI components" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, lineage, and storage references" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflow orchestration and auto-deployment" "Internal RHOAI"
        serviceMesh = softwareSystem "RHOAI Service Mesh" "Istio-based service mesh for secure inference endpoint exposure" "Internal RHOAI"

        # External Services
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts (AWS S3, MinIO, Ceph)" "External Storage"
        gcs = softwareSystem "Google Cloud Storage" "GCP object storage for model artifacts" "External Storage"
        azure = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External Storage"
        eventSink = softwareSystem "Event Sink / Knative Broker" "CloudEvents destination for request/response logging and audit" "External Service"

        # User Interactions
        user -> kserve "Creates InferenceService, ServingRuntime, TrainedModel via kubectl or SDK"
        admin -> kserve "Installs, configures ClusterServingRuntimes, manages RBAC"
        client -> istio "Sends inference requests via HTTPS (POST /v1/models/:predict, /v2/models/:infer)"

        # KServe to External Dependencies
        controller -> knative "Creates and manages Knative Services for serverless deployments" "Kubernetes API, HTTPS :6443"
        controller -> istio "Creates VirtualServices and DestinationRules for traffic routing and mTLS" "Kubernetes API, HTTPS :6443"
        controller -> k8s "Watches CRDs, creates Deployments, Services, Secrets, HPA" "Kubernetes API, HTTPS :6443, Service Account Token"
        webhook -> k8s "Receives webhook requests for validation and mutation" "HTTPS :9443, API Server cert"
        webhook -> certManager "Uses TLS certificate for webhook server" "Kubernetes Secret"
        controller -> keda "Creates ScaledObjects for custom metrics autoscaling (RPS, queue depth)" "Kubernetes API, HTTPS :6443"

        # KServe to Internal RHOAI
        dashboard -> controller "Manages InferenceServices via KServe Python SDK" "Kubernetes API, HTTPS :6443"
        modelServer -> modelRegistry "Fetches model metadata and storage URIs" "gRPC :9090 or HTTP"
        controller -> serviceMesh "Integrates with RHOAI service mesh for secure inference endpoints" "Istio CRDs"
        pipelines -> controller "Auto-deploys models as InferenceServices from pipeline steps" "Kubernetes API"

        # Data Plane Flows
        istio -> envoy "Routes external inference requests via VirtualService" "HTTP :80, mTLS"
        envoy -> agent "Forwards requests to agent sidecar for batching/logging" "HTTP :9081, localhost"
        agent -> modelServer "Sends batched inference requests" "HTTP :8080 or gRPC :9000, localhost"
        router -> modelServer "Routes multi-model requests in InferenceGraph pipelines" "HTTP :80, mTLS"

        # Storage Access
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS :443, AWS IAM or Secret Key"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS :443, GCP Service Account"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS :443, Azure credentials"

        # Observability
        controller -> prometheus "Exposes metrics" "HTTP :8080"
        modelServer -> prometheus "Exposes inference metrics" "HTTP :8080"
        modelServer -> otel "Sends traces and metrics for LLM inference" "gRPC :4317, HTTP :4318"
        agent -> eventSink "Sends request/response logs as CloudEvents" "HTTP/HTTPS :80/:443, Bearer Token"

        # Internal Pod Communication
        storageInitializer -> modelServer "Writes model files to shared volume /mnt/models" "Filesystem"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for KServe showing users, external dependencies, and integrations"
        }

        container kserve "Containers" {
            include *
            autoLayout tb
            description "Container diagram showing KServe internal components and their interactions"
        }

        component inferenceServicePod "InferenceServicePodComponents" {
            include *
            autoLayout lr
            description "Component diagram of InferenceService Pod showing storage-initializer, agent, model-server, and Istio sidecar"
        }

        dynamic kserve "InferenceRequestFlow" "Inference request flow from external client to model server" {
            client -> istio "1. POST /v1/models/model:predict (HTTPS :443, TLS 1.2+, Bearer Token)"
            istio -> envoy "2. Route via VirtualService (HTTP :80, mTLS)"
            envoy -> agent "3. Forward to agent sidecar (HTTP :9081)"
            agent -> modelServer "4. Send inference request (HTTP :8080, localhost)"
            modelServer -> agent "5. Return prediction result"
            agent -> envoy "6. Return response"
            envoy -> istio "7. Return response (mTLS)"
            istio -> client "8. Return JSON response (HTTPS :443, TLS 1.2+)"
            autoLayout lr
            description "Sequence of inference request through Istio gateway, service mesh, and model server"
        }

        dynamic kserve "ModelDeploymentFlow" "Model deployment flow when user creates InferenceService" {
            user -> k8s "1. kubectl apply InferenceService"
            k8s -> webhook "2. Call mutating/validating webhook (HTTPS :9443)"
            webhook -> k8s "3. Return validated/mutated CR"
            k8s -> controller "4. Notify controller (watch event)"
            controller -> knative "5. Create Knative Service (or Deployment)"
            controller -> istio "6. Create VirtualService, DestinationRule"
            controller -> k8s "7. Create Service, HPA, Secrets"
            k8s -> storageInitializer "8. Start InferenceService Pod (init container)"
            storageInitializer -> s3 "9. Download model artifacts (HTTPS :443, AWS IAM)"
            storageInitializer -> modelServer "10. Write to /mnt/models volume"
            modelServer -> modelServer "11. Load model, set readiness probe"
            autoLayout tb
            description "Sequence of model deployment from InferenceService creation to ready state"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "RHOAI Component" {
                background #4a90e2
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
                color #000000
            }
            element "External Service" {
                background #ff9800
                color #000000
            }
            element "Platform" {
                background #333333
                color #ffffff
            }
            element "Observability" {
                background #9b59b6
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Control Plane" {
                background #2e5c8a
                color #ffffff
            }
            element "Data Plane" {
                background #5a9fd4
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "User" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Admin" {
                shape person
                background #d32f2f
                color #ffffff
            }
            element "Client" {
                shape person
                background #7ed321
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

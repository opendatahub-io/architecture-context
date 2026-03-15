workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and monitors performance"

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform on Kubernetes" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, and related CRDs" "Go Operator" {
                tags "Operator"
            }
            webhook = container "Webhook Server" "Validates and mutates InferenceService resources; injects storage-initializer and agent" "Go Service" {
                tags "Webhook"
            }
            predictor = container "Predictor Runtime" "Loads and serves ML models using framework-specific servers" "Python/C++ (MLServer, TorchServe, Triton)" {
                tags "Runtime"
            }
            storageInit = container "Storage Initializer" "Downloads model artifacts from cloud storage before inference container starts" "Python Init Container" {
                tags "InitContainer"
            }
            agent = container "Agent Sidecar" "Handles request batching, logging to event sinks, and model pulling" "Go Sidecar" {
                tags "Sidecar"
            }
            router = container "InferenceGraph Router" "Routes requests through multi-step inference pipelines" "Go Service" {
                tags "Router"
            }
            localController = container "LocalModel Controller" "Manages local model caching for edge/disconnected deployments" "Go Controller" {
                tags "EdgeController"
            }
        }

        knative = softwareSystem "Knative Serving" "Serverless platform for autoscaling and traffic splitting" "External Platform" {
            tags "External"
        }

        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and observability" "External Platform" {
            tags "External"
        }

        keda = softwareSystem "KEDA" "Event-driven autoscaling with custom metrics" "External Platform" {
            tags "External"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks and services" "External Platform" {
            tags "External"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "Manages ODH component lifecycle and configuration" "Internal ODH" {
            tags "InternalODH"
        }

        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing InferenceServices and models" "Internal ODH" {
            tags "InternalODH"
        }

        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and lineage" "Internal ODH" {
            tags "InternalODH"
        }

        s3 = softwareSystem "S3 Storage" "Object storage for model artifacts (AWS S3, MinIO, Ceph)" "External Storage" {
            tags "ExternalStorage"
        }

        gcs = softwareSystem "Google Cloud Storage" "GCP object storage for model artifacts" "External Storage" {
            tags "ExternalStorage"
        }

        azure = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External Storage" {
            tags "ExternalStorage"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Observability" {
            tags "External"
        }

        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics for LLM inference" "External Observability" {
            tags "External"
        }

        eventBroker = softwareSystem "Event Broker" "Receives request/response logs from inference pods" "External Eventing" {
            tags "External"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane API server" "Platform" {
            tags "Platform"
        }

        # Relationships - Users
        dataScientist -> kserve "Creates InferenceService CRs via kubectl or Python SDK"
        dataScientist -> dashboard "Manages models via web UI"
        mlEngineer -> kserve "Configures ServingRuntimes and monitors inference workloads"
        mlEngineer -> prometheus "Views inference metrics and performance"

        # Relationships - KServe internal
        controller -> webhook "Registers admission webhooks"
        webhook -> predictor "Injects storage-initializer and agent sidecars"
        storageInit -> predictor "Loads models into shared volume"
        agent -> predictor "Proxies inference requests with batching"
        controller -> router "Creates InferenceGraph router deployments"
        router -> predictor "Routes requests to multiple models"

        # Relationships - KServe to K8s API
        dataScientist -> k8sAPI "Creates InferenceService resources" "kubectl apply / Python SDK"
        k8sAPI -> webhook "Calls admission webhooks for validation/mutation" "HTTPS/9443"
        controller -> k8sAPI "Watches CRDs and creates Knative Services, VirtualServices, Deployments" "HTTPS/6443"

        # Relationships - External dependencies
        controller -> knative "Creates Knative Services for serverless inference" "Kubernetes API / CRD"
        controller -> istio "Creates VirtualServices and DestinationRules for traffic routing" "Kubernetes API / CRD"
        controller -> keda "Creates ScaledObjects for custom metrics autoscaling" "Kubernetes API / CRD"
        webhook -> certManager "Uses TLS certificates for webhook HTTPS endpoint" "Certificate CR"
        predictor -> prometheus "Exposes /metrics endpoint" "HTTP/8080"
        predictor -> otel "Sends traces and metrics for LLM inference" "gRPC/4317"
        agent -> eventBroker "Sends request/response logs as CloudEvents" "HTTP/HTTPS"

        # Relationships - Internal ODH
        odhOperator -> controller "Enables/disables KServe component via DataScienceCluster CR" "Kubernetes API"
        dashboard -> kserve "Manages InferenceServices via Python SDK" "Kubernetes API"
        controller -> modelRegistry "References model metadata via storage URIs" "gRPC/9090"

        # Relationships - External storage
        storageInit -> s3 "Downloads model artifacts during pod initialization" "HTTPS/443"
        storageInit -> gcs "Downloads model artifacts from GCS buckets" "HTTPS/443"
        storageInit -> azure "Downloads model artifacts from Azure containers" "HTTPS/443"

        # Relationships - Inference path
        dataScientist -> istio "Sends inference requests" "HTTPS/443"
        istio -> knative "Routes to Knative Service or Deployment" "HTTP/80 with mTLS"
        knative -> predictor "Forwards inference request" "HTTP/8080"
        predictor -> dataScientist "Returns prediction result" "JSON response"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout lr
            title "KServe System Context"
            description "High-level view of KServe and its interactions with users, ODH components, and external systems"
        }

        container kserve "Containers" {
            include *
            autoLayout lr
            title "KServe Container View"
            description "Internal components of KServe platform"
        }

        dynamic kserve "InferenceFlow" "Inference request flow from client to model" {
            dataScientist -> istio "1. Sends POST /v1/models/model:predict"
            istio -> knative "2. Routes via VirtualService (mTLS)"
            knative -> agent "3. Forwards to pod (autoscales if needed)"
            agent -> predictor "4. Proxies to model server with batching"
            predictor -> agent "5. Returns prediction"
            agent -> eventBroker "6. Logs request/response (optional)"
            agent -> dataScientist "7. Returns JSON response"
            autoLayout lr
            title "Inference Request Flow"
        }

        dynamic kserve "DeploymentFlow" "Model deployment flow from user to running pod" {
            dataScientist -> k8sAPI "1. kubectl apply -f inferenceservice.yaml"
            k8sAPI -> webhook "2. Mutate and validate InferenceService"
            webhook -> k8sAPI "3. Return validated CR"
            k8sAPI -> controller "4. Watch event notification"
            controller -> knative "5. Create Knative Service"
            controller -> istio "6. Create VirtualService and DestinationRule"
            knative -> storageInit "7. Start pod with init container"
            storageInit -> s3 "8. Download model artifacts"
            storageInit -> predictor "9. Model loaded into /mnt/models"
            predictor -> k8sAPI "10. Pod ready"
            autoLayout lr
            title "Model Deployment Flow"
        }

        styles {
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "InternalODH" {
                background #7ed321
                color #000000
            }
            element "ExternalStorage" {
                background #f5a623
                color #000000
            }
            element "Platform" {
                background #6c8ebf
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
                background #4a90e2
                color #ffffff
            }
            element "InitContainer" {
                background #5a9fd4
                color #ffffff
            }
            element "Sidecar" {
                background #5a9fd4
                color #ffffff
            }
            element "Router" {
                background #4a90e2
                color #ffffff
            }
            element "EdgeController" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

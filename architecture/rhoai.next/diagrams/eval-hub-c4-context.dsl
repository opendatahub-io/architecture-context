workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs LLM evaluations"
        aiAgent = person "AI Agent" "Automates evaluation workflows via MCP"

        evalHub = softwareSystem "eval-hub" "Lightweight REST API service for orchestrating LLM evaluations across multiple backends" {
            apiServer = container "eval-hub API Server" "REST API for managing evaluation jobs, providers, and collections" "Go Service, 8080/TCP"
            mcpServer = container "evalhub-mcp" "MCP server exposing eval-hub functionality to AI agents" "Go Service, 3001/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "Go Service, 8081/TCP"
            initContainer = container "eval-runtime-init" "Init container for downloading test data from S3, Git, or HuggingFace" "Go CLI"
            sidecar = container "eval-runtime-sidecar" "Sidecar proxy mediating all outbound traffic from evaluation adapters" "Go Service"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication and RBAC authorization sidecar" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "Container orchestration control plane" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for evaluation data persistence" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and artifact logging" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for test data" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container and artifact registry for eval cards" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Observability data collection" "External"
        modelEndpoints = softwareSystem "Model Endpoints" "LLM inference endpoints for evaluation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        hardwareProfile = softwareSystem "HardwareProfile CR" "Resource specification for evaluation jobs" "Internal Platform"
        kueue = softwareSystem "Kueue" "Job scheduling and queueing" "Internal Platform"

        # Person interactions
        dataScientist -> kubeRbacProxy "Creates evaluation jobs via REST API" "HTTPS/443, Bearer Token"
        aiAgent -> kubeRbacProxy "Invokes eval-hub tools via MCP" "HTTPS/443, Bearer Token"

        # Auth proxy routing
        kubeRbacProxy -> apiServer "Forwards authenticated requests" "HTTP/8080, X-User/X-Tenant"
        kubeRbacProxy -> mcpServer "Forwards MCP requests" "HTTP/3001, Forwarded identity"

        # MCP → API loop-back
        mcpServer -> kubeRbacProxy "Calls eval-hub REST API" "HTTPS/443, EVALHUB_TOKEN"

        # API Server dependencies
        apiServer -> postgresql "Stores evaluation data" "SQL/5432, Password auth"
        apiServer -> kubernetesApi "Creates and manages evaluation Jobs" "HTTPS/6443, ServiceAccount"
        apiServer -> hardwareProfile "Reads resource specs" "HTTPS/6443, ServiceAccount"
        apiServer -> kueue "Lists available queues" "HTTPS/6443, ServiceAccount"
        apiServer -> otelCollector "Exports traces, metrics, logs" "OTLP/gRPC"

        # Init container
        initContainer -> s3Storage "Downloads test data" "HTTPS/443, AWS credentials"

        # Sidecar proxy
        sidecar -> modelEndpoints "Proxies inference requests" "HTTPS, configured auth"
        sidecar -> mlflow "Tracks experiment results" "HTTPS, SA token"
        sidecar -> ociRegistry "Publishes eval cards" "HTTPS/443, Docker config"
        sidecar -> apiServer "Reports job status" "HTTPS/8080, SA token"
        sidecar -> otelCollector "Exports traces, metrics, logs" "OTLP/gRPC"

        # Prometheus
        prometheus -> metricsServer "Scrapes metrics" "HTTP/8081"
    }

    views {
        systemContext evalHub "SystemContext" {
            include *
            autoLayout
        }

        container evalHub "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        // Actors
        datascientist = person "Data Scientist" "Creates and runs LLM evaluation jobs via Dashboard or CLI"
        aiagent = person "AI Agent" "Claude, Cursor, or VS Code Copilot — invokes evaluations via MCP protocol"

        // Main System
        evalhub = softwareSystem "EvalHub" "Lightweight REST API service for orchestrating LLM evaluations across multiple backends, tracking experiments, and running natively on OpenShift" {
            apiServer = container "eval-hub API Server" "HTTP REST API for evaluation orchestration, provider/collection management, and job lifecycle" "Go Service, 8080/TCP"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar; validates Bearer tokens and sets X-Tenant + X-User headers" "Sidecar, 8443/TCP"
            k8sRuntime = container "K8s Runtime" "Creates and manages Kubernetes Jobs, ConfigMaps, and Secrets for evaluation workloads" "Go Component"
            storage = container "Storage Layer" "Persistent storage for jobs, providers, and collections with tenant-scoped multi-tenancy" "SQLite / PostgreSQL"
            configWatcher = container "Config Watcher" "Watches provider/collection YAML files for live reloads via fsnotify" "Go Component"
            mcpServer = container "evalhub-mcp" "Model Context Protocol server for AI agent integration; exposes tools, resources, and workflow prompts" "Go Service, 3001/TCP"
            sidecar = container "eval-runtime-sidecar" "Reverse proxy sidecar in evaluation job pods; proxies eval-hub, MLflow, OCI, and model traffic with credential injection" "Go Sidecar (KEP-753)"
            initContainer = container "eval-runtime-init" "Init container that downloads test data from S3-compatible storage" "Go Init Container"
        }

        // Internal Platform Dependencies
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages eval-hub via EvalHub CR; creates ServiceAccount, RBAC, ConfigMaps, kube-rbac-proxy sidecar" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for submitting and monitoring evaluation jobs" "Internal RHOAI"
        hardwareProfile = softwareSystem "HardwareProfile CRD" "Defines GPU/resource profiles for evaluation job pods (infrastructure.opendatahub.io/v1)" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Optional workload queue management for GPU scheduling via ResourceFlavor admission" "Internal Platform"

        // External Dependencies
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for Job, ConfigMap, Secret CRUD" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment creation, workspace management, and run tracking" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for test data files referenced by benchmarks" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation result export" "External"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "LLM model serving endpoints evaluated by benchmark frameworks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection system" "External"
        otelCollector = softwareSystem "OTEL Collector" "Distributed tracing, metrics, and logs collection" "External"
        serviceCaOp = softwareSystem "OpenShift service-ca Operator" "Provides service-serving CA certificates via ConfigMap" "External"

        // Relationships — Actors
        datascientist -> evalhub "Submits evaluation jobs via HTTPS/8443" "HTTPS, Bearer Token"
        datascientist -> dashboard "Uses web UI to submit evaluations"
        aiagent -> mcpServer "Invokes evaluation tools via MCP protocol" "MCP JSON-RPC, stdio/HTTP"

        // Relationships — Internal containers
        kubeRbacProxy -> apiServer "Forwards authenticated requests" "HTTP/8080, X-Tenant + X-User"
        apiServer -> k8sRuntime "Delegates job creation"
        apiServer -> storage "Reads/writes evaluation data"
        configWatcher -> apiServer "Notifies config changes"
        mcpServer -> apiServer "REST API calls" "HTTP/HTTPS"
        k8sRuntime -> k8sApi "Creates Jobs, ConfigMaps, Secrets" "HTTPS/443, SA Token"
        sidecar -> kubeRbacProxy "Reports job status" "HTTPS/8443, SA Token"
        sidecar -> mlflow "Tracks experiments" "HTTPS, SA Projected Token"
        sidecar -> ociRegistry "Pushes artifacts" "HTTPS/443, Docker v2 Bearer"
        sidecar -> modelEndpoint "Model inference with credential injection" "HTTPS, API Key"
        initContainer -> s3Storage "Downloads test data" "HTTPS/443, AWS IAM"

        // Relationships — Platform
        trustyaiOperator -> evalhub "Manages via EvalHub CR (trustyai.opendatahub.io/v1alpha1)"
        dashboard -> evalhub "Submits jobs via API"
        k8sRuntime -> hardwareProfile "Reads GPU/resource profiles" "HTTPS/443"
        k8sRuntime -> kueue "Labels Jobs for queue-based GPU scheduling" "Label: kueue.x-k8s.io/queue-name"

        // Relationships — External
        apiServer -> mlflow "Creates experiments, manages workspaces" "HTTP/HTTPS, Bearer Token"
        prometheus -> apiServer "Scrapes metrics" "HTTP/8081"
        apiServer -> otelCollector "Exports traces, metrics, logs" "gRPC/HTTP"
        serviceCaOp -> evalhub "Provides CA certificate ConfigMap"
    }

    views {
        systemContext evalhub "SystemContext" {
            include *
            autoLayout
        }

        container evalhub "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #50e3c2
                color #333333
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

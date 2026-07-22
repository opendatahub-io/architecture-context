workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages LLM evaluations via Dashboard or SDK"
        aiAgent = person "AI Agent / LLM" "Orchestrates evaluations programmatically via MCP protocol"

        evalHub = softwareSystem "EvalHub" "Centralized evaluation orchestration platform for LLM assessment" {
            apiServer = container "eval-hub API" "REST API for evaluation job orchestration, provider/collection management, result export" "Go HTTP Service, :8080/:8081"
            runtimeSidecar = container "eval-runtime-sidecar" "Reverse proxy sidecar — proxies requests with credential injection" "Go HTTP Proxy, :8080 pod-local"
            runtimeInit = container "eval-runtime-init" "Init container — downloads test data from S3" "Go CLI Utility"
            mcpServer = container "evalhub-mcp" "MCP server exposing evaluation tools, resources, prompts for LLM integration" "Go MCP Server, :3001"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication enforcement — TLS termination, sets X-Tenant/X-User headers" "Go Reverse Proxy, :8443"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages EvalHub deployment lifecycle via EvalHub CR (trustyai.opendatahub.io/v1alpha1)" "Internal RHOAI"
        kubernetesApi = softwareSystem "Kubernetes API" "Cluster API for Jobs, Pods, Secrets, ConfigMaps, HardwareProfile CRDs" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluation jobs, providers, collections" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking, run logging, evaluation card artifact storage" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation card artifact publishing (Distribution v2)" "External"
        s3Storage = softwareSystem "AWS S3 / S3-compatible" "Test data storage for evaluation jobs" "External"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "LLM inference endpoints (LiteLLM, KFP, custom)" "External"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed traces, metrics, and logs export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via HTTP scrape" "Platform"
        evalHubSdk = softwareSystem "eval-hub-sdk" "Python framework adapter SDK — evaluation providers implement FrameworkAdapter" "Internal RHOAI"

        # Person relationships
        dataScientist -> evalHub "Creates evaluations via Dashboard/SDK" "HTTPS/8443"
        aiAgent -> evalHub "Orchestrates evaluations via MCP tools" "HTTP(S)/3001"

        # Container relationships
        dataScientist -> kubeRbacProxy "Submits evaluation requests" "HTTPS/8443, Bearer token"
        kubeRbacProxy -> apiServer "Forwards with identity headers" "HTTP/8080, X-Tenant/X-User"
        aiAgent -> mcpServer "MCP tools/resources/prompts" "HTTP(S)/3001 or stdio"
        mcpServer -> apiServer "REST API calls" "HTTP(S)/8080, Bearer token"
        apiServer -> postgresql "Stores jobs, providers, collections" "SQL/5432, TLS"
        apiServer -> kubernetesApi "Creates Jobs, reads Pods/Secrets" "HTTPS/443, SA token"
        apiServer -> mlflow "Logs experiments and artifacts" "HTTP(S)/5000, Bearer token"
        apiServer -> ociRegistry "Publishes evaluation cards" "HTTPS/443, Docker auth"
        apiServer -> otlpCollector "Exports telemetry" "gRPC/4317 or HTTP/4318"
        runtimeSidecar -> apiServer "Forwards status updates" "HTTP(S)/8080, SA token"
        runtimeSidecar -> mlflow "Forwards MLflow operations" "HTTP(S)/5000, Bearer token"
        runtimeSidecar -> ociRegistry "Forwards OCI operations" "HTTPS/443, OCI bearer"
        runtimeSidecar -> modelEndpoint "Forwards inference requests" "HTTP(S), Bearer/ref-token"
        runtimeInit -> s3Storage "Downloads test data" "HTTPS/443, AWS IAM"
        prometheus -> apiServer "Scrapes metrics" "HTTP/8081"

        # Operator relationship
        trustyaiOperator -> evalHub "Manages deployment lifecycle via EvalHub CR"
        evalHubSdk -> runtimeSidecar "Adapter calls via localhost proxy" "HTTP/8080"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages LLM evaluation jobs"
        aiagent = person "AI Agent" "Interacts with eval-hub via MCP protocol"
        sre = person "SRE / Platform Operator" "Monitors eval-hub metrics and health"

        evalhub = softwareSystem "eval-hub" "Lightweight REST API service for orchestrating LLM evaluations across multiple backends" {
            apiserver = container "eval-hub API Server" "Primary REST API for evaluation orchestration, job management, and MLflow integration" "Go HTTP Service, Port 8080"
            metricsserver = container "Metrics Server" "Dedicated Prometheus metrics endpoint" "Go HTTP Service, Port 8081"
            mcpserver = container "evalhub-mcp" "MCP server exposing eval-hub tools to AI agents via stdio/HTTP/SSE" "Go MCP Service, Port 3001"
            initcontainer = container "eval-runtime-init" "Init container downloading test data from S3/Git/HuggingFace" "Go CLI, Init Container"
            sidecar = container "eval-runtime-sidecar" "Reverse proxy for evaluation Job pods; handles credential injection for model, MLflow, OCI, and API traffic" "Go HTTP Reverse Proxy"
            kuberbacproxy = container "kube-rbac-proxy" "Authentication and authorization sidecar for all API traffic" "Proxy, Port 443"
        }

        k8s = softwareSystem "Kubernetes API" "Container orchestration and workload management" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for evaluation, collection, and provider persistence" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and result storage" "Internal Platform"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for evaluation test data" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Dataset repository for evaluation test data" "External"
        ociregistry = softwareSystem "OCI Registries" "Container and artifact registries for eval cards" "External"
        modelendpoints = softwareSystem "Model Endpoints" "LLM inference endpoints for evaluation" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing, metrics, and log aggregation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        hardwareprofile = softwareSystem "HardwareProfile CRD" "Compute requirements for evaluation Jobs" "Internal Platform"
        kueue = softwareSystem "Kueue" "Job scheduling and quota management via LocalQueue" "Internal Platform"

        # User interactions
        datascientist -> kuberbacproxy "Creates evaluation jobs via REST API" "HTTPS/443, Bearer Token"
        aiagent -> kuberbacproxy "Interacts via MCP protocol" "HTTPS/443, Bearer Token"
        sre -> prometheus "Monitors eval-hub metrics"

        # Internal flows
        kuberbacproxy -> apiserver "Forwards authenticated requests" "HTTP/8080, X-User/X-Tenant"
        kuberbacproxy -> mcpserver "Forwards MCP requests" "HTTP/3001, X-User/X-Tenant"
        mcpserver -> apiserver "REST API calls" "HTTP/8080, Bearer Token"

        # API Server dependencies
        apiserver -> k8s "Creates and manages Jobs, ConfigMaps, Secrets, NetworkPolicies" "HTTPS/6443, ServiceAccount"
        apiserver -> postgresql "Stores evaluations, collections, providers" "SQL/5432, Password"
        apiserver -> mlflow "Tracks experiments and stores results" "HTTPS, SA Token"
        apiserver -> otel "Exports traces, metrics, and logs" "OTLP/gRPC"
        apiserver -> hardwareprofile "Reads compute requirements" "Kubernetes API"
        apiserver -> kueue "Lists LocalQueues for job scheduling" "Kubernetes API"

        # Job pod flows
        initcontainer -> s3 "Downloads test data" "HTTPS/443, AWS IAM"
        initcontainer -> huggingface "Downloads datasets" "HTTPS/443"
        sidecar -> modelendpoints "Proxies inference traffic with SA token injection" "HTTPS, TLS 1.2+"
        sidecar -> mlflow "Proxies experiment tracking" "HTTPS, SA Token"
        sidecar -> ociregistry "Proxies eval card and artifact storage" "HTTPS/443, Token"
        sidecar -> apiserver "Callbacks for job status updates" "HTTPS/8080, SA Token"

        # Metrics
        prometheus -> metricsserver "Scrapes /metrics" "HTTP/8081"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

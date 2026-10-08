workspace {
    model {
        datascientist = person "Data Scientist" "Submits evaluation jobs and reviews results"
        aiagent = person "AI Agent" "Automated agent using MCP protocol for evaluations"

        evalhub = softwareSystem "EvalHub" "Lightweight REST API for orchestrating LLM evaluations across multiple backends with pluggable storage and Kubernetes-native job orchestration" {
            apiserver = container "eval-hub API Server" "Main REST API for job, collection, and provider management" "Go net/http" "8080/TCP"
            metricsserver = container "Metrics Server" "Dedicated Prometheus metrics endpoint" "Go net/http" "8081/TCP"
            storage = container "SQL Storage" "Pluggable storage layer for job and config persistence" "SQLite / PostgreSQL"
            k8sruntime = container "Kubernetes Runtime" "Creates and manages evaluation Job pods" "client-go"
            localruntime = container "Local Runtime" "Runs evaluations as subprocesses for development" "Go os/exec"
            mcpserver = container "evalhub-mcp" "MCP server exposing eval-hub to AI agents" "Go MCP SDK" "3001/TCP"
            initcontainer = container "eval-runtime-init" "Init container downloading test data from S3/Git/HuggingFace" "Go"
            sidecar = container "eval-runtime-sidecar" "Sidecar proxying callbacks to eval-hub and MLflow" "Go" "8082/TCP"
        }

        kuberbacproxy = softwareSystem "kube-rbac-proxy" "Authentication and RBAC authorization reverse proxy" "Infrastructure"
        trustyaiop = softwareSystem "TrustyAI Service Operator" "Deploys and manages EvalHub instances via EvalHub CR" "Internal RHOAI"
        k8sapi = softwareSystem "Kubernetes API" "Cluster API for job orchestration and resource management" "Infrastructure"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking, run management, artifact storage" "Internal RHOAI"
        s3storage = softwareSystem "S3-compatible Storage" "Object storage for test data and model artifacts" "External"
        otelcollector = softwareSystem "OpenTelemetry Collector" "Telemetry collection for traces, metrics, logs" "Infrastructure"
        ociregistry = softwareSystem "OCI Registry" "Container and artifact registry for evalcard publishing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Infrastructure"
        hardwareprofile = softwareSystem "HardwareProfile CRD" "GPU/accelerator resource allocation definitions" "Internal RHOAI"

        datascientist -> kuberbacproxy "Creates evaluation jobs via HTTPS/443 with Bearer token"
        kuberbacproxy -> evalhub "Forwards authenticated requests with X-User/X-Tenant headers"
        aiagent -> evalhub "Uses MCP protocol for AI-assisted evaluations"
        trustyaiop -> evalhub "Deploys and manages via EvalHub CR"
        evalhub -> k8sapi "Creates Jobs, ConfigMaps, Secrets via HTTPS/6443"
        evalhub -> mlflow "Tracks experiments and stores artifacts via HTTP(S)/5000"
        evalhub -> s3storage "Downloads test data via HTTPS/443"
        evalhub -> otelcollector "Exports traces, metrics, logs via OTLP/gRPC 4317"
        evalhub -> ociregistry "Publishes evalcard artifacts via HTTPS/443"
        evalhub -> hardwareprofile "Reads GPU/accelerator profiles for job scheduling"
        prometheus -> evalhub "Scrapes metrics via HTTP/8081"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
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

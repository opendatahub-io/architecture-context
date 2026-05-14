workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages LLM evaluation jobs via Dashboard or API"
        platformadmin = person "Platform Admin" "Manages RBAC, providers, and collections"

        evalhub = softwareSystem "Eval Hub" "REST API service for orchestrating LLM evaluation jobs, managing evaluation providers, benchmark collections, and tracking results" {
            apiserver = container "eval-hub API Server" "Primary REST API server for evaluation job orchestration, provider/collection management. OpenAPI 3.1." "Go REST API, 8080/TCP"
            sidecar = container "eval-runtime-sidecar" "Native sidecar container proxying eval-hub API, MLflow, and OCI registry calls from evaluation job pods with token injection" "Go HTTP Reverse Proxy"
            initcontainer = container "eval-runtime-init" "S3 test data downloader init container for evaluation jobs" "Go Init Container"
            mcpserver = container "evalhub-mcp" "Model Context Protocol server exposing eval-hub resources (providers, benchmarks, collections, jobs) to AI agents" "Go MCP Server, stdio/HTTP:3001"
            pythonwheel = container "eval-hub-server (Python wheel)" "pip-installable wrapper distributing the Go eval-hub binary for local development" "Python Package"
        }

        k8sapi = softwareSystem "Kubernetes API Server" "Cluster API for authentication (TokenReview), authorization (SAR), and resource management (Jobs, ConfigMaps)" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking, run logging, artifact management for evaluation results" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluation jobs, providers, and collections" "External"
        s3 = softwareSystem "S3-compatible Object Storage" "Test data distribution to evaluation job pods" "External"
        ociregistry = softwareSystem "OCI Registry" "Evaluation artifact export (results, model cards) via Distribution v2 API" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing, metrics, and logs collection via OTLP" "External"
        kueue = softwareSystem "Kueue" "Job queue management for evaluation workloads" "External"
        serviceca = softwareSystem "OpenShift Service CA" "Service-serving CA certificate for internal TLS verification" "Internal RHOAI"
        platformoperator = softwareSystem "RHOAI Platform Operator" "Manages eval-hub deployment, service accounts, and configuration" "Internal RHOAI"
        evalproviders = softwareSystem "Evaluation Providers" "Lighteval, lm-evaluation-harness, Garak, GuideLLM, IBM CLEAR adapter containers" "External"

        # User interactions
        datascientist -> evalhub "Creates evaluation jobs, views results" "HTTPS/8080, Bearer Token"
        platformadmin -> evalhub "Manages providers, collections, RBAC" "HTTPS/8080, Bearer Token"

        # Eval Hub → External dependencies
        evalhub -> k8sapi "TokenReview, SAR, Job/ConfigMap CRUD" "HTTPS/443, SA Token"
        evalhub -> mlflow "Create experiments, track runs, manage artifacts" "HTTPS, Projected SA Token"
        evalhub -> postgresql "Persistent storage for jobs, providers, collections" "TCP/5432, Connection string"
        evalhub -> s3 "Download test data for evaluation jobs" "HTTPS/443, AWS IAM"
        evalhub -> ociregistry "Push evaluation artifacts" "HTTPS/443, Bearer Token"
        evalhub -> otel "Export traces, metrics, logs" "gRPC/4317 or HTTP/4318"
        evalhub -> kueue "Queue management for eval jobs" "Job labels"
        evalhub -> serviceca "TLS CA certificates" "ConfigMap"
        evalhub -> evalproviders "Pull and execute adapter container images" "Container Image"

        # Internal interactions
        platformoperator -> evalhub "Deploy, configure, manage lifecycle" "Operator CR"

        # Container-level interactions
        datascientist -> apiserver "REST API calls" "HTTPS/8080, Bearer Token"
        apiserver -> k8sapi "Auth + resource management" "HTTPS/443"
        apiserver -> postgresql "Query/store data" "TCP/5432"
        apiserver -> mlflow "Experiment tracking" "HTTPS"
        apiserver -> otel "Telemetry export" "OTLP"
        sidecar -> apiserver "Forward status events" "HTTPS/8080"
        sidecar -> mlflow "Forward MLflow API calls" "HTTPS"
        sidecar -> ociregistry "Forward artifact pushes" "HTTPS/443"
        initcontainer -> s3 "Download test data" "HTTPS/443"
        mcpserver -> apiserver "REST API client" "HTTPS/8080"
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
            element "Person" {
                shape person
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
        }
    }
}

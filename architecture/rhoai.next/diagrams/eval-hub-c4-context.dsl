workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs LLM evaluations via Dashboard or CLI"
        aiagent = person "AI Agent" "Programmatically submits evaluations and queries results via MCP"

        evalhub = softwareSystem "Eval Hub" "Centralized evaluation orchestration service for running LLM benchmarks as Kubernetes Jobs" {
            apiserver = container "eval-hub API" "REST API for evaluation job management, provider/collection CRUD, auth middleware" "Go Service, 8080/TCP"
            sidecar = container "eval-runtime-sidecar" "Reverse proxy sidecar in evaluation job pods; injects auth for eval-hub, MLflow, OCI" "Go HTTP Proxy, KEP-753 native sidecar"
            initcontainer = container "eval-runtime-init" "Init container that downloads test data from S3 before evaluation" "Go CLI"
            mcpserver = container "evalhub-mcp" "MCP server exposing eval-hub capabilities as AI-consumable tools and resources" "Go MCP Server, 3001/TCP"
            configloader = container "Config Loader" "Hot-reloads provider/collection YAML from ConfigMaps via fsnotify" "Go (embedded in API)"
        }

        k8s = softwareSystem "Kubernetes API Server" "Manages Jobs, ConfigMaps, TokenReview, SubjectAccessReview" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluations, providers, collections" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment creation and evaluation result tracking" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Storage" "Test data download for evaluation benchmarks" "External"
        ociregistry = softwareSystem "OCI Registry (Quay)" "Evaluation artifact export" "External"
        otel = softwareSystem "OTEL Collector" "Distributed tracing and metrics export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping" "External"
        kueue = softwareSystem "Kueue" "Optional job queue management" "Internal RHOAI"
        rhoaioperator = softwareSystem "RHOAI Operator" "Deploys and manages eval-hub lifecycle" "Internal RHOAI"
        serviceca = softwareSystem "OpenShift Service CA" "Internal TLS certificate authority" "External"

        lmeval = softwareSystem "LM Evaluation Harness" "Evaluation runtime adapter for language model benchmarks" "Eval Runtime"
        lighteval = softwareSystem "Lighteval" "Lightweight evaluation runtime adapter" "Eval Runtime"
        garak = softwareSystem "Garak" "Security evaluation runtime adapter" "Eval Runtime"
        guidellm = softwareSystem "GuideLLM" "Performance evaluation runtime adapter" "Eval Runtime"

        datascientist -> evalhub "Submits evaluations, manages providers/collections" "HTTPS/8080, Bearer Token"
        aiagent -> mcpserver "Submits evaluations, queries status via MCP" "HTTP/3001 or stdio"

        mcpserver -> apiserver "Forwards MCP tool calls to REST API" "HTTPS/8080"
        apiserver -> k8s "Creates/deletes Jobs and ConfigMaps; TokenReview; SAR" "HTTPS/443, SA token"
        apiserver -> postgresql "Stores evaluation records, providers, collections" "SQL/5432, Password"
        apiserver -> mlflow "Creates experiments for evaluation tracking" "HTTPS, Bearer token"
        apiserver -> otel "Exports traces and metrics" "OTLP/4317-4318"

        initcontainer -> s3 "Downloads test data files" "HTTPS/443, AWS credentials"

        sidecar -> apiserver "Forwards status updates from eval adapter" "HTTPS/8080, SA token"
        sidecar -> mlflow "Forwards experiment tracking calls" "HTTPS, Projected SA token (1h)"
        sidecar -> ociregistry "Forwards artifact push requests" "HTTPS/443, Docker config"

        rhoaioperator -> evalhub "Deploys, configures, manages lifecycle"
        prometheus -> apiserver "Scrapes /metrics endpoint" "HTTP(S)/8080"

        apiserver -> lmeval "Creates K8s Job with adapter container"
        apiserver -> lighteval "Creates K8s Job with adapter container"
        apiserver -> garak "Creates K8s Job with adapter container"
        apiserver -> guidellm "Creates K8s Job with adapter container"
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
            element "Eval Runtime" {
                background #e8e8e8
                color #333333
            }
            element "Person" {
                background #f5a623
                shape Person
            }
        }
    }
}

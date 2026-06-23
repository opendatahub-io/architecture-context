workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs LLM evaluation jobs via dashboard, CLI, or SDK"
        aiDeveloper = person "AI Developer" "Uses IDE-based AI assistants for evaluation workflows via MCP"

        evalHub = softwareSystem "Eval Hub" "Orchestrates LLM evaluation jobs by managing providers, benchmark collections, and job execution on Kubernetes" {
            apiServer = container "eval-hub API Server" "REST API for evaluation job orchestration, provider/collection CRUD, and K8s Job lifecycle management" "Go HTTP Service, 8080/TCP"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics (request duration, total, in-flight)" "Go HTTP Service, 8081/TCP"
            mcpServer = container "evalhub-mcp" "Model Context Protocol server exposing eval-hub as MCP tools, resources, and prompts for AI-assisted evaluation" "Go MCP Server, 3001/TCP or stdio"
            runtimeSidecar = container "eval-runtime-sidecar" "Reverse proxy injected into evaluation Job pods; routes traffic to eval-hub API, MLflow, and OCI registries with per-target auth" "Go HTTP Reverse Proxy, 8080/TCP"
            runtimeInit = container "eval-runtime-init" "Init container that downloads test data from S3-compatible storage before evaluation runtime starts" "Go CLI"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar that validates bearer tokens and injects X-Tenant/X-User identity headers" "Internal Platform"
        kubernetesAPI = softwareSystem "Kubernetes API" "Orchestrates Jobs and ConfigMaps for evaluation execution" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluation jobs, providers, collections, and multi-tenant state" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking, run management, and evaluation metrics logging" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for test datasets used by evaluation runtimes" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container image and model artifact registry for evaluation runtime images" "External"
        otelCollector = softwareSystem "OTEL Collector" "Receives distributed traces via OTLP for observability" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes and stores operational metrics" "External"
        lmEvalHarness = softwareSystem "LM Evaluation Harness" "Evaluation runtime with 180+ benchmarks for accuracy, reasoning, safety, code, etc." "External"
        lighteval = softwareSystem "Lighteval" "Evaluation runtime with 30+ benchmarks" "External"
        garak = softwareSystem "Garak" "Safety evaluation runtime for adversarial testing" "External"

        # Person interactions
        dataScientist -> kubeRbacProxy "Creates evaluation jobs via HTTPS/443 with bearer token"
        aiDeveloper -> mcpServer "Submits evaluations via MCP tools (stdio or HTTP/3001)"

        # Auth flow
        kubeRbacProxy -> apiServer "Forwards requests with X-Tenant + X-User headers, HTTP/8080 (pod-local)"

        # Internal flows
        mcpServer -> apiServer "Delegates all operations, HTTP(S)/8080 with bearer token"

        # API Server egress
        apiServer -> kubernetesAPI "Creates/deletes Jobs and ConfigMaps, HTTPS/443 with SA token"
        apiServer -> postgresql "Stores evaluation state, TCP/5432 with DB credentials"
        apiServer -> mlflow "Creates experiments and logs runs, HTTP(S) with bearer token"
        apiServer -> otelCollector "Exports distributed traces, gRPC/4317"

        # Metrics
        prometheus -> metricsServer "Scrapes /metrics, HTTP/8081"

        # Runtime flows
        runtimeInit -> s3Storage "Downloads test datasets, HTTPS/443 with AWS IAM credentials"
        runtimeSidecar -> apiServer "Reports benchmark status, HTTPS with K8s SA token"
        runtimeSidecar -> mlflow "Logs evaluation metrics, HTTPS with MLflow bearer token"
        runtimeSidecar -> ociRegistry "Pulls artifacts, HTTPS/443 via OCI v2 auth"

        # Evaluation runtimes (run as containers alongside sidecar in Job pods)
        lmEvalHarness -> runtimeSidecar "Evaluation API calls via localhost:8080"
        lighteval -> runtimeSidecar "Evaluation API calls via localhost:8080"
        garak -> runtimeSidecar "Safety evaluation calls via localhost:8080"
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
                background #9b59b6
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
        }
    }
}

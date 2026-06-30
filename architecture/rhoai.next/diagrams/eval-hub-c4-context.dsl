workspace {
    model {
        datascientist = person "Data Scientist" "Submits and monitors LLM evaluation jobs"
        aiassistant = person "AI Assistant" "Cursor, VS Code, Claude Code - interacts via MCP"

        evalhub = softwareSystem "EvalHub" "LLM evaluation orchestration service for Red Hat OpenShift AI" {
            apiPod = container "eval-hub API" "REST API for evaluation job orchestration, provider/collection management, benchmark execution" "Go REST Service (8080/TCP)" {
                tags "Primary"
            }
            mcpServer = container "evalhub-mcp" "Model Context Protocol server exposing evaluation tools, resources, and prompts for AI assistants" "Go MCP Server (3001/TCP)" {
                tags "Primary"
            }
            runtimeSidecar = container "eval-runtime-sidecar" "Credential-injection proxy for evaluation job pods; routes requests and substitutes ref tokens with real credentials" "Go Sidecar (8080/TCP pod-local)" {
                tags "Ephemeral"
            }
            runtimeInit = container "eval-runtime-init" "Downloads test data from S3-compatible storage into evaluation job pods before benchmark execution" "Go Init Container" {
                tags "Ephemeral"
            }
            rbacProxy = container "kube-rbac-proxy" "Authentication and authorization enforcement via SubjectAccessReview; injects X-Tenant/X-User headers" "Sidecar (8443/TCP → upstream)" {
                tags "Security"
            }
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages EvalHub deployment via EvalHub CR (trustyai.opendatahub.io/v1alpha1)" {
            tags "Internal ODH"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Job scheduling, Secret/ConfigMap management, HardwareProfile CR access" {
            tags "External"
        }
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluations, collections, and providers (JSONB)" {
            tags "External"
        }
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and result aggregation" {
            tags "External"
        }
        s3Storage = softwareSystem "S3-compatible Storage" "Test data download for evaluation benchmarks" {
            tags "External"
        }
        ociRegistry = softwareSystem "OCI Registry" "Evaluation artifact push/pull" {
            tags "External"
        }
        modelEndpoints = softwareSystem "Model Endpoints" "LLM inference endpoints for evaluations" {
            tags "External"
        }
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing, metrics, and log export" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics scraping" {
            tags "External"
        }

        # Evaluation providers (container images)
        lmEvalHarness = softwareSystem "lm-evaluation-harness" "167+ LLM evaluation benchmarks" {
            tags "Provider"
        }
        ragas = softwareSystem "RAGAS" "RAG evaluation framework" {
            tags "Provider"
        }
        garak = softwareSystem "Garak" "LLM vulnerability scanner (9 security benchmarks)" {
            tags "Provider"
        }
        guidellm = softwareSystem "GuideLLM" "LLM performance/throughput evaluation" {
            tags "Provider"
        }
        lighteval = softwareSystem "LightEval" "Lightweight LLM evaluation framework" {
            tags "Provider"
        }

        kueue = softwareSystem "Kueue" "Workload queuing for GPU-bound evaluation jobs" {
            tags "Internal ODH"
        }
        hardwareProfile = softwareSystem "HardwareProfile CR" "GPU type, count, CPU/memory limits (infrastructure.opendatahub.io/v1)" {
            tags "Internal ODH"
        }

        # Relationships - Users
        datascientist -> evalhub "Creates InferenceService jobs via REST API" "HTTPS/8443"
        aiassistant -> evalhub "Interacts via MCP protocol" "HTTPS/8443"

        # Relationships - Internal
        datascientist -> rbacProxy "Bearer Token (SA token)" "HTTPS/8443"
        aiassistant -> rbacProxy "Bearer Token (SA token)" "HTTPS/8443"
        rbacProxy -> apiPod "X-Tenant + X-User headers" "HTTP/8080"
        rbacProxy -> mcpServer "X-Tenant + X-User headers" "HTTP/3001"
        mcpServer -> apiPod "Evaluation CRUD operations" "HTTP/8080"
        apiPod -> runtimeSidecar "Creates Job pods with sidecar" ""
        apiPod -> runtimeInit "Creates Job pods with init container" ""
        runtimeSidecar -> rbacProxy "Status events" "HTTPS/8443"

        # Relationships - External dependencies
        trustyaiOperator -> evalhub "Manages deployment via EvalHub CR"
        apiPod -> k8sApi "Create/delete Jobs, ConfigMaps, Secrets; read HardwareProfiles" "HTTPS/443"
        apiPod -> postgresql "JSONB storage (evaluations, collections, providers)" "TCP/5432"
        apiPod -> mlflow "Create experiments, set tags" "HTTPS"
        apiPod -> otelCollector "Tracing, metrics, logs" "gRPC/4317"
        runtimeInit -> s3Storage "Download test data" "HTTPS/443"
        runtimeSidecar -> modelEndpoints "Model inference with credential injection" "HTTPS"
        runtimeSidecar -> mlflow "Experiment tracking" "HTTPS"
        runtimeSidecar -> ociRegistry "Artifact push/pull" "HTTPS/443"
        prometheus -> apiPod "Scrape metrics" "HTTP/8081"
        apiPod -> kueue "Workload queuing via Job labels" ""
        apiPod -> hardwareProfile "Resolve GPU/resource requirements" "HTTPS/443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Provider" {
                background #9b59b6
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Ephemeral" {
                background #f5a623
                color #ffffff
            }
            element "Security" {
                background #e74c3c
                color #ffffff
            }
        }
    }
}

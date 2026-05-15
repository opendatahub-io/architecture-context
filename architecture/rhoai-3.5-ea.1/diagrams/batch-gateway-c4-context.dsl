workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible Batch API"
        admin = person "Platform Admin" "Deploys and configures batch-gateway via Helm chart"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for llm-d" {
            apiserver = container "API Server" "REST API for batch job submission, file management, status queries, and cancellation. OpenAI Batch API compatible." "Go HTTP Service" "Port 8000/TCP"
            processor = container "Batch Processor" "Asynchronous job processor: dequeues jobs, dispatches inference requests with concurrency control (global: 100, per-model: 10), writes results." "Go Worker Service" "Port 9090/TCP (observability)"
            gc = container "Garbage Collector" "Periodic scanner (30m interval) that removes expired batch jobs and files from metadata store and file storage." "Go Background Service"
        }

        redis = softwareSystem "Redis / Valkey" "Metadata storage (hash sets), priority queue (sorted sets), event bus (blocking lists), status cache (key-value with TTL)" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative persistent metadata storage for batch jobs and files" "External"
        s3 = softwareSystem "S3-Compatible Storage" "File content storage for batch input/output/error JSONL files. Tenant isolation via SHA256-hashed folder prefix." "External"
        inferenceGateway = softwareSystem "LLM Inference Gateway" "OpenAI-compatible inference endpoint (e.g., vLLM, llm-d) for individual request dispatch" "External"
        gatewayAPI = softwareSystem "llm-d-inference-gateway" "Kubernetes Gateway API gateway providing external ingress for batch API traffic" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate auto-provisioning for API server HTTPS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor (apiserver) and PodMonitor (processor)" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing export via OTLP gRPC" "External"
        grafana = softwareSystem "Grafana" "Dashboard auto-loading via ConfigMap with grafana_dashboard label" "External"
        gie = softwareSystem "GIE InferenceObjective" "Priority band assignment via x-gateway-inference-objective header" "Internal Platform"

        # User interactions
        user -> batchGateway "Submits batch jobs, uploads files, queries status, retrieves results" "HTTP/HTTPS + X-MaaS-Username header"
        admin -> batchGateway "Deploys and configures via Helm chart" "kubectl / Helm"

        # Internal container relationships
        apiserver -> redis "CRUD metadata, enqueue jobs, publish cancel events" "Redis/6379/TCP, TLS optional"
        apiserver -> postgresql "CRUD metadata (alternative backend)" "PostgreSQL/5432/TCP, TLS via DSN"
        apiserver -> s3 "Upload/download JSONL files" "HTTPS/443/TCP, AWS IAM"

        processor -> redis "Dequeue jobs, update status, receive cancel signals" "Redis/6379/TCP, TLS optional"
        processor -> s3 "Read input JSONL, write output/error JSONL" "HTTPS/443/TCP, AWS IAM"
        processor -> inferenceGateway "Dispatch individual inference requests with concurrency control" "HTTP/HTTPS, Bearer token"

        gc -> redis "Query and delete expired metadata" "Redis/6379/TCP, TLS optional"
        gc -> s3 "Delete expired file objects" "HTTPS/443/TCP, AWS IAM"

        # External integrations
        gatewayAPI -> apiserver "Routes external traffic via HTTPRoute" "Gateway API"
        apiserver -> otel "Export distributed traces" "gRPC/4317/TCP, OTLP"
        processor -> otel "Export distributed traces" "gRPC/4317/TCP, OTLP"
        prometheus -> apiserver "Scrape metrics" "HTTP/8081/TCP"
        prometheus -> processor "Scrape metrics" "HTTP/9090/TCP"
        certManager -> apiserver "Provision TLS certificates" "Kubernetes API"
        processor -> gie "Priority band via header propagation" "HTTP header"
    }

    views {
        systemContext batchGateway "SystemContext" {
            include *
            autoLayout
        }

        container batchGateway "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            relationship "Relationship" {
                dashed false
            }
        }
    }
}

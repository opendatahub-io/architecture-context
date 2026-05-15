workspace {
    model {
        dataScientist = person "Data Scientist / API Client" "Submits batch inference jobs via OpenAI-compatible API"
        platformAdmin = person "Platform Admin" "Deploys and configures Batch Gateway via Helm"

        batchGateway = softwareSystem "Batch Gateway" "High-performance batch inference job processing system with OpenAI-compatible API" {
            apiServer = container "API Server" "Handles REST API requests for batch job submission, management, tracking, and file operations" "Go HTTP Service" "Port: 8000/TCP"
            processor = container "Batch Processor" "Dequeues batch jobs, builds per-model execution plans, dispatches inference requests to downstream gateways" "Go Worker Service" "Port: 9090/TCP (obs)"
            gc = container "Garbage Collector" "Periodically scans for and deletes expired batch jobs and files" "Go Background Service" "Single replica"
        }

        postgresql = softwareSystem "PostgreSQL" "Batch and file metadata storage with JSONB tag queries" "External"
        redis = softwareSystem "Redis" "Priority queue (sorted sets), event pub/sub (lists), status cache, optional metadata backend" "External"
        s3 = softwareSystem "S3-compatible Storage" "Batch input/output/error file content storage" "External"
        inferenceGateway = softwareSystem "Inference Gateway (llm-d / vLLM)" "Downstream target for batch inference request dispatch" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API (Kubernetes)" "Optional ingress exposure via HTTPRoute" "Internal Platform"
        inferenceObjective = softwareSystem "GIE InferenceObjective" "Priority-based batch flow control via CRD reference" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor/PodMonitor" "External"
        grafana = softwareSystem "Grafana" "Dashboard visualization with pre-built JSON dashboards" "External"
        envoyExtAuthz = softwareSystem "Envoy ext_authz" "External authentication enforcement" "External"

        # User interactions
        dataScientist -> batchGateway "Submits batch jobs and files via /v1/batches, /v1/files" "HTTP/HTTPS 8000/TCP"
        platformAdmin -> batchGateway "Deploys and monitors" "Helm, kubectl"

        # Internal container interactions
        apiServer -> postgresql "Store/retrieve batch and file metadata" "PostgreSQL/5432"
        apiServer -> redis "Enqueue jobs, publish events, cache status" "Redis/6379"
        apiServer -> s3 "Upload/download file content" "HTTPS/443"

        processor -> redis "Dequeue jobs (priority queue), subscribe to cancel events" "Redis/6379"
        processor -> postgresql "Read metadata, update batch status" "PostgreSQL/5432"
        processor -> s3 "Download input files, upload output/error files" "HTTPS/443"
        processor -> inferenceGateway "Dispatch batch inference requests" "HTTP/HTTPS, Bearer token"

        gc -> postgresql "Query and delete expired metadata" "PostgreSQL/5432"
        gc -> s3 "Delete expired file content" "HTTPS/443"

        # External integrations
        gatewayAPI -> apiServer "Route external traffic via HTTPRoute" "/v1/batches, /v1/files"
        envoyExtAuthz -> apiServer "Authenticate requests, inject tenant headers" "HTTP headers"
        certManager -> apiServer "Provision TLS certificates" "Certificate CRD"
        apiServer -> otelCollector "Export traces" "gRPC/4317 OTLP"
        processor -> otelCollector "Export traces" "gRPC/4317 OTLP"
        prometheus -> apiServer "Scrape metrics" "HTTP/8081"
        prometheus -> processor "Scrape metrics" "HTTP/9090"
        grafana -> prometheus "Query metrics for dashboards" "PromQL"
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

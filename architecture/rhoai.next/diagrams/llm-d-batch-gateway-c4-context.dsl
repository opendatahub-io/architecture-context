workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"
        platformadmin = person "Platform Admin" "Manages batch gateway deployment and configuration"

        batchGateway = softwareSystem "llm-d Batch Gateway" "OpenAI-compatible batch inference API gateway for the llm-d platform" {
            apiserver = container "API Server" "OpenAI-compatible REST API for batch job and file management. Handles /v1/batches and /v1/files endpoints." "Go Service, 8000/TCP"
            processor = container "Batch Processor" "Dequeues batch jobs from priority queue, dispatches inference requests with AIMD flow control, uploads results." "Go Service"
            gc = container "Garbage Collector" "Periodic cleanup of expired jobs/files and reconciliation of orphaned jobs from crashed processors." "Go Service"
        }

        postgresql = softwareSystem "PostgreSQL" "Batch and file metadata storage with CAS updates" "External Data Store"
        redis = softwareSystem "Redis / Valkey" "Priority queue (ZSET), event channels (streams), status store, in-flight tracking" "External Data Store"
        s3 = softwareSystem "S3-Compatible Storage" "Batch input/output/error file storage" "External Data Store"

        llmdRouter = softwareSystem "llm-d Router" "Downstream inference gateway for synchronous dispatch" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Asynchronous dispatch via Redis-backed request/result queues" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant / Authorino" "Authentication and authorization enforcement upstream of API server" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes ingress routing via HTTPRoute CRD" "Internal Platform"

        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning for API server" "External"
        otelCollector = softwareSystem "OTel Collector" "OpenTelemetry distributed trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor/PodMonitor" "External"
        grafana = softwareSystem "Grafana" "Dashboard visualization via ConfigMap sidecar auto-discovery" "External"

        # User interactions
        datascientist -> kuadrant "Authenticates via API key / SA token / OpenShift token" "HTTPS/443"
        kuadrant -> apiserver "Forwards authenticated requests with X-MaaS-Username header" "HTTP(S)/8000"

        # API Server interactions
        apiserver -> postgresql "Stores/queries batch and file metadata" "TCP/5432 TLS"
        apiserver -> redis "Enqueues jobs, publishes events, stores status" "TCP/6379 TLS optional"
        apiserver -> s3 "Uploads/downloads batch files" "HTTPS/443 TLS 1.2+"

        # Processor interactions
        processor -> redis "Dequeues jobs, updates status, heartbeats" "TCP/6379 TLS optional"
        processor -> s3 "Downloads input files, uploads results" "HTTPS/443 TLS 1.2+"
        processor -> postgresql "Updates job status with CAS" "TCP/5432 TLS"
        processor -> llmdRouter "Dispatches inference requests (sync mode)" "HTTP(S) + mTLS optional"
        processor -> llmdAsync "Submits requests and polls results (async mode)" "Redis/6379"
        processor -> otelCollector "Exports distributed traces" "gRPC/4317"

        # GC interactions
        gc -> postgresql "Queries and deletes expired records" "TCP/5432 TLS"
        gc -> redis "Cleans up keys, reconciles orphaned jobs" "TCP/6379"
        gc -> s3 "Deletes expired batch files" "HTTPS/443"

        # Infrastructure
        gatewayAPI -> apiserver "Routes external traffic via HTTPRoute" "HTTP(S)/8000"
        certManager -> apiserver "Provisions TLS certificates" "Certificate CRD"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8081"
        prometheus -> processor "Scrapes metrics" "HTTP/9090"
        prometheus -> gc "Scrapes metrics" "HTTP/9091"

        # Admin interactions
        platformadmin -> batchGateway "Deploys and configures via Helm chart"
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
            element "Person" {
                shape Person
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
            element "External Data Store" {
                background #336791
                color #ffffff
                shape Cylinder
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }
}

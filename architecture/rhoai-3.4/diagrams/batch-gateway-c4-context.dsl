workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Submits batch inference jobs via API"
        platform_admin = person "Platform Admin" "Configures and manages batch gateway deployment"

        batchGateway = softwareSystem "Batch Gateway" "High-performance batch inference processing system with OpenAI-compatible API" {
            apiserver = container "API Server" "REST API exposing /v1/batches and /v1/files endpoints for batch job submission, management, and file operations" "Go Service, 8000/TCP"
            processor = container "Batch Processor" "Background worker pulling jobs from priority queue, dispatching inference requests with concurrency control, prefix-cache optimization, and SLO-driven scheduling" "Go Service, 9090/TCP (obs)"
            gc = container "Garbage Collector" "Long-lived process periodically scanning for and removing expired batch jobs and files" "Go Service"
        }

        postgresql = softwareSystem "PostgreSQL" "Persistent metadata storage for batch jobs and file records" "External Infrastructure"
        redis = softwareSystem "Redis" "Priority queue (Sorted Set), event channels (List), real-time status (String), Lua scripted queries" "External Infrastructure"
        s3 = softwareSystem "S3-compatible Storage" "Input/output file storage (AWS S3, MinIO, Ceph RGW)" "External Infrastructure"
        inferenceGateway = softwareSystem "Inference Gateway" "Downstream LLM inference endpoint (llm-d-inference-scheduler)" "Internal Platform"
        gieExtension = softwareSystem "Gateway API Inference Extension" "Kubernetes Gateway API extensions for inference workload routing" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor and PodMonitor" "External Infrastructure"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry distributed trace collection" "External Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for external traffic routing via HTTPRoute" "External Infrastructure"

        # External relationships
        datascientist -> batchGateway "Submits batch jobs, uploads files, checks status" "HTTPS/8000, Tenant header"
        platform_admin -> batchGateway "Configures via Helm chart, monitors via Grafana dashboards"

        # Internal container relationships
        datascientist -> apiserver "POST /v1/batches, POST /v1/files, GET status" "HTTP/HTTPS 8000/TCP, X-MaaS-Username"
        apiserver -> postgresql "Store/query batch and file metadata" "TCP/5432, TLS (configurable)"
        apiserver -> redis "Enqueue jobs (ZADD), send cancel events (RPUSH)" "TCP/6379, TLS (configurable)"
        apiserver -> s3 "Upload/download files" "HTTPS/443, IAM or static credentials"

        processor -> redis "Dequeue jobs (ZMPOP), subscribe events (BLMPOP), update progress" "TCP/6379, TLS (configurable)"
        processor -> postgresql "Fetch job metadata, update status" "TCP/5432, TLS (configurable)"
        processor -> s3 "Download input files, upload output/error files" "HTTPS/443, TLS 1.2+"
        processor -> inferenceGateway "Dispatch inference requests with SLO headers" "HTTP/HTTPS, Bearer token / API key"

        gc -> postgresql "Query and delete expired records" "TCP/5432, TLS (configurable)"
        gc -> redis "Delete expired keys" "TCP/6379, TLS (configurable)"
        gc -> s3 "Delete expired files" "HTTPS/443, TLS 1.2+"

        # Observability
        prometheus -> apiserver "Scrape metrics" "HTTP/8081"
        prometheus -> processor "Scrape metrics" "HTTP/9090"
        processor -> otlpCollector "Export traces" "gRPC, OTLP"

        # Infrastructure
        certManager -> apiserver "Provision TLS certificates" "Certificate CR"
        gatewayAPI -> apiserver "Route external traffic" "HTTPRoute CR"
        inferenceGateway -> gieExtension "Uses for workload routing" "Gateway API"
    }

    views {
        systemContext batchGateway "SystemContext" {
            include *
            autoLayout
            description "Batch Gateway in the context of its external dependencies and users"
        }

        container batchGateway "Containers" {
            include *
            autoLayout
            description "Internal architecture of the Batch Gateway system showing API Server, Processor, and Garbage Collector"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
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
        }
    }
}

workspace "llm-d-batch-gateway" "C4 model for llm-d-batch-gateway (RHOAI 3.7-ea.1)" {
    model {
        user = person "API Client" "Submits OpenAI-compatible batch jobs (files + batches)"

        batchGateway = softwareSystem "llm-d-batch-gateway" "OpenAI-compatible batch inference gateway that queues jobs in PostgreSQL and drives them through llm-d inference gateways with adaptive concurrency" {
            apiserver = container "batch-gateway-apiserver" "/v1/files and /v1/batches REST API, stores metadata and enqueues jobs. No in-process auth; trusts X-MaaS-Username." "Go HTTP Service (Deployment), 8000/TCP + 8081/TCP"
            processor = container "batch-gateway-processor" "Polls the priority queue, builds per-model plans, dispatches inference with AIMD concurrency, writes results" "Go Worker (StatefulSet), 9090/TCP"
            gc = container "batch-gateway-gc" "Deletes expired batches/files; reconciler reclaims jobs from dead processor pods" "Go Worker (Deployment), 9091/TCP"
            workDir = container "Processor workDir" "Per-model plan files and result checkpoints" "emptyDir 10Gi" "Storage"
        }

        platformGateway = softwareSystem "Platform External Gateway" "Gateway API + Kuadrant/Authorino/Limitador; HTTPRoute batch-route, TokenReview auth, rate limiting, tenant header injection" "Internal RHOAI"
        internalGateway = softwareSystem "llm-d Internal Gateway" "ClusterIP gateway batch-llm-route; AuthPolicy SubjectAccessReview on inferencepools; routes to llm-d scheduler and vLLM" "Internal RHOAI"
        llmdAsync = softwareSystem "llm-d-async" "Optional metrics-driven flow-control dispatcher consuming Redis/SQL queues" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Optional API server TLS certificate issuance" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus Operator" "ServiceMonitor / PodMonitor / PrometheusRule scraping" "Internal RHOAI"

        postgres = softwareSystem "PostgreSQL" "Metadata, priority queue, events, checkpoints; coordination plane (required)" "External"
        s3 = softwareSystem "S3-compatible Storage / PVC" "Input/output file content" "External"
        redis = softwareSystem "Redis / Valkey" "Async dispatch queue (dispatchMode=async)" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Trace collection" "External"
        k8s = softwareSystem "Kubernetes API" "StatefulSet/pod watch for orphan recovery" "External"

        user -> platformGateway "Calls /v1/files, /v1/batches" "HTTPS/443, Bearer token"
        platformGateway -> apiserver "Forwards authenticated requests with X-MaaS-Username" "HTTP/8000 (TLS optional)"

        apiserver -> postgres "Stores metadata, enqueues batches, emits cancel events" "PostgreSQL/5432"
        apiserver -> s3 "Uploads/downloads files" "HTTPS/443"

        processor -> postgres "Dequeues, leases, updates status, LISTEN cancel" "PostgreSQL/5432"
        processor -> s3 "Reads input, writes output/error files" "HTTPS/443"
        processor -> workDir "Writes plans and checkpoints"
        processor -> internalGateway "Sends inference requests with replayed user Bearer / API key" "HTTP/HTTPS, optional mTLS"
        processor -> redis "Pushes async requests, polls results" "RESP/6379"
        llmdAsync -> redis "Consumes requests, writes results" "RESP/6379"
        llmdAsync -> internalGateway "Inference with pass-through Bearer" "HTTP/HTTPS"

        gc -> k8s "Watches processor StatefulSet and pods" "HTTPS/6443"
        gc -> postgres "Deletes expired rows, reclaims orphaned jobs" "PostgreSQL/5432"
        gc -> s3 "Deletes expired objects" "HTTPS/443"

        apiserver -> otel "Exports traces" "OTLP/gRPC 4317"
        processor -> otel "Exports traces" "OTLP/gRPC 4317"
        gc -> otel "Exports traces" "OTLP/gRPC 4317"
        prometheus -> apiserver "Scrapes /metrics" "HTTP/8081"
        prometheus -> processor "Scrapes /metrics" "HTTP/9090"
        prometheus -> gc "Scrapes /metrics" "HTTP/9091"
        certManager -> apiserver "Issues serving certificate (optional)"
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
                shape person
                background #f5a623
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Storage" {
                shape cylinder
                background #a8c8f0
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}

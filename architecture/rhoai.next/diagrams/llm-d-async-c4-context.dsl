workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Submits batch inference requests via producer library"
        sre = person "SRE / Platform Operator" "Monitors processor health, configures dispatch gates"

        asyncProcessor = softwareSystem "llm-d Async Processor" "Asynchronous dispatch processor for latency-insensitive LLM inference workloads" {
            processor = container "async-processor" "Consumes from message queues, applies flow control gates, dispatches to inference gateways" "Go Service"
            apiModule = container "api module" "Request/response types, wire format, error categories" "Go Library (zero external deps)"
            producerModule = container "producer module" "Client library for submitting requests and retrieving results" "Go Library (api + go-redis)"
            pipelineModule = container "pipeline module" "Flow, Gate, RequestMergePolicy interfaces" "Go Library (api only)"
            helmChart = container "Helm Chart" "Deployment, ServiceAccount, ConfigMap, PodMonitor, PrometheusRule, Grafana dashboards" "Kubernetes Manifests"
        }

        redis = softwareSystem "Redis / Valkey" "Message queue backend for sorted sets, pub/sub, lists, quota, and cancellation" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Message queue backend for GCP deployments" "External"
        gcpMonitoring = softwareSystem "GCP Cloud Monitoring" "Subscription backlog metrics" "External"
        prometheus = softwareSystem "Prometheus" "Metric-based dispatch gate queries (saturation, budget, custom)" "External"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed tracing export (Jaeger, Grafana Tempo)" "External"

        llmdRouter = softwareSystem "llm-d-router" "Inference gateway receiving dispatched requests" "Internal llm-d"
        epp = softwareSystem "gateway-api-inference-extension (EPP)" "Flow control metrics provider" "Internal llm-d"
        vllm = softwareSystem "vLLM Model Servers" "GPU inference engines providing metrics for dispatch gates" "Internal llm-d"
        inferencePool = softwareSystem "InferencePool (Gateway API)" "Pod scaling metrics for budget computation" "Internal llm-d"

        promOperator = softwareSystem "Prometheus Operator" "Scrapes processor metrics via PodMonitor" "Platform"
        grafana = softwareSystem "Grafana" "Dashboards for async processor observability" "Platform"

        # Relationships
        datascientist -> producerModule "Submits batch inference requests" "Go API"
        sre -> grafana "Monitors processor metrics" "HTTPS"

        producerModule -> redis "Enqueues requests, retrieves results" "Redis/6379, Optional TLS"
        producerModule -> apiModule "Uses request/response types" "Go import"

        processor -> redis "ZPOPMIN requests, LPUSH results, quota, cancellation" "Redis/6379, Optional TLS"
        processor -> gcpPubSub "Subscriber.Receive, Publisher.Publish" "gRPC/443, TLS 1.2+"
        processor -> llmdRouter "POST /v1/completions (dispatched requests)" "HTTP(S), Optional mTLS"
        processor -> prometheus "PromQL queries for dispatch gates" "HTTP/9090"
        processor -> gcpMonitoring "Query num_undelivered_messages" "gRPC/443, TLS 1.2+"
        processor -> otlpCollector "Export distributed traces" "gRPC/4317, Optional TLS"
        processor -> pipelineModule "Implements Flow, Gate interfaces" "Go import"
        processor -> apiModule "Uses wire format types" "Go import"

        epp -> processor "Provides flow control metrics" "Prometheus metrics"
        vllm -> processor "Provides running/waiting request counts" "Prometheus metrics / HTTP scrape"
        inferencePool -> processor "Provides ready pod count" "Prometheus metrics"

        promOperator -> processor "Scrapes /metrics" "HTTP/9090"
        grafana -> prometheus "Queries processor metrics" "PromQL"
    }

    views {
        systemContext asyncProcessor "SystemContext" {
            include *
            autoLayout
        }

        container asyncProcessor "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

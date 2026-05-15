workspace {
    model {
        datascientist = person "Data Scientist / Client" "Sends inference requests to deployed LLM models"
        sre = person "SRE / Platform Admin" "Monitors inference pools, configures scheduling policies"

        llmdScheduler = softwareSystem "llm-d-inference-scheduler" "Intelligent request routing for LLM inference via Gateway API ext-proc" {
            epp = container "EPP (Endpoint Picker)" "Envoy ext-proc gRPC server; evaluates backends via Filter→Score→Pick pipeline with KV-cache, queue depth, prefix affinity, LoRA locality scoring" "Go 1.25, gRPC" {
                extProcServer = component "ext-proc Server" "Bidirectional gRPC streaming with Envoy for request/response processing" "gRPC 9002/TCP"
                schedulingFramework = component "Scheduling Framework" "Filter→Scorer→Picker pipeline with weighted scoring, DAG-ordered data producers" "Go Plugin Framework"
                flowControl = component "Flow Control Layer" "Priority-based admission, fairness (global-strict, round-robin), ordering (FCFS, EDF, SLO-deadline), eviction" "Go Concurrency"
                dataLayer = component "Data Layer" "Pluggable data source/extractor system: HTTP polling, ZMQ notifications, DAG ordering" "Go Data Pipeline"
                controllers = component "K8s Controllers" "Reconcilers for InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "controller-runtime v0.23.3"
                metricsEndpoint = component "Metrics Endpoint" "Prometheus metrics for pool, scheduling, flow control, token counts, SLO violations" "HTTP 9090/TCP"
                healthService = component "Health Service" "gRPC health with liveness (always serving) and readiness (pool synced + leader elected)" "gRPC 9003/TCP"
            }
            pdSidecar = container "PD Sidecar Proxy" "HTTP reverse proxy for disaggregated Prefill/Decode inference; NIXL v2, shared storage, SGLang protocols" "Go 1.25, HTTP" {
                proxyServer = component "Proxy Server" "OpenAI-compatible API server with P/D and E/P/D disaggregation" "HTTP/HTTPS 8000/TCP"
                nixlv2Connector = component "NIXL v2 Connector" "KV-cache transfer via RDMA for high-performance prefill/decode" "NIXL/RDMA"
                sharedStorageConnector = component "Shared Storage Connector" "KV-cache transfer via shared filesystem with try-decode-first optimization" "Shared FS"
                sglangConnector = component "SGLang Connector" "SGLang bootstrap coordination for data-parallel inference" "SGLang Protocol"
                ssrfProtection = component "SSRF Protection" "Validates routing targets against InferencePool pod membership" "IP Allowlist"
            }
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Kubernetes Gateway API implementation with ext-proc filter" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches, RBAC, pod lifecycle" "External"
        gatewayAPI = softwareSystem "Gateway API + GIE" "Gateway API v1.5.1 + Inference Extension v1.5.0 CRDs" "External"
        vllm = softwareSystem "vLLM / Model Servers" "LLM inference engines serving model predictions" "Internal Platform"
        kvCacheLib = softwareSystem "llm-d-kv-cache" "KV-cache block index library with ZMQ event notifications" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh for mTLS (optional, dev environments)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning (optional)" "External"

        datascientist -> llmdScheduler "Sends inference requests via Gateway"
        sre -> llmdScheduler "Configures InferencePool, InferenceObjective CRDs; monitors metrics"

        llmdScheduler -> envoyGateway "gRPC ext-proc bidirectional streaming (9002/TCP TLS)"
        llmdScheduler -> k8sAPI "Watch CRDs and Pods (HTTPS/443 SA token)"
        llmdScheduler -> vllm "Scrape metrics (HTTP/HTTPS), route requests, sidecar proxy"
        llmdScheduler -> kvCacheLib "ZMQ SUB for KV-cache block index updates (5557/TCP)"
        llmdScheduler -> otlpCollector "Export traces (gRPC/4317)"
        prometheus -> llmdScheduler "Scrape /metrics (HTTP/9090)"
        envoyGateway -> llmdScheduler "ext-proc request processing"

        llmdScheduler -> gatewayAPI "Consumes InferencePool, InferenceObjective, InferenceModelRewrite CRDs"
        llmdScheduler -> istio "Optional: mTLS, DestinationRules (dev environments)"
    }

    views {
        systemContext llmdScheduler "SystemContext" {
            include *
            autoLayout
        }

        container llmdScheduler "Containers" {
            include *
            autoLayout
        }

        component epp "EPP-Components" {
            include *
            autoLayout
        }

        component pdSidecar "PDSidecar-Components" {
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
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference services"
        sre = person "SRE / Platform Operator" "Monitors and manages the inference platform"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Intelligent inference request scheduler for LLM workloads via Envoy ext-proc" {
            epp = container "EPP (Endpoint Picker)" "Envoy ext-proc server that makes scheduling decisions via configurable filter/scorer/picker plugins" "Go gRPC Service" {
                extProcServer = component "ext-proc gRPC Server" "Bidirectional streaming ext-proc for request/response processing" "gRPC H2"
                schedulingPipeline = component "Scheduling Pipeline" "Filters, Scorers, Pickers chain for optimal endpoint selection" "Go Plugin Framework"
                flowControl = component "Flow Control Layer" "Multi-priority queuing with fairness, ordering, and admission control" "Go (Experimental)"
                crdReconcilers = component "CRD Reconcilers" "Watch InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "controller-runtime"
                metricsCollector = component "Metrics Collector" "Scrapes model server Prometheus metrics (queue depth, KV cache, running requests)" "Go HTTP Client"
                dataLayer = component "Data Layer" "DAG-based data producer/consumer framework for scheduling context" "Go"
            }
            pdSidecar = container "PD Sidecar Proxy" "Orchestrates disaggregated Prefill/Decode execution with pluggable KV transfer protocols" "Go HTTP Reverse Proxy"
            udsTokenizer = container "UDS Tokenizer" "Tokenization sidecar communicating over Unix Domain Socket" "Sidecar Container"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Data plane gateway with ext-proc filter for inference request routing" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration with CRDs for InferencePool, Pod management" "External"
        gatewayAPI = softwareSystem "Gateway API + GIE" "Gateway API v1.5.1 with Inference Extension v1.5.0 CRDs" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM model serving engine with Prometheus metrics and inference API" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export target" "External"
        llmdKVCache = softwareSystem "llm-d-kv-cache" "KV cache block indexer library for prefix cache scoring" "Internal Platform"

        // User interactions
        dataScientist -> llmdScheduler "Sends inference requests via Gateway" "HTTP/80"
        sre -> prometheus "Monitors scheduling metrics" "HTTP"

        // System interactions
        envoyGateway -> llmdScheduler "ext-proc callbacks for routing decisions" "gRPC/9002 TLS"
        llmdScheduler -> kubernetes "Watches CRDs (InferencePool, Pod, InferenceObjective)" "HTTPS/443"
        llmdScheduler -> vllm "Scrapes metrics + routes inference requests" "HTTP/3000, HTTP/8000"
        llmdScheduler -> otelCollector "Exports distributed traces" "gRPC/4317 OTLP"
        prometheus -> llmdScheduler "Scrapes EPP metrics" "HTTP/9090"
        llmdScheduler -> llmdKVCache "KV cache block index for prefix scoring" "Go library"

        // PD Sidecar interactions
        pdSidecar -> vllm "Routes to prefiller/decoder instances" "HTTP/HTTPS Dynamic"
        envoyGateway -> pdSidecar "Forwards disaggregated inference requests" "HTTP/HTTPS 8000"

        // Internal container interactions
        epp -> udsTokenizer "Tokenize prompts" "gRPC over UDS"
        epp -> pdSidecar "Routing headers injected via Envoy" "Indirect via Envoy"
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

        component epp "EPPComponents" {
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

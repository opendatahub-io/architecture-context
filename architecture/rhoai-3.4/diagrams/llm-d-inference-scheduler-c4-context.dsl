workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        sre = person "SRE / Platform Admin" "Monitors and manages the inference platform"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Optimized inference request scheduling and routing for the llm-d framework via Gateway API Inference Extension" {
            epp = container "Endpoint Picker Processor (EPP)" "Makes intelligent routing decisions for inference requests using pluggable filters, scorers, and profile handlers" "Go Service (ext-proc gRPC server)" {
                extProcServer = component "ext-proc gRPC Server" "Receives routing callbacks from Envoy and returns endpoint selections" "gRPC/9002"
                pluginSystem = component "Plugin System" "Filters, scorers, profile handlers for customizable routing" "Go Plugin Framework"
                kvCacheEngine = component "KV Cache Engine" "KV-Block Indexer and Prefix Store for cache-aware routing" "In-memory index"
                metricsEndpoint = component "Metrics Endpoint" "Exposes Prometheus metrics on 9090/TCP" "HTTP"
            }
            pdSidecar = container "P/D Routing Sidecar" "Orchestrates disaggregated prefill/decode inference with KV cache transfer coordination" "Go HTTP Reverse Proxy" {
                httpProxy = component "HTTP Reverse Proxy" "Proxies inference requests between prefill, decode, and encode stages" "HTTPS/8000"
                nixlv2Connector = component "NIXL v2 Connector" "Sequential prefill-then-decode KV transfer protocol" "Default"
                sharedStorageConnector = component "Shared Storage Connector" "Decode-first optimization with cache hit checking" "Optional"
                sglangConnector = component "SGLang Connector" "Concurrent prefill and decode for lower TTFT" "Optional"
                epdConnector = component "EPD Connector" "Encoder-Prefiller-Decoder for multimodal workloads" "Experimental"
                ssrfValidator = component "SSRF Allowlist Validator" "Validates prefill/encoder targets against InferencePool pod list" "Security"
            }
            udsTokenizer = container "UDS Tokenizer Sidecar" "Provides tokenization over Unix Domain Socket for prompt analysis" "External gRPC Service"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Kubernetes Gateway API implementation — routes traffic and sends ext-proc callbacks" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane — provides resource watching and RBAC" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM inference engines — prefill, decode, and encode workers" "External"
        gie = softwareSystem "Gateway API Inference Extension (GIE)" "Core scheduling framework (forked: red-hat-data-services)" "External Library"
        kvCacheLib = softwareSystem "llm-d-kv-cache" "KV cache indexing library for precise prefix cache scoring" "External Library"

        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor/PodMonitor" "Optional"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export via OTLP/gRPC" "Optional"
        huggingface = softwareSystem "HuggingFace Hub" "Tokenizer model downloads" "External"

        # Relationships
        dataScientist -> envoyGateway "Sends inference requests" "HTTP/80"
        sre -> prometheus "Monitors inference metrics"

        envoyGateway -> epp "Sends ext-proc routing callbacks" "gRPC/9002"
        envoyGateway -> pdSidecar "Routes requests to selected pods" "HTTPS/8000"

        epp -> k8sAPI "Watches InferencePool, Pod resources" "HTTPS/443, SA Token"
        epp -> vllm "Scrapes /v1/models for model metadata" "HTTP"
        epp -> vllm "Subscribes to KV cache events" "ZMQ SUB/5556"
        epp -> udsTokenizer "Tokenizes prompts for prefix cache" "gRPC/UDS"
        epp -> otelCollector "Exports traces" "gRPC/4317"
        epp -> huggingface "Downloads tokenizer models" "HTTPS/443"

        pdSidecar -> vllm "Sends prefill requests (remote)" "HTTP(S)"
        pdSidecar -> vllm "Sends decode requests (local)" "HTTP(S)/8001"
        pdSidecar -> vllm "Sends encode requests (EPD)" "HTTP(S)"
        pdSidecar -> k8sAPI "Watches InferencePool for SSRF allowlist" "HTTPS/443"
        pdSidecar -> otelCollector "Exports traces" "gRPC/4317"

        prometheus -> epp "Scrapes metrics" "HTTP/9090"

        # Library dependencies (compile-time)
        epp -> gie "Uses scheduling framework" "Go library"
        epp -> kvCacheLib "Uses KV cache indexing" "Go library"
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

        component pdSidecar "Sidecar-Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Library" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Optional" {
                background #cccccc
                color #333333
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

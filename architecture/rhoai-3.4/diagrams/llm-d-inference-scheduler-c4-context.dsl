workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and serves LLM models via InferencePool resources"
        client = person "API Client" "Sends inference requests (chat/completions) to served models"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Optimized inference request scheduler and routing sidecar for the llm-d disaggregated LLM serving framework" {
            epp = container "EPP (Endpoint Picker)" "Scheduling control plane — makes per-request routing decisions using pluggable filters, scorers, and profile handlers via Envoy ext-proc" "Go Service, gRPC ext-proc" {
                filterChain = component "Filter Chain" "by-label, by-label-selector, decode-filter, roles-filter" "Go Plugins"
                scorerChain = component "Scorer Chain" "prefix-cache, session-affinity, load-aware, active-request, no-hit-LRU" "Go Plugins"
                profileHandler = component "Profile Handler" "disagg-profile, pd-profile, dp-profile handlers" "Go Plugins"
                kvEventProcessor = component "KV Event Processor" "Processes ZMQ KV-cache events for prefix cache scoring" "ZMQ Subscriber"
            }
            sidecar = container "Routing Sidecar (pd-sidecar)" "Runtime sidecar for disaggregated inference orchestration — coordinates Prefill, Decode, and Encode stages with KV cache transfer" "Go Service, HTTP Reverse Proxy" {
                nixlConnector = component "NIXL v2 Connector" "Sequential prefill-then-decode with kv_transfer_params" "Go"
                sharedStorageConnector = component "Shared Storage Connector" "Optimistic decode-first with cache_hit_threshold" "Go"
                sglangConnector = component "SGLang Connector" "Concurrent prefill and decode with bootstrap coordination" "Go"
                ssrfProtection = component "SSRF Protection" "InferencePool-based pod IP allowlist" "Go, K8s Informers"
            }
            tokenizer = container "UDS Tokenizer" "Tokenization service communicating via Unix Domain Socket for precise token count computation" "Sidecar Container"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Data plane gateway with ext-proc filter support (Gateway API implementation)" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes API for CRD watches and pod discovery" "HTTPS/443"
        }
        vllm = softwareSystem "vLLM" "Model serving engine with KV-cache event emission" "External" {
            decoderPod = container "Decoder Pod" "Local decode-stage model server" "HTTP/8001"
            prefillerPod = container "Prefiller Pod" "Remote prefill-stage model server" "HTTP(S)/varies"
            encoderPod = container "Encoder Pod" "Remote encode-stage model server (multimodal)" "HTTP(S)/varies"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry distributed tracing" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs (Gateway, HTTPRoute, InferencePool)" "External"

        # Relationships - External
        client -> envoyGateway "Sends inference requests" "HTTP/80"
        datascientist -> kubernetes "Creates InferencePool CRs" "kubectl/HTTPS"

        # Relationships - Envoy to llm-d
        envoyGateway -> epp "ext-proc callback (request headers)" "gRPC/9002"
        envoyGateway -> sidecar "Routed inference requests" "HTTP(S)/8000"
        epp -> envoyGateway "Routing decision (selected endpoint)" "gRPC/9002"

        # Relationships - EPP internals
        epp -> kubernetes "Watch InferencePool CRs, Pods" "HTTPS/443, SA Token"
        epp -> vllm "Subscribe KV-cache events" "ZMQ/5556"
        epp -> vllm "Query model metadata" "HTTP/varies"
        epp -> tokenizer "Tokenize prompts" "Unix Socket"

        # Relationships - Sidecar
        sidecar -> decoderPod "Forward decode requests" "HTTP/8001"
        sidecar -> prefillerPod "Forward prefill requests" "HTTP(S)/varies"
        sidecar -> encoderPod "Forward encode requests (multimodal)" "HTTP(S)/varies"
        sidecar -> kubernetes "Watch InferencePool for SSRF allowlist" "HTTPS/443, SA Token"

        # Relationships - Observability
        prometheus -> epp "Scrape metrics" "HTTP/9090"
        epp -> otlpCollector "Export traces" "gRPC/4317"
        sidecar -> otlpCollector "Export traces" "gRPC/4317"
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

        component sidecar "Sidecar-Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
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

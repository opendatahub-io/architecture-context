workspace {
    model {
        datascientist = person "Data Scientist / Application" "Sends LLM inference requests via OpenAI-compatible API"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar that orchestrates prefill/decode disaggregated inference by routing requests between prefiller and decoder vLLM instances" {
            tlsProxy = container "TLS Reverse Proxy" "Accepts incoming HTTPS requests on port 8000, routes to appropriate handler" "Go net/http"
            chatHandler = container "Chat Completions Handler" "Processes /v1/chat/completions requests with P/D routing logic" "Go HTTP Handler"
            completionsHandler = container "Completions Handler" "Processes /v1/completions requests with P/D routing logic" "Go HTTP Handler"
            nixlv2Connector = container "NIXL v2 Connector" "Implements two-phase P/D protocol: prefill with max_tokens=1, then decode with KV metadata" "Go"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRDs and pods to maintain SSRF protection allowlist" "Go Kubernetes Informer"
            lruCache = container "LRU Proxy Cache" "Caches reverse proxy instances for prefiller targets (capacity: 16)" "hashicorp/golang-lru"
            decoderProxy = container "Decoder Reverse Proxy" "Static reverse proxy to localhost decoder" "Go httputil.ReverseProxy"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM instance for token generation (decode phase)" "Internal - Same Pod"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote vLLM instances for KV-cache prefilling (prefill phase)" "Internal - Remote Pods"
        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Inference endpoint picker that selects prefiller targets and sets x-prefiller-host-port header" "Internal llm-d"
        k8sApi = softwareSystem "Kubernetes API Server" "Provides watch streams for InferencePool and Pod resources" "External"
        inferencePool = softwareSystem "InferencePool CRD" "Gateway API Inference Extension CRD defining pool label selectors" "External - inference.networking.x-k8s.io"
        gatewayApi = softwareSystem "Gateway API Inference Extension" "Defines InferencePool CRD schema used for SSRF protection" "External"

        # Relationships
        datascientist -> routingSidecar "Sends OpenAI-compatible completion requests" "HTTPS/8000 TLS 1.2+"
        epp -> routingSidecar "Sets x-prefiller-host-port header on routed requests" "HTTP Header"

        routingSidecar -> vllmDecoder "Forwards all requests (completions and passthrough)" "HTTP(S)/8001"
        routingSidecar -> vllmPrefiller "Forwards prefill phase requests with max_tokens=1" "HTTP(S)/varies"
        routingSidecar -> k8sApi "Watches InferencePool and Pod resources for SSRF allowlist" "HTTPS/443 ServiceAccount token"

        # Internal relationships
        tlsProxy -> chatHandler "Routes /v1/chat/completions"
        tlsProxy -> completionsHandler "Routes /v1/completions"
        tlsProxy -> decoderProxy "Routes catch-all /* passthrough"
        chatHandler -> allowlistValidator "Validates prefiller target"
        chatHandler -> nixlv2Connector "P/D routing"
        nixlv2Connector -> lruCache "Gets/creates prefiller proxy"
        nixlv2Connector -> decoderProxy "Forwards with KV metadata"
        allowlistValidator -> k8sApi "Watch streams" "HTTPS/443"
    }

    views {
        systemContext routingSidecar "SystemContext" {
            include *
            autoLayout
        }

        container routingSidecar "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal - Same Pod" {
                background #7ed321
                color #ffffff
            }
            element "Internal - Remote Pods" {
                background #7ed321
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - inference.networking.x-k8s.io" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

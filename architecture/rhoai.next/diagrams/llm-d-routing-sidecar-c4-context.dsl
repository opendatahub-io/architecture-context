workspace {
    model {
        client = person "Client Application" "Sends OpenAI-compatible completion requests to the inference endpoint"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar that orchestrates prefill/decode disaggregated LLM inference" {
            tlsServer = container "TLS Server" "Accepts HTTPS requests on port 8000 with TLS 1.2+" "Go net/http"
            chatHandler = container "Chat Completions Handler" "Routes /v1/chat/completions with P/D logic" "Go HTTP Handler"
            connectorNIXLv2 = container "NIXL v2 Connector" "Implements prefill/decode coordination protocol" "Go"
            prefillerProxyCache = container "Prefiller Proxy LRU Cache" "Caches reverse proxy instances for prefiller targets (capacity: 16)" "hashicorp/golang-lru"
            decoderProxy = container "Decoder Reverse Proxy" "Static reverse proxy to localhost decoder" "Go httputil.ReverseProxy"
            allowlistValidator = container "Allowlist Validator" "Watches InferencePool CRDs and pods for SSRF protection" "Go Kubernetes Informer"
        }

        decoderVLLM = softwareSystem "vLLM Decoder" "Local vLLM instance for token generation (decode phase), co-located in same pod" "Internal"
        prefillerVLLM = softwareSystem "vLLM Prefiller" "Remote vLLM instances for KV-cache prefilling (prefill phase)" "Internal"
        inferenceScheduler = softwareSystem "llm-d-inference-scheduler (EPP)" "Endpoint Picker that selects prefiller targets and sets x-prefiller-host-port header" "Internal llm-d"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch streams for InferencePool and Pod resources" "Platform"
        inferencePoolCRD = softwareSystem "Gateway API Inference Extension" "Defines InferencePool CRD (inference.networking.x-k8s.io/v1alpha2)" "Platform"

        # External relationships
        client -> routingSidecar "Sends completion requests" "HTTPS/8000 TLS 1.2+"
        inferenceScheduler -> routingSidecar "Sets x-prefiller-host-port header on requests" "HTTP Header"

        # Internal container relationships
        tlsServer -> chatHandler "Routes /v1/chat/completions and /v1/completions"
        chatHandler -> connectorNIXLv2 "Delegates P/D routing when prefill header present"
        chatHandler -> decoderProxy "Direct forward when no prefill header"
        connectorNIXLv2 -> allowlistValidator "Validates prefiller target IP"
        connectorNIXLv2 -> prefillerProxyCache "Gets/creates prefiller reverse proxy"
        connectorNIXLv2 -> decoderProxy "Forwards with KV transfer metadata"

        # External system relationships
        routingSidecar -> decoderVLLM "Forwards requests to local decoder" "HTTP(S)/8001"
        routingSidecar -> prefillerVLLM "Forwards prefill requests to remote prefillers" "HTTP(S)/varies"
        routingSidecar -> k8sAPI "Watches InferencePool and Pod resources" "HTTPS/443 SA Token"
        k8sAPI -> inferencePoolCRD "Serves InferencePool CRD"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Internal llm-d" {
                background #4a90e2
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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

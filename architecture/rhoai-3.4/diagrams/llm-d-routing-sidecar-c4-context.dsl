workspace {
    model {
        client = person "Client / Upstream Gateway" "Sends OpenAI-compatible inference requests (chat completions, completions)"

        sidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar implementing disaggregated prefill/decode routing for LLM inference" {
            proxyListener = container "Proxy Listener" "HTTPS listener on port 8000 with TLS 1.2+ and AEAD cipher suites" "Go HTTP Server"
            nixlv2 = container "NIXL v2 Connector" "Two-phase prefill/decode orchestration with kv_transfer_params exchange" "Go Protocol Handler"
            allowlistValidator = container "AllowlistValidator" "SSRF protection via InferencePool pod IP allowlist" "Go K8s Informer"
            lruCache = container "LRU Cache" "Caches prefiller reverse proxy handlers (capacity: 16)" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Local LLM decoder instance for token generation" "Runtime Dependency"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote prefiller pods for KV-cache prefilling" "Runtime Dependency"
        k8sAPI = softwareSystem "Kubernetes API Server" "Control plane API for watching InferencePool CRs and Pods" "Platform"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API inference extension CRD defining pod selectors for prefill targets" "Platform CRD"

        # User interactions
        client -> sidecar "POST /v1/chat/completions, /v1/completions" "HTTPS/8000, TLS 1.2+"

        # Internal container interactions
        proxyListener -> nixlv2 "Routes P/D requests (x-prefiller-host-port header)" "Internal"
        nixlv2 -> allowlistValidator "Validates prefiller IP" "Internal"
        nixlv2 -> lruCache "Caches/retrieves proxy handlers" "Internal"

        # External interactions
        nixlv2 -> vllmPrefiller "Phase 1: Prefill request with kv_transfer_params" "HTTP(S), TLS 1.2+ configurable"
        nixlv2 -> vllmDecoder "Phase 2: Decode with kv_transfer_params from prefiller" "HTTP(S)/8001, TLS 1.2+ configurable"
        proxyListener -> vllmDecoder "Direct passthrough (no P/D header)" "HTTP(S)/8001"
        allowlistValidator -> k8sAPI "Watch InferencePool + Pods" "HTTPS/443, ServiceAccount token"
        k8sAPI -> inferencePool "Serves InferencePool resources" "API"
    }

    views {
        systemContext sidecar "SystemContext" {
            include *
            autoLayout
        }

        container sidecar "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Runtime Dependency" {
                background #9b59b6
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Platform CRD" {
                background #999999
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

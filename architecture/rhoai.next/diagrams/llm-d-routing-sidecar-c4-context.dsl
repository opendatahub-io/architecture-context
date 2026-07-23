workspace {
    model {
        client = person "API Client" "Sends inference requests (OpenAI-compatible /v1/chat/completions, /v1/completions)"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP/HTTPS reverse proxy sidecar that routes disaggregated prefill/decode requests between vLLM workers using NIXL v2 protocol" {
            proxy = container "Reverse Proxy" "Intercepts inference requests, orchestrates two-phase prefill-then-decode flow" "Go net/http/httputil.ReverseProxy" "8000/TCP"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRs and tracks pod IPs for SSRF protection" "Go Kubernetes Informer" "Optional"
            connectorNIXLv2 = container "NIXL v2 Connector" "Primary protocol for KV cache transfer metadata exchange" "Go"
            lruCache = container "LRU Cache" "Caches prefiller proxy handler instances (capacity 16)" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder (Local)" "Co-located vLLM instance for inference decode stage" "Internal"
        vllmPrefiller = softwareSystem "vLLM Prefiller (Remote)" "Remote vLLM prefiller pods for KV cache prefill stage" "Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides CRD and Pod watches for SSRF allowlist" "External"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD defining pod selectors for routing pools" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external ingress via Route with edge TLS termination" "External"

        # Relationships
        client -> openshiftRouter "Sends inference requests" "HTTPS/443"
        openshiftRouter -> routingSidecar "Forwards requests (TLS terminated)" "HTTP/8080"
        client -> routingSidecar "Sends inference requests (direct)" "HTTPS/8000"

        routingSidecar -> vllmDecoder "Forwards decode requests" "HTTP or HTTPS/8001"
        routingSidecar -> vllmPrefiller "Forwards prefill requests (when x-prefiller-host-port header present)" "HTTP or HTTPS/header-specified"
        routingSidecar -> k8sAPI "Watches InferencePool and Pod resources (when SSRF enabled)" "HTTPS/443"

        # Internal relationships
        proxy -> allowlistValidator "Validates prefill target IP" "in-process"
        proxy -> connectorNIXLv2 "Orchestrates P/D protocol" "in-process"
        proxy -> lruCache "Caches prefiller handlers" "in-process"
        allowlistValidator -> k8sAPI "Dynamic informer watches" "HTTPS/443 ServiceAccount token"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

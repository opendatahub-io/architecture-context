workspace {
    model {
        client = person "API Client" "Sends OpenAI-compatible inference requests"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar orchestrating disaggregated prefill/decode for LLM inference" {
            proxyServer = container "Proxy Server" "HTTP reverse proxy serving TLS on port 8000, routes requests based on x-prefiller-host-port header" "Go HTTP Server"
            chatHandler = container "Chat Completions Handler" "Processes /v1/chat/completions and /v1/completions requests, dispatches to connector" "Go HTTP Handler"
            nixlv2Connector = container "NIXL V2 Connector" "Implements two-phase prefill/decode: clones request for prefill (max_tokens=1), extracts kv_transfer_params, constructs decode request" "Go"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRDs and matching pods via Kubernetes informers to maintain SSRF allowlist of valid prefiller IPs" "Go Informer Controller"
            lruCache = container "LRU Cache" "Caches prefiller reverse proxy handlers (16 entries) to avoid recreating transports" "hashicorp/golang-lru"
            bufferedWriter = container "bufferedResponseWriter" "Captures prefiller HTTP responses in memory for JSON parsing before constructing decode requests" "Go"
        }

        decoder = softwareSystem "vLLM Decoder" "Co-located vLLM instance performing decode phase of inference" "Internal"
        prefiller = softwareSystem "vLLM Prefiller" "Remote vLLM instances performing prefill phase (KV-cache population)" "Internal"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server providing watch streams for InferencePool and Pod resources" "Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external ingress via Route with edge TLS termination" "Platform"

        client -> openshiftRouter "Sends inference requests" "HTTPS/443"
        openshiftRouter -> routingSidecar "Forwards to sidecar service" "HTTPS/8080"
        routingSidecar -> prefiller "Forwards prefill requests (max_tokens=1)" "HTTP(S)/configurable"
        routingSidecar -> decoder "Forwards decode requests with kv_transfer_params" "HTTP(S)/8001"
        routingSidecar -> k8sAPI "Watches InferencePool and Pod resources for SSRF allowlist" "HTTPS/6443"

        proxyServer -> chatHandler "Routes /v1/ requests"
        chatHandler -> allowlistValidator "Validates prefiller target IP"
        chatHandler -> nixlv2Connector "Dispatches disaggregated request"
        nixlv2Connector -> lruCache "Gets/creates prefiller proxy"
        nixlv2Connector -> bufferedWriter "Captures prefiller response"
        allowlistValidator -> k8sAPI "Watches InferencePool + Pods" "HTTPS/6443"
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
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

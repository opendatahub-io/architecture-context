workspace {
    model {
        client = person "Client / Inference Gateway" "Sends OpenAI-compatible completion requests"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar enabling disaggregated prefill/decode serving for LLM inference" {
            proxyServer = container "Proxy Server" "TLS-enabled reverse proxy listening on port 8000, routes completion requests through P/D protocol" "Go net/http"
            nixlv2Connector = container "NIXL v2 Connector" "Two-phase prefill/decode protocol: sends prefill request, captures kv_transfer_params, forwards decode request" "Go"
            lruCache = container "LRU Proxy Cache" "Caches up to 16 httputil.ReverseProxy instances keyed by host:port for prefill targets" "golang-lru"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CR and matching pods via dynamic informers, maintains SSRF protection allowlist" "Go client-go"
            tlsManager = container "TLS Manager" "Manages TLS certificates: loads from cert-path or generates self-signed 4096-bit RSA fallback" "Go crypto/tls"
        }

        localDecoder = softwareSystem "Local vLLM Decoder" "Co-located vLLM instance performing token decoding after prefill phase" "Co-located"
        remotePrefiller = softwareSystem "Remote vLLM Prefiller" "Remote vLLM instance(s) performing prompt prefill and KV cache population" "Remote"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for watching InferencePool and Pod resources" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "External traffic ingress with TLS edge termination" "External"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension custom resource providing pod selector for SSRF allowlist" "External"

        client -> routingSidecar "Sends completion requests via OpenAI-compatible API" "HTTPS/8000 TLS 1.2+"
        openshiftRouter -> routingSidecar "Routes external traffic" "HTTPS/8080 Edge TLS"
        routingSidecar -> localDecoder "Forwards decode requests" "HTTP or HTTPS/8001"
        routingSidecar -> remotePrefiller "Forwards prefill requests" "HTTP or HTTPS/per-request"
        routingSidecar -> k8sAPI "Watches InferencePool and Pods for SSRF allowlist" "HTTPS/6443 SA Token"

        proxyServer -> nixlv2Connector "Dispatches P/D requests"
        proxyServer -> allowlistValidator "Validates prefill targets"
        nixlv2Connector -> lruCache "Gets cached proxy for prefill target"
        proxyServer -> tlsManager "Loads TLS configuration"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Co-located" {
                background #7ed321
                color #ffffff
            }
            element "Remote" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
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

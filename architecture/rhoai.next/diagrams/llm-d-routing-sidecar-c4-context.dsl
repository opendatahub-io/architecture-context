workspace {
    model {
        client = person "Client Application" "Sends LLM inference requests via OpenAI-compatible API"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar routing inference requests between prefill and decode workers in disaggregated P/D architecture" {
            proxyServer = container "Proxy Server" "HTTP ServeMux with TLS 1.2+, routes /v1/chat/completions and /v1/completions" "Go HTTP Server"
            connectors = container "Connector Protocols" "NIXL v2 (current), NIXL v1 (deprecated), LMCache (deprecated) - manages two-phase prefill/decode" "Go Library"
            allowlistValidator = container "AllowlistValidator" "SSRF protection via InferencePool-based pod allowlisting with Kubernetes informers" "Go Library"
            proxyCache = container "Prefiller Proxy Cache" "16-entry LRU cache for prefiller reverse proxy handlers" "Go Library"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM instance receiving decode requests with KV transfer parameters" "Internal"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote prefill workers receiving prefill-only requests" "Internal"
        kubernetesAPI = softwareSystem "Kubernetes API" "Provides InferencePool and Pod watch events for SSRF allowlist" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external Route with TLS edge termination" "External"
        inferencePool = softwareSystem "Gateway API InferencePool" "CRD defining valid prefill target pod selectors" "External"

        # Relationships
        client -> routingSidecar "POST /v1/chat/completions, /v1/completions" "HTTPS/8000 TLS 1.2+"
        client -> openshiftRouter "HTTPS requests" "HTTPS/443"
        openshiftRouter -> routingSidecar "Forwards traffic" "TCP/8080 TLS Edge"

        proxyServer -> connectors "Dispatches to protocol handler"
        proxyServer -> allowlistValidator "Validates prefiller host"
        connectors -> proxyCache "Gets/creates prefiller proxy"

        routingSidecar -> vllmDecoder "Decode requests with KV transfer params" "HTTP(S)/8001"
        routingSidecar -> vllmPrefiller "Prefill-only requests" "HTTP(S)/per-header-port"
        allowlistValidator -> kubernetesAPI "Watches InferencePool and Pods" "HTTPS/6443 ServiceAccount token"
        inferencePool -> kubernetesAPI "Stored as CR"
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
            element "Internal" {
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
        }
    }
}

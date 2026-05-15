workspace {
    model {
        client = person "Client / API Consumer" "Sends OpenAI-compatible inference requests to the LLM serving endpoint"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar that implements disaggregated prefill/decode (P/D) routing for vLLM inference workloads" {
            proxyServer = container "Proxy Server" "HTTPS reverse proxy listener on port 8000 with TLS 1.2+ and FIPS cipher suites" "Go net/http"
            nixlv2Connector = container "NIXL v2 Connector" "Implements disaggregated P/D protocol: extracts kv_transfer_params (block_ids, engine_id, host, port) from prefill response" "Go"
            allowlistValidator = container "AllowlistValidator" "SSRF protection: watches InferencePool CRs and builds pod IP/hostname allowlist via Kubernetes dynamic client" "Go k8s.io/client-go"
            lruCache = container "LRU Proxy Cache" "Caches reverse proxy handler instances for prefiller connections" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder (Local)" "Co-located vLLM instance that handles token generation/decode phase" "Internal"
        vllmPrefiller = softwareSystem "vLLM Prefiller Pods" "Remote vLLM instances that handle KV cache prefill phase, addressed via x-prefiller-host-port header" "Internal"
        inferenceScheduler = softwareSystem "llm-d-inference-scheduler" "Upstream router that determines prefiller assignment and sets x-prefiller-host-port header" "Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch streams for InferencePool CRs and Pods" "External"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API inference extension CRD defining pool of inference pods with label selectors" "External"
        openShiftRoute = softwareSystem "OpenShift Route" "Edge TLS termination ingress for external access" "External"

        # Relationships
        client -> openShiftRoute "Sends inference requests" "HTTPS/443"
        openShiftRoute -> routingSidecar "Forwards after TLS termination" "HTTP/8080 → HTTPS/8000"
        inferenceScheduler -> client "Sets x-prefiller-host-port header" "HTTP Header"

        # Internal container relationships
        proxyServer -> nixlv2Connector "Routes P/D requests" "Internal"
        proxyServer -> allowlistValidator "Validates prefiller host" "Internal"
        nixlv2Connector -> lruCache "Gets/caches proxy handlers" "Internal"

        # External relationships
        routingSidecar -> vllmDecoder "Forwards decode requests" "HTTP(S)/8001"
        routingSidecar -> vllmPrefiller "Forwards prefill requests" "HTTP(S)/dynamic"
        allowlistValidator -> k8sAPI "Watches InferencePool and Pods" "HTTPS/443 SA Token"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
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

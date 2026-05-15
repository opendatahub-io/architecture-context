workspace {
    model {
        scheduler = person "llm-d-inference-scheduler (EPP)" "Routes inference requests to appropriate decoder pods, sets x-prefiller-host-port header for disaggregated P/D"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar that routes LLM inference requests between prefill and decode workers in disaggregated P/D architecture" {
            proxy = container "HTTP Reverse Proxy" "Intercepts OpenAI-compatible requests on port 8000 and orchestrates P/D protocol" "Go net/http"
            nixlv2Connector = container "NIXL V2 Connector" "Implements two-phase prefill/decode protocol with kv_transfer_params exchange" "Go"
            nixlv1Connector = container "NIXL V1 Connector (deprecated)" "Legacy protocol with individual field exchange" "Go"
            lmcacheConnector = container "LMCache Connector (deprecated)" "Legacy LMCache protocol" "Go"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRs and pods to build SSRF protection allowlist" "Go · Kubernetes dynamic client"
            lruCache = container "LRU Cache" "Caches prefiller reverse proxy handlers" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Local vLLM decoder instance running in the same pod, serves token generation" "Internal"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote vLLM prefill workers that compute KV cache blocks" "Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch API for InferencePool and Pod resources" "External"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API CRD defining valid inference worker pools" "External"

        # Relationships
        scheduler -> routingSidecar "Sends OpenAI-compatible requests with x-prefiller-host-port header" "HTTPS/8000 · TLS 1.2+"
        routingSidecar -> vllmDecoder "Forwards decode requests with KV cache params" "HTTP(S)/8001 · localhost"
        routingSidecar -> vllmPrefiller "Sends prefill requests, receives kv_transfer_params" "HTTP(S)/configurable · Optional TLS"
        routingSidecar -> k8sAPI "Watches InferencePool and Pod resources for SSRF allowlist" "HTTPS/443 · ServiceAccount token"
        k8sAPI -> inferencePool "Serves InferencePool CRs" "inference.networking.x-k8s.io/v1alpha2"

        # Internal container relationships
        proxy -> nixlv2Connector "Routes completion requests through default connector"
        proxy -> nixlv1Connector "Routes via legacy connector (if configured)"
        proxy -> lmcacheConnector "Routes via LMCache connector (if configured)"
        proxy -> allowlistValidator "Validates prefill targets before forwarding"
        nixlv2Connector -> lruCache "Caches prefiller proxy handlers"
        allowlistValidator -> k8sAPI "Watches InferencePool and Pod resources" "HTTPS/443"
    }

    views {
        systemContext routingSidecar "SystemContext" {
            include *
            autoLayout
            description "System context diagram for llm-d-routing-sidecar showing its role in the disaggregated P/D inference stack"
        }

        container routingSidecar "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of the routing sidecar"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #3498db
                color #ffffff
                shape Person
            }
            element "Container" {
                background #6c5ce7
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
        }
    }
}

workspace {
    model {
        user = person "ML Application Client" "Sends OpenAI-compatible inference requests to LLM serving endpoints"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar that orchestrates prefill/decode disaggregation for LLM inference" {
            proxy = container "Reverse Proxy Server" "HTTP/HTTPS reverse proxy intercepting inference requests and orchestrating P/D protocol" "Go HTTP Server, TLS 1.2+"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRs and pods to maintain SSRF protection allowlist" "Go Kubernetes Watcher"
            nixlv2Connector = container "NIXL v2 Connector" "Implements current P/D disaggregation protocol with kv_transfer_params envelope" "Go Protocol Handler"
            nixlv1Connector = container "NIXL v1 Connector" "Deprecated P/D protocol with top-level transfer fields" "Go Protocol Handler"
            lmcacheConnector = container "LMCache Connector" "Deprecated P/D protocol using max_tokens=1 and shared cache" "Go Protocol Handler"
            lruCache = container "LRU Cache" "Caches prefiller reverse proxy handlers (capacity 16)" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Local vLLM instance performing decode phase of inference" "Co-located"
        vllmPrefillers = softwareSystem "vLLM Prefiller(s)" "Remote vLLM instances performing prefill phase and KV cache computation" "Cluster Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch APIs for InferencePool and Pod resources" "Platform"
        inferencePool = softwareSystem "Gateway API Inference Extension" "Defines InferencePool CRD (inference.networking.x-k8s.io/v1alpha2) for routing" "External CRD"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides Route-based ingress with edge TLS termination" "Platform"

        # Relationships
        user -> routingSidecar "POST /v1/chat/completions, /v1/completions" "HTTPS/443 via Route"
        openshiftRouter -> routingSidecar "Forwards traffic after TLS termination" "HTTP/8080"

        routingSidecar -> vllmDecoder "Forwards enriched decode requests" "HTTP(S)/8001"
        routingSidecar -> vllmPrefillers "Sends prefill requests, receives kv_transfer_params" "HTTP(S)/dynamic port"
        routingSidecar -> k8sAPI "Watches InferencePool and Pod resources for SSRF protection" "HTTPS/443, ServiceAccount token"

        # Internal container relationships
        proxy -> allowlistValidator "Validates prefill target against allowlist" "in-process"
        proxy -> nixlv2Connector "Dispatches NIXL v2 protocol requests" "in-process"
        proxy -> nixlv1Connector "Dispatches NIXL v1 protocol requests (deprecated)" "in-process"
        proxy -> lmcacheConnector "Dispatches LMCache protocol requests (deprecated)" "in-process"
        nixlv2Connector -> lruCache "Caches prefiller proxy handlers" "in-process"
        allowlistValidator -> k8sAPI "Watch InferencePool, Pods" "HTTPS/443"

        inferencePool -> k8sAPI "Registered CRD" ""
    }

    views {
        systemContext routingSidecar "SystemContext" {
            include *
            autoLayout
            description "System context for llm-d-routing-sidecar showing external interactions"
        }

        container routingSidecar "Containers" {
            include *
            autoLayout
            description "Internal structure of the routing sidecar"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Co-located" {
                background #7ed321
                color #ffffff
            }
            element "Cluster Internal" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "External CRD" {
                background #f5a623
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

workspace {
    model {
        client = person "LLM Client" "Application sending inference requests via OpenAI-compatible API"
        platformAdmin = person "Platform Admin" "Manages InferencePool resources and SSRF protection configuration"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar enabling disaggregated prefill/decode inference with SSRF protection" {
            proxy = container "HTTP Reverse Proxy" "Intercepts inference requests, orchestrates P/D flow" "Go net/http + httputil.ReverseProxy" {
                chatHandler = component "Chat Completions Handler" "Handles /v1/chat/completions with P/D interception" "Go HTTP Handler"
                completionsHandler = component "Completions Handler" "Handles /v1/completions with P/D interception" "Go HTTP Handler"
                passthroughHandler = component "Passthrough Handler" "Forwards all other requests to decoder" "Go HTTP Handler"
                healthHandler = component "Health Check" "Returns HTTP 200 at /health" "Go HTTP Handler"
            }
            connectors = container "Connector Protocols" "Protocol adapters for KV cache transfer metadata" "Go" {
                nixlv2 = component "NIXLv2 Connector" "Current/recommended protocol for kv_transfer_params" "Go"
                nixlv1 = component "NIXLv1 Connector" "Deprecated protocol with individual KV fields" "Go"
                lmcache = component "LMCache Connector" "Deprecated protocol, max_tokens=1 prefill warming" "Go"
            }
            allowlistValidator = container "AllowlistValidator" "SSRF protection via InferencePool-based pod IP allowlisting" "Go Kubernetes Dynamic Informers"
            lruCache = container "LRU Cache" "Caches prefiller reverse proxy handler instances (capacity 16)" "hashicorp/golang-lru/v2"
            tlsManager = container "TLS Manager" "Manages server and client TLS configurations with FIPS-compatible ciphers" "Go crypto/tls"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Local vLLM instance for token generation (decode stage), runs in same pod" {
            tags "Internal"
        }

        vllmPrefiller = softwareSystem "vLLM Prefiller Pods" "Remote GPU workers executing the prefill stage of LLM inference" {
            tags "Internal"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Provides access to InferencePool CRs and Pod resources" {
            tags "External"
        }

        gatewayEPP = softwareSystem "Gateway API Inference Extension (EPP)" "Endpoint Picker that routes requests and sets x-prefiller-host-port header" {
            tags "Internal"
        }

        inferencePoolCRD = softwareSystem "InferencePool CRD" "Custom Resource defined by Gateway API Inference Extension (inference.networking.x-k8s.io/v1alpha2)" {
            tags "External"
        }

        # Relationships
        client -> routingSidecar "Sends OpenAI-compatible inference requests" "HTTPS/8000 TLS 1.2+"
        gatewayEPP -> routingSidecar "Routes requests with x-prefiller-host-port header" "HTTP/HTTPS"
        routingSidecar -> vllmDecoder "Forwards modified requests with KV transfer params or passthrough" "HTTP or HTTPS/8001"
        routingSidecar -> vllmPrefiller "Sends prefill-stage requests" "HTTP or HTTPS/varies"
        vllmPrefiller -> routingSidecar "Returns kv_transfer_params metadata" "HTTP or HTTPS"
        routingSidecar -> k8sAPI "Watches InferencePool CRs and Pods for SSRF allowlist" "HTTPS/443 ServiceAccount Token"
        k8sAPI -> inferencePoolCRD "Serves InferencePool resources" "HTTPS"
        platformAdmin -> k8sAPI "Creates/manages InferencePool resources" "kubectl"

        # Internal relationships
        proxy -> connectors "Selects protocol based on -connector flag"
        proxy -> allowlistValidator "Validates prefiller target host"
        proxy -> lruCache "Caches/retrieves prefiller proxy handlers"
        proxy -> tlsManager "Configures TLS for server and clients"
        allowlistValidator -> k8sAPI "Watches InferencePool + Pods (30s resync)" "HTTPS/443"
    }

    views {
        systemContext routingSidecar "SystemContext" {
            include *
            autoLayout
            description "System context showing llm-d-routing-sidecar in the disaggregated P/D inference ecosystem"
        }

        container routingSidecar "Containers" {
            include *
            autoLayout
            description "Container view showing internal structure of the routing sidecar"
        }

        component proxy "ProxyComponents" {
            include *
            autoLayout
            description "Component view of the HTTP proxy handlers"
        }

        component connectors "ConnectorComponents" {
            include *
            autoLayout
            description "Component view of the connector protocol adapters"
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

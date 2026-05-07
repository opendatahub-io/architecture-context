workspace {
    model {
        client = person "Client / Gateway" "Sends OpenAI-compatible inference requests via Gateway API Inference Extension (EPP)"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar that orchestrates disaggregated prefill/decode (P/D) inference" {
            proxyServer = container "Proxy Server" "HTTP/TLS server listening on port 8000; routes requests to handlers" "Go HTTP Server"
            chatHandler = container "Chat Completions Handler" "Intercepts /v1/chat/completions for P/D disaggregation" "Go Handler"
            compHandler = container "Completions Handler" "Intercepts /v1/completions for P/D disaggregation" "Go Handler"
            nixlv2Connector = container "NIXL v2 Connector" "Current P/D protocol using kv_transfer_params for KV cache metadata" "Go Protocol Handler"
            nixlv1Connector = container "NIXL v1 Connector" "Deprecated P/D protocol using flat fields" "Go Protocol Handler (deprecated)"
            lmcacheConnector = container "LMCache Connector" "Deprecated LMCache P/D protocol" "Go Protocol Handler (deprecated)"
            allowlistValidator = container "Allowlist Validator" "SSRF protection via InferencePool-based pod allowlist" "Go / K8s Dynamic Client"
            proxyCache = container "Prefiller Proxy Cache" "LRU cache of up to 16 httputil.ReverseProxy instances" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Local vLLM instance co-located in same pod; generates tokens" "Internal - Co-located"
        vllmPrefillers = softwareSystem "vLLM Prefiller Pods" "Remote vLLM instances that compute KV cache for prompt tokens" "Internal - Remote Pods"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Provides watch APIs for InferencePool and Pod resources" "Platform"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD defining inference pool membership" "Platform - CRD"

        # Relationships
        client -> routingSidecar "Sends inference requests" "HTTPS/8000 TLS 1.2+"
        routingSidecar -> vllmDecoder "Forwards decode requests and passthrough traffic" "HTTP(S)/8001"
        routingSidecar -> vllmPrefillers "Forwards prefill requests for KV cache computation" "HTTP(S)/dynamic port"
        routingSidecar -> kubernetesAPI "Watches InferencePool and Pod resources for SSRF allowlist" "HTTPS/443 SA Token"

        # Internal container relationships
        proxyServer -> chatHandler "Routes /v1/chat/completions"
        proxyServer -> compHandler "Routes /v1/completions"
        chatHandler -> allowlistValidator "Validates prefiller target"
        compHandler -> allowlistValidator "Validates prefiller target"
        chatHandler -> nixlv2Connector "Delegates P/D orchestration"
        compHandler -> nixlv2Connector "Delegates P/D orchestration"
        nixlv2Connector -> proxyCache "Gets/creates prefiller proxy"
        allowlistValidator -> kubernetesAPI "Watches InferencePool + Pods" "HTTPS/443"
    }

    views {
        systemContext routingSidecar "SystemContext" {
            include *
            autoLayout
            description "System context showing llm-d-routing-sidecar in the disaggregated inference ecosystem"
        }

        container routingSidecar "Containers" {
            include *
            autoLayout
            description "Internal container view of the routing sidecar"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal - Co-located" {
                background #7ed321
                color #ffffff
            }
            element "Internal - Remote Pods" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Platform - CRD" {
                background #bbbbbb
                color #333333
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
            element "Go Protocol Handler (deprecated)" {
                background #999999
                color #ffffff
            }
        }
    }
}

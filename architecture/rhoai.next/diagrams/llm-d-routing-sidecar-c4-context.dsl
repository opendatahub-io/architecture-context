workspace {
    model {
        client = person "Client Application" "Sends LLM inference requests (chat/completions) via EPP/Gateway"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar that orchestrates disaggregated prefill/decode (P/D) protocol for LLM inference" {
            proxyServer = container "Proxy Server" "HTTP/HTTPS reverse proxy listening on :8000, routes requests based on x-prefiller-host-port header" "Go Service"
            nixlv2Connector = container "NIXL v2 Connector" "Implements current P/D protocol with kv_transfer_params for KV-cache transfer" "Go Module"
            nixlv1Connector = container "NIXL v1 Connector" "Deprecated P/D protocol with top-level transfer fields" "Go Module (deprecated)"
            lmcacheConnector = container "LMCache Connector" "Deprecated P/D protocol using max_tokens=1 prefill trigger" "Go Module (deprecated)"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRs and Pod IPs to build dynamic SSRF allowlist via K8s informers" "Go Subsystem"
            tlsManager = container "TLS Manager" "Manages TLS certificates for proxy, supports self-signed (4096-bit RSA) and external certs" "Go Subsystem"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM instance that handles decode (generation) phase of LLM inference" "Internal - Co-located"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote vLLM instances that handle prefill (prompt processing) phase" "Internal - Remote"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch APIs for InferencePool CRs and Pod resources" "Platform"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD (inference.networking.x-k8s.io/v1alpha2) defining pool of inference workers" "Platform CRD"
        epp = softwareSystem "llm-d EPP" "Endpoint Picker that routes requests and sets x-prefiller-host-port header" "Internal llm-d"
        gatewayAPI = softwareSystem "Gateway API Inference Extension" "Kubernetes Gateway API extension for inference workload routing" "External Platform"
        openshiftRoute = softwareSystem "OpenShift Route" "Edge TLS termination for external access" "Platform"

        # Relationships
        client -> openshiftRoute "Sends inference requests" "HTTPS/443"
        openshiftRoute -> routingSidecar "Forwards after TLS termination" "HTTP/8080"
        epp -> routingSidecar "Sets x-prefiller-host-port header on routed requests"

        proxyServer -> nixlv2Connector "Delegates P/D orchestration (default)"
        proxyServer -> nixlv1Connector "Delegates P/D orchestration (deprecated)"
        proxyServer -> lmcacheConnector "Delegates P/D orchestration (deprecated)"
        proxyServer -> allowlistValidator "Validates prefiller host (if SSRF enabled)"
        tlsManager -> proxyServer "Provides TLS configuration"

        routingSidecar -> vllmDecoder "Forwards decode requests and pass-through traffic" "HTTP(S)/8001"
        routingSidecar -> vllmPrefiller "Forwards prefill requests to remote workers" "HTTP(S)/{dynamic port}"
        allowlistValidator -> k8sAPI "Watches InferencePool CRs and Pods" "HTTPS/443 SA Token"
        inferencePool -> allowlistValidator "Provides label selectors for pod filtering"
        gatewayAPI -> inferencePool "Defines InferencePool CRD"
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
                background #438DD5
                color #ffffff
            }
            element "Internal - Co-located" {
                background #85BBF0
                color #000000
            }
            element "Internal - Remote" {
                background #85BBF0
                color #000000
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Platform CRD" {
                background #f5a623
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
            }
        }
    }
}

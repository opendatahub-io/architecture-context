workspace {
    model {
        client = person "Client / Application" "Sends OpenAI-compatible completion requests to the inference serving stack"
        scheduler = softwareSystem "llm-d-inference-scheduler (EPP)" "Routes requests and sets x-prefiller-host-port header for disaggregated serving" "Internal llm-d"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar that orchestrates disaggregated prefill/decode inference using NIXL v2 KV-transfer protocol" {
            proxy = container "HTTP Reverse Proxy" "Intercepts completion requests on port 8000, routes between prefiller and decoder" "Go net/http"
            nixlv2 = container "NIXL v2 Connector" "Implements two-phase prefill-then-decode with kv_transfer_params envelope" "Go"
            allowlistValidator = container "AllowlistValidator" "SSRF protection via InferencePool-based dynamic pod IP allowlist" "Go k8s informers"
            tlsManager = container "TLS Manager" "Self-signed cert generation or cert-path loading, FIPS cipher suites" "Go crypto/tls"
        }

        decoderVLLM = softwareSystem "vLLM Decoder (Local)" "Co-located vLLM instance for decode inference on localhost:8001" "Internal Pod"
        prefillerVLLM = softwareSystem "vLLM Prefiller (Remote)" "Remote vLLM instances for prefill inference, identified via x-prefiller-host-port header" "Remote Pods"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides InferencePool CR and Pod resource watch APIs" "External"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD defining valid prefill target pod selectors" "External"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "Manages InferencePool resources and decoder pod lifecycle" "Internal llm-d"

        # Relationships
        client -> scheduler "Sends completion requests"
        scheduler -> routingSidecar "Forwards with x-prefiller-host-port header" "HTTPS/8000"
        client -> routingSidecar "Direct requests (no prefiller)" "HTTPS/8000"

        proxy -> nixlv2 "Selects protocol handler"
        proxy -> allowlistValidator "Validates prefill target IP"
        proxy -> tlsManager "TLS termination"

        routingSidecar -> decoderVLLM "Forwards decode requests and passthrough" "HTTP(S)/8001"
        routingSidecar -> prefillerVLLM "Forwards prefill requests with kv_transfer_params" "HTTP(S)/variable"
        routingSidecar -> k8sAPI "Watches InferencePool and Pods for SSRF allowlist" "HTTPS/443 SA Token"

        gatewayAPIExt -> inferencePool "Manages"
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
            element "Internal llm-d" {
                background #7ed321
            }
            element "Internal Pod" {
                background #4a90e2
                color #ffffff
            }
            element "Remote Pods" {
                background #f5a623
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

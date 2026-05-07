workspace {
    model {
        client = person "Client / Gateway" "Sends OpenAI-compatible inference requests to the sidecar"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar that orchestrates disaggregated prefill/decode pipeline for LLM inference" {
            proxy = container "HTTP Reverse Proxy" "Intercepts inference requests, routes through P/D pipeline when x-prefiller-host-port header present" "Go net/http"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRs and pods to maintain SSRF protection allowlist of valid prefill targets" "Go Kubernetes dynamic client"
            nixlv2Connector = container "NIXL v2 Connector" "Constructs prefill/decode requests with kv_transfer_params for KV cache transfer" "Go"
            tlsManager = container "TLS Manager" "Manages TLS 1.2+ with ECDHE cipher suites; self-signed RSA-4096 or mounted certs" "Go crypto/tls"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM instance performing decode phase of LLM inference" "Internal - Same Pod"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote vLLM instances performing prefill phase, addressed via x-prefiller-host-port header" "Internal - Remote Pod"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD defining the pool of valid prefill target pods" "Kubernetes CRD"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch interface for InferencePool and Pod resources" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external TLS edge-terminated route to the sidecar service" "External"

        # Relationships
        client -> routingSidecar "Sends POST /v1/chat/completions" "HTTPS/8000 TLS 1.2+"
        openshiftRouter -> routingSidecar "Routes external traffic" "HTTPS/443 → HTTP/8080 edge TLS"

        # Internal container relationships
        proxy -> nixlv2Connector "Delegates P/D request handling"
        proxy -> allowlistValidator "Validates prefill target host"
        proxy -> tlsManager "Configures TLS for listener and upstreams"

        # External relationships
        routingSidecar -> vllmDecoder "Forwards decode requests and passthrough traffic" "HTTP or HTTPS/8001"
        routingSidecar -> vllmPrefiller "Forwards prefill requests with kv_transfer_params" "HTTP or HTTPS/variable port"
        routingSidecar -> k8sAPI "Watches InferencePool and Pod resources for SSRF allowlist" "HTTPS/443 SA Token"
        allowlistValidator -> inferencePool "Watches for selector changes" "Kubernetes dynamic client"
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
            element "Internal - Same Pod" {
                background #7ed321
                color #ffffff
            }
            element "Internal - Remote Pod" {
                background #7ed321
                color #ffffff
            }
            element "Kubernetes CRD" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

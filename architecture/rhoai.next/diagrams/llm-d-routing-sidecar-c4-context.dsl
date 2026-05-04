workspace {
    model {
        client = person "Client / Inference Gateway" "Sends OpenAI-compatible inference requests with optional x-prefiller-host-port header for disaggregated P/D routing"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Go HTTP reverse proxy sidecar that orchestrates disaggregated prefill/decode pipeline for LLM inference" {
            proxy = container "HTTP Reverse Proxy" "Intercepts inference requests, routes through P/D pipeline when x-prefiller-host-port header present, otherwise passes through to decoder" "Go net/http, TLS 1.2+"
            nixlv2Connector = container "NIXL v2 Connector" "Wraps requests with kv_transfer_params, sends prefill with max_tokens=1, extracts KV params from response, constructs decode request" "Go"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CR and Pods via dynamic client to maintain SSRF allowlist of valid prefill target IPs" "Go, k8s client-go"
            tlsManager = container "TLS Manager" "Manages TLS configuration: self-signed RSA-4096 certs or mounted certs, TLS 1.2+ with ECDHE cipher suites" "Go crypto/tls"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM instance that executes the decode phase of LLM inference using KV cache transferred from prefiller" "Internal - same pod"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote vLLM instance(s) that execute the computationally expensive prefill phase and transfer KV cache via NIXL transport" "Internal - separate pod"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch API for InferencePool CRs and Pod resources used by SSRF allowlist" "External"
        inferencePool = softwareSystem "Gateway API Inference Extension" "Defines InferencePool CRD (inference.networking.x-k8s.io/v1alpha2) specifying valid prefill target pod selectors" "External"
        certManager = softwareSystem "cert-manager" "Provisions and manages TLS certificates for the sidecar listener" "External, Optional"

        # Relationships
        client -> routingSidecar "Sends inference requests" "HTTPS/8000, TLS 1.2+"
        routingSidecar -> vllmDecoder "Forwards decode requests and passthrough traffic" "HTTP(S)/8001, localhost"
        routingSidecar -> vllmPrefiller "Forwards prefill requests with modified parameters" "HTTP(S)/variable port"
        routingSidecar -> k8sAPI "Watches InferencePool and Pod resources for SSRF allowlist" "HTTPS/443, ServiceAccount token"
        certManager -> routingSidecar "Provisions TLS certificates" "kubernetes.io/tls secret"

        # Internal container relationships
        proxy -> nixlv2Connector "Routes P/D requests through connector"
        proxy -> allowlistValidator "Validates prefiller host against allowlist"
        proxy -> tlsManager "Manages TLS for listener and upstream connections"
        allowlistValidator -> k8sAPI "Dynamic client informer watch" "HTTPS/443"
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
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal - same pod" {
                background #f5a623
                color #ffffff
            }
            element "Internal - separate pod" {
                background #f5a623
                color #ffffff
            }
            element "External, Optional" {
                background #bbbbbb
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        client = person "Client / Application" "Sends OpenAI-compatible chat completion requests"
        platformOperator = person "Platform Operator" "Deploys and configures disaggregated inference topology"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar that orchestrates disaggregated prefill/decode (P/D) inference by routing requests between prefiller and decoder vLLM instances" {
            proxy = container "Reverse Proxy" "HTTP/HTTPS reverse proxy that intercepts OpenAI-compatible requests and coordinates P/D protocol" "Go HTTP Server"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRs and pod IPs to maintain dynamic SSRF allowlist" "Go Kubernetes Informer"
            nixlV2Connector = container "NIXL v2 Connector" "Default protocol: structured kv_transfer_params for KV cache transfer" "Go Protocol Handler"
            tlsManager = container "TLS Manager" "Handles TLS termination with self-signed or external certificates" "Go crypto/tls"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Local co-located vLLM instance performing token generation (decode phase)" "Internal"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote vLLM instance performing prompt processing (prefill phase)" "Internal"
        gatewayEPP = softwareSystem "Gateway API Inference Extension (EPP)" "Endpoint Picker Plugin that sets x-prefiller-host-port header for P/D routing" "Internal"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD defining valid prefiller pod selectors" "Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch API for InferencePool CRs and Pods" "External"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD build pipeline for container images" "External"

        # External relationships
        client -> routingSidecar "Sends chat completion requests" "HTTPS/8000 TLS 1.2+"
        gatewayEPP -> routingSidecar "Sets x-prefiller-host-port header" "HTTP header convention"
        routingSidecar -> vllmDecoder "Forwards inference requests" "HTTP(S)/8001"
        routingSidecar -> vllmPrefiller "Sends prefill requests" "HTTP(S)/dynamic port"
        routingSidecar -> k8sAPI "Watches InferencePool CRs and Pods" "HTTPS/443 SA Bearer Token"
        konflux -> routingSidecar "Builds container image" "Dockerfile.konflux"
        platformOperator -> routingSidecar "Configures sidecar injection"

        # Internal container relationships
        proxy -> allowlistValidator "Validates prefiller target IPs" "In-process"
        proxy -> nixlV2Connector "Executes P/D protocol" "In-process"
        proxy -> tlsManager "TLS termination" "In-process"
        allowlistValidator -> k8sAPI "Watches InferencePool + Pods" "HTTPS/443"
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

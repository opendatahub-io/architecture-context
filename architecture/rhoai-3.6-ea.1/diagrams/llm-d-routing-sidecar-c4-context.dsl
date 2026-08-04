workspace {
    model {
        client = person "API Client" "Sends OpenAI-compatible inference requests (chat/completions)"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar for disaggregated prefill/decode inference routing" {
            proxy = container "Reverse Proxy" "Intercepts OpenAI API requests, routes prefill to remote pods" "Go HTTP Proxy"
            tlsHandler = container "TLS Handler" "TLS 1.2+ with ECDHE ciphers, self-signed or operator certs" "crypto/tls"
            ssrfAllowlist = container "SSRF Allowlist" "Watches InferencePool CRs to build dynamic allowlist of permitted prefill targets" "Kubernetes Informer"
            lruCache = container "LRU Proxy Cache" "Caches reverse proxy handlers for frequently-targeted prefiller endpoints" "hashicorp/golang-lru"
            connectorNIXLv2 = container "NIXL v2 Connector" "Default P/D protocol for prefill/decode coordination" "Go"
            connectorNIXLv1 = container "NIXL v1 Connector" "Deprecated P/D protocol" "Go"
            connectorLMCache = container "LMCache Connector" "Deprecated P/D protocol" "Go"

            tlsHandler -> proxy "Terminates TLS, forwards plaintext"
            proxy -> ssrfAllowlist "Validates prefiller target"
            proxy -> lruCache "Gets/caches proxy handlers"
            proxy -> connectorNIXLv2 "Routes via NIXL v2"
            proxy -> connectorNIXLv1 "Routes via NIXL v1"
            proxy -> connectorLMCache "Routes via LMCache"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located inference engine for decode operations" "Internal - Co-located"
        vllmPrefiller = softwareSystem "vLLM Prefiller Pods" "Remote pods for disaggregated prefill operations" "Internal - Remote"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource watches" "External"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API inference.networking.x-k8s.io/v1alpha2 resource defining pool membership" "External"
        openShiftRouter = softwareSystem "OpenShift Router" "Ingress via Route for external access" "External"

        client -> openShiftRouter "Sends inference requests" "HTTPS"
        openShiftRouter -> routingSidecar "Forwards to sidecar service" "HTTP/8080"
        client -> routingSidecar "Sends inference requests (direct)" "HTTP/HTTPS 8000/TCP"
        routingSidecar -> vllmDecoder "Forwards inference requests" "HTTP/HTTPS 8001/TCP"
        routingSidecar -> vllmPrefiller "Sends disaggregated prefill requests" "HTTP/HTTPS Dynamic port"
        routingSidecar -> kubernetesAPI "Watches InferencePool and Pods" "HTTPS/WSS 6443/TCP"
        kubernetesAPI -> inferencePool "Manages" "Kubernetes API"
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
            element "Internal - Co-located" {
                background #f5a623
                color #ffffff
            }
            element "Internal - Remote" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
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

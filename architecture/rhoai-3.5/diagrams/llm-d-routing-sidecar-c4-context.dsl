workspace {
    model {
        scheduler = person "Inference Scheduler" "llm-d-inference-scheduler that routes inference requests and sets x-prefiller-host-port headers"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar orchestrating disaggregated prefill/decode (P/D) inference" {
            proxy = container "Reverse Proxy" "Intercepts requests, routes to prefiller then decoder using NIXL v2 protocol" "Go httputil.ReverseProxy"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CRs to maintain dynamic pod IP/hostname allowlist for SSRF protection" "Go SharedInformer"
            tlsManager = container "TLS Manager" "Manages server and client TLS configurations with AEAD cipher suites" "Go crypto/tls"
            lruCache = container "Prefiller Proxy Cache" "Caches reverse proxy instances for up to 16 prefiller endpoints" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM inference server that performs the decode phase of LLM inference" "Internal - Same Pod"
        vllmPrefillers = softwareSystem "vLLM Prefiller Workers" "Remote pods performing the prefill phase (KV cache generation) of disaggregated inference" "Internal - Remote Pods"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch APIs for InferencePool CRs and Pod resources" "External"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD defining the set of pods in the inference pool" "External - inference.networking.x-k8s.io/v1alpha2"
        openshiftRoute = softwareSystem "OpenShift Route" "TLS edge-terminating route for external access" "External"

        # External relationships
        scheduler -> routingSidecar "Sends inference requests with x-prefiller-host-port header" "HTTPS/8000, TLS 1.2+"
        openshiftRoute -> routingSidecar "Forwards external traffic after TLS edge termination" "HTTP/8080"

        # Internal relationships
        proxy -> vllmDecoder "Forwards decode requests and passthrough traffic" "HTTP(S)/8001, localhost"
        proxy -> vllmPrefillers "Sends prefill requests (max_tokens=1) via LRU-cached proxy" "HTTP(S)/varies, TLS 1.2+"
        proxy -> lruCache "Retrieves/stores prefiller proxy handlers" ""
        allowlistValidator -> k8sAPI "Watches InferencePool and Pods via SharedInformer" "HTTPS/443, SA Token"
        allowlistValidator -> proxy "Validates prefiller host against allowlist" ""
        tlsManager -> proxy "Provides TLS config for server and client connections" ""
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
            element "Internal - Same Pod" {
                background #f5a623
                color #000000
            }
            element "Internal - Remote Pods" {
                background #f5a623
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - inference.networking.x-k8s.io/v1alpha2" {
                background #d4a5f5
                color #000000
            }
            element "Container" {
                background #4a90e2
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

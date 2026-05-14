workspace {
    model {
        client = person "Client / Inference Gateway" "Sends OpenAI-compatible inference requests to LLM endpoints"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar that orchestrates disaggregated prefill/decode (P/D) pipeline for LLM inference" {
            proxy = container "HTTP Reverse Proxy" "Intercepts inference requests, routes through P/D pipeline when x-prefiller-host-port header is present, otherwise passes through to local decoder" "Go HTTP Server, TLS 1.2+"
            allowlistValidator = container "AllowlistValidator" "Watches InferencePool CR and pods via Kubernetes API to maintain dynamic SSRF protection allowlist of valid prefill target hosts" "Go Kubernetes Watch Client"
            nixlConnector = container "NIXL v2 Connector" "Wraps requests with kv_transfer_params, sends prefill with max_tokens=1, extracts KV transfer metadata, constructs decode request" "Go Protocol Handler"
            lruCache = container "LRU Proxy Cache" "Caches reverse proxy handlers for prefiller connections (capacity 16)" "hashicorp/golang-lru"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM instance handling the decode phase of LLM inference" "Internal - Same Pod"
        vllmPrefiller = softwareSystem "vLLM Prefiller" "Remote vLLM instances designated as prefill workers for the computationally expensive prefill phase" "Internal - Remote Pods"
        inferencePool = softwareSystem "InferencePool CR" "Gateway API Inference Extension CRD defining the pool of valid prefill target pods" "Kubernetes CRD"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides watch APIs for InferencePool and Pod resources" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing TLS edge termination via Routes" "External"

        # Relationships
        client -> openshiftRouter "Sends inference requests" "HTTPS/443"
        openshiftRouter -> routingSidecar "Routes to sidecar service" "HTTP/8080 (post TLS edge termination)"

        client -> routingSidecar "Sends inference requests (direct)" "HTTPS/8000, TLS 1.2+"

        proxy -> allowlistValidator "Validates prefiller target host" "In-process"
        proxy -> nixlConnector "Delegates P/D protocol handling" "In-process"
        proxy -> lruCache "Caches prefiller proxy handlers" "In-process"

        routingSidecar -> vllmDecoder "Forwards decode requests and passthrough traffic" "HTTP or HTTPS/8001, Optional TLS 1.2+"
        routingSidecar -> vllmPrefiller "Forwards prefill requests to designated workers" "HTTP or HTTPS/variable port, Optional TLS 1.2+"

        allowlistValidator -> k8sAPI "Watches InferencePool and Pod resources for SSRF allowlist" "HTTPS/443, ServiceAccount Token"
        k8sAPI -> inferencePool "Serves InferencePool CR data" "API"
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
                background #7ed321
                color #ffffff
            }
            element "Internal - Remote Pods" {
                background #9b59b6
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

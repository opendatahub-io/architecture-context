workspace {
    model {
        user = person "ML Application / Client" "Sends inference requests via OpenAI-compatible API"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy sidecar for LLM inference routing with P/D disaggregated serving and SSRF protection" {
            proxy = container "Reverse Proxy" "Intercepts and routes OpenAI-compatible inference requests" "Go HTTP Server"
            allowlistValidator = container "AllowlistValidator" "Maintains dynamic pod IP allowlist from InferencePool resources for SSRF protection" "Go Component"
            pdRouter = container "P/D Router" "Inspects request headers/body to determine Prefiller/Decoder routing" "Go Handler"
        }

        vllmDecoder = softwareSystem "vLLM Decoder" "Co-located vLLM decoder instance for inference serving" "Co-located"
        prefillerInstances = softwareSystem "Prefiller Instances" "Remote prefiller pods discovered via InferencePool for disaggregated P/D serving" "Cluster Internal"
        openshiftRoute = softwareSystem "OpenShift Route" "Edge TLS termination and external access" "Platform"
        kubernetesAPI = softwareSystem "Kubernetes API" "Control plane for resource watches and pod discovery" "Platform"
        inferencePool = softwareSystem "InferencePool CR" "Custom resource defining prefiller target pools (inference.networking.x-k8s.io/v1alpha2)" "Platform"

        # External relationships
        user -> openshiftRoute "Sends inference requests" "HTTPS/443"
        openshiftRoute -> routingSidecar "Forwards after TLS termination" "HTTP/8080"
        routingSidecar -> vllmDecoder "Reverse proxies catch-all requests" "HTTP (LRU cached)"
        routingSidecar -> prefillerInstances "Proxies P/D prefill requests" "TLS 1.2+ ECDHE"
        routingSidecar -> kubernetesAPI "Watches InferencePool and Pod resources" "HTTPS/WSS 6443"
        kubernetesAPI -> inferencePool "Serves InferencePool watch events" "API"

        # Internal relationships
        proxy -> pdRouter "Routes /v1/chat/completions, /v1/completions"
        pdRouter -> allowlistValidator "Validates prefiller target IPs"
        allowlistValidator -> kubernetesAPI "Dynamic client informers (30s resync)" "HTTPS/6443"
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
            element "Co-located" {
                background #7ed321
            }
            element "Cluster Internal" {
                background #82b366
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
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

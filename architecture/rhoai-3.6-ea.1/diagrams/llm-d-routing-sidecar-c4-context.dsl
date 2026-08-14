workspace {
    model {
        inferenceClient = person "Inference Client" "Sends OpenAI-compatible inference requests (chat completions, completions)"

        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Reverse-proxy sidecar for prefill/decode disaggregation; intercepts inference requests and routes prefill operations to remote pods" {
            listener = container "TLS Listener" "Accepts inbound inference requests on port 8000 with optional TLS 1.2+" "Go net/http"
            connectorHandler = container "Connector Handler" "Detects P/D routing headers and selects nixlv2/nixl/lmcache protocol" "Go"
            defaultProxy = container "Default Reverse Proxy" "Catch-all route forwarding to co-located vLLM decoder" "Go httputil.ReverseProxy"
            lruCache = container "Prefiller Proxy Cache" "LRU cache (capacity 16) for prefiller reverse proxy handlers" "hashicorp/golang-lru"
            allowlistValidator = container "AllowlistValidator" "Optional SSRF protection via InferencePool CR watch" "Go Kubernetes informer"
            tlsConfig = container "TLS Configuration" "Manages TLS 1.2+ with curated cipher suites, self-signed or provided certs" "Go crypto/tls"
        }

        vllm = softwareSystem "vLLM Decoder" "Co-located vLLM inference engine for decode operations" "Internal"
        prefillers = softwareSystem "Remote Prefiller Pods" "Remote pods handling prefill phase of P/D disaggregation" "Internal"
        k8sApi = softwareSystem "Kubernetes API" "Kubernetes control plane for resource watching" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing TLS-terminated HTTPS routes" "External"

        # Relationships
        inferenceClient -> openshiftRouter "Sends inference requests" "HTTPS/443"
        openshiftRouter -> routingSidecar "Forwards to service" "TCP/8080 → 8000"

        routingSidecar -> vllm "Forwards decode requests" "HTTP(S)/8001 localhost"
        routingSidecar -> prefillers "Proxies prefill requests" "HTTP(S)/dynamic"
        routingSidecar -> k8sApi "Watches InferencePool CRs and Pods for SSRF allowlist" "HTTPS+WSS/6443"

        # Internal relationships
        listener -> connectorHandler "Routes requests with P/D headers"
        listener -> defaultProxy "Routes requests without P/D headers"
        connectorHandler -> lruCache "Gets/creates prefiller proxy handler"
        connectorHandler -> allowlistValidator "Validates prefill target"
        allowlistValidator -> k8sApi "Watches InferencePool + Pods" "HTTPS/6443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
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
        }
    }
}

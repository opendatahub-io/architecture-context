workspace {
    model {
        client = person "API Client" "Sends inference requests to the MaaS gateway"

        praxisExtproc = softwareSystem "praxis-extproc" "Envoy ExtProc gRPC server running Praxis filter pipelines for header/body inspection, mutation, and rejection" {
            preProcessing = container "payload-pre-processing" "Pre-auth ExtProc stage: extracts model name from request body, resolves model providers, sets X-Gateway-Model-Name header" "Rust gRPC Service" "fail-open"
            postProcessing = container "payload-processing" "Post-auth ExtProc stage: runs full Praxis filter pipeline on request and response phases" "Rust gRPC Service" "fail-closed"
            fipsModule = container "FIPS Module" "Installs OpenSSL-backed rustls CryptoProvider, enforces FIPS mode" "Rust Library"
            filterPipeline = container "Filter Pipeline" "Executes Praxis filter chain (model_to_header, llmisvc_model_provider_resolver, etc.)" "Rust Library"
            healthService = container "Health Service" "gRPC health check for Kubernetes readiness/liveness probes" "gRPC Service"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics exposition" "HTTP Service"
        }

        envoy = softwareSystem "Istio Gateway (Envoy)" "Service mesh ingress gateway with EnvoyFilter-managed HTTP filter chain" "External"
        kuadrant = softwareSystem "Kuadrant" "Auth/AuthZ WasmPlugin positioned between pre- and post-processing stages" "External"
        inferencePool = softwareSystem "InferencePool / EPP" "Endpoint Picker Plugin for model routing, repositioned behind post-processing" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster control plane for reading configmaps, secrets, and CRDs" "External"
        modelServer = softwareSystem "Upstream Model Server" "AI/ML model serving endpoint" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # External relationships
        client -> envoy "Sends inference requests" "HTTPS/443, TLS 1.2+"
        envoy -> preProcessing "Sends ExtProc messages (pre-auth, fail-open)" "gRPC/9004, TLS"
        preProcessing -> envoy "Returns routing headers (X-Gateway-Model-Name)" "gRPC/9004"
        envoy -> kuadrant "Forwards for authentication" "Inline WasmPlugin"
        envoy -> postProcessing "Sends ExtProc messages (post-auth, fail-closed)" "gRPC/9004, TLS"
        postProcessing -> envoy "Returns header/body mutations" "gRPC/9004"
        envoy -> inferencePool "Forwards for model routing" "gRPC ExtProc"
        envoy -> modelServer "Forwards inference request" "HTTP/gRPC, TLS"

        # Internal relationships
        preProcessing -> filterPipeline "Invokes filter chain"
        postProcessing -> filterPipeline "Invokes filter chain"
        preProcessing -> fipsModule "Uses for TLS"
        postProcessing -> fipsModule "Uses for TLS"
        preProcessing -> k8sAPI "Reads externalproviders, externalmodels" "HTTPS/443, SA token"
        postProcessing -> k8sAPI "Reads configmaps, secrets, CRDs" "HTTPS/443, SA token"
        prometheus -> metricsEndpoint "Scrapes metrics" "HTTP/9090"
    }

    views {
        systemContext praxisExtproc "SystemContext" {
            include *
            autoLayout
        }

        container praxisExtproc "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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

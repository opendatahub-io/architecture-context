workspace {
    model {
        client = person "API Client" "Sends inference requests to LLM models via OpenAI-compatible API"

        ipp = softwareSystem "Inference Payload Processor (IPP)" "Pluggable Envoy ext-proc service that inspects and mutates inference payloads for multi-pool routing" {
            extProcServer = container "ExternalProcessor Server" "gRPC ext-proc service handling request/response lifecycle events from Envoy" "Go gRPC Service" "9004/TCP"
            pluginFramework = container "Plugin Framework" "Registration, instantiation, and pipeline orchestration of request/response plugins organized into profiles" "Go Library"
            modelSelector = container "ModelSelector" "Filter-Score-Pick pipeline for selecting which model serves a request" "Go Library"
            dataLayer = container "Data Layer" "Cross-request state management via extractors, collectors, and datasources" "Go Library"
            certReloader = container "CertReloader" "Hot-reloading of externally provisioned TLS certificates via filesystem watching" "Go Library"
            healthServer = container "Health Server" "gRPC health check endpoint for liveness and readiness probes" "Go gRPC Service" "9005/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with optional authn/authz" "HTTP Server" "9090/TCP"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that routes inference traffic and invokes ext-proc for payload processing" "External"
        llmdRouter = softwareSystem "llm-d Router (EPP)" "Endpoint Picker Plugin that selects optimal pods within an InferencePool" "Internal llm-d"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server providing ConfigMap watches for model-to-base-model mappings" "External"
        otlpCollector = softwareSystem "OTLP Collector" "Receives distributed traces from IPP when tracing is enabled" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes request metrics (TTFT, model selection, plugin latency)" "External"
        modelServer = softwareSystem "Model Server" "vLLM or other inference runtime serving models in an InferencePool" "External"

        # Relationships
        client -> envoyProxy "Sends inference requests" "HTTPS/443 TLS 1.2+ Bearer Token"
        envoyProxy -> ipp "Invokes ext-proc for payload processing" "gRPC/9004 Optional TLS"
        ipp -> envoyProxy "Returns header mutations and routing directives" "gRPC stream"
        envoyProxy -> modelServer "Forwards requests to selected pool" "HTTP/8000"

        ipp -> k8sAPI "Watches ConfigMaps for model mappings" "HTTPS+WSS/6443 TLS 1.2+ SA Token"
        ipp -> otlpCollector "Exports traces" "gRPC/4317"
        prometheus -> ipp "Scrapes metrics" "HTTP/9090"

        llmdRouter -> modelServer "Selects pods within pool" ""

        # Internal relationships
        extProcServer -> pluginFramework "Dispatches lifecycle events to plugin pipeline"
        pluginFramework -> modelSelector "Invokes for model selection"
        pluginFramework -> dataLayer "Reads cross-request state"
        extProcServer -> certReloader "Loads TLS credentials"
    }

    views {
        systemContext ipp "SystemContext" {
            include *
            autoLayout
        }

        container ipp "Containers" {
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
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6bb5f0
                color #ffffff
            }
        }
    }
}

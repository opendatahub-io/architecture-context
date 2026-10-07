workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        platformEngineer = person "Platform Engineer" "Configures IPP pipeline and model mappings"

        ipp = softwareSystem "Inference Payload Processor" "Pluggable gRPC service that inspects and mutates LLM inference payloads for payload-aware routing and model selection via the Envoy ext-proc protocol" {
            extProcServer = container "ExternalProcessor Server" "Receives ext-proc callouts from Envoy, runs plugin pipeline, returns header/body mutations" "Go gRPC Service" "9004/TCP"
            pluginFramework = container "Plugin Framework" "Registry-based plugin system: request/response processors, profile pickers, model selectors, data layer plugins" "Go Library"
            modelSelector = container "Model Selector Pipeline" "Filter -> Score -> Pick pipeline for cost-aware, affinity-based model selection" "Go Library"
            dataLayer = container "Data Layer" "Asynchronous cross-request state via event-driven extractors, periodic collectors, in-memory datastore" "Go Library"
            healthServer = container "Health Server" "Plaintext gRPC health check for Kubernetes probes" "Go gRPC Service" "9005/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics with optional authn/authz and pprof" "Go HTTP Service" "9090/TCP"
        }

        envoyProxy = softwareSystem "Envoy Gateway Proxy" "API gateway with ext-proc filter chain for request/response processing" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for ConfigMap watches and RBAC" "External"
        istio = softwareSystem "Istio Service Mesh" "EnvoyFilter and DestinationRule for proxy integration" "External"
        gke = softwareSystem "GKE Gateway" "GCPRoutingExtension for native routing extension integration" "External"
        inferencePool = softwareSystem "InferencePool" "Pool-level backend serving a single base model, selected by HTTPRoute header match" "Internal llm-d"
        llmdRouter = softwareSystem "llm-d Router (EPP)" "Endpoint Picker selects pod within an InferencePool" "Internal llm-d"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and monitoring" "External"
        modelServer = softwareSystem "Model Server" "vLLM or compatible inference server serving base model + LoRA adapters" "External"

        # Relationships
        dataScientist -> envoyProxy "Sends inference requests" "HTTPS/443"
        platformEngineer -> k8sAPI "Configures model mappings via ConfigMaps" "kubectl"

        envoyProxy -> ipp "Sends ext-proc callouts for every HTTP lifecycle event" "gRPC/9004"
        ipp -> k8sAPI "Watches ConfigMaps for base-model-to-adapter mappings" "HTTPS/6443"
        ipp -> otlpCollector "Exports distributed traces" "gRPC/4317"
        prometheus -> ipp "Scrapes metrics" "HTTP/9090"

        envoyProxy -> inferencePool "Routes based on X-Gateway-Base-Model-Name header" "HTTP/8000"
        inferencePool -> llmdRouter "EPP selects serving pod" "gRPC"
        llmdRouter -> modelServer "Forwards inference request to selected pod" "HTTP"

        istio -> envoyProxy "Configures ext-proc filter via EnvoyFilter" "Kubernetes API"
        gke -> envoyProxy "Registers ext-proc via GCPRoutingExtension" "Kubernetes API"

        # Container relationships
        extProcServer -> pluginFramework "Delegates to plugin pipeline"
        pluginFramework -> modelSelector "Invokes for model selection profiles"
        pluginFramework -> dataLayer "Fires events, reads state"
        modelSelector -> dataLayer "Reads candidate models and scores"
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

workspace {
    model {
        operator = person "Platform Engineer" "Deploys and configures inference gateways with payload processing"
        datascientist = person "Data Scientist" "Sends inference requests to deployed models and LoRA adapters"

        ipp = softwareSystem "Inference Payload Processor" "Pluggable Envoy ext-proc service for payload-aware inference routing across models and LoRA adapters" {
            extProcServer = container "ExtProc gRPC Server" "Implements Envoy External Processing API; receives per-request lifecycle events" "Go gRPC Service" "9004/TCP"
            pluginFramework = container "Plugin Framework" "Extensible pipeline: PreProcessor, ProfilePicker, Profile (Filter/Score/Pick), PostProcessor, ModelSelector" "Go Library"
            configMapReconciler = container "ConfigMapReconciler" "Watches ConfigMaps with inference.llm-d.ai/ipp-managed=true label for adapter-to-base-model mappings" "Controller-Runtime Controller"
            dataLayerProcessor = container "Data Layer Processor" "Event-driven pipeline with Collector, Extractor, and DataSource plugins for cross-request state" "Go Library"
            healthServer = container "Health Server" "Dedicated gRPC health check endpoint for kubelet probes" "gRPC Service" "9005/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics and pprof endpoints with optional authentication" "HTTP Service" "9090/TCP"
            adaptersStore = container "AdaptersStore" "In-memory LRU cache of adapter-to-base-model mappings" "Go In-Memory Cache"

            extProcServer -> pluginFramework "Dispatches request/response events to plugin pipeline"
            pluginFramework -> dataLayerProcessor "Feeds data-layer events for cross-request state"
            pluginFramework -> adaptersStore "Looks up adapter-to-base-model mappings"
            configMapReconciler -> adaptersStore "Populates adapter-to-base-model mappings"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "Inference gateway proxy with ext-proc filter chain" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for ConfigMap access and RBAC" "External"
        llmdRouter = softwareSystem "llm-d Router (EPP)" "Endpoint Picker for pod-level routing within an InferencePool" "Internal llm-d"
        inferencePool = softwareSystem "InferencePool / Model Server" "Serves model inference requests" "Internal llm-d"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter for ext-proc wiring and mTLS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"

        datascientist -> envoyProxy "Sends inference requests" "HTTPS/443"
        envoyProxy -> ipp "Sends ext-proc callouts for each request lifecycle event" "gRPC/9004"
        ipp -> envoyProxy "Returns header/body mutations and routing headers" "gRPC/9004"
        envoyProxy -> inferencePool "Forwards routed inference requests" "HTTP/8000"
        ipp -> kubernetesAPI "Watches ConfigMaps for adapter-to-base-model mappings" "HTTPS/6443"
        ipp -> llmdRouter "Imports shared plugin framework types" "Go library"
        prometheus -> ipp "Scrapes metrics endpoint" "HTTP/9090"
        ipp -> otlpCollector "Exports distributed traces" "gRPC/4317"
        operator -> ipp "Configures via PayloadProcessorConfig YAML and Helm chart"
        operator -> istio "Deploys EnvoyFilter for ext-proc integration"
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
                color #333333
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

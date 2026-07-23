workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys models and LoRA adapters behind the inference gateway"
        platformEngineer = person "Platform Engineer" "Configures Gateway routing, IPP plugins, and model mappings"

        ipp = softwareSystem "Inference Payload Processor (IPP)" "Pluggable Envoy ext-proc service for payload-aware routing and model selection in the llm-d data plane" {
            extProcServer = container "ext-proc gRPC Server" "Receives request/response lifecycle events from Envoy and returns header/body mutations" "Go gRPC Service, 9004/TCP"
            pluginFramework = container "Plugin Framework" "Registry-based factory pattern supporting request processors, response processors, model selectors, and data layer plugins" "Go Library"
            modelSelectorPipeline = container "Model Selector Pipeline" "Three-phase Filter → Score → Pick pipeline for selecting which model serves a request" "Go Library"
            dataLayer = container "Data Layer" "Asynchronous event-driven system maintaining cross-request state (in-flight counts, cost distributions)" "Go Library"
            configReconciler = container "ConfigMap Reconciler" "Watches Kubernetes ConfigMaps with label inference.llm-d.ai/ipp-managed for adapter-to-base-model mappings" "controller-runtime Reconciler"
            healthServer = container "Health Server" "gRPC health check service for liveness and readiness probes" "Go gRPC Service, 9005/TCP"
            metricsServer = container "Metrics & Profiling" "Prometheus metrics endpoint and pprof profiling" "HTTP, 9090/TCP"
        }

        envoyProxy = softwareSystem "Envoy Proxy (Gateway)" "L7 proxy that invokes IPP via ext-proc protocol and applies routing decisions" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Provides ConfigMap watch API for model mappings and RBAC enforcement" "External"
        inferencePool = softwareSystem "InferencePool" "Gateway API Inference Extension pool-level backend selected by HTTPRoute header match" "Internal llm-d"
        epp = softwareSystem "llm-d Router (EPP)" "Complementary ext-proc service that selects pods within a pool" "Internal llm-d"
        modelServers = softwareSystem "Model Servers (vLLM)" "Actual LLM inference endpoints serving predictions" "External"
        istioGateway = softwareSystem "Istio Gateway" "Service mesh gateway; EnvoyFilter inserts ext-proc filter into filter chain" "External"
        gkeGateway = softwareSystem "GKE Gateway" "Google Cloud gateway; GCPRoutingExtension registers IPP as routing extension" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed traces via OTLP/gRPC" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes operational metrics from /metrics endpoint" "External"

        # Relationships
        dataScientist -> envoyProxy "Sends inference requests" "HTTPS/443"
        platformEngineer -> k8sApi "Creates ConfigMaps with model mappings" "kubectl"

        envoyProxy -> ipp "Invokes ext-proc on each request/response lifecycle event" "gRPC/9004, self-signed TLS"
        ipp -> envoyProxy "Returns header/body mutations (routing headers)" "gRPC/9004"
        ipp -> k8sApi "Watches ConfigMaps for adapter→base model mappings" "HTTPS/443, SA token"
        ipp -> otelCollector "Exports distributed traces" "gRPC/4317, OTLP"

        envoyProxy -> inferencePool "Routes to pool via HTTPRoute header match" "HTTP"
        inferencePool -> epp "Delegates pod selection" "ext-proc"
        epp -> modelServers "Forwards inference request" "HTTP/8000"

        prometheus -> ipp "Scrapes metrics" "HTTP/9090"

        istioGateway -> envoyProxy "Configures via EnvoyFilter" "Control Plane"
        gkeGateway -> envoyProxy "Configures via GCPRoutingExtension" "Control Plane"

        # Container-level relationships
        extProcServer -> pluginFramework "Dispatches lifecycle events to plugins"
        pluginFramework -> modelSelectorPipeline "Invokes model selection for requests"
        pluginFramework -> dataLayer "Emits events asynchronously"
        dataLayer -> dataLayer "Extractors process events and update datastore"
        modelSelectorPipeline -> dataLayer "Reads model attributes and costs for scoring"
        configReconciler -> k8sApi "Watches ConfigMaps" "HTTPS/443"
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

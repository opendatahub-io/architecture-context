workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests via API"
        platformeng = person "Platform Engineer" "Configures InferencePool, InferenceModel, and EPP scheduling plugins"

        llmdScheduler = softwareSystem "llm-d-inference-scheduler" "Inference request scheduler (EPP) that makes optimized routing decisions for LLM inference requests via Gateway API ext-proc" {
            eppServer = container "EPP ext-proc Server" "gRPC server receiving Envoy callbacks, running scheduling pipeline, returning routing decisions" "Go Service (gRPC)"
            pluginFramework = container "Plugin Framework" "Pluggable filters, scorers, profile handlers, pre/post-request handlers" "Go Library (extends GIE)"
            kvCacheTracker = container "KV-Cache Tracker" "Real-time KV-cache state tracking via ZMQ events and prefix hash matching" "Go Library + Rust FFI Tokenizer"
            pdScheduling = container "P/D Scheduling" "Disaggregated Prefill/Decode routing with threshold-based decision logic" "Go Library"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Gateway API implementation that routes inference requests and calls EPP via ext-proc" "External"
        gie = softwareSystem "Gateway API Inference Extension (GIE)" "Core framework providing EPP runner, scheduling framework, plugin registry, CRD reconciliation" "External"
        vllm = softwareSystem "vLLM Model-Serving Pods" "LLM inference runtime serving model predictions" "Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD watches and resource discovery" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Tokenizer model downloads for prefix hash computation" "External"

        # User interactions
        datascientist -> envoyGateway "Sends inference requests" "HTTP/HTTPS"
        platformeng -> k8sAPI "Creates InferencePool, InferenceModel CRs and EndpointPickerConfig" "kubectl"

        # System interactions
        envoyGateway -> llmdScheduler "Calls ext-proc for routing decisions" "gRPC/9002"
        llmdScheduler -> envoyGateway "Returns selected pod address" "gRPC/9002"
        envoyGateway -> vllm "Forwards inference requests to selected pod" "HTTP/8000"
        llmdScheduler -> k8sAPI "Watches InferencePool, InferenceModel, Pods, EndpointSlices" "HTTPS/443"
        vllm -> llmdScheduler "Publishes KV-cache events (cache_tracking mode)" "ZMQ/5557"
        llmdScheduler -> otelCollector "Exports distributed traces" "gRPC OTLP/4317"
        llmdScheduler -> hfHub "Downloads tokenizer models" "HTTPS/443"
        prometheus -> llmdScheduler "Scrapes scheduler metrics" "HTTP/9090"

        # Internal container interactions
        eppServer -> pluginFramework "Delegates scheduling decisions"
        pluginFramework -> kvCacheTracker "Gets prefix cache scores"
        pluginFramework -> pdScheduling "Runs P/D profile evaluation"
    }

    views {
        systemContext llmdScheduler "SystemContext" {
            include *
            autoLayout
            description "System context showing llm-d-inference-scheduler in the LLM inference ecosystem"
        }

        container llmdScheduler "Containers" {
            include *
            autoLayout
            description "Internal container view of the EPP scheduler components"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

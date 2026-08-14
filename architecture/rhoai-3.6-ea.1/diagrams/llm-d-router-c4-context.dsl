workspace {
    model {
        user = person "ML Engineer" "Deploys and manages LLM inference workloads"
        operator = person "Platform Operator" "Configures routing policies and scaling objectives"

        llmDRouter = softwareSystem "llm-d-router" "Envoy ExtProc endpoint picker and routing sidecar for LLM inference workloads" {
            epp = container "Endpoint Picker (EPP)" "gRPC External Processor that selects optimal backend pod via configurable plugin pipeline" "Go gRPC Service"
            pluginPipeline = container "Plugin Pipeline" "Scheduling, flow-control, data-layer, and parsing plugins configured via EndpointPickerConfig CRD" "Go Plugins"
            controllerManager = container "Controller-Runtime Manager" "Reconciles InferencePool, InferenceModelRewrite, InferenceObjective, and Pod resources" "Go Controller"
            datastore = container "In-Memory Datastore" "Live view of available model-serving endpoints and their state" "In-Memory Store"
            pdSidecar = container "pd-sidecar" "DNS-aware routing proxy co-deployed with model-serving pods" "Go HTTP Proxy"
            coordinator = container "coordinator" "Orchestrates multi-instance EPP topologies" "Go Controller"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "HTTP Service"

            epp -> pluginPipeline "Evaluates requests through"
            pluginPipeline -> datastore "Queries endpoint state"
            controllerManager -> datastore "Populates with reconciled resources"
        }

        envoy = softwareSystem "Envoy Proxy" "L7 proxy that routes inference traffic" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster resource management" "External"
        gatewayAPIInference = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRDs for pool-based autoscaling" "Internal Platform"
        llmDKVCache = softwareSystem "llm-d-kv-cache" "KV cache management library for LLM inference" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"
        modelServingPods = softwareSystem "Model-Serving Pods" "Backend pods running LLM inference engines" "Internal Platform"

        operator -> llmDRouter "Configures via EndpointPickerConfig, InferenceModelRewrite, InferenceObjective CRDs"
        envoy -> epp "gRPC ExtProc callout on port 9002"
        epp -> envoy "Returns routing decision (target pod + headers)"
        envoy -> modelServingPods "Forwards inference request to selected pod"
        controllerManager -> k8sAPI "Watches InferencePool, InferenceModelRewrite, InferenceObjective, Pod" "HTTPS/6443 TLS 1.2+"
        controllerManager -> gatewayAPIInference "Watches InferencePool resources" "Kubernetes API"
        pluginPipeline -> llmDKVCache "Uses KV cache library" "Go library"
        metricsServer -> prometheus "Exposes metrics" "HTTP/9090"
        epp -> otelCollector "Exports traces" "OTLP/gRPC"
    }

    views {
        systemContext llmDRouter "SystemContext" {
            include *
            autoLayout
        }

        container llmDRouter "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

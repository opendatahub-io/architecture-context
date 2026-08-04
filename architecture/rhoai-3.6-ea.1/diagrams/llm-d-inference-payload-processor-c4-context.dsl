workspace {
    model {
        client = person "External Client" "Sends inference requests to the serving infrastructure"

        payloadProcessor = softwareSystem "llm-d-inference-payload-processor" "Envoy ExtProc that intercepts inference requests, applies plugin pipeline for payload transformation, model selection, and routing" {
            extProcServer = container "ExtProc gRPC Server" "Receives Envoy ExtProc callouts and processes requests through the plugin pipeline" "Go gRPC Service" "port 9004, TLS"
            pluginPipeline = container "Plugin Pipeline" "Configurable pre-processors, profile picker, and post-processors for request transformation and model selection" "Go Plugin Framework"
            configMapReconciler = container "ConfigMap Reconciler" "Watches ConfigMaps for runtime reconfiguration of base-model-to-header mapping" "controller-runtime Controller"
            healthServer = container "Health gRPC Server" "Provides liveness and readiness probes via grpc.health.v1.Health" "Go gRPC Service" "port 9005, plaintext"
            metricsServer = container "Metrics HTTP Server" "Exposes Prometheus metrics with bearer-token authentication" "controller-runtime HTTP" "port 9090"
        }

        envoy = softwareSystem "Envoy Proxy" "Edge proxy that routes inference requests and delegates processing to ExtProc" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations and auth delegation" "External"
        vllmServers = softwareSystem "vLLM Model Servers" "Serve ML model inference (DeepSeek R1, Llama 3 8B)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # External relationships
        client -> envoy "Sends inference requests" "HTTP/8081"
        envoy -> payloadProcessor "gRPC ExtProc callouts" "gRPC/9004 TLS"
        envoy -> vllmServers "Forwards processed requests" "HTTP/8000"
        prometheus -> payloadProcessor "Scrapes metrics" "HTTP/9090"

        # Internal container relationships
        extProcServer -> pluginPipeline "Processes incoming requests through pipeline"
        pluginPipeline -> extProcServer "Returns modified headers and routing decisions"
        configMapReconciler -> pluginPipeline "Updates base-model-to-header mapping"
        configMapReconciler -> k8sAPI "Watches ConfigMaps" "HTTPS/6443 SA token"
        metricsServer -> k8sAPI "Validates bearer tokens" "HTTPS/6443"

        # Platform relationships
        payloadProcessor -> k8sAPI "ConfigMap reconciliation, metrics auth" "HTTPS/6443"
    }

    views {
        systemContext payloadProcessor "SystemContext" {
            include *
            autoLayout
        }

        container payloadProcessor "Containers" {
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
            element "Person" {
                shape person
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

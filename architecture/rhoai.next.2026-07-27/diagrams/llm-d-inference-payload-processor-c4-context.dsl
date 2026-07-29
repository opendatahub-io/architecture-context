workspace {
    model {
        user = person "ML Application Client" "Sends inference requests to LLM models"
        sre = person "SRE / Platform Admin" "Monitors and configures the inference stack"

        payloadProcessor = softwareSystem "llm-d-inference-payload-processor" "Envoy ExtProc gRPC server providing plugin-based pipeline for pre-processing, profile-based routing, and post-processing of LLM inference requests" {
            extProcServer = container "ExtProc gRPC Server" "Receives Envoy ext_proc callouts, executes plugin pipeline, returns routing decisions" "Go gRPC Service" "9004/TCP"
            pluginFramework = container "Plugin Framework" "Factory-based system with 15 in-tree plugins across pre-processing, profile picking, model selection, response processing, and datalayer categories" "Go"
            configMapController = container "ConfigMap Controller" "controller-runtime manager watching ConfigMaps labeled inference.llm-d.ai/ipp-managed for base model to adapter mappings" "Go controller-runtime"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint and optional OpenTelemetry tracing" "Go" "9090/TCP"
            healthService = container "Health Service" "gRPC health check and HTTP health probe" "Go" "8000/TCP"

            extProcServer -> pluginFramework "Invokes plugin pipeline"
            configMapController -> pluginFramework "Updates base-model mappings"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "Reverse proxy with ext_proc filter for request interception" "Infrastructure"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for ConfigMap watches and resource operations" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP gRPC" "Infrastructure"

        vllmLlama = softwareSystem "vllm-llama3-8b-instruct" "Model server for Llama 3 8B Instruct (dev/e2e)" "Model Server"
        vllmDeepseek = softwareSystem "vllm-deepseek-r1" "Model server for DeepSeek R1 (dev/e2e)" "Model Server"

        user -> envoyProxy "Sends inference requests" "HTTP/8081"
        envoyProxy -> payloadProcessor "ExtProc callouts for request/response processing" "gRPC/9004"
        payloadProcessor -> envoyProxy "Returns routing headers (X-Gateway-Base-Model-Name)"
        envoyProxy -> vllmLlama "Routes inference request to llama_cluster" "HTTP/8000"
        envoyProxy -> vllmDeepseek "Routes inference request to deepseek_cluster" "HTTP/8000"
        payloadProcessor -> k8sAPI "Watches ConfigMaps, resource operations" "HTTPS/6443"
        prometheus -> payloadProcessor "Scrapes metrics" "HTTP/9090"
        payloadProcessor -> otelCollector "Exports traces (when enabled)" "gRPC OTLP"
        sre -> prometheus "Monitors system health"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Model Server" {
                background #f5a623
                color #333333
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

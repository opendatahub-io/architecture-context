workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference services"
        platformAdmin = person "Platform Admin" "Configures inference pools, gateways, and scheduling policies"

        llmdScheduler = softwareSystem "llm-d-inference-scheduler" "Intelligent inference request scheduler for LLM serving — implements Endpoint Picker (EPP) and P/D routing sidecar" {
            epp = container "Endpoint Picker (EPP)" "Receives inference requests from Envoy via gRPC ext-proc, runs scheduling plugins (filters, scorers, profile handlers), returns optimal pod endpoint" "Go gRPC Service" "primary"
            pdSidecar = container "P/D Routing Sidecar" "HTTP reverse proxy on vLLM decode pods — orchestrates disaggregated Encode/Prefill/Decode pipeline and KV cache transfers" "Go HTTP Proxy" "sidecar"
            pluginSystem = container "Plugin System" "21+ pluggable filters, scorers, profile handlers, deciders, data layers for extensible scheduling decisions" "Go Plugins"
            kvCacheIndex = container "KV-Cache Index" "In-memory real-time index of KV-block cache state per endpoint, updated via ZMQ events with speculative indexing" "In-Memory Data Structure"

            epp -> pluginSystem "Executes scheduling pipeline" "Function calls"
            pluginSystem -> kvCacheIndex "Queries prefix cache scores" "In-process"
            epp -> kvCacheIndex "Speculative index writes after routing" "In-process"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Data plane gateway with ext-proc support (Gateway API implementation)" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane — CRD watches, RBAC, pod discovery" "External"
        vllmServers = softwareSystem "vLLM Model Servers" "LLM model serving pods (decoder, prefiller, encoder roles)" "Internal llm-d"
        udsTokenizer = softwareSystem "UDS Tokenizer" "Tokenization service via gRPC over Unix Domain Socket" "Internal llm-d"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Tokenizer model downloads" "External"
        inferencePoolCRD = softwareSystem "InferencePool CRD (GIE)" "Gateway API Inference Extension — defines pools of model-serving pods" "Internal GIE"

        # User interactions
        dataScientist -> envoyGateway "Sends inference requests" "HTTP/80"
        platformAdmin -> inferencePoolCRD "Configures inference pools and EPP references" "kubectl"

        # Gateway to scheduler
        envoyGateway -> epp "Forwards requests for routing decisions" "gRPC ext-proc/9002"
        epp -> envoyGateway "Returns routing decision with target pod headers" "gRPC ext-proc/9002"
        envoyGateway -> pdSidecar "Routes request to selected vLLM pod" "HTTP or HTTPS/8000"

        # EPP dependencies
        epp -> k8sAPI "Watches InferencePool, Pod resources" "HTTPS/443 (SA token)"
        epp -> udsTokenizer "Tokenizes prompts for prefix cache scoring" "gRPC/UDS"
        epp -> vllmServers "Subscribes to KV-cache events" "ZMQ SUB/5555-5557"
        epp -> otlpCollector "Exports distributed traces" "gRPC/4317"
        epp -> huggingFace "Downloads tokenizer models" "HTTPS/443 (HF_TOKEN)"
        epp -> prometheus "Exposes scheduling metrics" "HTTP/9090"

        # Sidecar dependencies
        pdSidecar -> vllmServers "Forwards decode/prefill/encode requests" "HTTP or HTTPS/8001 + configurable"
        pdSidecar -> k8sAPI "Watches pods for SSRF allowlist" "HTTPS/443 (SA token)"
        pdSidecar -> otlpCollector "Exports distributed traces" "gRPC/4317"

        # CRD relationship
        epp -> inferencePoolCRD "Watches for pod endpoint discovery" "K8s Watch API"
    }

    views {
        systemContext llmdScheduler "SystemContext" {
            include *
            autoLayout
        }

        container llmdScheduler "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Internal GIE" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "primary" {
                background #4a90e2
            }
            element "sidecar" {
                background #2d6cb4
            }
        }
    }
}

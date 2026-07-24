workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and manages ML inference workloads"
        platformEngineer = person "Platform Engineer" "Configures inference pools, routing policies, and scheduling profiles"

        llmDRouter = softwareSystem "llm-d Router" "Intelligent inference request router with LLM load-aware, prefix-cache-aware routing, request prioritization, and disaggregated inference coordination" {
            epp = container "Endpoint Picker (EPP)" "Core inference routing engine; integrates with Envoy via ext_proc gRPC; plugin-based scheduling with 60+ built-in plugins across 7 extension points" "Go Service (controller-runtime)" {
                extProcServer = component "ext_proc gRPC Server" "Bidirectional streaming gRPC server implementing Envoy ExternalProcessor protocol" "Go gRPC Server"
                pluginFramework = component "Plugin Framework" "Extensible scheduling framework: filters, scorers, pickers, profile handlers, flow control, request control, data layer, request handling" "Go Plugin System"
                controllers = component "Kubernetes Controllers" "Reconciles InferencePool, Pod, InferenceObjective, InferenceModelRewrite resources" "controller-runtime"
                datastore = component "In-Memory Datastore" "Stores endpoint state, metrics, priorities, model rewrites for scheduling decisions" "Go In-Memory"
                metricsServer = component "Metrics Server" "Prometheus metrics endpoint with 50+ metrics across request, pool, scheduler, flow control subsystems" "HTTP Server"
            }

            sidecar = container "Disaggregation Sidecar (pd-sidecar)" "Coordinates multi-stage disaggregated inference (P/D, E/P/D); manages KV-cache transfers via pluggable connectors" "Go HTTP Proxy" {
                proxyHandler = component "Proxy Handler" "Intercepts inference requests and routes prefill/encode stages to remote workers" "HTTP Reverse Proxy"
                kvConnectors = component "KV-Cache Connectors" "Pluggable KV-cache transfer: nixlv2, shared-storage, sglang, mooncake" "Go Plugins"
                ecConnectors = component "EC Connectors" "Pluggable encoder connectors: ec-example, ec-nixl" "Go Plugins"
            }
        }

        envoy = softwareSystem "Envoy / AgentGateway" "L7 proxy providing ext_proc integration for data plane traffic management" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform; API server for CRD watches and leader election" "External"
        gatewayAPIIE = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRD (sigs.k8s.io/gateway-api-inference-extension)" "External"
        modelServers = softwareSystem "Model Servers (vLLM / SGLang)" "LLM inference backends providing prediction and metrics endpoints" "Internal Platform"
        prefillWorkers = softwareSystem "Prefill Workers" "Remote prefill stage workers for P/D disaggregated inference" "Internal Platform"
        encodeWorkers = softwareSystem "Encode Workers" "Remote encode stage workers for E/P/D disaggregated inference" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing with W3C Trace Context propagation" "External"
        latencyPredictor = softwareSystem "Latency Predictor" "TTFT/TPOT latency prediction service for SLO-aware scheduling" "Internal Platform"
        kvCacheLib = softwareSystem "llm-d-kv-cache" "KV-cache block management library for prefix cache scoring" "External"

        # Relationships
        dataScientist -> llmDRouter "Sends inference requests via"
        platformEngineer -> llmDRouter "Configures InferencePool, InferenceObjective, InferenceModelRewrite CRDs"

        envoy -> epp "Sends ext_proc ProcessingRequest" "gRPC/9002 TLS"
        epp -> envoy "Returns routing decisions via header mutations" "gRPC/9002 TLS"
        envoy -> modelServers "Forwards routed inference requests" "HTTP/8000"
        envoy -> sidecar "Forwards requests for disaggregated inference" "HTTPS/8000"

        epp -> kubernetes "Watches CRDs: InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "HTTPS/443 SA token"
        epp -> modelServers "Scrapes Prometheus metrics for scheduling decisions" "HTTP/8000 InsecureSkipVerify"
        epp -> otel "Exports distributed traces" "gRPC/4317"
        epp -> latencyPredictor "Queries TTFT/TPOT predictions" "HTTP/8001"

        sidecar -> prefillWorkers "Routes prefill stage requests" "HTTP(S)/Dynamic"
        sidecar -> encodeWorkers "Routes encode stage requests" "HTTP(S)/Dynamic"
        sidecar -> modelServers "Forwards decode stage to local vLLM" "HTTP(S)/8001"

        prometheus -> epp "Scrapes metrics" "HTTP/9090"

        llmDRouter -> gatewayAPIIE "Uses InferencePool CRD" "Kubernetes API"
        llmDRouter -> kvCacheLib "Uses for prefix cache scoring" "Go library"
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

        component epp "EPPComponents" {
            include *
            autoLayout
        }

        component sidecar "SidecarComponents" {
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
                background #4a90e2
                color #ffffff
                shape person
            }
        }
    }
}

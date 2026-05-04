workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference models"
        sre = person "SRE / Platform Admin" "Manages inference platform and monitors performance"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Optimized routing and scheduling for LLM inference workloads via Gateway API Inference Extension (GIE)" {
            epp = container "EPP (Endpoint Picker)" "Main scheduling service receiving ext_proc gRPC calls from Envoy, routing inference requests to optimal model-serving pods via pluggable filter/scorer/picker pipeline" "Go Service (controller-runtime)" {
                extProcServer = component "ext_proc gRPC Server" "Receives routing callbacks from Envoy for each request" "gRPC Server, 9002/TCP"
                schedulingPipeline = component "Scheduling Pipeline" "Pluggable filter/scorer/picker framework with configurable profiles" "Go Plugin Framework"
                controllers = component "CRD Reconcilers" "Watch InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "controller-runtime"
                dataLayer = component "Data Layer" "DAG-based data collection from metrics, K8s events, ZMQ streams" "Go"
                kvCacheIndex = component "KV Cache Index" "Precise prefix cache scoring via real-time KV cache events" "llm-d-kv-cache library"
                flowControl = component "Flow Control" "Priority-based admission with fairness and ordering policies" "Go (Experimental)"
                metricsServer = component "Metrics Server" "Prometheus metrics exposition" "HTTP Server, 9090/TCP"
                healthServer = component "Health Server" "Liveness and readiness checks" "gRPC Server, 9003/TCP"
            }

            sidecar = container "P/D Routing Sidecar" "Sidecar proxy for disaggregated inference, orchestrating prefill/decode/encode stages with KV cache transfer" "Go HTTP Proxy" {
                httpProxy = component "HTTP/HTTPS Proxy" "Intercepts inference API calls and coordinates P/D stages" "HTTP Proxy, 8000/TCP"
                nixlConnector = component "NIXL V2 Connector" "Direct memory KV transfer via request parameters" "Go"
                sharedStorageConnector = component "Shared Storage Connector" "KV transfer via intermediate storage layer" "Go"
                sglangConnector = component "SGLang Connector" "Concurrent execution with room-based coordination" "Go"
                ssrfAllowlist = component "SSRF Allowlist" "InferencePool-based pod allowlist for target validation" "Go"
            }

            tokenizer = container "UDS Tokenizer" "Tokenization service for prompt analysis" "External Sidecar Image, Unix Domain Socket"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Kubernetes Gateway with ext_proc support for traffic routing" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD management and pod discovery" "External"
        vllmServers = softwareSystem "vLLM Model Servers" "LLM model serving pods providing inference and metrics" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        gatewayAPI = softwareSystem "Gateway API (GIE)" "Kubernetes Gateway API Inference Extension framework" "External"

        # User interactions
        datascientist -> envoyGateway "Sends inference requests" "HTTP/HTTPS"
        sre -> prometheus "Monitors metrics" "HTTP"

        # External system interactions
        envoyGateway -> epp "Sends ext_proc routing callbacks" "gRPC/9002"
        epp -> envoyGateway "Returns routing decisions (target endpoint)" "gRPC/9002"
        envoyGateway -> vllmServers "Routes requests to selected pods" "HTTP/8000"
        envoyGateway -> sidecar "Routes P/D requests to sidecar" "HTTP-HTTPS/8000"

        epp -> k8sAPI "Watches InferencePool, Pod, InferenceObjective, InferenceModelRewrite CRs" "HTTPS/443, SA Token"
        epp -> vllmServers "Scrapes Prometheus metrics (queue, KV cache, LoRA)" "HTTP/HTTPS"
        vllmServers -> epp "Publishes KV cache events" "ZMQ PUB/SUB 5556"
        tokenizer -> epp "Tokenizes prompts for prefix cache scoring" "gRPC/UDS"

        sidecar -> vllmServers "Forwards prefill/decode/encode requests" "HTTP/HTTPS"
        sidecar -> k8sAPI "Watches InferencePool for SSRF allowlist" "HTTPS/443"

        prometheus -> epp "Scrapes /metrics" "HTTP/9090"
        epp -> otelCollector "Exports distributed traces" "gRPC OTLP/4317"
    }

    views {
        systemContext llmdScheduler "SystemContext" {
            include *
            autoLayout
            description "System context showing llm-d Inference Scheduler in the broader inference platform"
        }

        container llmdScheduler "Containers" {
            include *
            autoLayout
            description "Container view showing EPP, P/D Sidecar, and UDS Tokenizer"
        }

        component epp "EPP-Components" {
            include *
            autoLayout
            description "EPP internal components: scheduling pipeline, controllers, data layer"
        }

        component sidecar "Sidecar-Components" {
            include *
            autoLayout
            description "P/D Sidecar internal components: proxy, KV connectors, SSRF protection"
        }

        styles {
            element "Software System" {
                background #1168bd
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

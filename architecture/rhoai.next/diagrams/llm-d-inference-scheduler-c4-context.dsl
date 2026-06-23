workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and serves LLM models via InferencePool/InferenceService"
        sre = person "SRE / Platform Admin" "Monitors scheduling performance, configures InferenceObjective priorities"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Intelligent inference request scheduler that routes LLM inference traffic to optimal model server endpoints" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc gRPC service that schedules inference requests using pluggable filter/scorer/picker pipeline" "Go gRPC Service" {
                extProcServer = component "ext-proc gRPC Server" "Receives request headers/body from gateway, returns routing decision" "gRPC/9002"
                schedulingPipeline = component "Scheduling Pipeline" "Filter → Score → Pick with pluggable plugins (KV-cache, latency, prefix, LoRA, session)" "Go Plugin Framework"
                dataLayer = component "Data Layer Runtime" "DAG-based data collection from model server metrics, ZMQ events, K8s watches" "Plugin Pipeline"
                flowControl = component "Flow Control Layer" "Priority-based admission control with fairness policies and saturation detection" "Experimental"
                poolReconciler = component "InferencePool Reconciler" "Watches InferencePool CRs for pool config" "controller-runtime"
                podReconciler = component "Pod Reconciler" "Tracks model server pod readiness" "controller-runtime"
                objectiveReconciler = component "InferenceObjective Reconciler" "Manages priority bands" "controller-runtime"
                rewriteReconciler = component "InferenceModelRewrite Reconciler" "Model name rewriting rules" "controller-runtime"
            }

            pdSidecar = container "PD-Sidecar" "Per-pod reverse proxy that orchestrates disaggregated prefill/decode inference with KV-cache transfer" "Go HTTP Reverse Proxy" {
                reverseProxy = component "HTTP Reverse Proxy" "Intercepts inference requests and orchestrates P/D pipeline" "8000/TCP"
                kvConnector = component "KV Connector" "Pluggable KV-cache transfer (NIXLv2/Mooncake/SGLang/shared-storage)" "Go Plugin"
                ecConnector = component "EC Connector" "Encoder cache connector for multimodal EPD pipeline" "Go Plugin"
                ssrfValidator = component "SSRF Validator" "Validates prefill/encoder targets against InferencePool pod allowlist" "Security"
            }
        }

        envoyGateway = softwareSystem "Envoy/Istio Inference Gateway" "Gateway API-compatible proxy that handles external traffic and delegates routing to EPP" "External"
        vllmServers = softwareSystem "vLLM/SGLang Model Servers" "LLM inference engines serving model predictions" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches and pod tracking" "External"
        gatewayAPIGIE = softwareSystem "Gateway API Inference Extension" "Upstream project defining InferencePool and InferenceModel CRDs" "External"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics monitoring and alerting" "External"
        mooncake = softwareSystem "Mooncake Bootstrap" "Data-parallel rank mapping for Mooncake KV connector" "External"

        # Person interactions
        dataScientist -> llmdScheduler "Creates InferencePool, InferenceModelRewrite CRs via kubectl"
        sre -> llmdScheduler "Configures InferenceObjective priorities and monitors metrics"

        # System-level interactions
        envoyGateway -> llmdScheduler "Sends ext-proc requests for routing decisions" "gRPC/9002 TLS"
        llmdScheduler -> vllmServers "Scrapes /metrics, dispatches prefill/decode/encode requests" "HTTP/HTTPS"
        llmdScheduler -> k8sAPI "Watches CRDs, Pods for scheduling state" "HTTPS/443 SA Token"
        llmdScheduler -> otelCollector "Exports distributed traces" "gRPC/4317 OTLP"
        llmdScheduler -> mooncake "Queries dp_rank mapping" "HTTP/8998"
        prometheus -> llmdScheduler "Scrapes /metrics endpoint" "HTTP/9090"
        envoyGateway -> vllmServers "Forwards routed requests to selected model server" "HTTP/HTTPS"

        # Container-level interactions
        envoyGateway -> epp "ext-proc ProcessingRequest with headers/body" "gRPC/9002 TLS"
        epp -> k8sAPI "Watch InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "HTTPS/443"
        epp -> vllmServers "Scrape /metrics for KV-cache, queue depth, running requests" "HTTP"
        epp -> otelCollector "Export scheduling traces" "gRPC/4317"
        envoyGateway -> pdSidecar "Forward inference requests (P/D mode)" "HTTP(S)/8000"
        pdSidecar -> vllmServers "Dispatch prefill, decode, encode phases" "HTTP(S)"
        pdSidecar -> k8sAPI "Watch InferencePool pods for SSRF allowlist" "HTTPS/443"
        pdSidecar -> mooncake "Query dp_rank→engine_id mapping" "HTTP/8998"
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

        component epp "EPP-Components" {
            include *
            autoLayout
        }

        component pdSidecar "Sidecar-Components" {
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
            element "Software System" {
                background #4a90e2
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

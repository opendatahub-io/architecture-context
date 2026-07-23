workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries ML models via inference APIs"
        sre = person "SRE / Platform Admin" "Configures InferencePools, monitors routing performance"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent LLM inference request routing engine with KV-cache-aware endpoint selection, priority-based flow control, and disaggregated prefill/decode orchestration" {
            epp = container "Endpoint Picker (EPP)" "Routing engine using ext-proc protocol to intercept Envoy requests and select optimal model server endpoints based on KV-cache locality, load, priority, and model compatibility" "Go (controller-runtime + gRPC)" {
                pluginFramework = component "Plugin Framework" "60+ built-in plugins for filtering, scoring, data collection, flow control, and request parsing" "Go"
                scheduler = component "Scheduling Engine" "Filter → Score → Pick pipeline for endpoint selection" "Go"
                crdWatcher = component "CRD Watcher" "Watches InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "controller-runtime"
                metricsCollector = component "Metrics Collector" "Scrapes Prometheus metrics from model servers for scheduling decisions" "Go"
            }
            sidecar = container "Disaggregation Sidecar (pd-sidecar)" "Orchestrates P/D and E/P/D disaggregated inference flows, managing KV-cache and embedding transfers between prefill, encode, and decode workers" "Go (HTTP reverse proxy)"
            coordinator = container "Coordinator (experimental)" "E/P/D pipeline orchestrator that sequences encode/prefill/decode through the inference gateway" "Go (HTTP)"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy providing ext-proc integration, TLS termination, and traffic routing to model servers" "External"
        gieExtension = softwareSystem "Gateway API Inference Extension (GIE)" "Provides InferencePool CRD and endpoint picker protocol (v1.5.0)" "External"
        vllmServers = softwareSystem "vLLM Model Servers" "Model serving backends (vLLM, SGLang, Triton) that run inference workloads" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides CRD storage, Pod watches, and RBAC enforcement" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection (optional)" "External"
        redis = softwareSystem "Redis" "Optional distributed data layer for shared state" "External"

        prefillWorkers = softwareSystem "Prefill Worker Pods" "Execute prefill computation and transfer KV-cache via NIXL RDMA or shared storage" "Internal"
        encoderWorkers = softwareSystem "Encoder Worker Pods" "Process multimodal content encoding for E/P/D pipeline" "Internal"
        inferenceGateway = softwareSystem "Inference Gateway" "Routes encode/prefill/decode pipeline requests (coordinator mode)" "Internal"

        # Relationships
        user -> envoyProxy "Sends inference requests" "HTTPS/443"
        sre -> llmdRouter "Configures InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "kubectl"

        envoyProxy -> epp "Sends requests for endpoint selection" "ext-proc gRPC/9002, Self-signed TLS"
        epp -> envoyProxy "Returns selected endpoint" "gRPC response"
        envoyProxy -> vllmServers "Routes inference requests to selected endpoint" "HTTP/8000"
        envoyProxy -> sidecar "Forwards requests to disaggregated decode pods" "HTTP/8000"

        epp -> k8sAPI "Watches CRDs and Pods" "HTTPS/443, SA Token"
        epp -> vllmServers "Scrapes metrics for scheduling" "HTTP/8000, InsecureSkipVerify"
        epp -> prometheus "Exposes operational metrics" "HTTP/9090"
        epp -> otlpCollector "Exports traces" "gRPC/4317"
        epp -> redis "Optional distributed state" "TCP/6379"

        sidecar -> prefillWorkers "Sends prefill requests" "HTTP/Dynamic, Optional TLS"
        sidecar -> vllmServers "Forwards decode requests to local server" "HTTP/8200"
        sidecar -> k8sAPI "Watches InferencePool for SSRF validation" "HTTPS/443, SA Token"
        prefillWorkers -> vllmServers "Transfers KV-cache" "NIXL RDMA/61005"

        coordinator -> inferenceGateway "Routes E/P/D pipeline phases" "HTTP/2 /80, EPP-Phase headers"
        coordinator -> encoderWorkers "Sends encode requests (via gateway)" "HTTP/Dynamic"

        llmdRouter -> gieExtension "Uses InferencePool CRD protocol" ""
    }

    views {
        systemContext llmdRouter "SystemContext" {
            include *
            autoLayout
        }

        container llmdRouter "Containers" {
            include *
            autoLayout
        }

        component epp "EPPComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

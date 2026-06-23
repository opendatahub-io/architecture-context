workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference services"
        platformeng = person "Platform Engineer" "Configures inference pools, scheduling profiles, and routing policies"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Optimized routing and disaggregated inference orchestration for LLM workloads via Gateway API Inference Extension" {
            epp = container "EPP (Endpoint Picker)" "Envoy ext-proc server that schedules inference requests to optimal model-serving pods using pluggable filter/scorer/picker pipeline" "Go Service (controller-runtime)" {
                extProcServer = component "ext-proc gRPC Server" "Receives requests from Envoy Gateway, returns routing decisions" "gRPC/9002 TLS"
                pluginPipeline = component "Plugin Pipeline" "Filters → Scorers → Pickers for request scheduling" "Go Plugin Framework"
                datastore = component "Datastore" "In-memory state for InferencePool, Pod, Model, Objective CRDs" "controller-runtime cache"
                dataLayer = component "Data Layer" "Collectors and extractors for vLLM metrics and KV cache state" "Polling + ZMQ"
                kvCacheIndexer = component "KV Cache Indexer" "Tracks per-pod KV cache block state for prefix cache scoring" "llm-d-kv-cache lib"
            }
            sidecar = container "Routing Sidecar (pd-sidecar)" "HTTP reverse proxy sidecar for disaggregated inference orchestration (P/D, E/P/D) with pluggable KV transfer protocols" "Go Service" {
                proxyServer = component "HTTP/HTTPS Proxy" "Intercepts OpenAI-compatible API requests" "HTTP/8000 TLS 1.2+"
                nixlConnector = component "NIXL v2 Connector" "Two-stage KV transfer with explicit parameter passing" "Go Plugin"
                sharedStorageConnector = component "Shared Storage Connector" "Cache-first with decode-early optimization" "Go Plugin"
                sglangConnector = component "SGLang Connector" "Concurrent P/D with bootstrap-based KV sharing" "Go Plugin"
                ssrfProtection = component "SSRF Allowlist" "Validates prefill/encoder targets against InferencePool pod IPs" "Dynamic Watcher"
            }
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Data plane gateway for inference traffic routing with ext-proc support" "External"
        gatewayAPI = softwareSystem "Gateway API + Inference Extension (GIE)" "Kubernetes Gateway API CRDs and Inference Extension framework" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM model serving engine providing metrics, KV cache events, and inference API" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches, pod discovery, and RBAC" "Infrastructure"
        istio = softwareSystem "Istio" "Service mesh for mTLS and traffic management (optional)" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Tokenizer model downloads for prefix cache scoring" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        datascientist -> envoyGateway "Sends inference requests" "HTTPS/443"
        platformeng -> k8sAPI "Creates InferencePool, InferenceModel, InferenceObjective CRDs" "kubectl/HTTPS"

        # Envoy ↔ llm-d Scheduler
        envoyGateway -> epp "Calls ext-proc for routing decisions" "gRPC/9002 TLS"
        epp -> envoyGateway "Returns selected endpoint + headers" "gRPC/9002 TLS"
        envoyGateway -> sidecar "Forwards inference requests" "HTTP(S)/8000 TLS 1.2+"

        # EPP dependencies
        epp -> k8sAPI "Watches InferencePool, Pod, Objective, ModelRewrite CRDs" "HTTPS/443 SA Token"
        epp -> vllm "Scrapes metrics (queue depth, KV cache utilization)" "HTTP(S)/configurable"
        epp -> vllm "Subscribes to KV cache events" "ZMQ/5556-5557"
        epp -> huggingface "Downloads tokenizer models" "HTTPS/443 HF_TOKEN"
        epp -> otlpCollector "Exports traces" "gRPC/4317"

        # Sidecar dependencies
        sidecar -> vllm "Forwards inference to local decoder" "HTTP(S)/8001"
        sidecar -> vllm "Sends prefill/encode requests to remote pods" "HTTP(S)/configurable"
        sidecar -> k8sAPI "Watches InferencePool for SSRF allowlist" "HTTPS/443 SA Token"
        sidecar -> otlpCollector "Exports traces" "gRPC/4317"

        # Monitoring
        prometheus -> epp "Scrapes scheduling metrics" "HTTP/9090"

        # Library dependency
        epp -> gatewayAPI "Uses core scheduling framework, CRD types, built-in plugins" "Go library"
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
            element "Infrastructure" {
                background #6c3483
                color #ffffff
            }
            element "Person" {
                shape Person
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

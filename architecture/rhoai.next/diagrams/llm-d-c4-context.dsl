workspace {
    model {
        // People
        datascientist = person "Data Scientist" "Deploys and serves LLM models for inference"
        platformeng = person "Platform Engineer" "Deploys and configures the llm-d inference stack"
        securityeng = person "Security Engineer" "Reviews network policies, RBAC, and compliance"

        // Primary System
        llmd = softwareSystem "llm-d" "High-performance distributed inference serving stack for LLMs on Kubernetes" {
            gatewayProxy = container "Gateway / Proxy Layer" "Accepts external requests, routes to model servers via EPP selection" "Envoy / AgentGateway / Istio" "gateway"
            epp = container "EPP (Endpoint Picker)" "Core scheduling brain - selects optimal model server pod per request using prefix-cache affinity, load-aware balancing, queue depth" "Go (llm-d-inference-scheduler)" "scheduler"
            inferencePool = container "InferencePool CRD" "Groups model server pods and configures EPP routing behavior" "Kubernetes CRD (GAIE)"
            decodeServer = container "Decode Model Server" "Executes LLM inference (decode phase), serves OpenAI-compatible API" "Python (vLLM) on GPU/CPU" "modelserver"
            prefillServer = container "Prefill Model Server" "Executes prefill phase, transfers KV cache to decode pods via NIXL" "Python (vLLM) on GPU" "modelserver"
            routingSidecar = container "Routing Sidecar" "Routes requests and manages KV transfer between prefill/decode pods" "Go (llm-d-routing-sidecar)"
            udsTokenizer = container "UDS Tokenizer" "Tokenization sidecar for precise prefix cache-aware routing" "Python"
            latencyPredictor = container "Latency Predictor" "XGBoost sidecar for predicted-latency scheduling" "Python (XGBoost)"
            kvCacheIndexer = container "KV Cache Indexer" "Indexes KV cache blocks for precise prefix routing" "Python (ZMQ)"
            wva = container "Workload Variant Autoscaler" "SLO-aware autoscaler that reads Prometheus metrics and manages HPA" "Go (llm-d-workload-variant-autoscaler)"
        }

        // External Systems - Kubernetes Infrastructure
        k8s = softwareSystem "Kubernetes" "Container orchestration platform (1.29+)" "External"
        gatewayAPICRDs = softwareSystem "Gateway API / GAIE" "Gateway API CRDs and Inference Extension CRDs (InferencePool, InferenceObjective, InferenceModelRewrite)" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node GPU workload orchestration for wide expert-parallelism" "External"

        // External Systems - Gateway Implementations
        istio = softwareSystem "Istio" "Service mesh and Gateway API implementation with telemetry" "External"
        agentGateway = softwareSystem "AgentGateway" "Preferred Gateway API implementation for new deployments" "External"

        // External Systems - Storage & Registries
        huggingface = softwareSystem "HuggingFace Hub" "Model weight storage and distribution" "External"
        ghcr = softwareSystem "GitHub Container Registry" "Container image registry (ghcr.io)" "External"

        // External Systems - Observability
        prometheus = softwareSystem "Prometheus" "Metrics collection and querying" "External"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry distributed trace collection" "External"

        // Communication libraries (compiled into images)
        nixl = softwareSystem "NIXL" "Unified communication abstraction for KV cache transfer (NVSHMEM/RIXL/UCX)" "External"
        nvshmem = softwareSystem "NVSHMEM" "GPU collective communication library for wide expert-parallelism" "External"

        // Relationships - People
        datascientist -> llmd "Submits inference requests via OpenAI-compatible API" "HTTP/80"
        platformeng -> llmd "Deploys and configures using Kustomize overlays and Helm values" "kubectl/helm"
        securityeng -> llmd "Reviews security posture, network policies, RBAC" "Documentation"

        // Relationships - Internal
        gatewayProxy -> epp "Queries for optimal endpoint selection" "gRPC ext-proc/9002"
        epp -> inferencePool "Watches pool configuration and objectives" "Kubernetes API"
        epp -> decodeServer "Reads pod metrics for scheduling decisions" "HTTP/8000"
        epp -> prefillServer "Reads pod metrics for scheduling decisions" "HTTP/8000"
        gatewayProxy -> decodeServer "Routes inference requests" "HTTP/8000"
        gatewayProxy -> prefillServer "Routes prefill requests" "HTTP/8000"
        gatewayProxy -> routingSidecar "Routes to decode via sidecar" "HTTP/8000"
        prefillServer -> decodeServer "Transfers KV cache blocks" "NIXL/5600"
        routingSidecar -> decodeServer "Forwards decode requests" "HTTP/8200"
        udsTokenizer -> epp "Provides tokenization" "Unix Domain Socket"
        latencyPredictor -> epp "Provides latency predictions" "HTTP/localhost"
        kvCacheIndexer -> epp "Publishes cache events" "ZMQ PUB/SUB"
        wva -> prometheus "Reads inference metrics for autoscaling" "HTTP/9090"

        // Relationships - External
        llmd -> k8s "Deploys on" "Kubernetes API"
        llmd -> gatewayAPICRDs "Consumes Gateway, HTTPRoute, InferencePool, InferenceObjective CRDs" "Kubernetes API"
        llmd -> lws "Uses for multi-node GPU workloads" "Kubernetes API"
        gatewayProxy -> istio "Implements via Istio GatewayClass" "Envoy"
        gatewayProxy -> agentGateway "Implements via AgentGateway GatewayClass" "Envoy"
        decodeServer -> huggingface "Downloads model weights" "HTTPS/443 (HF_TOKEN)"
        decodeServer -> ghcr "Pulls container images" "HTTPS/443"
        decodeServer -> prometheus "Exposes metrics" "HTTP/8000 /metrics"
        decodeServer -> otelCollector "Exports traces" "gRPC/4317"
        epp -> prometheus "Exposes EPP metrics" "HTTP/9090 /metrics"
        prefillServer -> nixl "Uses for KV transfer abstraction" "Library"
        decodeServer -> nvshmem "Uses for GPU collective communication" "Library"
    }

    views {
        systemContext llmd "SystemContext" {
            include *
            autoLayout
        }

        container llmd "Containers" {
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "gateway" {
                background #d79b00
                color #ffffff
            }
            element "scheduler" {
                background #6c8ebf
                color #ffffff
            }
            element "modelserver" {
                background #82b366
                color #ffffff
            }
        }
    }
}

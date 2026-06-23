workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM models via OpenAI-compatible API"
        sre = person "SRE / Platform Admin" "Manages infrastructure, monitors performance, validates RDMA fabric"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed LLM inference serving stack with intelligent routing, P/D disaggregation, and multi-accelerator support" {
            modelServerCuda = container "llm-d-cuda" "NVIDIA GPU model server — vLLM with CUDA, NIXL, UCX, NVSHMEM, GDRCopy, DeepEP, DeepGEMM, FlashInfer" "Container Image (Dockerfile.cuda)"
            modelServerCpu = container "llm-d-cpu" "CPU-only model server — vLLM with NIXL and UCX" "Container Image (Dockerfile.cpu)"
            modelServerRocm = container "llm-d-rocm" "AMD ROCm model server — vLLM with RIXL and UCX" "Container Image (Dockerfile.rocm)"
            modelServerHpu = container "llm-d-hpu" "Intel Gaudi model server — vLLM-Gaudi" "Container Image (Dockerfile.hpu)"
            rdmaTools = container "llm-d-rdma-tools" "RDMA diagnostic toolkit — iperf3, perftest, NCCL tests, GDRCopy" "Container Image (Dockerfile.rdma-tools)"
            deploymentGuides = container "Deployment Guides" "Kustomize well-lit-path blueprints for optimized baseline, P/D disaggregation, wide-EP, autoscaling, flow control" "Kustomize Overlays"
            deploymentRecipes = container "Deployment Recipes" "Reusable Kustomize bases and components for model servers, gateways, scheduling, monitoring" "Kustomize Bases"
        }

        # Internal Platform Dependencies (sibling repos)
        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Endpoint Picker — intelligent routing with prefix-cache affinity, load-awareness, predicted latency" "Internal llm-d"
        gaie = softwareSystem "Gateway API Inference Extension" "InferencePool CRD — bridges gateway to model server pods via endpoint discovery" "Internal llm-d"
        wva = softwareSystem "Workload Variant Autoscaler" "Cost-aware scaling across heterogeneous hardware variants" "Internal llm-d"
        latencyPredictor = softwareSystem "Latency Predictor" "XGBoost-based TTFT/TPOT prediction for scheduling" "Internal llm-d"
        kvIndexer = softwareSystem "KV-Cache Indexer" "Per-pod KV cache state tracking via ZMQ events" "Internal llm-d"

        # Kubernetes Infrastructure
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Gateway and HTTPRoute CRDs for ingress traffic routing" "Infrastructure"
        envoyProxy = softwareSystem "Envoy / Istio / AgentGateway" "L7 proxy implementing ext-proc for EPP routing decisions" "Infrastructure"
        lws = softwareSystem "LeaderWorkerSet (LWS)" "Multi-node inference coordination for wide expert parallelism" "Infrastructure"

        # Monitoring
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor scrape" "Monitoring"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing telemetry" "Monitoring"
        grafana = softwareSystem "Grafana" "Pre-built dashboards for vLLM, P/D, flow control metrics" "Monitoring"

        # External Services
        hfHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer downloads" "External"
        s3Storage = softwareSystem "S3 / Object Storage" "Model artifact storage for tiered KV cache offloading" "External"

        # In-process Libraries
        nixl = softwareSystem "NIXL" "GPU-Direct RDMA KV cache transfer library" "Library"
        lmcache = softwareSystem "LMCache" "Tiered KV cache offloading (GPU HBM to CPU to storage)" "Library"
        vllm = softwareSystem "vLLM" "Core LLM inference engine (Neural Magic fork)" "Library"

        # Relationships - User interactions
        user -> envoyProxy "Sends inference requests via" "HTTP/HTTPS :80/443"
        sre -> rdmaTools "Validates RDMA fabric with"
        sre -> grafana "Monitors inference performance via"

        # Relationships - Request flow
        envoyProxy -> epp "Consults for routing decisions" "gRPC ext-proc :9002"
        epp -> llmd "Selects optimal model server pod" "HTTP :8000"
        envoyProxy -> llmd "Routes inference request to selected pod" "HTTP :8000"

        # Relationships - llm-d internal
        llmd -> vllm "Embeds as inference engine" "In-process"
        llmd -> nixl "Uses for P/D KV cache transfer" "RDMA :5600"
        llmd -> lmcache "Uses for tiered KV cache offloading" "In-process"

        # Relationships - Infrastructure
        llmd -> gatewayAPI "Consumes Gateway and HTTPRoute CRDs" "Kubernetes API"
        llmd -> gaie "Consumes InferencePool CRD" "Kubernetes API"
        envoyProxy -> gatewayAPI "Implements GatewayClass" "Kubernetes API"

        # Relationships - Platform
        epp -> latencyPredictor "Uses for predicted latency routing" "In-process sidecar"
        epp -> kvIndexer "Uses for KV cache state tracking" "ZMQ events"
        wva -> llmd "Autoscales model server replicas" "HPA/KEDA"
        lws -> llmd "Coordinates multi-node inference" "Kubernetes CRD"

        # Relationships - External
        llmd -> hfHub "Downloads model weights" "HTTPS :443, Bearer HF_TOKEN"
        llmd -> s3Storage "Offloads KV cache to storage" "HTTPS :443"

        # Relationships - Monitoring
        prometheus -> llmd "Scrapes /metrics" "HTTP :8000, 30s"
        llmd -> otelCollector "Exports traces" "gRPC OTLP :4317"
        grafana -> prometheus "Queries metrics" "HTTP :9090"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Monitoring" {
                background #9b59b6
                color #ffffff
            }
            element "Library" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

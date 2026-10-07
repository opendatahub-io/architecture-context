workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and serves LLMs on Kubernetes"
        platformEngineer = person "Platform Engineer" "Configures and manages the inference stack"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack with intelligent routing, KV-cache management, and disaggregated serving" {
            cpuImage = container "vLLM CPU Image" "vLLM model server for CPU inference (x86_64, ARM64) with NIXL and UCX" "Python / Ubuntu 22.04"
            xpuImage = container "vLLM XPU Image" "vLLM model server for Intel Data Center GPUs with LMCache SYCL" "Python / vLLM XPU base"
            rocmImage = container "vLLM ROCm Image" "vLLM model server for AMD Instinct GPUs with NIXL-ROCm, MORI, UCX, UCCL" "Python / vLLM ROCm base"
            rdmaTools = container "RDMA Tools Image" "Network diagnostic and benchmarking toolkit" "C/C++ / UBI9"
            guides = container "Well-Lit-Path Guides" "Tested deployment recipes for 10+ accelerator/engine combinations across 15+ patterns" "Kustomize Overlays + Helm Values"
            recipes = container "Reusable Recipes" "Shared deployment building blocks for model servers, routers, gateways, observability" "Kustomize Bases + Components"
        }

        router = softwareSystem "llm-d-router" "Intelligent LLM-aware request routing (EPP + L7 Proxy) implementing Gateway API Inference Extension" "Internal llm-d"
        kvCache = softwareSystem "llm-d-kv-cache" "Distributed KV cache scheduling and offloading" "Internal llm-d"
        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Prefill/decode routing sidecar for disaggregated serving" "Internal llm-d"
        batchGateway = softwareSystem "llm-d-batch-gateway" "OpenAI-compatible batch API gateway" "Internal llm-d"
        latencyPredictor = softwareSystem "llm-d-latency-predictor" "XGBoost-based predicted-latency scoring for routing" "Internal llm-d"

        vllm = softwareSystem "vLLM" "High-performance LLM inference engine (v0.30.0)" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API + Inference Extension (InferencePool CRD)" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.29+)" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-host model server deployment controller (v0.11.1)" "External"
        keda = softwareSystem "KEDA" "Kubernetes event-driven autoscaling (2.x)" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository" "External"

        dataScientist -> llmd "Deploys models via guides and recipes" "kubectl / kustomize / helm"
        platformEngineer -> llmd "Configures infrastructure and routing"

        llmd -> vllm "Embeds as inference engine" "Container Image"
        llmd -> gatewayAPI "Uses for ingress and InferencePool" "CRD / HTTPRoute"
        llmd -> kubernetes "Deploys workloads" "Kustomize / Helm"
        llmd -> router "Deploys via Helm chart" "Helm / gRPC ext-proc / 9002"
        llmd -> kvCache "Configures for KV offloading" "Container / NIXL"
        llmd -> routingSidecar "Includes for P/D disaggregation" "Kustomize Component"
        llmd -> batchGateway "Deploys for batch workloads" "Container"
        llmd -> latencyPredictor "Configures for routing scoring" "Container"
        llmd -> lws "Uses for multi-host serving" "CRD / LeaderWorkerSet"
        llmd -> keda "Uses for autoscaling" "Prometheus Scaler"
        llmd -> prometheus "Exports metrics" "HTTP /metrics / 8000"
        llmd -> otelCollector "Exports traces" "gRPC OTLP / 4317"
        llmd -> huggingface "Downloads model weights" "HTTPS / 443 / Bearer HF_TOKEN"
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
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Deploys and queries LLM models for inference"
        sre = person "SRE / Platform Admin" "Configures deployment recipes, monitors health"

        llmd = softwareSystem "llm-d" "High-performance distributed LLM inference serving stack with optimized container images and Kubernetes deployment recipes" {
            cudaImage = container "llm-d-cuda" "Production vLLM image for NVIDIA CUDA GPUs with NIXL, UCX, NVSHMEM, DeepEP, DeepGEMM, FlashInfer, LMCache" "Container Image"
            cpuImage = container "llm-d-cpu" "vLLM image for CPU-only inference with NIXL and UCX" "Container Image"
            hpuImage = container "llm-d-hpu" "vLLM image for Intel Gaudi HPUs via vllm-gaudi plugin" "Container Image"
            rocmImage = container "llm-d-rocm" "vLLM image for AMD ROCm GPUs with RIXL and UCX" "Container Image"
            recipes = container "Deployment Recipes" "Composable Kustomize/Helm manifests for model server, scheduler, gateway, and monitoring" "Kustomize/Helm"
        }

        vllm = softwareSystem "vLLM" "Core model serving engine (v0.19.1)" "External"
        nixl = softwareSystem "NIXL" "KV-cache transfer library over RDMA/TCP (v1.0.0)" "External"
        nvshmem = softwareSystem "NVSHMEM" "NVIDIA symmetric heap memory for GPU-to-GPU communication" "External"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Gateway and HTTPRoute CRDs for load balancing" "External"
        inferenceScheduler = softwareSystem "llm-d Inference Scheduler (EPP)" "Endpoint Picker Protocol for intelligent routing (v0.8.0)" "Internal llm-d"
        routingSidecar = softwareSystem "llm-d Routing Sidecar" "P/D disaggregation coordination sidecar (v0.7.1)" "Internal llm-d"
        istio = softwareSystem "Istio" "Service mesh and Gateway API provider" "External"
        agentGateway = softwareSystem "AgentGateway" "Alternative Gateway API provider" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "PodMonitor CRDs for metrics scraping" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "SLO-aware autoscaling of model server replicas" "Internal llm-d"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer downloads" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node GPU workload orchestration" "External"
        lmcache = softwareSystem "LMCache" "Distributed KV-cache with CPU/storage offloading" "External"

        # Relationships
        user -> llmd "Sends inference requests via Gateway API" "HTTP/80"
        sre -> llmd "Deploys and configures via Kustomize/Helm"

        llmd -> vllm "Bundles as model serving engine" "Embedded"
        llmd -> nixl "Uses for KV-cache transfer" "RDMA/TCP 5600"
        llmd -> nvshmem "Uses for GPU-to-GPU communication" "InfiniBand RDMA"
        llmd -> gatewayAPI "Consumes Gateway and HTTPRoute CRDs" "HTTP/80"
        llmd -> inferenceScheduler "Routes requests via EPP" "HTTP/8081"
        llmd -> routingSidecar "Coordinates P/D disaggregation" "HTTP/8000"
        llmd -> istio "Uses as Gateway API provider" "Envoy"
        llmd -> agentGateway "Alternative Gateway provider"
        llmd -> prometheusOperator "Exports metrics via PodMonitor" "HTTP/9090"
        llmd -> otelCollector "Exports distributed traces" "gRPC/4317"
        llmd -> wva "Autoscales model server replicas" "HTTPS/8443"
        llmd -> hfHub "Downloads model weights" "HTTPS/443"
        llmd -> lws "Orchestrates multi-node workloads" "gRPC/5555"
        llmd -> lmcache "Offloads KV-cache to CPU/storage" "Library"
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
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
            element "Kustomize/Helm" {
                background #e8d4f0
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
        }
    }
}

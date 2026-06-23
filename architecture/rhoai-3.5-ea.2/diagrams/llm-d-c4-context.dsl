workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys LLM inference workloads"
        mlops = person "MLOps Engineer" "Deploys and manages inference infrastructure"
        sre = person "SRE" "Monitors and troubleshoots inference clusters"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack for LLMs" {
            cudaImage = container "llm-d-cuda" "Optimized vLLM image for NVIDIA CUDA GPUs with HPC libraries (UCX, UCCL, NVSHMEM, nixl, FlashInfer, DeepEP, DeepGEMM, LMCache)" "Dockerfile + vLLM"
            cpuImage = container "llm-d-cpu" "CPU-only vLLM inference image with multi-arch support" "Dockerfile + vLLM"
            rocmImage = container "llm-d-rocm" "AMD ROCm GPU inference image with RIXL, UCX, UCCL" "Dockerfile + vLLM"
            xpuImage = container "llm-d-xpu" "Intel XPU inference image (thin wrapper over upstream vLLM)" "Dockerfile + vLLM"
            deploymentGuides = container "Deployment Guides" "Composable kustomize recipes and Helm values for model servers, routers, gateways, autoscaling, and observability" "Kustomize + Helm"
            rdmaTools = container "RDMA Tools" "Network diagnostic toolkit (iperf3, perftest, nccl-tests, gdrcopy)" "Dockerfile"
            interactivePod = container "Interactive Pod" "Benchmarking and debugging pod with Python, genai-perf, inference-perf" "Dockerfile + Python"
        }

        llmdRouter = softwareSystem "llm-d Router" "Intelligent request router with Envoy proxy and Endpoint Picker (EPP) for prefix-cache-aware, load-aware routing" "Internal llm-d"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Traffic ingress via Gateway and HTTPRoute CRDs" "External"
        gaie = softwareSystem "Gateway API Inference Extension (GAIE)" "InferencePool CRD for model server pool management" "Internal llm-d"
        vllm = softwareSystem "vLLM" "High-throughput LLM serving engine" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        kgateway = softwareSystem "kgateway" "Gateway implementation" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.29+)" "External"
        helm = softwareSystem "Helm" "Kubernetes package manager for router deployment" "External"
        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy with ext_proc for intelligent routing" "External"

        hfHub = softwareSystem "Hugging Face Hub" "Model weight repository" "External"
        s3 = softwareSystem "S3/GCS Storage" "Model artifact storage" "External"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry telemetry collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "External"

        ucx = softwareSystem "UCX" "Unified Communication X for RDMA transport (v1.20.0)" "External HPC"
        uccl = softwareSystem "UCCL" "Unified Collective Communication Library (v0.1.1)" "External HPC"
        nvshmem = softwareSystem "NVSHMEM" "NVIDIA SHMEM for GPU communication (v3.4.5)" "External HPC"
        nixl = softwareSystem "nixl" "NVIDIA Inter-node Exchange Library for KV transfer (v1.2.0)" "External HPC"
        flashinfer = softwareSystem "FlashInfer" "High-performance attention kernels (v0.6.12)" "External HPC"
        deepep = softwareSystem "DeepEP" "Expert parallelism MoE kernels" "External HPC"
        deepgemm = softwareSystem "DeepGEMM" "GEMM kernels for MoE workloads" "External HPC"
        lmcache = softwareSystem "LMCache" "KV cache connector for tiered offloading (v0.4.6)" "External HPC"

        # User interactions
        datascientist -> llmd "Deploys models via kustomize recipes and sends inference requests"
        mlops -> llmd "Manages container image builds and deployment configurations"
        sre -> llmd "Monitors via Prometheus/OTEL and debugs via interactive-pod and RDMA tools"

        # Internal dependencies
        llmd -> llmdRouter "Deploys via Helm charts, routes inference requests" "HTTP/gRPC"
        llmd -> gaie "Uses InferencePool CRD for pod grouping" "Kubernetes CRD"
        llmd -> vllm "Compiles from source into container images" "Build-time"
        llmd -> envoyProxy "Deployed as L7 proxy via Helm, ext_proc integration" "HTTP/gRPC"

        # External dependencies
        llmd -> gatewayAPI "Traffic ingress via Gateway/HTTPRoute CRDs" "HTTP/80"
        llmd -> kubernetes "Container orchestration, pod scheduling" "HTTPS/6443"
        llmd -> helm "Router deployment via Helm charts" "CLI"
        llmd -> istio "Optional service mesh, mTLS, telemetry" "Configurable"
        llmd -> kgateway "Optional Gateway implementation" "Configurable"

        # Compiled HPC libraries
        llmd -> ucx "Compiled into CUDA/ROCm images for RDMA" "Build-time"
        llmd -> uccl "Compiled into CUDA/ROCm images for collective comms" "Build-time"
        llmd -> nvshmem "Compiled into CUDA image for GPU shared memory" "Build-time"
        llmd -> nixl "Compiled into CUDA/CPU images for KV transfer" "Build-time/5600 TCP"
        llmd -> flashinfer "Compiled into CUDA image for attention" "Build-time"
        llmd -> deepep "Compiled into CUDA image for expert parallelism" "Build-time"
        llmd -> deepgemm "Compiled into CUDA image for MoE GEMM" "Build-time"
        llmd -> lmcache "Compiled into CUDA image for KV cache offload" "Build-time"

        # External service integrations
        llmd -> hfHub "Downloads model weights at startup" "HTTPS/443 Bearer Token"
        llmd -> s3 "Loads model artifacts from storage" "HTTPS/443 IAM"
        llmd -> otelCollector "Exports distributed traces" "gRPC OTLP/4317"
        llmd -> prometheus "Exposes metrics via /metrics endpoint" "HTTP/8000"
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
            element "External HPC" {
                background #76b5c5
                color #ffffff
            }
            element "Internal llm-d" {
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
        }
    }
}

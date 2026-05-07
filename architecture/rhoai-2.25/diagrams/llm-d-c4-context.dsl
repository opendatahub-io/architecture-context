workspace {
    model {
        # Personas
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        platformEngineer = person "Platform Engineer" "Configures and manages the llm-d inference stack on OpenShift"

        # Primary System
        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack with optimized container images, deployment recipes, and multi-accelerator support" {
            buildSystem = container "Build System" "Multi-stage Dockerfile builds, Makefile orchestration for multi-arch/multi-OS container images" "Shell, Dockerfile"
            cudaImage = container "CUDA Container Image" "Production vLLM image with CUDA, NIXL, UCX, NVSHMEM, FlashInfer, DeepEP, DeepGEMM, LMCache" "Python, C/C++"
            rocmImage = container "ROCm Container Image" "vLLM image for AMD GPUs with RIXL, UCX, RDMA support" "Python, C/C++"
            hpuImage = container "HPU Container Image" "vLLM image for Intel Gaudi accelerators via vllm-gaudi plugin" "Python"
            cpuImage = container "CPU Container Image" "vLLM image for CPU-only inference with NIXL and UCX" "Python, C/C++"
            deploymentRecipes = container "Deployment Recipes" "Helm charts and Kustomize overlays for Gateway, Router, and model server topologies" "YAML, Helm, Kustomize"
        }

        # Internal Platform Dependencies
        epp = softwareSystem "llm-d Router (EPP)" "Endpoint Picker for intelligent request routing using KV-cache, queue depth, and prefix cache signals" "Internal RHOAI"
        gatewayController = softwareSystem "Gateway API Controller" "L7 proxy (Envoy/Istio/AgentGateway) implementing Gateway API for inference traffic routing" "Internal Platform"
        gatewayAPICRDs = softwareSystem "Gateway API Inference Extension" "InferencePool and InferenceModel CRDs defining routing topology" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection from vLLM model servers for monitoring and autoscaling" "Internal Platform"
        grafana = softwareSystem "Grafana" "Visualization dashboards for inference performance metrics" "Internal Platform"
        hpaKeda = softwareSystem "HPA / KEDA" "Metrics-driven autoscaling for model server replicas" "Internal Platform"
        wva = softwareSystem "Workload Variant Autoscaler" "SLO-aware autoscaling for heterogeneous hardware and multiple model variants" "Internal Platform"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node model server orchestration for wide expert-parallelism" "Internal Platform"

        # External Dependencies
        vllm = softwareSystem "vLLM" "Model serving engine (v0.19.1) — core runtime compiled into container images" "External"
        kubernetes = softwareSystem "Kubernetes" "Infrastructure orchestration, workload management, API server" "External"
        nixl = softwareSystem "NIXL" "GPU-to-GPU KV cache transfer via RDMA for prefill/decode disaggregation" "External"
        ucx = softwareSystem "UCX" "Unified Communication X transport layer for RDMA" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository for downloading LLM artifacts" "External"
        containerRegistry = softwareSystem "Container Registry (ghcr.io)" "Container image storage and distribution" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection via OTLP gRPC" "External"
        s3Storage = softwareSystem "sccache S3 Bucket" "Build cache storage for CI/CD compilation speedup" "External"

        # Relationships - Users
        dataScientist -> llmd "Deploys models and sends inference requests"
        platformEngineer -> llmd "Configures deployment recipes and container builds"

        # Relationships - Build System
        buildSystem -> vllm "Compiles from source (commit SHA pinned)" "HTTPS/443"
        buildSystem -> nixl "Compiles from source (v1.0.0)" "HTTPS/443"
        buildSystem -> ucx "Compiles from source (v1.20.0)" "HTTPS/443"
        buildSystem -> containerRegistry "Pushes built images" "HTTPS/443"
        buildSystem -> s3Storage "Read/write build cache" "HTTPS/443"
        buildSystem -> cudaImage "Produces"
        buildSystem -> rocmImage "Produces"
        buildSystem -> hpuImage "Produces"
        buildSystem -> cpuImage "Produces"

        # Relationships - Runtime
        cudaImage -> huggingface "Downloads model weights at startup" "HTTPS/443"
        cudaImage -> otelCollector "Exports distributed traces" "gRPC OTLP/4317"
        deploymentRecipes -> epp "Deploys via Helm chart"
        deploymentRecipes -> gatewayController "Deploys via Helm chart"
        deploymentRecipes -> cudaImage "Deploys via Kustomize"

        # Relationships - Platform Integration
        epp -> gatewayAPICRDs "Watches InferencePool, InferenceModel CRDs"
        epp -> kubernetes "Pod/endpoint discovery" "HTTPS/6443"
        epp -> cudaImage "Scrapes metrics for scheduling decisions" "HTTP/8000"
        gatewayController -> epp "ext-proc routing decisions" "gRPC/9002"
        gatewayController -> cudaImage "Forwards inference requests" "HTTP/8000"
        prometheus -> cudaImage "Scrapes /metrics endpoint" "HTTP/8000"
        grafana -> prometheus "Queries metrics"
        hpaKeda -> prometheus "Reads metrics for autoscaling"
        wva -> kubernetes "Custom controller for SLO-aware scaling"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
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
        }
    }
}

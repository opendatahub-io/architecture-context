workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference endpoints"
        platformengineer = person "Platform Engineer" "Deploys and operates llm-d infrastructure"

        llmd = softwareSystem "llm-d" "High-performance distributed LLM inference serving stack for Kubernetes" {
            cudaImage = container "llm-d-cuda" "vLLM runtime with CUDA GPU support, NVSHMEM, UCX, NIXL, DeepEP, FlashInfer, LMCache" "Container Image (Python/CUDA)"
            cpuImage = container "llm-d-cpu" "vLLM runtime for CPU-only inference with NIXL/UCX" "Container Image (Python)"
            hpuImage = container "llm-d-hpu" "vLLM runtime for Intel Gaudi HPU with vllm-gaudi plugin" "Container Image (Python)"
            rocmImage = container "llm-d-rocm" "vLLM runtime for AMD ROCm GPUs with RIXL" "Container Image (Python/ROCm)"
            rdmaTools = container "llm-d-rdma-tools" "Diagnostic image with RDMA/InfiniBand testing tools" "Container Image (C)"
            deploymentGuides = container "Deployment Guides" "Kustomize bases, overlays, Helm values for well-lit-path deployments" "Kustomize + Helm"
        }

        epp = softwareSystem "llm-d Inference Scheduler (EPP)" "Intelligent request router with ext-proc interface for Gateway API" "Internal Platform"
        gatewayController = softwareSystem "Gateway Controller" "L7 proxy (Envoy, Istio, agentgateway, kgateway) handling ingress and ext-proc" "External"
        gatewayAPI = softwareSystem "Gateway API + Inference Extension" "Kubernetes CRDs: Gateway, HTTPRoute, InferencePool, InferenceObjective" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.28+)" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing aggregation" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository" "External"
        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "SLO-driven autoscaling across heterogeneous hardware" "Internal Platform"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node expert parallelism pod groups" "External"

        # Relationships
        datascientist -> llmd "Sends inference requests via" "HTTP/HTTPS"
        platformengineer -> llmd "Deploys and configures via" "kubectl/kustomize/helm"

        llmd -> epp "Receives routing decisions from" "ext-proc gRPC"
        llmd -> gatewayController "Traffic routed through" "HTTP 8000/TCP"
        llmd -> gatewayAPI "Configured via" "Gateway, HTTPRoute, InferencePool CRDs"
        llmd -> kubernetes "Deployed on" "Kubernetes API 443/TCP HTTPS"
        llmd -> prometheus "Exposes metrics to" "HTTP 8000/TCP, 9090/TCP"
        llmd -> otelCollector "Exports traces to" "gRPC 4317/TCP"
        llmd -> huggingface "Downloads model weights from" "HTTPS 443/TCP, Bearer HF_TOKEN"

        epp -> llmd "Scrapes model server metrics" "HTTP 8000/TCP"
        epp -> kubernetes "Watches Pods, InferencePool CRDs" "HTTPS 443/TCP mTLS"
        gatewayController -> epp "Delegates routing via" "ext-proc gRPC"

        wva -> prometheus "Queries metrics for autoscaling" "HTTPS 443/TCP"
        wva -> kubernetes "Scales model server replicas" "Kubernetes API"

        # Container-level relationships
        cudaImage -> huggingface "Downloads model weights" "HTTPS 443/TCP"
        cudaImage -> otelCollector "Exports traces" "gRPC 4317/TCP"
        deploymentGuides -> epp "Deploys EPP via Helm charts" "Helm values"
        deploymentGuides -> gatewayAPI "Creates Gateway/HTTPRoute/InferencePool CRs" "kubectl apply"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

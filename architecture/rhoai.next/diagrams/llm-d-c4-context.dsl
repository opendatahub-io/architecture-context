workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM models for inference"
        platformEngineer = person "Platform Engineer" "Deploys and operates the llm-d inference stack"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack — container images, deployment recipes, and orchestration patterns for production-scale LLM serving" {
            cudaImage = container "llm-d-cuda" "Multi-stage CUDA image with vLLM, NIXL, UCX, NVSHMEM, DeepEP, DeepGEMM, FlashInfer, LMCache, OTEL" "Container Image (Dockerfile)"
            cpuImage = container "llm-d-cpu" "CPU-only vLLM image with NIXL/UCX" "Container Image (Dockerfile)"
            hpuImage = container "llm-d-hpu" "vLLM-Gaudi image for Intel Habana accelerators" "Container Image (Dockerfile)"
            rocmImage = container "llm-d-rocm" "vLLM image for AMD ROCm GPUs with RIXL/UCX" "Container Image (Dockerfile)"
            rdmaTools = container "llm-d-rdma-tools" "Diagnostic image for RDMA network validation" "Container Image (Dockerfile)"
            deploymentRecipes = container "Deployment Recipes" "Kustomize bases/overlays for model server topologies (single-host, P/D, wide-EP)" "Kustomize"
            gatewayRecipes = container "Gateway Recipes" "Gateway API configs for Istio, agentgateway, GKE" "Kustomize/YAML"
            schedulerValues = container "Scheduler Configuration" "Helm values for EPP plugin chains, scoring profiles" "Helm Values"
        }

        vllm = softwareSystem "vLLM" "High-performance LLM serving engine with OpenAI-compatible API" "External Upstream"
        nixl = softwareSystem "NIXL" "High-performance data transfer library for KV cache disaggregation" "External Upstream"
        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Endpoint Picker extension for intelligent inference load balancing" "Internal Platform"
        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Routing proxy sidecar for P/D decode coordination" "Internal Platform"
        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "SLO-aware autoscaling for model server instances" "Internal Platform"

        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Ingress and routing control plane (Gateway, HTTPRoute CRDs)" "External"
        inferenceGW = softwareSystem "Kubernetes Inference Gateway Extension" "InferencePool, InferenceObjective, EndpointPickerConfig CRDs" "External"
        istio = softwareSystem "Istio" "Service mesh and Gateway API provider" "External"
        agentgateway = softwareSystem "agentgateway (kgateway)" "Alternative Gateway API implementation" "External"
        gkeGateway = softwareSystem "GKE Gateway" "Google Cloud Gateway API implementation" "External"
        lws = softwareSystem "LeaderWorkerSet Controller" "Multi-node workload management for expert parallelism" "External"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        grafana = softwareSystem "Grafana" "Metrics visualization dashboards" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        jaeger = softwareSystem "Jaeger" "Distributed trace visualization" "External"

        hfHub = softwareSystem "HuggingFace Hub" "Model weight repository" "External"
        rdmaFabric = softwareSystem "RDMA/InfiniBand Fabric" "GPU-to-GPU high-speed interconnect" "External"

        # User interactions
        dataScientist -> llmd "Sends inference requests via HTTP/80"
        platformEngineer -> llmd "Deploys and configures via Kustomize/Helm"

        # Core runtime dependencies
        llmd -> vllm "Embeds as model serving engine" "Container runtime"
        llmd -> nixl "Embeds for KV cache transfer" "Library / 5600/TCP"
        llmd -> epp "Routes requests through" "gRPC/9002 ext_proc"
        llmd -> routingSidecar "Coordinates P/D decode via" "HTTP/8000 init container"
        llmd -> wva "Autoscales with" "Kubernetes API"

        # Infrastructure dependencies
        llmd -> gatewayAPI "Uses for ingress" "Kubernetes API (Gateway, HTTPRoute)"
        llmd -> inferenceGW "Uses for pool management" "Kubernetes API (InferencePool, InferenceObjective)"
        llmd -> istio "Uses as gateway provider" "Kubernetes API"
        llmd -> agentgateway "Uses as gateway provider" "Kubernetes API"
        llmd -> gkeGateway "Uses as gateway provider" "Kubernetes API"
        llmd -> lws "Uses for multi-node groups" "Kubernetes API (LeaderWorkerSet)"

        # Observability
        llmd -> prometheus "Exposes metrics" "HTTP/8000 + 9002 scrape"
        llmd -> otelCollector "Exports traces" "gRPC/4317 OTLP"
        otelCollector -> jaeger "Forwards traces" "HTTP"
        prometheus -> grafana "Feeds dashboards" "HTTP"

        # External services
        llmd -> hfHub "Downloads model weights" "HTTPS/443 + HF_TOKEN"
        llmd -> rdmaFabric "Transfers KV cache via GPU-Direct" "RDMA/IB (L2)"
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
            element "External Upstream" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #000000
            }
            element "Container Image (Dockerfile)" {
                background #76b900
                color #000000
            }
            element "Kustomize" {
                background #d5e8d4
                color #000000
            }
            element "Kustomize/YAML" {
                background #d5e8d4
                color #000000
            }
            element "Helm Values" {
                background #fff2cc
                color #000000
            }
        }
    }
}

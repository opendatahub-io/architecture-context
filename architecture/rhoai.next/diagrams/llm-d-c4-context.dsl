workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM models for inference"
        platformeng = person "Platform Engineer" "Configures and operates the inference platform"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack with optimized container images, deployment recipes, and orchestration patterns for production-scale LLM serving" {
            cudaImage = container "llm-d-cuda" "Multi-stage CUDA-based vLLM image with NIXL, UCX, NVSHMEM, DeepEP, DeepGEMM, FlashInfer, LMCache, OTEL" "Container Image (Dockerfile)"
            cpuImage = container "llm-d-cpu" "CPU-only vLLM image with NIXL/UCX" "Container Image (Dockerfile)"
            hpuImage = container "llm-d-hpu" "vLLM-Gaudi image for Intel Habana accelerators" "Container Image (Dockerfile)"
            rocmImage = container "llm-d-rocm" "vLLM image for AMD ROCm GPUs with RIXL and UCX" "Container Image (Dockerfile)"
            deploymentRecipes = container "Deployment Recipes" "Kustomize bases and overlays for single-host, P/D disaggregation, wide-EP topologies" "Kustomize Manifests"
            gatewayRecipes = container "Gateway Recipes" "Gateway API configurations for Istio, agentgateway, GKE" "Kustomize/YAML"
            schedulerConfig = container "Scheduler Configuration" "Helm values for EPP plugin chains and scoring profiles" "Helm Values"
            wellLitPaths = container "Well-Lit Path Guides" "End-to-end deployment guides with manifests" "Documentation + YAML"
        }

        vllm = softwareSystem "vLLM" "Model serving engine - core inference runtime (OpenAI-compatible API)" "External"
        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Endpoint Picker extension - intelligent load balancing via ext_proc" "Internal Platform"
        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Routing proxy sidecar for P/D disaggregation coordination" "Internal Platform"
        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "SLO-aware autoscaling of model server instances" "Internal Platform"
        nixl = softwareSystem "NIXL" "High-performance KV cache transfer library for disaggregated serving" "External"
        nvshmem = softwareSystem "NVSHMEM" "NVIDIA symmetric memory for GPU-to-GPU expert parallelism" "External"

        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Gateway, HTTPRoute CRDs for ingress and routing" "External"
        inferenceGW = softwareSystem "Kubernetes Inference Gateway Extension" "InferencePool, InferenceObjective, EndpointPickerConfig CRDs" "External"
        istio = softwareSystem "Istio" "Service mesh and Gateway API provider" "External"
        agentgateway = softwareSystem "agentgateway (kgateway)" "Alternative Gateway API provider" "External"
        gkeGateway = softwareSystem "GKE Gateway" "Google Cloud Gateway API implementation" "External"
        lws = softwareSystem "LeaderWorkerSet Controller" "Multi-node workload management for expert parallelism" "External"

        huggingface = softwareSystem "HuggingFace Hub" "Model weight storage and download" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        grafana = softwareSystem "Grafana" "Metrics visualization dashboards" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        jaeger = softwareSystem "Jaeger" "Distributed trace visualization" "External"

        datascientist -> llmd "Deploys models using deployment recipes"
        datascientist -> vllm "Sends inference requests via OpenAI API" "HTTP/8000"
        platformeng -> llmd "Configures deployment topologies and gateway routing"

        llmd -> vllm "Provides optimized container images for" "Container Runtime"
        llmd -> epp "Configures via Helm values" "Helm"
        llmd -> routingSidecar "Deploys as init container on decode pods" "Kustomize"
        llmd -> gatewayAPI "Consumes Gateway and HTTPRoute CRDs" "Kubernetes API"
        llmd -> inferenceGW "Consumes InferencePool and InferenceObjective CRDs" "Kubernetes API"
        llmd -> lws "Consumes LeaderWorkerSet CRD for wide-EP" "Kubernetes API"

        epp -> vllm "Routes requests to selected backend" "gRPC ext_proc/9002 → HTTP/8000"
        vllm -> nixl "Transfers KV cache between instances" "RDMA/TCP/5600"
        vllm -> nvshmem "GPU-to-GPU collective communication" "IB/RoCE RDMA"
        vllm -> huggingface "Downloads model weights" "HTTPS/443"
        vllm -> otelCollector "Exports traces" "OTLP gRPC/4317"
        prometheus -> vllm "Scrapes /metrics endpoint" "HTTP/8000"
        prometheus -> epp "Scrapes metrics" "HTTP/9002"
        grafana -> prometheus "Queries metrics" "HTTP/9090"
        otelCollector -> jaeger "Forwards traces" "HTTP/16686"

        istio -> gatewayAPI "Implements Gateway API"
        agentgateway -> gatewayAPI "Implements Gateway API"
        gkeGateway -> gatewayAPI "Implements Gateway API"

        wva -> vllm "Autoscales model server instances" "Kubernetes API"
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
            element "Internal Platform" {
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
        }
    }
}

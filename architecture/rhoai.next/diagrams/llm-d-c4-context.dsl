workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and serves LLM models for inference"
        client = person "API Consumer" "Sends inference requests to deployed models"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack providing optimized container images, deployment recipes, and orchestration patterns for production-scale LLM serving" {
            cudaImage = container "llm-d-cuda" "Multi-stage CUDA vLLM image with NIXL, UCX, NVSHMEM, DeepEP, DeepGEMM, FlashInfer, LMCache, OTEL" "Container Image"
            cpuImage = container "llm-d-cpu" "CPU-only vLLM image with NIXL/UCX" "Container Image"
            hpuImage = container "llm-d-hpu" "Intel Gaudi vLLM image with NIXL" "Container Image"
            rocmImage = container "llm-d-rocm" "AMD ROCm vLLM image with RIXL/UCX" "Container Image"
            deploymentRecipes = container "Deployment Recipes" "Kustomize bases/overlays for single-host, P/D disaggregation, wide-EP topologies" "Kustomize"
            gatewayRecipes = container "Gateway Recipes" "Gateway API configurations for Istio, kgateway, agentgateway, GKE" "Kustomize/YAML"
            schedulerValues = container "Scheduler Values" "Helm values for EPP plugin chains, scoring profiles" "Helm Values"
        }

        vllm = softwareSystem "vLLM" "High-throughput LLM serving engine with OpenAI-compatible API" "External"
        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Endpoint Picker extension for intelligent load balancing via Gateway ext_proc" "Internal llm-d"
        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Prefill/decode coordination sidecar for disaggregated serving" "Internal llm-d"
        wva = softwareSystem "Workload Variant Autoscaler" "SLO-aware autoscaling for model server instances" "Internal llm-d"
        nixl = softwareSystem "NIXL" "High-performance KV cache transfer library for disaggregated serving" "External"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Standard API for ingress and traffic routing" "External"
        inferenceGateway = softwareSystem "K8s Inference Gateway Extension" "InferencePool, InferenceObjective, EndpointPickerConfig CRDs" "External"
        istio = softwareSystem "Istio" "Service mesh and Gateway API provider with ext_proc support" "External"
        agentgateway = softwareSystem "agentgateway (kgateway)" "Alternative Gateway API provider" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        grafana = softwareSystem "Grafana" "Metrics visualization dashboards" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        jaeger = softwareSystem "Jaeger" "Distributed trace visualization" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository" "External"
        lws = softwareSystem "LeaderWorkerSet Controller" "Multi-node workload management for expert parallelism" "External"
        certManager = softwareSystem "cert-manager" "Certificate management" "External"

        # User interactions
        user -> llmd "Deploys models using Kustomize recipes and Helm values"
        client -> llmd "Sends inference requests via Gateway"

        # Internal relationships
        llmd -> vllm "Bundles as model serving engine inside container images"
        llmd -> epp "Configures via Helm values for request routing"
        llmd -> routingSidecar "Deploys as init container on decode pods for P/D disaggregation"
        llmd -> nixl "Bundles for KV cache transfer between prefill/decode instances" "RDMA/TCP port 5600"
        llmd -> gatewayAPI "Configures Gateway and HTTPRoute CRDs" "Kubernetes API"
        llmd -> inferenceGateway "Configures InferencePool and InferenceObjective CRDs" "Kubernetes API"
        llmd -> wva "Configures for workload autoscaling" "Kubernetes API"

        # External dependencies
        llmd -> istio "Uses as Gateway API provider" "Kubernetes API"
        llmd -> agentgateway "Uses as alternative Gateway API provider" "Kubernetes API"
        llmd -> lws "Uses for multi-node expert parallelism" "Kubernetes API"
        llmd -> huggingface "Downloads model weights at startup" "HTTPS port 443"
        llmd -> otelCollector "Exports distributed traces" "gRPC OTLP port 4317"
        llmd -> prometheus "Exposes metrics for scraping" "HTTP port 8000"

        # Observability chain
        prometheus -> grafana "Provides data for dashboards"
        otelCollector -> jaeger "Forwards traces for visualization"

        # EPP integration
        epp -> llmd "Routes requests to selected backend" "gRPC ext_proc port 9002"
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
                color #000000
            }
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
            element "Kustomize" {
                background #f5a623
                color #000000
            }
            element "Helm Values" {
                background #f5a623
                color #000000
            }
            element "Kustomize/YAML" {
                background #f5a623
                color #000000
            }
        }
    }
}

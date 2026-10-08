workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and serves LLMs at scale"
        platformEngineer = person "Platform Engineer" "Configures and manages llm-d infrastructure"

        llmd = softwareSystem "llm-d" "CNCF sandbox distributed inference serving stack for LLMs on Kubernetes" {
            dockerfiles = container "Container Images" "Dockerfiles for vLLM model servers (CPU, ROCm, XPU, RDMA tools)" "Docker"
            guides = container "Deployment Guides" "Kustomize overlays and Helm values across accelerator × engine × provider matrix" "Kustomize + Helm"
            recipes = container "Recipes" "Composable Kustomize components (monitoring, shutdown, cache, RDMA)" "Kustomize"
            proposals = container "Proposals" "Feature design documents for new components" "Markdown"
        }

        llmdRouter = softwareSystem "llm-d-router" "Intelligent request routing: Envoy/agentgateway proxy + Endpoint Picker (EPP)" "Internal llm-d"
        llmdKVCache = softwareSystem "llm-d-kv-cache" "Distributed KV cache indexing with tiered offloading and P2P sharing" "Internal llm-d"
        llmdRoutingSidecar = softwareSystem "llm-d-routing-sidecar" "Prefill/decode disaggregation request orchestration sidecar" "Internal llm-d"
        llmdBatchGateway = softwareSystem "llm-d-batch-gateway" "OpenAI-compatible batch API and processing" "Internal llm-d"
        llmdAsync = softwareSystem "llm-d-async" "Asynchronous request queue and dispatch" "Internal llm-d"
        llmdLatencyPredictor = softwareSystem "llm-d-latency-predictor" "XGBoost-based latency prediction for SLO-aware routing" "Internal llm-d"

        vllm = softwareSystem "vLLM" "High-throughput LLM serving engine (v0.30.0)" "External"
        gatewayAPI = softwareSystem "Gateway API + Inference Extension" "Kubernetes L4/L7 networking with InferencePool CRD" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.29+)" "External"
        nixl = softwareSystem "NIXL" "KV cache transfer library over RDMA (InfiniBand/RoCE)" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for model servers" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Model weight registry and download" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otel = softwareSystem "OpenTelemetry" "Distributed tracing and observability" "External"

        dataScientist -> llmd "Deploys models using guides and recipes"
        platformEngineer -> llmd "Configures infrastructure, accelerators, and routing"

        llmd -> llmdRouter "Deploys via Helm chart" "Helm"
        llmd -> llmdKVCache "Coordinates KV cache infrastructure"
        llmd -> llmdRoutingSidecar "Configures P/D disaggregation"
        llmd -> llmdBatchGateway "Configures batch processing"
        llmd -> llmdAsync "Configures async dispatch"
        llmd -> llmdLatencyPredictor "Configures latency prediction"

        dockerfiles -> vllm "Builds from source" "Git + pip"
        guides -> gatewayAPI "Creates InferencePool + HTTPRoute" "Kustomize"
        guides -> kubernetes "Deploys model server pods" "Kustomize"
        llmdRouter -> gatewayAPI "ext-proc endpoint selection" "gRPC/9002"
        llmdRoutingSidecar -> nixl "KV cache RDMA transfer" "InfiniBand/RoCE"
        llmd -> keda "Autoscales model servers" "ScaledObject"
        llmd -> huggingface "Downloads model weights" "HTTPS/443"
        llmd -> prometheus "Exports metrics" "HTTP/8000"
        llmd -> otel "Exports traces" "gRPC/4317"
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
                background #ab47bc
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
        }
    }
}

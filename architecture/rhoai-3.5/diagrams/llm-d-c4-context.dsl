workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys LLM models for inference"
        sre = person "SRE / Platform Engineer" "Operates and monitors llm-d deployments"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed LLM inference serving stack with intelligent routing, KV-cache management, and autoscaling" {
            cudaImage = container "llm-d-cuda" "vLLM model server with NVIDIA CUDA, NIXL, UCCL, NVSHMEM, DeepEP, DeepGEMM, FlashInfer, LMCache" "Container Image (Python/C++/CUDA)" "Image"
            gb200Image = container "llm-d-cuda-gb200" "Blackwell-specific variant of llm-d-cuda" "Container Image" "Image"
            cpuImage = container "llm-d-cpu" "CPU-only vLLM model server with NIXL, UCX" "Container Image (Python)" "Image"
            rocmImage = container "llm-d-rocm" "AMD ROCm vLLM model server with NIXL, UCX, UCCL, Mori" "Container Image (Python/C++)" "Image"
            xpuImage = container "llm-d-xpu" "Intel XPU vLLM model server with LMCache" "Container Image (Python)" "Image"
            deploymentGuides = container "Well-Lit Path Guides" "Kustomize manifests and Helm values for all deployment patterns" "Kustomize/YAML" "Docs"
        }

        epp = softwareSystem "llm-d-inference-scheduler" "EPP routing engine — request placement via ext-proc gRPC" "Internal llm-d"
        kvcache = softwareSystem "llm-d-kv-cache" "KV-cache block indexer and filesystem offloading connector" "Internal llm-d"
        latpredictor = softwareSystem "llm-d-latency-predictor" "XGBoost predicted latency server for routing decisions" "Internal llm-d"
        wva = softwareSystem "llm-d-workload-variant-autoscaler" "SLO-aware workload autoscaler" "Internal llm-d"
        asyncProc = softwareSystem "llm-d-async" "Asynchronous request processor for batch inference" "Internal llm-d"
        batchgw = softwareSystem "llm-d-batch-gateway" "OpenAI-compatible batch API gateway" "Internal llm-d"

        gateway = softwareSystem "Gateway/Proxy" "Istio, AgentGateway, Envoy AI Gateway, or GKE L7" "External"
        gaie = softwareSystem "Gateway API Inference Extension" "InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "External"
        vllm = softwareSystem "vLLM" "Core inference engine (neuralmagic fork v0.23.0)" "External"
        nixl = softwareSystem "NIXL" "GPU-to-GPU KV-cache transfer library" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otel = softwareSystem "OpenTelemetry" "Distributed tracing" "External"
        s3 = softwareSystem "Object Storage" "Model artifact storage (S3, GCS, etc.)" "External"

        datascientist -> llmd "Deploys InferenceService, sends inference requests"
        sre -> llmd "Monitors, configures autoscaling, manages deployments"

        llmd -> gateway "Receives routed traffic" "HTTP/8000"
        gateway -> epp "Routes via ext-proc" "gRPC/9002"
        epp -> llmd "Scrapes metrics for routing decisions" "HTTP/8000"

        llmd -> kvcache "KV-cache block distribution tracking" "ZeroMQ"
        llmd -> nixl "GPU-to-GPU KV transfer" "RDMA/TCP"
        epp -> latpredictor "Predicted latency queries" "gRPC"
        wva -> llmd "SLO-aware scaling decisions" "Kubernetes API"
        asyncProc -> llmd "Async request dispatch" "Redis"
        batchgw -> asyncProc "Batch API requests" "HTTP"

        llmd -> huggingface "Downloads model weights" "HTTPS/443"
        llmd -> s3 "Loads model artifacts" "HTTPS/443"
        prometheus -> llmd "Scrapes /metrics endpoint" "HTTP/8000"
        llmd -> otel "Exports traces" "OTLP"
        llmd -> gaie "Uses InferencePool/InferenceObjective CRDs" "Kubernetes API"
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
            element "Image" {
                shape RoundedBox
            }
            element "Docs" {
                shape Folder
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

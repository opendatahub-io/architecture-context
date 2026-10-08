workspace {
    model {
        user = person "ML Engineer" "Deploys and queries LLM models for inference"

        llmd = softwareSystem "llm-d" "High-performance distributed LLM inference serving stack for Kubernetes" {
            vllmCPU = container "vLLM CPU Image" "Model server for CPU inference with NIXL and UCX" "Python (vLLM)" "Container"
            vllmROCm = container "vLLM ROCm Image" "Model server for AMD Instinct GPUs with UCCL, NIXL, MORI" "Python (vLLM)" "Container"
            vllmXPU = container "vLLM XPU Image" "Model server for Intel GPUs with LMCache SYCL" "Python (vLLM)" "Container"
            rdmaTools = container "RDMA Tools" "Diagnostic sidecar for network validation" "C/C++" "Sidecar"
            podSnapshot = container "Pod Snapshot Launcher" "GKE Fast Pod Snapshotting for cold-start optimization" "Python" "Module"
            guideSystem = container "Guide System" "Declarative deployment recipes via kustomize and Helm" "YAML" "Configuration"
        }

        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Ingress entry point for inference traffic" "External"
        gaie = softwareSystem "Gateway API Inference Extension" "InferencePool and model-level routing CRDs" "External"
        llmdRouter = softwareSystem "llm-d-router" "Intelligent request routing with prefix-cache affinity" "Internal llm-d"
        llmdRoutingSidecar = softwareSystem "llm-d-routing-sidecar" "Prefill/decode routing sidecar" "Internal llm-d"
        llmdKVCache = softwareSystem "llm-d-kv-cache" "Distributed KV-cache scheduling and tiered offloading" "Internal llm-d"
        llmdAutoscaler = softwareSystem "llm-d-workload-variant-autoscaler" "SLO-aware autoscaling of model-server replicas" "Internal llm-d"
        llmdLatencyPredictor = softwareSystem "llm-d-latency-predictor" "Predicted-latency scoring for request scheduling" "Internal llm-d"
        llmdBatchGateway = softwareSystem "llm-d-batch-gateway" "OpenAI-compatible batch API processing" "Internal llm-d"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight storage and distribution" "External"
        ghcr = softwareSystem "GitHub Container Registry" "Container images and Helm charts" "External"

        user -> llmd "Sends inference requests via HTTP"
        user -> llmd "Deploys models using kustomize/Helm guides"
        llmd -> gatewayAPI "Exposes inference endpoints" "HTTP/80"
        llmd -> gaie "Defines InferencePool and InferenceModel CRDs"
        llmd -> llmdRouter "Routes requests with prefix-cache affinity" "HTTP/8081"
        llmd -> llmdRoutingSidecar "Disaggregated prefill/decode routing" "In-pod"
        llmd -> llmdKVCache "Transfers KV-cache between pods" "TCP/5600 NIXL"
        llmd -> llmdAutoscaler "Autoscales model-server replicas" "KEDA"
        llmd -> llmdLatencyPredictor "Scores endpoints by predicted latency" "EPP Plugin"
        llmd -> kubernetes "Deploys model-server pods and services" "Kubernetes API"
        llmd -> prometheus "Exports vLLM metrics" "HTTP/8000 /metrics"
        llmd -> otel "Exports distributed traces" "gRPC/4317 OTLP"
        llmd -> huggingface "Downloads model weights" "HTTPS/443"
        llmd -> ghcr "Pulls container images and Helm charts" "HTTPS/443"
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
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #4a90e2
                color #ffffff
                shape hexagon
            }
            element "Module" {
                background #4a90e2
                color #ffffff
            }
            element "Configuration" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Deploys and queries large language models for inference"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack for LLMs with intelligent routing and multi-accelerator support" {
            modelServerCUDA = container "llm-d-cuda" "NVIDIA GPU model server with vLLM, NVSHMEM, UCX, NIXL, DeepEP, FlashInfer" "Python/CUDA Container"
            modelServerCPU = container "llm-d-cpu" "CPU-only model server with vLLM" "Python Container"
            modelServerHPU = container "llm-d-hpu" "Intel Gaudi model server with vLLM-Gaudi" "Python Container"
            modelServerROCm = container "llm-d-rocm" "AMD ROCm model server with vLLM and RIXL" "Python Container"
            routingSidecar = container "llm-d-routing-sidecar" "Request routing sidecar for prefill/decode disaggregation" "Go Container"
            kustomizeManifests = container "Kustomize Manifests" "Layered deployment configuration for multiple guides and hardware backends" "YAML/Kustomize"
            helmValues = container "Helm Values" "Configuration for llm-d-inference-scheduler chart" "YAML/Helm"
        }

        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Intelligent Envoy-based routing engine with KV-cache-aware and load-aware scheduling plugins" "Internal"
        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that consults EPP via ext-proc for routing decisions" "External"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "External traffic ingress via Gateway and HTTPRoute resources" "External"
        agentGateway = softwareSystem "AgentGateway" "Default Gateway API provider (v1.1.0)" "External"
        istio = softwareSystem "Istio" "Alternative gateway provider with service mesh and mTLS capabilities" "External"
        gaie = softwareSystem "Gateway API Inference Extension (GAIE)" "Provides InferencePool and EPP CRDs (v1.5.0)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor resources" "External"
        otelCollector = softwareSystem "OTEL Collector" "Distributed tracing pipeline (OTLP)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model weight repository" "External"
        s3Storage = softwareSystem "S3 / Object Storage" "Model artifact storage" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"

        // Relationships
        user -> llmd "Sends inference requests via HTTP"
        user -> llmd "Deploys models via kubectl/kustomize"

        llmd -> epp "Consulted for routing decisions" "gRPC ext-proc/6789"
        llmd -> envoyProxy "Proxied through for load balancing" "HTTP/80"
        llmd -> gatewayAPI "Ingress via Gateway/HTTPRoute CRDs" "HTTP/80"
        llmd -> agentGateway "Default gateway provider" "HTTP/80"
        llmd -> istio "Alternative gateway with mTLS" "HTTP/80"
        llmd -> gaie "Uses InferencePool CRDs" "Kubernetes API"
        llmd -> prometheus "Exposes /metrics endpoints" "HTTP/8000, HTTP/9090"
        llmd -> otelCollector "Exports traces" "gRPC OTLP/4317"
        llmd -> hfHub "Downloads model weights" "HTTPS/443"
        llmd -> s3Storage "Downloads model artifacts" "HTTPS/443"
        llmd -> kubernetesAPI "Watches CRDs, manages pods" "HTTPS/443"

        epp -> kubernetesAPI "Watches InferencePool and Pod resources" "HTTPS/443"
        epp -> llmd "Polls model server metrics" "HTTP/8000"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

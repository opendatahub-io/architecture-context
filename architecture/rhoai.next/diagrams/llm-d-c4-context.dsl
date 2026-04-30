workspace {
    model {
        // Actors
        datascientist = person "Data Scientist" "Deploys and manages LLM inference services"
        mlops = person "MLOps Engineer" "Configures serving patterns and autoscaling"
        sre = person "SRE" "Monitors inference health and performance"

        // Core System
        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack for large language models" {
            proxyLayer = container "Proxy Layer" "Accepts client requests and routes to optimal model server endpoints via ext-proc protocol" "Envoy / Gateway API"
            epp = container "Endpoint Picker (EPP)" "Scheduling brain: Filter→Score→Pick pipeline with flow control, priority bands, and fairness policies" "Go Service (llm-d-inference-scheduler)"
            inferencePool = container "InferencePool" "Kubernetes CRD that groups model server pods via label selectors for endpoint discovery" "Kubernetes CRD (Gateway API Inference Extension)"
            decodeServer = container "Decode Model Server" "Executes model inference on accelerators, serves OpenAI-compatible API, exposes Prometheus metrics" "vLLM / SGLang"
            prefillServer = container "Prefill Model Server" "Handles prefill phase in P/D disaggregation mode (FLOPs-bound), transfers KV cache via NIXL" "vLLM + Routing Sidecar"
            nixlTransfer = container "NIXL KV Transfer" "Abstracts GPU memory transfer across transports (NVLink, RoCE, InfiniBand, EFA) for P/D disaggregation" "NIXL v0.10.0"
        }

        // External Dependencies
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Standard L7 networking API for Kubernetes" "External"
        agentgateway = softwareSystem "agentgateway" "Preferred gateway implementation, self-installed" "External"
        istio = softwareSystem "Istio" "Service mesh and ingress gateway" "External"
        gkeGateway = softwareSystem "GKE Gateway" "Cloud-managed gateway (Google)" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for pod discovery, CRD management, RBAC" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for scheduling decisions and monitoring" "External"
        grafana = softwareSystem "Grafana" "Dashboards: vLLM Overview, Failure & Saturation, P/D Coordinator, EPP Metrics" "External"
        jaeger = softwareSystem "Jaeger" "Distributed tracing backend (OpenTelemetry)" "External"
        containerRegistry = softwareSystem "Container Registry" "ghcr.io/llm-d - stores llm-d container images" "External"
        modelStorage = softwareSystem "Model Storage" "Model artifact storage (HuggingFace Hub, S3, PVC)" "External"

        // Hardware
        nvidia = softwareSystem "NVIDIA GPUs" "A100, H100, H200, B200, L4 accelerators" "Hardware"
        amd = softwareSystem "AMD GPUs" "MI250X+ accelerators" "Hardware"
        intel = softwareSystem "Intel Accelerators" "Data Center GPU Max 1550+ (XPU), Gaudi 1/2/3 (HPU)" "Hardware"
        googleTPU = softwareSystem "Google TPU" "TPU v5e, v6e, v7 accelerators" "Hardware"

        // Infrastructure Providers
        gke = softwareSystem "Google GKE" "Managed Kubernetes on Google Cloud" "Infrastructure"
        aks = softwareSystem "Azure AKS" "Managed Kubernetes on Azure" "Infrastructure"
        ocp = softwareSystem "OpenShift" "Red Hat OpenShift Container Platform" "Infrastructure"

        // Relationships - Users
        datascientist -> llmd "Deploys models via well-lit path guides" "kubectl / Kustomize / Helmfile"
        mlops -> llmd "Configures serving patterns, autoscaling, and flow control"
        sre -> grafana "Monitors inference health and performance"

        // Relationships - Internal
        proxyLayer -> epp "Consults for routing decisions" "ext-proc gRPC (FULL_DUPLEX_STREAMED)"
        epp -> inferencePool "Discovers model server endpoints" "Kubernetes label selector"
        inferencePool -> decodeServer "Groups decode pods" "Label: llm-d.ai/role=decode"
        inferencePool -> prefillServer "Groups prefill pods" "Label: llm-d.ai/role=prefill"
        proxyLayer -> decodeServer "Forwards inference requests" "HTTP/8000"
        proxyLayer -> prefillServer "Forwards prefill requests" "HTTP/8000"
        prefillServer -> nixlTransfer "Sends KV cache blocks" "RDMA/5600"
        nixlTransfer -> decodeServer "Transfers KV cache" "GPUDirect RDMA"

        // Relationships - External
        proxyLayer -> agentgateway "Uses as preferred gateway" "Gateway API"
        proxyLayer -> istio "Alternative gateway" "Gateway API"
        proxyLayer -> gkeGateway "Alternative gateway (GKE)" "Gateway API"
        epp -> k8sAPI "Watches pod lifecycle events" "Kubernetes API / ServiceAccount token"
        epp -> prometheus "Collects model server metrics" "HTTP scrape"
        decodeServer -> prometheus "Exposes metrics" "HTTP/9002"
        decodeServer -> jaeger "Sends traces" "OTLP"
        decodeServer -> modelStorage "Downloads model artifacts" "HTTPS / HF Token / AWS IAM"
        decodeServer -> containerRegistry "Pulls container images" "HTTPS"
        prometheus -> grafana "Feeds dashboards" "PromQL"
        decodeServer -> nvidia "Runs inference on" "CUDA"
        decodeServer -> amd "Runs inference on" "ROCm"
        decodeServer -> intel "Runs inference on" "XPU/HPU"
        decodeServer -> googleTPU "Runs inference on" "TPU runtime"
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
            element "Hardware" {
                background #95a5a6
                color #ffffff
                shape Hexagon
            }
            element "Infrastructure" {
                background #7f8c8d
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
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

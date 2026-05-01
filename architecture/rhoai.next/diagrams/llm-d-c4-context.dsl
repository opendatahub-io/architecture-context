workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and manages ML models for inference"
        appDeveloper = person "Application Developer" "Builds applications that consume LLM inference APIs"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack for large language models" {
            proxyLayer = container "Gateway / Envoy Proxy" "Accepts client requests, consults EPP via ext-proc for routing decisions" "Envoy / Gateway API" "Port 80/TCP"
            epp = container "Endpoint Picker (EPP)" "Scheduling brain: Filter → Score → Pick pipeline with flow control, prefix cache affinity, and P/D disaggregation" "Go Service (llm-d-inference-scheduler v0.7.0)"
            inferencePool = container "InferencePool CRD" "Kubernetes CRD for endpoint discovery and gateway integration, namespace-scoped" "Kubernetes Custom Resource"
            modelServer = container "Model Server (vLLM)" "Executes LLM inference on accelerator hardware, serves OpenAI-compatible API" "Python (vLLM / SGLang)" "Port 8000/TCP"
            routingSidecar = container "Routing Sidecar" "Orchestrates prefill/decode disaggregation flow" "Go Service (v0.7.1)" "Port 8000/TCP"
            nixlTransfer = container "NIXL Transfer" "GPU-to-GPU KV cache transfer via RDMA (GPUDirect)" "C++ Library (v0.10.0)" "Port 5600/TCP"
            lmcache = container "LMCache" "Hierarchical KV cache offloading across storage tiers" "Python (v0.3.14)"
        }

        // External systems
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Standard L7 networking for Kubernetes" "External"
        agentgateway = softwareSystem "agentgateway" "Preferred gateway implementation for llm-d" "External"
        istio = softwareSystem "Istio" "Service mesh and ingress gateway" "External"
        gkeGateway = softwareSystem "GKE Gateway" "Google Cloud managed load balancer" "External Cloud"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster orchestration, pod lifecycle, CRD management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting (GKE Managed / OCP UWM / Self-managed)" "External"
        jaeger = softwareSystem "Jaeger" "Distributed tracing backend via OpenTelemetry" "External"
        grafana = softwareSystem "Grafana" "Metrics dashboards and visualization" "External"

        containerRegistry = softwareSystem "Container Registry" "ghcr.io/llm-d - Container image storage" "External"
        modelStorage = softwareSystem "Model Storage" "S3, GCS, PVC - Model artifact storage" "External"
        githubActions = softwareSystem "GitHub Actions" "CI/CD pipeline with 55 workflows, Trivy scanning, DCO enforcement" "External"

        // Internal ODH/RHOAI systems
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ML workloads" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"

        // Relationships - User interactions
        appDeveloper -> llmd "Sends OpenAI-compatible inference requests" "HTTP/80"
        dataScientist -> llmd "Deploys models via Kustomize/Helm guides" "kubectl / kustomize"

        // Internal container relationships
        proxyLayer -> epp "Consults for every routing decision" "ext-proc gRPC (FULL_DUPLEX_STREAMED)"
        epp -> inferencePool "Discovers available endpoints" "Kubernetes API (watch/list)"
        inferencePool -> modelServer "Label-based pod discovery" "llm-d.ai/inference-serving selector"
        proxyLayer -> modelServer "Forwards requests to selected endpoint" "HTTP/8000"
        proxyLayer -> routingSidecar "Forwards P/D requests" "HTTP/8000"
        routingSidecar -> modelServer "Prefill request (max_tokens=1)" "HTTP/8000"
        modelServer -> nixlTransfer "KV cache block transfer" "RDMA/5600 (GPUDirect)"
        nixlTransfer -> modelServer "KV blocks to decode worker" "RDMA/5600"
        modelServer -> lmcache "Tiered cache offloading" "Memory/Disk/Network"

        // External dependencies
        llmd -> gatewayAPI "Uses for standard L7 networking" "Kubernetes Gateway CRDs"
        proxyLayer -> agentgateway "Preferred gateway implementation" "Gateway API"
        proxyLayer -> istio "Alternative gateway (IngressGateway)" "Gateway API"
        proxyLayer -> gkeGateway "Cloud-managed gateway option" "Gateway API"
        epp -> k8sAPI "Watches pods, CRDs, services" "Kubernetes API"
        epp -> prometheus "Polls model server metrics" "HTTP scrape"
        modelServer -> prometheus "Exposes metrics" "HTTP/9002,9090"
        modelServer -> jaeger "Sends traces" "OTLP"
        prometheus -> grafana "Visualizes metrics" "PromQL"
        modelServer -> containerRegistry "Pulls container images" "HTTPS/443"
        modelServer -> modelStorage "Downloads model artifacts" "HTTPS/NFS"
        llmd -> githubActions "CI/CD builds, tests, security scanning" "GitHub Events"

        // Internal integrations
        odhDashboard -> llmd "UI management of inference services" "Kubernetes API"
        dsPipelines -> llmd "Auto-deploys trained models" "Kubernetes API"
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
            element "External Cloud" {
                background #4285f4
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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

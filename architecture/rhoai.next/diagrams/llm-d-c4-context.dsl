workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        platform_admin = person "Platform Admin" "Deploys and configures the llm-d inference stack"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed inference serving stack (CNCF Sandbox)" {
            modelServer = container "vLLM Model Server" "OpenAI-compatible inference API on port 8000/TCP. Built from Dockerfiles for CUDA, CPU, ROCm, XPU." "Python/vLLM"
            epp = container "llm-d-router EPP" "Endpoint Picker - KV-cache-aware, load-balanced request routing via ext-proc gRPC" "Go"
            proxy = container "Envoy Proxy" "Sidecar or gateway proxy for inference traffic routing" "Envoy"
            mooncakeMaster = container "Mooncake Master Store" "Singleton metadata store for KV-cache segment coordination. Ports 50051 (gRPC), 8080 (HTTP), 9003 (metrics)" "C++"
            mooncakeClient = container "Mooncake Client" "DaemonSet agent for node-level RDMA KV-cache offload. Port 50052 (gRPC)" "C++"
            nixl = container "NIXL KV Transfer" "Direct KV-cache transfer between prefill and decode pods on port 5600/TCP" "C++/gRPC"
            kustomizeGuides = container "Kustomize Deployment Guides" "Production-ready deployment recipes: optimized-baseline, P/D disaggregation, prefix-cache, wide-EP, autoscaling" "Kustomize/YAML"
            dockerfiles = container "Container Image Builds" "Multi-stage Dockerfiles for CUDA, CPU, ROCm, XPU accelerator variants" "Dockerfile"
        }

        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Ingress via Gateway and HTTPRoute CRDs" "External"
        gaie = softwareSystem "Gateway API Inference Extension" "InferencePool CRD for endpoint discovery" "External"
        istio = softwareSystem "Istio" "Service mesh, Gateway implementation with ext-proc support" "External"
        agentgateway = softwareSystem "agentgateway" "Lightweight Gateway implementation" "External"
        envoyAIGW = softwareSystem "Envoy AI Gateway" "AI-optimized Gateway implementation" "External"
        gkeGateway = softwareSystem "GKE Gateway" "Google Cloud managed Gateway" "External"

        vllmUpstream = softwareSystem "vLLM (upstream)" "Core inference engine compiled into container images" "External"
        llmdRouter = softwareSystem "llm-d-router" "Helm charts for EPP + Envoy proxy deployment" "Internal llm-d"
        llmdBenchmark = softwareSystem "llm-d-benchmark" "Performance benchmarking harness" "Internal llm-d"

        prometheus = softwareSystem "Prometheus" "Metrics collection from model servers and Mooncake" "External"
        grafana = softwareSystem "Grafana" "Pre-built dashboards for vLLM, SGLang, P/D coordinator" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export on port 4317/TCP gRPC" "External"
        jaeger = softwareSystem "Jaeger" "Trace visualization for request flow debugging" "External"

        hfHub = softwareSystem "HuggingFace Hub" "Model weight downloads via HTTPS/443 with Bearer token auth" "External"
        wva = softwareSystem "Workload Variant Autoscaler" "SLO-aware autoscaling via HPA external metrics" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node model server coordination CRD for wide expert parallelism" "External"

        # Relationships
        user -> llmd "Sends inference requests (POST /v1/chat/completions)" "HTTP/HTTPS"
        platform_admin -> llmd "Deploys and configures via Kustomize guides and Helm charts" "kubectl/helm"

        llmd -> gatewayAPI "Uses Gateway and HTTPRoute CRDs for ingress" "Kubernetes API"
        llmd -> gaie "Uses InferencePool CRD for endpoint discovery" "Kubernetes API"
        llmd -> istio "Uses as Gateway implementation with mTLS optional" "HTTP/gRPC"
        llmd -> agentgateway "Uses as lightweight Gateway implementation" "HTTP"
        llmd -> envoyAIGW "Uses as AI-optimized Gateway implementation" "HTTP"
        llmd -> gkeGateway "Uses as cloud-managed Gateway" "HTTPS"

        llmd -> vllmUpstream "Builds inference engine from source into container images" "Source"
        llmd -> llmdRouter "Deploys EPP + Envoy proxy via Helm charts" "Helm OCI"
        llmd -> llmdBenchmark "Performance testing of inference deployments" "CLI"

        llmd -> prometheus "Exposes metrics on 8000/TCP and 9003/TCP" "HTTP"
        llmd -> otelCollector "Exports traces on 4317/TCP" "gRPC"
        prometheus -> grafana "Feeds dashboards" "PromQL"
        otelCollector -> jaeger "Exports traces" "OTLP"

        llmd -> hfHub "Downloads model weights at pod startup" "HTTPS/443 Bearer"
        llmd -> wva "Provides external metrics for SLO-aware autoscaling" "Prometheus"
        llmd -> lws "Uses for multi-node expert parallelism coordination" "Kubernetes API"

        # Container-level relationships
        proxy -> epp "ext-proc gRPC for route selection" "gRPC"
        epp -> modelServer "Scrapes metrics and routes requests" "HTTP/8000"
        modelServer -> nixl "KV-cache transfer in P/D disaggregation" "gRPC/5600"
        modelServer -> mooncakeClient "KV-cache offload" "gRPC/50052"
        mooncakeClient -> mooncakeMaster "Segment metadata coordination" "gRPC/50051"
        modelServer -> hfHub "Model weight downloads" "HTTPS/443"
        dockerfiles -> modelServer "Builds container images" "Docker"
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
            element "Person" {
                shape person
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

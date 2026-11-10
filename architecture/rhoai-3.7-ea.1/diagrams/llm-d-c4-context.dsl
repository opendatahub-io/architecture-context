workspace "llm-d" "llm-d meta-repository: well-lit-path deployment guides, recipes, and auxiliary images (RHOAI 3.7-ea.1 reference)" {
    model {
        clusterOperator = person "Cluster Operator / Platform Engineer" "Follows llm-d guides with helm install and kubectl apply -k"
        client = person "Inference Client" "Calls OpenAI-compatible inference APIs"

        llmd = softwareSystem "llm-d" "Meta-repository of deployment recipes, guides, and auxiliary images for distributed LLM inference. No runtime service of its own." {
            guides = container "Guides" "About 30 well-lit paths across the accelerator x model server x provider matrix (base, gke, ocp, cks, amd-ci)" "Kustomize + Helm values"
            routerRecipes = container "Router Recipes" "Base and feature values for external llm-d Router charts: EPP, Envoy/agentgateway proxy, FailOpen, monitoring, tracing" "Helm values"
            gatewayRecipes = container "Gateway Recipes" "Gateway CR variants: istio, agentgateway, kgateway (deprecated), gke-l7, nginx, envoy-ai-gateway" "Kustomize"
            modelserverRecipes = container "Modelserver Recipes" "Deployment, LeaderWorkerSet, DisaggregatedSet bases; image pins; PodMonitors; model-cache PVC" "Kustomize"
            autoscalingRecipes = container "Autoscaling Recipes" "OpenShift KEDA to Thanos auth bundle (SA, ClusterRoleBinding, SA token Secret)" "Kustomize"
            observabilityRecipes = container "Observability Recipes" "OTel collector, Jaeger, Grafana dashboards, PrometheusRules, OpenCost" "Manifests"
            images = container "Auxiliary Images" "Dockerfile.cpu (vLLM v0.30.0), Dockerfile.xpu (LMCache), Dockerfile.rdma-tools, interactive-pod, snapshot launcher. Not used in RHOAI" "Dockerfile"
            docs = container "Docs and Proposals" "Architecture, EPP HTTP/gRPC API, headers, InferencePool, InferenceObjective reference" "Markdown"
        }

        router = softwareSystem "llm-d-router" "EPP endpoint picker, coordinator, disaggregation sidecar (Helm charts and images)" "Internal llm-d"
        kvcache = softwareSystem "llm-d-kv-cache" "Precise prefix-cache routing" "Internal llm-d"
        wva = softwareSystem "llm-d-workload-variant-autoscaler" "SLO-aware autoscaling" "Internal llm-d"
        asyncBatch = softwareSystem "llm-d-async / batch-gateway" "Batch and async serving" "Internal llm-d"
        kserve = softwareSystem "KServe LLMInferenceService" "RHOAI deployer of the llm-d topology using RHAIIS AIPCC images (overlays 0011, 0019)" "Internal RHOAI"

        vllm = softwareSystem "vLLM / SGLang" "Model servers (docker.io/vllm/vllm-openai v0.31.0 in guides)" "External"
        gatewayApi = softwareSystem "Gateway API Provider" "Istio (only supported on OCP), agentgateway, GKE, NGINX, Envoy AI Gateway" "External"
        gaie = softwareSystem "Gateway API + GAIE CRDs" "InferencePool, HTTPRoute" "External"
        lws = softwareSystem "LeaderWorkerSet / DisaggregatedSet" "Multi-host and P/D group scheduling" "External"
        keda = softwareSystem "KEDA" "EPP-metric-driven autoscaling" "External"
        thanos = softwareSystem "OpenShift Monitoring (Thanos Querier)" "Metrics source for KEDA triggers" "External"
        prometheus = softwareSystem "Prometheus Operator" "PodMonitor, PrometheusRule" "External"
        hf = softwareSystem "HuggingFace Hub" "Model weight download" "External"

        clusterOperator -> guides "Follows guides" "helm / kubectl"
        client -> gatewayApi "Inference requests" "HTTP/80, no TLS, no auth (guide default)"
        guides -> routerRecipes "Uses"
        guides -> gatewayRecipes "Uses"
        guides -> modelserverRecipes "Patches"
        guides -> autoscalingRecipes "Uses"
        guides -> observabilityRecipes "Uses"

        routerRecipes -> router "Configures Helm charts" "oci://ghcr.io/llm-d/charts"
        modelserverRecipes -> vllm "Deploys model servers" "8000/TCP HTTP"
        modelserverRecipes -> lws "Creates LeaderWorkerSet / DisaggregatedSet"
        gatewayRecipes -> gatewayApi "Creates Gateway + HTTPRoute" "HTTP/80"
        routerRecipes -> gaie "Creates InferencePool"
        autoscalingRecipes -> keda "ScaledObject + TriggerAuthentication"
        keda -> thanos "Queries EPP metrics" "HTTPS/9091, Bearer SA token"
        observabilityRecipes -> prometheus "PodMonitor / PrometheusRule"
        guides -> kvcache "Precise prefix-cache guide"
        guides -> wva "Workload-autoscaling guide"
        guides -> asyncBatch "Batch-serving guides"

        gatewayApi -> router "ext-proc endpoint picking" "gRPC"
        router -> vllm "Routes to selected endpoint" "HTTP/8000"
        vllm -> hf "Downloads model weights" "HTTPS/443, Bearer HF_TOKEN"
        kserve -> llmd "Mirrors topology, default flags, ports, header contracts"
        images -> vllm "Optional upstream model-server builds"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
            }
            element "Internal RHOAI" {
                background #f5a623
            }
        }
    }
}

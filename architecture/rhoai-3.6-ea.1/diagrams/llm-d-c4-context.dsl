workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM models for inference"
        devops = person "Platform Engineer" "Deploys and configures llm-d stack"

        llmD = softwareSystem "llm-d" "Reference architecture for multi-accelerator vLLM inference serving on Kubernetes" {
            decodeDeployment = container "Decode Deployment" "vLLM OpenAI-compatible API server for token generation" "Python / vLLM" "Deployment"
            prefillDeployment = container "Prefill Deployment" "vLLM server for prompt processing in P/D disaggregation mode" "Python / vLLM" "Deployment"
            dockerImages = container "Container Images" "Multi-accelerator vLLM images (CPU, CUDA, ROCm, XPU)" "Docker" "Build Artifact"
            kustomizeRecipes = container "Kustomize Recipes" "Composable deployment recipes for serving patterns" "Kustomize / Helm" "Configuration"
        }

        llmDRouter = softwareSystem "llm-d-router" "EPP and Envoy proxy for intelligent inference request routing" {
            epp = container "Endpoint Picker Plugin" "Load-aware and cache-aware request routing via ext_proc" "Go" "Service"
            envoyProxy = container "Envoy Proxy" "Reverse proxy with ORIGINAL_DST routing" "Envoy" "Proxy"
        }

        gatewayAPIInfExt = softwareSystem "Gateway API Inference Extension" "Provides InferencePool and InferenceModel CRDs for Kubernetes-native inference routing" "External"
        gatewayProvider = softwareSystem "Gateway Provider" "Gateway API, Istio, kgateway, or AgentGateway for ingress and auth" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        nixl = softwareSystem "nixl" "KV cache P2P transfer library" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        # User relationships
        user -> llmD "Sends inference requests via HTTP"
        devops -> llmD "Deploys using kustomize recipes and Helm charts"

        # Internal relationships
        dockerImages -> decodeDeployment "Provides container image"
        dockerImages -> prefillDeployment "Provides container image"
        kustomizeRecipes -> decodeDeployment "Configures"
        kustomizeRecipes -> prefillDeployment "Configures"
        prefillDeployment -> decodeDeployment "Transfers KV cache via nixl" "TCP/5600"

        # External relationships
        llmD -> llmDRouter "Requests routed through" "HTTP/8081"
        epp -> decodeDeployment "Routes requests to" "HTTP/8000"
        epp -> prefillDeployment "Routes requests to" "HTTP/8000"
        epp -> gatewayAPIInfExt "Watches InferencePool and InferenceModel CRDs"
        gatewayProvider -> llmDRouter "Forwards requests via ext_proc" "gRPC/9002"
        user -> gatewayProvider "Sends requests" "HTTP/80"
        epp -> otelCollector "Exports traces" "gRPC/4317"
        decodeDeployment -> prometheus "Exposes metrics"
        prefillDeployment -> nixl "Uses for KV cache transfer" "TCP/5600"
        llmD -> kubernetes "Deployed on"
    }

    views {
        systemContext llmD "SystemContext" {
            include *
            autoLayout
        }

        container llmD "LlmDContainers" {
            include *
            autoLayout
        }

        container llmDRouter "RouterContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Deployment" {
                background #4a90e2
                color #ffffff
            }
            element "Service" {
                background #f5a623
                color #ffffff
            }
            element "Proxy" {
                background #f5a623
                color #ffffff
            }
            element "Build Artifact" {
                background #dddddd
                color #333333
            }
            element "Configuration" {
                background #dddddd
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Deploys and manages LLM inference workloads"
        client = person "Inference Client" "Sends inference requests to deployed models"

        llmdDeployer = softwareSystem "llm-d-deployer" "Deprecated monolithic Helm chart for deploying the llm-d distributed LLM inference stack" {
            helmChart = container "llm-d Helm Chart" "Monolithic Helm chart (v1.0.23) packaging the complete inference stack" "Helm/Go Templates"
            controller = container "ModelService Controller" "Reconciles ModelService CRs into prefill/decode Deployments, Services, InferencePools, and InferenceModels" "Go Controller" "ghcr.io/llm-d/llm-d-model-service:v0.0.15"
            epp = container "Endpoint Picker (EPP)" "Envoy external processor scoring and selecting inference backends using prefix, load, KV-cache, and session awareness" "Go gRPC Service" "ghcr.io/llm-d/llm-d-inference-scheduler:v0.1.0"
            vllmPrefill = container "vLLM Prefill" "Serves prefill phase of LLM inference with NixL KV-cache transfer" "Python (vLLM)" "ghcr.io/llm-d/llm-d:0.0.8"
            vllmDecode = container "vLLM Decode" "Serves decode phase of LLM inference, receives KV-cache from prefill" "Python (vLLM)" "ghcr.io/llm-d/llm-d:0.0.8"
            routingProxy = container "Routing Proxy Sidecar" "Sidecar on decode pods intercepting port 8000, proxying to vLLM on port 8001" "Go Proxy" "ghcr.io/llm-d/llm-d-routing-sidecar:0.0.7"
            redis = container "Redis" "LMCache lookup URL backend and KV-cache indexer for EPP scorers" "Bitnami Redis 20.13.4"
            quickstart = container "Quickstart Installer" "Wraps Helm install with namespace creation, HF token, CRD application, monitoring provisioning" "Bash Script"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (>= 1.30)" "External"
        gatewayImpl = softwareSystem "Gateway Implementation" "Istio, kGateway, or GKE L7 — provides Gateway class for inference routing" "External"
        gatewayAPI = softwareSystem "Gateway API" "Gateway, HTTPRoute, InferencePool, InferenceModel CRDs" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model artifact repository" "External"
        prometheus = softwareSystem "Prometheus Operator" "Metrics scraping via ServiceMonitor CRDs" "External"
        nvidiaGPU = softwareSystem "NVIDIA GPU" "GPU accelerator for vLLM inference" "External"
        openshift = softwareSystem "OpenShift" "Optional platform integration (Route, SCC, user workload monitoring)" "External"

        # Relationships
        user -> llmdDeployer "Deploys inference stack via Helm install or quickstart script"
        user -> controller "Creates ModelService CRs via kubectl"
        client -> gatewayImpl "Sends inference requests" "HTTP/80"

        gatewayImpl -> epp "Routes via external processor" "gRPC/9002"
        epp -> redis "KV-cache lookup" "TCP/8100"
        gatewayImpl -> routingProxy "Forwards to decode pod" "HTTP/8000"
        routingProxy -> vllmDecode "Proxies inference request" "HTTP/8001"
        vllmDecode -> vllmPrefill "NixL KV-cache transfer" "NixL/5557"

        controller -> kubernetes "Creates Deployments, Services, InferencePool, InferenceModel" "HTTPS/443"
        vllmPrefill -> huggingFace "Downloads model artifacts" "HTTPS/443"
        vllmDecode -> huggingFace "Downloads model artifacts" "HTTPS/443"
        vllmPrefill -> nvidiaGPU "Requires GPU for inference"
        vllmDecode -> nvidiaGPU "Requires GPU for inference"

        llmdDeployer -> gatewayAPI "Uses Gateway, HTTPRoute, InferencePool, InferenceModel CRDs"
        llmdDeployer -> prometheus "Exposes metrics via ServiceMonitor"
        llmdDeployer -> openshift "Optional Route, SCC integration"

        quickstart -> helmChart "Wraps with pre/post-install steps"
    }

    views {
        systemContext llmdDeployer "SystemContext" {
            include *
            autoLayout
        }

        container llmdDeployer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
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

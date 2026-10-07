workspace {
    model {
        datascientist = person "Data Scientist" "Creates ModelService CRDs to deploy LLM inference stacks"
        sre = person "SRE / Platform Engineer" "Installs and operates the llm-d Helm chart"

        llmDDeployer = softwareSystem "llm-d-deployer" "Deprecated monolithic Helm chart for deploying the llm-d distributed LLM inference framework on Kubernetes" {
            helmChart = container "llm-d Helm Chart" "Packages and deploys the entire llm-d inference ecosystem as a single Helm release" "Helm Chart v1.0.23"
            controller = container "ModelService Controller" "Reconciles ModelService CRDs into prefill/decode Deployments, Services, InferencePools, and routing resources" "Go Operator"
            epp = container "Endpoint Picker (EPP)" "GIE-compatible external processor for intelligent request routing to inference backends" "Go Service, gRPC 9002/9003"
            prefillVLLM = container "Prefill vLLM" "vLLM inference server handling prompt prefill with NIXL KV-cache output" "Python, HTTP 8000, NIXL 5557"
            decodeVLLM = container "Decode vLLM" "vLLM inference server handling token decoding with NIXL KV-cache input" "Python, HTTP 8001, NIXL 5557"
            routingProxy = container "Routing Proxy" "Sidecar on decode nodes managing port routing (8000→8001) and NIXL connectivity" "Go Sidecar"
            redis = container "Redis" "KV-cache lookup index for LMCache distributed coordination" "Bitnami Redis 20.13.4, TCP 8100"
            presetConfigMaps = container "Preset ConfigMaps" "Deployment template presets (basic-gpu, gpu-with-nixl, gpu-with-nixl-and-redis-lookup, sim)" "Kubernetes ConfigMap"
            inferenceGateway = container "Inference Gateway" "Gateway API resource routing external traffic to InferencePools via EPP" "Gateway (gateway.networking.k8s.io)"
            grafana = container "Grafana" "Observability dashboard with Prometheus datasource" "Grafana"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (>= 1.30.0)" "External"
        gatewayBackend = softwareSystem "Gateway Backend" "Istio, kGateway, or GKE L7 gateway implementation" "External"
        gatewayAPICRDs = softwareSystem "Gateway API CRDs" "gateway.networking.k8s.io resources for ingress routing" "External"
        gieCRDs = softwareSystem "GIE CRDs" "inference.networking.x-k8s.io InferencePool/InferenceModel" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model artifact storage and download" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics scraping via ServiceMonitor CRD" "External"
        nvidiaGPU = softwareSystem "NVIDIA GPUs" "GPU hardware for vLLM inference" "External"

        # Relationships
        datascientist -> llmDDeployer "Creates ModelService CRD via kubectl"
        sre -> llmDDeployer "Installs Helm chart via helm install"

        controller -> kubernetes "Watches CRDs, creates resources" "HTTPS/443"
        controller -> presetConfigMaps "Reads deployment templates"
        controller -> prefillVLLM "Creates prefill deployments"
        controller -> decodeVLLM "Creates decode deployments"
        controller -> epp "Creates EPP deployments"

        inferenceGateway -> epp "Routes via GIE ExternalProcessor" "gRPC/9002"
        epp -> prefillVLLM "Selects inference backend" "HTTP/8000"
        epp -> routingProxy "Selects inference backend" "HTTP/8000"
        routingProxy -> decodeVLLM "Redirects traffic" "HTTP/8001"

        prefillVLLM -> decodeVLLM "NIXL KV-cache transfer" "TCP/5557"
        prefillVLLM -> redis "LMCache KV lookup" "TCP/8100"
        decodeVLLM -> redis "LMCache KV lookup" "TCP/8100"
        prefillVLLM -> huggingFace "Downloads model artifacts" "HTTPS/443"
        decodeVLLM -> huggingFace "Downloads model artifacts" "HTTPS/443"

        llmDDeployer -> gatewayBackend "Uses for traffic routing"
        llmDDeployer -> gatewayAPICRDs "Requires Gateway API resources"
        llmDDeployer -> gieCRDs "Requires GIE resources"
        llmDDeployer -> nvidiaGPU "Requires GPU hardware"

        grafana -> prometheusOperator "Queries metrics via Prometheus"
    }

    views {
        systemContext llmDDeployer "SystemContext" {
            include *
            autoLayout
        }

        container llmDDeployer "Containers" {
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
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

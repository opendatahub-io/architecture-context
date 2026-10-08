workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Deploys and manages LLM inference workloads"
        admin = person "Platform Admin" "Installs and configures llm-d infrastructure"

        llmdDeployer = softwareSystem "llm-d-deployer" "Deprecated monolithic Helm chart for deploying llm-d distributed LLM inference framework on Kubernetes/OpenShift" {
            helmChart = container "llm-d Helm Chart" "Monolithic Helm chart packaging all llm-d ecosystem components" "Helm 3.x"
            installer = container "Quickstart Installer" "Automated bash installer wrapping Helm with dependency validation and setup" "Bash"
            presets = container "Preset ConfigMaps" "Deployment templates for prefill, decode, and EPP configurations" "Kubernetes ConfigMap"
        }

        modelServiceController = softwareSystem "llm-d-model-service" "Controller that watches ModelService CRs and reconciles inference workloads" "Internal"
        inferenceScheduler = softwareSystem "llm-d-inference-scheduler (EPP)" "Endpoint picker for intelligent request routing with configurable scoring strategies" "Internal"
        llmdVLLM = softwareSystem "llm-d (vLLM)" "Modified vLLM serving engine with NixL and LMCache KV-cache connectors" "Internal"
        routingSidecar = softwareSystem "llm-d-routing-sidecar" "Routing proxy sidecar for decode pods enabling NixL v2 connectivity" "Internal"

        gatewayAPI = softwareSystem "Kubernetes Gateway API" "Gateway, HTTPRoute resources for inference routing" "External"
        gaie = softwareSystem "Gateway API Inference Extension (GAIE)" "InferencePool, InferenceModel CRDs for gateway-aware model routing" "External"
        gatewayProvider = softwareSystem "Gateway Provider" "Istio, kgateway, or GKE L7 backend for Gateway API" "External"
        redis = softwareSystem "Redis" "Bitnami Redis for LMCache KV-cache lookup coordination" "External"
        kubernetes = softwareSystem "Kubernetes" "Target container orchestration platform (>= 1.30.0)" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model artifact repository" "External"
        prometheus = softwareSystem "Prometheus / Grafana" "Metrics collection and observability dashboards" "External"

        llmdInfra = softwareSystem "llm-d-infra" "Successor: modular Helmfile-based composition approach (replaces this repo)" "Successor"

        # Relationships
        admin -> llmdDeployer "Installs via Helm or quickstart installer"
        user -> llmdDeployer "Creates ModelService CRs via kubectl"
        llmdDeployer -> modelServiceController "Deploys controller image (v0.0.15)"
        llmdDeployer -> inferenceScheduler "Deploys EPP image (v0.1.0)"
        llmdDeployer -> llmdVLLM "Deploys vLLM inference pods (0.0.8)"
        llmdDeployer -> routingSidecar "Deploys routing proxy sidecar (0.0.7)"
        llmdDeployer -> gatewayAPI "Installs Gateway and HTTPRoute CRDs"
        llmdDeployer -> gaie "Installs InferencePool and InferenceModel CRDs"
        llmdDeployer -> gatewayProvider "Configures Istio/kgateway/GKE L7 gateway" "YAML/Helm"
        llmdDeployer -> redis "Deploys as subchart for KV-cache lookup" "Redis/8100"
        llmdDeployer -> kubernetes "Deploys workloads" "Kubernetes API/6443"
        llmdDeployer -> huggingFace "Downloads model artifacts" "HTTPS/443"
        llmdDeployer -> prometheus "Configures ServiceMonitors and Grafana dashboards"
        llmdInfra -> llmdDeployer "Supersedes (deprecated July 2025)"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Successor" {
                background #e74c3c
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages Llama Stack inference servers on Kubernetes"
        admin = person "Platform Administrator" "Configures operator settings and manages infrastructure"

        llamaStackOperator = softwareSystem "Llama Stack K8s Operator" "Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers" {
            controllerManager = container "Operator Controller Manager" "Reconciles LlamaStackDistribution CRDs and manages workload lifecycle" "Go 1.24, controller-runtime v0.19.4"
            llsdController = container "LlamaStackDistribution Controller" "Watches CRDs and creates Deployments, Services, PVCs, NetworkPolicies, Ingresses" "Go Controller"
            kustomizeEngine = container "Kustomize-based Deployment Engine" "Dynamically generates Kubernetes manifests from templates" "kustomize/kyaml v0.18.1"
            rbacProxy = container "kube-rbac-proxy Sidecar" "Secures metrics endpoint with token validation" "kube-rbac-proxy"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        ollama = softwareSystem "Ollama Server" "Local LLM inference backend" "External"
        vllm = softwareSystem "vLLM Server" "High-performance LLM serving with GPU acceleration" "External"
        tgi = softwareSystem "Text Generation Inference (TGI)" "HuggingFace inference backend" "External"
        bedrock = softwareSystem "AWS Bedrock" "Managed AI inference service" "External"
        containerRegistry = softwareSystem "Container Registry" "Docker Hub, Quay.io for distribution images" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact repository" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Cluster monitoring stack with ServiceMonitor support" "Internal RHOAI"
        scc = softwareSystem "Security Context Constraints" "OpenShift pod security policies (anyuid)" "Internal RHOAI"

        user -> llamaStackOperator "Creates LlamaStackDistribution CRDs via kubectl"
        admin -> llamaStackOperator "Configures feature flags and image overrides via ConfigMap"

        llamaStackOperator -> kubernetes "Manages CRDs, Deployments, Services, PVCs, NetworkPolicies, Ingresses" "HTTPS/6443 TLS 1.2+ ServiceAccount JWT"
        llamaStackOperator -> containerRegistry "Pulls Llama Stack distribution images" "HTTPS/443 TLS 1.2+"
        llamaStackOperator -> huggingface "Downloads model weights (vLLM distributions)" "HTTPS/443 TLS 1.2+ HF Token"
        llamaStackOperator -> prometheus "Exposes operator metrics" "HTTPS/8443 TLS Bearer Token"
        llamaStackOperator -> openshiftMonitoring "Integrates via ServiceMonitor CRD" "Prometheus protocol"
        llamaStackOperator -> scc "Uses anyuid SCC for managed pods" "OpenShift API"

        llamaStackOperator -> ollama "Deploys and connects to Ollama distribution" "HTTP/11434"
        llamaStackOperator -> vllm "Deploys and connects to vLLM distribution" "HTTP/8000"
        llamaStackOperator -> tgi "Deploys and connects to TGI distribution" "HTTP/8080"
        llamaStackOperator -> bedrock "Deploys Bedrock integration distribution" "HTTPS/443 AWS API"

        user -> ollama "Sends inference requests via Llama Stack API" "HTTP/8321"
        user -> vllm "Sends inference requests via Llama Stack API" "HTTP/8321"
        user -> tgi "Sends inference requests via Llama Stack API" "HTTP/8321"
    }

    views {
        systemContext llamaStackOperator "SystemContext" {
            include *
            autoLayout
        }

        container llamaStackOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
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

        themes default
    }
}

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages Llama Stack inference servers on Kubernetes"
        admin = person "Platform Administrator" "Configures operator settings, manages feature flags and image overrides"

        llamaOperator = softwareSystem "Llama Stack K8s Operator" "Automates deployment and lifecycle management of Llama Stack inference servers on Kubernetes" {
            controller = container "Operator Controller Manager" "Reconciles LlamaStackDistribution CRDs and manages lifecycle" "Go 1.24, controller-runtime v0.19.4" {
                llsdController = component "LlamaStackDistribution Controller" "Watches CRDs, creates Deployments/Services/PVCs/NetworkPolicies" "Go Controller"
                kustomizeEngine = component "Kustomize Deployment Engine" "Generates manifests from templates" "kustomize kyaml v0.18.1"
                networkTransformer = component "Network Policy Transformer" "Dynamically generates NetworkPolicy rules" "Plugin"
            }
            metricsProxy = container "kube-rbac-proxy" "Secures metrics endpoint with RBAC" "Go Service"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External Platform"

        inferenceBackends = softwareSystem "Inference Providers" "Backend LLM inference engines" "External Services" {
            ollama = container "Ollama Server" "Ollama inference backend" "11434/TCP HTTP"
            vllm = container "vLLM Server" "vLLM GPU-accelerated inference" "8000/TCP HTTP"
            tgi = container "TGI Server" "HuggingFace Text Generation Inference" "8080/TCP HTTP"
        }

        containerRegistry = softwareSystem "Container Registry" "Stores Llama Stack distribution images" "External (docker.io, quay.io)"
        huggingface = softwareSystem "HuggingFace Hub" "Model weights repository" "External (huggingface.co)"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH/RHOAI"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Platform monitoring stack" "Internal ODH/RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "Internal ODH/RHOAI (Optional)"

        # Relationships
        user -> llamaOperator "Creates LlamaStackDistribution CRDs via kubectl/oc"
        admin -> llamaOperator "Configures feature flags and image overrides via ConfigMaps"

        llamaOperator -> kubernetes "Reconciles CRDs, manages Deployments/Services/PVCs" "HTTPS/6443 (ServiceAccount JWT)"
        llamaOperator -> prometheus "Exposes metrics via ServiceMonitor" "HTTPS/8443 (Bearer Token)"
        llamaOperator -> containerRegistry "Pulls Llama Stack distribution images" "HTTPS/443 (Pull Secrets)"

        inferenceBackends -> huggingface "Downloads model weights (vLLM)" "HTTPS/443 (HF Token)"

        prometheus -> openshiftMonitoring "Integrates with cluster monitoring"
        llamaOperator -> certManager "Optional TLS certificate provisioning" "HTTPS/6443"

        user -> inferenceBackends "Sends inference requests" "HTTP/HTTPS (via Ingress)"
        llamaOperator -> inferenceBackends "Manages and routes to backends" "HTTP"

        # Deployment relationships
        kubernetes -> inferenceBackends "Hosts inference workloads"
    }

    views {
        systemContext llamaOperator "SystemContext" {
            include *
            autoLayout
        }

        container llamaOperator "Containers" {
            include *
            autoLayout
        }

        component controller "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Services" {
                background #d6b656
                color #000000
            }
            element "External" {
                background #f5a623
                color #000000
            }
            element "Internal ODH/RHOAI" {
                background #7ed321
                color #000000
            }
            element "Internal ODH/RHOAI (Optional)" {
                background #a8d99c
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5dade2
                color #ffffff
            }
            element "Component" {
                background #85c1e9
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

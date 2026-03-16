workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys AI inference servers for LLM workloads"
        admin = person "Platform Administrator" "Manages operator and infrastructure"

        llamaOperator = softwareSystem "Llama Stack Kubernetes Operator" "Automates deployment and lifecycle management of Llama Stack AI inference servers on Kubernetes" {
            controller = container "Operator Controller Manager" "Reconciles LlamaStackDistribution CRDs and manages inference deployments" "Go, controller-runtime v0.20+" {
                llsdController = component "LlamaStackDistribution Controller" "Watches and reconciles LlamaStackDistribution custom resources" "Go Controller"
                kustomize = component "Kustomize Transformer" "Generates Kubernetes manifests from templates" "Internal Library"
                distResolver = component "Distribution Resolver" "Maps distribution names to container images" "Internal Component"
                netPolicy = component "Network Policy Manager" "Creates and manages network isolation policies" "Internal Component"
                storage = component "Storage Provisioner" "Creates and manages PersistentVolumeClaims" "Internal Component"
            }

            rbacProxy = container "kube-rbac-proxy" "Secures metrics endpoint with RBAC" "Go Service"

            managedServer = container "Llama Stack Server (Managed)" "Inference server instance created per LlamaStackDistribution CR" "Python/Container" {
                tags "Managed Resource"
            }
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration control plane" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External/Optional"

        ollama = softwareSystem "Ollama" "Ollama inference backend" "Inference Provider"
        vllm = softwareSystem "vLLM" "vLLM inference backend" "Inference Provider"
        tgi = softwareSystem "TGI" "HuggingFace Text Generation Inference backend" "Inference Provider"

        registry = softwareSystem "Container Registry (quay.io)" "Container image storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact storage and distribution" "External"

        clientApp = softwareSystem "Client Application" "Application consuming inference API" "Client"

        # Relationships
        user -> llamaOperator "Creates LlamaStackDistribution CRDs via kubectl"
        admin -> llamaOperator "Monitors operator health and metrics"

        llamaOperator -> kubernetes "Watches CRDs, creates/manages Deployments, Services, NetworkPolicies, PVCs" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        controller -> kubernetes "Reconciles resources" "HTTPS/6443"

        prometheus -> rbacProxy "Scrapes metrics" "HTTPS/8443, Bearer Token"
        rbacProxy -> controller "Proxies to metrics endpoint" "HTTP/8080 (localhost)"

        managedServer -> ollama "Sends inference requests" "HTTP/11434"
        managedServer -> vllm "Sends inference requests" "HTTP/8000"
        managedServer -> tgi "Sends inference requests" "HTTP/8080"
        managedServer -> registry "Pulls distribution images" "HTTPS/443, TLS 1.2+"
        managedServer -> huggingface "Downloads AI models" "HTTPS/443, TLS 1.2+, HF Token"

        clientApp -> managedServer "Sends inference requests" "HTTP/8321, /v1/* endpoints"
        controller -> managedServer "Health checks" "HTTP/8321, /providers"

        llsdController -> kustomize "Uses for manifest generation"
        llsdController -> distResolver "Resolves distribution images"
        llsdController -> netPolicy "Creates network policies"
        llsdController -> storage "Provisions storage"
    }

    views {
        systemContext llamaOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container llamaOperator "Containers" {
            include *
            autoLayout lr
        }

        component controller "Components" {
            include *
            autoLayout tb
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Inference Provider" {
                background #9370DB
                color #ffffff
            }
            element "Client" {
                background #4DB8E8
                color #ffffff
            }
            element "Managed Resource" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

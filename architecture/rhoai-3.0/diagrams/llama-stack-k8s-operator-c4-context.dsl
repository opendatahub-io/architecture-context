workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages AI inference servers using Kubernetes CRs"

        llamaStackOperator = softwareSystem "Llama Stack Kubernetes Operator" "Automates deployment and lifecycle management of Llama Stack AI inference servers" {
            controller = container "Operator Controller Manager" "Reconciles LlamaStackDistribution CRDs and manages Kubernetes resources" "Go, controller-runtime v0.20+" {
                distController = component "LlamaStackDistribution Controller" "Watches and reconciles LlamaStackDistribution custom resources" "Go Controller"
                kustomizeTransformer = component "Kustomize Transformer" "Dynamically generates Kubernetes manifests from templates" "Internal Library"
                distResolver = component "Distribution Resolver" "Maps distribution names to container images" "Internal Component"
                networkMgr = component "Network Policy Manager" "Creates and manages network isolation policies" "Internal Component"
                storageProvisioner = component "Storage Provisioner" "Creates and manages PersistentVolumeClaims for model storage" "Internal Component"
            }

            metricsProxy = container "kube-rbac-proxy" "Secures metrics endpoint with Kubernetes RBAC" "Go Service"

            llamaStackServer = container "Llama Stack Server" "Inference server deployed per LlamaStackDistribution CR" "Python, llama-stack"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.20+)" "External"

        ollama = softwareSystem "Ollama Server" "Backend inference engine for Ollama distribution" "External Provider"
        vllm = softwareSystem "vLLM Server" "Backend inference engine for vLLM distributions" "External Provider"
        tgi = softwareSystem "TGI Server" "Backend inference engine for TGI distribution" "External Provider"

        containerRegistry = softwareSystem "Container Registry (quay.io)" "Stores and serves llama-stack distribution images" "External"
        huggingface = softwareSystem "HuggingFace Hub" "AI model repository for downloading model artifacts" "External"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring (optional)" "External"

        # Relationships
        user -> llamaStackOperator "Creates LlamaStackDistribution CRs via kubectl"
        user -> llamaStackServer "Sends inference requests to" "HTTP/8321"

        llamaStackOperator -> kubernetes "Watches CRDs, creates and manages resources" "HTTPS/6443, TLS 1.2+"

        controller -> metricsProxy "Exposes metrics through" "HTTP/8080 (localhost)"
        metricsProxy -> prometheus "Provides secured metrics to" "HTTPS/8443, Bearer Token"

        llamaStackServer -> ollama "Sends inference requests to" "HTTP/11434"
        llamaStackServer -> vllm "Sends inference requests to" "HTTP/8000"
        llamaStackServer -> tgi "Sends inference requests to" "HTTP/8080"

        llamaStackServer -> containerRegistry "Pulls distribution images from" "HTTPS/443, TLS 1.2+"
        llamaStackServer -> huggingface "Downloads AI models from" "HTTPS/443, TLS 1.2+, Token Auth"

        distController -> kustomizeTransformer "Uses for manifest generation"
        distController -> distResolver "Uses for image resolution"
        distController -> networkMgr "Uses for network policy creation"
        distController -> storageProvisioner "Uses for PVC provisioning"
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

        component controller "OperatorComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Provider" {
                background #e8e8e8
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape person
                background #f5a623
                color #ffffff
            }
        }
    }
}

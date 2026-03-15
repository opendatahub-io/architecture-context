workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages Llama Stack servers for LLM inference"
        admin = person "Platform Administrator" "Configures and manages the operator"

        llamaStackOperator = softwareSystem "Llama Stack Operator" "Kubernetes operator that creates and manages Llama Stack server deployments" {
            controllerManager = container "Controller Manager" "Reconciles LlamaStackDistribution CRs and manages lifecycle" "Go 1.24.6 / controller-runtime v0.22.4" {
                llamaStackController = component "LlamaStackDistribution Controller" "Reconciles LlamaStackDistribution CRs" "Go Reconciler"
                configMapWatcher = component "ConfigMap Watcher" "Watches for configuration changes" "Controller Watch"
                networkPolicyManager = component "NetworkPolicy Manager" "Manages NetworkPolicy resources" "Go Reconciler"
                kustomizeEngine = component "Kustomize Engine" "Renders Kubernetes manifests from templates" "kustomize v0.21.0"
            }
            metricsService = container "Metrics Service" "Exposes Prometheus metrics" "HTTPS/8443"
            healthProbes = container "Health Probes" "Provides liveness and readiness checks" "HTTP/8081"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Managed Llama Stack server instances providing LLM inference APIs" "Managed by Operator" {
            llamaStackPod = container "Llama Stack Pod" "Handles inference requests and routes to providers" "Python / Docker"
            llamaStackService = container "Llama Stack Service" "Exposes Llama Stack API" "ClusterIP/8321"
            storage = container "Persistent Storage" "Stores Llama Stack configuration and state" "PVC (10Gi default)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        ollama = softwareSystem "Ollama" "Local LLM inference provider" "Internal RHOAI"
        vllm = softwareSystem "vLLM" "GPU-accelerated LLM inference provider" "Internal RHOAI"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository and downloads" "External SaaS"
        registry = softwareSystem "Container Registry" "Container image storage" "External"
        ingressController = softwareSystem "Ingress Controller" "External access to Llama Stack servers" "External"

        # User interactions
        user -> llamaStackOperator "Creates LlamaStackDistribution CRs via kubectl"
        user -> llamaStackServer "Sends inference requests" "HTTP(S)/8321"
        admin -> llamaStackOperator "Configures via ConfigMap"

        # Operator interactions
        llamaStackOperator -> kubernetes "Watches CRs, creates/manages resources" "HTTPS/6443, ServiceAccount Token"
        llamaStackOperator -> llamaStackServer "Creates and manages" "Kubernetes API"
        prometheus -> llamaStackOperator "Scrapes metrics" "HTTPS/8443, Bearer Token"

        # Llama Stack Server interactions
        llamaStackServer -> ollama "Inference requests (starter distribution)" "HTTP/11434"
        llamaStackServer -> vllm "Inference requests (vLLM distribution)" "HTTP(S)/8000, Optional Token"
        llamaStackServer -> kubernetes "Accesses ConfigMaps, Secrets" "HTTPS/6443"
        ingressController -> llamaStackServer "Routes external traffic (optional)" "HTTP(S)/8321"

        # vLLM interactions
        vllm -> huggingface "Downloads models" "HTTPS/443, HF Token"

        # Registry interactions
        llamaStackServer -> registry "Pulls container images" "HTTPS/443, Pull Secret"

        # Internal component relationships
        llamaStackController -> kustomizeEngine "Renders manifests"
        llamaStackController -> networkPolicyManager "Manages network policies"
        configMapWatcher -> llamaStackController "Triggers reconciliation"
    }

    views {
        systemContext llamaStackOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container llamaStackOperator "OperatorContainers" {
            include *
            autoLayout lr
        }

        container llamaStackServer "LlamaStackContainers" {
            include *
            autoLayout lr
        }

        component controllerManager "ControllerComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "Software System" {
                background #1168bd
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
                background #08427b
                color #ffffff
                shape person
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "External SaaS" {
                background #f5a623
                color #000000
            }
            element "Managed by Operator" {
                background #4a90e2
                color #ffffff
            }
        }

        theme default
    }
}

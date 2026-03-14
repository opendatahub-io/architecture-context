workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates and deploys Llama Stack instances for LLM inference"
        devOpsEngineer = person "DevOps / Platform Engineer" "Manages operator configuration and infrastructure"

        llamaStackOperator = softwareSystem "Llama Stack Operator" "Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers" {
            controllerManager = container "Controller Manager" "Reconciles LlamaStackDistribution CRs and manages resources" "Go Operator (controller-runtime)" {
                controller = component "LlamaStackDistribution Controller" "Reconciles CR lifecycle" "Go Reconciler"
                kustomizeEngine = component "Kustomize Engine" "Renders Kubernetes manifests" "In-Process Library"
                networkPolicyManager = component "NetworkPolicy Manager" "Manages network isolation" "Go Reconciler"
                configMapWatcher = component "ConfigMap Watcher" "Triggers reconciliation on config changes" "Controller Watch"
            }
            metricsService = container "Metrics Service" "Exposes Prometheus metrics" "kube-rbac-proxy" {
                tags "Monitoring"
            }
            healthProbes = container "Health Probes" "Provides liveness and readiness checks" "HTTP Endpoints" {
                tags "Health"
            }
        }

        llamaStackServer = softwareSystem "Llama Stack Server (Managed)" "Deployed and managed Llama Stack instance" "Managed Resource" {
            deployment = container "Llama Stack Deployment" "Runs Llama Stack server process" "Python/uvicorn"
            service = container "Llama Stack Service" "Exposes API endpoint" "Kubernetes Service"
            storage = container "Persistent Storage" "Stores models and configuration" "PersistentVolumeClaim"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Cluster orchestration and resource management" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"
        ollama = softwareSystem "Ollama Server" "Inference provider for Llama models" "Internal ODH/RHOAI"
        vllm = softwareSystem "vLLM Server" "GPU-accelerated inference provider" "Internal ODH/RHOAI"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact repository" "External Service"
        registry = softwareSystem "Container Registry" "Distribution container images" "External Service"
        ingressController = softwareSystem "Ingress Controller" "External access routing" "External Platform"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Advanced networking and mTLS" "Optional ODH/RHOAI"
        trustedCA = softwareSystem "odh-trusted-ca-bundle" "Trusted CA certificates" "Internal ODH/RHOAI"

        # User interactions
        dataScientist -> llamaStackOperator "Creates LlamaStackDistribution CR via kubectl"
        dataScientist -> llamaStackServer "Sends inference requests" "HTTP/HTTPS 8321/TCP"
        devOpsEngineer -> llamaStackOperator "Configures feature flags and image overrides via ConfigMap"

        # Operator interactions
        llamaStackOperator -> kubernetes "Watches CRs, creates/updates managed resources" "HTTPS/6443 ServiceAccount Token"
        llamaStackOperator -> llamaStackServer "Creates and manages lifecycle" "Kubernetes API"

        # Monitoring
        prometheus -> llamaStackOperator "Scrapes metrics" "HTTPS/8443 Bearer Token"

        # Llama Stack interactions
        llamaStackServer -> ollama "Inference requests (starter distribution)" "HTTP/11434"
        llamaStackServer -> vllm "Inference requests (remote-vllm distribution)" "HTTP/HTTPS/8000"
        llamaStackServer -> trustedCA "Mounts CA certificates for TLS verification" "ConfigMap mount"

        # vLLM dependencies
        vllm -> huggingface "Downloads model artifacts" "HTTPS/443 HF Token"

        # Registry access
        llamaStackOperator -> registry "Pulls operator image" "HTTPS/443 Pull Secret"
        llamaStackServer -> registry "Pulls distribution image" "HTTPS/443 Pull Secret"

        # Optional integrations
        ingressController -> llamaStackServer "Routes external traffic (when exposeRoute: true)" "HTTP/HTTPS"
        llamaStackServer -> serviceMesh "Integrates for mTLS and traffic management (optional)" "Istio sidecar"

        # Internal relationships
        controllerManager -> metricsService "Exposes metrics"
        controllerManager -> healthProbes "Provides health endpoints"
        controller -> kustomizeEngine "Renders manifests"
        controller -> networkPolicyManager "Manages NetworkPolicy resources"
        controller -> configMapWatcher "Watches ConfigMap changes"

        deployment -> service "Exposed by"
        deployment -> storage "Mounts"
    }

    views {
        systemContext llamaStackOperator "SystemContext" {
            include *
            autoLayout lr
            title "Llama Stack Operator - System Context"
            description "Shows how the Llama Stack Operator fits into the ODH/RHOAI ecosystem"
        }

        container llamaStackOperator "OperatorContainers" {
            include *
            include dataScientist
            include devOpsEngineer
            include kubernetes
            include prometheus
            include llamaStackServer
            autoLayout tb
            title "Llama Stack Operator - Container View"
            description "Internal structure of the operator"
        }

        container llamaStackServer "ManagedServerContainers" {
            include *
            include dataScientist
            include ollama
            include vllm
            include storage
            include trustedCA
            autoLayout tb
            title "Llama Stack Server - Container View"
            description "Managed Llama Stack server components"
        }

        component controllerManager "ControllerComponents" {
            include *
            autoLayout lr
            title "Controller Manager - Component View"
            description "Internal components of the controller manager"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #cc6600
                color #ffffff
            }
            element "Internal ODH/RHOAI" {
                background #6aa84f
                color #ffffff
            }
            element "Optional ODH/RHOAI" {
                background #93c47d
                color #000000
            }
            element "Managed Resource" {
                background #674ea7
                color #ffffff
            }
            element "Monitoring" {
                background #f1c232
                color #000000
            }
            element "Health" {
                background #e06666
                color #ffffff
            }
        }
    }
}

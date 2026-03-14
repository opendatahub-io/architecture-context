workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Llama Stack deployments for model inference"
        admin = person "Platform Administrator" "Installs and configures Llama Stack Operator in RHOAI"

        llamaOperator = softwareSystem "Llama Stack Operator" "Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers with various inference distributions" {
            controller = container "Controller Manager" "Reconciles LlamaStackDistribution CRs and manages Kubernetes resources" "Go Operator (controller-runtime v0.22.4)" {
                reconciler = component "LlamaStackDistribution Controller" "Main reconciliation loop" "Go"
                kustomize = component "Kustomize Engine" "Renders Kubernetes manifests from templates" "kustomize v0.21.0"
                configWatcher = component "ConfigMap Watcher" "Triggers reconciliation on config changes" "Go"
                netpolManager = component "NetworkPolicy Manager" "Creates/deletes NetworkPolicy based on feature flags" "Go"
            }
            metrics = container "Metrics Service" "Exposes Prometheus metrics for monitoring" "HTTP Service (8443/TCP HTTPS)"
            health = container "Health Probes" "Provides liveness and readiness checks" "HTTP Service (8081/TCP HTTP)"
        }

        llamaStack = softwareSystem "Llama Stack Server" "Managed deployment providing Meta's Llama Stack API for model inference" {
            deployment = container "Llama Stack Deployment" "Running Llama Stack distribution" "Python/uvicorn"
            service = container "Service" "ClusterIP service exposing API" "Kubernetes Service (8321/TCP)"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"
        ollama = softwareSystem "Ollama Server" "Local inference provider for Llama models" "External Inference"
        vllm = softwareSystem "vLLM Server" "GPU-accelerated inference provider" "External Inference"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact repository" "External Service"
        registry = softwareSystem "Container Registry" "Container image storage" "External Service"

        # Internal ODH/RHOAI Dependencies
        dashboard = softwareSystem "ODH Dashboard" "RHOAI platform dashboard" "Internal ODH"
        servicemesh = softwareSystem "Service Mesh (Istio)" "Service mesh for advanced networking" "Internal ODH"
        cabundle = softwareSystem "odh-trusted-ca-bundle" "Trusted CA certificates ConfigMap" "Internal ODH"

        # User interactions
        user -> llamaOperator "Creates LlamaStackDistribution CR via kubectl/oc"
        user -> llamaStack "Sends inference requests"
        admin -> llamaOperator "Installs and configures via Operator Lifecycle Manager"
        admin -> dashboard "Manages RHOAI platform"

        # Operator interactions
        llamaOperator -> kubernetes "Manages CRs, Deployments, Services, NetworkPolicies, etc." "HTTPS/6443 (TLS 1.2+, ServiceAccount Token)"
        llamaOperator -> llamaStack "Creates and manages lifecycle" "Kubernetes API"
        prometheus -> metrics "Scrapes metrics" "HTTPS/8443 (TLS, Bearer Token)"

        # Llama Stack interactions
        llamaStack -> ollama "Forwards inference requests (starter distribution)" "HTTP/11434"
        llamaStack -> vllm "Forwards inference requests (remote-vllm, meta-reference-gpu)" "HTTP/HTTPS/8000 (Optional Token)"
        llamaStack -> registry "Pulls distribution images" "HTTPS/443 (TLS 1.2+, Pull Secret)"
        llamaStack -> cabundle "Uses TLS certificates for verification"
        llamaStack -> servicemesh "Optional service mesh integration"

        # vLLM interactions
        vllm -> huggingface "Downloads model artifacts on first request" "HTTPS/443 (TLS 1.2+, HF Token)"

        # Dashboard integration
        dashboard -> llamaOperator "Future: UI-based management of Llama Stack deployments"
    }

    views {
        systemContext llamaOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container llamaOperator "OperatorContainers" {
            include *
            include user
            include kubernetes
            include prometheus
            autoLayout lr
        }

        component controller "ControllerComponents" {
            include *
            autoLayout lr
        }

        container llamaStack "LlamaStackContainers" {
            include *
            include user
            include ollama
            include vllm
            include registry
            autoLayout lr
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Monitoring" {
                background #999999
                color #ffffff
            }
            element "External Inference" {
                background #cc9900
                color #ffffff
            }
            element "External Service" {
                background #cc6666
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6fb3e0
                color #ffffff
            }
            element "Component" {
                background #85c1e2
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

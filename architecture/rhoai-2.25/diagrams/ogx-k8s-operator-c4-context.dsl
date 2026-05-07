workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Creates LlamaStackDistribution CRs to deploy AI inference servers"

        llamaStackOperator = softwareSystem "Llama Stack K8s Operator" "Kubernetes operator managing lifecycle of Llama Stack AI inference server distributions" {
            controller = container "llama-stack-k8s-operator" "Reconciles LlamaStackDistribution CRs, manages full deployment stacks" "Go Operator (controller-runtime)"
            kustomizePipeline = container "Kustomize Manifest Pipeline" "Renders and transforms base Kubernetes manifests with per-instance customization" "Embedded kustomize + Go plugins"
            npTransformer = container "NetworkPolicy Transformer" "Dynamically builds NetworkPolicy ingress rules from CR spec.network" "Go kustomize plugin"
        }

        llamaStackServer = softwareSystem "Llama Stack Distribution Server" "AI inference server running Llama Stack distribution (remote-vllm, ollama, tgi, etc.)" "Managed Workload"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Infrastructure"
        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys and manages this operator" "Internal RHOAI/ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        configMaps = softwareSystem "ConfigMaps" "Configuration and CA certificate bundles (user-config, odh-trusted-ca-bundle)" "Kubernetes Resources"
        openshiftSCC = softwareSystem "OpenShift SCC" "Security Context Constraints (anyuid) for workload pods" "Infrastructure"

        # Relationships
        user -> llamaStackOperator "Creates LlamaStackDistribution CRs via kubectl" "HTTPS/443"
        platformOperator -> llamaStackOperator "Deploys operator via kustomize overlays" "Kustomize"

        llamaStackOperator -> k8sApi "CRUD operations on Deployments, Services, PVCs, NetworkPolicies, Ingresses, ConfigMaps, ClusterRoleBindings" "HTTPS/443 TLS 1.2+"
        llamaStackOperator -> llamaStackServer "Polls /v1/health, /v1/providers, /v1/version for status" "HTTP/8321"
        llamaStackOperator -> configMaps "Watches for changes, triggers rolling restarts on content hash changes"
        llamaStackOperator -> openshiftSCC "Creates ClusterRoleBindings to anyuid SCC for workload ServiceAccounts"

        prometheus -> llamaStackOperator "Scrapes /metrics endpoint" "HTTPS/8443"

        # Internal container relationships
        controller -> kustomizePipeline "Invokes manifest rendering"
        kustomizePipeline -> npTransformer "Applies NetworkPolicy transformation"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI/ODH" {
                background #7ed321
                color #ffffff
            }
            element "Managed Workload" {
                background #9b59b6
                color #ffffff
            }
            element "Kubernetes Resources" {
                background #f5a623
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

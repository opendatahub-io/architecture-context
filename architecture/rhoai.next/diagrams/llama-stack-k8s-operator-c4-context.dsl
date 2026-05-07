workspace {
    model {
        admin = person "Platform Admin" "Creates and manages LlamaStackDistribution custom resources"
        client = person "External Client" "Consumes Llama Stack API endpoints for AI inference"

        llamaOperator = softwareSystem "llama-stack-k8s-operator" "Kubernetes operator managing Llama Stack distribution server deployments on OpenShift/Kubernetes" {
            controller = container "Reconciler" "Reconciles LlamaStackDistribution CRs, manages lifecycle of per-instance resources" "Go (controller-runtime)"
            kustomizePipeline = container "Kustomize Pipeline" "Renders base YAML manifests with plugin transformations (NamePrefix, Namespace, FieldMutator, NetworkPolicy)" "Go (kustomize/api)"
            caBundleManager = container "CA Bundle Manager" "Aggregates and validates PEM/X.509 CA certificates from user and platform sources" "Go (crypto/x509)"
            directClient = container "DirectClient" "Non-cached Kubernetes client for reading ConfigMaps without operator labels" "Go (controller-runtime)"
        }

        llamaServer = softwareSystem "Llama Stack Server" "Meta's AI application framework server (managed pods)" "Managed"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "Infrastructure"
        ingressController = softwareSystem "OpenShift Ingress Controller" "Routes external HTTP traffic to cluster services" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Platform-managed trusted CA certificates ConfigMap" "Internal RHOAI"
        openshiftSCC = softwareSystem "OpenShift SCC System" "Security Context Constraints for pod permissions" "Infrastructure"

        admin -> llamaOperator "Creates LlamaStackDistribution CR via kubectl/API"
        llamaOperator -> k8sAPI "CRUD resources, leader election, status updates" "HTTPS/443 TLS 1.2+ Bearer Token"
        llamaOperator -> llamaServer "Probes /v1/health, /v1/providers, /v1/version" "HTTP/8321 plaintext"
        llamaOperator -> odhTrustedCA "Reads platform CA certificates" "Kubernetes API"
        llamaOperator -> openshiftSCC "Binds anyuid SCC to instance ServiceAccounts" "RBAC"
        client -> ingressController "AI inference requests (when exposeRoute=true)" "HTTP/80"
        ingressController -> llamaServer "Forwards to instance service" "HTTP/8321"
        prometheus -> llamaOperator "Scrapes operator metrics" "HTTPS/8443 TLS Bearer Token"

        controller -> kustomizePipeline "Renders per-instance manifests"
        controller -> caBundleManager "Aggregates CA certificates"
        controller -> directClient "Reads user and operator ConfigMaps"
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

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Managed" {
                background #50c878
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

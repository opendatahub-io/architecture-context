workspace {
    model {
        user = person "Data Scientist / Admin" "Creates and manages Llama Stack distribution instances via kubectl or GitOps"

        llamaStackOperator = softwareSystem "llama-stack-k8s-operator" "Kubernetes operator managing LlamaStackDistribution CRs to deploy Llama Stack AI inference server instances" {
            controller = container "LlamaStackDistribution Controller" "Reconciles LlamaStackDistribution CRs; manages full lifecycle of per-instance resources" "Go, controller-runtime"
            kustomizePipeline = container "Kustomize Pipeline" "Renders base manifests with plugin transforms: name prefix, namespace, field mutation, NetworkPolicy" "Go, kustomize/api"
            caBundleManager = container "CA Bundle Manager" "Validates PEM/X.509 certificates, aggregates from user + ODH sources into managed ConfigMap" "Go, crypto/x509"
            directClient = container "Direct Client" "Reads ConfigMaps without informer cache for user-referenced and operator-config data" "Go, controller-runtime client.Reader"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Meta's AI application framework server; deployed and managed by the operator" "Managed"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management, authentication, and authorization" "Platform"
        odhCACM = softwareSystem "odh-trusted-ca-bundle" "Platform ConfigMap with trusted CA certificates for RHOAI/ODH" "Internal Platform"
        openshiftSCC = softwareSystem "OpenShift SCC System" "Security Context Constraints for pod security (anyuid)" "Platform"
        ingressController = softwareSystem "OpenShift Ingress Controller" "Routes external HTTP traffic to cluster services" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        # User interactions
        user -> llamaStackOperator "Creates LlamaStackDistribution CR" "kubectl / GitOps"
        user -> llamaStackServer "Sends inference requests (when exposed)" "HTTP/8321 or Ingress/80"

        # Operator internal
        controller -> kustomizePipeline "Renders per-instance manifests"
        controller -> caBundleManager "Validates and aggregates CA certificates"
        controller -> directClient "Reads user/operator ConfigMaps (uncached)"

        # Operator → external
        llamaStackOperator -> k8sAPI "CR reconciliation, resource CRUD, leader election" "HTTPS/443, TLS 1.2+, SA Bearer Token"
        llamaStackOperator -> llamaStackServer "Health probes, provider/version queries" "HTTP/8321, No TLS"
        llamaStackOperator -> odhCACM "Auto-detects platform CA certificates" "Kubernetes API, DirectClient"

        # Platform interactions
        ingressController -> llamaStackServer "Forwards external traffic" "HTTP/8321"
        prometheus -> llamaStackOperator "Scrapes operator metrics" "HTTPS/8443, Bearer Token"
        openshiftSCC -> llamaStackServer "Grants anyuid SCC via RoleBinding" "RBAC"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
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

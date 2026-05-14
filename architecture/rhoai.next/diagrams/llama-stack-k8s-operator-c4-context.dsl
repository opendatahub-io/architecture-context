workspace {
    model {
        admin = person "Platform Admin" "Deploys and manages Llama Stack instances via LlamaStackDistribution CRs"
        datascientist = person "Data Scientist" "Consumes Llama Stack inference APIs for AI application development"

        llamaStackOperator = softwareSystem "llama-stack-k8s-operator" "Kubernetes operator managing lifecycle of Llama Stack distribution server deployments on OpenShift/Kubernetes" {
            controller = container "Reconciler" "controller-runtime based reconcile loop; watches LlamaStackDistribution CRs and manages per-instance resources" "Go"
            kustomizer = container "Kustomize Pipeline" "Renders base manifests into instance-specific K8s resources via plugin pipeline (name prefix, namespace, field mutation, NetworkPolicy transform)" "Go / kustomize API"
            caManager = container "CA Bundle Manager" "Aggregates CA certificates from user bundles and ODH trusted CA bundle; validates PEM/X.509 with security limits" "Go / crypto/x509"
            webhook = container "Validating Webhook" "Validates OGXServer CRs on create/update: distribution name, unique providers, model-provider references" "Go / controller-runtime"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Meta's AI application framework server; managed by the operator as Deployments" "Managed"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management, RBAC, leader election" "External"
        openshiftIngress = softwareSystem "OpenShift Ingress Controller" "Routes external HTTP traffic to cluster services via Ingress resources" "External"
        openshiftSCC = softwareSystem "OpenShift SCC System" "Security Context Constraints for pod security; provides anyuid SCC" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor scraping" "External"

        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Platform-level trusted CA certificate ConfigMap (odh-trusted-ca-bundle)" "Internal RHOAI"
        operatorConfig = softwareSystem "Operator Config" "Feature flags and image overrides ConfigMap (llama-stack-operator-config)" "Internal RHOAI"

        # Relationships
        admin -> llamaStackOperator "Creates LlamaStackDistribution CRs" "kubectl / YAML"
        datascientist -> llamaStackServer "Sends inference requests" "HTTP/8321"

        llamaStackOperator -> k8sAPI "CRUD resources, leader election, status updates" "HTTPS/443 TLS 1.2+"
        llamaStackOperator -> llamaStackServer "Probes health, providers, version" "HTTP/8321"
        llamaStackOperator -> odhTrustedCA "Reads platform CA certificates" "Kubernetes API"
        llamaStackOperator -> operatorConfig "Reads feature flags and image overrides" "Kubernetes API"
        llamaStackOperator -> openshiftSCC "Binds anyuid SCC to instance ServiceAccounts" "RoleBinding"

        openshiftIngress -> llamaStackServer "Routes external traffic when exposeRoute=true" "HTTP/8321"
        prometheus -> llamaStackOperator "Scrapes operator metrics" "HTTPS/8443 Bearer Token"

        # Internal container relationships
        controller -> kustomizer "Renders manifests for each CR instance"
        controller -> caManager "Validates and aggregates CA certificates"
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
                color #ffffff
            }
            element "Managed" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

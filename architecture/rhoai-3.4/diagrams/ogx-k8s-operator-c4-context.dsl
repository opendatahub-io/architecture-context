workspace {
    model {
        dataScientist = person "Data Scientist" "Creates LlamaStackDistribution CRs to deploy AI model inference servers"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures CA bundles and feature flags"

        llamaStackOperator = softwareSystem "LlamaStack K8s Operator" "Kubernetes operator managing LlamaStack distribution server deployments" {
            controller = container "LlamaStackDistribution Reconciler" "Watches LlamaStackDistribution CRs and reconciles desired state" "Go (controller-runtime)"
            kustomizer = container "Kustomize Renderer" "Renders base manifests and applies transformer plugins" "Go (kustomize/api)"
            caManager = container "CA Bundle Manager" "Aggregates and validates X.509 certificates from multiple ConfigMaps" "Go (crypto/x509)"
            featureFlags = container "Feature Flags" "Reads operator config for NetworkPolicy enablement and image overrides" "Go"
        }

        llamaStackServer = softwareSystem "LlamaStack Server" "Meta Llama AI model distribution server managed by the operator" {
            serverPod = container "LlamaStack Server Pod" "Serves AI model inference via HTTP API" "Python (uvicorn)" "8321/TCP"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftSCC = softwareSystem "OpenShift SCC" "Security Context Constraints (anyuid) for PVC mount privileges" "External"
        prometheus = softwareSystem "Prometheus Monitoring" "Metrics collection via ServiceMonitor" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Deploys and manages the LlamaStack operator" "Internal RHOAI"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Platform-managed CA certificate ConfigMap" "Internal RHOAI"
        ingressController = softwareSystem "Ingress Controller" "Routes external traffic to cluster services" "External"

        # User interactions
        dataScientist -> llamaStackOperator "Creates LlamaStackDistribution CR" "kubectl / RHOAI Dashboard"
        platformAdmin -> odhTrustedCA "Manages platform CA certificates" "ConfigMap"
        platformAdmin -> llamaStackOperator "Configures feature flags and image overrides" "ConfigMap"

        # Operator interactions
        llamaStackOperator -> kubernetesAPI "Watches CRDs, CRUD managed resources, reads ConfigMaps" "HTTPS/443, TLS 1.2+, SA Bearer Token"
        llamaStackOperator -> llamaStackServer "Health checks, provider/version introspection" "HTTP/8321, plaintext"
        llamaStackOperator -> odhTrustedCA "Reads platform CA certificates for aggregation" "HTTPS/443 via K8s API"

        # Internal container interactions
        controller -> kustomizer "Renders manifests for CR"
        controller -> caManager "Aggregates CA bundles"
        controller -> featureFlags "Checks feature flags"

        # External integrations
        rhoaiOperator -> llamaStackOperator "Deploys operator via kustomize overlays"
        prometheus -> llamaStackOperator "Scrapes metrics" "HTTPS/8443, TLS, Bearer Token"
        llamaStackServer -> openshiftSCC "Uses anyuid SCC via RoleBinding" "N/A"
        ingressController -> llamaStackServer "Routes external traffic when exposeRoute=true" "HTTP/8321"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

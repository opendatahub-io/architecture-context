workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Llama Stack AI inference server deployments"
        clusterAdmin = person "Cluster Admin" "Deploys and configures the operator on the platform"

        llamaStackOperator = softwareSystem "Llama Stack K8s Operator" "Manages lifecycle of Llama Stack distribution servers via LlamaStackDistribution CRDs" {
            controller = container "Reconciler Controller" "controller-runtime based reconciliation loop managing LlamaStackDistribution CRs" "Go"
            kustomizePipeline = container "Kustomize Pipeline" "In-process kustomize rendering with Go-based transformer plugins (FieldMutator, NamePrefix, Namespace, NetworkPolicyTransformer)" "Go"
            caBundleManager = container "CA Bundle Manager" "Aggregates CA certificates from explicit ConfigMaps and auto-detected odh-trusted-ca-bundle with PEM/X.509 validation" "Go"
            statusProbe = container "Status Probe" "Queries Llama Stack server /v1/health, /v1/providers, /v1/version endpoints for rich status" "Go"
            kubeRbacProxy = container "kube-rbac-proxy" "Sidecar proxy exposing Prometheus metrics with RBAC auth" "Go Sidecar"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "AI inference server running Llama Stack distribution images" {
            serverPod = container "Server Pod" "Llama Stack distribution container serving inference API on 8321/TCP" "Container"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for managing Kubernetes resources" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        ingressController = softwareSystem "Ingress Controller" "Routes external HTTP traffic to cluster services" "External"
        openShiftSCC = softwareSystem "OpenShift SCC" "Security Context Constraints for container permissions" "External"

        rhoaiOperator = softwareSystem "RHOAI / ODH Operator" "Platform operator that deploys the Llama Stack operator via kustomize overlays" "Internal Platform"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Platform-wide trusted CA certificates ConfigMap" "Internal Platform"

        # Relationships
        dataScientist -> llamaStackOperator "Creates LlamaStackDistribution CRs via kubectl"
        clusterAdmin -> rhoaiOperator "Deploys operator via platform installer"

        rhoaiOperator -> llamaStackOperator "Deploys via kustomize overlays" "Kustomize"

        controller -> kustomizePipeline "Renders per-instance manifests"
        controller -> caBundleManager "Aggregates CA certificates"
        controller -> statusProbe "Triggers status probing"

        controller -> k8sAPI "CRUD on Deployments, Services, ConfigMaps, NetworkPolicies, Ingresses, PVCs, HPAs, PDBs, RoleBindings" "HTTPS/443 TLS 1.2+ SA Token"
        statusProbe -> serverPod "Probes /v1/health, /v1/providers, /v1/version" "HTTP/8321"
        caBundleManager -> odhTrustedCA "Auto-detects and reads CA certificates" "ConfigMap"

        prometheus -> kubeRbacProxy "Scrapes operator metrics" "HTTPS/8443 TLS Bearer Token"

        llamaStackOperator -> llamaStackServer "Creates and manages server deployments"
        llamaStackOperator -> openShiftSCC "Binds ServiceAccount to anyuid SCC" "RoleBinding"

        ingressController -> serverPod "Routes external traffic when exposeRoute=true" "HTTP/8321"
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
            element "Internal Platform" {
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

workspace {
    model {
        user = person "Data Scientist" "Creates and manages Llama Stack inference deployments via LlamaStackDistribution CRs"
        admin = person "Platform Admin" "Deploys and configures the operator via kustomize overlays"

        llamaStackOperator = softwareSystem "Llama Stack K8s Operator" "Kubernetes operator managing lifecycle of Llama Stack AI inference server deployments" {
            controller = container "Operator Controller" "controller-runtime based reconciler; watches LlamaStackDistribution CRs and manages child resources" "Go"
            kustomizePipeline = container "Kustomize Pipeline" "In-process kustomize rendering with Go transformer plugins (FieldMutator, NamePrefix, Namespace, NetworkPolicyTransformer)" "Go"
            caBundleManager = container "CA Bundle Manager" "Aggregates and validates PEM/X.509 certificates from ODH platform and user sources; max 10MB/1000 certs" "Go"
            statusProber = container "Status Prober" "Queries Llama Stack server /v1/health, /v1/providers, /v1/version endpoints" "Go"
            rbacProxy = container "kube-rbac-proxy" "Sidecar protecting /metrics endpoint via Bearer Token auth" "Go"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "AI inference server pod running Llama Stack distribution image" {
            serverPod = container "Server Pod" "Runs inference workloads; exposes /v1/* API on port 8321" "Container"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD and watch operations" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Infrastructure"
        odhPlatform = softwareSystem "ODH/RHOAI Platform" "Parent platform providing trusted CA bundles and operator deployment" "Internal Platform"
        openshiftSCC = softwareSystem "OpenShift SCC" "Security Context Constraints providing anyuid permissions" "Infrastructure"
        ingressController = softwareSystem "Ingress Controller" "Kubernetes Ingress for optional external access" "Infrastructure"

        # User interactions
        user -> llamaStackOperator "Creates LlamaStackDistribution CRs via kubectl"
        admin -> llamaStackOperator "Deploys operator via kustomize overlays"

        # Internal container interactions
        controller -> kustomizePipeline "Renders per-instance K8s manifests"
        controller -> caBundleManager "Aggregates CA certificates"
        controller -> statusProber "Triggers status probing"

        # External interactions
        llamaStackOperator -> k8sApi "CRUD on Deployments, Services, ConfigMaps, NetworkPolicies, Ingresses, PVCs, HPAs, PDBs, RoleBindings" "HTTPS/443, TLS 1.2+"
        llamaStackOperator -> llamaStackServer "Probes /v1/health, /v1/providers, /v1/version" "HTTP/8321"
        llamaStackOperator -> odhPlatform "Reads odh-trusted-ca-bundle ConfigMap" "K8s API"
        llamaStackOperator -> openshiftSCC "Binds per-instance SA to anyuid SCC" "RoleBinding"
        prometheus -> llamaStackOperator "Scrapes /metrics via kube-rbac-proxy" "HTTPS/8443, Bearer Token"
        ingressController -> llamaStackServer "Routes external traffic when exposeRoute=true" "HTTP/8321"
        user -> llamaStackServer "Sends inference requests" "HTTP/8321"
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
            element "Infrastructure" {
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workspaces on OpenShift"

        kubeflowNotebook = softwareSystem "Kubeflow Notebook Controller" "Manages Jupyter notebook server lifecycle on OpenShift including pod creation, idle culling, Gateway API ingress, kube-rbac-proxy authentication, and data science integrations" {
            kfController = container "odh-kf-notebook-controller" "Upstream Kubeflow controller managing Notebook CR lifecycle (StatefulSet, Service, idle culling)" "Go Operator (controller-runtime)"
            odhController = container "odh-notebook-controller" "RHOAI extension adding kube-rbac-proxy injection, Gateway API HTTPRoute ingress, NetworkPolicies, DSPA/MLflow/Feast integrations, admission webhooks" "Go Operator (controller-runtime)"
            reconcileHelper = container "common/reconcilehelper" "Shared reconciliation utilities for Deployment, Service, StatefulSet resources" "Go Library"
        }

        # External Dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD watches, resource CRUD, RBAC" "External"
        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Platform gateway for external notebook ingress via HTTPRoutes" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy (odh-kube-auth-proxy)" "Authentication proxy sidecar performing SubjectAccessReview" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Auto-provisions and rotates TLS certificates for Services" "External"

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys both controllers via kustomize manifests" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines Operator (DSPA)" "Provides pipeline storage config for Elyra runtime secrets" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking with per-notebook RoleBindings" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores and serves ML model metadata" "Internal RHOAI"

        # OpenShift APIs
        openshiftImageStream = softwareSystem "OpenShift ImageStream" "Resolves notebook container images from ImageStream tags" "External"
        openshiftProxy = softwareSystem "OpenShift Proxy CR" "Cluster-wide proxy configuration (HTTP_PROXY, HTTPS_PROXY)" "External"

        # User workloads
        jupyterNotebook = softwareSystem "Jupyter Notebook Server" "User notebook pods running Jupyter with kernels and terminals" "Workload"

        # Monitoring
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        dataScientist -> kubeflowNotebook "Creates Notebook CRs via kubectl/Dashboard"
        dataScientist -> jupyterNotebook "Accesses notebooks via browser through Gateway"

        rhodsOperator -> kubeflowNotebook "Deploys and manages" "Kustomize"

        kfController -> k8sAPI "StatefulSet, Service, Pod CRUD" "HTTPS/6443"
        kfController -> jupyterNotebook "Polls /api/kernels, /api/terminals for idle culling" "HTTP/8888"
        kfController -> reconcileHelper "Uses reconciliation utilities"

        odhController -> k8sAPI "CRD watches, HTTPRoute/NetworkPolicy/RBAC CRUD" "HTTPS/6443"
        odhController -> gatewayAPI "Creates HTTPRoutes, discovers hostname" "HTTPS/6443"
        odhController -> openshiftImageStream "Resolves container images from tags" "HTTPS/6443"
        odhController -> dspa "Reads pipeline storage config" "HTTPS/6443"
        odhController -> mlflow "References ClusterRole for RoleBindings" "N/A"
        odhController -> openshiftProxy "Reads cluster proxy config" "HTTPS/6443"
        odhController -> reconcileHelper "Uses reconciliation utilities"

        kubeRBACProxy -> k8sAPI "SubjectAccessReview for auth" "HTTPS/6443"
        kubeRBACProxy -> jupyterNotebook "Forwards authenticated requests" "HTTP/8888"

        prometheus -> kubeflowNotebook "Scrapes metrics" "HTTP/8080"
    }

    views {
        systemContext kubeflowNotebook "SystemContext" {
            include *
            autoLayout
        }

        container kubeflowNotebook "Containers" {
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
            element "Workload" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

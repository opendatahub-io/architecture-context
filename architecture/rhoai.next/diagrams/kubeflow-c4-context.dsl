workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workspaces for ML experimentation"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and namespaces"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle of Jupyter notebook workspaces on Kubernetes with per-notebook auth, networking, and platform integrations" {
            kfController = container "odh-kf-notebook-controller" "Upstream Kubeflow controller: manages StatefulSet, Service, VirtualService lifecycle and idle-notebook culling" "Go Controller (controller-runtime)"
            odhController = container "odh-notebook-controller" "RHOAI/ODH controller: manages HTTPRoutes, kube-rbac-proxy injection, NetworkPolicies, DSPA secrets, MLflow/Feast integration" "Go Controller (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for Notebook CRs — injects sidecars, resolves images, prevents restart-causing mutations" "Go HTTPS Server"
            reconcileHelper = container "reconcilehelper" "Shared utilities for reconciling Deployments, Services, StatefulSets, and VirtualServices" "Go Library"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        gateway = softwareSystem "Gateway (data-science-gateway)" "Gateway API ingress controller for notebook routing" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar container for per-notebook RBAC authentication via SubjectAccessReview" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Pipeline orchestration platform providing Elyra runtime configuration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking and model registry" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store integration for notebook workspaces" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Container image resolution and tagging" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys this component via kustomize manifests" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning for cluster services" "External"
        trustedCaBundle = softwareSystem "odh-trusted-ca-bundle" "Cluster-wide CA certificate bundle for notebook containers" "Internal RHOAI"

        # User interactions
        dataScientist -> kubeflow "Creates Notebook CR via kubectl/Dashboard"
        dataScientist -> gateway "Accesses notebook UI via browser" "HTTPS/443"
        platformAdmin -> rhoaiOperator "Configures RHOAI platform"

        # Internal container interactions
        odhController -> webhookServer "Serves admission requests" "HTTPS/8443"
        kfController -> reconcileHelper "Uses shared reconcile utilities"

        # External interactions
        kfController -> kubernetes "CRUD: StatefulSets, Services, Pods, Events, Notebooks" "HTTPS/6443"
        odhController -> kubernetes "CRUD: HTTPRoutes, NetworkPolicies, Secrets, RBAC, ConfigMaps" "HTTPS/6443"
        kubernetes -> webhookServer "Sends admission reviews" "HTTPS/8443"

        kubeflow -> gateway "Creates HTTPRoutes referencing Gateway as parentRef" "HTTPS/6443"
        kubeflow -> kubeRBACProxy "Injects as sidecar into notebook pods" "HTTPS/8443"
        kubeflow -> dspa "Watches DSPA CRs for Elyra runtime secret construction" "HTTPS/6443"
        kubeflow -> mlflow "Creates RoleBindings for mlflow-operator-mlflow-integration ClusterRole" "HTTPS/6443"
        kubeflow -> feast "Mounts feast-config ConfigMap when label is set" "HTTPS/6443"
        kubeflow -> imageStreams "Resolves notebook images from ImageStream tags" "HTTPS/6443"
        kubeflow -> trustedCaBundle "Watches and propagates CA certificates to notebook namespaces" "HTTPS/6443"

        rhoaiOperator -> kubeflow "Deploys via kustomize manifests"
        serviceCa -> kubeflow "Provisions TLS certificates for webhook and kube-rbac-proxy"

        gateway -> kubeRBACProxy "Routes notebook traffic" "HTTPS/8443"
    }

    views {
        systemContext kubeflow "SystemContext" {
            include *
            autoLayout
        }

        container kubeflow "Containers" {
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
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

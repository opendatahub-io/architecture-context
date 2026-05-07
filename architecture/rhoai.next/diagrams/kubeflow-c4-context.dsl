workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches via RHOAI Dashboard or kubectl"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform, manages namespaces and RBAC"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle, networking, authentication, and integrations for Jupyter notebook workbenches on RHOAI" {
            notebookController = container "notebook-controller" "Core notebook lifecycle: StatefulSet/Service creation, pod status mirroring, idle notebook culling via Jupyter API polling" "Go Operator (controller-runtime)"
            odhNotebookController = container "odh-notebook-controller" "RHOAI extensions: kube-rbac-proxy sidecar injection, HTTPRoute/ReferenceGrant management, NetworkPolicy creation, DSPA/MLflow/Feast integrations, mutating/validating webhooks" "Go Operator (controller-runtime)"
            commonLib = container "common" "Shared reconciliation helpers for Deployment, Service, StatefulSet, VirtualService resources" "Go Library"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for Notebook CR (image resolution, sidecar injection, config sync, validation)" "HTTPS 8443/TCP"
        }

        notebookPod = softwareSystem "Notebook Pod" "Jupyter notebook workbench running as StatefulSet-managed pod with optional kube-rbac-proxy sidecar" "Internal"

        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Gateway and HTTPRoute-based ingress for notebook access with TLS termination" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar injected into notebook pods; validates tokens via TokenReview/SubjectAccessReview" "Internal"

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Core platform API server for all resource CRUD, RBAC, admission webhooks" "External"
        openShiftAPIs = softwareSystem "OpenShift Extensions" "ImageStreams, Routes, OAuthClients, Proxy config, Service CA" "External"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Pipeline configuration and S3 credential management for Elyra integration" "Internal ODH"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking integration via ClusterRole bindings and env var injection" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store integration via ConfigMap mounting" "Internal ODH"
        certManager = softwareSystem "OpenShift Service CA" "Provides TLS certificates for webhook and kube-rbac-proxy services" "External"

        # Relationships
        dataScientist -> kubeflow "Creates Notebook CR via kubectl/Dashboard"
        dataScientist -> gatewayAPI "Accesses notebook via browser" "HTTPS/443"
        platformAdmin -> kubernetes "Manages namespaces, RBAC, platform config"

        kubeflow -> kubernetes "CRUD on StatefulSets, Services, Secrets, ConfigMaps, NetworkPolicies, HTTPRoutes, ReferenceGrants" "HTTPS/6443"
        kubeflow -> openShiftAPIs "Resolves ImageStreams, reads Routes, manages OAuthClients" "HTTPS/6443"
        kubeflow -> dspa "Reads DSPA CR for S3 config, creates pipeline secrets" "HTTPS/6443"
        kubeflow -> mlflow "Creates RoleBinding to mlflow-integration ClusterRole" "HTTPS/6443"
        kubeflow -> feast "Mounts feast-config ConfigMap into notebook pods" "N/A"
        kubeflow -> certManager "Obtains TLS certificates for webhook and sidecar" "Auto"
        kubeflow -> notebookPod "Creates and manages notebook pod lifecycle" "HTTP/8888"
        kubeflow -> gatewayAPI "Creates HTTPRoutes for notebook ingress" "HTTPS/6443"

        gatewayAPI -> kubeRBACProxy "Routes authenticated traffic" "HTTPS/8443"
        kubeRBACProxy -> kubernetes "TokenReview, SubjectAccessReview" "HTTPS/6443"
        kubeRBACProxy -> notebookPod "Proxies authenticated requests" "HTTP/8888"

        notebookController -> commonLib "Uses reconciliation helpers"
        odhNotebookController -> commonLib "Uses reconciliation helpers"
        odhNotebookController -> webhookServer "Serves admission webhooks"

        kubernetes -> webhookServer "Invokes admission webhooks" "HTTPS/8443"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #4a90e2
                color #ffffff
            }
            element "Internal" {
                background #b8d4e3
                color #333333
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

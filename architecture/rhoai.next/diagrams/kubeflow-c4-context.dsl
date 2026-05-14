workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook workbenches via RHOAI Dashboard or kubectl"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle, networking, authentication, and integrations for Jupyter notebook workbenches on RHOAI" {
            notebookController = container "notebook-controller" "Core notebook lifecycle: StatefulSet, Service, VirtualService creation; pod status mirroring; idle notebook culling via Jupyter kernel/terminal API polling" "Go Operator (controller-runtime)"
            cullingController = container "Culling Controller" "Periodically polls Jupyter HTTP API to detect idle notebooks and scales them down" "Go (embedded in notebook-controller)"
            odhController = container "odh-notebook-controller" "RHOAI extensions: kube-rbac-proxy sidecar injection, HTTPRoute/ReferenceGrant management, NetworkPolicy creation, DSPA/MLflow/Feast integrations, mutating/validating webhooks" "Go Operator (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Enriches notebook pods: injects kube-rbac-proxy, resolves ImageStreams, mounts CA bundles and pipeline config, injects env vars" "Go Webhook Handler (8443/TCP)"
            validatingWebhook = container "Validating Webhook" "Prevents removal of MLflow annotation on running notebooks" "Go Webhook Handler (8443/TCP)"
            commonLib = container "Common Library" "Shared reconciliation helpers for Deployment, Service, StatefulSet, VirtualService resources" "Go Library"
        }

        notebookPod = softwareSystem "Notebook Pod" "Jupyter notebook instance running as StatefulSet with optional kube-rbac-proxy sidecar" {
            jupyterContainer = container "Jupyter Container" "User notebook server" "Jupyter (8888/TCP)"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication sidecar: TokenReview + SubjectAccessReview" "Go (8443/TCP HTTPS)"
        }

        gateway = softwareSystem "Gateway API (data-science-gateway)" "Ingress gateway for notebook access via HTTPRoutes" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes and OpenShift API" "External"
        openShiftImageStreams = softwareSystem "OpenShift ImageStreams" "Container image resolution and runtime image metadata" "External"
        openShiftServiceCA = softwareSystem "OpenShift Service CA" "TLS certificate provisioning for webhooks and services" "External"
        dspa = softwareSystem "Data Science Pipelines Application" "Pipeline configuration and S3 credential management" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking integration" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store integration via ConfigMap mounting" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that defines additional webhooks for notebooks" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing notebooks and data science projects" "Internal RHOAI"

        # User interactions
        user -> rhoaiDashboard "Creates notebooks via web UI"
        user -> k8sAPI "Creates Notebook CRs via kubectl" "HTTPS/6443"
        user -> gateway "Accesses running notebooks" "HTTPS/443"

        # Gateway to notebook pod
        gateway -> kubeRBACProxy "Routes authenticated requests" "HTTPS/8443"
        gateway -> jupyterContainer "Routes unauthenticated requests" "HTTP/8888"

        # kube-rbac-proxy auth
        kubeRBACProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        kubeRBACProxy -> jupyterContainer "Forwards authenticated requests" "HTTP/8888 (localhost)"

        # K8s API webhook callbacks
        k8sAPI -> mutatingWebhook "Calls on Notebook create/update" "HTTPS/443→8443"
        k8sAPI -> validatingWebhook "Calls on Notebook update" "HTTPS/443→8443"

        # notebook-controller operations
        notebookController -> k8sAPI "Creates StatefulSet, Service, VirtualService; manages pod lifecycle" "HTTPS/6443"
        cullingController -> jupyterContainer "Polls /api/kernels, /api/terminals for idle detection" "HTTP/8888"
        cullingController -> k8sAPI "Patches Notebook annotations; scales StatefulSet to 0" "HTTPS/6443"

        # odh-notebook-controller operations
        odhController -> k8sAPI "Creates HTTPRoute, ReferenceGrant, NetworkPolicy, kube-rbac-proxy resources" "HTTPS/6443"
        odhController -> openShiftImageStreams "Resolves notebook container images" "HTTPS/6443"
        odhController -> dspa "Reads DSPA CR for S3 config, syncs pipeline secrets" "HTTPS/6443"
        odhController -> mlflow "Creates RoleBinding to mlflow-integration ClusterRole" "HTTPS/6443"
        odhController -> feast "Mounts feast-config ConfigMap" "N/A"

        # Shared library usage
        notebookController -> commonLib "Uses reconciliation helpers"
        odhController -> commonLib "Uses reconciliation helpers"

        # Service CA
        openShiftServiceCA -> odhController "Provisions webhook TLS certificates"
        openShiftServiceCA -> kubeRBACProxy "Provisions per-notebook TLS certificates"

        # Platform webhook interactions
        rhodsOperator -> k8sAPI "Registers connection-notebook and hardwareprofile-injector webhooks"
    }

    views {
        systemContext kubeflow "SystemContext" {
            include *
            autoLayout
            description "Kubeflow Notebook Controllers in the RHOAI ecosystem"
        }

        container kubeflow "Containers" {
            include *
            autoLayout
            description "Internal structure of the dual-controller architecture"
        }

        container notebookPod "NotebookPod" {
            include *
            autoLayout
            description "Notebook pod with optional kube-rbac-proxy sidecar"
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

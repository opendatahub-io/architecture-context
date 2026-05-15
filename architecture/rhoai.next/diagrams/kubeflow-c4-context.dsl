workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workloads via Dashboard or kubectl"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform, manages Gateway and controller settings"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Dual-controller system managing Jupyter notebook lifecycle, Gateway API ingress, and authentication proxy injection on OpenShift" {
            kfController = container "kf-notebook-controller" "Upstream Kubeflow notebook lifecycle: StatefulSet, Service, VirtualService creation and idle culling" "Go Operator (controller-runtime)" "Component"
            cullingController = container "Culling Controller" "Monitors Jupyter API for kernel/terminal activity, scales idle notebooks to zero" "Go (embedded in kf-controller)" "Component"
            odhController = container "odh-notebook-controller" "RHOAI extensions: Gateway API routing, kube-rbac-proxy injection, DSPA/MLflow/Feast integration, NetworkPolicy management" "Go Operator (controller-runtime)" "Component"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook CR create/update to inject kube-rbac-proxy sidecar, CA bundles, Elyra secrets, Feast config, MLflow env vars" "Go Webhook (8443/TCP HTTPS)" "Component"
            validatingWebhook = container "Validating Webhook" "Prevents removal of MLflow annotation on running notebooks" "Go Webhook (8443/TCP HTTPS)" "Component"
        }

        notebookPod = softwareSystem "Notebook Pod" "Jupyter notebook container with optional kube-rbac-proxy sidecar, running as StatefulSet" "Runtime"

        # Platform dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all CR, resource, and RBAC management" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API ingress entry point for notebook HTTPRoutes (openshift-ingress namespace)" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines Application" "Pipeline orchestration with S3 storage config, credentials for Elyra integration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking, provides ClusterRole for notebook ServiceAccount access" "Internal RHOAI"
        feast = softwareSystem "Feast Feature Store" "Feature store configuration mounted into notebook pods via ConfigMap" "Internal RHOAI"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Resolves notebook container images from ImageStream tags" "External"
        istio = softwareSystem "Istio" "Optional service mesh for VirtualService-based notebook routing (legacy)" "External"
        certManager = softwareSystem "OpenShift Service CA" "Provisions and auto-rotates TLS certificates for webhook and kube-rbac-proxy" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing notebooks" "Internal RHOAI"

        # Relationships - Users
        dataScientist -> kubeflow "Creates Notebook CRs via kubectl or Dashboard"
        dataScientist -> notebookPod "Accesses Jupyter UI via browser through Gateway"
        platformAdmin -> kubeflow "Configures controller settings, Gateway, and integrations"

        # Relationships - Internal
        kfController -> k8sAPI "Creates StatefulSet, Service; manages lifecycle" "HTTPS/6443"
        kfController -> notebookPod "Queries /api/kernels, /api/terminals for idle detection" "HTTP/8888"
        cullingController -> notebookPod "Polls Jupyter API for activity timestamps" "HTTP/8888"
        cullingController -> k8sAPI "Patches stop annotation on idle notebooks" "HTTPS/6443"
        odhController -> k8sAPI "Creates HTTPRoute, NetworkPolicy, ReferenceGrant, RoleBindings" "HTTPS/6443"
        odhController -> gateway "References as HTTPRoute parent" "Gateway API"
        odhController -> dspa "Reads pipeline config and S3 credentials for Elyra" "HTTPS/443"
        odhController -> mlflow "References ClusterRole for RoleBinding creation" "K8s API"
        odhController -> feast "Mounts feature store ConfigMap into pods" "K8s API"
        odhController -> imageRegistry "Resolves container images from ImageStreams" "HTTPS/443"
        mutatingWebhook -> k8sAPI "Reads ImageStreams, Secrets, ConfigMaps during mutation" "HTTPS/6443"
        kfController -> istio "Creates VirtualService when USE_ISTIO=true (optional)" "K8s API"

        # Relationships - External actors
        k8sAPI -> mutatingWebhook "Sends AdmissionReview for Notebook create/update" "HTTPS/8443"
        k8sAPI -> validatingWebhook "Sends AdmissionReview for Notebook update" "HTTPS/8443"
        odhDashboard -> kubeflow "Creates Notebook CRs on behalf of users" "HTTPS/6443 (via K8s API)"
        gateway -> notebookPod "Routes traffic to kube-rbac-proxy sidecar" "HTTPS/8443"
        certManager -> kubeflow "Provisions TLS serving certificates" "Annotation-based"
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
            element "Component" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

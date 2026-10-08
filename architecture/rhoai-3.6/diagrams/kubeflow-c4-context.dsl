workspace {
    model {
        user = person "Data Scientist / Developer" "Creates and interacts with Jupyter notebook workbenches"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle of Jupyter notebook workbench pods on OpenShift AI" {
            notebookController = container "notebook-controller" "Reconciles Notebook CRs into StatefulSets and Services; idle culling" "Go Controller (controller-runtime)"
            odhNotebookController = container "odh-notebook-controller" "Auth sidecar injection, Gateway API routing, NetworkPolicy, OAuth, DSPA secrets, MLflow" "Go Controller (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Injects kube-rbac-proxy sidecar, resolves ImageStreams" "Admission Webhook"
            validatingWebhook = container "Validating Webhook" "Validates PodSpec security, MLflow annotation rules" "Admission Webhook"
            cullingReconciler = container "CullingReconciler" "Monitors notebook pod activity and stops idle notebooks" "Go Controller"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource CRUD" "External"
        gatewayAPI = softwareSystem "Gateway API (Platform Gateway)" "Kubernetes-native ingress routing" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages data science pipeline infrastructure" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OpenShift authentication system" "External"
        imageStreams = softwareSystem "OpenShift Image Streams" "Container image tag management" "External"
        osRoutes = softwareSystem "OpenShift Routes" "OpenShift route management" "External"
        osAPIServerConfig = softwareSystem "OpenShift APIServer Config" "Cluster TLS security profile" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing RHOAI resources" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / service-ca" "Certificate provisioning and rotation" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication proxy sidecar for notebook pods" "Internal RHOAI"

        # User interactions
        user -> kubeflow "Creates Notebook CRs via kubectl / Dashboard"
        user -> dashboard "Manages notebooks via web UI"
        dashboard -> kubeflow "Creates/manages Notebook CRs"

        # Controller → Kubernetes API
        notebookController -> k8sAPI "CRUD: StatefulSets, Services, Pods" "HTTPS/6443"
        odhNotebookController -> k8sAPI "CRUD: HTTPRoutes, NetworkPolicies, Secrets, RoleBindings" "HTTPS/6443"

        # Controller → OpenShift services
        odhNotebookController -> gatewayAPI "Creates per-notebook HTTPRoutes" "HTTPS/6443"
        odhNotebookController -> dspo "Reads DSPA CRs, syncs pipeline secrets" "HTTPS/6443"
        odhNotebookController -> openshiftOAuth "Manages OAuthClients (legacy)" "HTTPS/6443"
        mutatingWebhook -> imageStreams "Resolves ImageStream tags" "HTTPS/6443"
        odhNotebookController -> osRoutes "Reads dashboard/DSPA routes" "HTTPS/6443"
        notebookController -> osAPIServerConfig "Reads TLS security profile" "HTTPS/6443"
        odhNotebookController -> osAPIServerConfig "Reads and watches TLS profile" "HTTPS/6443"

        # Monitoring
        prometheus -> kubeflow "Scrapes controller metrics" "HTTPS/8443,8080"

        # Certificate management
        certManager -> kubeflow "Provisions webhook and proxy TLS certs"

        # Sidecar injection
        mutatingWebhook -> kubeRBACProxy "Injects as sidecar into notebook pods"
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

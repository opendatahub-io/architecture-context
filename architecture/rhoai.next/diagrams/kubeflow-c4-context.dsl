workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter Notebook workbenches on OpenShift"
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI platform"

        kubeflowNotebooks = softwareSystem "Kubeflow Notebook Controllers" "Dual-controller architecture managing Jupyter Notebook workbench lifecycle on RHOAI" {
            notebookController = container "notebook-controller" "Core notebook lifecycle: StatefulSet, Service, VirtualService management, idle culling" "Go Operator (controller-runtime 0.21.0)" "controller"
            odhNotebookController = container "odh-notebook-controller" "RHOAI extensions: HTTPRoute routing, kube-rbac-proxy auth, NetworkPolicy, webhook mutations, MLflow/Elyra/Feast integration" "Go Operator (controller-runtime 0.21.0)" "controller"
            mutatingWebhook = container "Mutating Webhook" "Image resolution, CA bundle injection, proxy settings, kube-rbac-proxy config, MLflow env vars, reconciliation lock" "Go HTTPS Server (8443/TCP)" "webhook"
            validatingWebhook = container "Validating Webhook" "Validates MLflow annotation safety on running notebooks" "Go HTTPS Server (8443/TCP)" "webhook"
            kubeRbacProxy = container "kube-rbac-proxy" "Sidecar authenticating notebook access via TokenReview + SubjectAccessReview" "kube-rbac-proxy (8443/TCP)" "sidecar"
            notebookPod = container "Notebook Pod" "Jupyter notebook workbench running as StatefulSet" "Jupyter (8888/TCP)" "workload"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes API" "API server for all controller operations" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "Route, ImageStream, Proxy, OAuth, Service CA APIs" "External"
        gatewayAPI = softwareSystem "Gateway API / data-science-gateway" "Central ingress gateway with Envoy data plane" "External"

        # Internal RHOAI Dependencies
        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys both controllers via component manifests" "Internal RHOAI"
        mlflowOperator = softwareSystem "MLflow Operator" "Provides MLflow integration ClusterRole for notebook ServiceAccounts" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Pipeline endpoints for Elyra runtime configuration" "Internal RHOAI"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Resolves notebook images from ImageStream tags to digests" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift Service CA" "Auto-generates TLS certs for kube-rbac-proxy and webhook services" "External"
        prometheus = softwareSystem "Prometheus" "Collects controller metrics" "External"

        # Relationships - Users
        dataScientist -> kubeflowNotebooks "Creates Notebook CR via kubectl/Dashboard"
        dataScientist -> notebookPod "Accesses notebook UI via browser (HTTPS/443 via Gateway)"
        platformAdmin -> rhoaiOperator "Deploys and configures"

        # Relationships - Internal
        odhNotebookController -> mutatingWebhook "Serves admission requests"
        odhNotebookController -> validatingWebhook "Serves admission requests"
        notebookController -> notebookPod "Creates StatefulSet, polls for idle detection" "HTTP/8888"
        odhNotebookController -> kubeRbacProxy "Injects sidecar into notebook pods"
        kubeRbacProxy -> notebookPod "Forwards authenticated requests" "HTTP/8888 localhost"

        # Relationships - External Dependencies
        notebookController -> kubernetes "StatefulSet, Service, Event CRUD" "HTTPS/443"
        odhNotebookController -> kubernetes "HTTPRoute, NetworkPolicy, RBAC, ConfigMap, Secret CRUD" "HTTPS/443"
        kubeRbacProxy -> kubernetes "TokenReview, SubjectAccessReview" "HTTPS/443"
        odhNotebookController -> gatewayAPI "Creates HTTPRoutes, discovers listener hostname" "HTTPS/443"
        odhNotebookController -> openshiftPlatform "ImageStream resolution, Proxy config, OAuth cleanup" "HTTPS/443"

        # Relationships - Internal RHOAI Dependencies
        rhoaiOperator -> kubeflowNotebooks "Deploys via Kustomize manifests"
        odhNotebookController -> mlflowOperator "Checks ClusterRole existence for RoleBinding" "N/A"
        odhNotebookController -> dsPipelines "Discovers DSPA endpoints for Elyra config" "HTTPS/443"
        odhNotebookController -> imageRegistry "Resolves ImageStream tags to digests" "HTTPS/443"
        serviceCA -> kubeRbacProxy "Provisions TLS certificates (annotation-based)"
        serviceCA -> mutatingWebhook "Provisions webhook TLS certificate"
        prometheus -> notebookController "Scrapes metrics" "HTTP/8080"
        prometheus -> odhNotebookController "Scrapes metrics" "HTTP/8080"
    }

    views {
        systemContext kubeflowNotebooks "SystemContext" {
            include *
            autoLayout
        }

        container kubeflowNotebooks "Containers" {
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
            element "controller" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "webhook" {
                background #e8524a
                color #ffffff
                shape Hexagon
            }
            element "sidecar" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "workload" {
                background #50e3c2
                color #ffffff
                shape RoundedBox
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

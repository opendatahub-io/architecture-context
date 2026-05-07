workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches for ML experimentation"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and notebook images"

        // Primary System
        kubeflow = softwareSystem "Kubeflow Notebook Controller" "Manages the lifecycle of Jupyter Notebook workbenches on OpenShift, including pod creation, idle culling, authentication, and Gateway API routing" {
            notebookController = container "notebook-controller" "Core notebook lifecycle: StatefulSet/Service creation, pod status tracking, idle culling via Jupyter API queries" "Go Controller (controller-runtime)"
            odhNotebookController = container "odh-notebook-controller" "RHOAI extensions: HTTPRoute routing, kube-rbac-proxy auth injection, webhooks, CA bundle management, DSPA/MLflow/Feast integrations" "Go Controller (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook CREATE/UPDATE to inject sidecars, resolve ImageStreams, mount configs" "Go Webhook Server (8443/TCP HTTPS)"
            validatingWebhook = container "Validating Webhook" "Validates Notebook UPDATE operations, blocks restart-requiring changes" "Go Webhook Server (8443/TCP HTTPS)"
            reconcileHelper = container "reconcilehelper" "Shared utility library for reconciling Kubernetes resources" "Go Library"

            // Internal relationships
            odhNotebookController -> mutatingWebhook "Hosts" "HTTPS/8443"
            odhNotebookController -> validatingWebhook "Hosts" "HTTPS/8443"
            notebookController -> reconcileHelper "Uses"
            odhNotebookController -> reconcileHelper "Uses"
        }

        // Internal ODH Components
        dataScienceGateway = softwareSystem "data-science-gateway" "Central Gateway API ingress for all RHOAI notebook workbenches" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and notebook workbenches" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines (DSPA)" "Elyra pipeline execution and S3 artifact storage" "Internal ODH"
        modelRegistry = softwareSystem "MLflow Operator" "MLflow tracking server for experiment logging" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store for ML feature serving" "Internal ODH"
        rhodsOperator = softwareSystem "RHOAI Operator" "Deploys and manages Kubeflow notebook controllers via kustomize overlays" "Internal ODH"

        // Platform Services
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource CRUD operations" "Platform"
        servingCertController = softwareSystem "OpenShift serving-cert-controller" "Auto-generates and rotates TLS certificates for services" "Platform"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Stores and serves container images referenced by ImageStreams" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Platform"

        // External Services
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Per-notebook authentication sidecar enforcing RBAC via TokenReview/SAR" "Sidecar"

        // Relationships - Users
        dataScientist -> odhDashboard "Creates notebooks via" "HTTPS"
        dataScientist -> dataScienceGateway "Accesses notebooks via" "HTTPS/443"
        platformAdmin -> rhodsOperator "Configures platform via" "kubectl"

        // Relationships - Primary flows
        dataScienceGateway -> kubeRbacProxy "Routes requests to" "HTTPS/8443 (TLS)"
        kubeRbacProxy -> k8sAPI "Validates auth via" "HTTPS/6443 (TokenReview + SAR)"

        odhDashboard -> k8sAPI "Creates Notebook CRs via" "HTTPS/6443"
        k8sAPI -> mutatingWebhook "Sends admission requests" "HTTPS/8443"
        k8sAPI -> validatingWebhook "Sends admission requests" "HTTPS/8443"

        notebookController -> k8sAPI "Creates StatefulSet, Service" "HTTPS/6443"
        odhNotebookController -> k8sAPI "Creates HTTPRoute, NetworkPolicy, RBAC" "HTTPS/6443"
        odhNotebookController -> dataScienceGateway "Reads Gateway hostname" "HTTPS/6443 (via K8s API)"
        odhNotebookController -> imageRegistry "Resolves ImageStreams" "HTTPS/5000"

        // Relationships - Integrations
        odhNotebookController -> dsPipelines "Extracts Elyra runtime config" "HTTPS"
        odhNotebookController -> modelRegistry "Derives tracking URI, creates RoleBinding" "HTTPS/6443 (via K8s API)"
        odhNotebookController -> feast "Mounts config ConfigMap" "K8s API"
        rhodsOperator -> kubeflow "Deploys via kustomize" "kubectl apply"
        servingCertController -> kubeRbacProxy "Issues TLS certificates" "Annotation-triggered"
        servingCertController -> odhNotebookController "Issues webhook TLS certificate" "Annotation-triggered"
        prometheus -> notebookController "Scrapes metrics" "HTTP/8080"
        prometheus -> odhNotebookController "Scrapes metrics" "HTTP/8080"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #e87d7d
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

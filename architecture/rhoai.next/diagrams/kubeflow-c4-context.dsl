workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter Notebook workloads on OpenShift"
        admin = person "Platform Admin" "Configures and operates the RHOAI platform"

        kubeflow = softwareSystem "Kubeflow Notebook Controller" "Manages the lifecycle of Jupyter Notebook workloads including pod creation, idle culling, authentication, and network routing" {
            notebookController = container "notebook-controller" "Upstream Kubeflow controller: reconciles Notebook CRs into StatefulSets and Services, implements idle notebook culling via Jupyter API polling" "Go Controller (controller-runtime)" "upstream"
            odhNotebookController = container "odh-notebook-controller" "ODH/RHOAI controller: injects kube-rbac-proxy sidecars, creates HTTPRoutes (Gateway API), manages NetworkPolicies, handles CA cert bundles, integrates with DSPA/Elyra/MLflow/Feast" "Go Controller (controller-runtime) + Webhooks" "odh"
            mutatingWebhook = container "Mutating Webhook" "Injects kube-rbac-proxy sidecar, CA certs, proxy env vars, pipeline config, MLflow env, Feast config; blocks pod-template changes on running notebooks" "Admission Webhook" "webhook"
            validatingWebhook = container "Validating Webhook" "Prevents MLflow annotation removal on running notebooks" "Admission Webhook" "webhook"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for CRUD operations on all resources" "External"
        dataScienceGateway = softwareSystem "data-science-gateway" "Gateway API gateway in openshift-ingress namespace for external notebook access routing" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar injected per notebook: TokenReview + SubjectAccessReview" "Internal RHOAI"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto-generates and rotates TLS certificates for annotated Services" "External"
        openshiftImageRegistry = softwareSystem "OpenShift Image Registry" "Stores and serves container images; resolves ImageStream tags" "External"
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys and configures notebook controllers" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Data Science Pipelines Application for Elyra runtime integration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model management" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store for ML feature serving" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and workbenches" "Internal RHOAI"

        # User interactions
        dataScientist -> kubeflow "Creates Notebook CRs via kubectl / Dashboard"
        dataScientist -> dataScienceGateway "Accesses Jupyter Notebooks via browser" "HTTPS/443"
        admin -> rhodsOperator "Configures platform"

        # Internal container interactions
        notebookController -> k8sAPI "Creates StatefulSets, Services; scales for culling" "HTTPS/443"
        odhNotebookController -> k8sAPI "Creates HTTPRoutes, ReferenceGrants, NetworkPolicies, ServiceAccounts, Services, ConfigMaps, RoleBindings" "HTTPS/443"
        odhNotebookController -> openshiftImageRegistry "Resolves ImageStream tags to image digests" "HTTPS/5000"

        # Gateway flow
        dataScienceGateway -> kubeRBACProxy "Routes notebook traffic via HTTPRoute" "HTTPS/8443"
        kubeRBACProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/443"

        # Webhook interactions
        k8sAPI -> mutatingWebhook "Notebook admission (mutate)" "HTTPS/8443"
        k8sAPI -> validatingWebhook "Notebook admission (validate)" "HTTPS/8443"

        # Platform dependencies
        rhodsOperator -> kubeflow "Deploys and configures both controllers"
        odhNotebookController -> dataScienceGateway "Reads Gateway CR for hostname extraction" "CRD Watch"
        odhNotebookController -> dspa "Extracts pipeline config for Elyra runtime" "CRD Watch"
        openshiftServiceCA -> kubeRBACProxy "Provisions TLS certificates" "Annotation-based"

        # Integration points
        odhDashboard -> kubeflow "Creates/manages notebooks via UI"
        kubeflow -> mlflow "Injects MLflow tracking env vars, creates RoleBindings" "CRD/RBAC"
        kubeflow -> feast "Mounts Feast config ConfigMap into notebooks" "ConfigMap"

        # Idle culling
        notebookController -> kubeRBACProxy "Polls Jupyter API for idle culling" "HTTP/80"
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
            element "upstream" {
                background #4a90e2
                color #ffffff
            }
            element "odh" {
                background #4a90e2
                color #ffffff
            }
            element "webhook" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}

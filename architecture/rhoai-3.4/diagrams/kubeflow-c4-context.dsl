workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter Notebook workbenches via RHOAI Dashboard or kubectl"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform, manages namespaces and quotas"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages the lifecycle of Jupyter Notebook workbenches on OpenShift, including pod scheduling, network exposure, authentication, and platform integrations" {
            notebookController = container "notebook-controller" "Manages StatefulSets, Services, and VirtualServices for Notebook CRs; implements idle notebook culling via Jupyter kernel/terminal API monitoring" "Go Controller (controller-runtime)"
            cullingReconciler = container "Culling Reconciler" "Monitors Jupyter kernel and terminal activity; stops idle notebooks after configurable inactivity period" "Go (embedded in notebook-controller)"
            odhNotebookController = container "odh-notebook-controller" "Extends notebook lifecycle with Gateway API networking, kube-rbac-proxy sidecar injection, certificate management, DSPA/MLflow/Feast integration" "Go Controller (controller-runtime)"
            mutatingWebhook = container "Mutating Admission Webhook" "Injects auth sidecars, CA bundles, pipeline secrets, MLflow env, proxy config, and reconciliation lock on Notebook CREATE/UPDATE" "Go Webhook (8443/TCP HTTPS)"
            validatingWebhook = container "Validating Admission Webhook" "Validates Notebook UPDATE to prevent MLflow annotation removal on running notebooks" "Go Webhook (8443/TCP HTTPS)"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for all resource CRUD operations" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API Gateway CR for notebook ingress routing via HTTPRoutes" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-ca-operator" "Auto-generates and rotates TLS certificates for services" "External"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Container image registry with tag resolution and runtime image discovery" "External"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Data Science Pipelines Application for ML workflow orchestration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "MLflow tracking server integration for experiment tracking" "Internal RHOAI"
        feast = softwareSystem "Feast Feature Store" "Feature store for ML feature serving and management" "Internal RHOAI"
        rhoaiOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys and manages notebook controllers" "Internal RHOAI"
        jupyterServer = softwareSystem "Jupyter Notebook Server" "User notebook workbench running as StatefulSet pod" "Managed Workload"

        # User interactions
        dataScientist -> kubeflow "Creates Notebook CR via kubectl/Dashboard" "HTTPS/443"
        dataScientist -> jupyterServer "Accesses notebook UI via browser" "HTTPS/443 (via Gateway)"
        platformAdmin -> rhoaiOperator "Configures RHOAI platform" "HTTPS/443"

        # Controller → K8s API
        notebookController -> k8sApi "CRUD: StatefulSets, Services, Pods, Events, Notebooks" "HTTPS/443, SA token"
        odhNotebookController -> k8sApi "CRUD: HTTPRoutes, ReferenceGrants, Services, NetworkPolicies, Secrets, ConfigMaps, RBAC" "HTTPS/443, SA token"

        # Controller → managed workloads
        notebookController -> jupyterServer "Creates StatefulSet and Service for notebook pod"
        cullingReconciler -> jupyterServer "Queries /api/kernels and /api/terminals for idle detection" "HTTP/8888"

        # ODH controller integrations
        odhNotebookController -> gateway "Creates HTTPRoutes referencing Gateway as parent" "Gateway API CRD"
        odhNotebookController -> dspa "Reads DSPA CR for pipeline endpoint and S3 config" "HTTPS/443, SA token"
        odhNotebookController -> mlflow "References mlflow-operator-mlflow-integration ClusterRole" "ClusterRole binding"
        odhNotebookController -> feast "Mounts feast-config ConfigMap when label present" "ConfigMap"
        odhNotebookController -> imageStreams "Resolves notebook images and discovers runtime images" "HTTPS/443, SA token"

        # Certificate provisioning
        serviceCa -> kubeflow "Generates TLS certs for webhook and kube-rbac-proxy" "Annotation-driven"

        # Platform operator deploys controllers
        rhoaiOperator -> kubeflow "Deploys via kustomize from components/base/" "Kustomize"

        # Internal container relationships
        notebookController -> cullingReconciler "Runs as embedded reconciler"
        odhNotebookController -> mutatingWebhook "Serves webhook endpoints"
        odhNotebookController -> validatingWebhook "Serves webhook endpoints"
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
            element "Managed Workload" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
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

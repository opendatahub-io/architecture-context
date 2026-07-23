workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter Notebook workbenches"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator configuration"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Manages lifecycle of workbenches (Jupyter Notebooks) infrastructure for RHOAI" {
            controller = container "Workbenches Controller" "Reconciles Workbenches CR, renders kustomize manifests via SSA, manages deployment health and distribution handshake" "Go / controller-runtime"
            kustomizeRenderer = container "Kustomize Renderer" "Renders upstream kustomize manifests with platform-specific overlays at reconcile time" "kustomize/api"
            hwProfileWebhook = container "HardwareProfile Webhook" "Mutating webhook injecting resource requirements, node selectors, and tolerations from HardwareProfile CRs into Notebooks" "Go / admission webhook"
            connectionWebhook = container "Connection Notebook Webhook" "Mutating webhook injecting connection secrets as envFrom references with SubjectAccessReview authorization" "Go / admission webhook"
            tlsManager = container "TLS Config Manager" "Bootstraps and watches cluster TLS security profile, triggers graceful restart on changes" "Go / SecurityProfileWatcher"
            metricsServer = container "Metrics Server" "Exposes controller-runtime Prometheus metrics with RBAC-authenticated access" "Go / controller-runtime"
        }

        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform orchestrator that creates Workbenches CR and manages version handshake" "Internal RHOAI"
        kfNotebookController = softwareSystem "kf-notebook-controller" "Kubeflow Notebook controller managing Notebook CR lifecycle" "Deployed by Operator"
        odhNotebookController = softwareSystem "odh-notebook-controller" "ODH-extended Notebook controller with kube-rbac-proxy sidecars and Gateway API HTTPRoutes" "Deployed by Operator"
        notebookImageStreams = softwareSystem "Notebook ImageStreams" "Workbench and runtime image definitions (11 notebooks + 14 runtimes for RHOAI)" "Deployed by Operator"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API server for CR management, SSA patches, and webhook dispatch" "External"
        openshiftApiServer = softwareSystem "OpenShift APIServer" "OpenShift cluster configuration including TLS security profiles" "External"
        certManager = softwareSystem "cert-manager" "Manages TLS certificates with self-signed issuer for webhook serving" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        platformAdmin -> platformOperator "Configures platform via DSCi/DSC CRs"
        platformOperator -> workbenchesOperator "Creates Workbenches CR, writes odh-workbenches-config ConfigMap"
        dataScientist -> k8sApi "Creates Notebook CRs via kubectl/dashboard"
        k8sApi -> hwProfileWebhook "Dispatches AdmissionReview for Notebook create/update" "HTTPS/9443"
        k8sApi -> connectionWebhook "Dispatches AdmissionReview for Notebook create/update" "HTTPS/9443"

        controller -> kustomizeRenderer "Renders manifests with platform params"
        controller -> k8sApi "SSA patches, CR reconciliation, deployment status" "HTTPS/443"
        controller -> openshiftApiServer "Reads TLS security profile" "HTTPS/443"
        tlsManager -> openshiftApiServer "Watches for TLS profile changes" "HTTPS/443"

        hwProfileWebhook -> k8sApi "Reads HardwareProfile CRs" "HTTPS/443"
        connectionWebhook -> k8sApi "Validates secrets, creates SubjectAccessReviews" "HTTPS/443"

        workbenchesOperator -> kfNotebookController "Deploys and manages via SSA" "Server-Side Apply"
        workbenchesOperator -> odhNotebookController "Deploys and manages via SSA" "Server-Side Apply"
        workbenchesOperator -> notebookImageStreams "Deploys image definitions via SSA" "Server-Side Apply"

        certManager -> workbenchesOperator "Provisions webhook-server-cert TLS certificate" "Self-signed issuer"
        prometheus -> metricsServer "Scrapes /metrics endpoint" "HTTPS/8443"
    }

    views {
        systemContext workbenchesOperator "SystemContext" {
            include *
            autoLayout
        }

        container workbenchesOperator "Containers" {
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
            element "Deployed by Operator" {
                background #27ae60
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

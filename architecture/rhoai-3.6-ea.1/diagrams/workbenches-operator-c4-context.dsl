workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration via DSC"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Manages lifecycle of Kubeflow Notebook workbenches, connection-secret injection, and hardware-profile mutation" {
            reconciler = container "WorkbenchesReconciler" "Reconciles cluster-scoped Workbenches CR to deploy notebook-controller stack via kustomize" "Go controller-runtime"
            connectionWebhook = container "NotebookWebhook" "Validates connection secrets exist and user has read permission via SAR, then injects volume mounts" "Mutating Admission Webhook"
            hardwareProfileInjector = container "HardwareProfile Injector" "Resolves HardwareProfile CRs and mutates notebook container resource limits" "Mutating Admission Webhook"
            tlsManager = container "TLS Config Manager" "Bootstraps TLS from OpenShift APIServer profile, watches for profile changes" "Go SecurityProfileWatcher"
        }

        platformOrchestrator = softwareSystem "Platform Orchestrator (DSC)" "Projects platform config into Workbenches CR" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebook Controller" "Manages notebook pod lifecycle" "Managed Operand"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "Infrastructure"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Provisions TLS serving certificates for services" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Alternative TLS certificate provider" "Infrastructure"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile" "Infrastructure"

        # Relationships
        platformAdmin -> platformOrchestrator "Configures RHOAI platform"
        platformOrchestrator -> workbenchesOperator "Creates/updates Workbenches CR" "Kubernetes API"
        dataScientist -> kubernetesAPI "Creates Notebook CR via kubectl/Dashboard"

        reconciler -> kubernetesAPI "Applies kustomize manifests (Deployments, Services, RBAC)" "HTTPS/6443"
        reconciler -> kubeflowNotebooks "Deploys and manages" "Kustomize manifests"
        connectionWebhook -> kubernetesAPI "Validates secrets, creates SubjectAccessReview" "HTTPS/6443"
        hardwareProfileInjector -> kubernetesAPI "Reads HardwareProfile CRs" "HTTPS/6443"
        tlsManager -> openshiftAPIServer "Watches TLS security profile" "Kubernetes API"

        kubernetesAPI -> connectionWebhook "Routes admission requests" "HTTPS/443→9443"
        kubernetesAPI -> hardwareProfileInjector "Routes admission requests" "HTTPS/443→9443"

        openshiftServiceCA -> workbenchesOperator "Provisions webhook TLS certificates"
        certManager -> workbenchesOperator "Fallback certificate provisioning" "Certificate CR"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Managed Operand" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

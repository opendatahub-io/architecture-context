workspace {
    model {
        platformAdmin = person "Platform Administrator" "Configures the RHOAI platform and manages component lifecycle"
        dataScientist = person "Data Scientist" "Creates and uses Notebook workbenches for ML development"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Deploys and manages the notebook workbench infrastructure (Kubeflow notebook controller, ODH notebook controller, and notebook manifests) on OpenShift" {
            controllerManager = container "Controller Manager" "Reconciles Workbenches CR, renders Kustomize manifests, applies via SSA" "Go / controller-runtime"
            hardwareProfileWebhook = container "Hardware Profile Webhook" "Mutating webhook that injects resource constraints, tolerations, nodeSelector, and Kueue labels into Notebook CRs" "Go / Admission Webhook"
            connectionWebhook = container "Connection Notebook Webhook" "Mutating webhook that injects connection secrets as envFrom references into Notebook CRs after SAR validation" "Go / Admission Webhook"
            manifests = container "Embedded Manifests" "Kustomize bundles for kf-notebook-controller, odh-notebook-controller, notebooks, workspaces-controller" "Filesystem (/opt/manifests)"
        }

        platformOrchestrator = softwareSystem "Platform Orchestrator" "opendatahub-operator / rhods-operator — creates and updates Workbenches CR" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook controller managing Notebook CRs (kubeflow.org)" "Internal RHOAI"
        hardwareProfiles = softwareSystem "Hardware Profiles" "HardwareProfile CRs defining resource constraints and scheduling" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD CRUD, SSA, admission webhooks, leader election" "External"
        certManager = softwareSystem "cert-manager" "Certificate management for webhook TLS on non-OpenShift clusters" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-CA" "Provisions and auto-rotates webhook TLS certificates" "External"
        openshiftImageStreams = softwareSystem "OpenShift Image Streams" "Manages notebook container images as ImageStream resources" "External"

        # Relationships
        platformAdmin -> platformOrchestrator "Configures platform components"
        dataScientist -> kubeflowNotebooks "Creates Notebook CRs via kubectl/dashboard"

        platformOrchestrator -> workbenchesOperator "Creates/updates Workbenches CR (gatewayDomain, mlflowEnabled, platform)"
        controllerManager -> manifests "Reads and renders Kustomize bundles"
        controllerManager -> kubernetesAPI "SSA apply manifests, CRD CRUD, leader election" "HTTPS/6443"
        controllerManager -> kubeflowNotebooks "Deploys notebook controllers"
        controllerManager -> openshiftImageStreams "Manages ImageStream resources" "HTTPS/6443"
        controllerManager -> prometheusOperator "Creates ServiceMonitor" "HTTPS/6443"

        kubernetesAPI -> hardwareProfileWebhook "Admission request on Notebook CREATE/UPDATE" "HTTPS/443→9443"
        hardwareProfileWebhook -> hardwareProfiles "Reads HardwareProfile CR for resource constraints" "HTTPS/6443"
        hardwareProfileWebhook -> kubernetesAPI "Returns admission response (JSON patch)" "HTTPS/443"

        kubernetesAPI -> connectionWebhook "Admission request on Notebook CREATE/UPDATE" "HTTPS/443→9443"
        connectionWebhook -> kubernetesAPI "SubjectAccessReview + read Secrets" "HTTPS/6443"

        openshiftServiceCA -> workbenchesOperator "Provisions webhook TLS cert (auto-rotate)"
        certManager -> workbenchesOperator "Issues Certificate via ClusterIssuer (fallback)"
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

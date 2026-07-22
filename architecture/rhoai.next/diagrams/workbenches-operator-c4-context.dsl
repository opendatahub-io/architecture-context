workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Deploys and configures the RHOAI platform"
        datascientist = person "Data Scientist" "Creates and uses Notebooks (Workbenches)"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Module operator managing Workbenches component lifecycle — deploys kf-notebook-controller, odh-notebook-controller, and notebook ImageStreams" {
            controller = container "Workbenches Controller" "Watches Workbenches CR and platform ConfigMap; renders kustomize manifests; applies via SSA; tracks deployment readiness" "Go (controller-runtime)"
            hwWebhook = container "Hardware Profile Webhook" "Mutating webhook injecting HardwareProfile resource requirements, nodeSelector, tolerations into Notebooks" "Go (admission webhook)"
            connWebhook = container "Notebook Connection Webhook" "Mutating webhook validating and injecting connection secret references into Notebooks via SubjectAccessReview" "Go (admission webhook)"
            tlsBootstrap = container "TLS Bootstrap" "Reads OpenShift cluster TLS security profile; configures webhook and metrics server TLS; watches for profile changes" "Go (library)"
        }

        platformOrchestrator = softwareSystem "Platform Orchestrator" "rhods-operator / opendatahub-operator — creates Workbenches CR and manages platform ConfigMap" "Internal RHOAI"
        kfNotebookController = softwareSystem "kf-notebook-controller" "Kubeflow Notebook controller — manages Notebook pod lifecycle" "Internal - Deployed by Operator"
        odhNotebookController = softwareSystem "odh-notebook-controller" "ODH Notebook controller — ODH-specific Notebook lifecycle management with gateway and MLflow integration" "Internal - Deployed by Operator"
        notebookImageStreams = softwareSystem "Notebook ImageStreams" "Available workbench container images (ODH / RHOAI variants)" "Internal - Deployed by Operator"

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External Infrastructure"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "External Infrastructure"
        serviceCA = softwareSystem "OpenShift Service-CA Controller" "Provisions and rotates webhook TLS certificates" "External Infrastructure"
        hardwareProfileCRD = softwareSystem "HardwareProfile CRD" "infrastructure.opendatahub.io — defines hardware resource profiles" "Internal RHOAI"

        # Relationships
        clusterAdmin -> platformOrchestrator "Configures platform components"
        datascientist -> kubernetesAPI "Creates/updates Notebook CRs via kubectl/Dashboard"

        platformOrchestrator -> workbenchesOperator "Creates Workbenches CR and manages odh-workbenches-config ConfigMap" "HTTPS/443 via Kubernetes API"
        workbenchesOperator -> kubernetesAPI "Watch CRs, SSA Patch, SubjectAccessReview, status updates" "HTTPS/443, TLS 1.2+, SA token"
        workbenchesOperator -> openshiftAPIServer "Read cluster TLS security profile" "HTTPS/443, TLS 1.2+, SA token"
        serviceCA -> workbenchesOperator "Provisions webhook TLS certificate" "service-CA annotation"

        workbenchesOperator -> kfNotebookController "Deploys and monitors readiness" "SSA via Kubernetes API"
        workbenchesOperator -> odhNotebookController "Deploys with gateway-url and mlflow-enabled params" "SSA via Kubernetes API"
        workbenchesOperator -> notebookImageStreams "Deploys platform-specific notebook images" "SSA via Kubernetes API"

        kubernetesAPI -> workbenchesOperator "Sends Notebook create/update webhook calls" "HTTPS/9443, TLS (service-CA)"
        workbenchesOperator -> hardwareProfileCRD "Reads HardwareProfile specs for webhook injection" "HTTPS/443 via Kubernetes API"
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
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal - Deployed by Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

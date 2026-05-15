workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and runs ML pipelines via Data Science Pipelines"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow execution engine for Kubernetes, powering Data Science Pipelines in RHOAI" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs and orchestrates workflow execution by creating and managing pods. Singleton with leader election." "Go Operator (UBI9, FIPS)"
            argoexec = container "argoexec" "Sidecar/init container injected into workflow pods. Manages artifact I/O, container lifecycle, and result reporting via emissary pattern." "Go Sidecar (UBI9, FIPS dual-binary)"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Core platform for CRD management, pod orchestration, RBAC, leader election" "External"
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and configures workflow-controller, provides argoexec image references" "Internal RHOAI"
        s3Minio = softwareSystem "S3 / Minio" "Artifact storage for workflow inputs, outputs, and logs" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archival and node status offloading" "External"
        mysql = softwareSystem "MySQL" "Alternative optional workflow archival backend" "External"
        gcs = softwareSystem "Google Cloud Storage" "Optional GCS artifact backend" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Optional Azure artifact backend" "External"
        containerRegistries = softwareSystem "Container Registries" "OCI image registries for resolving workflow step entrypoints" "External"

        # Relationships
        user -> dspo "Configures DSP instance via DataSciencePipelinesApplication CR"
        dspo -> argoWorkflows "Deploys and configures" "Kubernetes manifests"

        user -> k8sApi "Creates Workflow CRs via DSP API" "HTTPS/443"
        k8sApi -> workflowController "Watch events for Workflow/CronWorkflow CRDs" "HTTPS/443"
        workflowController -> k8sApi "CRD CRUD, pod management, leader election" "HTTPS/443"
        workflowController -> argoexec "Injects into workflow pods as sidecar" "Pod spec injection"
        argoexec -> k8sApi "Create WorkflowTaskResult CRs, read pod metadata" "HTTPS/443"
        argoexec -> s3Minio "Store and retrieve workflow artifacts" "HTTPS/443 or HTTP/9000"
        workflowController -> postgresql "Archive workflow data" "TCP/5432 SSL"
        workflowController -> mysql "Archive workflow data (alternative)" "TCP/3306"
        argoexec -> gcs "Store artifacts in GCS" "HTTPS/443"
        argoexec -> azureBlob "Store artifacts in Azure" "HTTPS/443"
        workflowController -> containerRegistries "Resolve step image entrypoints" "HTTPS/443 OCI"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
            description "Argo Workflows in the RHOAI ecosystem - system context view"
        }

        container argoWorkflows "Containers" {
            include *
            autoLayout
            description "Internal structure of Argo Workflows showing controller and executor"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

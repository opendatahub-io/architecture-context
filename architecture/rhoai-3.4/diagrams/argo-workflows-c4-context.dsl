workspace {
    model {
        user = person "Data Scientist" "Defines and submits ML training pipelines via DSP UI/API"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow execution engine for Data Science Pipelines" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs, creates pods, manages lifecycle, leader election, metrics" "Go Controller"
            argoexec = container "argoexec" "Sidecar executor injected into workflow pods; manages artifacts, captures outputs, reports results via emissary pattern" "Go Sidecar"
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows components" "Internal RHOAI"
        dspAPIServer = softwareSystem "DSP API Server" "User-facing pipeline API; submits Workflow CRs and reads results" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "CRD storage, pod management, RBAC, leader election" "Platform"
        s3Storage = softwareSystem "S3/MinIO Storage" "Artifact storage for pipeline inputs/outputs" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archival and node status offloading" "External"
        mysql = softwareSystem "MySQL" "Alternative optional persistence backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        # Relationships
        user -> dspAPIServer "Submits pipelines via UI/API"
        dspAPIServer -> kubernetesAPI "Creates Workflow CRs" "HTTPS/443"
        dspOperator -> argoWorkflows "Deploys and configures"

        workflowController -> kubernetesAPI "Watches CRDs, creates pods, leader election" "HTTPS/443"
        argoexec -> kubernetesAPI "Creates WorkflowTaskResult CRDs" "HTTPS/443"
        argoexec -> s3Storage "Uploads/downloads artifacts" "HTTPS/443"
        argoexec -> gcs "Uploads/downloads artifacts" "HTTPS/443"
        argoexec -> azureBlob "Uploads/downloads artifacts" "HTTPS/443"
        workflowController -> postgresql "Archives completed workflows" "TCP/5432"
        workflowController -> mysql "Archives completed workflows" "TCP/3306"
        prometheus -> workflowController "Scrapes metrics" "HTTPS/9090"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
        }

        container argoWorkflows "Containers" {
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
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}

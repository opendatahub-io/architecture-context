workspace {
    model {
        datascientist = person "Data Scientist" "Creates ML pipelines via RHOAI Dashboard"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow execution engine for ML pipeline steps" {
            workflowController = container "workflow-controller" "Watches Workflow CRs, orchestrates pod creation, manages DAG execution, handles CronWorkflows, artifact GC, and optional workflow archival" "Go (client-go informers)"
            argoexec = container "argoexec" "Emissary executor injected into workflow step pods; manages container lifecycle, captures outputs, handles artifact I/O" "Go Binary (standard + FIPS)"
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows components" "Internal RHOAI"
        kfpApiServer = softwareSystem "Kubeflow Pipelines API Server" "Compiles ML pipeline definitions into Argo Workflow CRs" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User interface for managing pipelines and experiments" "Internal RHOAI"

        k8sApiServer = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"
        s3Store = softwareSystem "S3-Compatible Object Store" "Pipeline artifact storage (Minio/AWS S3/GCS/Azure)" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archival and node status offloading" "External"
        containerRegistry = softwareSystem "Container Registry" "OCI image registry for executor images" "External"

        # Relationships
        datascientist -> rhoaiDashboard "Creates ML pipelines via"
        rhoaiDashboard -> kfpApiServer "Submits pipeline runs to"
        kfpApiServer -> k8sApiServer "Creates Workflow CRs via" "HTTPS/6443"

        dspOperator -> argoWorkflows "Deploys and configures"

        workflowController -> k8sApiServer "Watches Workflow CRs, creates Pods, manages lifecycle" "HTTPS/6443, SA Token"
        workflowController -> s3Store "Artifact garbage collection" "HTTPS/443, S3 credentials"
        workflowController -> postgresql "Archives completed workflows" "TCP/5432, Username/Password"

        argoexec -> k8sApiServer "Reports task results via WorkflowTaskResult CRs" "HTTPS/6443, SA Token"
        argoexec -> s3Store "Uploads/downloads pipeline artifacts" "HTTPS/443, S3 credentials"

        k8sApiServer -> containerRegistry "Pulls argoexec image for workflow pods" "HTTPS/443"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

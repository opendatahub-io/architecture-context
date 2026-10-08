workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and runs ML workflows and pipelines"
        dspOperator = person "DSP Operator" "Deploys and manages Data Science Pipelines stack" "Operator"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow engine for orchestrating parallel jobs on Kubernetes" {
            workflowController = container "workflow-controller" "Reconciles Workflow/CronWorkflow CRDs, manages pod lifecycle, handles leader election, cron scheduling, and artifact GC" "Go Controller"
            argoExec = container "argoexec" "Sidecar injected into workflow pods to manage artifact I/O, container lifecycle, and resource reporting" "Go Sidecar"
            argoServer = container "argo-server" "gRPC + REST API and web UI for workflow management (not deployed in RHOAI DSP)" "Go API Server"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane API server" "External"
        s3Storage = softwareSystem "S3 / Minio" "S3-compatible object storage for workflow artifacts" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "GCS storage for workflow artifacts" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Azure storage for workflow artifacts" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for workflow archiving (optional)" "External"
        mysql = softwareSystem "MySQL" "Relational database for workflow archiving (optional)" "External"
        dspServer = softwareSystem "Data Science Pipelines Server" "Pipeline API server that replaces argo-server in RHOAI" "Internal RHOAI"
        dspOperatorSystem = softwareSystem "data-science-pipelines-operator" "Deploys workflow-controller and argoexec as part of DSP stack" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        user -> dspServer "Creates and monitors pipelines via" "HTTPS"
        dspServer -> k8sAPI "Creates Workflow CRs via" "HTTPS/6443"
        dspOperatorSystem -> argoWorkflows "Deploys and configures"

        workflowController -> k8sAPI "Watches CRDs, creates pods, manages lifecycle" "HTTPS/6443"
        argoExec -> k8sAPI "Reports task status" "HTTPS/6443"
        argoExec -> s3Storage "Uploads/downloads artifacts" "HTTPS/443"
        argoExec -> gcsStorage "Uploads/downloads artifacts" "HTTPS/443"
        argoExec -> azureStorage "Uploads/downloads artifacts" "HTTPS/443"
        workflowController -> postgresql "Archives workflows (optional)" "TCP/5432"
        workflowController -> mysql "Archives workflows (optional)" "TCP/3306"
        prometheus -> workflowController "Scrapes metrics" "HTTP/9090"
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
            element "Operator" {
                shape Robot
            }
        }
    }
}

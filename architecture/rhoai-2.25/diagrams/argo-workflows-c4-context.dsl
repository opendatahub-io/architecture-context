workspace {
    model {
        dsp = person "Data Science Pipelines" "Creates and manages ML pipeline workflows via Workflow CRs"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow engine for orchestrating parallel jobs as DAGs and step-based workflows" {
            workflowController = container "workflow-controller" "Reconciles Workflow CRDs, creates execution Pods, manages lifecycle, handles CronWorkflows, artifact GC, and workflow archival" "Go Controller" "Primary"
            argoexec = container "argoexec" "Runs inside workflow Pods to execute steps, manage artifacts, capture logs, and report task results" "Go Sidecar/Init Container" "Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Runtime platform for CRDs, Pods, leader election, RBAC" "External"
        s3 = softwareSystem "S3/MinIO Artifact Store" "Stores and retrieves workflow artifacts (pipeline step outputs/inputs)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        azure = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archival and node status offloading" "External"
        mysql = softwareSystem "MySQL" "Optional workflow archival and node status offloading" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures workflow-controller and argoexec images" "Internal RHOAI"

        # System-level relationships
        dsp -> argoWorkflows "Creates Workflow CRs via" "Kubernetes API / HTTPS 443"
        argoWorkflows -> kubernetes "Manages CRDs, Pods, PVCs, Leases via" "HTTPS/443, SA Token"
        argoWorkflows -> s3 "Stores/retrieves artifacts via" "HTTPS/443, AWS IAM"
        argoWorkflows -> gcs "Stores/retrieves artifacts via" "HTTPS/443, SA JSON Key"
        argoWorkflows -> azure "Stores/retrieves artifacts via" "HTTPS/443, Azure Identity"
        argoWorkflows -> postgresql "Archives workflows via" "TCP/5432, Username/Password"
        argoWorkflows -> mysql "Archives workflows via" "TCP/3306, Username/Password"
        prometheus -> argoWorkflows "Scrapes metrics from" "HTTP/9090"
        dspOperator -> argoWorkflows "Deploys and configures" "Kubernetes Deployments"

        # Container-level relationships
        workflowController -> kubernetes "CRUD on Workflows, Pods, ConfigMaps, PVCs, PDBs, Leases" "HTTPS/443, ServiceAccount Token"
        workflowController -> s3 "Delete expired artifacts" "HTTPS/443, AWS IAM / AccessKey"
        workflowController -> postgresql "Archive workflow data" "TCP/5432, Username/Password"
        workflowController -> mysql "Archive workflow data" "TCP/3306, Username/Password"
        argoexec -> kubernetes "Create WorkflowTaskResults, read Secrets" "HTTPS/443, Workflow SA Token"
        argoexec -> s3 "Upload/download step artifacts" "HTTPS/443, AWS IAM / AccessKey"
        workflowController -> argoexec "Injects as sidecar in workflow Pods" "Pod spec"
        prometheus -> workflowController "Scrape metrics" "HTTP/9090"
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
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

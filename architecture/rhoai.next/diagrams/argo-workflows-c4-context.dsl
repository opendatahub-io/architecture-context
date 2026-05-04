workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and runs ML pipelines via Data Science Pipelines"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow engine for ML pipeline execution in RHOAI" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs, orchestrates pod creation, DAG/step scheduling, cron scheduling, artifact GC, workflow archival" "Go Controller (client-go informers)"
            argoexec = container "argoexec" "Runs as sidecar/init in workflow pods; manages artifact I/O, parameter extraction, container lifecycle via emissary pattern" "Go Executor (sidecar)"
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows controller and executor images" "Internal RHOAI"
        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform, CRD storage, RBAC enforcement" "External"
        s3 = softwareSystem "S3 / Minio" "Artifact storage for pipeline step inputs and outputs" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archive and node status offloading" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"

        # Relationships
        user -> dspOperator "Creates pipeline runs via DSP API"
        dspOperator -> argoWorkflows "Deploys controller, creates Workflow CRs"
        dspOperator -> kubernetes "Manages deployments"

        workflowController -> kubernetes "CRUD on Pods, Workflows, ConfigMaps, Secrets" "HTTPS/443 TLS 1.2+ SA Bearer"
        workflowController -> postgresql "Archive workflows, offload node status" "PostgreSQL/5432 TLS configurable"
        workflowController -> prometheus "Exposes metrics" "HTTP/9090"

        argoexec -> s3 "Upload/download pipeline artifacts" "HTTPS/443 S3 API"
        argoexec -> kubernetes "Patch WorkflowTaskResult, read Secrets" "HTTPS/443 TLS 1.2+ SA Bearer"
        argoexec -> gcs "Upload/download artifacts (alternative)" "HTTPS/443"
        argoexec -> azureBlob "Upload/download artifacts (alternative)" "HTTPS/443"
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
            element "Software System" {
                background #438DD5
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
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML pipeline runs via Data Science Pipelines"
        dspAdmin = person "Platform Admin" "Configures and manages DSP infrastructure"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow execution engine for Data Science Pipelines" {
            workflowController = container "workflow-controller" "Reconciles Workflow CRDs, creates pods, manages lifecycle, GC, and archival. Leader election via Leases. Worker pools: 32 workflow, 4 TTL, 4 cleanup, 8 cron, 8 archive." "Go Controller" "UID 8737"
            argoexec = container "argoexec" "Sidecar/init container in every step pod. Handles artifact upload/download, output capture, and result reporting. FIPS dual-build." "Go Executor (sidecar)" "UID 2000"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows components" "Internal RHOAI"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration, CRD hosting, pod execution" "External"
        s3 = softwareSystem "S3-compatible Storage" "Artifact storage for workflow inputs/outputs (S3, GCS, Azure Blob, HDFS)" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow history archival and node status offloading" "External"
        mysql = softwareSystem "MySQL" "Optional workflow history archival (alternative to PostgreSQL)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for workflow execution telemetry" "External"
        argoEvents = softwareSystem "Argo Events" "Event-driven workflow triggering via WorkflowEventBinding" "External"

        # User interactions
        user -> dspo "Creates DataSciencePipelinesApplication CR" "kubectl / UI"
        dspo -> argoWorkflows "Deploys, configures, manages lifecycle" "Kubernetes Deployment"

        # Workflow Controller interactions
        workflowController -> kubernetes "CRD CRUD, pod management, leader election" "HTTPS/443 TLS 1.2+"
        workflowController -> postgresql "Archive workflow history" "TCP/5432 TLS configurable"
        workflowController -> mysql "Archive workflow history (alt)" "TCP/3306 TLS configurable"

        # Executor interactions
        argoexec -> kubernetes "Patch annotations, report results" "HTTPS/443 TLS 1.2+"
        argoexec -> s3 "Upload/download artifacts" "HTTPS/443 TLS 1.2+"

        # Monitoring
        prometheus -> argoWorkflows "Scrape metrics" "HTTP/9090"

        # Event integration
        argoEvents -> argoWorkflows "Trigger workflows via WorkflowEventBinding" "CRD Watch"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

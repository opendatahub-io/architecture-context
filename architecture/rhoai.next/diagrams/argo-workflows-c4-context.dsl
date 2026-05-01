workspace {
    model {
        user = person "Data Scientist" "Creates and runs ML pipelines through Data Science Pipelines"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow execution engine for Data Science Pipelines" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs, creates/manages pods for workflow steps, handles lifecycle, GC, and archival" "Go Controller"
            argoexec = container "argoexec" "Runs inside workflow step pods as init/wait containers for artifact management and result reporting" "Go Executor Sidecar"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows components" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration, CRD hosting, pod execution" "External"
        s3 = softwareSystem "S3-compatible Storage" "Artifact storage for workflow inputs/outputs (S3, GCS, Azure Blob, HDFS)" "External"
        postgresql = softwareSystem "PostgreSQL / MySQL" "Optional workflow archival and node status offloading" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for workflow execution telemetry" "External"
        argoEvents = softwareSystem "Argo Events" "Event-driven workflow triggering via WorkflowEventBinding" "External"

        # Relationships
        user -> dspo "Submits pipeline runs via DSP API"
        dspo -> argoWorkflows "Deploys, configures, and manages lifecycle"

        workflowController -> k8sAPI "CRD CRUD, pod lifecycle, leader election, ConfigMap watch" "HTTPS/443"
        workflowController -> postgresql "Archives workflow history" "TCP/5432 or 3306"
        argoexec -> k8sAPI "Reports task results, patches pod annotations" "HTTPS/443"
        argoexec -> s3 "Uploads/downloads workflow artifacts" "HTTPS/443"

        prometheus -> argoWorkflows "Scrapes workflow execution metrics" "HTTP/9090"
        argoEvents -> argoWorkflows "Triggers workflows from EventSource/Sensor events"
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
            element "Container" {
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
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist" "Creates ML pipelines and workflows via DSP UI"
        dspUser = person "DSP API Consumer" "Submits workflows programmatically via DSP API"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow engine that orchestrates parallel jobs on Kubernetes using CRD-based workflow definitions" {
            workflowController = container "Workflow Controller" "Watches Workflow CRs, manages pod lifecycle, handles scheduling, retries, artifact GC, and cron workflows. Uses leader election for HA." "Go Controller (Deployment)"
            argoexec = container "argoexec" "Runs inside workflow pods as sidecar to manage container lifecycle, collect artifacts, and report task results" "Go Executor (Sidecar)"
        }

        dsp = softwareSystem "Data Science Pipelines" "Creates Workflow CRs consumed by the controller; provides API layer replacing argo-server" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "CRD CRUD, Pod lifecycle management, leader election, RBAC" "Infrastructure"
        artifactStorage = softwareSystem "Artifact Storage" "S3/MinIO, GCS, Azure Blob, OSS, HDFS — stores workflow artifacts" "External"
        archiveDB = softwareSystem "Workflow Archive DB" "PostgreSQL or MySQL — persists completed workflow records" "External"
        argoEvents = softwareSystem "Argo Events" "Event-driven workflow triggering via EventSource and Sensor CRDs" "External"

        # Relationships
        datascientist -> dsp "Creates ML pipelines via UI"
        dspUser -> dsp "Submits workflows via API"
        dsp -> argoWorkflows "Creates Workflow CRs" "Kubernetes CRD"

        workflowController -> k8sAPI "Watches CRDs, creates pods, manages lifecycle" "HTTPS/6443, SA token"
        argoexec -> k8sAPI "Reports WorkflowTaskResult CRs" "HTTPS/6443, SA token"
        argoexec -> artifactStorage "Uploads/downloads artifacts" "HTTPS/443, Cloud credentials"
        workflowController -> archiveDB "Persists completed workflow records" "TCP/5432 or 3306, TLS configurable"
        argoEvents -> argoWorkflows "Triggers workflows via events" "Kubernetes CRD"
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
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

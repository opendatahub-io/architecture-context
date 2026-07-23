workspace {
    model {
        user = person "Data Scientist / Pipeline User" "Creates and runs ML pipelines via Data Science Pipelines"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow engine for orchestrating parallel jobs on Kubernetes — powers Data Science Pipelines execution" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs and orchestrates pod creation, lifecycle management, artifact GC, cron scheduling, and workflow archival" "Go Operator"
            argoexec = container "argoexec" "Emissary executor — runs inside workflow pods, manages artifact loading/saving, container lifecycle, result reporting" "Go Sidecar"
            argoServer = container "argo-server" "API server providing REST/gRPC access to workflow management (deployed by DSP operator)" "Go Service"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform — Pods, Services, ConfigMaps, Leases, PVCs" "External"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures workflow-controller and argoexec images" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage for workflow inputs/outputs (MinIO, AWS S3)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archival and node status offloading" "External"
        mysql = softwareSystem "MySQL" "Alternative to PostgreSQL for workflow archival" "External"
        oidcProvider = softwareSystem "OIDC Provider" "SSO authentication for argo-server" "External"
        argoEvents = softwareSystem "Argo Events" "Event-driven workflow triggering via eventsources and sensors" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Optional metrics export via OTLP" "External"

        # Relationships
        user -> argoWorkflows "Submits workflows via kubectl or DSP API"
        dspOperator -> argoWorkflows "Deploys and configures"

        argoWorkflows -> kubernetes "Watches CRDs, creates Pods, manages lifecycle" "HTTPS/443"
        argoWorkflows -> s3Storage "Uploads/downloads workflow artifacts" "HTTPS/443"
        argoWorkflows -> gcs "Uploads/downloads workflow artifacts" "HTTPS/443"
        argoWorkflows -> azureBlob "Uploads/downloads workflow artifacts" "HTTPS/443"
        argoWorkflows -> postgresql "Archives completed workflows" "TCP/5432"
        argoWorkflows -> mysql "Archives completed workflows (alternative)" "TCP/3306"
        argoWorkflows -> oidcProvider "SSO authentication" "HTTPS/443"
        argoEvents -> argoWorkflows "Triggers workflows via WorkflowEventBindings"
        argoWorkflows -> otelCollector "Exports metrics via OTLP" "gRPC"

        # Container-level relationships
        workflowController -> kubernetes "Watches CRDs, creates/manages Pods" "HTTPS/443 SA Token"
        workflowController -> s3Storage "Resolves artifact repository config" "HTTPS/443"
        workflowController -> postgresql "Archives workflows" "TCP/5432 SSL"
        workflowController -> mysql "Archives workflows" "TCP/3306"
        argoexec -> kubernetes "Patches WorkflowTaskResults, reads ConfigMaps" "HTTPS/443 SA Token"
        argoexec -> s3Storage "Uploads/downloads artifacts" "HTTPS/443 IAM/Secret"
        argoexec -> gcs "Uploads/downloads artifacts" "HTTPS/443 GCP IAM"
        argoexec -> azureBlob "Uploads/downloads artifacts" "HTTPS/443 Azure AD"
        argoServer -> kubernetes "API proxy for workflow management" "HTTPS/443 SA Token"
        argoServer -> oidcProvider "SSO token validation" "HTTPS/443 OAuth2"
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

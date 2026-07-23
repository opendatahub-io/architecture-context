workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and runs ML pipeline workflows via Data Science Pipelines"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow engine powering DSP execution backend" {
            workflowController = container "Workflow Controller" "Reconciles Workflow CRDs, creates execution Pods, manages lifecycle, artifacts, caching, and garbage collection" "Go Controller" "Primary"
            argoexec = container "argoexec" "Executor sidecar injected into workflow pods - manages artifact staging, process proxying (emissary mode), and result reporting" "Go Executor Sidecar"
            argoServer = container "Argo Server" "gRPC + HTTP/1.1 API gateway with web UI, SSO/OIDC auth, webhook support (bundled in DSP, not separate Konflux image)" "Go API Server"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing CRD hosting, Pod execution, and RBAC" "External"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures workflow-controller and argoexec as part of DSP stack" "Internal RHOAI"
        dspAPIServer = softwareSystem "Data Science Pipelines API Server" "Submits Workflow CRDs for pipeline execution" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact repository for workflow artifacts (MinIO, AWS S3, GCS, Azure Blob)" "External"
        postgresql = softwareSystem "PostgreSQL" "Workflow archival and node status offloading (optional)" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores workflow container images; controller performs entrypoint lookup" "External"
        oidcProvider = softwareSystem "OIDC Provider" "SSO authentication via Dex, Keycloak, etc. (optional)" "External"
        gitProviders = softwareSystem "Git Providers" "GitHub, GitLab, Bitbucket - trigger workflows via webhooks" "External"

        # Relationships
        user -> dspAPIServer "Submits pipeline runs" "HTTPS/443"
        dspAPIServer -> argoWorkflows "Creates Workflow CRDs" "HTTPS/443"
        dspOperator -> argoWorkflows "Deploys and configures"

        workflowController -> kubernetes "CRD reconciliation, Pod CRUD, ConfigMap/Secret access, leader election" "HTTPS/443"
        workflowController -> s3Storage "Artifact garbage collection" "HTTPS/443"
        workflowController -> postgresql "Archives workflows (optional)" "TCP/5432 SSL"
        workflowController -> containerRegistry "Image entrypoint lookup" "HTTPS/443"

        argoexec -> kubernetes "Patches WorkflowTaskResult CRDs, reads pod annotations" "HTTPS/443"
        argoexec -> s3Storage "Uploads/downloads workflow artifacts" "HTTPS/443"

        argoServer -> kubernetes "CRUD operations on CRDs" "HTTPS/443"
        argoServer -> oidcProvider "SSO token exchange and JWKS verification" "HTTPS/443"
        gitProviders -> argoServer "Webhook event submission" "HTTPS/2746 HMAC-SHA256"
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

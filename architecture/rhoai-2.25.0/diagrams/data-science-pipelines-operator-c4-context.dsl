workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML pipeline workflows for data preparation, model training, validation, and experimentation"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Data Science Pipeline applications based on Kubeflow Pipelines" {
            controller = container "DSPO Controller" "Reconciles DataSciencePipelinesApplication CRs and manages component lifecycle" "Go Operator" {
                tags "Operator"
            }
            webhook = container "Webhook Server" "Validates and mutates PipelineVersion resources" "Go Service" {
                tags "Operator"
            }
            apiServer = container "API Server" "Main DSP API for pipeline management, execution, and artifact access" "Go Service" {
                tags "Core"
            }
            persistenceAgent = container "Persistence Agent" "Syncs workflow execution status to database" "Go Service" {
                tags "Core"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled/recurring pipeline executions" "Go Service" {
                tags "Core"
            }
            workflowController = container "Workflow Controller" "Namespace-scoped Argo controller for pipeline orchestration" "Argo Workflows" {
                tags "Core"
            }
            mlmdGrpc = container "MLMD gRPC" "ML Metadata service for artifact lineage tracking" "gRPC Service" {
                tags "Optional"
            }
            mlmdEnvoy = container "MLMD Envoy" "OAuth-protected proxy for MLMD service" "Envoy Proxy" {
                tags "Optional"
            }
            ui = container "ML Pipelines UI" "Web frontend for pipeline visualization" "React/TypeScript" {
                tags "Optional"
            }
        }

        # External Dependencies (Required)
        kubernetes = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External" {
            tags "Platform"
        }
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine for DSP v2" "External" {
            tags "External Required"
        }
        s3Storage = softwareSystem "S3-compatible Storage" "Pipeline artifact storage (Minio or AWS S3)" "External" {
            tags "External Required"
        }
        database = softwareSystem "MySQL/MariaDB" "Metadata persistence for pipeline definitions and execution history" "External" {
            tags "External Required"
        }
        oauthProxy = softwareSystem "OAuth Proxy" "OpenShift authentication for external access" "External" {
            tags "External Required"
        }

        # Optional External Dependencies
        tektonPipelines = softwareSystem "Tekton Pipelines" "Workflow orchestration for DSP v1 (legacy)" "External" {
            tags "External Optional"
        }
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External" {
            tags "External Optional"
        }
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Optional mTLS and traffic management" "External" {
            tags "External Optional"
        }

        # Internal ODH Components
        odhDashboard = softwareSystem "ODH Dashboard" "Unified web UI for Open Data Hub platform" "Internal ODH" {
            tags "Internal"
        }
        kserve = softwareSystem "KServe" "Model serving platform for deploying trained models" "Internal ODH" {
            tags "Internal"
        }
        ray = softwareSystem "Ray" "Distributed computing framework for ML workloads" "Internal ODH" {
            tags "Internal"
        }

        # External Services
        containerRegistry = softwareSystem "Container Registry" "Stores pipeline step container images" "External" {
            tags "External Service"
        }

        # Relationships - User
        user -> dspo "Creates DataSciencePipelinesApplication via kubectl/oc"
        user -> apiServer "Submits and manages pipelines via API" "HTTPS/OAuth"
        user -> ui "Visualizes pipelines and runs" "HTTPS/OAuth"
        user -> odhDashboard "Accesses DSP UI integration" "HTTPS"

        # Relationships - DSPO Core
        controller -> kubernetes "Watches DSPA CRs and manages resources" "HTTPS/6443"
        controller -> apiServer "Deploys and configures"
        controller -> persistenceAgent "Deploys and configures"
        controller -> scheduledWorkflow "Deploys and configures"
        controller -> workflowController "Deploys namespace-scoped instance"
        controller -> mlmdGrpc "Optionally deploys"
        controller -> mlmdEnvoy "Optionally deploys"
        controller -> ui "Optionally deploys"
        controller -> database "Optionally deploys MariaDB"
        controller -> s3Storage "Optionally deploys Minio"

        webhook -> kubernetes "Validates/mutates Pipeline and PipelineVersion CRs" "HTTPS/8443"

        # Relationships - API Server
        apiServer -> database "Stores pipeline metadata" "MySQL/3306"
        apiServer -> s3Storage "Stores and retrieves pipeline artifacts" "S3 API"
        apiServer -> kubernetes "Creates and manages Workflow CRs" "HTTPS/6443"
        apiServer -> mlmdGrpc "Records artifact lineage" "gRPC/8080"
        apiServer -> oauthProxy "Protected by OAuth authentication" "HTTP/8888"

        # Relationships - Workflow Execution
        workflowController -> kubernetes "Creates pipeline step pods" "HTTPS/6443"
        workflowController -> argoWorkflows "Uses for workflow orchestration (v2)"
        persistenceAgent -> kubernetes "Watches Workflow CRs" "HTTPS/6443"
        persistenceAgent -> database "Syncs execution status" "MySQL/3306"
        scheduledWorkflow -> kubernetes "Creates scheduled Workflow CRs" "HTTPS/6443"

        # Relationships - MLMD
        mlmdGrpc -> database "Stores artifact metadata and lineage" "MySQL/3306"
        mlmdEnvoy -> mlmdGrpc "Proxies gRPC requests with OAuth" "gRPC/8080"
        mlmdEnvoy -> oauthProxy "Protected by OAuth authentication"

        # Relationships - UI
        ui -> apiServer "Fetches pipeline data" "HTTP/8888"
        ui -> oauthProxy "Protected by OAuth authentication"
        odhDashboard -> ui "Embeds DSP UI"

        # Relationships - External Dependencies
        dspo -> argoWorkflows "Requires for DSP v2 pipelines"
        dspo -> tektonPipelines "Requires for DSP v1 pipelines (legacy)"
        dspo -> oauthProxy "Uses for external authentication"
        dspo -> certManager "Optionally uses for TLS certificates"
        dspo -> serviceMesh "Optionally integrates for mTLS"

        # Relationships - Integration Points
        apiServer -> kserve "Deploys models via InferenceService CRs" "K8s API"
        apiServer -> ray "Submits distributed compute jobs via Ray CRs" "K8s API"

        # Relationships - External Services
        workflowController -> containerRegistry "Pulls pipeline step images" "HTTPS/443"
    }

    views {
        systemContext dspo "DSPOSystemContext" {
            include *
            autoLayout
            description "System context diagram for Data Science Pipelines Operator showing external dependencies and integrations"
        }

        container dspo "DSPOContainers" {
            include *
            autoLayout
            description "Container diagram showing DSPO internal components and their interactions"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Core" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #7ec8e3
                color #000000
            }
            element "External Required" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #326ce5
                color #ffffff
            }
        }
    }
}

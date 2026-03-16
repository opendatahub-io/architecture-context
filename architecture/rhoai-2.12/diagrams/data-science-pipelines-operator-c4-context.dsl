workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and executes ML pipelines for data preparation, model training, and experimentation"
        developer = person "Developer" "Develops and submits pipeline code via SDK"

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages Data Science Pipeline (Kubeflow Pipelines) stacks in OpenShift namespaces" {
            controllerManager = container "Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and deploys pipeline components" "Go Operator"

            apiServer = container "DS Pipelines API Server" "REST/gRPC API for pipeline management, execution, and artifact retrieval" "Go Service" {
                restAPI = component "REST API (v2beta1)" "Pipeline management endpoints" "HTTP/gRPC"
                orchestrator = component "Workflow Orchestrator" "Creates and manages pipeline workflows" "Go"
                artifactManager = component "Artifact Manager" "Manages pipeline artifacts and signed URLs" "Go"
            }

            persistenceAgent = container "Persistence Agent" "Syncs workflow execution status to metadata database" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline runs" "Go Service"

            mariadb = container "MariaDB" "Stores pipeline and ML metadata" "MariaDB StatefulSet" "Database"
            minio = container "Minio" "Object storage for pipeline artifacts" "Minio Deployment" "Storage"

            ui = container "ML Pipelines UI" "Web interface for pipeline visualization and management" "TypeScript/React"

            mlmdGrpc = container "ML Metadata gRPC" "gRPC service for ML metadata artifact lineage tracking" "Python Service"
            mlmdEnvoy = container "ML Metadata Envoy" "Envoy proxy providing HTTP/gRPC access to MLMD with OAuth" "Envoy Proxy"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for DSP v2 pipelines" "External"
        tekton = softwareSystem "OpenShift Pipelines (Tekton)" "Workflow execution engine for DSP v1 pipelines (deprecated)" "External"

        openshift = softwareSystem "OpenShift/Kubernetes" "Container orchestration platform" "External"
        oauthProxy = softwareSystem "OAuth Proxy" "Authentication and authorization for external routes" "External"
        serviceCa = softwareSystem "Service CA Operator" "TLS certificate provisioning for inter-service communication" "External"

        externalS3 = softwareSystem "External S3 Storage" "Optional external object storage for pipeline artifacts" "External"
        externalDB = softwareSystem "External MySQL/MariaDB" "Optional external database for pipeline metadata" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Provides integrated pipeline UI and management interface" "Internal ODH"
        dsCluster = softwareSystem "DataScienceCluster CR" "Manages DSPO deployment as part of ODH/RHOAI platform" "Internal ODH"

        kfpSDK = softwareSystem "KFP SDK (v2)" "Python SDK for pipeline authoring and submission" "External"
        elyra = softwareSystem "Elyra" "Visual pipeline authoring and execution tool" "External"

        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"

        // User relationships
        dataScientist -> ui "Creates and monitors pipelines via web UI"
        dataScientist -> elyra "Authors pipelines visually"
        developer -> kfpSDK "Authors and submits pipelines via SDK"

        // SDK/Tool relationships
        kfpSDK -> apiServer "Submits and manages pipelines" "REST/gRPC 8443/TCP HTTPS OAuth2"
        elyra -> apiServer "Submits pipelines" "REST 8443/TCP HTTPS OAuth2"

        // UI relationships
        ui -> apiServer "Fetches pipeline data and metadata" "HTTP/gRPC 8888/TCP"

        // Operator relationships
        controllerManager -> openshift "Creates DSPA instance resources" "K8s API 443/TCP HTTPS"
        controllerManager -> apiServer "Deploys and manages" "K8s Resources"
        controllerManager -> persistenceAgent "Deploys and manages" "K8s Resources"
        controllerManager -> scheduledWorkflow "Deploys and manages" "K8s Resources"
        controllerManager -> mariadb "Conditionally deploys" "K8s Resources"
        controllerManager -> minio "Conditionally deploys" "K8s Resources"
        controllerManager -> ui "Conditionally deploys" "K8s Resources"
        controllerManager -> mlmdGrpc "Conditionally deploys" "K8s Resources"
        controllerManager -> mlmdEnvoy "Conditionally deploys" "K8s Resources"

        // API Server relationships
        apiServer -> argoWorkflows "Creates Workflow CRs for pipeline execution" "K8s API 443/TCP HTTPS"
        apiServer -> tekton "Creates Pipeline CRs (v1 - deprecated)" "K8s API 443/TCP HTTPS"
        apiServer -> mariadb "Stores pipeline metadata" "MySQL 3306/TCP"
        apiServer -> minio "Stores pipeline artifacts" "HTTP 9000/TCP"
        apiServer -> externalS3 "Stores pipeline artifacts (if configured)" "HTTPS 443/TCP"
        apiServer -> externalDB "Stores pipeline metadata (if configured)" "MySQL 3306/TCP"

        // Persistence Agent relationships
        persistenceAgent -> mariadb "Syncs workflow execution status" "MySQL 3306/TCP"

        // Scheduled Workflow relationships
        scheduledWorkflow -> argoWorkflows "Creates scheduled workflow CRs" "K8s API 443/TCP HTTPS"

        // ML Metadata relationships
        mlmdEnvoy -> mlmdGrpc "Proxies gRPC requests with OAuth" "gRPC 9090/TCP"
        mlmdGrpc -> mariadb "Stores ML metadata and lineage" "MySQL 3306/TCP"

        // Workflow engine relationships
        argoWorkflows -> minio "Pipeline pods download/upload artifacts" "HTTP 9000/TCP"
        argoWorkflows -> externalS3 "Pipeline pods download/upload artifacts (if configured)" "HTTPS 443/TCP"
        argoWorkflows -> mlmdEnvoy "Pipeline pods log ML metadata" "gRPC 9090/TCP"

        // Authentication and security
        oauthProxy -> apiServer "Protects external API access" "OAuth2 Bearer Token"
        oauthProxy -> ui "Protects UI access" "OAuth2 Bearer Token"
        oauthProxy -> mlmdEnvoy "Protects MLMD access" "OAuth2 Bearer Token"
        serviceCa -> oauthProxy "Provisions TLS certificates" "K8s API"

        // Platform integration
        dsCluster -> controllerManager "Manages operator deployment"
        odhDashboard -> ui "Embeds pipeline UI"

        // Monitoring
        prometheus -> controllerManager "Scrapes operator metrics" "HTTP 8080/TCP"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "Containers" {
            include *
            autoLayout
        }

        component apiServer "APIServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Database" {
                shape Cylinder
                background #4a90e2
                color #ffffff
            }
            element "Storage" {
                shape Folder
                background #f5a623
                color #000000
            }
        }

        themes default
    }
}

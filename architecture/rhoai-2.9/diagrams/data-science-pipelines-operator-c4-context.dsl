workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and executes ML pipeline workflows"

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages namespace-scoped Data Science Pipelines instances for ML workflow orchestration based on Kubeflow Pipelines" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and manages component lifecycle" "Go Operator" {
                tags "Operator"
            }

            apiServer = container "API Server" "REST/gRPC API for pipeline creation, execution, and management" "Go Service" {
                tags "Core"
            }

            persistenceAgent = container "Persistence Agent" "Syncs workflow status to database for pipeline run tracking" "Go Controller" {
                tags "Core"
            }

            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages cron-based recurring pipeline executions" "Go Controller" {
                tags "Core"
            }

            workflowController = container "Workflow Controller" "Argo-specific controller for workflow execution (v2 only)" "Argo" {
                tags "Core"
            }

            mlmd = container "ML Metadata gRPC" "ML metadata tracking and lineage service" "gRPC Service" {
                tags "Optional"
            }

            mlmdEnvoy = container "ML Metadata Envoy Proxy" "OAuth2 proxy for MLMD with mTLS termination" "Envoy Proxy" {
                tags "Optional"
            }

            mariadb = container "MariaDB" "Pipeline metadata storage (development)" "Database" {
                tags "Storage"
            }

            minio = container "Minio" "Pipeline artifact storage (development)" "Object Storage" {
                tags "Storage"
            }
        }

        odhDashboard = softwareSystem "ODH Dashboard" "User interface for pipeline interaction and management" "Internal ODH"

        openShiftOAuth = softwareSystem "OpenShift OAuth" "User authentication and authorization" "Platform Service"

        serviceMesh = softwareSystem "OpenShift Service Mesh" "mTLS, network policies, and service discovery" "Platform Service"

        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "Platform Service"

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution backend for DSP v2" "External Dependency"

        tektonPipelines = softwareSystem "Tekton Pipelines (OpenShift Pipelines)" "PipelineRun execution backend for DSP v1" "External Dependency"

        externalS3 = softwareSystem "S3-compatible Object Storage" "Production artifact storage for pipeline outputs" "External Service"

        externalDB = softwareSystem "MariaDB/MySQL Database" "Production metadata storage for pipeline runs" "External Service"

        kubernetes = softwareSystem "OpenShift/Kubernetes API" "Container orchestration platform" "Platform"

        certManager = softwareSystem "cert-manager / service-serving-cert" "TLS certificate provisioning for services" "Platform Service"

        %% User interactions
        dataScientist -> odhDashboard "Creates and manages pipelines via"
        dataScientist -> apiServer "Submits pipelines directly via kubectl/SDK"

        %% ODH Dashboard integration
        odhDashboard -> apiServer "Manages pipelines" "HTTPS/8443 (OAuth), gRPC/8887"
        odhDashboard -> mlmdEnvoy "Queries ML metadata" "HTTPS/9090 (OAuth2)"

        %% DSPO Controller interactions
        controller -> kubernetes "Watches DSPA CRs, creates resources" "HTTPS/6443"

        %% API Server interactions
        apiServer -> mariadb "Stores pipeline metadata" "TCP/3306"
        apiServer -> externalDB "Stores pipeline metadata (production)" "TCP/3306 TLS"
        apiServer -> mlmd "Tracks ML lineage" "gRPC/8080"
        apiServer -> workflowController "Creates Argo workflows (v2)" "HTTP/8080"
        apiServer -> tektonPipelines "Creates Tekton PipelineRuns (v1)" "Kubernetes API"

        %% Persistence Agent interactions
        persistenceAgent -> apiServer "Queries workflow status" "HTTP/8888"
        persistenceAgent -> mariadb "Updates run metadata" "TCP/3306"

        %% Scheduled Workflow interactions
        scheduledWorkflow -> kubernetes "Checks cron schedules" "HTTPS/6443"
        scheduledWorkflow -> apiServer "Triggers pipeline runs" "HTTP/8888"

        %% Workflow Controller interactions
        workflowController -> kubernetes "Creates pipeline pods" "HTTPS/6443"
        argoWorkflows -> workflowController "Provides workflow execution (v2)" "Embedded"
        tektonPipelines -> kubernetes "Executes PipelineRuns (v1)" "Kubernetes API"

        %% ML Metadata interactions
        mlmd -> mariadb "Persists metadata" "TCP/3306"
        mlmdEnvoy -> mlmd "Proxies with OAuth2/mTLS" "gRPC/8080"

        %% Storage interactions
        apiServer -> minio "Stores artifacts (dev)" "HTTP/9000"
        apiServer -> externalS3 "Stores artifacts (production)" "HTTPS/443"

        %% Platform services
        openShiftOAuth -> apiServer "Authenticates users" "OAuth proxy"
        serviceMesh -> apiServer "Provides mTLS and network policies" "Service Mesh"
        prometheusOperator -> controller "Scrapes operator metrics" "HTTP/8080"
        certManager -> apiServer "Provisions TLS certificates" "service-serving-cert annotation"
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

        styles {
            element "Person" {
                shape person
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
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Platform Service" {
                background #9673a6
                color #ffffff
            }
            element "Platform" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Core" {
                background #50c878
                color #ffffff
            }
            element "Optional" {
                background #ffa500
                color #ffffff
            }
            element "Storage" {
                background #708090
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist" "Develops and executes ML pipelines"

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages Data Science Pipeline stacks for ML workflow orchestration" {
            api = container "DS Pipelines API Server" "Provides KFP v2 API for pipeline management and execution" "REST API"
            controller = container "DSPO Controller Manager" "Reconciles DSPA resources and manages pipeline stack lifecycle" "Operator"
            argo = container "Argo Workflow Controller" "Executes pipeline workflows using Argo Workflows" "Workflow Engine"
            persistence = container "Persistence Agent" "Persists workflow metadata and artifacts to database" "Agent"
            scheduler = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline executions" "Scheduler"
            mlmd = container "ML Metadata" "Tracks ML artifacts, models, and lineage" "gRPC Service"
            mariadb = container "MariaDB" "Stores pipeline metadata and execution history" "Database"
            minio = container "Minio" "Stores pipeline artifacts and outputs" "Object Storage"
        }

        k8s = softwareSystem "Kubernetes API" "Container orchestration platform"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine"
        certManager = softwareSystem "cert-manager" "TLS certificate management"
        externalS3 = softwareSystem "External S3" "External object storage (optional)"
        externalDB = softwareSystem "External MariaDB" "External database (optional)"
        registry = softwareSystem "Container Registry" "Container image repository"

        odhDashboard = softwareSystem "ODH Dashboard" "Pipeline UI and notebook integration"
        odhOperator = softwareSystem "ODH Operator" "Manages ODH components via DataScienceCluster"
        notebooks = softwareSystem "Notebooks" "Jupyter notebooks for pipeline development"

        # Relationships
        user -> api "Submits pipelines, views results" "HTTPS/KFP SDK"
        user -> odhDashboard "Manages pipelines via UI" "HTTPS"

        controller -> k8s "Manages resources" "HTTPS"
        controller -> api "Manages deployment" "HTTP"
        controller -> argo "Manages deployment" "HTTP"
        controller -> certManager "Requests TLS certificates" "HTTPS"

        api -> mariadb "Stores pipeline metadata" "MySQL/TLS"
        api -> minio "Stores/retrieves artifacts" "S3 API/TLS"
        api -> argo "Creates workflows" "HTTP"
        api -> mlmd "Tracks lineage" "gRPC"

        argo -> k8s "Creates workflow pods" "HTTPS"
        argo -> argoWorkflows "Uses workflow engine" "CRD"

        persistence -> mariadb "Persists metadata" "MySQL/TLS"
        persistence -> mlmd "Tracks execution" "gRPC/mTLS"

        scheduler -> argo "Schedules workflows" "HTTP"

        api -> externalS3 "Optional artifact storage" "HTTPS"
        api -> externalDB "Optional metadata storage" "MySQL/TLS"

        odhDashboard -> api "Integrates pipeline UI" "HTTPS"
        odhOperator -> controller "Manages via DataScienceCluster" "CRD"
        notebooks -> argo "Executes pipeline steps" "K8s Pods"

        argo -> registry "Pulls executor images" "HTTPS"
    }

    views {
        systemContext dspo "DataSciencePipelinesOperator-Context" {
            include *
            autoLayout lr
        }

        container dspo "DataSciencePipelinesOperator-Containers" {
            include *
            autoLayout lr
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
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

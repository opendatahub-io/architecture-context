workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, submits, and monitors ML pipeline workflows"
        mlEngineer = person "ML Engineer" "Builds and deploys automated ML training pipelines"

        dsp = softwareSystem "Data Science Pipelines" "Kubernetes-native ML pipeline orchestration platform for defining, scheduling, running, and tracking machine learning workflows" {
            apiServer = container "API Server" "Central API gateway for all pipeline operations. Dual-protocol: REST (gRPC Gateway) on 8888/TCP and native gRPC on 8887/TCP. Includes webhook server on 8443/TCP for PipelineVersion validation/mutation." "Go Service" "Primary"
            driver = container "Driver" "Runs as init container in Argo Workflow steps. Prepares execution context, resolves inputs, generates pod spec patches, manages cache lookups." "Go CLI" "Utility"
            launcher = container "Launcher" "Runs alongside user containers. Manages artifact download/upload, publishes execution metadata to MLMD. Ships FIPS and non-FIPS binaries." "Go CLI" "Utility"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and ScheduledWorkflows. Syncs execution state to API server database via gRPC." "Go Service" "Primary"
            scheduledWorkflowCtrl = container "Scheduled Workflow Controller" "Watches ScheduledWorkflow CRDs, evaluates cron/periodic schedules, submits new pipeline runs when due." "Go Controller" "Primary"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine; executes pipeline DAGs as Kubernetes pods" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC metadata service for tracking pipeline lineage, executions, and artifacts" "External"
        mysql = softwareSystem "MySQL/MariaDB" "Relational database for pipeline metadata storage" "External"
        objectStore = softwareSystem "MinIO/S3 Object Store" "Artifact and pipeline specification storage" "External"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform, CRD operations, RBAC enforcement" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks and inter-service TLS" "External"

        dspaOperator = softwareSystem "DSPA Operator" "Manages lifecycle and configuration of all DSP components per namespace" "Internal RHOAI"
        dashboard = softwareSystem "OpenShift Dashboard" "UI for pipeline creation, monitoring, and artifact viewing" "Internal RHOAI"
        workbench = softwareSystem "Workbench (Jupyter)" "Submit pipelines from notebooks via kfp Python SDK" "Internal RHOAI"

        awsS3 = softwareSystem "AWS S3" "Cloud artifact storage" "Cloud Service"
        gcs = softwareSystem "Google Cloud Storage" "Alternative cloud artifact storage" "Cloud Service"

        # Person interactions
        dataScientist -> dsp "Creates and monitors pipelines via KFP SDK and Dashboard"
        mlEngineer -> dsp "Builds automated training pipelines with recurring schedules"

        # Internal RHOAI integrations
        dashboard -> dsp "Pipeline management UI" "REST/8888"
        workbench -> dsp "Pipeline submission from notebooks" "REST+gRPC/8888,8887"
        dspaOperator -> dsp "Deploys and configures DSP stack"

        # External dependencies
        dsp -> argoWorkflows "Workflow orchestration" "CRD via K8s API"
        dsp -> mlmd "Execution lineage and artifact metadata" "gRPC/8080"
        dsp -> mysql "Pipeline metadata persistence" "MySQL/3306"
        dsp -> objectStore "Artifact and pipeline spec storage" "HTTP(S)/9000"
        dsp -> kubernetes "Pod management, CRD ops, RBAC (SAR/TokenReview)" "HTTPS/6443"
        dsp -> certManager "TLS certificate provisioning"

        # Cloud services
        dsp -> awsS3 "Cloud artifact storage" "HTTPS/443"
        dsp -> gcs "Cloud artifact storage" "HTTPS/443"

        # Container-level relationships
        apiServer -> mysql "Store/retrieve pipeline metadata" "MySQL/3306"
        apiServer -> objectStore "Store/retrieve pipeline specs and artifacts" "HTTP(S)/9000"
        apiServer -> kubernetes "CRD operations, TokenReview, SubjectAccessReview" "HTTPS/6443"
        driver -> mlmd "Create executions, register artifacts" "gRPC/8080"
        driver -> apiServer "Cache lookup and storage" "gRPC/8887"
        driver -> kubernetes "PVC create/delete, ConfigMap reads" "HTTPS/6443"
        launcher -> mlmd "Publish execution results" "gRPC/8080"
        launcher -> objectStore "Download/upload artifacts" "HTTP(S)/9000"
        launcher -> apiServer "Report execution status" "gRPC/8887"
        persistenceAgent -> apiServer "Report workflow state" "gRPC/8887"
        persistenceAgent -> kubernetes "Watch Workflows and ScheduledWorkflows" "HTTPS/6443"
        scheduledWorkflowCtrl -> apiServer "CreateRun for scheduled executions" "gRPC/8887"
        scheduledWorkflowCtrl -> kubernetes "Watch/create ScheduledWorkflows and Workflows" "HTTPS/6443"
    }

    views {
        systemContext dsp "SystemContext" {
            include *
            autoLayout
        }

        container dsp "Containers" {
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
            element "Cloud Service" {
                background #f5a623
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Utility" {
                background #74b9ff
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

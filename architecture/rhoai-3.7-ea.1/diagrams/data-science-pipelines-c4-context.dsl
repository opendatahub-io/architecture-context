workspace "data-science-pipelines" "RHOAI 3.7-ea.1 Data Science Pipelines (Kubeflow Pipelines 2.16.1 downstream)" {
    model {
        user = person "Data Scientist" "Authors, submits and monitors ML pipelines via KFP SDK or ODH Dashboard"

        dsp = softwareSystem "Data Science Pipelines" "Red Hat downstream of Kubeflow Pipelines v2; per-namespace pipeline service" {
            apiServer = container "ml-pipeline API Server" "Pipeline/run/experiment/recurring-run CRUD, IR to Argo compilation, artifact/log read; gRPC 8887, REST 8888" "Go"
            webhook = container "PipelineVersion Webhook" "Validating + mutating admission for PipelineVersion CRs (8443, in API server process)" "Go"
            mlflowPlugin = container "MLflow Plugin" "Creates MLflow experiments/runs and injects tracking credentials" "Go module"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows/ScheduledWorkflows and reports state to ReportService; TTL GC" "Go controller"
            swfController = container "ScheduledWorkflow Controller" "Reconciles ScheduledWorkflow CRs into periodic/cron runs" "Go controller"
            driver = container "Driver" "Per-task: resolves inputs, cache, Kubernetes task config; records MLMD executions" "Go CLI"
            launcher = container "Launcher v2" "Per-task: wraps user container, moves artifacts, publishes outputs/logs" "Go CLI"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys DSP per namespace from DataSciencePipelinesApplication CR, plus DB, MLMD, auth proxy" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Pipelines UI" "Internal RHOAI"
        authProxy = softwareSystem "DSPA Route + Auth Proxy" "External access with OpenShift token authentication (DSPO-managed)" "Internal RHOAI"
        argo = softwareSystem "Argo Workflows" "Executes compiled pipeline workflows" "Internal RHOAI"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Lineage and cache store, gRPC 8080" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics scrape" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API" "CRDs, Workflows, TokenReview, SubjectAccessReview, pod logs" "External"
        db = softwareSystem "SQL Database" "MariaDB / MySQL / PostgreSQL for pipeline metadata" "External"
        s3 = softwareSystem "S3-compatible Object Store" "Pipeline packages, artifacts, logs" "External"

        user -> dashboard "Uses pipelines UI"
        user -> authProxy "Submits pipelines via KFP SDK" "HTTPS/443"
        dashboard -> authProxy "REST API" "HTTPS/443"
        authProxy -> apiServer "Forwards requests" "HTTP(S)/8888"
        dspo -> dsp "Deploys and configures"

        apiServer -> db "Stores metadata" "MySQL/3306 or PostgreSQL/5432"
        apiServer -> s3 "Reads/writes packages and artifacts" "HTTP(S)"
        apiServer -> mlmd "Lineage lookup" "gRPC/8080"
        apiServer -> k8s "Creates Workflows, SWF, Pipeline CRs; TokenReview/SAR" "HTTPS/6443"
        apiServer -> mlflowPlugin "Invokes"
        mlflowPlugin -> mlflow "Creates experiments and runs" "HTTPS"
        k8s -> webhook "PipelineVersion admission" "HTTPS/8443"
        persistenceAgent -> k8s "Watches Workflows/SWF" "HTTPS/6443"
        persistenceAgent -> apiServer "ReportService" "gRPC/8887"
        swfController -> k8s "Watches SWF, creates Workflows" "HTTPS/6443"
        swfController -> apiServer "Creates runs" "gRPC/8887"
        argo -> driver "Runs as workflow step"
        argo -> launcher "Runs as workflow step"
        driver -> mlmd "Executions, cache" "gRPC/8080"
        driver -> apiServer "Task state" "gRPC/8887"
        launcher -> s3 "Artifacts and logs" "HTTP(S)"
        launcher -> mlmd "Publishes outputs" "gRPC/8080"
        launcher -> apiServer "Task updates" "gRPC/8887"
        launcher -> mlflow "Metrics/params (optional)" "HTTPS"
        prometheus -> apiServer "Scrapes metrics" "HTTP"
        prometheus -> swfController "Scrapes /metrics" "HTTP"
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}

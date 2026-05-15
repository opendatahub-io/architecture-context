workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages LLM evaluation jobs via dashboard or SDK"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and evaluation infrastructure"

        evalHub = softwareSystem "Eval-Hub" "REST API service for orchestrating LLM evaluations across multiple framework backends" {
            apiServer = container "eval-hub API Server" "Central REST API for evaluation job orchestration, provider/collection management, experiment tracking" "Go HTTP Service"
            authMiddleware = container "Auth Middleware" "Authenticates via K8s TokenReview, authorizes via SubjectAccessReview with custom API groups" "Go Middleware"
            storageLayer = container "Storage Layer" "SQL-based persistence with JSON documents, supports SQLite and PostgreSQL" "Go SQL Interface"
            runtimeAbstraction = container "Runtime Abstraction" "Pluggable job execution — Kubernetes batch/v1 Jobs (production) or local processes (development)" "Go Interface"
            sidecar = container "eval-runtime-sidecar" "KEP-753 native sidecar in job pods — reverse proxy with auth token injection for eval-hub, MLflow, OCI" "Go HTTP Sidecar"
            initContainer = container "eval-runtime-init" "Init container that downloads S3 test data to shared volume before adapter starts" "Go CLI"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages eval-hub instances via EvalHub custom resource" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for authentication, authorization, and workload management" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Relational database for production persistent storage" "Infrastructure"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and metric logging for evaluation runs" "Internal RHOAI"
        s3 = softwareSystem "AWS S3" "Object storage for test data artifacts" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation result export" "External"
        otelCollector = softwareSystem "OTEL Collector" "Distributed tracing collection (optional)" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection via /metrics scrape endpoint" "Infrastructure"
        kueue = softwareSystem "Kueue" "Job queue management for evaluation workloads (optional)" "Platform"
        serviceCA = softwareSystem "OpenShift Service CA" "Provides CA certificates for internal service TLS" "Platform"

        # User interactions
        dataScientist -> evalHub "Creates evaluation jobs, manages providers and collections" "HTTPS/8080, Bearer Token"
        platformAdmin -> trustyaiOperator "Creates EvalHub CR to deploy instances" "kubectl"

        # Operator manages eval-hub
        trustyaiOperator -> evalHub "Deploys Deployment, Service, ConfigMap via EvalHub CR" "K8s API"

        # eval-hub dependencies
        evalHub -> k8sAPI "TokenReview, SAR, Job/ConfigMap CRUD" "HTTPS/443, SA Token"
        evalHub -> postgresql "Persistent storage for evaluations, providers, collections" "TCP/5432, Password"
        evalHub -> mlflow "Create/get experiments, log metrics" "HTTPS/5000, Bearer Token"
        evalHub -> s3 "Download test data (via init container)" "HTTPS/443, AWS IAM"
        evalHub -> ociRegistry "Export evaluation result artifacts (via sidecar)" "HTTPS/443, Bearer Token"
        evalHub -> otelCollector "Export distributed traces" "gRPC/4317, OTLP"
        prometheus -> evalHub "Scrape metrics" "HTTP(S)/8080"
        evalHub -> kueue "Job queue scheduling labels" "Label injection"
        evalHub -> serviceCA "CA certificates for internal TLS" "ConfigMap mount"

        # Internal container interactions
        apiServer -> authMiddleware "Validates requests"
        authMiddleware -> k8sAPI "TokenReview + SAR"
        apiServer -> storageLayer "CRUD operations"
        apiServer -> runtimeAbstraction "Job lifecycle"
        runtimeAbstraction -> k8sAPI "Create/delete batch/v1 Jobs"
        sidecar -> apiServer "Forward status events" "HTTPS/8443, SA Token"
        sidecar -> mlflow "Forward experiment tracking" "HTTPS/5000, Projected SA Token"
        sidecar -> ociRegistry "Forward artifact push/pull" "HTTPS/443, Bearer Token"
        initContainer -> s3 "Download test data" "HTTPS/443, AWS IAM"
    }

    views {
        systemContext evalHub "SystemContext" {
            include *
            autoLayout
        }

        container evalHub "Containers" {
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #438dd5
                color #ffffff
            }
            element "Infrastructure" {
                background #85bbf0
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

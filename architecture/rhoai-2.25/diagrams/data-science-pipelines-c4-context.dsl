workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, deploys, and monitors ML pipelines"
        mlEngineer = person "ML Engineer" "Builds and schedules recurring ML workflows"

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform (KFP v2) for defining, deploying, and managing reproducible ML workflows" {
            apiServer = container "API Server" "REST/gRPC API for pipeline, run, experiment, and artifact management. Serves as central hub." "Go Service, 8888/TCP HTTP, 8887/TCP gRPC"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and ScheduledWorkflows, persists state to database via API Server" "Go Service"
            swfController = container "Scheduled Workflow Controller" "Manages cron/periodic pipeline execution via ScheduledWorkflow CRD" "Go Controller"
            driver = container "Driver" "Orchestrates pipeline step execution: resolves inputs, checks cache, generates pod specs. Runs as init container in Argo pods." "Go Binary (Argo step)"
            launcher = container "Launcher" "Executes user code within pipeline step containers, publishes results to MLMD and object store. FIPS dual-binary." "Go Binary (Argo step)"
            cacheServer = container "Cache Server" "Kubernetes admission webhook for cache sidecar injection into Argo Workflow pods" "Go Service, 443/TCP HTTPS"
            frontendUI = container "Frontend UI" "Web UI for pipeline management" "TypeScript, 3000/TCP HTTP"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline step execution engine using Kubernetes Workflow CRDs" "External"
        mysql = softwareSystem "MySQL / PostgreSQL" "Relational database for pipeline, run, experiment, and cache metadata" "External"
        minio = softwareSystem "MinIO / S3" "Object storage for pipeline specs and step artifacts" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution lineage and artifact metadata tracking service" "External"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, CRD management, RBAC" "External"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys and manages DSP component lifecycle via DataSciencePipelinesApplication CR" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Frontend UI for RHOAI platform management" "Internal RHOAI"
        seldonCore = softwareSystem "Seldon Core" "Model serving platform (SeldonDeployment CRDs)" "Internal RHOAI"

        awsS3 = softwareSystem "AWS S3" "Cloud object storage for artifacts" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for artifacts" "External Cloud"

        # User interactions
        dataScientist -> dsp "Creates and monitors ML pipelines via REST API and UI"
        mlEngineer -> dsp "Schedules recurring pipelines and manages experiments"

        # Internal container interactions
        apiServer -> mysql "Stores pipeline/run/experiment metadata" "TCP/3306 or 5432, Username/Password"
        apiServer -> minio "Stores pipeline specs and artifacts" "HTTP(S)/9000 or 443, Access Key"
        apiServer -> kubernetes "Manages CRDs, RBAC checks (TokenReview/SAR)" "HTTPS/6443, SA Token"
        apiServer -> argoWorkflows "Creates Workflow CRs for pipeline execution" "HTTPS/6443, SA Token"
        persistenceAgent -> apiServer "Persists workflow state" "gRPC/8887, SA Token"
        persistenceAgent -> kubernetes "Watches Workflow and ScheduledWorkflow CRs" "HTTPS/6443, SA Token"
        swfController -> apiServer "Creates runs for scheduled pipelines" "gRPC/8887, SA Token"
        swfController -> kubernetes "Watches ScheduledWorkflows, creates Workflows" "HTTPS/6443, SA Token"
        driver -> mlmd "Resolves input artifacts and execution metadata" "gRPC/8080, Optional TLS"
        driver -> apiServer "Cache fingerprint lookup" "gRPC/8887"
        driver -> kubernetes "Reads ConfigMaps, manages PVCs" "HTTPS/6443, SA Token"
        launcher -> mlmd "Publishes output artifacts and parameters" "gRPC/8080, Optional TLS"
        launcher -> minio "Uploads step artifacts" "HTTP(S)/9000 or 443, Access Key"
        launcher -> apiServer "Records cache execution" "gRPC/8887"
        cacheServer -> kubernetes "Admission webhook for Argo pods" "HTTPS/443, TLS client cert"

        # External platform interactions
        rhoaiOperator -> dsp "Deploys and configures all DSP components" "Kubernetes CRD"
        dashboard -> apiServer "Pipeline management UI calls" "HTTP/8888, Bearer Token"
        launcher -> awsS3 "Uploads artifacts to cloud storage" "HTTPS/443, AWS IAM"
        launcher -> gcs "Uploads artifacts to cloud storage" "HTTPS/443, GCP SA"
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
            element "External Cloud" {
                background #f5a623
                color #000000
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

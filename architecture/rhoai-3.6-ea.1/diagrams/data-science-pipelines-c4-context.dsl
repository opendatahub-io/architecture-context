workspace {
    model {
        user = person "Data Scientist" "Creates, manages, and monitors ML pipelines"

        dsp = softwareSystem "Data Science Pipelines" "Kubernetes-deployed ML pipeline orchestration platform providing gRPC/REST APIs, Argo Workflows-based execution, metadata tracking, step-level caching, and a web UI" {
            apiServer = container "ml-pipeline API Server" "Central control plane serving v1beta1/v2beta1 REST/gRPC APIs for pipeline CRUD, execution, and artifact management. Per-request TokenReview + SubjectAccessReview authentication." "Go, gRPC-gateway" "API Server"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow status and synchronizes completed run state back to the API server database" "Go"
            scheduledWFController = container "Scheduled Workflow Controller" "Manages recurring pipeline runs via ScheduledWorkflow custom resources" "Go"
            cacheServer = container "Cache Server" "Mutating/validating admission webhooks on PipelineVersion resources for step-level caching" "Go"
            cacheDeployer = container "Cache Deployer" "Manages webhook certificate lifecycle for cache server" "Go"
            driver = container "Driver" "Manages individual step execution within Argo Workflow pods" "Go, FIPS"
            launcherV2 = container "Launcher-v2" "Handles container launches within workflow pods" "Go"
            metadataEnvoy = container "Metadata Envoy Proxy" "Proxies gRPC traffic to ML Metadata service" "Envoy"
            mlmd = container "ML Metadata Server" "Artifact and execution lineage tracking via gRPC" "C++, gRPC"
            metadataWriter = container "Metadata Writer" "Syncs pod metadata to ML Metadata" "Python"
            pipelineUI = container "ml-pipeline-ui" "Web interface for browsing and managing pipelines and runs" "Node.js"
            vizServer = container "Visualization Server" "Generates visualizations for pipeline outputs" "Python"
            viewerController = container "Viewer CRD Controller" "Manages viewer deployments from Viewer custom resources" "Go"
            mysql = container "MySQL" "Pipeline metadata persistence store" "MySQL 8.4" "Database"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline execution orchestration via Workflow CRs" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for RBAC, CRD management, TokenReview, SubjectAccessReview" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for pipeline artifacts (MinIO, SeaweedFS, AWS S3)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from API server and controllers" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbenches for data scientists" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "mTLS enforcement and AuthorizationPolicy for MySQL access control" "External"

        # User interactions
        user -> dsp "Submits pipelines, creates runs, monitors execution via REST/gRPC and web UI"
        user -> pipelineUI "Browses pipelines and runs" "HTTP/80"

        # API Server interactions
        apiServer -> k8sAPI "Creates Argo Workflow CRs, TokenReview, SubjectAccessReview" "HTTPS/6443"
        apiServer -> mysql "Persists pipeline metadata" "MySQL/3306"
        apiServer -> s3Storage "Stores pipeline artifacts" "HTTP/S"
        apiServer -> argoWorkflows "Creates Workflow resources for pipeline execution"

        # Execution engine
        argoWorkflows -> driver "Launches driver pods for step management"
        driver -> launcherV2 "Launches step containers"
        launcherV2 -> s3Storage "Downloads/uploads artifacts" "HTTP/S"

        # State synchronization
        persistenceAgent -> k8sAPI "Watches Workflow status" "HTTPS/6443"
        persistenceAgent -> apiServer "Reports run completion"
        scheduledWFController -> k8sAPI "Creates Workflow CRs on schedule" "HTTPS/6443"

        # Admission webhooks
        k8sAPI -> cacheServer "Mutating/validating webhooks for PipelineVersion" "HTTPS/8443"

        # Metadata
        metadataWriter -> metadataEnvoy "Writes execution metadata" "gRPC/9090"
        metadataEnvoy -> mlmd "Proxies to MLMD" "gRPC/8080"

        # Frontend
        pipelineUI -> apiServer "Queries pipeline data" "REST/8888"

        # Monitoring
        prometheus -> apiServer "Scrapes metrics" "HTTP/8888"
        prometheus -> scheduledWFController "Scrapes metrics" "HTTP"

        # Notebooks integration
        dsp -> kubeflowNotebooks "Creates and manages notebook workbenches" "HTTPS"

        # Istio
        istio -> mysql "Enforces AuthorizationPolicy for MySQL access"
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
            element "Software System" {
                background #4a90e2
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "API Server" {
                background #2c5282
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape cylinder
            }
        }
    }
}

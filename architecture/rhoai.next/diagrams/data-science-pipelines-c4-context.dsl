workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, submits, and monitors ML pipelines via KFP SDK or Web UI"

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform — compiles, schedules, executes, and tracks machine learning workflows on Kubernetes" {
            apiServer = container "API Server" "REST/gRPC API for pipeline, run, experiment, and artifact management" "Go Service" "8888/TCP REST, 8887/TCP gRPC"
            frontendUI = container "Frontend UI" "Web UI for pipeline visualization, run management, and artifact browsing" "React/TypeScript"
            frontendServer = container "Frontend Server" "BFF proxy handling auth, artifact streaming, and API proxying" "Express.js" "3000/TCP"
            driver = container "Driver" "Pipeline step orchestrator — resolves inputs, checks cache, generates pod specs" "Go CLI (init container)"
            launcher = container "Launcher" "Executes user containers, manages artifacts, publishes results to MLMD" "Go CLI (sidecar)"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows, persists state to database via API server" "Go Service"
            scheduledWFCtrl = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRDs, triggers runs on schedule" "Go Controller"
            cacheServer = container "Cache Server" "Mutating admission webhook for pipeline step caching" "Go Service" "8443/TCP HTTPS"
            cacheDeployer = container "Cache Deployer" "Deploys and manages cache webhook TLS certificates" "Go Service"
            metadataWriter = container "Metadata Writer" "Watches Argo Workflow pods, records execution metadata to MLMD" "Python Service"
            visualizationServer = container "Visualization Server" "Generates visualizations from pipeline artifacts" "Python Service"
            viewerController = container "Viewer Controller" "Manages Viewer CRD instances (TensorBoard) as Deployments + Services" "Go Controller"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for pipeline runs (v3.7.11)" "External"
        database = softwareSystem "MySQL / PostgreSQL" "Pipeline, run, experiment, and cache state storage" "External"
        objectStore = softwareSystem "MinIO / S3 / GCS" "Artifact and log storage" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution lineage and artifact tracking via gRPC" "External"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, RBAC, admission control" "External"

        dspaOperator = softwareSystem "DSPA Operator" "Creates and manages all DSP service deployments per-namespace" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "mTLS, AuthorizationPolicy for multi-user isolation" "Internal RHOAI"
        openShiftRouter = softwareSystem "OpenShift Router" "External access to pipeline UI via Routes" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "Internal RHOAI"

        # User interactions
        dataScientist -> dsp "Creates and monitors pipelines via KFP SDK (REST/gRPC) and Web UI"
        dataScientist -> frontendUI "Browses pipelines, views runs, inspects artifacts"
        dataScientist -> apiServer "Submits pipelines and runs via KFP SDK" "REST/8888, gRPC/8887"

        # Internal component interactions
        frontendUI -> frontendServer "Served by"
        frontendServer -> apiServer "Proxies API requests" "HTTP/8888"
        apiServer -> database "Stores/retrieves pipeline state" "MySQL/3306, PG/5432"
        apiServer -> objectStore "Stores/retrieves artifacts and logs" "HTTP(S)/9000,443"
        apiServer -> mlmd "Queries artifact lineage" "gRPC/8080"
        apiServer -> kubernetes "Creates Argo Workflows, RBAC checks" "HTTPS/443"
        driver -> mlmd "Resolves upstream outputs" "gRPC/8080"
        driver -> apiServer "Cache lookups" "gRPC/8887"
        launcher -> objectStore "Uploads/downloads artifacts" "HTTP(S)/9000,443"
        launcher -> mlmd "Publishes execution results" "gRPC/8080"
        persistenceAgent -> kubernetes "Watches Argo Workflows" "HTTPS/443"
        persistenceAgent -> apiServer "Reports workflow state" "gRPC/8887"
        scheduledWFCtrl -> apiServer "Creates scheduled runs" "gRPC/8887"
        scheduledWFCtrl -> kubernetes "Watches ScheduledWorkflows" "HTTPS/443"
        cacheServer -> database "Cache entry lookups" "MySQL/3306"
        cacheDeployer -> cacheServer "Provisions TLS certificates"
        metadataWriter -> mlmd "Writes execution metadata" "gRPC/8080"
        metadataWriter -> kubernetes "Watches workflow pods" "HTTPS/443"

        # External system interactions
        dsp -> argoWorkflows "Creates and monitors Workflows" "Kubernetes API"
        dsp -> database "Persists all platform state" "MySQL/PG wire protocol"
        dsp -> objectStore "Stores all artifacts" "HTTP(S)"
        dsp -> mlmd "Tracks execution lineage" "gRPC/8080"
        dsp -> kubernetes "Resource management, RBAC" "HTTPS/443"

        # Internal platform interactions
        dspaOperator -> dsp "Deploys and manages all DSP components per-namespace"
        istio -> dsp "Provides mTLS and AuthorizationPolicy for multi-user isolation"
        openShiftRouter -> frontendServer "Routes external traffic to UI" "HTTPS/443 → HTTP/3000"
        certManager -> cacheServer "Provisions webhook TLS certificates"
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
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

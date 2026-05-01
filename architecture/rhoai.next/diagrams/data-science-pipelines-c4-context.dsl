workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, submits, and monitors ML pipelines using KFP SDK or UI"
        platformAdmin = person "Platform Admin" "Manages DSP installations via DSPA operator"

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform — compiles, schedules, executes, and tracks ML workflows on Kubernetes (Kubeflow Pipelines v2)" {
            apiServer = container "API Server" "Central REST/gRPC API for pipeline, run, experiment, and artifact management. Hosts PipelineVersion webhook." "Go Service" "8888/TCP REST, 8887/TCP gRPC, 8443/TCP Webhook"
            frontendUI = container "Frontend UI" "Web UI for pipeline visualization, run management, and artifact browsing" "React/TypeScript SPA" "3000/TCP"
            frontendServer = container "Frontend Server" "Backend-for-frontend proxy handling auth, artifact streaming, and API proxying" "Express/TypeScript"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and ScheduledWorkflows, persists state to database via API server" "Go Service"
            scheduledWFController = container "Scheduled Workflow Controller" "Kubernetes controller for ScheduledWorkflow CRD, triggers runs on schedule" "Go Controller" "9090/TCP metrics"
            cacheServer = container "Cache Server" "Mutating admission webhook for pipeline step caching" "Go Service" "8443/TCP HTTPS"
            cacheDeployer = container "Cache Deployer" "Deploys and manages cache webhook TLS certificates" "Go Service"
            driver = container "Driver" "Pipeline step orchestrator — init container that resolves inputs, checks cache, generates pod specs" "Go CLI"
            launcher = container "Launcher" "Executes user containers, manages artifacts, publishes results to MLMD" "Go CLI (FIPS-compliant)"
            metadataWriter = container "Metadata Writer" "Watches Argo Workflow pods and records execution metadata to MLMD" "Python Service"
            viewerController = container "Viewer Controller" "Manages Viewer CRD instances (TensorBoard) as Deployments + Services" "Go Controller"
            visualizationServer = container "Visualization Server" "Generates visualizations from pipeline artifacts" "Python Service" "8888/TCP"
            argoCompiler = container "Argo Compiler" "Compiles KFP pipeline specs into Argo Workflow manifests" "Go Library"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for pipeline runs (v3.7.11)" "External"
        database = softwareSystem "MySQL / PostgreSQL" "Pipeline, run, experiment, and cache state storage" "External"
        objectStore = softwareSystem "MinIO / S3 / GCS" "Artifact and log storage" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution lineage and artifact tracking via gRPC" "External"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, RBAC, admission control" "External"

        dspaOperator = softwareSystem "DSPA Operator" "Creates and manages all DSP service deployments per-namespace" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "mTLS, AuthorizationPolicy, multi-user network isolation" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning for webhooks" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Route CR for external UI access" "Internal RHOAI"

        # User interactions
        dataScientist -> dsp "Defines pipelines via KFP SDK, submits runs, monitors execution" "HTTP/gRPC"
        dataScientist -> frontendUI "Browses pipelines, views runs, inspects artifacts" "HTTPS/443"
        platformAdmin -> dspaOperator "Configures DataSciencePipelinesApplication CR" "kubectl"

        # Internal container relationships
        frontendUI -> frontendServer "Proxies API calls" "HTTP"
        frontendServer -> apiServer "REST API calls" "HTTP/8888"
        persistenceAgent -> apiServer "Reports workflow state" "gRPC/8887, Projected SA Token"
        scheduledWFController -> apiServer "Creates scheduled runs" "gRPC/8887, Projected SA Token"
        driver -> apiServer "Cache lookup" "gRPC/8887"
        driver -> mlmd "Resolves upstream inputs" "gRPC/8080"
        launcher -> mlmd "Publishes execution results" "gRPC/8080"
        launcher -> objectStore "Downloads/uploads artifacts" "HTTP(S)/9000/443"
        metadataWriter -> mlmd "Records execution metadata" "gRPC/8080"

        # External system interactions
        dsp -> argoWorkflows "Creates and monitors Argo Workflow CRs" "Kubernetes API/443"
        dsp -> database "Stores pipeline, run, experiment, cache state" "MySQL/PG wire/3306/5432"
        dsp -> objectStore "Stores and retrieves artifacts and logs" "HTTP(S)/9000/443"
        dsp -> mlmd "Execution lineage, artifact tracking" "gRPC/8080"
        dsp -> kubernetes "Resource management, RBAC checks (TokenReview, SubjectAccessReview)" "HTTPS/443"

        # Infrastructure interactions
        dspaOperator -> dsp "Deploys and manages all DSP components" "Kubernetes API"
        istio -> dsp "Provides mTLS and AuthorizationPolicies (multi-user mode)" "Sidecar injection"
        certManager -> dsp "Provisions webhook TLS certificates" "Certificate CR"
        openshiftRouter -> frontendUI "Routes external traffic to UI" "HTTPS/443 edge TLS"
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
                shape Person
                background #4a90e2
                color #ffffff
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, deploys, and monitors ML pipelines"
        platformAdmin = person "Platform Admin" "Deploys and configures the DSP platform via DSPO"

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform (Kubeflow Pipelines v2) for defining, executing, and managing reproducible ML workflows" {
            apiServer = container "ml-pipeline API Server" "Central API for pipeline CRUD, run management, experiment tracking, artifact queries, and webhook validation" "Go Service" "8888/TCP REST, 8887/TCP gRPC, 8443/TCP webhooks"
            ui = container "ml-pipeline-ui" "Frontend SPA serving React application and proxying API/artifact requests" "Node.js/Express + React" "3000/TCP HTTP"
            persistenceAgent = container "ml-pipeline-persistenceagent" "Background agent syncing Argo Workflow state to API server via informers" "Go Service"
            swfController = container "ml-pipeline-scheduledworkflow" "Controller managing ScheduledWorkflow CRDs for recurring pipeline runs" "Go Controller"
            viewerController = container "ml-pipeline-viewer-crd" "Controller creating TensorBoard viewer Deployments and Services from Viewer CRDs" "Go Controller (controller-runtime)"
            cacheServer = container "cache-server" "Mutating admission webhook checking execution cache on pod creation" "Go Webhook Server" "8443/TCP HTTPS"
            cacheDeployer = container "cache-deployer" "Manages TLS certificates and webhook configuration for cache server" "Go Utility"
            driver = container "ml-pipeline-driver" "Per-step orchestrator resolving MLMD inputs, managing caching, generating pod spec patches" "Go CLI (Argo task)" "Ephemeral"
            launcher = container "ml-pipeline-launcher" "Per-step executor downloading artifacts, running user code, uploading outputs" "Go CLI (Argo task)" "Ephemeral, dual FIPS binary"
            vizServer = container "ml-pipeline-visualizationserver" "Renders custom HTML visualizations (TFDV, TFMA)" "Python Service" "8888/TCP HTTP"
            mlmd = container "ML Metadata (MLMD)" "Artifact lineage and execution metadata store" "gRPC Server" "8080/TCP gRPC"
            envoyProxy = container "Envoy Proxy" "gRPC-Web proxy for browser access to MLMD" "Envoy" "9090/TCP HTTP/2"
        }

        argo = softwareSystem "Argo Workflows" "Pipeline execution engine — orchestrates workflow pods on Kubernetes" "External"
        db = softwareSystem "MySQL / PostgreSQL" "Relational database for pipeline, run, experiment, and job persistence" "External"
        objectStore = softwareSystem "MinIO / SeaweedFS / S3" "S3-compatible blob storage for pipeline artifacts, specs, and logs" "External"
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages all DSP sub-components via DataSciencePipelinesApplication CR" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "mTLS, AuthorizationPolicy, and traffic routing between services" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API" "Container orchestration, RBAC, TokenReview, SubjectAccessReview" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Optional experiment tracking for metrics, parameters, and artifacts" "External"
        oauth = softwareSystem "OpenShift OAuth" "User authentication for multi-user deployments" "Internal RHOAI"

        # Person relationships
        dataScientist -> dsp "Creates pipelines, submits runs, views results" "HTTP REST / gRPC"
        platformAdmin -> dspo "Configures DataSciencePipelinesApplication CR" "kubectl / RHOAI Dashboard"

        # System context relationships
        dsp -> argo "Submits Workflow CRDs for pipeline execution" "HTTPS/443"
        dsp -> db "Persists pipeline metadata, runs, experiments, cache entries" "TCP/3306 or 5432"
        dsp -> objectStore "Stores/retrieves pipeline artifacts, specs, logs" "HTTP/9000"
        dsp -> k8sApi "CRD management, TokenReview, SubjectAccessReview, informers" "HTTPS/443"
        dsp -> mlflow "Logs metrics, parameters, artifacts (optional plugin)" "HTTPS/8443"
        dspo -> dsp "Deploys and manages all sub-components" "Kubernetes API"
        istio -> dsp "Enforces mTLS and AuthorizationPolicy" "Sidecar injection"
        oauth -> dsp "Provides user authentication tokens" "Token passthrough"

        # Container relationships
        ui -> apiServer "Proxies API requests and artifact retrieval" "HTTP/8888, gRPC/8887"
        ui -> vizServer "Renders custom visualizations" "HTTP/8888"
        apiServer -> db "Stores pipeline metadata" "TCP/3306 or 5432"
        apiServer -> objectStore "Stores pipeline specs and artifacts" "HTTP/9000"
        apiServer -> argo "Submits Argo Workflows" "HTTPS/443"
        apiServer -> mlmd "Queries artifact metadata" "gRPC/8080"
        apiServer -> k8sApi "TokenReview, SubjectAccessReview, CRD management" "HTTPS/443"
        persistenceAgent -> apiServer "Reports workflow execution state" "gRPC/8887"
        persistenceAgent -> k8sApi "Watches Argo Workflow resources via informers" "HTTPS/443"
        swfController -> apiServer "Creates runs on schedule" "gRPC/8887"
        swfController -> k8sApi "Watches ScheduledWorkflow CRDs" "HTTPS/443"
        viewerController -> k8sApi "Creates viewer Deployments and Services" "HTTPS/443"
        cacheDeployer -> cacheServer "Manages TLS certificates" "Internal"
        driver -> mlmd "Resolves inputs, records execution metadata" "gRPC/8080"
        driver -> apiServer "Checks and creates cache entries" "gRPC/8887"
        launcher -> objectStore "Downloads inputs, uploads outputs" "HTTP/9000"
        launcher -> mlmd "Records execution results" "gRPC/8080"
        envoyProxy -> mlmd "Proxies gRPC-Web to gRPC" "gRPC/8080"
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

workspace {
    model {
        user = person "Data Scientist" "Defines, submits, schedules, and monitors ML pipeline workflows"
        admin = person "Platform Admin" "Deploys and configures DSP instances via DSPO"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines backend providing API, execution engine, and scheduling for ML pipeline workflows" {
            apiServer = container "API Server (ml-pipeline)" "Central REST/gRPC gateway for pipeline CRUD, experiment management, run execution, and artifact retrieval" "Go Service" {
                restApi = component "REST API" "HTTP endpoints for pipeline operations" "gRPC-Gateway"
                grpcServices = component "gRPC Services" "Pipeline, Experiment, Run, RecurringRun, Artifact, Task, Report, Auth, Visualization, Healthz" "gRPC"
                webhookServer = component "Webhook Server" "Validates and mutates PipelineVersion CRDs" "HTTPS Admission Webhook"
                authInterceptor = component "Auth Interceptor" "TokenReview + SubjectAccessReview" "Go Interceptor"
            }
            driver = container "Driver" "Orchestrates individual pipeline steps — resolves inputs, manages caching, creates MLMD executions" "Go CLI (Argo step)"
            launcher = container "Launcher v2" "Executes user containers, handles artifact I/O, publishes metadata to MLMD" "Go CLI (Argo step)"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows via informers, syncs execution state to API server" "Go Agent"
            swfController = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRD, creates Argo Workflows on cron/periodic schedules" "Go Controller"
            cacheServer = container "Cache Server" "Mutating admission webhook injecting cached outputs into Argo pods" "Go Webhook Server"
            viewerController = container "Viewer Controller" "Creates TensorBoard Deployments from Viewer CRDs" "Go Controller"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages DSP component lifecycle per namespace via DataSciencePipelinesApplication CRD" "Internal RHOAI"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine — pipeline steps run as Argo Workflow tasks" "External"
        database = softwareSystem "MySQL / PostgreSQL" "Relational database for pipeline, experiment, run metadata" "External"
        objectStore = softwareSystem "MinIO / S3 / GCS" "Object storage for pipeline specs, artifacts, and logs" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC service for artifact lineage and execution tracking" "External"
        k8sApi = softwareSystem "Kubernetes API" "Resource management, RBAC enforcement, admission webhooks" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks" "External"
        openshift = softwareSystem "OpenShift" "Platform providing Route/HTTPRoute for API ingress" "External"
        mlflow = softwareSystem "MLflow" "Optional experiment tracking integration" "External"
        istio = softwareSystem "Istio / Service Mesh" "Multi-user traffic routing and authorization" "External"

        # User interactions
        user -> dsp "Creates/monitors pipelines and runs via REST/gRPC"
        admin -> dspo "Deploys DSP instances via DataSciencePipelinesApplication CR"

        # DSPO manages DSP
        dspo -> dsp "Deploys and manages all sub-components"

        # API Server dependencies
        apiServer -> database "Stores pipeline metadata" "SQL/3306-5432"
        apiServer -> objectStore "Stores pipeline specs and artifacts" "S3 API/9000-443"
        apiServer -> mlmd "Artifact lineage queries" "gRPC/8080"
        apiServer -> argoWorkflows "Creates Workflow resources" "HTTPS/443"
        apiServer -> k8sApi "SubjectAccessReview, TokenReview, resource management" "HTTPS/443"
        apiServer -> mlflow "Optional experiment/run tracking" "HTTP/HTTPS"

        # Driver dependencies
        driver -> mlmd "Creates executions, artifact lineage" "gRPC/8080"
        driver -> apiServer "Cache key lookup, task creation" "gRPC/8887"
        driver -> objectStore "Artifact upload/download" "S3 API"
        driver -> k8sApi "PVC creation, pod spec patching" "HTTPS/443"

        # Launcher dependencies
        launcher -> objectStore "Downloads inputs, uploads outputs" "S3 API"
        launcher -> mlmd "Publishes execution metadata" "gRPC/8080"

        # Persistence Agent
        persistenceAgent -> apiServer "ReportWorkflow, ReportScheduledWorkflow" "gRPC/8887"
        persistenceAgent -> k8sApi "Watches Workflows and ScheduledWorkflows" "HTTPS/443"

        # Scheduled Workflow Controller
        swfController -> apiServer "CreateRun for v2 pipelines" "gRPC/8887"
        swfController -> k8sApi "Watch/Create ScheduledWorkflows and Workflows" "HTTPS/443"

        # Cache Server
        cacheServer -> k8sApi "Mutating admission webhook" "HTTPS/443"

        # Viewer Controller
        viewerController -> k8sApi "Creates TensorBoard Deployments" "HTTPS/443"

        # External → DSP
        openshift -> apiServer "Route ingress" "HTTPS/443"
        istio -> apiServer "VirtualService routing (multi-user)" "HTTP"
        certManager -> cacheServer "Provisions TLS certificates" "Certificate CRD"
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

        component apiServer "APIServerComponents" {
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
        }
    }
}

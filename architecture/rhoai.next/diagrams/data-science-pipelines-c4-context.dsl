workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, submits, and monitors ML pipelines"
        platformAdmin = person "Platform Admin" "Deploys and manages DSP instances via DSPO"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines backend for ML pipeline orchestration on Kubernetes" {
            apiserver = container "ml-pipeline API Server" "Central REST/gRPC API for pipeline CRUD, run management, artifact access, and admission webhooks" "Go Service" {
                restHandler = component "REST Handler" "Handles /apis/v2beta1/* and /apis/v1beta1/* endpoints" "gorilla/mux + grpc-gateway"
                grpcServer = component "gRPC Server" "Serves Experiment, Pipeline, Run, Job, Artifact, and other services" "gRPC v1.82.1"
                webhookServer = component "Webhook Server" "Validates and mutates PipelineVersion CRs" "controller-runtime"
                authInterceptor = component "Auth Interceptor" "TokenReview and SubjectAccessReview enforcement" "Go"
            }
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow status and syncs to API server" "Go Controller"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages ScheduledWorkflow CRDs for recurring runs" "Go Controller"
            driver = container "Driver" "Resolves task inputs, computes pod spec patches, manages DAG execution" "Go Init/Sidecar"
            launcher = container "Launcher" "Downloads/uploads artifacts, invokes Python executor" "Go Sidecar"
            cacheServer = container "Cache Server" "Mutating webhook for execution caching" "Go Webhook"
            ui = container "Pipeline UI" "Web interface for pipeline management and run visualization" "TypeScript/React"
            vizServer = container "Visualization Server" "Generates ROC curves, confusion matrices from run outputs" "Python Service"
            metadataWriter = container "Metadata Writer" "Writes ML Metadata entries from Workflow annotations" "Python Service"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for pipeline DAGs" "External"
        mysql = softwareSystem "MySQL / MariaDB" "Relational database for pipeline metadata and run state" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for pipeline artifacts and definitions" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server for artifact lineage and execution tracking" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for resource management, auth, and RBAC" "External"
        istio = softwareSystem "Istio" "Service mesh for mTLS and authorization policies" "External"
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages DSP instances per namespace via DSPApplication CR" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks" "External"

        # User interactions
        dataScientist -> dsp "Submits pipelines and monitors runs" "REST/gRPC"
        dataScientist -> ui "Manages pipelines via web UI" "HTTPS"
        platformAdmin -> dspo "Creates DSPApplication CRs" "kubectl"

        # Internal container interactions
        ui -> apiserver "API calls" "HTTP/8888"
        persistenceAgent -> apiserver "Reports run status" "gRPC/8887"
        persistenceAgent -> k8sAPI "Watches Argo Workflows" "HTTPS/6443"
        scheduledWorkflow -> k8sAPI "Watches ScheduledWorkflows, creates Workflows" "HTTPS/6443"
        driver -> mlmd "Records execution metadata" "gRPC/8080"
        launcher -> s3Storage "Downloads/uploads artifacts" "HTTP/HTTPS"
        metadataWriter -> mlmd "Writes lineage entries" "gRPC/8080"
        vizServer -> s3Storage "Reads run output artifacts" "HTTP/HTTPS"

        # External dependencies
        apiserver -> mysql "Persists pipeline metadata" "TCP/3306"
        apiserver -> s3Storage "Stores pipeline definitions and artifacts" "HTTP/HTTPS"
        apiserver -> k8sAPI "Creates Workflows, manages CRDs, auth checks" "HTTPS/6443"
        apiserver -> mlmd "Queries execution metadata" "gRPC/8080"
        cacheServer -> k8sAPI "Intercepts pod creation for caching" "HTTPS/6443"
        dsp -> argoWorkflows "Executes pipeline DAGs" "Kubernetes API"
        dsp -> istio "Service-to-service mTLS and authorization" "mTLS"
        dspo -> dsp "Deploys and configures all components" "CRD reconciliation"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8888"
        prometheus -> scheduledWorkflow "Scrapes metrics" "HTTP/9090"
        certManager -> apiserver "Provisions webhook TLS certs" "Secret"
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

        component apiserver "APIServerComponents" {
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
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

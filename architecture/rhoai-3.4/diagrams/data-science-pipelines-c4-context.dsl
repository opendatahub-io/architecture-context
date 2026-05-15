workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, schedules, and monitors ML pipeline workflows"
        mlEngineer = person "ML Engineer" "Builds and deploys production ML pipelines"

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform (Kubeflow Pipelines v2) for defining, scheduling, executing, and monitoring ML workflows on Kubernetes" {
            apiServer = container "API Server" "Central REST/gRPC API for managing pipelines, runs, experiments, and artifacts with database and object store backends" "Go Service" "8888/TCP HTTP, 8887/TCP gRPC"
            driver = container "Driver" "Orchestrates pipeline step execution within Argo Workflow pods; resolves inputs, evaluates conditions, manages caching, generates pod spec patches" "Go CLI (Argo init container)"
            launcher = container "Launcher" "Wraps user container execution; downloads input artifacts, runs user code, uploads output artifacts, publishes to MLMD. Ships dual FIPS/non-FIPS binaries" "Go CLI (container wrapper)"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and ScheduledWorkflows, persists execution state to API server database" "Go Controller"
            scheduledWorkflowController = container "Scheduled Workflow Controller" "Manages ScheduledWorkflow CRD; creates Argo Workflows or API Runs on cron/periodic schedules" "Go Controller"
            cacheServer = container "Cache Server" "Kubernetes mutating admission webhook that intercepts pod creation and injects cached pipeline outputs" "Go Webhook" "8443/TCP HTTPS"
            viewerController = container "Viewer Controller" "Manages Viewer CRD instances; creates Tensorboard deployments" "Go Controller"
            frontendUI = container "Frontend UI" "Web interface for browsing pipelines, runs, experiments, and visualizations" "TypeScript/React" "3000/TCP HTTP"
            vizServer = container "Visualization Server" "Generates pipeline run visualizations" "Python Service"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline step execution engine; creates Workflow CRs for each pipeline run" "External" {
            tags "External"
        }

        database = softwareSystem "MySQL / PostgreSQL" "Pipeline, experiment, run, and cache metadata storage" "External" {
            tags "External"
        }

        objectStore = softwareSystem "S3 / MinIO / GCS" "Object storage for pipeline specs, artifacts, and logs" "External" {
            tags "External"
        }

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC service for pipeline execution lineage and artifact tracking" "External" {
            tags "External"
        }

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, RBAC, resource management" "External" {
            tags "External"
        }

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Deploys and manages DSP instances via DataSciencePipelinesApplication CRD" "Internal RHOAI" {
            tags "Internal"
        }

        rhoaiOperator = softwareSystem "RHOAI Operator" "Installs DSPO and manages its lifecycle" "Internal RHOAI" {
            tags "Internal"
        }

        gatewayAPI = softwareSystem "Gateway API" "Platform ingress via HTTPRoute for RHOAI 3.x" "Internal RHOAI" {
            tags "Internal"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "External"
        }

        # User interactions
        dataScientist -> dsp "Defines and monitors pipelines via REST API and UI"
        mlEngineer -> dsp "Builds production pipelines via SDK and API"

        # Container-level relationships
        apiServer -> database "Stores metadata" "TCP/3306 or 5432, Username/Password"
        apiServer -> objectStore "Stores pipeline specs and artifacts" "HTTP(S)/9000 or 443, Access Key/IAM"
        apiServer -> kubernetes "Creates Argo Workflows, RBAC checks" "HTTPS/443, ServiceAccount Token"
        apiServer -> argoWorkflows "Creates Workflow CRs" "Kubernetes API"

        driver -> mlmd "Creates execution contexts" "gRPC/8080, Optional TLS"
        driver -> apiServer "Cache queries via TaskService" "gRPC/8887, Bearer Token"
        driver -> kubernetes "Reads ConfigMaps, manages PVCs" "HTTPS/443, ServiceAccount Token"

        launcher -> objectStore "Downloads/uploads artifacts" "HTTP(S)/9000 or 443, Access Key/IAM"
        launcher -> mlmd "Publishes execution results" "gRPC/8080, Optional TLS"

        persistenceAgent -> kubernetes "Watches Argo Workflows" "HTTPS/443 Watch, ServiceAccount Token"
        persistenceAgent -> apiServer "Reports workflow state" "gRPC/8887, Bearer Token (SA)"

        scheduledWorkflowController -> kubernetes "Watches ScheduledWorkflows" "HTTPS/443 Watch, ServiceAccount Token"
        scheduledWorkflowController -> apiServer "Creates runs on schedule" "gRPC/8887, Bearer Token (SA)"

        cacheServer -> database "Cache lookups" "TCP/3306, Username/Password"
        kubernetes -> cacheServer "Sends AdmissionReview for pod creation" "HTTPS/443→8443, TLS"

        frontendUI -> apiServer "Renders pipeline data" "HTTP/8888"
        vizServer -> apiServer "Fetches visualization data" "HTTP/8888"

        # Platform relationships
        dspo -> dsp "Deploys all components via DSPA CR"
        rhoaiOperator -> dspo "Manages DSPO lifecycle"
        gatewayAPI -> apiServer "Routes external traffic" "HTTPRoute, HTTPS/443"

        # Monitoring
        prometheus -> apiServer "Scrapes /metrics" "HTTP/8888"
        prometheus -> scheduledWorkflowController "Scrapes metrics" "HTTP/9090"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
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

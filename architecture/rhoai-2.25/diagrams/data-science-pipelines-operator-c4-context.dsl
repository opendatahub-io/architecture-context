workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or SDK"
        mlEngineer = person "ML Engineer" "Manages pipeline infrastructure and DSPA configurations"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines V2 deployments on OpenShift via DSPA custom resources" {
            controller = container "DSPO Controller Manager" "Reconciles DSPA CRs, orchestrates sub-component deployment with dependency ordering" "Go Operator (controller-runtime)"
            apiServer = container "DS Pipeline API Server" "Kubeflow Pipelines REST/gRPC API for pipeline CRUD and execution" "Go Service" {
                tags "Pipeline Core"
            }
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow status back to API server" "Go Service" {
                tags "Pipeline Core"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages recurring pipeline runs via cron schedules" "Go Service" {
                tags "Pipeline Core"
            }
            argoController = container "Argo Workflow Controller" "Executes pipeline DAGs as Argo Workflows" "Go Service" {
                tags "Execution Engine"
            }
            mlmdGrpc = container "MLMD gRPC Server" "Stores ML metadata (artifacts, executions, contexts)" "C++ Service" {
                tags "Metadata"
            }
            mlmdEnvoy = container "MLMD Envoy Proxy" "HTTP-to-gRPC translation with OAuth authentication" "Envoy Proxy" {
                tags "Metadata"
            }
            pipelinesUI = container "ML Pipelines UI" "Web UI for viewing pipeline runs, artifacts, experiments" "Node.js" {
                tags "UI"
            }
            webhook = container "Pipeline Version Webhook" "Validates and mutates PipelineVersion CRs" "Go Service" {
                tags "Admission Control"
            }
            mariadb = container "MariaDB" "Default relational database for pipeline metadata" "MariaDB" {
                tags "Storage" "Database"
            }
            minio = container "MinIO" "Default S3-compatible artifact storage" "MinIO" {
                tags "Storage" "Object Store"
            }
        }

        // External Systems
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management and CRD operations" "External" {
            tags "External"
        }
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller with TLS termination/reencrypt" "External" {
            tags "External"
        }
        serviceCa = softwareSystem "OpenShift Service CA" "Auto-provisions TLS certificates for annotated services" "External" {
            tags "External"
        }
        oauthProxy = softwareSystem "OpenShift OAuth" "OpenShift SSO authentication via oauth-proxy sidecars" "External" {
            tags "External"
        }
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus metrics scraping via ServiceMonitor CRs" "External" {
            tags "External"
        }

        // Internal ODH/RHOAI Systems
        platformOperator = softwareSystem "ODH/RHOAI Platform Operator" "Creates DSPA CRs to deploy pipeline stacks" "Internal RHOAI" {
            tags "Internal RHOAI"
        }
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing Data Science projects and pipelines" "Internal RHOAI" {
            tags "Internal RHOAI"
        }
        trustedCaBundle = softwareSystem "ODH Trusted CA Bundle" "ConfigMap with custom/proxy CA certificates" "Internal RHOAI" {
            tags "Internal RHOAI"
        }

        // Integration targets (pipeline execution)
        kserve = softwareSystem "KServe" "ML model serving (InferenceService CRs created by pipelines)" "Internal RHOAI" {
            tags "Internal RHOAI" "Integration"
        }
        ray = softwareSystem "Ray" "Distributed compute (RayCluster/RayJob CRs created by pipelines)" "Internal RHOAI" {
            tags "Internal RHOAI" "Integration"
        }
        codeflare = softwareSystem "CodeFlare" "Distributed workload management (AppWrapper CRs)" "Internal RHOAI" {
            tags "Internal RHOAI" "Integration"
        }

        // External storage backends
        externalDb = softwareSystem "External Database" "Alternative to built-in MariaDB (MySQL-compatible)" "External" {
            tags "External" "Optional"
        }
        externalS3 = softwareSystem "External S3 Storage" "Alternative to built-in MinIO (AWS S3, Ceph, etc.)" "External" {
            tags "External" "Optional"
        }

        // Relationships - Users
        dataScientist -> dashboard "Creates pipelines via" "HTTPS/443"
        dataScientist -> dspo "Submits pipeline runs via" "HTTPS/443 (Route)"
        mlEngineer -> dspo "Creates DSPA CRs via" "kubectl/HTTPS"

        // Relationships - Platform
        platformOperator -> dspo "Creates DSPA CRs" "Kubernetes API"
        dashboard -> dspo "Pipeline management" "HTTPS/443 (Route)"

        // Relationships - Internal
        controller -> k8sApi "Watches DSPA CRs, applies manifests" "HTTPS/443"
        controller -> mariadb "Health checks" "MySQL/3306"
        controller -> minio "Health checks" "HTTP/9000"
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores pipeline artifacts" "HTTP/9000"
        apiServer -> k8sApi "Creates Workflow CRs" "HTTPS/443"
        persistenceAgent -> apiServer "Syncs workflow status" "REST/8888 + gRPC/8887"
        argoController -> k8sApi "Creates pipeline pods" "HTTPS/443"
        mlmdGrpc -> mariadb "Stores ML metadata" "MySQL/3306"
        mlmdEnvoy -> mlmdGrpc "HTTP-to-gRPC proxy" "gRPC/8080"
        pipelinesUI -> apiServer "Fetches pipeline data" "REST/8888"

        // Relationships - External
        dspo -> serviceCa "TLS certificate injection" "Annotation-based"
        dspo -> oauthProxy "Authentication sidecars" "HTTPS/8443"
        dspo -> openshiftRouter "External access via Routes" "HTTPS/443 Reencrypt"
        dspo -> monitoring "Exposes Prometheus metrics" "HTTP/8080, 8888"
        dspo -> trustedCaBundle "Reads CA certificates" "ConfigMap watch"

        // Relationships - Optional external backends
        apiServer -> externalDb "Pipeline metadata (optional)" "MySQL/3306 TLS"
        apiServer -> externalS3 "Pipeline artifacts (optional)" "HTTPS/443"

        // Relationships - Integration targets
        dspo -> kserve "Pipeline steps create InferenceServices" "Kubernetes API"
        dspo -> ray "Pipeline steps create RayClusters" "Kubernetes API"
        dspo -> codeflare "Pipeline steps create AppWrappers" "Kubernetes API"

        k8sApi -> webhook "Admission review" "HTTPS/8443"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "Containers" {
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
            element "Integration" {
                background #50c878
                color #ffffff
            }
            element "Pipeline Core" {
                background #4a90e2
                color #ffffff
            }
            element "Execution Engine" {
                background #e8a838
                color #ffffff
            }
            element "Metadata" {
                background #9b59b6
                color #ffffff
            }
            element "UI" {
                background #3498db
                color #ffffff
            }
            element "Storage" {
                background #e74c3c
                color #ffffff
            }
            element "Admission Control" {
                background #f5a623
                color #ffffff
            }
            element "Optional" {
                background #cccccc
                color #333333
                border dashed
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

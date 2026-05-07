workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML pipelines, experiments, and runs"
        platformAdmin = person "Platform Admin" "Deploys and configures DSPA instances"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines v2 stack on OpenShift AI" {
            controller = container "DSPAReconciler" "Reconciles DSPA CRs; deploys all sub-components via manifestival templating" "Go Operator (controller-runtime)"
            apiServer = container "ds-pipeline-api-server" "KFP v2 REST/gRPC API for pipeline CRUD, run management, artifact access" "Go Service" {
                tags "Templated"
            }
            kubeRbacProxy = container "kube-rbac-proxy" "Authenticates external requests via SubjectAccessReview" "Sidecar" {
                tags "Security"
            }
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow status back to KFP database" "Go Service" {
                tags "Templated"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Creates Argo Workflows from ScheduledWorkflow CRs on cron triggers" "Go Service" {
                tags "Templated"
            }
            workflowController = container "Argo Workflow Controller" "Orchestrates pipeline step execution as Kubernetes pods" "Argo 3.6.12" {
                tags "Templated"
            }
            mlmdGrpc = container "MLMD gRPC Server" "ML Metadata — stores experiment, artifact, execution lineage" "gRPC Service" {
                tags "Templated"
            }
            mlmdEnvoy = container "MLMD Envoy Proxy" "Fronts MLMD gRPC with kube-rbac-proxy for external access" "Envoy + kube-rbac-proxy" {
                tags "Templated"
            }
            webhook = container "Pipeline Webhook" "Admission webhook for PipelineVersion validation" "Go Service" {
                tags "Templated"
            }
            managedDB = container "MariaDB" "Pipeline metadata and MLMD storage (optional managed)" "MariaDB 10.5" {
                tags "Storage Optional"
            }
            managedMinIO = container "MinIO" "Pipeline artifact storage (optional managed, dev/test)" "MinIO" {
                tags "Storage Optional"
            }
        }

        rhodsOperator = softwareSystem "RHOAI Platform Operator" "Deploys DSPO with image refs and config via kustomize" "Internal RHOAI" {
            tags "Internal Platform"
        }
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing pipelines and viewing results" "Internal RHOAI" {
            tags "Internal Platform"
        }
        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster API for all resource CRUD operations" "Platform"
        openShiftRouter = softwareSystem "OpenShift Router" "Ingress controller with TLS termination" "Platform"
        serviceCa = softwareSystem "OpenShift service-ca" "Generates TLS certificates for services" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Platform"

        externalDB = softwareSystem "External Database" "MySQL/MariaDB for pipeline metadata (user-provided)" "External" {
            tags "External"
        }
        externalS3 = softwareSystem "External S3 Storage" "S3-compatible object store for artifacts (user-provided)" "External" {
            tags "External"
        }
        ociRegistry = softwareSystem "OCI Registry" "Container image registry for managed pipelines" "External" {
            tags "External"
        }

        kserve = softwareSystem "KServe" "Model serving inference platform" "Internal RHOAI" {
            tags "Internal Platform"
        }
        ray = softwareSystem "Ray" "Distributed compute framework" "Internal RHOAI" {
            tags "Internal Platform"
        }
        codeflare = softwareSystem "CodeFlare" "Batch workload scheduling" "Internal RHOAI" {
            tags "Internal Platform"
        }

        # Relationships - External Users
        dataScientist -> dspo "Submits pipelines, creates runs via REST/gRPC" "HTTPS/443"
        dataScientist -> dashboard "Manages pipelines via web UI" "HTTPS/443"
        platformAdmin -> dspo "Creates DataSciencePipelinesApplication CRs" "kubectl"

        # Relationships - Platform
        rhodsOperator -> dspo "Deploys operator with image refs/config" "Kustomize"
        dspo -> kubeAPI "CRUD all managed Kubernetes resources" "HTTPS/443"
        dspo -> serviceCa "Obtains TLS certificates for services" "annotation-based"
        dspo -> openShiftRouter "Creates Routes for external access" "HTTPS/443"
        dspo -> prometheus "Exposes metrics via ServiceMonitor" "HTTP/8888"

        # Relationships - External Services
        dspo -> externalDB "Pipeline metadata storage" "MySQL/3306 TLS"
        dspo -> externalS3 "Artifact storage and retrieval" "HTTPS/443"
        dspo -> ociRegistry "Fetches managed pipeline manifests" "HTTPS/443"

        # Relationships - Internal Integrations
        dspo -> kserve "Pipeline steps create InferenceService CRs" "K8s API"
        dspo -> ray "Pipeline steps create Ray CRs for distributed compute" "K8s API"
        dspo -> codeflare "Pipeline steps create AppWrapper CRs" "K8s API"
        dashboard -> dspo "Queries pipeline runs and MLMD lineage" "HTTPS/443"

        # Internal container relationships
        kubeRbacProxy -> apiServer "Proxies authenticated requests" "HTTP/8888"
        persistenceAgent -> apiServer "Syncs workflow status" "HTTP/8888"
        workflowController -> kubeAPI "Manages Workflow pods" "HTTPS/443"
        apiServer -> managedDB "Stores pipeline metadata" "MySQL/3306"
        apiServer -> managedMinIO "Stores artifacts" "HTTP/9000"
        mlmdGrpc -> managedDB "Stores lineage data" "MySQL/3306"
        mlmdEnvoy -> mlmdGrpc "Proxies gRPC requests" "gRPC/8080"
        controller -> apiServer "Deploys and configures" "manifestival"
        controller -> workflowController "Deploys" "manifestival"
        controller -> mlmdGrpc "Deploys" "manifestival"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Storage Optional" {
                background #e74c3c
                color #ffffff
            }
            element "Security" {
                background #9b59b6
                color #ffffff
            }
            element "Templated" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or CLI"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and DSPA instances"

        # Primary System
        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Kubeflow Pipelines v2 deployments on OpenShift" {
            controllerManager = container "DSPO Controller Manager" "Reconciles DSPA CRs, deploys and manages all pipeline sub-components via Go templates" "Go Operator (controller-runtime)"
            pipelineVersionWebhook = container "PipelineVersion Webhook" "Validates and mutates PipelineVersion CRs for Kubernetes-backed pipeline storage" "Admission Webhook"

            apiServer = container "KFP API Server" "REST/gRPC API for pipeline CRUD operations, run management, and artifact access" "Go Service" {
                tags "ManagedComponent"
            }
            kubeRbacProxy = container "kube-rbac-proxy" "Authorization proxy enforcing SubjectAccessReview on DSPA api subresource" "Sidecar Container" {
                tags "SecurityComponent"
            }
            initManagedPipelines = container "init-managed-pipelines" "Extracts managed pipeline definitions from OCI images" "Init Container" {
                tags "ManagedComponent"
            }
            persistenceAgent = container "Persistence Agent" "Syncs pipeline run state from Argo Workflows to the KFP API server database" "Go Service" {
                tags "ManagedComponent"
            }
            scheduledWorkflow = container "Scheduled Workflow" "Manages cron-based pipeline run scheduling" "Go Service" {
                tags "ManagedComponent"
            }
            argoController = container "Argo Workflow Controller" "Orchestrates pipeline execution via Argo Workflows CRDs" "Go Controller" {
                tags "ManagedComponent"
            }
            mlmdEnvoyProxy = container "MLMD Envoy Proxy" "Routes and proxies gRPC traffic to MLMD server" "Envoy Proxy" {
                tags "ManagedComponent"
            }
            mlmdGrpcServer = container "MLMD gRPC Server" "Stores ML metadata (experiments, executions, artifacts) in MySQL" "Go gRPC Service" {
                tags "ManagedComponent"
            }
        }

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that creates DSPA CRs to deploy pipeline instances" {
            tags "InternalPlatform"
        }
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and pipelines" {
            tags "InternalPlatform"
        }
        kserve = softwareSystem "KServe" "Model serving platform for inference endpoints" {
            tags "InternalPlatform"
        }
        ray = softwareSystem "Ray" "Distributed compute framework for ML workloads" {
            tags "InternalPlatform"
        }
        codeflare = softwareSystem "CodeFlare" "Distributed computing workload manager" {
            tags "InternalPlatform"
        }
        mlflowOperator = softwareSystem "MLflow Operator" "Experiment tracking and model registry (optional)" {
            tags "InternalPlatform"
        }

        # External Dependencies
        mariaDB = softwareSystem "MariaDB / External MySQL" "Relational database for pipeline metadata and MLMD" {
            tags "External"
        }
        s3Storage = softwareSystem "S3 / MinIO Storage" "Object store for pipeline artifacts" {
            tags "External"
        }
        ociRegistry = softwareSystem "OCI Container Registry" "Hosts managed pipeline definition images" {
            tags "External"
        }
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Automatic TLS certificate generation for services" {
            tags "External"
        }
        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API for resource management" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "External"
        }

        # Relationships - Users
        dataScientist -> dspo "Creates and runs ML pipelines" "HTTPS/8443 via Route"
        platformAdmin -> rhodsOperator "Configures DSPA instances"
        rhodsOperator -> dspo "Creates DSPA CRs" "K8s API"
        odhDashboard -> dspo "Pipeline management UI" "HTTPS/8443"

        # Relationships - Internal containers
        controllerManager -> apiServer "Deploys and configures" "K8s API"
        controllerManager -> persistenceAgent "Deploys" "K8s API"
        controllerManager -> scheduledWorkflow "Deploys" "K8s API"
        controllerManager -> argoController "Deploys" "K8s API"
        controllerManager -> mlmdEnvoyProxy "Deploys" "K8s API"
        controllerManager -> mlmdGrpcServer "Deploys" "K8s API"

        kubeRbacProxy -> apiServer "Proxies authorized requests" "HTTP/8888"
        persistenceAgent -> apiServer "Syncs run state" "HTTP(S)/8888"
        scheduledWorkflow -> apiServer "Triggers scheduled runs" "HTTP(S)/8888"
        apiServer -> argoController "Creates Workflow CRs" "K8s API"
        mlmdEnvoyProxy -> mlmdGrpcServer "Routes gRPC traffic" "gRPC/8080 mTLS"

        # Relationships - External
        dspo -> mariaDB "Stores pipeline metadata and MLMD" "MySQL/3306 TLS"
        dspo -> s3Storage "Stores pipeline artifacts" "HTTP(S)/9000 or 443"
        controllerManager -> ociRegistry "Fetches managed pipeline manifests" "HTTPS/443"
        controllerManager -> k8sApiServer "Reconciles resources" "HTTPS/6443 mTLS"
        controllerManager -> openshiftServiceCA "Requests TLS certificates" "K8s API"
        dspo -> prometheus "Exposes metrics" "HTTP/8080 TLS"

        # Relationships - Integration points
        dspo -> kserve "Pipeline steps create InferenceServices" "K8s API"
        dspo -> ray "Pipeline steps create RayClusters/Jobs" "K8s API"
        dspo -> codeflare "Pipeline steps create AppWrappers" "K8s API"
        controllerManager -> mlflowOperator "Reads MLflow endpoint (optional)" "K8s API"
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
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "InternalPlatform" {
                background #7ed321
                color #ffffff
            }
            element "ManagedComponent" {
                background #50c878
                color #ffffff
            }
            element "SecurityComponent" {
                background #e8725c
                color #ffffff
            }
        }
    }
}

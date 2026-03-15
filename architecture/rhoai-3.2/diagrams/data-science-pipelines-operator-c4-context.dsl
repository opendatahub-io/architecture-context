workspace {
    model {
        user = person "Data Scientist" "Creates and executes ML pipelines for data preparation, model training, and validation"
        admin = person "Platform Admin" "Deploys and configures Data Science Pipelines infrastructure"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of namespace-scoped DSP stacks on OpenShift, providing ML workflow orchestration with KFP v1beta1/v2beta1 API and Argo Workflows execution" {
            controller = container "DSPO Controller" "Reconciles DataSciencePipelinesApplication CRs and manages DSP component deployments" "Go Operator" {
                tags "Operator"
            }
            apiServer = container "DS Pipelines API Server" "Kubeflow Pipelines REST/gRPC API for pipeline management and execution" "Go Service" {
                tags "API"
            }
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow execution status to KFP database" "Go Service" {
                tags "Background"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages cron-scheduled recurring pipeline runs" "Go Controller" {
                tags "Controller"
            }
            mlmdGrpc = container "MLMD gRPC" "ML Metadata service for tracking ML artifacts and lineage" "Python gRPC Service" {
                tags "Metadata"
            }
            mlmdEnvoy = container "MLMD Envoy Proxy" "Reverse proxy with mTLS termination for MLMD gRPC" "Envoy Proxy" {
                tags "Proxy"
            }
            argoController = container "Argo Workflow Controller" "Namespace-scoped workflow engine for executing pipeline tasks" "Go Controller" {
                tags "WorkflowEngine"
            }
            mariadb = container "MariaDB" "Stores pipeline metadata, runs, experiments, and ML metadata" "MariaDB 10.x" {
                tags "Database"
            }
            minio = container "Minio" "Stores pipeline artifacts and intermediate data" "Minio S3-compatible" {
                tags "ObjectStorage"
            }
        }

        openshift = softwareSystem "OpenShift / Kubernetes" "Container orchestration platform" "External" {
            tags "Platform"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine (deployed by DSPO)" "External" {
            tags "External"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing pipelines and visualizing results" "Internal ODH" {
            tags "InternalODH"
        }

        kserve = softwareSystem "KServe" "Model serving platform for deploying trained models" "Internal ODH" {
            tags "InternalODH"
        }

        ray = softwareSystem "Ray" "Distributed computing framework for training jobs" "Internal ODH" {
            tags "InternalODH"
        }

        codeflare = softwareSystem "Distributed Workloads (CodeFlare)" "AppWrapper-based distributed workload management" "Internal ODH" {
            tags "InternalODH"
        }

        externalDb = softwareSystem "External Database" "External MySQL/MariaDB for pipeline metadata (optional)" "External" {
            tags "ExternalService"
        }

        externalS3 = softwareSystem "External S3 Storage" "S3-compatible storage (ODF, AWS S3) for artifacts (optional)" "External" {
            tags "ExternalService"
        }

        certManager = softwareSystem "cert-manager / service-ca" "TLS certificate management" "External" {
            tags "External"
        }

        # User interactions
        user -> odhDashboard "Creates and monitors pipelines via UI"
        user -> apiServer "Submits pipelines via KFP SDK/CLI" "HTTPS/8443, gRPC/8887, Bearer Token"
        admin -> controller "Deploys DSP stack via DataSciencePipelinesApplication CR" "Kubernetes API"

        # Controller relationships
        controller -> openshift "Manages DSP resources (Deployments, Services, Routes, Secrets)" "Kubernetes API/6443, HTTPS, TLS 1.2+"
        controller -> apiServer "Deploys and configures" "Creates Deployment"
        controller -> persistenceAgent "Deploys and configures" "Creates Deployment"
        controller -> scheduledWorkflow "Deploys and configures" "Creates Deployment"
        controller -> mlmdGrpc "Deploys and configures" "Creates Deployment"
        controller -> mlmdEnvoy "Deploys and configures" "Creates Deployment"
        controller -> argoController "Deploys namespace-scoped controller" "Creates Deployment"
        controller -> mariadb "Provisions managed database (optional)" "Creates Deployment"
        controller -> minio "Provisions managed object storage (optional)" "Creates Deployment"

        # API Server relationships
        apiServer -> mariadb "Stores pipeline metadata, runs, experiments" "MySQL/3306, TLS 1.2+ optional, MySQL Auth"
        apiServer -> minio "Stores pipeline artifacts, generates pre-signed URLs" "HTTP/9000, S3 API, AWS SigV4"
        apiServer -> mlmdGrpc "Tracks ML artifacts and lineage" "gRPC/8080, mTLS optional"
        apiServer -> openshift "Creates Workflow CRs for pipeline runs" "Kubernetes API/6443, HTTPS, SA Token"
        apiServer -> externalDb "Uses external database for metadata (alternative)" "MySQL/3306, TLS 1.2+, MySQL Auth"
        apiServer -> externalS3 "Uses external S3 for artifacts (alternative)" "HTTPS/443, TLS 1.2+, AWS IAM/SigV4"

        # ODH Dashboard integration
        odhDashboard -> apiServer "Manages pipelines via KFP API" "HTTPS/8443, TLS 1.3, Bearer Token"

        # Workflow execution
        argoController -> openshift "Creates and monitors Workflow pods" "Kubernetes API/6443, HTTPS, SA Token"
        persistenceAgent -> openshift "Watches Workflow status" "Kubernetes API/6443, HTTPS, SA Token"
        persistenceAgent -> mariadb "Syncs workflow state to database" "MySQL/3306, TLS 1.2+ optional"
        scheduledWorkflow -> openshift "Creates scheduled Workflow CRs" "Kubernetes API/6443, HTTPS, SA Token"

        # Workflow pod integrations
        openshift -> minio "Workflow pods download/upload artifacts" "HTTP/9000, S3 API, AWS SigV4"
        openshift -> mlmdGrpc "Workflow pods log ML metadata" "gRPC/8080, mTLS optional"
        openshift -> apiServer "Workflow pods report task status" "gRPC/8887, TLS 1.3 optional, Bearer Token"
        openshift -> kserve "Workflow pods deploy models to KServe" "Kubernetes API, InferenceService CRD"
        openshift -> ray "Workflow pods execute distributed training" "Kubernetes API, RayCluster/RayJob CRD"
        openshift -> codeflare "Workflow pods submit as AppWrappers" "Kubernetes API, AppWrapper CRD"
        openshift -> externalS3 "Workflow pods access external artifacts" "HTTPS/443, TLS 1.2+, AWS IAM/SigV4"

        # MLMD
        mlmdGrpc -> mariadb "Persists ML metadata" "MySQL/3306, TLS 1.2+ optional"
        mlmdEnvoy -> mlmdGrpc "Proxies external access with mTLS" "gRPC/8080, mTLS"

        # Certificate management
        certManager -> apiServer "Provisions TLS certificates for kube-rbac-proxy" "service-ca / cert-manager"
        certManager -> mlmdGrpc "Provisions mTLS certificates" "service-ca / cert-manager"
        certManager -> mlmdEnvoy "Provisions Envoy proxy TLS certificates" "service-ca / cert-manager"
        certManager -> mariadb "Provisions MariaDB TLS certificates (optional)" "service-ca / cert-manager"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
            description "System context diagram for Data Science Pipelines Operator showing external dependencies and integrations"
        }

        container dspo "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of Data Science Pipelines Operator"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "InternalODH" {
                background #7ed321
                color #000000
            }
            element "ExternalService" {
                background #f5a623
                color #000000
            }
            element "Platform" {
                background #bd10e0
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "API" {
                background #50e3c2
                color #000000
                shape RoundedBox
            }
            element "Background" {
                background #f8e71c
                color #000000
                shape RoundedBox
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Metadata" {
                background #9013fe
                color #ffffff
                shape RoundedBox
            }
            element "Proxy" {
                background #b8e986
                color #000000
                shape RoundedBox
            }
            element "WorkflowEngine" {
                background #ff6d00
                color #ffffff
                shape RoundedBox
            }
            element "Database" {
                background #8b572a
                color #ffffff
                shape Cylinder
            }
            element "ObjectStorage" {
                background #417505
                color #ffffff
                shape Cylinder
            }
        }
    }
}

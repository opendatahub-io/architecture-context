workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages ML pipelines for data preparation, training, and experimentation"
        operator = person "Platform Operator" "Deploys and manages DSP instances via DSPA CRs"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines instances for ML workflow orchestration" {
            controller = container "DSPO Controller" "Reconciles DSPA CRs and manages all DSP components" "Go Operator" {
                tags "Operator"
            }
            apiserver = container "API Server" "REST/gRPC server for pipeline submission and run management" "Go Service" {
                tags "Application"
            }
            persistenceagent = container "Persistence Agent" "Syncs workflow execution status to database" "Go Service" {
                tags "Application"
            }
            scheduledworkflow = container "Scheduled Workflow Controller" "Manages scheduled/recurring pipeline runs" "Go Service" {
                tags "Application"
            }
            workflowcontroller = container "Workflow Controller" "Argo Workflows controller for v2 pipeline orchestration" "Argo v3.4.17" {
                tags "Application"
            }
            mariadb = container "MariaDB" "Metadata database for pipelines, runs, experiments" "StatefulSet" {
                tags "Database"
            }
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts (dev/test)" "Deployment" {
                tags "Storage"
            }
            mlmdgrpc = container "MLMD gRPC Server" "ML Metadata lineage and artifact tracking service" "Go Service" {
                tags "Application"
            }
            mlmdenvoy = container "MLMD Envoy Proxy" "OAuth2 proxy and load balancer for MLMD gRPC" "Envoy" {
                tags "Proxy"
            }
        }

        k8s = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External" {
            tags "External"
        }

        oauth = softwareSystem "OpenShift OAuth" "User authentication and authorization" "External" {
            tags "External"
        }

        s3 = softwareSystem "External S3 Storage" "Production pipeline artifact storage (AWS/Cloud)" "External" {
            tags "External"
        }

        externaldb = softwareSystem "External MySQL/PostgreSQL" "Production pipeline metadata storage" "External" {
            tags "External"
        }

        registry = softwareSystem "Container Registry" "Container images for pipeline tasks" "External" {
            tags "External"
        }

        tekton = softwareSystem "OpenShift Pipelines (Tekton)" "Workflow execution backend for DSP v1 (deprecated)" "External" {
            tags "External"
        }

        odhdashboard = softwareSystem "ODH Dashboard" "Web UI for managing DSP instances and viewing pipelines" "Internal ODH" {
            tags "Internal ODH"
        }

        dsc = softwareSystem "DataScienceCluster" "Manages DSPO installation via ODH operator" "Internal ODH" {
            tags "Internal ODH"
        }

        servicemesh = softwareSystem "Service Mesh (Istio)" "mTLS for pod-to-pod encryption" "Internal ODH" {
            tags "Internal ODH"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH" {
            tags "Internal ODH"
        }

        %% User interactions
        datascientist -> apiserver "Creates and manages pipelines via KFP SDK/UI" "HTTPS/8443, OAuth2"
        datascientist -> mlmdenvoy "Queries ML metadata and lineage" "gRPC/HTTPS, OAuth2"
        operator -> controller "Creates DSPA CRs to deploy pipeline instances" "kubectl/oc"

        %% Controller relationships
        controller -> k8s "Creates and manages pipeline components (Deployments, Services, Routes)" "HTTPS/6443, SA Token"
        controller -> apiserver "Deploys and manages" "Reconciliation"
        controller -> persistenceagent "Deploys and manages" "Reconciliation"
        controller -> scheduledworkflow "Deploys and manages" "Reconciliation"
        controller -> workflowcontroller "Deploys and manages" "Reconciliation"
        controller -> mariadb "Deploys and manages" "Reconciliation"
        controller -> minio "Deploys and manages" "Reconciliation"
        controller -> mlmdgrpc "Deploys and manages" "Reconciliation"
        controller -> mlmdenvoy "Deploys and manages" "Reconciliation"

        %% API Server relationships
        apiserver -> mariadb "Stores pipeline metadata" "MySQL/3306, TLS or None"
        apiserver -> minio "Stores pipeline artifacts (dev/test)" "HTTP/9000, S3 API"
        apiserver -> s3 "Stores pipeline artifacts (production)" "HTTPS/443, AWS IAM"
        apiserver -> externaldb "Stores pipeline metadata (production)" "MySQL/3306 or PostgreSQL/5432"
        apiserver -> oauth "Validates user tokens" "HTTPS/443"
        apiserver -> workflowcontroller "Creates workflow CRs for pipeline runs" "HTTP/8080"

        %% Workflow Controller relationships
        workflowcontroller -> k8s "Creates and manages workflow pods" "HTTPS/6443, SA Token"

        %% Workflow pod relationships (implicit via K8s)
        workflowcontroller -> mlmdgrpc "Logs metadata and lineage from workflow pods" "gRPC/8080"
        workflowcontroller -> minio "Reads/writes artifacts from workflow pods" "HTTP/9000, S3 API"
        workflowcontroller -> s3 "Reads/writes artifacts from workflow pods (production)" "HTTPS/443, AWS IAM"
        workflowcontroller -> registry "Pulls container images for pipeline tasks" "HTTPS/443"

        %% Persistence Agent relationships
        persistenceagent -> k8s "Watches workflow execution status" "HTTPS/6443, SA Token"
        persistenceagent -> mariadb "Syncs workflow state to database" "MySQL/3306"

        %% Scheduled Workflow relationships
        scheduledworkflow -> k8s "Creates scheduled workflow CRs" "HTTPS/6443, SA Token"

        %% MLMD relationships
        mlmdenvoy -> mlmdgrpc "Proxies gRPC requests with OAuth2" "gRPC/8080"
        mlmdenvoy -> oauth "Validates user tokens" "HTTPS/443"
        mlmdgrpc -> mariadb "Stores ML metadata and lineage" "MySQL/3306"

        %% ODH/RHOAI Integration
        odhdashboard -> apiserver "Embeds pipeline UI, manages DSPA lifecycle" "HTTPS/8443"
        odhdashboard -> k8s "Creates/updates DSPA CRs" "HTTPS/6443"
        dsc -> controller "Installs DSPO via ODH operator" "CRD Management"
        servicemesh -> apiserver "Provides mTLS for pod-to-pod encryption" "mTLS"
        prometheus -> controller "Scrapes operator metrics" "HTTP/8080"
        prometheus -> apiserver "Scrapes component metrics" "HTTP Metrics"

        %% External dependencies (v1 only)
        apiserver -> tekton "Uses Tekton for v1 pipeline execution (deprecated)" "Kubernetes API"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Application" {
                background #5bc0de
                color #ffffff
            }
            element "Database" {
                background #d9534f
                color #ffffff
            }
            element "Storage" {
                background #f0ad4e
                color #000000
            }
            element "Proxy" {
                background #5cb85c
                color #ffffff
            }
        }
    }
}

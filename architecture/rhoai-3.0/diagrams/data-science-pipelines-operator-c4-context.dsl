workspace {
    model {
        datascientist = person "Data Scientist" "Creates and executes ML workflows for data preparation, training, and model deployment"
        platformadmin = person "Platform Administrator" "Deploys and manages Data Science Pipeline instances"

        dspo = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator that manages lifecycle of Data Science Pipeline (DSP) instances based on Kubeflow Pipelines 2.x. Provides ML workflow orchestration, experiment tracking, and artifact lineage." {
            controller = container "DSPO Controller" "Reconciles DataSciencePipelinesApplication CRs and deploys pipeline infrastructure" "Go Operator" {
                tags "Operator"
            }

            apiserver = container "DSP API Server" "Provides KFP v2 REST/gRPC API for pipeline management, runs, and artifacts" "Go Service" {
                tags "API"
            }

            persistenceagent = container "Persistence Agent" "Syncs workflow execution state from Argo to database for pipeline run persistence" "Go Service" {
                tags "Agent"
            }

            scheduledworkflow = container "Scheduled Workflow Controller" "Manages cron-scheduled and recurring pipeline runs" "Go Service" {
                tags "Controller"
            }

            workflowcontroller = container "Argo Workflow Controller" "Namespace-scoped Argo Workflows controller for pipeline execution orchestration" "Go Controller" {
                tags "Controller"
            }

            mariadb = container "MariaDB" "Stores pipeline metadata, runs, experiments, and ML artifact lineage" "MariaDB 10.3" {
                tags "Database" "Optional"
            }

            minio = container "Minio" "S3-compatible object storage for pipeline artifacts (dev/test only)" "Minio" {
                tags "Storage" "Optional"
            }

            mlmdgrpc = container "ML Metadata gRPC" "Tracks artifact lineage and metadata using gRPC service" "Go Service" {
                tags "Metadata" "Optional"
            }
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External" {
            tags "External"
        }

        argoworkflows = softwareSystem "Argo Workflows" "Workflow execution engine deployed by DSPO" "External" {
            tags "External"
        }

        s3storage = softwareSystem "S3-compatible Storage" "External object storage for pipeline artifacts (AWS S3, Ceph, etc.)" "External" {
            tags "External"
        }

        externaldb = softwareSystem "External Database" "External MySQL/PostgreSQL for pipeline metadata (production)" "External" {
            tags "External" "Optional"
        }

        odhdashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science resources" "Internal ODH" {
            tags "Internal ODH"
        }

        workbenches = softwareSystem "Workbenches (Notebooks)" "JupyterLab/VSCode environments for data science work" "Internal ODH" {
            tags "Internal ODH"
        }

        kserve = softwareSystem "KServe" "Model serving platform for inference deployments" "Internal ODH" {
            tags "Internal ODH"
        }

        rayclusters = softwareSystem "Ray Clusters" "Distributed compute framework for scalable ML workloads" "Internal ODH" {
            tags "Internal ODH"
        }

        servicemesh = softwareSystem "Service Mesh (Istio)" "Service mesh for mTLS, traffic management, and observability" "Internal ODH" {
            tags "Internal ODH" "Optional"
        }

        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus/Grafana for metrics and alerting" "Internal ODH" {
            tags "Internal ODH"
        }

        # Relationships - User interactions
        datascientist -> odhdashboard "Creates and monitors ML pipelines via web UI"
        datascientist -> workbenches "Authors pipeline definitions using KFP SDK"
        platformadmin -> kubernetes "Deploys DataSciencePipelinesApplication CR"

        # Relationships - DSPO internal
        controller -> kubernetes "Watches DSPA CRs, creates/manages pipeline infrastructure" "HTTPS/6443 (SA Token)"
        controller -> apiserver "Deploys and configures"
        controller -> persistenceagent "Deploys and configures"
        controller -> scheduledworkflow "Deploys and configures"
        controller -> workflowcontroller "Deploys namespace-scoped controller"
        controller -> mariadb "Optionally deploys (dev/test)"
        controller -> minio "Optionally deploys (dev/test)"
        controller -> mlmdgrpc "Optionally deploys"

        apiserver -> mariadb "Stores pipeline metadata, runs, experiments" "MySQL/3306 (TLS, DB Password)"
        apiserver -> workflowcontroller "Creates Argo Workflow CRs for pipeline execution" "HTTP/8001 (TLS, SA Token)"
        apiserver -> mlmdgrpc "Queries artifact lineage" "gRPC/8080 (TLS, mTLS)"

        persistenceagent -> apiserver "Queries workflow status" "gRPC/8887 (TLS, SA Token)"
        persistenceagent -> mariadb "Syncs pipeline run state" "MySQL/3306 (TLS, DB Password)"

        scheduledworkflow -> apiserver "Creates scheduled pipeline runs" "gRPC/8887 (TLS, SA Token)"

        workflowcontroller -> kubernetes "Creates pipeline execution pods" "HTTPS/6443 (TLS 1.2+, SA Token)"

        mlmdgrpc -> mariadb "Stores artifact lineage metadata" "MySQL/3306 (TLS, DB Password)"

        # Relationships - External dependencies
        dspo -> kubernetes "Uses for container orchestration" "HTTPS/6443"
        dspo -> argoworkflows "Uses for workflow execution (deployed by operator)" "N/A"
        apiserver -> s3storage "Stores/retrieves pipeline artifacts" "HTTPS/443 (TLS 1.2+, S3 Credentials)"
        apiserver -> externaldb "Alternative to embedded MariaDB (production)" "MySQL/PostgreSQL (TLS 1.2+, DB Credentials)"

        # Relationships - Internal ODH integrations
        odhdashboard -> apiserver "Provides UI for pipeline management" "HTTPS/443 via Route (OAuth Token)"
        workbenches -> apiserver "Submits pipelines from notebooks" "HTTP/8888 (TLS pod-to-pod, SA Token)"
        apiserver -> kserve "Deploys inference services from pipelines" "HTTP/HTTPS (TLS 1.2+)"
        apiserver -> rayclusters "Launches distributed compute tasks" "HTTP/8265 (TLS 1.2+)"
        dspo -> servicemesh "Optional: Uses for mTLS and traffic management" "N/A"
        dspo -> monitoring "Exposes metrics via ServiceMonitors" "HTTP/8080, HTTP/9090"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for Data Science Pipelines Operator showing external users, systems, and integration points"
        }

        container dspo "Containers" {
            include *
            autoLayout tb
            description "Container diagram showing internal components of Data Science Pipelines Operator"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                opacity 70
            }
            element "Operator" {
                shape hexagon
            }
            element "API" {
                shape roundedbox
            }
            element "Agent" {
                shape circle
            }
            element "Controller" {
                shape component
            }
            element "Database" {
                shape cylinder
            }
            element "Storage" {
                shape folder
            }
            element "Metadata" {
                shape pipe
            }
        }

        theme default
    }
}

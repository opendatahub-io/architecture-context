workspace {
    model {
        datascientist = person "Data Scientist" "Creates and executes ML workflows and pipelines"
        developer = person "Pipeline Developer" "Develops and tests pipeline components"

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages ML workflow orchestration infrastructure on OpenShift" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and deploys pipeline infrastructure" "Go Operator" {
                tags "Operator"
            }

            apiserver = container "DS Pipelines API Server" "REST/gRPC API for pipeline management, run submission, and artifact tracking" "Python/Go" {
                tags "API"
            }

            persistenceagent = container "Persistence Agent" "Synchronizes workflow execution state to metadata database" "Go" {
                tags "Agent"
            }

            scheduledworkflow = container "Scheduled Workflow Controller" "Manages cron-based pipeline execution schedules" "Go" {
                tags "Controller"
            }

            ui = container "ML Pipelines UI" "Web interface for pipeline visualization and management" "React/TypeScript" {
                tags "UI"
            }

            mlmd = container "ML Metadata gRPC" "Tracks ML artifacts, lineage, and metadata" "Python/gRPC" {
                tags "Optional"
            }

            mlmdenvoy = container "MLMD Envoy Proxy" "Proxy for ML Metadata gRPC service" "Envoy" {
                tags "Optional"
            }

            mariadb = container "MariaDB" "Metadata persistence for pipelines, runs, and experiments" "MariaDB 10.3+" {
                tags "Optional" "Database"
            }

            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Minio" {
                tags "Optional" "Storage"
            }
        }

        argoworkflows = softwareSystem "Argo Workflows" "Workflow execution engine for DSP v2" "External" {
            tags "External"
        }

        openshift = softwareSystem "OpenShift/Kubernetes" "Container orchestration platform" "External" {
            tags "External"
        }

        oauth = softwareSystem "OpenShift OAuth" "Authentication and authorization service" "External" {
            tags "External"
        }

        odhdashboard = softwareSystem "ODH Dashboard" "OpenShift AI web console for data science tools" "Internal ODH" {
            tags "Internal ODH"
        }

        odhoperator = softwareSystem "opendatahub-operator" "Manages ODH/RHOAI platform components" "Internal ODH" {
            tags "Internal ODH"
        }

        externals3 = softwareSystem "External S3 Storage" "AWS S3 or S3-compatible object storage for production artifacts" "External" {
            tags "External"
        }

        externaldb = softwareSystem "External MySQL/MariaDB" "External database for production metadata storage" "External" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "External"
        }

        registry = softwareSystem "Container Registry" "Stores pipeline component container images" "External" {
            tags "External"
        }

        # User interactions
        datascientist -> ui "Views pipeline runs and artifacts via web UI" "HTTPS/8443, OAuth"
        datascientist -> apiserver "Submits pipelines and creates runs via API" "HTTPS/8443, OAuth"
        developer -> apiserver "Tests and deploys pipeline components" "HTTPS/8443, OAuth"
        datascientist -> odhdashboard "Navigates to pipeline UI" "HTTPS"

        # Controller orchestration
        controller -> openshift "Watches DataSciencePipelinesApplication CRs" "Kubernetes API"
        controller -> apiserver "Deploys and manages" "Kubernetes API"
        controller -> persistenceagent "Deploys and manages" "Kubernetes API"
        controller -> scheduledworkflow "Deploys and manages" "Kubernetes API"
        controller -> ui "Deploys and manages (optional)" "Kubernetes API"
        controller -> mlmd "Deploys and manages (optional)" "Kubernetes API"
        controller -> mlmdenvoy "Deploys and manages (optional)" "Kubernetes API"
        controller -> mariadb "Deploys and manages (optional)" "Kubernetes API"
        controller -> minio "Deploys and manages (optional)" "Kubernetes API"
        controller -> oauth "Configures OAuth proxies for routes" "OpenShift API"

        # API Server interactions
        apiserver -> mariadb "Stores pipeline metadata" "TCP/3306, MySQL Auth"
        apiserver -> externaldb "Stores pipeline metadata (production)" "TCP/3306, MySQL Auth, TLS"
        apiserver -> minio "Stores pipeline artifacts" "HTTP/9000, S3 API"
        apiserver -> externals3 "Stores pipeline artifacts (production)" "HTTPS/443, AWS Signature v4"
        apiserver -> argoworkflows "Submits workflow executions" "HTTP/8001, K8s API"
        apiserver -> mlmdenvoy "Queries artifact lineage" "gRPC/9090"
        apiserver -> oauth "Validates OAuth tokens" "HTTPS"

        # Workflow execution
        scheduledworkflow -> apiserver "Triggers scheduled pipeline runs" "HTTP/8888, Bearer Token"
        argoworkflows -> openshift "Creates workflow pods" "Kubernetes API"
        argoworkflows -> minio "Reads/writes artifacts" "HTTP/9000, S3 API"
        argoworkflows -> externals3 "Reads/writes artifacts (production)" "HTTPS/443, AWS Signature v4"
        argoworkflows -> mlmd "Tracks execution metadata" "gRPC/8080"

        # Persistence and metadata
        persistenceagent -> mariadb "Syncs workflow state" "TCP/3306, MySQL Auth"
        persistenceagent -> externaldb "Syncs workflow state (production)" "TCP/3306, MySQL Auth"
        mlmd -> mariadb "Stores artifact metadata" "TCP/3306, MySQL Auth"
        mlmd -> externaldb "Stores artifact metadata (production)" "TCP/3306, MySQL Auth"
        mlmdenvoy -> mlmd "Proxies gRPC requests" "gRPC/8080"

        # UI interactions
        ui -> apiserver "Fetches pipeline data" "HTTP/8888, Bearer Token"
        ui -> minio "Downloads artifacts for display" "HTTP/80, S3 API"
        ui -> mlmdenvoy "Displays artifact lineage" "gRPC/9090"

        # ODH integration
        odhoperator -> controller "Deploys when datasciencepipelines component enabled" "Kubernetes API"
        odhdashboard -> apiserver "Lists DSPAs and runs" "Kubernetes API"
        odhdashboard -> ui "Provides navigation links" "HTTPS"

        # Monitoring and infrastructure
        prometheus -> controller "Scrapes operator metrics" "HTTP/8080"
        prometheus -> apiserver "Scrapes component metrics" "HTTP/8888"
        openshift -> registry "Pulls component images" "HTTPS/443"
        controller -> registry "Pulls component images" "HTTPS/443"
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
                background #1168bd
                color #ffffff
            }

            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }

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

            element "API" {
                background #f5a623
                color #000000
            }

            element "Controller" {
                background #bd10e0
                color #ffffff
            }

            element "Agent" {
                background #b8e986
                color #000000
            }

            element "UI" {
                background #50e3c2
                color #000000
            }

            element "Optional" {
                background #e8e8e8
                color #000000
            }

            element "Database" {
                shape cylinder
            }

            element "Storage" {
                shape cylinder
            }
        }
    }
}

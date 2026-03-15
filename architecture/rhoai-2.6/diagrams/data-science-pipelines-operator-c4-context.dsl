workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages ML pipeline workflows"

        dspo = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator that deploys and manages namespace-scoped Data Science Pipelines (DSP) application stacks on OpenShift" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and manages lifecycle" "Go Operator" {
                tags "Operator"
            }

            apiserver = container "DSP API Server" "KFP API server for pipeline CRUD, run management, and artifact tracking" "Go Service" {
                tags "Core Component"
            }

            persistenceagent = container "Persistence Agent" "Syncs Tekton PipelineRun status to DSP database" "Go Controller" {
                tags "Core Component"
            }

            scheduledworkflow = container "Scheduled Workflow Controller" "Manages cron-based pipeline execution schedules" "Go Controller" {
                tags "Core Component"
            }

            oauthproxy = container "OAuth Proxy" "OpenShift OAuth proxy securing API endpoints" "Sidecar Container" {
                tags "Security"
            }

            mariadb = container "MariaDB" "Pipeline metadata storage (optional/default)" "Database" {
                tags "Optional Storage"
            }

            minio = container "Minio" "S3-compatible artifact storage (optional/dev-test)" "Object Storage" {
                tags "Optional Storage"
            }

            mlpipelineui = container "ML Pipelines UI" "Upstream KFP UI for pipeline visualization (unsupported)" "Web Frontend" {
                tags "Optional UI"
            }

            mlmdgrpc = container "MLMD gRPC Server" "ML Metadata server for artifact lineage tracking" "gRPC Service" {
                tags "Optional MLMD"
            }

            mlmdenvoy = container "MLMD Envoy Proxy" "Envoy proxy for external MLMD access" "Proxy" {
                tags "Optional MLMD"
            }

            mlmdwriter = container "MLMD Writer" "Writes pipeline execution metadata to MLMD" "Go Controller" {
                tags "Optional MLMD"
            }
        }

        # External Dependencies
        tekton = softwareSystem "OpenShift Pipelines (Tekton)" "Pipeline execution engine - Tekton PipelineRuns backend for KFP workflows" "External Dependency"
        openshift = softwareSystem "OpenShift" "Kubernetes platform with Routes, OAuth, Service CA injection" "External Platform"
        odhdashboard = softwareSystem "ODH Dashboard" "Web interface for data scientists to interact with ODH components" "Internal ODH"
        notebookcontroller = softwareSystem "Notebook Controller" "Manages Jupyter notebooks for data science workloads" "Internal ODH"
        modelregistry = softwareSystem "Model Registry" "Tracks model metadata and lineage" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"

        # External Services (Optional)
        externaldb = softwareSystem "External Database" "MySQL/PostgreSQL database for pipeline metadata" "External Service"
        externals3 = softwareSystem "External S3 Storage" "AWS S3 or compatible object storage for artifacts" "External Service"

        # User interactions
        datascientist -> dspo "Creates DataSciencePipelinesApplication CR, submits pipelines via API/UI"
        datascientist -> odhdashboard "Views pipeline UI, explores artifact lineage"
        datascientist -> notebookcontroller "Submits pipelines from notebooks via kfp-tekton SDK"

        # DSPO internal relationships
        controller -> apiserver "Creates and manages"
        controller -> persistenceagent "Creates and manages"
        controller -> scheduledworkflow "Creates and manages"
        controller -> mariadb "Deploys (optional)"
        controller -> minio "Deploys (optional)"
        controller -> mlpipelineui "Deploys (optional)"
        controller -> mlmdgrpc "Deploys (optional)"
        controller -> mlmdenvoy "Deploys (optional)"
        controller -> mlmdwriter "Deploys (optional)"

        oauthproxy -> apiserver "Secures with OAuth authentication"
        apiserver -> mariadb "Stores pipeline definitions, runs, experiments" "MySQL/3306"
        apiserver -> minio "Stores pipeline artifacts and data" "S3 API/9000"
        apiserver -> tekton "Creates and manages PipelineRuns" "Kubernetes API/443 HTTPS"

        persistenceagent -> tekton "Watches PipelineRun status" "Kubernetes API/443 HTTPS"
        persistenceagent -> apiserver "Updates run status" "HTTP/8888"
        persistenceagent -> mariadb "Syncs metadata" "MySQL/3306"

        scheduledworkflow -> tekton "Creates scheduled PipelineRuns" "Kubernetes API/443 HTTPS"
        scheduledworkflow -> apiserver "Triggers scheduled runs" "HTTP/8888"

        mlmdwriter -> mlmdgrpc "Writes execution metadata" "gRPC/8080"
        mlmdwriter -> tekton "Watches PipelineRuns for lineage" "Kubernetes API/443 HTTPS"
        mlmdenvoy -> mlmdgrpc "Proxies gRPC requests" "gRPC/8080"
        mlmdgrpc -> mariadb "Stores artifact lineage" "MySQL/3306"

        # External integrations
        controller -> openshift "Depends on Routes, OAuth, Service CA" "Kubernetes API"
        odhdashboard -> mlpipelineui "Embeds pipeline UI" "HTTPS/8443"
        odhdashboard -> mlmdenvoy "Queries artifact lineage" "gRPC/9090"
        notebookcontroller -> apiserver "Submits pipelines from notebooks" "HTTPS/8443 OAuth"
        modelregistry -> mlmdgrpc "Tracks model lineage" "gRPC/9090"
        prometheus -> controller "Scrapes operator metrics" "HTTP/8080"
        prometheus -> apiserver "Scrapes component metrics" "HTTP/8888"

        # Optional external services
        apiserver -> externaldb "Stores metadata (alternative to MariaDB)" "MySQL/PostgreSQL 3306/5432"
        apiserver -> externals3 "Stores artifacts (alternative to Minio)" "HTTPS/443"

        # Deployment environment
        deploymentEnvironment "OpenShift Cluster" {
            deploymentNode "Operator Namespace" {
                containerInstance controller
            }

            deploymentNode "User Namespace" {
                deploymentNode "API Server Pod" {
                    containerInstance apiserver
                    containerInstance oauthproxy
                }

                deploymentNode "Persistence Agent Pod" {
                    containerInstance persistenceagent
                }

                deploymentNode "Scheduled Workflow Pod" {
                    containerInstance scheduledworkflow
                }

                deploymentNode "MariaDB Pod (Optional)" {
                    containerInstance mariadb
                }

                deploymentNode "Minio Pod (Optional)" {
                    containerInstance minio
                }

                deploymentNode "MLMD Pods (Optional)" {
                    containerInstance mlmdgrpc
                    containerInstance mlmdenvoy
                    containerInstance mlmdwriter
                }

                deploymentNode "UI Pod (Optional)" {
                    containerInstance mlpipelineui
                }
            }
        }
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

        deployment dspo "OpenShift Cluster" "Deployment" {
            include *
            autoLayout
            description "Deployment architecture of DSPO in OpenShift cluster"
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
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Platform" {
                background #666666
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Monitoring" {
                background #e8743b
                color #ffffff
            }
            element "External Service" {
                background #cccccc
                color #000000
                shape Cylinder
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Core Component" {
                background #50b5e9
                color #ffffff
            }
            element "Security" {
                background #f5a623
                color #000000
            }
            element "Optional Storage" {
                background #d0e0e3
                color #000000
                shape Cylinder
            }
            element "Optional UI" {
                background #e1bee7
                color #000000
            }
            element "Optional MLMD" {
                background #ffecb3
                color #000000
            }
        }
    }
}

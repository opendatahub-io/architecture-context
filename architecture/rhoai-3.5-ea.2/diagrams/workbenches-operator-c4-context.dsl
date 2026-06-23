workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures RHOAI platform components via the orchestrator"
        dataSciUser = person "Data Scientist" "Uses workbenches (Kubeflow Notebooks) for ML development"

        workbenchesOperator = softwareSystem "workbenches-operator" "Kubernetes operator managing the lifecycle of the Workbenches component (Kubeflow Notebook infrastructure) for RHOAI" {
            controller = container "Workbenches Controller" "Reconciles Workbenches CR, manages workbench namespace, monitors deployment health" "Go (controller-runtime)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with SubjectAccessReview authentication" "HTTPS 8443/TCP"
            healthProbes = container "Health Probes" "Liveness and readiness probe endpoints" "HTTP 8081/TCP"
        }

        orchestrator = softwareSystem "Platform Orchestrator (rhods-operator)" "Creates Workbenches CR and projects platform configuration" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "Infrastructure"
        notebookController = softwareSystem "Kubeflow Notebook Controller" "Manages workbench (notebook) pods in the workbench namespace" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"

        # Future integrations (not yet active)
        hardwareProfiles = softwareSystem "HardwareProfile Controller" "Manages GPU/accelerator allocation profiles" "Internal RHOAI (future)"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Manages notebook container images" "Infrastructure (future)"

        # Relationships
        platformAdmin -> orchestrator "Configures workbenches component"
        orchestrator -> k8sAPI "Creates/updates Workbenches CR" "HTTPS/443, TLS 1.2+, SA Token"
        k8sAPI -> workbenchesOperator "Watch events for Workbenches CR changes"

        workbenchesOperator -> k8sAPI "CRUD: namespaces, deployments, Workbenches status, SubjectAccessReviews" "HTTPS/443, TLS 1.2+, SA Token"
        workbenchesOperator -> notebookController "Monitors deployment readiness via label selector" "K8s API (LIST)"

        prometheus -> workbenchesOperator "Scrapes metrics" "HTTPS/8443, Bearer Token (SAR)"

        dataSciUser -> notebookController "Uses workbenches for ML development" "via RHOAI Dashboard"

        # Future
        workbenchesOperator -> hardwareProfiles "Will manage GPU allocation (future)" "" "future"
        workbenchesOperator -> imageStreams "Will manage notebook images (future)" "" "future"
    }

    views {
        systemContext workbenchesOperator "SystemContext" {
            include *
            autoLayout
            description "System context for workbenches-operator showing its role in the RHOAI decomposed operator architecture"
        }

        container workbenchesOperator "Containers" {
            include *
            autoLayout
            description "Internal structure of the workbenches-operator"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Infrastructure" {
                background #999999
            }
            element "Internal RHOAI (future)" {
                background #cccccc
                color #666666
                border dashed
            }
            element "Infrastructure (future)" {
                background #cccccc
                color #666666
                border dashed
            }
        }
    }
}

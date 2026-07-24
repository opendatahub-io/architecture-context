workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration via DSC/DSCI resources"
        dataScienceUser = person "Data Scientist" "Uses Jupyter notebook workbenches for ML development"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Manages lifecycle of workbench (notebook) infrastructure for RHOAI platform" {
            controller = container "Workbenches Controller" "Reconciles Workbenches CR, manages namespace lifecycle, monitors deployment health, computes kustomize parameters" "Go (controller-runtime v0.23.3)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with SubjectAccessReview auth" "HTTPS 8443/TCP"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints" "HTTP 8081/TCP"
        }

        platformOrchestrator = softwareSystem "Platform Orchestrator" "Central operator (rhods-operator) managing all RHOAI component operators" "Internal RHOAI" {
            tags "Internal"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "External" {
            tags "External"
        }

        notebookControllers = softwareSystem "Notebook Controller Deployments" "Deployments labeled app.opendatahub.io/workbenches=true managing notebook pods" "Internal RHOAI" {
            tags "Internal"
        }

        kubeflowNotebook = softwareSystem "Kubeflow Notebook CRD" "kubeflow.org/v1 Notebook custom resource for workbench instances" "External" {
            tags "Future"
        }

        openshiftImageStream = softwareSystem "OpenShift ImageStream" "image.openshift.io/v1 ImageStream for workbench container images" "External" {
            tags "Future"
        }

        hardwareProfile = softwareSystem "HardwareProfile CRD" "infrastructure.platform.opendatahub.io/v1 HardwareProfile for GPU/accelerator selection" "Internal RHOAI" {
            tags "Future"
        }

        prometheus = softwareSystem "Prometheus" "Monitoring and alerting system" "External" {
            tags "External"
        }

        # Relationships
        platformAdmin -> platformOrchestrator "Configures RHOAI platform via DSC/DSCI"
        platformOrchestrator -> workbenchesOperator "Creates/updates Workbenches CR with projected config" "K8s API / HTTPS 443"
        workbenchesOperator -> kubernetesAPI "CRUD on CRs, Namespaces, Deployments; leader election; SubjectAccessReview" "HTTPS/443 TLS 1.2+"
        workbenchesOperator -> notebookControllers "Monitors deployment health via label selector" "K8s API"
        prometheus -> workbenchesOperator "Scrapes metrics" "HTTPS/8443 SubjectAccessReview"

        # Future integrations (planned)
        workbenchesOperator -> kubeflowNotebook "Planned: manage notebook instances" "K8s API"
        workbenchesOperator -> openshiftImageStream "Planned: manage workbench images" "K8s API"
        workbenchesOperator -> hardwareProfile "Planned: GPU/accelerator profiles" "K8s API"

        dataScienceUser -> notebookControllers "Uses notebook workbenches"
    }

    views {
        systemContext workbenchesOperator "SystemContext" {
            include *
            autoLayout
        }

        container workbenchesOperator "Containers" {
            include *
            autoLayout
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Future" {
                background #cccccc
                color #666666
                border dashed
            }
        }
    }
}

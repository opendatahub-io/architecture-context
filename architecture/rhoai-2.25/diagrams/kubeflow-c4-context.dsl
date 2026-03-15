workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML experimentation"
        admin = person "Platform Administrator" "Manages notebook controller configuration and policies"

        notebookController = softwareSystem "Kubeflow Notebook Controller" "Manages lifecycle of Jupyter notebook instances in Kubernetes as custom resources" {
            controller = container "Notebook Reconciler" "Reconciles Notebook CRDs to create/update StatefulSets and Services" "Go Operator" {
                reconcilerLogic = component "Reconciliation Logic" "Watches Notebook CRs and creates/updates resources" "Go"
                statusUpdater = component "Status Updater" "Updates Notebook CR status with ready replicas" "Go"
                virtualServiceMgr = component "VirtualService Manager" "Creates Istio VirtualServices when USE_ISTIO=true" "Go"
            }

            cullingController = container "Culling Reconciler" "Monitors notebook kernel activity and stops idle notebooks" "Go Controller" {
                idleChecker = component "Idle Checker" "Queries /api/kernels endpoint for activity" "Go"
                annotationManager = component "Annotation Manager" "Adds kubeflow-resource-stopped annotation" "Go"
            }

            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for notebook operations" "HTTP Service" {
                tags "Monitoring"
            }

            healthProbe = container "Health Probe" "Provides liveness and readiness health checks" "HTTP Service" {
                tags "Health"
            }
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Platform API for creating and managing cluster resources" "External" {
            tags "External"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and VirtualService routing" "External" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External" {
            tags "External"
        }

        dashboard = softwareSystem "Kubeflow Dashboard" "Web UI for managing notebooks and other Kubeflow resources" "Internal ODH" {
            tags "Internal"
        }

        notebookPods = softwareSystem "Jupyter Notebook Pods" "Running Jupyter notebook instances with kernels" "Managed Workload" {
            tags "Managed"
        }

        # Relationships
        dataScientist -> dashboard "Creates and manages notebooks via web UI"
        dataScientist -> kubernetes "Creates Notebook CRs via kubectl/API"
        admin -> notebookController "Configures controller settings (USE_ISTIO, ENABLE_CULLING)"

        dashboard -> kubernetes "Creates Notebook CRs" "kubectl/REST API"
        dashboard -> notebookController "Displays notebook instances"

        controller -> kubernetes "Watches Notebook CRDs, creates StatefulSets/Services/VirtualServices" "REST API/6443 HTTPS TLS1.2+"
        cullingController -> notebookPods "Queries /api/kernels for kernel activity" "HTTP/8888"
        cullingController -> kubernetes "Updates Notebook CR annotations" "REST API/6443 HTTPS TLS1.2+"

        virtualServiceMgr -> istio "Creates VirtualService resources" "Kubernetes CRD API"

        prometheus -> metricsServer "Scrapes notebook metrics" "HTTP/8080"
        kubernetes -> healthProbe "Health checks" "HTTP/8081"

        kubernetes -> notebookPods "Creates and manages pods via Kubelet" "HTTPS/10250 mTLS"

        notebookPods -> dataScientist "Provides Jupyter notebook interface" "HTTP/8888 via Istio or port-forward"
    }

    views {
        systemContext notebookController "SystemContext" {
            include *
            autoLayout
            description "System context diagram for Kubeflow Notebook Controller showing external dependencies and users"
        }

        container notebookController "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of the Notebook Controller"
        }

        component controller "NotebookReconcilerComponents" {
            include *
            autoLayout
            description "Component diagram for Notebook Reconciler showing internal logic"
        }

        component cullingController "CullingReconcilerComponents" {
            include *
            autoLayout
            description "Component diagram for Culling Reconciler showing idle detection logic"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Managed" {
                background #4a90e2
                color #ffffff
            }
            element "Monitoring" {
                background #f5a623
                color #ffffff
            }
            element "Health" {
                background #50e3c2
                color #000000
            }
        }

        theme default
    }
}

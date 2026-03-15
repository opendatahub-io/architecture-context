workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML/data science work"

        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter Notebook lifecycle as StatefulSets in Kubernetes via custom resources" {
            notebookReconciler = container "NotebookReconciler" "Main reconciliation loop for Notebook CRs" "Go Controller" {
                tags "Controller"
            }
            cullingReconciler = container "CullingReconciler" "Monitors and culls idle notebooks" "Go Controller" {
                tags "Controller" "Optional"
            }
            metricsExporter = container "Metrics Exporter" "Exposes Prometheus metrics" "HTTP Server" {
                tags "Monitoring"
            }
            healthProbes = container "Health/Readiness Probes" "Kubernetes health checks" "HTTP Server" {
                tags "Infrastructure"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management and ingress" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        controllerRuntime = softwareSystem "controller-runtime" "Kubernetes controller framework" "External"

        # Internal ODH Dependencies
        jupyterWebApp = softwareSystem "jupyter-web-app" "UI for creating Notebook CRs" "Internal ODH"
        odhDashboard = softwareSystem "odh-dashboard" "Displays Notebook status in ODH dashboard" "Internal ODH"
        notebookImages = softwareSystem "notebook-images" "Base Jupyter notebook container images" "Internal ODH"
        odhNotebookController = softwareSystem "odh-notebook-controller" "ODH-specific notebook controller extensions" "Internal ODH"

        # User interactions
        user -> jupyterWebApp "Creates notebooks via UI"
        user -> kubernetes "Creates Notebook CRs via kubectl"

        # Controller interactions with Kubernetes
        notebookReconciler -> kubernetes "Watches Notebook CRs, manages StatefulSets/Services" "HTTPS/6443 (ServiceAccount Token)"
        cullingReconciler -> kubernetes "Watches Notebook CRs, adds STOP_ANNOTATION" "HTTPS/6443 (ServiceAccount Token)"
        notebookReconciler -> istio "Creates VirtualService for ingress" "HTTPS/6443 (when USE_ISTIO=true)"

        # Internal ODH integrations
        jupyterWebApp -> kubernetes "Creates Notebook CRs" "HTTPS/6443 (Bearer Token)"
        odhDashboard -> kubernetes "Reads Notebook CR status" "HTTPS/6443"
        notebookReconciler -> notebookImages "References container images in StatefulSet spec"
        notebookReconciler -> odhNotebookController "Uses ODH-specific annotations (notebook-restart)"

        # Monitoring
        prometheus -> metricsExporter "Scrapes metrics" "HTTP/8080"
        kubernetes -> healthProbes "Health/readiness checks" "HTTP/8081"

        # Framework dependencies
        notebookReconciler -> controllerRuntime "Uses for reconciliation and caching" "Library"
        cullingReconciler -> controllerRuntime "Uses for reconciliation and caching" "Library"

        # Culling flow
        cullingReconciler -> kubernetes "Polls /api/kernels on notebook pods for idle detection" "HTTP/8888"
    }

    views {
        systemContext notebookController "SystemContext" {
            include *
            autoLayout
        }

        container notebookController "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                opacity 70
            }
            element "Monitoring" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

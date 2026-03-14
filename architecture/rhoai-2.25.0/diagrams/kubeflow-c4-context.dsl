workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML experimentation"
        dashboard = person "ODH Dashboard User" "Manages notebook instances via web interface"

        notebookController = softwareSystem "Notebook Controller (Kubeflow)" "Manages lifecycle of Jupyter notebook instances in Kubernetes through Notebook CRDs" {
            controller = container "Notebook Reconciler" "Reconciles Notebook CRDs to StatefulSets and Services" "Go Operator" {
                reconciler = component "NotebookReconciler" "Watches Notebook CRs and creates/updates StatefulSets" "Go Controller"
                serviceManager = component "Service Manager" "Creates and manages ClusterIP services for notebooks" "Go"
                virtualServiceManager = component "VirtualService Manager" "Creates Istio VirtualServices when USE_ISTIO=true" "Go"
            }

            culling = container "Culling Reconciler" "Monitors notebook kernel activity and stops idle notebooks" "Go Controller" {
                idleChecker = component "Idle Checker" "Queries /api/kernels endpoint for kernel activity" "Go"
                annotator = component "Annotation Manager" "Adds kubeflow-resource-stopped annotation to idle notebooks" "Go"
            }

            metrics = container "Metrics Server" "Exposes Prometheus metrics for notebook operations" "HTTP Server :8080"
            health = container "Health Probe" "Provides liveness and readiness endpoints" "HTTP Server :8081"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        istio = softwareSystem "Istio Service Mesh" "Traffic management and service mesh" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"

        notebookPods = softwareSystem "Jupyter Notebook Pods" "Running Jupyter server instances" "Workload"

        # User interactions
        user -> notebookController "Creates Notebook CRs via kubectl" "kubectl/HTTPS"
        dashboard -> notebookController "Creates and manages notebooks" "Kubernetes API/HTTPS"

        # Controller dependencies
        notebookController -> kubernetes "Creates/updates StatefulSets, Services, Pods" "HTTPS/6443 TLS1.2+"
        notebookController -> istio "Creates VirtualService resources (optional)" "Kubernetes API/6443"
        notebookController -> notebookPods "Queries /api/kernels for idle detection" "HTTP/8888"

        # Monitoring
        prometheus -> notebookController "Scrapes /metrics endpoint" "HTTP/8080"

        # Integration
        odhDashboard -> notebookController "Manages notebooks via Kubernetes API" "HTTPS/6443"
        kubernetes -> notebookPods "Schedules and manages notebook workloads" "HTTPS/10250 mTLS"

        # Istio routing
        istio -> notebookPods "Routes traffic to notebooks (when enabled)" "HTTP/80"
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

        component controller "NotebookReconcilerComponents" {
            include *
            autoLayout
        }

        component culling "CullingComponents" {
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
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Workload" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

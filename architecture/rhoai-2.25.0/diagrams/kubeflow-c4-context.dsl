workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML experimentation"
        admin = person "Platform Administrator" "Manages notebook controller configuration and monitors notebook resources"

        notebookController = softwareSystem "Notebook Controller" "Manages lifecycle of Jupyter notebook instances as Kubernetes custom resources" {
            controller = container "Notebook Reconciler" "Reconciles Notebook CRDs to StatefulSets and Services" "Go Controller" {
                tags "Controller"
            }
            culling = container "Culling Reconciler" "Monitors and stops idle notebooks" "Go Controller" {
                tags "Controller"
            }
            metrics = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Endpoint :8080" {
                tags "Monitoring"
            }
            health = container "Health Probe" "Provides health checks" "HTTP Endpoint :8081" {
                tags "Monitoring"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External" {
            tags "Platform"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and VirtualServices" "External" {
            tags "Platform"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "Monitoring"
        }

        dashboard = softwareSystem "Kubeflow Dashboard" "Web UI for managing notebooks" "Internal ODH" {
            tags "Internal"
        }

        notebookPods = softwareSystem "Jupyter Notebook Pods" "Running Jupyter notebook instances" "Workload" {
            tags "Workload"
        }

        # User interactions
        datascientist -> dashboard "Creates/manages notebooks via UI"
        datascientist -> k8s "Creates/manages notebooks via kubectl"
        admin -> notebookController "Configures culling and Istio settings"
        admin -> prometheus "Monitors notebook metrics"

        # Dashboard interactions
        dashboard -> k8s "Creates Notebook CRs" "HTTPS/6443"

        # Controller interactions
        controller -> k8s "Watches Notebook CRs, creates StatefulSets/Services" "HTTPS/6443"
        controller -> istio "Creates VirtualServices when USE_ISTIO=true" "K8s API"
        controller -> metrics "Publishes metrics"

        culling -> notebookPods "Queries /api/kernels for idle detection" "HTTP/8888"
        culling -> k8s "Adds culling annotations to Notebooks" "HTTPS/6443"
        culling -> metrics "Publishes culling metrics"

        k8s -> notebookPods "Creates/manages pods via Kubelet" "mTLS/10250"

        # Monitoring
        prometheus -> metrics "Scrapes metrics" "HTTP/8080"

        # Istio routing
        istio -> notebookPods "Routes traffic to notebooks" "HTTP"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Controller" {
                background #d5e8d4
                color #000000
            }
            element "Monitoring" {
                background #e1d5e7
                color #000000
            }
            element "Workload" {
                background #dae8fc
                color #000000
            }
        }
    }
}

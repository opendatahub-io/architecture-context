workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML/data science work"
        admin = person "Platform Administrator" "Configures notebook controller and manages cluster resources"

        kubeflow = softwareSystem "Kubeflow Notebook Controller" "Automates deployment and lifecycle management of Jupyter notebook instances" {
            controller = container "Notebook Controller Manager" "Reconciles Notebook CRs and manages infrastructure" "Go Operator" {
                notebookReconciler = component "Notebook Reconciler" "Creates StatefulSets, Services, VirtualServices for notebooks" "Go Controller"
                cullingReconciler = component "Culling Reconciler" "Monitors and culls idle notebooks based on activity" "Go Controller"
                metricsEndpoint = component "Metrics Collector" "Exposes Prometheus metrics" "HTTP Endpoint :8080"
                healthEndpoint = component "Health Probes" "Liveness and readiness checks" "HTTP Endpoint :8081"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic routing, mTLS, and observability" "External Platform"
        dashboard = softwareSystem "ODH Dashboard (jupyter-web-app)" "Web interface for creating and managing notebooks" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        imageRegistry = softwareSystem "Container Image Registry" "Provides Jupyter notebook container images" "Internal ODH"

        # User interactions
        user -> dashboard "Creates and manages notebooks via web UI"
        dashboard -> k8s "Creates Notebook CRs via Kubernetes API" "HTTPS/6443 TLS1.2+ Bearer Token"
        user -> kubeflow "Accesses notebook instances" "HTTPS/443 via Istio Gateway"

        # Controller interactions
        kubeflow -> k8s "Manages StatefulSets, Services, Pods" "HTTPS/6443 TLS1.2+ ServiceAccount Token"
        kubeflow -> istio "Creates VirtualServices for routing" "Kubernetes CRD API"
        kubeflow -> imageRegistry "Pulls Jupyter notebook images" "HTTPS (Docker registry protocol)"

        # Monitoring
        prometheus -> kubeflow "Scrapes metrics" "HTTP/8080"

        # Admin
        admin -> kubeflow "Configures culling, Istio settings" "ConfigMaps and Environment Variables"

        # Component-level relationships
        notebookReconciler -> k8s "CRUD operations on StatefulSets, Services" "HTTPS/6443"
        notebookReconciler -> istio "Creates VirtualServices" "K8s API"
        cullingReconciler -> k8s "Queries and deletes idle notebooks" "HTTPS/6443"
        cullingReconciler -> notebookReconciler "Culls idle Notebook CRs" "HTTP/80 to notebook pods"
        prometheus -> metricsEndpoint "Scrapes controller metrics" "HTTP/8080"
    }

    views {
        systemContext kubeflow "SystemContext" {
            include *
            autoLayout
        }

        container kubeflow "Containers" {
            include *
            autoLayout
        }

        component controller "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML/data science workloads"

        notebookController = softwareSystem "Notebook Controller" "Kubernetes operator that manages Jupyter notebook instances via Notebook CRD" {
            manager = container "Manager" "Main controller process running reconciliation loops" "Go, controller-runtime" {
                notebookReconciler = component "NotebookReconciler" "Reconciles Notebook CRs by creating/updating StatefulSets, Services, and VirtualServices" "Go Controller"
                cullingReconciler = component "CullingReconciler" "Monitors notebook kernel activity and stops idle notebooks" "Go Controller"
                metricsExporter = component "Metrics Exporter" "Exposes Prometheus metrics for monitoring" "Go"
            }
            rbacProxy = container "kube-rbac-proxy" "Optional RBAC proxy for securing metrics endpoint" "Go Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes control plane API" "External"
        }

        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        jupyterWebApp = softwareSystem "jupyter-web-app" "Kubeflow web UI for spawning notebooks" "Internal ODH"

        notebookPods = softwareSystem "Notebook Pods" "Jupyter server instances running user workloads" "Managed Resources"

        // User interactions
        dataScientist -> jupyterWebApp "Creates notebook instances via web UI"
        dataScientist -> notebookPods "Accesses Jupyter notebooks via browser" "HTTPS/443 via Istio"

        // Controller interactions
        jupyterWebApp -> apiServer "Creates Notebook CRs" "HTTPS/443, User credentials"
        apiServer -> notebookReconciler "Sends watch events for Notebook CRs" "HTTPS, ServiceAccount token"
        notebookReconciler -> apiServer "Creates/updates StatefulSets, Services, VirtualServices" "HTTPS/443, ServiceAccount token"
        apiServer -> notebookPods "Schedules and manages notebook pods"

        // Culling
        cullingReconciler -> notebookPods "Queries kernel activity" "HTTP/8888"
        cullingReconciler -> apiServer "Updates Notebook CRs with stop annotation" "HTTPS/443"

        // Istio integration
        notebookReconciler -> istio "Creates VirtualServices for external access" "HTTPS/443 via K8s API"
        istio -> notebookPods "Routes external traffic" "HTTP/80, mTLS"

        // Metrics
        prometheus -> rbacProxy "Scrapes metrics" "HTTPS/8443, RBAC"
        rbacProxy -> metricsExporter "Proxies metrics requests" "HTTP/8080 localhost"
        metricsExporter -> apiServer "Lists StatefulSets for metrics" "HTTPS/443"
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

        component manager "Components" {
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
            element "Managed Resources" {
                background #4a90e2
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

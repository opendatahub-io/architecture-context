workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML experimentation"
        admin = person "Platform Admin" "Manages notebook controller configuration and RBAC"

        notebookController = softwareSystem "Notebook Controller" "Manages lifecycle of Jupyter notebook instances in Kubernetes" {
            controller = container "Notebook Controller" "Reconciles Notebook CRs and manages underlying Kubernetes resources" "Go Operator" {
                notebookReconciler = component "NotebookReconciler" "Main reconciliation loop for Notebook CRs" "Controller"
                cullingReconciler = component "CullingReconciler" "Monitors and culls idle notebooks" "Controller"
                metricsCollector = component "Metrics Collector" "Exposes Prometheus metrics" "Exporter"
                webhookServer = component "Webhook Server" "CRD conversion webhook (disabled)" "Admission Controller"
            }

            notebookCRD = container "Notebook CRD" "Custom Resource Definition for notebook instances" "Kubernetes CRD" {
                tags "CRD"
            }

            generatedResources = container "Generated Resources" "StatefulSets, Services, VirtualServices created per notebook" "Kubernetes Resources" {
                tags "Generated"
            }
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes API for resource management" "kube-apiserver"
            kubelet = container "Kubelet" "Runs and monitors pods" "kubelet"
        }

        istio = softwareSystem "Istio" "Service mesh for traffic management and ingress" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Optional"
        jupyterHub = softwareSystem "JupyterHub" "Multi-user Jupyter environment launcher" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"
        containerRegistry = softwareSystem "Container Registry" "Stores Jupyter notebook container images" "External"

        notebookPod = softwareSystem "Jupyter Notebook Pod" "Running notebook instance with Jupyter server" "Workload" {
            tags "Workload"
        }

        # User relationships
        dataScientist -> jupyterHub "Launches notebooks via"
        dataScientist -> odhDashboard "Manages notebooks via"
        dataScientist -> notebookPod "Uses for ML experimentation" "HTTPS/443 (via Istio)"
        admin -> kubernetes "Configures RBAC and ConfigMaps via" "kubectl"

        # JupyterHub/Dashboard to Kubernetes
        jupyterHub -> apiServer "Creates Notebook CRs via" "HTTPS/6443"
        odhDashboard -> apiServer "Creates/deletes Notebook CRs via" "HTTPS/6443"

        # Controller to Kubernetes API
        apiServer -> notebookReconciler "Sends watch events to" "Watch API"
        notebookReconciler -> apiServer "Creates/updates StatefulSets, Services, VirtualServices" "HTTPS/6443"
        cullingReconciler -> apiServer "Updates Notebook CRs (stop idle notebooks)" "HTTPS/6443"

        # Controller to Notebook CRD
        notebookReconciler -> notebookCRD "Watches and reconciles"
        notebookCRD -> generatedResources "Defines desired state for"

        # Controller to Notebook Pods (culling)
        cullingReconciler -> notebookPod "Queries kernel/terminal activity" "HTTP/8888"

        # Prometheus metrics
        prometheus -> metricsCollector "Scrapes metrics from" "HTTP/8080"

        # Kubelet health probes
        kubelet -> controller "Health and readiness probes" "HTTP/8081"

        # Generated resources to workloads
        generatedResources -> notebookPod "Creates and manages"
        generatedResources -> istio "Creates VirtualServices for" "if USE_ISTIO=true"

        # Notebook pod to registry
        notebookPod -> containerRegistry "Pulls images from" "HTTPS/443"

        # Istio routing
        istio -> notebookPod "Routes external traffic to" "HTTP/80"
    }

    views {
        systemContext notebookController "SystemContext" {
            include *
            autoLayout lr
        }

        container notebookController "Containers" {
            include *
            autoLayout tb
        }

        component controller "Components" {
            include *
            autoLayout tb
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
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Workload" {
                background #f5a623
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "CRD" {
                background #f5a623
                color #ffffff
            }
            element "Generated" {
                background #d79b00
                color #ffffff
            }
        }

        theme default
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses Jupyter notebook environments for ML development"
        admin = person "Administrator" "Manages notebook resources and configures culling policies"

        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter notebook server lifecycle as Kubernetes custom resources" {
            controller = container "NotebookReconciler" "Main reconciliation controller" "Go Operator" {
                tags "Controller"
            }
            culler = container "CullingReconciler" "Idle notebook culling controller" "Go Operator" {
                tags "Controller"
            }
            metrics = container "Metrics Collector" "Prometheus metrics exporter" "Go Service" {
                tags "Metrics"
            }
            webhookServer = container "Webhook Server" "Validates and mutates Notebook CRs (disabled by default)" "Go Service" {
                tags "Webhook"
            }
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform" {
            tags "External"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS and traffic management" {
            tags "External"
            gateway = container "Istio Gateway" "Ingress gateway for external access" "Istio"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "External"
        }

        notebookPods = softwareSystem "Notebook Pods" "Running Jupyter notebook servers" {
            tags "Internal RHOAI"
        }

        kubeflowCommon = softwareSystem "kubeflow/common" "Shared reconciliation utilities" {
            tags "Internal ODH"
        }

        configMaps = softwareSystem "ConfigMaps" "Configuration for Istio and culling settings" {
            tags "Internal RHOAI"
        }

        %% Relationships - Users
        dataScientist -> notebookController "Creates and accesses Notebook CRs via kubectl/UI"
        dataScientist -> notebookPods "Uses Jupyter notebooks for ML development" "HTTPS/443"
        admin -> notebookController "Configures culling policies and Istio settings"

        %% Relationships - Controller
        notebookController -> kubernetes "Watches and manages Notebook, StatefulSet, Service, Pod, Event resources" "HTTPS/6443"
        controller -> kubernetes "Creates/updates StatefulSets and Services" "HTTPS/6443"
        culler -> kubernetes "Lists Notebooks and updates annotations" "HTTPS/6443"
        culler -> notebookPods "Checks /api/kernels for activity" "HTTP/8888 (mTLS)"
        metrics -> prometheus "Exposes notebook lifecycle metrics" "HTTP/8080"

        %% Relationships - Istio
        notebookController -> istio "Creates VirtualService resources (when USE_ISTIO=true)" "HTTPS/6443"
        gateway -> notebookPods "Routes external traffic to notebooks" "HTTP/80 (mTLS)"

        %% Relationships - Configuration
        notebookController -> configMaps "Reads USE_ISTIO, ENABLE_CULLING, CULL_IDLE_TIME" "HTTPS/6443"
        notebookController -> kubeflowCommon "Uses shared reconciliation helpers" "Go import"

        %% Relationships - Monitoring
        prometheus -> notebookController "Scrapes metrics (notebook_running, notebook_create_total)" "HTTP/8080"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal RHOAI" {
                background #4a90e2
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Metrics" {
                background #f5a623
                color #ffffff
            }
            element "Webhook" {
                background #d0d0d0
                color #000000
            }
        }
    }
}

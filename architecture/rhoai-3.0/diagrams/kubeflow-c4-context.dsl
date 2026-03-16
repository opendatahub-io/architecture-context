workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebooks for ML experiments and model development"
        admin = person "Platform Administrator" "Configures and monitors notebook controller deployment"

        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter notebook lifecycle as StatefulSets in Kubernetes" {
            controller = container "NotebookReconciler" "Watches Notebook CRs and manages StatefulSet/Service lifecycle" "Go Operator" {
                reconciler = component "Reconciliation Loop" "Main reconciliation logic for Notebook CRs" "Go"
                vsGenerator = component "VirtualService Generator" "Creates Istio VirtualService for ingress routing" "Go"
                eventRecorder = component "Event Recorder" "Propagates Pod/StatefulSet events to Notebook CR" "Go"
            }
            culler = container "CullingReconciler" "Monitors notebook idle time and culls inactive notebooks" "Go Controller" {
                idleDetector = component "Idle Detector" "Polls /api/kernels to detect idle notebooks" "Go"
                cullExecutor = component "Cull Executor" "Adds STOP_ANNOTATION to idle notebooks" "Go"
            }
            metricsExporter = container "Metrics Exporter" "Exposes Prometheus metrics for observability" "Go HTTP Server"
            healthProbes = container "Health/Readiness Probes" "Provides /healthz and /readyz endpoints" "Go HTTP Server"
        }

        k8s = softwareSystem "Kubernetes API Server" "Manages cluster resources and orchestration" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides service mesh routing and mTLS" "External"
        prometheus = softwareSystem "Prometheus" "Collects and stores metrics" "External"
        jupyterWebApp = softwareSystem "Jupyter Web App" "UI for creating and managing notebooks" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Displays notebook status and conditions" "Internal ODH"
        notebookImages = softwareSystem "Notebook Images Registry" "Provides base Jupyter notebook container images" "Internal ODH"

        %% Relationships
        dataScientist -> jupyterWebApp "Creates notebooks via UI"
        dataScientist -> k8s "Creates Notebook CRs via kubectl"
        admin -> notebookController "Configures via environment variables and ConfigMaps"
        admin -> prometheus "Monitors notebook metrics"

        jupyterWebApp -> k8s "Creates Notebook CRs" "HTTPS/6443"

        k8s -> controller "Sends watch events for Notebook CRs" "Internal"
        controller -> k8s "CRUD operations on StatefulSet/Service/Pod resources" "HTTPS/6443"
        controller -> vsGenerator "Triggers VirtualService creation when USE_ISTIO=true"
        vsGenerator -> k8s "Creates Istio VirtualService CRDs" "HTTPS/6443"
        controller -> eventRecorder "Propagates events"
        eventRecorder -> k8s "Creates Event resources" "HTTPS/6443"

        culler -> idleDetector "Triggers idle checks every IDLENESS_CHECK_PERIOD"
        idleDetector -> k8s "Polls Notebook Pods /api/kernels endpoint" "HTTP/8888"
        idleDetector -> cullExecutor "Reports idle notebooks"
        cullExecutor -> k8s "Adds STOP_ANNOTATION to Notebook CR" "HTTPS/6443"

        prometheus -> metricsExporter "Scrapes metrics" "HTTPS/8443 or HTTP/8080"
        metricsExporter -> k8s "Lists StatefulSets for metrics calculation" "HTTPS/6443"

        k8s -> healthProbes "Liveness/Readiness checks" "HTTP/8081"

        odhDashboard -> k8s "Reads Notebook CR status" "HTTPS/6443"

        controller -> istio "Creates VirtualService resources for ingress routing" "via Kubernetes API"

        %% Notebook workload relationships (implicit)
        k8s -> notebookImages "Pulls notebook container images" "Container Registry Protocol"
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

        component culler "CullingReconcilerComponents" {
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
            element "Software System" {
                background #4a90e2
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
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

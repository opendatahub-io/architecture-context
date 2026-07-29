workspace {
    model {
        admin = person "Cluster Admin" "Manages MLflow deployments via ODH/RHOAI platform"
        datascientist = person "Data Scientist" "Uses MLflow tracking server for experiment tracking"

        mlflowOperator = softwareSystem "mlflow-operator" "Kubernetes operator managing MLflow tracking server deployments on OpenShift" {
            mlflowController = container "MLflow Controller" "Reconciles MLflow CRs, renders Helm charts, manages MLflow server lifecycle" "Go Controller"
            mlflowOpController = container "MLflowOperator Controller" "Reconciles MLflowOperator CRs for ODH platform coordination" "Go Controller"
            namespaceController = container "Namespace Controller" "Manages per-namespace RBAC bindings based on Auth CR" "Go Controller"
            securityProfileWatcher = container "SecurityProfileWatcher" "Monitors OpenShift TLS profile changes and triggers restart" "Go Watcher"
            helmEngine = container "Helm Renderer" "Renders charts/mlflow to generate managed resources" "Helm v3"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster control plane" "External"
        gatewayApi = softwareSystem "Gateway API" "Traffic routing via HTTPRoutes" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitors" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with ConsoleLinks" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "TLS certificate provisioning" "External"
        openshiftApiServer = softwareSystem "OpenShift APIServer Config" "Cluster TLS profile configuration" "External"
        authService = softwareSystem "Auth Service" "ODH platform authentication (services.platform.opendatahub.io)" "Internal ODH"

        admin -> mlflowOperator "Creates MLflow and MLflowOperator CRs via kubectl/ODH Dashboard"
        datascientist -> mlflowOperator "Creates MLflowConfig for namespace overrides"

        mlflowController -> helmEngine "Renders chart templates with CR values"
        mlflowController -> k8sApi "CRUD for Deployments, Services, Secrets, PVCs, CronJobs, Jobs" "HTTPS/6443"
        mlflowController -> gatewayApi "Creates HTTPRoutes (conditional)" "HTTPS"
        mlflowController -> prometheusOp "Creates ServiceMonitors (conditional)" "HTTPS"
        mlflowController -> openshiftConsole "Creates ConsoleLinks (conditional)" "HTTPS"

        mlflowOpController -> k8sApi "Manages MLflowOperator CR status" "HTTPS/6443"

        namespaceController -> k8sApi "Manages RoleBindings per namespace" "HTTPS/6443"
        namespaceController -> authService "Reads Auth CR for RBAC configuration" "Kubernetes API"

        securityProfileWatcher -> openshiftApiServer "Watches TLS profile changes" "Kubernetes API"
        mlflowOperator -> serviceCa "TLS cert provisioning for metrics" "annotation-based"
    }

    views {
        systemContext mlflowOperator "SystemContext" {
            include *
            autoLayout
        }

        container mlflowOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
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
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

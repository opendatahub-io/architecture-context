workspace {
    model {
        platformAdmin = person "Platform Admin" "Deploys and configures MLflow instances via MLflow CR"
        dataScientist = person "Data Scientist" "Uses MLflow tracking and artifact storage for ML experiments"

        mlflowOperator = softwareSystem "mlflow-operator" "Kubernetes operator automating MLflow deployment, lifecycle management, and upgrade orchestration" {
            mlflowReconciler = container "MLflowReconciler" "Reconciles MLflow CRs, renders Helm chart, manages Deployments, Services, Jobs, HTTPRoutes" "Go Controller"
            mlflowOperatorReconciler = container "MLflowOperatorReconciler" "Handles ODH/RHOAI platform handoff via MLflowOperator singleton" "Go Controller"
            namespaceRBACReconciler = container "NamespaceRBACReconciler" "Distributes workspace-scoped view/edit RoleBindings" "Go Controller"
            helmRenderer = container "Helm Chart Renderer" "Renders vendored MLflow Helm chart at reconcile time" "Helm SDK (in-process)"
            metricsServer = container "Metrics Server" "Serves Prometheus metrics with TLS and auth" "HTTPS 8443/TCP"
        }

        managedMLflow = softwareSystem "Managed MLflow Instance" "MLflow tracking and artifact servers deployed by the operator" {
            trackingServer = container "MLflow Tracking Server" "Experiment tracking, run management" "Python/uvicorn"
            artifactServer = container "Artifact Server" "Dedicated artifact I/O" "Python/uvicorn"
            gcCronJob = container "Garbage Collection CronJob" "Periodic cleanup of expired data" "CronJob"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "data-science-gateway for external traffic routing" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Web UI with ConsoleLink integration" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack with ServiceMonitor support" "External"
        authCR = softwareSystem "Auth CR" "Platform auth providing workspace group subjects" "Internal RHOAI"
        openshiftTLS = softwareSystem "OpenShift TLS Profile" "Cluster-wide TLS cipher/version policy" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "TLS certificate provisioning and rotation" "External"

        # Relationships - Users
        platformAdmin -> mlflowOperator "Creates/updates MLflow CR via kubectl"
        dataScientist -> managedMLflow "Logs experiments, stores artifacts"

        # Relationships - Operator to dependencies
        mlflowOperator -> kubernetesAPI "CRUD resources, watch events, leader election" "HTTPS/6443 TLS 1.2+"
        mlflowOperator -> gatewayAPI "Creates HTTPRoutes for /mlflow and /mlflow-artifacts"
        mlflowOperator -> openshiftConsole "Creates ConsoleLink for MLflow UI"
        mlflowOperator -> prometheusOperator "Creates ServiceMonitor for scrape config"
        mlflowOperator -> authCR "Reads workspace subjects for RBAC distribution"
        mlflowOperator -> openshiftTLS "Fetches and watches TLS cipher policy"
        serviceCa -> mlflowOperator "Provisions metrics TLS certificate"

        # Relationships - Operator to managed resources
        mlflowOperator -> managedMLflow "Deploys and manages lifecycle"

        # Internal container relationships
        mlflowReconciler -> helmRenderer "Renders chart with computed values"
        mlflowReconciler -> kubernetesAPI "Applies rendered manifests"
        namespaceRBACReconciler -> authCR "Reads workspace group subjects"
        prometheusOperator -> metricsServer "Scrapes metrics" "HTTPS/8443 TLS"

        # Managed MLflow to Gateway
        gatewayAPI -> managedMLflow "Routes external traffic"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Person" {
                shape Person
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
        }
    }
}

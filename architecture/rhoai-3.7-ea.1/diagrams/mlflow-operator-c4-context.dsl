workspace {
    model {
        admin = person "Platform Admin" "Configures the cluster-wide MLflow CR"
        user = person "Data Scientist" "Tracks experiments and registers models via MLflow UI/SDK"

        mlflowOperator = softwareSystem "MLflow Operator" "Reconciles the singleton MLflow CR into a TLS-secured, Kubernetes-auth MLflow service exposed at /mlflow" {
            manager = container "mlflow-operator manager" "MLflowReconciler, MLflowOperatorReconciler, NamespaceRBACReconciler; metrics :8443, probes :8081" "Go, controller-runtime"
            chart = container "Embedded Helm chart" "Renders operand Deployments, Services, RBAC, PVC, NetworkPolicy, ServiceMonitor, CronJobs" "Helm v3"
            tracking = container "MLflow tracking server" "kubernetes-auth app, kubernetes:// workspace store, HTTPS 8443" "Python, MLflow v3.17.0"
            artifacts = container "MLflow artifacts server" "Optional dedicated /mlflow-artifacts API, HTTPS 8443" "Python, MLflow"
            migration = container "Migration Job" "Database schema migration after scale-to-zero" "Kubernetes Job"
        }

        rhods = softwareSystem "rhods-operator" "Deploys operator, creates MLflowOperator CR, owns Auth CR" "Internal ODH"
        gateway = softwareSystem "data-science-gateway" "Platform Gateway API ingress in openshift-ingress" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard / Workbenches / Pipelines" "MLflow consumers via mlflow-integration ClusterRole" "Internal ODH"
        kube = softwareSystem "Kubernetes API" "Reconciliation target and SSAR authorizer" "External"
        console = softwareSystem "OpenShift Console" "ConsoleLink application menu" "External"
        serviceca = softwareSystem "OpenShift service-ca" "Serving certificates" "External"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus scraping via ServiceMonitor" "External"
        db = softwareSystem "PostgreSQL / MySQL" "MLflow metadata store" "External"
        s3 = softwareSystem "Object Storage" "S3-compatible artifact storage" "External"

        admin -> manager "Creates MLflow CR" "kubectl / HTTPS 6443"
        rhods -> manager "Deploys; MLflowOperator CR; Auth CR"
        user -> gateway "Uses MLflow UI/API" "HTTPS 443, Bearer token"
        gateway -> tracking "Routes /mlflow" "HTTPS 8443"
        gateway -> artifacts "Routes /mlflow-artifacts" "HTTPS 8443"
        dashboard -> tracking "Programmatic access" "HTTPS 8443, Bearer token"
        manager -> chart "Renders"
        chart -> tracking "Applies"
        chart -> artifacts "Applies"
        manager -> migration "Creates on version change"
        manager -> kube "Watch/CRUD, discovery" "HTTPS 6443"
        manager -> gateway "Creates HTTPRoutes"
        manager -> console "Creates ConsoleLink"
        serviceca -> tracking "Issues mlflow-tls"
        monitoring -> manager "Scrapes /metrics" "HTTPS 8443, TokenReview+SAR"
        monitoring -> tracking "Scrapes operand metrics" "HTTPS 8443"
        tracking -> kube "SelfSubjectAccessReview" "HTTPS 6443"
        tracking -> db "Metadata" "SQL 5432/3306"
        tracking -> s3 "Artifacts" "HTTPS 443/9000"
        artifacts -> s3 "Artifacts" "HTTPS 443/9000"
        migration -> db "Schema migration" "SQL"
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
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}

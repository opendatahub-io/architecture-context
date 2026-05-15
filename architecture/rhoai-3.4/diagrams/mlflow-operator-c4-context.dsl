workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML experiments, models, and artifacts via MLflow"
        platformAdmin = person "Platform Admin" "Deploys and configures the MLflow operator via RHOAI platform operator"
        workspaceOwner = person "Workspace Owner" "Configures per-namespace artifact storage credentials via MLflowConfig"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow tracking server deployments via Helm chart reconciliation" {
            controller = container "MLflow Controller" "Watches MLflow CRs and reconciles deployments using embedded Helm chart rendering and Server-Side Apply" "Go (controller-runtime)"
            helmRenderer = container "Helm Chart Renderer" "Renders charts/mlflow templates into unstructured Kubernetes resources" "helm.sh/helm/v3"
            migrationInjector = container "Migration Injector" "Post-render mutation to inject db-migration init container for RHOAI upgrades" "Go"
        }

        mlflowServer = softwareSystem "MLflow Tracking Server" "Deployed MLflow server providing experiment tracking, model registry, and artifact management" {
            server = container "MLflow Server" "Python application serving REST API over HTTPS with Kubernetes-native RBAC authorization" "Python (uvicorn), 8443/TCP HTTPS"
            caBundleWatcher = container "CA Bundle Watcher" "Sidecar that polls CA certificate sources every 30s and regenerates combined bundle" "Shell script sidecar"
            dbMigration = container "DB Migration" "Init container running mlflow db fix-migration-gap for Alembic schema migration" "Python init container"
            combineCaBundles = container "CA Bundle Aggregator" "Init container combining system, platform, and custom CA certificates" "Shell script init container"
        }

        # External dependencies
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API server for resource management and RBAC authorization" "External"
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "rhods-operator that deploys MLflow operator and creates MLflow CRs" "Internal RHOAI"
        dataScienceGateway = softwareSystem "Data Science Gateway" "Envoy-based Gateway API gateway providing external HTTPS ingress" "Internal RHOAI"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with application menu integration via ConsoleLink" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Auto-provisions TLS certificates for annotated Services" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics scraping and monitoring via ServiceMonitor" "External"

        # Data stores
        postgresql = softwareSystem "PostgreSQL" "Backend metadata store for MLflow experiments and model registry" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "MinIO or SeaweedFS providing artifact storage for ML experiments" "External"

        # Platform CA
        platformCa = softwareSystem "Platform CA Bundle" "odh-trusted-ca-bundle ConfigMap managed by RHOAI platform operator" "Internal RHOAI"

        # Relationships - Users
        dataScientist -> mlflowServer "Creates experiments, logs metrics, registers models" "HTTPS/8443, Bearer Token"
        platformAdmin -> rhoaiOperator "Configures RHOAI platform" "kubectl/API"
        workspaceOwner -> k8sApi "Creates MLflowConfig CR and mlflow-artifact-connection Secret" "kubectl/API"

        # Relationships - Platform lifecycle
        rhoaiOperator -> mlflowOperator "Deploys operator, creates singleton MLflow CR" "Kubernetes API"
        mlflowOperator -> k8sApi "Watches CRs, applies resources via Server-Side Apply" "HTTPS/6443"
        mlflowOperator -> mlflowServer "Creates and manages Deployment, Service, NetworkPolicy" "Kubernetes API"

        # Relationships - Runtime
        dataScienceGateway -> mlflowServer "Routes external traffic to MLflow" "HTTPS/8443, TLS (service-ca)"
        mlflowServer -> k8sApi "SelfSubjectAccessReview for authorization" "HTTPS/6443"
        mlflowServer -> postgresql "Stores experiment/model metadata" "PostgreSQL/5432, TLS verify-full"
        mlflowServer -> s3Storage "Stores/retrieves ML artifacts" "HTTPS/9000, AWS IAM"
        serviceCa -> mlflowServer "Provisions TLS certificate (mlflow-tls secret)" "Annotation-triggered"
        platformCa -> mlflowServer "Provides trusted CA certificates" "ConfigMap volume mount"
        prometheus -> mlflowOperator "Scrapes operator metrics" "HTTPS/8443, TokenReview+SAR"
        mlflowOperator -> dataScienceGateway "Creates HTTPRoute for external ingress" "Gateway API"
        mlflowOperator -> openshiftConsole "Creates ConsoleLink for menu integration" "ConsoleLink CR"

        controller -> helmRenderer "Passes CR spec values for chart rendering"
        helmRenderer -> migrationInjector "Rendered unstructured objects for post-processing"
    }

    views {
        systemContext mlflowOperator "SystemContext" {
            include *
            autoLayout
            description "MLflow Operator system context showing all external interactions"
        }

        container mlflowOperator "OperatorContainers" {
            include *
            autoLayout
            description "Internal structure of the MLflow Operator"
        }

        container mlflowServer "ServerContainers" {
            include *
            autoLayout
            description "Internal structure of the deployed MLflow Tracking Server"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates feature definitions, deploys feature stores, and retrieves features for ML training and inference"
        platformAdmin = person "Platform Admin" "Manages FeatureStore CRs and configures authentication/authorization"

        feast = softwareSystem "Feast" "Feature store platform providing Kubernetes operator for lifecycle management and multi-language feature serving" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CR lifecycle, reconciles 12 owned resource types" "Go, controller-runtime v0.23.3"
            notebookReconciler = container "Notebook ConfigMap Reconciler" "Injects Feast client configuration into Kubeflow Notebook workbenches" "Go, controller-runtime"
            goFeatureServer = container "Go Feature Server" "High-performance online feature retrieval via HTTP and gRPC" "Go" {
                tags "NoAuth"
            }
            pythonFeatureServer = container "Python Feature Server" "Comprehensive REST API with 90+ endpoints, gRPC services, monitoring, lineage, and UI" "Python, FastAPI/Starlette"
            securityManager = container "Security Manager" "Configurable authentication: OIDC token validation, Kubernetes RBAC, or NoAuth" "Python, PyJWT"
            registryServer = container "Registry Server (gRPC)" "55+ RPCs for feature registry CRUD operations" "Python, gRPC"
            feastUI = container "Feast UI" "Web interface for feature store management and monitoring" "React"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External" {
            tags "External"
        }
        postgresql = softwareSystem "PostgreSQL" "Online feature store backend" "External" {
            tags "External"
        }
        redis = softwareSystem "Redis / Valkey" "Online feature store backend for low-latency lookups" "External" {
            tags "External"
        }
        s3 = softwareSystem "S3-compatible Storage" "Feature registry and model artifact storage" "External" {
            tags "External"
        }
        gcs = softwareSystem "Google Cloud Storage" "Feature registry and artifact storage" "External" {
            tags "External"
        }
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider for token-based authentication" "External" {
            tags "External"
        }
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbenches for data science" "Internal RHOAI" {
            tags "Internal"
        }
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring stack for metrics collection" "Internal RHOAI" {
            tags "Internal"
        }
        openLineage = softwareSystem "OpenLineage" "Data lineage tracking platform" "External" {
            tags "External"
        }
        ray = softwareSystem "Ray" "Distributed compute engine for materialization jobs" "External" {
            tags "External"
        }

        # Person interactions
        dataScientist -> feast "Creates FeatureStore CRs, queries features" "kubectl, HTTP/gRPC"
        platformAdmin -> feast "Configures auth, manages deployments" "kubectl"

        # Operator interactions
        feastOperator -> kubernetesAPI "Creates/manages Deployments, Services, ConfigMaps, RBAC, HPAs, PDBs, CronJobs, Routes" "HTTPS/6443"
        notebookReconciler -> kubeflowNotebooks "Injects Feast client ConfigMaps" "Kubernetes API"
        feastOperator -> prometheusOperator "Creates ServiceMonitors" "Kubernetes API"

        # Feature serving interactions
        goFeatureServer -> postgresql "Queries feature values" "TCP/pgx"
        goFeatureServer -> redis "Queries feature values" "TCP/go-redis"
        goFeatureServer -> s3 "Loads feature registry" "HTTPS/443"
        goFeatureServer -> gcs "Loads feature registry" "HTTPS/443"

        pythonFeatureServer -> postgresql "Queries/writes feature values" "TCP/psycopg"
        pythonFeatureServer -> redis "Queries/writes feature values" "TCP/redis-py"
        pythonFeatureServer -> s3 "Reads/writes registry and artifacts" "HTTPS/443"
        pythonFeatureServer -> gcs "Reads/writes registry and artifacts" "HTTPS/443"
        pythonFeatureServer -> openLineage "Emits lineage events" "HTTPS"
        pythonFeatureServer -> ray "Submits materialization jobs" "Ray protocol"

        # Security
        securityManager -> oidcProvider "Validates JWT tokens" "HTTPS"
        securityManager -> kubernetesAPI "SubjectAccessReview for K8s RBAC auth" "HTTPS/6443"

        # Internal container relationships
        pythonFeatureServer -> securityManager "Delegates auth" "Internal"
        pythonFeatureServer -> registryServer "Registry operations" "gRPC"
    }

    views {
        systemContext feast "SystemContext" {
            include *
            autoLayout
        }

        container feast "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "NoAuth" {
                background #e74c3c
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and tracks ML experiments, registers models, and deploys inference services"
        mlEngineer = person "ML Engineer" "Manages ML pipelines, monitors model performance, and configures AI Gateway endpoints"
        admin = person "Platform Admin" "Manages users, roles, workspaces, and platform configuration"

        mlflow = softwareSystem "MLflow" "Experiment tracking, model registry, and artifact management service for Red Hat OpenShift AI" {
            trackingServer = container "MLflow Tracking Server" "Hybrid ASGI/WSGI server providing REST APIs, GraphQL, OTLP ingestion, and web UI serving" "Python (FastAPI + Flask)"
            reactUI = container "MLflow React UI" "Single-page application for experiment visualization, run comparison, model registry, and prompt engineering" "TypeScript/React"
            authMiddleware = container "Auth Middleware" "Workspace-scoped RBAC enforcement with role-based permissions per resource" "Python"
            hueyQueue = container "Huey Task Queue" "Async job execution for background ML tasks using SQLite in /dev/shm" "Python"
            aiGateway = container "AI Gateway" "Proxy for LLM invocations with rate limiting and auth" "Python (FastAPI Router)"
            otlpEndpoint = container "OTLP Endpoint" "OpenTelemetry trace ingestion via HTTP (protobuf + JSON)" "Python (FastAPI Router)"
            kubePlugins = container "mlflow-kubernetes-plugins" "Kubernetes-native workspace store and authentication integration" "Python Library"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar enforcing Kubernetes RBAC before proxying to MLflow" "RHOAI Platform"
        platformGateway = softwareSystem "Platform Gateway" "Gateway API HTTPRoute-based ingress routing for RHOAI services" "RHOAI Platform"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing MLflow deployment and configuration" "RHOAI Platform"

        postgresql = softwareSystem "PostgreSQL" "Relational database for experiment tracking data, model registry, auth, and workspaces" "External"
        s3 = softwareSystem "S3/MinIO" "Object storage for ML artifacts (models, datasets, logs)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for workspace store operations and service discovery" "External"
        llmProviders = softwareSystem "LLM Providers" "External AI services (OpenAI, Anthropic, Bedrock) proxied via AI Gateway" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system scraping MLflow metrics endpoint" "RHOAI Platform"
        evalHub = softwareSystem "EvalHub" "RHOAI dashboard embedding MLflow UI components via module federation" "RHOAI Platform"

        # User interactions
        dataScientist -> mlflow "Tracks experiments, logs metrics/artifacts via Python SDK" "HTTPS/443"
        dataScientist -> reactUI "Browses experiments, compares runs, manages models" "HTTPS/443"
        mlEngineer -> mlflow "Configures AI Gateway endpoints, manages model versions" "HTTPS/443"
        admin -> mlflow "Manages users, roles, workspaces, permissions" "HTTPS/443"

        # Platform integration
        platformGateway -> kubeRbacProxy "Routes external traffic" "HTTPS/443 → 8443"
        kubeRbacProxy -> trackingServer "Forwards authenticated requests" "HTTP/5000 (localhost)"
        rhodsOperator -> mlflow "Deploys and configures MLflow" "Kubernetes API"

        # Internal container interactions
        trackingServer -> authMiddleware "Enforces workspace-scoped RBAC"
        trackingServer -> hueyQueue "Dispatches async jobs"
        trackingServer -> aiGateway "Routes gateway invocations"
        trackingServer -> otlpEndpoint "Routes OTLP trace requests"
        authMiddleware -> kubePlugins "Workspace lookup and auth check"

        # External dependencies
        trackingServer -> postgresql "Stores experiments, runs, metrics, models, auth data" "PostgreSQL/5432"
        trackingServer -> s3 "Stores and retrieves ML artifacts" "HTTPS/9000,443"
        kubePlugins -> kubernetesAPI "Workspace store operations" "HTTPS/6443"
        aiGateway -> llmProviders "Proxies LLM invocations" "HTTPS/443"

        # Platform integrations
        prometheus -> trackingServer "Scrapes metrics" "HTTP/5000 GET /metrics"
        evalHub -> reactUI "Embeds UI components via module federation" "HTTP"
    }

    views {
        systemContext mlflow "SystemContext" {
            include *
            autoLayout
        }

        container mlflow "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "RHOAI Platform" {
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

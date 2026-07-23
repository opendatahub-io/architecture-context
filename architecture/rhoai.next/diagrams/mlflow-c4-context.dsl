workspace {
    model {
        dataScientist = person "Data Scientist" "Logs experiments, manages models, and deploys inference endpoints"
        mlEngineer = person "ML Engineer" "Builds training pipelines and manages model lifecycle"
        appDeveloper = person "Application Developer" "Uses AI Gateway to integrate LLM capabilities into applications"

        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry, AI gateway, and MCP server registry for RHOAI" {
            fastApiApp = container "FastAPI Application" "Main entry point — async routes for OTLP traces, AI Gateway, MCP, jobs" "Python / FastAPI / uvicorn"
            flaskWsgi = container "Flask WSGI Application" "Legacy Tracking API v2/v3, GraphQL, AJAX, artifact proxy, webhooks" "Python / Flask"
            securityMiddleware = container "Security Middleware" "CORS blocking, host validation, security headers, auth plugin dispatch" "Python / Starlette"
            webUI = container "Web UI" "React/TypeScript browser UI for experiment visualization, model management, prompt engineering" "React / TypeScript"
            k8sPlugin = container "Kubernetes Plugins" "Workspace provider (namespace mapping) and Kubernetes auth (TokenReview)" "Python / mlflow-kubernetes-plugins"
            cli = container "MLflow CLI" "Server management, DB migrations, garbage collection, KEK rotation" "Python CLI"

            fastApiApp -> flaskWsgi "Mounts via EfficientWSGIMiddleware"
            securityMiddleware -> fastApiApp "Wraps all requests"
            k8sPlugin -> fastApiApp "Provides workspace + auth"
        }

        postgresql = softwareSystem "PostgreSQL" "Backend metadata store for experiments, runs, metrics, models, traces, workspaces, secrets, jobs" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Artifact storage for ML models, datasets, and run outputs (MinIO, AWS S3, Ceph)" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Workspace enumeration (namespace listing), authentication (TokenReview), RBAC validation" "External"
        llmProviders = softwareSystem "External LLM Providers" "OpenAI, Anthropic, and other LLM APIs proxied via AI Gateway" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact downloads from HuggingFace model hub" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Trace export destination for OTLP traces" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via prometheus-flask-exporter" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform dashboard — embeds MLflow UI via Module Federation" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator — manages MLflow Deployment, Service, ingress resources" "Internal RHOAI"
        webhookReceivers = softwareSystem "Webhook Receivers" "External systems receiving model registry event notifications" "External"

        # User interactions
        dataScientist -> mlflow "Logs experiments, metrics, artifacts via mlflow SDK" "HTTP/HTTPS :5000"
        mlEngineer -> mlflow "Manages model versions and lifecycle" "HTTP/HTTPS :5000"
        appDeveloper -> mlflow "Invokes LLM endpoints via AI Gateway" "HTTP/HTTPS :5000"

        # System dependencies
        mlflow -> postgresql "Stores experiment metadata, runs, models, traces" "PostgreSQL :5432"
        mlflow -> s3Storage "Stores and retrieves model artifacts" "HTTPS :443 / HTTP :9000"
        mlflow -> k8sApi "Workspace provider + auth (TokenReview)" "HTTPS :6443"
        mlflow -> llmProviders "Proxies LLM requests via AI Gateway" "HTTPS :443"
        mlflow -> huggingface "Downloads model artifacts" "HTTPS :443"
        mlflow -> otelCollector "Exports traces" "OTLP HTTP"
        mlflow -> webhookReceivers "Sends model registry event webhooks" "HTTPS"

        # Internal integrations
        rhoaiDashboard -> mlflow "Embeds MLflow UI components" "Module Federation (JS)"
        rhodsOperator -> mlflow "Creates and manages deployment resources" "Kubernetes API"
        prometheus -> mlflow "Scrapes metrics endpoint" "HTTP :5000"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist" "Tracks experiments, logs models, prompts and traces via UI or SDK"

        mlflow = softwareSystem "MLflow (RHOAI)" "Multi-tenant MLflow tracking server, model/prompt registry and UI; namespaces map to workspaces" {
            server = container "MLflow Tracking Server" "REST APIs (experiments, runs, traces, registry, Skills, MCP servers), artifact proxy, OTLP ingest" "Python, FastAPI + Flask on uvicorn, 5000/TCP"
            ui = container "MLflow UI" "Standalone UI and module-federated bundle for ODH Dashboard" "TypeScript/React"
            authPlugin = container "kubernetes-auth plugin" "Per-request SelfSubjectAccessReview on mlflow.kubeflow.org pseudo-resources" "Python, mlflow-kubernetes-plugins 2.1.1"
            wsProvider = container "kubernetes:// workspace provider" "Maps namespaces to workspaces, reads MLflowConfig overrides" "Python, mlflow-kubernetes-plugins 2.1.1"
            cli = container "mlflow CLI" "server, db upgrade, db fix-migration-gap" "Python"
        }

        operator = softwareSystem "MLflow Operator" "Deploys MLflow via Helm chart from MLflow CR" "Internal ODH"
        gateway = softwareSystem "ODH Data Science Gateway" "Gateway API entry point, HTTPRoute /mlflow" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Embeds MLflow UI via module federation" "Internal ODH"
        workloads = softwareSystem "Workbenches / Pipelines / Training Jobs" "MLflow SDK clients" "Internal ODH"
        k8s = softwareSystem "Kubernetes API" "SSAR, namespaces, MLflowConfig" "External"
        postgres = softwareSystem "PostgreSQL" "Backend and registry metadata store" "External"
        s3 = softwareSystem "S3-compatible Storage" "Artifact store" "External"
        webhooks = softwareSystem "Webhook Receivers" "Model registry event consumers" "External"
        llm = softwareSystem "LLM Providers" "OpenAI, Anthropic, Bedrock, ... (AI Gateway disabled by default)" "External"

        user -> gateway "Uses UI / SDK" "HTTPS/443"
        workloads -> gateway "Logs runs, traces, models" "HTTPS/443"
        gateway -> server "Forwards Bearer + X-MLFLOW-WORKSPACE" "HTTPS/5000"
        dashboard -> ui "Embeds federated bundle"
        operator -> mlflow "Deploys Deployment, Service, HTTPRoute, TLS, RBAC"
        server -> authPlugin "Wrapped by (in-process)"
        server -> wsProvider "Resolves workspace (in-process)"
        server -> ui "Serves static assets"
        authPlugin -> k8s "SelfSubjectAccessReview with caller token" "HTTPS/443"
        wsProvider -> k8s "List/watch namespaces, read MLflowConfig" "HTTPS/443"
        server -> postgres "Reads/writes metadata" "PostgreSQL/5432"
        server -> s3 "Proxies artifacts" "HTTPS/443"
        server -> webhooks "Delivers signed webhooks" "HTTPS/443 HMAC-SHA256"
        server -> llm "Only if AI Gateway enabled (disabled)" "HTTPS/443"
        cli -> postgres "Schema migrations" "PostgreSQL/5432"
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
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Person" {
                shape person
            }
        }
    }
}

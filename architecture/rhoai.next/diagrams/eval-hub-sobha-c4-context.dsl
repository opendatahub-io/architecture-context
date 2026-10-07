workspace {
    model {
        datascientist = person "Data Scientist" "Creates and monitors LLM evaluation jobs"
        platformadmin = person "Platform Admin" "Manages EvalHub deployment and tenant RBAC"

        evalhub = softwareSystem "EvalHub (eval-hub-sobha)" "Lightweight REST API for orchestrating LLM evaluations across multiple backends" {
            apiServer = container "eval-hub API Server" "Central REST API for evaluation orchestration, job lifecycle, collection/provider CRUD" "Go Service (net/http)" {
                authMiddleware = component "Auth Middleware" "TokenReview + SubjectAccessReview with endpoint-to-resource mapping" "Go Middleware"
                executionContext = component "ExecutionContext" "Threads request ID, tenant, user identity, and logger through handlers" "Go Pattern"
                k8sRuntime = component "Kubernetes Runtime" "Creates ConfigMaps and batch/v1 Jobs in tenant namespaces" "client-go"
                storageLayer = component "Storage Layer" "Pluggable storage with tenant-scoped queries (SQLite/PostgreSQL)" "Go Interface"
                mlflowClient = component "MLflow Client" "Tracks experiments and logs metrics/artifacts" "Go HTTP Client"
                metricsExporter = component "Metrics Exporter" "Prometheus metrics and OpenTelemetry tracing" "prometheus/client_golang + otel"
            }
            sidecar = container "eval_runtime_sidecar" "Reverse proxy injected into evaluation Job pods" "Go Service"
            initContainer = container "eval_runtime_init" "Downloads test data from S3 to shared volume" "Go CLI"
            lighteval = container "lighteval Adapter" "Evaluation adapter running lighteval framework" "Python Container"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages EvalHub deployment via EvalHub CR" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and metric logging" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTPS reverse proxy with mTLS and token auth" "Platform"
        k8sApi = softwareSystem "Kubernetes API" "Job/ConfigMap management, TokenReview, SAR" "Platform"
        s3 = softwareSystem "S3-Compatible Storage" "Test data and model artifact storage" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace and metric collection" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and monitoring" "Platform"

        datascientist -> kubeRbacProxy "Creates evaluation jobs" "HTTPS/443, Bearer Token"
        kubeRbacProxy -> evalhub "Forwards authenticated requests" "HTTP/8080"
        evalhub -> k8sApi "Manages Jobs, ConfigMaps, runs TokenReview/SAR" "HTTPS/6443, SA Token"
        evalhub -> mlflow "Tracks experiments and logs results" "HTTPS, Bearer Token"
        sidecar -> evalhub "Reports evaluation status events" "HTTPS, Bearer Token"
        sidecar -> mlflow "Logs evaluation metrics" "HTTPS, Bearer Token"
        initContainer -> s3 "Downloads test data" "HTTPS, AWS Credentials"
        lighteval -> sidecar "Sends evaluation results via localhost proxy" "HTTP/8080"
        evalhub -> otelCollector "Exports traces" "OTLP/gRPC"
        prometheus -> evalhub "Scrapes /metrics endpoint" "HTTP/8080"
        trustyaiOperator -> evalhub "Deploys and manages lifecycle via EvalHub CR"
        platformadmin -> trustyaiOperator "Configures EvalHub deployment"
    }

    views {
        systemContext evalhub "SystemContext" {
            include *
            autoLayout
        }

        container evalhub "Containers" {
            include *
            autoLayout
        }

        component apiServer "APIComponents" {
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
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

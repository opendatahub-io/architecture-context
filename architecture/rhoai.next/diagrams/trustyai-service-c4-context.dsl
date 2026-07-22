workspace {
    model {
        datascientist = person "Data Scientist" "Creates ML models and monitors them for fairness and drift"
        mlops = person "MLOps Engineer" "Manages model deployments and monitoring infrastructure"

        trustyai = softwareSystem "TrustyAI Service" "Python REST API for AI model monitoring: fairness metrics, drift detection, explainability, and LM evaluation" {
            fastapi = container "FastAPI Application" "REST API endpoints for data ingestion, metrics, and evaluation" "Python/FastAPI + Hypercorn"
            gzipMiddleware = container "Gzip Middleware" "Decompresses gzip-encoded request bodies with bomb protection" "Python Middleware"
            kserveConsumer = container "KServe V2 Consumer" "Ingests KServe V2 inference payloads, reconciles input/output pairs" "FastAPI Router"
            modelmeshConsumer = container "ModelMesh Consumer" "Ingests ModelMesh protobuf payloads (base64-encoded)" "FastAPI Router"
            metricsEngine = container "Metrics Engine" "Pure algorithms: SPD, DIR, KS test, Welch's t-test, batch mean" "Python (scipy, scikit-learn)"
            prometheusScheduler = container "Prometheus Scheduler" "Periodic metric computation and gauge publishing" "Python asyncio"
            prometheusPublisher = container "Prometheus Publisher" "Manages Prometheus gauge registry" "prometheus-client"
            metricsDirectory = container "Metrics Directory" "Plugin registry for metric calculator functions" "Python"
            storageInterface = container "Storage Interface" "Abstract storage layer for inference data persistence" "Python ABC"
            pvcBackend = container "PVC Storage Backend" "HDF5 file storage on persistent volumes" "h5py"
            mariadbBackend = container "MariaDB Backend" "Database-backed storage with TLS and legacy migration" "MariaDB Connector"
            lmEvalHarness = container "LM Evaluation Harness" "Subprocess-based LM benchmarking with sandboxed env" "lm-eval (optional)"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar enforcing Kubernetes RBAC via Bearer tokens" "Sidecar"
        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and configures TrustyAI Service instances via TrustyAIService CRs" "Internal RHOAI"
        kserve = softwareSystem "KServe / ModelMesh" "ML model inference serving platform providing KServe V2 protocol" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting system" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing RHOAI components and viewing model metrics" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB" "External relational database for persistent storage (optional)" "External"
        pvcStorage = softwareSystem "PVC / Persistent Volume" "Kubernetes persistent volume for HDF5 file storage" "Kubernetes"
        lmEvalAPIs = softwareSystem "LM Eval API Providers" "External LLM APIs (OpenAI, Anthropic, etc.) for model evaluation" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for health probes and RBAC" "Kubernetes"

        # User interactions
        datascientist -> rhoaiDashboard "Views fairness/drift metrics"
        mlops -> trustyaiOperator "Creates TrustyAIService CRs"

        # Operator deploys the service
        trustyaiOperator -> trustyai "Deploys, configures, injects secrets"

        # Inference data flow
        kserve -> kubeRbacProxy "Sends KServe V2 inference payloads" "HTTPS/8443"
        kubeRbacProxy -> trustyai "Forwards authenticated requests" "HTTP/8080 (loopback)"

        # Dashboard queries
        rhoaiDashboard -> kubeRbacProxy "Queries metrics and model info" "HTTPS/8443"

        # Prometheus scraping
        prometheus -> kubeRbacProxy "Scrapes /q/metrics" "HTTPS/8443"

        # Health probes
        k8sAPI -> trustyai "Liveness and readiness probes" "HTTP/8080"

        # Storage egress
        trustyai -> pvcStorage "Writes/reads HDF5 inference data" "Local I/O"
        trustyai -> mariadb "Persists inference data (optional)" "MariaDB/3306 TLS"

        # LM Eval egress
        trustyai -> lmEvalAPIs "Language model API calls (optional)" "HTTPS/443"

        # Internal container relationships
        fastapi -> gzipMiddleware "Request processing"
        gzipMiddleware -> kserveConsumer "Decompressed KServe payloads"
        gzipMiddleware -> modelmeshConsumer "Decompressed ModelMesh payloads"
        kserveConsumer -> storageInterface "Persist reconciled data"
        modelmeshConsumer -> storageInterface "Persist reconciled data"
        fastapi -> metricsEngine "On-demand metric computation"
        metricsEngine -> storageInterface "Read inference data"
        prometheusScheduler -> metricsDirectory "Lookup registered metrics"
        prometheusScheduler -> metricsEngine "Compute scheduled metrics"
        prometheusScheduler -> prometheusPublisher "Update gauge values"
        storageInterface -> pvcBackend "PVC mode"
        storageInterface -> mariadbBackend "MariaDB mode"
        lmEvalHarness -> lmEvalAPIs "Subprocess API calls"
    }

    views {
        systemContext trustyai "SystemContext" {
            include *
            autoLayout
        }

        container trustyai "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Sidecar" {
                background #d79b00
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
        }
    }
}

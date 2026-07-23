workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, monitors model performance"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures monitoring"

        trustyaiService = softwareSystem "TrustyAI Service" "Python REST API for AI model monitoring: drift detection, fairness metrics, explainability, and LLM evaluation" {
            apiLayer = container "API Layer (FastAPI)" "REST API endpoints for consumers, metrics, info, explainers, and LM evaluation" "Python FastAPI"
            coreAlgorithms = container "Core Algorithms" "Pure metric algorithms: KS-Test, CompareMeans, Jensen-Shannon, FourierMMD, SPD, DIR" "Python scipy/scikit-learn"
            serviceLayer = container "Service Infrastructure" "Storage backends (HDF5/MariaDB), Prometheus publishing, scheduling, serialization" "Python"
            gzipMiddleware = container "Gzip Middleware" "Decompresses gzip-encoded request bodies" "Python ASGI Middleware"
            promScheduler = container "Prometheus Scheduler" "Asyncio background task computing metrics on 30s interval" "Python asyncio"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar proxy enforcing Kubernetes RBAC" "Auth Proxy"
        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and configures TrustyAI Service instances, provisions TLS certs" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform sending inference payloads" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving runtime sending inference payloads" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        openshiftDashboard = softwareSystem "OpenShift AI Dashboard" "Web UI for model management and monitoring" "Internal RHOAI"
        pvc = softwareSystem "PersistentVolumeClaim" "HDF5 file storage for inference data" "Infrastructure"
        mariadb = softwareSystem "MariaDB" "Optional relational storage backend" "External"
        llmEndpoint = softwareSystem "LLM Inference Endpoint" "Remote LLM for evaluation harness jobs" "External"

        # Relationships - External
        dataScientist -> openshiftDashboard "Monitors model fairness and drift via"
        platformAdmin -> trustyaiOperator "Configures TrustyAI via"
        openshiftDashboard -> kubeRbacProxy "Queries model info and triggers metrics" "HTTPS/8443"
        kserve -> kubeRbacProxy "Sends inference CloudEvent payloads" "HTTPS/8443"
        modelMesh -> kubeRbacProxy "Sends protobuf inference payloads" "HTTPS/8443"
        kubeRbacProxy -> trustyaiService "Forwards after RBAC validation" "HTTP/8080 loopback"
        trustyaiOperator -> trustyaiService "Deploys and configures" "Kubernetes API"
        prometheus -> kubeRbacProxy "Scrapes /q/metrics" "HTTPS/8443"

        # Relationships - Internal
        apiLayer -> gzipMiddleware "Passes requests through"
        apiLayer -> coreAlgorithms "Calls metric algorithms"
        apiLayer -> serviceLayer "Uses storage and data access"
        promScheduler -> coreAlgorithms "Computes scheduled metrics"
        promScheduler -> serviceLayer "Reads data, publishes metrics"

        # Relationships - Egress
        trustyaiService -> pvc "Stores inference data as HDF5 files" "Filesystem"
        trustyaiService -> mariadb "Optional: stores inference data" "MySQL/3306 TLS"
        trustyaiService -> llmEndpoint "Optional: LM evaluation targets" "HTTPS"
    }

    views {
        systemContext trustyaiService "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiService "Containers" {
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
            element "Auth Proxy" {
                background #e74c3c
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

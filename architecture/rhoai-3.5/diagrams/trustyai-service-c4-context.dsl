workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, deploys, and monitors ML models for fairness and drift"
        platformAdmin = person "Platform Admin" "Manages OpenShift AI platform and monitoring configuration"

        trustyaiService = softwareSystem "TrustyAI Service" "REST API for AI model monitoring: drift detection, fairness metrics, explainability, and LLM evaluation" {
            endpointLayer = container "Endpoint Layer" "REST API endpoints for metrics, data ingestion, info, and evaluation" "Python FastAPI"
            serviceLayer = container "Service Layer" "Storage management, Prometheus scheduling, and data access" "Python"
            coreLibrary = container "Core Metrics Library" "Pure algorithm implementations for drift and fairness metrics" "Python (scikit-learn, scipy)"
            prometheusScheduler = container "Prometheus Scheduler" "Periodic computation and publishing of scheduled metrics as Prometheus gauges" "Python asyncio"
            storageInterface = container "Storage Interface" "Pluggable storage backends for inference data persistence" "Python (h5py, mariadb)"
            lmEvalRunner = container "LM Eval Runner" "Job management for LLM benchmarking via isolated subprocess execution" "Python subprocess"
        }

        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and configures TrustyAI Service instances per namespace" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform providing inference services" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform with payload processing" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar enforcing Kubernetes RBAC" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "Internal Platform"
        dashboard = softwareSystem "OpenShift AI Dashboard" "Web UI for managing AI/ML workloads" "Internal RHOAI"
        mariaDB = softwareSystem "MariaDB" "Optional relational database for inference data storage" "External"
        pvcStorage = softwareSystem "PVC / HDF5 Storage" "Default persistent volume storage for inference data" "Infrastructure"
        llmEndpoints = softwareSystem "LLM Inference Endpoints" "Target model servers for LLM evaluation benchmarking" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for RBAC and resource management" "Infrastructure"

        # User interactions
        dataScientist -> trustyaiService "Requests fairness/drift metrics, schedules recurring evaluations" "HTTPS/8443"
        dataScientist -> dashboard "Views TrustyAI metrics and model monitoring status" "HTTPS"
        platformAdmin -> trustyaiOperator "Configures TrustyAI Service deployments" "kubectl/HTTPS"

        # Inbound data flows
        kserve -> trustyaiService "Sends inference cloud events for input/output reconciliation" "HTTPS/8443"
        modelMesh -> trustyaiService "Sends KServe v2 format payloads (base64 protobuf)" "HTTPS/8443"

        # Authentication
        kubeRBACProxy -> trustyaiService "Forwards pre-authenticated requests" "HTTP/8080 loopback"
        kubeRBACProxy -> kubernetesAPI "SubjectAccessReview for Bearer Token validation" "HTTPS"

        # Internal integrations
        trustyaiOperator -> trustyaiService "Deploys, configures TLS, storage, ServiceMonitor" "Kubernetes API"
        dashboard -> trustyaiService "REST calls for metrics display and scheduling" "HTTPS/8443"
        prometheus -> trustyaiService "Scrapes /q/metrics for trustyai_* gauges" "HTTPS/8443"

        # Storage backends
        trustyaiService -> pvcStorage "Reads/writes HDF5 inference data files" "Filesystem I/O"
        trustyaiService -> mariaDB "Persists inference data (optional backend)" "MySQL/3306 TLS"

        # LM Eval
        trustyaiService -> llmEndpoints "Runs LLM evaluation benchmarks via subprocess" "HTTP/HTTPS"

        # Container-level relationships
        endpointLayer -> serviceLayer "Delegates data access and metric computation"
        endpointLayer -> coreLibrary "Invokes metric algorithms"
        serviceLayer -> storageInterface "Reads/writes inference data"
        prometheusScheduler -> serviceLayer "Reads data for scheduled metric computation"
        prometheusScheduler -> coreLibrary "Computes scheduled metrics"
        lmEvalRunner -> llmEndpoints "Executes LLM evaluations via isolated subprocess" "HTTP/HTTPS"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #ffffff
            }
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
        }
    }
}

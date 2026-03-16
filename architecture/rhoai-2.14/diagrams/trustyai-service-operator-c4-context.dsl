workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and monitors ML models for fairness and bias"
        mlEngineer = person "ML Engineer" "Deploys and configures TrustyAI services for model explainability"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Kubernetes operator that manages TrustyAI service deployments for AI/ML model explainability, fairness monitoring, and bias detection" {
            controller = container "Operator Controller Manager" "Reconciles TrustyAIService CRDs and manages lifecycle" "Go Operator" {
                reconciler = component "Reconciliation Loop" "Watches TrustyAIService CRs and creates resources" "controller-runtime"
                kserveWatcher = component "KServe Integration" "Watches and patches InferenceServices" "Go"
            }

            trustyaiService = container "TrustyAI Service" "Provides explainability and fairness metrics" "Quarkus Application" {
                api = component "REST API" "HTTP API for bias detection and explainability" "Quarkus REST"
                metricsEngine = component "Metrics Engine" "Calculates fairness metrics (SPD, DIR)" "Java"
                storage = component "Storage Layer" "Persists data to PVC or Database" "JPA/Hibernate"
            }

            oauthProxy = container "OAuth Proxy" "Authentication layer for external access" "OAuth Proxy Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with Routes and OAuth" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "OpenDataHub/RHOAI web console" "Internal RHOAI"
        database = softwareSystem "External Database" "PostgreSQL/MySQL database for persistent storage" "External"

        # Relationships - Users
        dataScientist -> trustyaiOperator "Creates TrustyAIService resources to monitor models" "kubectl/OpenShift Console"
        mlEngineer -> trustyaiOperator "Configures fairness metrics and thresholds" "kubectl/API"
        dataScientist -> dashboard "Views bias detection results and metrics" "HTTPS/443"

        # Relationships - Operator Internal
        controller -> kubernetes "Manages Kubernetes resources (Deployments, Services, Routes, PVCs)" "HTTPS/6443"
        controller -> trustyaiService "Creates and manages instances" "K8s API"
        controller -> oauthProxy "Deploys as sidecar for authentication" "Pod Spec"

        # Relationships - External Dependencies
        trustyaiOperator -> kubernetes "Uses for container orchestration and resource management" "HTTPS/6443"
        trustyaiOperator -> openshift "Uses Routes for external access and OAuth for authentication" "HTTPS/6443"
        trustyaiOperator -> prometheus "Exposes metrics via ServiceMonitor" "HTTP/80"

        # Relationships - Internal RHOAI
        trustyaiOperator -> kserve "Watches InferenceServices and patches for monitoring" "K8s API Watch/Patch"
        trustyaiOperator -> modelMesh "Injects payload processor configuration" "Env Var Injection"
        modelMesh -> trustyaiService "Sends inference payloads for bias detection" "HTTP/80"
        dashboard -> trustyaiOperator "Manages TrustyAI instances via UI" "K8s API"

        # Relationships - Data Flow
        trustyaiService -> database "Stores metrics and data (DATABASE mode)" "JDBC/TLS"
        trustyaiService -> kubernetes "Mounts PersistentVolume (PVC mode)" "Volume Mount"
        prometheus -> trustyaiService "Scrapes fairness metrics (trustyai_spd, trustyai_dir)" "HTTP/80 /q/metrics"

        # Relationships - Authentication
        oauthProxy -> openshift "Validates OAuth tokens" "OAuth Protocol"
        oauthProxy -> trustyaiService "Proxies authenticated requests" "HTTP/8080 localhost"
    }

    views {
        systemContext trustyaiOperator "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiOperator "Containers" {
            include *
            autoLayout
        }

        component controller "OperatorComponents" {
            include *
            autoLayout
        }

        component trustyaiService "TrustyAIServiceComponents" {
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
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #50e3c2
                color #000000
            }
            element "Component" {
                background #f5a623
                color #000000
            }
        }

        theme default
    }
}

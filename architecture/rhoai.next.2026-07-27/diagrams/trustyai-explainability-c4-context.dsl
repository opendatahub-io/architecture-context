workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and monitors fairness/explainability"
        mlEngineer = person "ML Engineer" "Configures and operates model serving infrastructure"

        trustyai = softwareSystem "TrustyAI Explainability" "AI model fairness monitoring and explainability service (Quarkus)" {
            service = container "trustyai-service" "Intercepts KServe inference payloads, computes fairness metrics, stores inference data" "Quarkus (Java)"
            initContainer = container "config-map-overrider" "Creates model-serving-config ConfigMap to register TrustyAI as KServe payload processor" "Init Container"
            pvc = container "trustyai-service-pvc" "Persists inference data for fairness analysis" "PersistentVolumeClaim" "Storage"
            configMap = container "trustyai-config" "Runtime configuration: storage format, batch size, data format, metrics scheduling" "ConfigMap" "Configuration"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Model serving infrastructure that routes inference payloads" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes control plane" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress via OpenShift Routes" "External"

        # User interactions
        dataScientist -> trustyai "Views fairness metrics and explainability results"
        mlEngineer -> trustyai "Configures TrustyAI service and monitors operations"

        # Internal container relationships
        initContainer -> openshiftAPI "Creates model-serving-config ConfigMap" "HTTPS/443, SA token"
        service -> pvc "Stores inference data" "Filesystem /inputs"
        service -> configMap "Reads runtime configuration"

        # External system interactions
        kserve -> trustyai "Sends inference payloads" "HTTP POST /consumer/kserve/v2, 8080/TCP"
        prometheus -> trustyai "Scrapes metrics" "HTTP GET /q/metrics, 8080/TCP"
        openshiftRouter -> trustyai "Routes external traffic" "HTTP, 80/TCP → 8080/TCP"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Storage" {
                shape cylinder
                background #f5a623
                color #333333
            }
            element "Configuration" {
                background #ffe6cc
                color #333333
            }
        }
    }
}

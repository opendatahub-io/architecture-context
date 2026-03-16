workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and monitors AI/ML models for fairness and explainability"
        sre = person "SRE / Platform Admin" "Deploys and manages TrustyAI services"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages lifecycle of TrustyAI service instances for AI/ML model explainability and bias detection" {
            controller = container "Operator Controller" "Reconciles TrustyAIService CRDs and manages all Kubernetes resources" "Go Operator" {
                reconciler = component "TrustyAIService Reconciler" "Main reconciliation logic" "Go"
                serviceMonitorCtrl = component "ServiceMonitor Controller" "Creates Prometheus ServiceMonitors" "Go"
                inferenceHandler = component "InferenceService Handler" "Patches KServe InferenceServices" "Go"
                storageManager = component "Storage Manager" "Manages PVC/DB configuration" "Go"
                routeController = component "Route Controller" "Creates OpenShift Routes" "Go"
                istioController = component "Istio Integration" "Manages VirtualServices/DestinationRules" "Go"
            }

            trustyaiService = container "TrustyAI Service (Managed)" "Deployed service instance with OAuth proxy" "Quarkus + OAuth Proxy" {
                serviceContainer = component "TrustyAI Service Container" "Fairness metrics computation and data storage" "Java/Quarkus"
                oauthProxy = component "OAuth Proxy Sidecar" "OpenShift authentication" "Go"
            }
        }

        k8s = softwareSystem "Kubernetes API" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift Platform" "Enhanced Kubernetes platform with Routes, OAuth, service-serving certs" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and mTLS" "External"
        modelMesh = softwareSystem "Model Mesh" "Multi-model serving platform" "Internal RHOAI"
        pvcStorage = softwareSystem "Persistent Volume Storage" "Kubernetes PVC-based storage" "External"
        database = softwareSystem "PostgreSQL/MariaDB" "Relational database for inference data" "External"

        # User interactions
        sre -> trustyaiOperator "Creates TrustyAIService CR via kubectl/OpenShift Console"
        user -> trustyaiService "Accesses TrustyAI service via OpenShift Route" "HTTPS/443 (OAuth)"

        # Operator interactions
        trustyaiOperator -> k8s "Watches TrustyAIService CRDs, manages resources" "HTTPS/6443 (ServiceAccount token)"
        trustyaiOperator -> openshift "Creates Routes, uses service-serving certs, OAuth integration" "HTTPS/6443"
        trustyaiOperator -> kserve "Patches InferenceServices with payload processor config" "Kubernetes API"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics scraping" "Kubernetes API"
        trustyaiOperator -> istio "Creates VirtualServices and DestinationRules" "Kubernetes API"

        # TrustyAI service interactions
        trustyaiService -> prometheus "Exposes fairness metrics (SPD, DIR)" "HTTP/80 (Bearer token)"
        kserve -> trustyaiService "Sends inference payload data for monitoring" "HTTP/HTTPS (mTLS in mesh)"
        modelMesh -> trustyaiService "Sends inference payload data for monitoring" "HTTP/HTTPS"
        trustyaiService -> pvcStorage "Stores inference data (PVC mode)" "Filesystem"
        trustyaiService -> database "Stores inference data (DATABASE mode)" "JDBC/TLS"
        openshift -> trustyaiService "Routes external traffic, provides OAuth" "HTTPS"
        istio -> trustyaiService "Routes service mesh traffic with mTLS" "HTTP/HTTPS"

        # Prometheus interactions
        prometheus -> trustyaiService "Scrapes /q/metrics endpoint" "HTTP/80"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

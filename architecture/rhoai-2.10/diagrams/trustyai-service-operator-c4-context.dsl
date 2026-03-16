workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates TrustyAI services to monitor model fairness and explainability"
        admin = person "Platform Admin" "Installs and manages the TrustyAI Service Operator"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Kubernetes operator that automates deployment and lifecycle management of TrustyAI services for AI/ML model explainability and fairness monitoring" {
            controller = container "Operator Controller" "Reconciles TrustyAIService CRDs and manages service lifecycle" "Go Operator" {
                reconciler = component "TrustyAIService Reconciler" "Watches TrustyAIService CRs and creates/updates resources" "Go Controller"
                inferenceWatcher = component "InferenceService Watcher" "Monitors KServe InferenceServices for ModelMesh integration" "Go Controller"
            }

            trustyaiService = container "TrustyAI Service (Managed)" "Provides explainability and fairness metrics for ML models" "Quarkus Application" {
                metricsAPI = component "Metrics API" "Exposes fairness and explainability metrics" "REST API"
                dataCollector = component "Data Collector" "Receives and stores inference payloads" "Quarkus Service"
            }

            oauthProxy = container "OAuth Proxy Sidecar" "Provides OpenShift OAuth authentication" "OpenShift OAuth Proxy"
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External Platform"
        kserve = softwareSystem "KServe" "Model serving platform for Kubernetes" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "High-density model serving framework" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        oauthServer = softwareSystem "OpenShift OAuth Server" "OpenShift authentication service" "External Platform"
        serviceCa = softwareSystem "service-ca" "OpenShift certificate authority for services" "External Platform"
        storage = softwareSystem "Persistent Storage" "Kubernetes persistent volumes" "External Platform"
        registry = softwareSystem "Container Registries" "Quay.io, Red Hat Registry" "External"

        # Relationships
        user -> trustyaiOperator "Creates TrustyAIService CRs to deploy monitoring services"
        admin -> trustyaiOperator "Installs operator via OLM/kubectl"

        trustyaiOperator -> kubernetes "Creates and manages Deployments, Services, Routes, PVCs" "Kubernetes API / HTTPS 6443"
        trustyaiOperator -> kserve "Watches InferenceServices and ServingRuntimes" "Kubernetes API / HTTPS 6443"
        trustyaiOperator -> modelmesh "Patches ModelMesh deployments with payload processor config" "Kubernetes API / HTTPS 6443"

        modelmesh -> trustyaiService "Forwards inference payloads for analysis" "HTTP/80"
        trustyaiService -> storage "Stores inference data and model metadata" "PVC mount"
        trustyaiService -> oauthServer "Validates user tokens" "HTTPS/443"

        prometheus -> trustyaiService "Scrapes fairness and explainability metrics" "HTTP/80"

        oauthProxy -> oauthServer "Validates OAuth tokens and performs Subject Access Review" "HTTPS/443"
        oauthProxy -> trustyaiService "Proxies authenticated requests" "HTTP/8080 localhost"

        serviceCa -> oauthProxy "Injects TLS certificates for HTTPS service" "Certificate injection"

        user -> oauthProxy "Accesses TrustyAI service via OpenShift Route" "HTTPS/443"

        trustyaiOperator -> registry "Pulls operator and service container images" "HTTPS/443"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #cccccc
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
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

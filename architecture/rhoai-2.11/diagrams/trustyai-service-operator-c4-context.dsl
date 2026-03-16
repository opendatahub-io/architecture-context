workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and monitors AI models for fairness and explainability"
        odadmin = person "ODH Administrator" "Deploys and manages TrustyAI service instances"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI service deployments for AI model explainability, fairness monitoring, and bias detection" {
            controller = container "TrustyAI Controller" "Reconciles TrustyAIService CRDs and manages lifecycle" "Go Operator" {
                reconciler = component "TrustyAIServiceReconciler" "Main reconciliation controller" "Controller"
                pvcManager = component "PVC Manager" "Provisions persistent storage" "Storage Controller"
                routeManager = component "Route Manager" "Manages OpenShift Routes" "Network Controller"
                smManager = component "ServiceMonitor Manager" "Creates Prometheus ServiceMonitors" "Metrics Controller"
                isIntegrator = component "InferenceService Integrator" "Patches KServe InferenceServices" "Integration Controller"
            }

            trustyaiService = container "TrustyAI Service Instance" "Core explainability and fairness monitoring service" "Java/Quarkus" {
                apiServer = component "REST API Server" "Exposes explainability and fairness APIs" "HTTP Server"
                metricsCollector = component "Metrics Collector" "Collects and processes inference metrics" "Service"
                biasDetector = component "Bias Detector" "Analyzes data for bias and fairness issues" "Service"
                explainabilityEngine = component "Explainability Engine" "Generates model explanations (LIME, SHAP)" "Service"
            }

            oauthProxy = container "OAuth Proxy" "Provides OpenShift authentication" "OAuth Proxy Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with OAuth and Routes" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus via ServiceMonitors" "External"

        kserve = softwareSystem "KServe" "Model serving platform for ML inference" "Internal ODH"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"
        serviceCa = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External"

        storage = softwareSystem "Persistent Storage" "Stores inference data and metrics" "External"

        # User interactions
        dataScientist -> trustyaiService "Accesses fairness metrics and explainability results via" "HTTPS/443 OAuth"
        dataScientist -> odhDashboard "Monitors models via" "HTTPS/443"
        odadmin -> kubernetes "Creates TrustyAIService CRs via" "kubectl"
        odadmin -> odhDashboard "Manages TrustyAI instances via" "HTTPS/443"

        # Operator interactions
        controller -> kubernetes "Watches TrustyAIService CRs and manages resources via" "HTTPS/6443"
        controller -> trustyaiService "Creates and manages" "API"
        controller -> oauthProxy "Deploys as sidecar" "Container"
        controller -> kserve "Patches InferenceServices with payload processors via" "HTTPS/6443"
        controller -> modelMesh "Configures MM_PAYLOAD_PROCESSORS via" "Environment Variables"
        controller -> prometheusOperator "Creates ServiceMonitors via" "CRD"
        controller -> serviceCa "Requests TLS certificates via" "Service Annotation"

        # TrustyAI Service interactions
        trustyaiService -> storage "Stores metrics and inference data in" "PVC"
        trustyaiService -> prometheus "Exposes metrics to" "HTTP/80"
        oauthProxy -> openshift "Authenticates users via" "OAuth 2.0"
        oauthProxy -> trustyaiService "Forwards authenticated requests to" "HTTP/8080"

        # Integration flows
        kserve -> trustyaiService "Sends inference payloads for monitoring via" "HTTP/80"
        modelMesh -> trustyaiService "Forwards inference data via payload processor" "HTTP/80"
        prometheus -> trustyaiService "Scrapes /q/metrics from" "HTTP/80"
        prometheus -> controller "Scrapes operator metrics from" "HTTP/8080"

        # Dashboard integration
        odhDashboard -> controller "Triggers TrustyAI service creation via" "Kubernetes API"

        # Service CA
        serviceCa -> oauthProxy "Provisions TLS certificates for" "Auto-rotation"
        serviceCa -> trustyaiService "Provisions internal TLS certificates for" "Auto-rotation"
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

        component controller "ControllerComponents" {
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
            element "Internal ODH" {
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
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}

workspace {
    model {
        user = person "Data Scientist" "Creates and monitors ML models for fairness and bias"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI explainability services for AI/ML model monitoring" {
            controller = container "Operator Controller" "Reconciles TrustyAIService CRs and manages deployments" "Go Operator"
            trustyaiService = container "TrustyAI Service" "Provides AI explainability and fairness metrics" "Quarkus Java Service"
            oauthProxy = container "OAuth Proxy" "Authenticates user requests via OpenShift OAuth" "OAuth Proxy Sidecar"
            storage = container "PVC Storage" "Stores inference payloads and metrics data" "Persistent Volume"
        }

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Provides Route, OAuth, and TLS services" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kserve = softwareSystem "KServe" "ML model serving platform" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh" "Multi-model serving runtime" "Internal RHOAI"

        # User interactions
        user -> trustyaiOperator "Creates TrustyAIService CR via kubectl/oc"
        user -> oauthProxy "Accesses TrustyAI UI and APIs" "HTTPS/443 via OpenShift Route"

        # Operator interactions
        controller -> kubernetes "Watches CRs and manages resources" "HTTPS/6443"
        controller -> trustyaiService "Creates and manages deployments" "Kubernetes API"
        controller -> kserve "Patches InferenceService logger configuration" "HTTPS/6443"
        controller -> modelmesh "Injects MM_PAYLOAD_PROCESSORS env variable" "HTTPS/6443"

        # OAuth flow
        oauthProxy -> openshift "Authenticates users via OAuth" "HTTPS/443"
        oauthProxy -> kubernetes "Validates permissions via SubjectAccessReview" "HTTPS/6443"
        oauthProxy -> trustyaiService "Forwards authenticated requests" "HTTP/8080"

        # TrustyAI service interactions
        trustyaiService -> storage "Stores inference data and metrics" "Filesystem"
        kserve -> trustyaiService "Sends inference payloads" "HTTP/8080 POST /consumer/kserve/v2"
        prometheus -> trustyaiService "Scrapes fairness metrics" "HTTP/80 GET /q/metrics"

        # External dependencies
        trustyaiOperator -> kubernetes "Uses for orchestration" "HTTPS/6443"
        trustyaiOperator -> openshift "Uses for routing and authentication" "HTTPS/443"
        trustyaiOperator -> prometheus "Exposes metrics via ServiceMonitor" "HTTP/80"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

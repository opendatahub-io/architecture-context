workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and monitors AI/ML models for fairness and explainability"
        admin = person "Platform Administrator" "Deploys and configures TrustyAI services"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages deployment and lifecycle of TrustyAI services for AI explainability and fairness monitoring on Kubernetes/OpenShift" {
            operator = container "TrustyAI Operator Controller" "Reconciles TrustyAIService CRs and manages resources" "Go Operator" {
                tags "Operator"
            }
            trustyaiService = container "TrustyAI Service" "Provides AI explainability and fairness metrics analysis" "Quarkus/Java" {
                tags "Service"
            }
            oauthProxy = container "OAuth Proxy" "Handles authentication and TLS termination for external access" "Go Sidecar" {
                tags "Proxy"
            }
            storage = container "Persistent Storage" "Stores inference data and computed metrics" "PVC" {
                tags "Storage"
            }
        }

        %% External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External Platform" {
            tags "External"
        }
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with Routes and OAuth" "External Platform" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager / OpenShift Service CA" "TLS certificate provisioning" "External Security" {
            tags "External"
        }

        %% Internal ODH/RHOAI Dependencies
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH" {
            tags "Internal ODH"
        }
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving runtime" "Internal ODH" {
            tags "Internal ODH"
        }
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for Open Data Hub" "Internal ODH" {
            tags "Internal ODH"
        }

        %% User interactions
        user -> trustyai "Views fairness/explainability metrics via"
        admin -> trustyai "Creates TrustyAIService CR via kubectl/Dashboard"
        user -> odhDashboard "Accesses TrustyAI metrics from"

        %% External dependencies
        trustyai -> kubernetes "Runs on, uses API for resource management" "HTTPS/6443 TLS 1.2+"
        trustyai -> openshift "Uses Routes and OAuth for external access" "HTTPS/6443 TLS 1.2+"
        trustyai -> certManager "Obtains TLS certificates from"
        prometheus -> trustyai "Scrapes metrics from" "HTTP/80"

        %% Internal ODH interactions
        trustyai -> kserve "Configures inference loggers on InferenceServices" "API patch HTTPS/6443"
        kserve -> trustyai "Sends inference payloads to" "HTTP/80"
        trustyai -> modelMesh "Configures payload processor via env vars" "API patch HTTPS/6443"
        modelMesh -> trustyai "Sends inference payloads to" "HTTP/80"
        odhDashboard -> trustyai "Displays metrics from"

        %% Container relationships
        operator -> trustyaiService "Creates and manages"
        operator -> oauthProxy "Creates and manages"
        operator -> storage "Provisions"
        oauthProxy -> trustyaiService "Proxies authenticated requests to" "HTTP/8080"
        trustyaiService -> storage "Stores inference data to"
        oauthProxy -> openshift "Authenticates users via OAuth" "HTTPS/6443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Proxy" {
                background #f5a623
                color #ffffff
            }
            element "Storage" {
                background #bd10e0
                color #ffffff
                shape Cylinder
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }

        theme default
    }
}

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and monitors AI models for bias and fairness"
        admin = person "Platform Administrator" "Manages TrustyAI service deployments"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages deployment and lifecycle of TrustyAI explainability services for AI model monitoring and bias detection" {
            operator = container "TrustyAI Operator Controller" "Reconciles TrustyAIService CRDs and manages service lifecycle" "Go Controller-Runtime"
            service = container "TrustyAI Service" "Provides AI explainability and bias detection metrics" "Quarkus Application"
            oauthProxy = container "OAuth Proxy" "Provides OpenShift OAuth authentication for service access" "Go Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with integrated authentication and routing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH/RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform for inference workloads" "Internal ODH/RHOAI"
        modelMesh = softwareSystem "Model Mesh" "Multi-model serving system" "Internal ODH/RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for Open Data Hub components" "Internal ODH/RHOAI"
        database = softwareSystem "Database (PostgreSQL/MySQL)" "Persistent storage for model inference data" "External (Optional)"
        s3Storage = softwareSystem "S3 Storage" "Model artifact storage" "External"

        # User interactions
        admin -> trustyai "Creates and manages TrustyAIService resources via kubectl/oc"
        user -> trustyai "Accesses bias metrics and explainability reports" "HTTPS/443 (OAuth)"

        # TrustyAI interactions
        trustyai -> kubernetes "Manages deployments, services, and resources" "Kubernetes API (HTTPS/6443)"
        trustyai -> openshift "Creates Routes for external access, uses OAuth for authentication" "OpenShift API (HTTPS/6443)"
        trustyai -> prometheus "Exposes fairness metrics (SPD, DIR)" "ServiceMonitor (HTTP/80)"
        trustyai -> kserve "Patches InferenceServices to inject payload processors" "Kubernetes API (HTTPS/6443)"
        trustyai -> modelMesh "Configures MM_PAYLOAD_PROCESSORS environment variables" "Kubernetes API (HTTPS/6443)"
        trustyai -> database "Stores model inference data (optional)" "JDBC (3306/5432, TLS optional)"

        # Integration from other systems
        odhDashboard -> trustyai "Discovers TrustyAI routes for dashboard integration" "Route Discovery"
        kserve -> service "Sends inference payloads for bias analysis" "HTTPS/443 (Service Cert)"
        modelMesh -> service "Sends model payloads for monitoring" "HTTPS/443 (Service Cert)"
        prometheus -> service "Scrapes metrics" "HTTP/80"

        # Container-level interactions
        operator -> kubernetes "Watches TrustyAIService CRDs, creates resources" "HTTPS/6443 (SA Token)"
        operator -> service "Creates and manages" "Kubernetes API"
        operator -> oauthProxy "Creates and configures" "Kubernetes API"
        oauthProxy -> openshift "Validates OAuth tokens" "HTTPS/443 (OAuth 2.0)"
        oauthProxy -> service "Proxies authenticated requests" "HTTP/8080 (localhost)"
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
            element "Internal ODH/RHOAI" {
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
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

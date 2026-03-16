workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and monitors ML models for fairness and explainability"
        admin = person "Platform Administrator" "Manages TrustyAI service deployments and LMEval jobs"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI services for ML model explainability, fairness monitoring, and language model evaluation" {
            operator = container "TrustyAI Operator" "Reconciles TrustyAIService and LMEvalJob CRs" "Go Operator"
            trustyaiService = container "TrustyAI Service" "Provides explainability and fairness metrics" "Quarkus Application"
            oauthProxy = container "OAuth Proxy" "Secures external API access" "OAuth Proxy Sidecar"
            lmevalJob = container "LMEval Job" "Executes language model evaluation tasks" "Batch Job"
            driver = container "LMEval Driver" "Manages job execution lifecycle" "Init Container"
        }

        kserve = softwareSystem "KServe" "Model inference serving platform" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving runtime" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        openshift = softwareSystem "OpenShift" "Container platform with Routes and OAuth" "External"
        kueue = softwareSystem "Kueue" "Job queue management system" "External"
        database = softwareSystem "Database" "Persistent storage for TrustyAI metrics" "PostgreSQL/MySQL"
        huggingface = softwareSystem "Hugging Face Hub" "Language model and dataset repository" "External"
        odhdashboard = softwareSystem "ODH Dashboard" "Web UI for Open Data Hub platform" "Internal RHOAI"

        # User interactions
        user -> trustyaiOperator "Creates TrustyAIService and LMEvalJob CRs via kubectl"
        admin -> trustyaiOperator "Manages TrustyAI deployments and monitors jobs"
        user -> odhdashboard "Accesses TrustyAI services via web UI"

        # Operator relationships
        operator -> kserve "Watches InferenceServices and patches with TrustyAI payload processor" "HTTPS/6443"
        operator -> modelMesh "Patches deployments with TrustyAI integration" "HTTPS/6443"
        operator -> istio "Creates VirtualServices and DestinationRules" "HTTPS/6443"
        operator -> openshift "Creates Routes for external access" "HTTPS/6443"
        operator -> kueue "Creates Workloads for LMEvalJobs" "HTTPS/6443"
        operator -> prometheus "Creates ServiceMonitors" "HTTPS/6443"

        # TrustyAI Service relationships
        modelMesh -> trustyaiService "Sends inference payloads for monitoring" "HTTPS/443 mTLS"
        kserve -> trustyaiService "Monitored for fairness and explainability" "Integration"
        trustyaiService -> database "Stores inference data and metrics" "JDBC TLS1.2+"
        oauthProxy -> trustyaiService "Forwards authenticated requests" "HTTP/8080"
        prometheus -> trustyaiService "Scrapes fairness and explainability metrics" "HTTP/80"

        # External access
        user -> oauthProxy "Accesses TrustyAI API" "HTTPS/443 OAuth"
        openshift -> oauthProxy "Routes external traffic" "HTTPS"

        # LMEval relationships
        driver -> lmevalJob "Manages execution lifecycle" "Shared Volume"
        lmevalJob -> huggingface "Downloads models and datasets" "HTTPS/443"
        lmevalJob -> database "Stores evaluation results" "PVC or JDBC"

        # Service discovery
        odhdashboard -> trustyaiService "Discovers and displays TrustyAI services" "Service Discovery"
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

    configuration {
        scope softwaresystem
    }
}

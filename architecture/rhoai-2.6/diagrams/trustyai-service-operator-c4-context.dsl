workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and monitors ML models for fairness and bias"
        platformAdmin = person "Platform Administrator" "Deploys and manages TrustyAI service instances"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Kubernetes operator that manages deployment and lifecycle of TrustyAI explainability and bias monitoring services" {
            operatorManager = container "Operator Manager" "Reconciles TrustyAIService CRs and manages deployed resources" "Go Operator (Kubebuilder)"
            trustyaiService = container "TrustyAI Service" "Provides explainability and bias metrics for ML models" "Quarkus Java Service"
            oauthProxy = container "OAuth Proxy" "Authenticates requests to TrustyAI service" "OpenShift OAuth Proxy"
            storage = container "Persistent Storage" "Stores inference data and metrics" "PersistentVolumeClaim"
        }

        kubernetes = softwareSystem "Kubernetes API" "Cluster orchestration and resource management" "External"
        openshift = softwareSystem "OpenShift" "Extended Kubernetes platform with Routes and OAuth" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH"
        modelMesh = softwareSystem "Model Mesh" "Multi-model serving system" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"

        # User interactions
        platformAdmin -> trustyaiOperator "Creates TrustyAIService CR via kubectl"
        dataScientist -> trustyaiService "Accesses explainability metrics via HTTPS"

        # Operator interactions
        operatorManager -> kubernetes "Watches CRDs and manages resources" "HTTPS/6443"
        operatorManager -> trustyaiService "Deploys and configures" "CR Reconciliation"
        operatorManager -> storage "Provisions PVCs" "Kubernetes API"
        operatorManager -> kserve "Watches InferenceService CRs" "HTTPS/6443"
        operatorManager -> modelMesh "Patches deployments with TrustyAI config" "Environment Injection"

        # Service interactions
        trustyaiService -> storage "Stores inference data and metrics" "Filesystem"
        trustyaiService -> kserve "Receives inference data from" "HTTP/8080"
        oauthProxy -> openshift "Authenticates users via OAuth" "HTTPS/443"
        oauthProxy -> trustyaiService "Proxies authenticated requests to" "HTTP/8080"
        openshift -> trustyaiService "Routes external traffic to" "Route + Service"

        # Monitoring
        prometheus -> trustyaiService "Scrapes metrics (/q/metrics)" "HTTP/80"
        prometheus -> operatorManager "Scrapes operator metrics" "HTTP/8080"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }

        theme default
    }
}

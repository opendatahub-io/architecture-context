workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and monitors ML models for fairness and explainability"
        admin = person "Platform Administrator" "Deploys and configures TrustyAI services"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages deployment and lifecycle of TrustyAI services for AI model explainability, fairness metrics, and LLM evaluation in Kubernetes/OpenShift" {
            operator = container "TrustyAI Service Operator" "Reconciles TrustyAIService and LMEvalJob CRDs, manages service lifecycle" "Go/Kubebuilder v4"
            service = container "TrustyAI Service" "Provides explainability, fairness metrics (SPD, DIR), and bias detection" "Quarkus/Java"
            oauthProxy = container "OAuth Proxy" "Provides authentication/authorization for TrustyAI endpoints" "OpenShift OAuth Proxy"
            lmesDriver = container "LMES Driver" "Manages LM Evaluation Job execution and resource allocation" "Python"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with Routes and OAuth" "External"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "Internal ODH"
        prometheus = softwareSystem "Prometheus (UWM)" "User workload monitoring and metrics collection" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for Open Data Hub components" "Internal ODH"
        istio = softwareSystem "Istio" "Service mesh for mTLS and traffic policies" "External"
        kueue = softwareSystem "Kueue" "Workload queue management for batch jobs" "External"
        database = softwareSystem "Database" "External database for model data storage (MySQL/PostgreSQL)" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for LLM evaluation outputs" "External"

        # User interactions
        user -> trustyai "Creates TrustyAIService and LMEvalJob CRs via kubectl/oc"
        user -> dashboard "Views TrustyAI metrics and explainability data"
        admin -> trustyai "Deploys and configures TrustyAI operator"

        # TrustyAI to platform
        trustyai -> kubernetes "Manages deployments, services, and persistent volumes"
        trustyai -> openshift "Creates Routes and integrates OAuth authentication" "HTTPS/443"

        # TrustyAI to ODH components
        trustyai -> kserve "Watches InferenceServices and injects payload processors for data collection" "K8s API"
        trustyai -> modelmesh "Discovers ModelMesh deployments via label selectors" "K8s API"
        trustyai -> prometheus "Exposes fairness metrics (trustyai_spd, trustyai_dir) via ServiceMonitor" "HTTP/8080"
        dashboard -> trustyai "Discovers TrustyAI service endpoints via labels"

        # TrustyAI integrations
        trustyai -> istio "Creates DestinationRules and VirtualServices for service mesh" "K8s API"
        trustyai -> kueue "Creates Workloads for LMEvalJobs with resource management" "K8s API"
        trustyai -> database "Stores model data and metrics in DATABASE mode" "JDBC/TLS"
        trustyai -> s3 "Writes LLM evaluation outputs" "HTTPS/443"

        # KServe to TrustyAI
        kserve -> trustyai "Sends inference data to /consumer/kserve/v2 endpoint" "HTTP/8080"
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

        theme default
    }
}

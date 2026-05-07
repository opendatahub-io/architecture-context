workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, and monitors model fairness/bias"
        mlEngineer = person "ML Engineer" "Deploys inference services with guardrails and monitoring"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing explainability monitoring, LM evaluation, and guardrails orchestration" {
            operatorController = container "Operator Controllers" "TAS, LMES, GORCH, JOB_MGR controller loops" "Go / controller-runtime"
            trustyaiService = container "TrustyAI Service" "Explainability and bias monitoring for ML model predictions" "Java / Quarkus"
            lmevalJob = container "LMEvalJob Pod" "Language model evaluation using lm-evaluation-harness" "Python 3.11 + Go driver"
            guardrailsOrchestrator = container "GuardrailsOrchestrator" "Content detection and guardrails for inference services" "Orchestrator container"
            oauthProxy = container "OAuth Proxy Sidecars" "Authentication enforcement via OpenShift OAuth" "ose-oauth-proxy"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Traffic management, mTLS, and network policy enforcement" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        kueue = softwareSystem "Kueue" "Fair-share job scheduling and quota management" "External"
        odhOperator = softwareSystem "OpenDataHub Operator" "Platform-level configuration and component management" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Cluster authentication and authorization" "External"
        serviceCa = softwareSystem "OpenShift Service CA" "Automatic TLS certificate generation for services" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"

        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact and dataset storage" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        externalDb = softwareSystem "External Database" "Persistent storage for TrustyAI monitoring data" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates LMEvalJob CRs for model evaluation" "kubectl / HTTPS 6443"
        dataScientist -> trustyaiOperator "Views bias/explainability metrics" "HTTPS 443 via Route"
        mlEngineer -> trustyaiOperator "Creates TrustyAIService and GuardrailsOrchestrator CRs" "kubectl / HTTPS 6443"

        # Internal container relationships
        operatorController -> trustyaiService "Creates and manages Deployment" "Kubernetes API"
        operatorController -> lmevalJob "Creates evaluation Pods" "Kubernetes API"
        operatorController -> guardrailsOrchestrator "Creates and manages Deployment" "Kubernetes API"
        oauthProxy -> trustyaiService "Proxies authenticated requests" "HTTP/8080 localhost"
        oauthProxy -> guardrailsOrchestrator "Proxies authenticated requests" "HTTPS/8032"

        # Platform integrations
        operatorController -> kserve "Watches InferenceServices, patches with TrustyAI logger" "Kubernetes API"
        operatorController -> istio "Creates DestinationRules and VirtualServices (conditional)" "Kubernetes API"
        operatorController -> prometheus "Creates ServiceMonitors for metrics scraping" "Kubernetes API"
        operatorController -> kueue "Creates Workload CRs for fair-share scheduling" "Kubernetes API"
        operatorController -> odhOperator "Reads DSC configuration for LMEval permissions" "ConfigMap"
        oauthProxy -> openshiftOAuth "Validates OAuth tokens, performs SAR checks" "HTTPS"
        operatorController -> serviceCa "Triggers TLS cert generation via service annotations" "Annotation"

        kserve -> trustyaiService "Forwards inference payloads for monitoring" "HTTPS/443 TLS (service-ca)"
        guardrailsOrchestrator -> kserve "Calls generation and detector InferenceServices" "HTTPS TLS (service-ca)"

        # External service integrations
        trustyaiService -> externalDb "Stores monitoring data" "JDBC TLS (optional)"
        lmevalJob -> s3Storage "Downloads offline assets (models, datasets)" "HTTPS/443 TLS 1.2+"
        lmevalJob -> huggingFace "Downloads models and datasets (when online allowed)" "HTTPS/443 TLS 1.2+"
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
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

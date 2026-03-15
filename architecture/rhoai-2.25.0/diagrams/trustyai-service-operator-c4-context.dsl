workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and monitors AI models, runs evaluations, deploys guardrails"
        administrator = person "Platform Administrator" "Manages TrustyAI operator and infrastructure"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI services for AI explainability, LM evaluation, and guardrails" {
            operatorController = container "Operator Controller Manager" "Reconciles CRDs and manages lifecycle" "Go Operator (controller-runtime)" {
                trustyaiController = component "TrustyAI Service Controller" "Manages TrustyAI service instances"
                lmevalController = component "LM Eval Job Controller" "Orchestrates language model evaluation jobs"
                guardrailsController = component "Guardrails Orchestrator Controller" "Manages AI safety guardrails"
                conversionWebhook = component "CRD Conversion Webhook" "Converts between v1 and v1alpha1 CRDs"
            }

            trustyaiService = container "TrustyAI Service" "Provides AI explainability and bias detection" "Java (Quarkus)" {
                explainabilityEngine = component "Explainability Engine" "Computes LIME, SHAP explanations"
                biasDetector = component "Bias Detector" "Detects fairness and bias metrics"
                metricsCollector = component "Metrics Collector" "Collects and stores model predictions"
            }

            lmesJob = container "LM Eval Job" "Executes language model evaluations" "Python (lm-evaluation-harness)"
            guardrailsOrch = container "Guardrails Orchestrator" "Orchestrates AI safety detectors" "Python"
            oauthProxy = container "OAuth Proxy" "Provides OpenShift OAuth authentication" "Go"
        }

        kubernetes = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External"
        kserve = softwareSystem "KServe" "Model serving for ML inference" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving framework" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "User authentication service" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management" "External"
        kueue = softwareSystem "Kueue" "Kubernetes workload queue manager" "External"

        database = softwareSystem "PostgreSQL/MySQL Database" "Persistent storage for TrustyAI data" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for evaluation results" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model and dataset repository" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for platform management" "Internal ODH"

        # Relationships
        dataScientist -> trustyaiOperator "Creates TrustyAI services, LM eval jobs, guardrails via kubectl/dashboard"
        dataScientist -> odhDashboard "Manages AI services via web UI"
        administrator -> trustyaiOperator "Deploys and configures operator"

        odhDashboard -> trustyaiOperator "Creates TrustyAIService CRDs"

        trustyaiOperator -> kubernetes "Deploys and manages pods, services, routes" "Kubernetes API/HTTPS/6443"
        trustyaiOperator -> kserve "Monitors and patches InferenceServices" "Kubernetes API/HTTPS/6443"
        trustyaiOperator -> modelmesh "Configures payload processors" "Pod Exec/gRPC/8033"
        trustyaiOperator -> prometheus "Exposes metrics via ServiceMonitors" "HTTP/8080, HTTPS/8443"
        trustyaiOperator -> openShiftOAuth "Authenticates user requests" "OpenShift SAR"
        trustyaiOperator -> istio "Creates VirtualServices and DestinationRules" "Kubernetes API/HTTPS/6443"
        trustyaiOperator -> kueue "Manages workload admission for jobs" "Kubernetes API/HTTPS/6443"

        trustyaiService -> database "Stores prediction data and metrics" "PostgreSQL/MySQL/5432,3306"
        trustyaiService -> kserve "Receives prediction payloads from models" "HTTP/HTTPS/80-443"

        lmesJob -> huggingFace "Downloads models and datasets" "HTTPS/443"
        lmesJob -> kserve "Sends inference requests" "HTTPS/443"
        lmesJob -> s3Storage "Stores evaluation results" "S3 API/HTTPS/443"

        guardrailsOrch -> kserve "Calls detector and generator InferenceServices" "HTTPS/443"

        oauthProxy -> trustyaiService "Forwards authenticated requests" "HTTP/8080"
        oauthProxy -> openShiftOAuth "Validates bearer tokens" "OpenShift OAuth API"

        dataScientist -> oauthProxy "Accesses TrustyAI services via routes" "HTTPS/443"
    }

    views {
        systemContext trustyaiOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container trustyaiOperator "Containers" {
            include *
            autoLayout tb
        }

        component operatorController "OperatorComponents" {
            include *
            autoLayout lr
        }

        component trustyaiService "TrustyAIServiceComponents" {
            include *
            autoLayout tb
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
                shape person
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

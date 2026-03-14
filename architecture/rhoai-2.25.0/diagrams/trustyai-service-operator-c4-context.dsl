workspace {
    model {
        user = person "Data Scientist" "Creates and evaluates AI models, monitors for bias and fairness"
        developer = person "ML Engineer" "Deploys and monitors AI models in production"
        securityEngineer = person "Security Engineer" "Configures guardrails for AI safety"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI services, LM evaluation jobs, and guardrails orchestrators for AI model explainability, evaluation, and safety" {
            operator = container "Operator Manager" "Manages lifecycle of TrustyAI resources" "Go Operator" {
                controller = component "TrustyAI Controller" "Reconciles TrustyAIService CRs" "controller-runtime"
                lmevalController = component "LMEvalJob Controller" "Reconciles LMEvalJob CRs" "controller-runtime"
                guardrailsController = component "GuardrailsOrchestrator Controller" "Reconciles GuardrailsOrchestrator CRs" "controller-runtime"
                webhook = component "Conversion Webhook" "Converts v1alpha1 to v1" "Kubernetes Webhook"
            }

            trustyaiService = container "TrustyAI Service" "Provides AI explainability, bias detection, and fairness metrics" "Quarkus/Java" {
                api = component "REST API" "Exposes metrics and explainability endpoints" "HTTP/HTTPS"
                monitor = component "Prediction Monitor" "Captures model predictions" "Payload Processor"
                metrics = component "Metrics Engine" "Calculates fairness and bias metrics" "ML Library"
                storage = component "Data Storage" "Persists prediction data" "PVC/Database"
            }

            lmesJob = container "LMES Job" "Executes language model evaluation" "Python/lm-evaluation-harness"

            guardrailsOrch = container "Guardrails Orchestrator" "Orchestrates AI safety detectors" "Python" {
                gateway = component "Gateway API" "Processes guardrail requests" "HTTP/HTTPS"
                orchestrator = component "Detector Orchestrator" "Coordinates safety checks" "Orchestration Logic"
            }

            oauthProxy = container "OAuth Proxy" "Provides OpenShift OAuth authentication" "ose-oauth-proxy"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        modelMesh = softwareSystem "ModelMesh" "Distributed model serving" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH"

        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openshift = softwareSystem "OpenShift" "Kubernetes platform with OAuth, Routes, and service-ca" "External"
        kueue = softwareSystem "Kueue" "Kubernetes job queueing" "External"

        database = softwareSystem "PostgreSQL/MySQL" "Relational database for persistent storage" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for evaluation results" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Model and dataset repository" "External"

        # User interactions
        user -> dashboard "Creates TrustyAI services via UI"
        user -> trustyai "Creates LMEvalJob resources via kubectl"
        developer -> trustyai "Monitors model explainability metrics"
        securityEngineer -> trustyai "Configures guardrails orchestrators"

        # Dashboard integration
        dashboard -> operator "Creates TrustyAIService CRs" "Kubernetes API"

        # Operator manages containers
        operator -> trustyaiService "Creates and manages deployments" "Kubernetes API"
        operator -> lmesJob "Creates job pods" "Kubernetes API"
        operator -> guardrailsOrch "Creates orchestrator deployments" "Kubernetes API"
        operator -> oauthProxy "Injects as sidecar" "Kubernetes API"

        # TrustyAI Service integrations
        trustyaiService -> kserve "Monitors InferenceService predictions" "HTTP/HTTPS"
        operator -> modelMesh "Injects payload processors via pod exec" "gRPC/mTLS"
        trustyaiService -> database "Persists prediction data" "PostgreSQL/MySQL TLS"
        trustyaiService -> pipelines "Shares PVC storage" "Filesystem"

        # LM Evaluation integrations
        lmesJob -> kueue "Uses workload queue management" "Kubernetes API"
        lmesJob -> huggingface "Downloads models and datasets" "HTTPS/443"
        lmesJob -> kserve "Evaluates model endpoints" "HTTPS/443"
        lmesJob -> s3 "Stores evaluation results" "S3 API HTTPS"

        # Guardrails integrations
        guardrailsOrch -> kserve "Checks safety with detector models" "HTTPS/443"

        # Platform integrations
        operator -> openshift "Creates Routes for external access" "Kubernetes API"
        operator -> istio "Creates VirtualServices for serverless" "Kubernetes API"
        oauthProxy -> openshift "Validates OAuth tokens" "OpenShift OAuth API"
        prometheus -> trustyaiService "Scrapes /q/metrics endpoint" "HTTP/8080"
        prometheus -> operator "Scrapes /metrics endpoint" "HTTPS/8443"

        # Operator watches resources
        operator -> kserve "Watches InferenceService resources" "Kubernetes API Watch"
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

        component operator "OperatorComponents" {
            include *
            autoLayout
        }

        component trustyaiService "TrustyAIServiceComponents" {
            include *
            autoLayout
        }

        component guardrailsOrch "GuardrailsOrchestratorComponents" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #999999
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
        }

        theme default
    }
}

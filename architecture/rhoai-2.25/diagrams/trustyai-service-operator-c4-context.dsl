workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and monitors ML models with TrustyAI services"
        admin = person "Platform Administrator" "Manages TrustyAI operator and service instances"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI explainability services, LM evaluation jobs, and guardrails orchestrators for AI model governance" {
            controller = container "Operator Controller Manager" "Manages TrustyAI service lifecycle, reconciles CRs" "Go Operator (controller-runtime)" {
                reconciler = component "CR Reconciler" "Watches and reconciles TrustyAIService, LMEvalJob, GuardrailsOrchestrator CRs" "Go"
                resourceManager = component "Resource Manager" "Creates/updates Deployments, Services, Routes, ServiceMonitors" "Go"
                kserveIntegration = component "KServe Integration" "Patches InferenceServices for monitoring integration" "Go"
            }

            webhook = container "Conversion Webhook Server" "Converts TrustyAIService between v1alpha1 and v1" "Go Webhook" {
                conversionHandler = component "Version Conversion Handler" "Handles CR version migration" "Go"
            }

            rbacProxy = container "kube-rbac-proxy" "Secures operator metrics endpoint with RBAC" "Go Proxy"
        }

        trustyaiService = softwareSystem "TrustyAI Service" "Provides AI explainability, bias detection, and fairness metrics for ML models" {
            explainer = container "Explainability Engine" "Generates model explanations (LIME, SHAP)" "Java/Quarkus"
            biasDetector = container "Bias Detector" "Detects fairness and bias in model predictions" "Java/Quarkus"
            dataCollector = container "Data Collector" "Collects and stores model predictions and metadata" "Java/Quarkus"
            metricsExporter = container "Metrics Exporter" "Exports Prometheus metrics for monitoring" "Java/Quarkus"
        }

        lmEvalJob = softwareSystem "LM Eval Job" "Executes language model evaluation using lm-evaluation-harness" {
            driver = container "LM Eval Driver" "Orchestrates evaluation job lifecycle" "Python"
            executor = container "LMES Executor" "Runs lm-evaluation-harness tasks" "Python"
        }

        guardrails = softwareSystem "Guardrails Orchestrator" "Orchestrates AI safety detectors for input/output filtering" {
            orchestrator = container "Orchestration Engine" "Routes requests through detector and generator chains" "Python/FastAPI"
            detectorClient = container "Detector Client" "Calls detector InferenceServices" "Python"
            generatorClient = container "Generator Client" "Calls generator InferenceServices" "Python"
        }

        # External OpenDataHub/RHOAI Systems
        kserve = softwareSystem "KServe" "Kubernetes-based serverless ML inference platform" "External ODH"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime for high-density model hosting" "External ODH"
        dashboard = softwareSystem "ODH Dashboard" "OpenDataHub web console for managing platform components" "External ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration (Kubeflow Pipelines)" "External ODH"

        # External Platform Components
        kubernetes = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and mTLS" "External Platform"
        oauth = softwareSystem "OpenShift OAuth" "OpenShift authentication and authorization service" "External Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External Platform"
        kueue = softwareSystem "Kueue" "Kubernetes workload queue management for job scheduling" "External Platform"

        # External Services
        s3 = softwareSystem "S3-compatible Storage" "Object storage for LM evaluation results" "External Service"
        huggingface = softwareSystem "Hugging Face Hub" "Model and dataset repository" "External Service"
        database = softwareSystem "PostgreSQL/MySQL" "Relational database for TrustyAI data storage" "External Service"

        # User Interactions
        user -> dashboard "Creates TrustyAI services via UI"
        user -> kubernetes "Creates LMEvalJob, GuardrailsOrchestrator CRs via kubectl"
        user -> trustyaiService "Views explainability and bias metrics via OAuth-protected endpoint"
        user -> guardrails "Sends AI requests through guardrails for safety filtering"
        admin -> trustyai "Deploys and configures TrustyAI operator"
        admin -> kubernetes "Monitors operator health and metrics"

        # Operator Relationships
        trustyai -> kubernetes "Watches CRs, creates/updates resources via API" "HTTPS/6443 TLS1.3"
        trustyai -> trustyaiService "Manages deployment lifecycle"
        trustyai -> lmEvalJob "Creates and manages evaluation jobs"
        trustyai -> guardrails "Deploys and configures orchestrators"
        trustyai -> kserve "Watches and patches InferenceService CRs" "HTTPS/6443"
        trustyai -> modelMesh "Configures payload processors via pod exec" "gRPC/8033 mTLS"
        trustyai -> prometheus "Exposes operator metrics via ServiceMonitor" "HTTPS/8443"
        trustyai -> oauth "Configures OAuth proxies for service authentication"
        trustyai -> certManager "Uses for webhook TLS certificate provisioning" "HTTPS/6443"
        trustyai -> istio "Creates VirtualServices and DestinationRules for KServe serverless mode" "HTTPS/6443"
        trustyai -> kueue "Creates Workload CRDs for LM evaluation job queueing" "HTTPS/6443"

        # TrustyAI Service Relationships
        trustyaiService -> kserve "Monitors model predictions via payload processor" "HTTP/HTTPS 80-443"
        trustyaiService -> database "Stores prediction data and metrics" "PostgreSQL/MySQL 5432/3306 TLS1.2+"
        trustyaiService -> prometheus "Exports business metrics" "HTTP/8080"

        # LM Eval Job Relationships
        lmEvalJob -> kserve "Evaluates models via inference API" "HTTPS/443 TLS1.2+"
        lmEvalJob -> huggingface "Downloads models and datasets" "HTTPS/443 TLS1.2+"
        lmEvalJob -> s3 "Stores evaluation results" "HTTPS/443 TLS1.2+ AWS IAM"
        lmEvalJob -> kueue "Queued for admission control" "HTTPS/6443"

        # Guardrails Relationships
        guardrails -> kserve "Calls detector and generator InferenceServices" "HTTPS/443 TLS1.2+"
        guardrails -> oauth "Authenticates external requests via OAuth proxy"

        # Integration Points
        dashboard -> trustyai "User creates TrustyAIService via dashboard UI" "HTTPS/6443"
        pipelines -> lmEvalJob "Auto-deploys evaluation jobs from pipeline tasks" "HTTPS/6443"
    }

    views {
        systemContext trustyai "TrustyAIOperatorContext" {
            include *
            autoLayout
            title "TrustyAI Service Operator - System Context"
            description "Shows how TrustyAI Service Operator fits into the OpenDataHub/RHOAI ecosystem"
        }

        container trustyai "TrustyAIOperatorContainers" {
            include *
            autoLayout
            title "TrustyAI Service Operator - Container View"
            description "Operator internal components: Controller, Webhook, RBAC Proxy"
        }

        container trustyaiService "TrustyAIServiceContainers" {
            include *
            autoLayout
            title "TrustyAI Service - Container View"
            description "TrustyAI Service internal components for explainability and bias detection"
        }

        container lmEvalJob "LMEvalJobContainers" {
            include *
            autoLayout
            title "LM Eval Job - Container View"
            description "LM evaluation job components: Driver and Executor"
        }

        container guardrails "GuardrailsContainers" {
            include *
            autoLayout
            title "Guardrails Orchestrator - Container View"
            description "Guardrails orchestrator components for AI safety"
        }

        systemLandscape "ODHLandscape" {
            include *
            autoLayout
            title "OpenDataHub/RHOAI AI Governance Landscape"
            description "Complete view of TrustyAI operator and related ODH components"
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
            element "External ODH" {
                background #7ed321
                color #000000
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
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

        themes default
    }

    configuration {
        scope softwaresystem
    }
}

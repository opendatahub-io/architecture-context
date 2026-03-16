workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys ML models, runs evaluations, applies guardrails"
        mlEngineer = person "ML Engineer" "Monitors model performance, investigates bias, ensures compliance"
        securityEngineer = person "Security Engineer" "Configures guardrails, reviews audit logs, enforces AI safety policies"

        # TrustyAI Service Operator System
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Kubernetes operator managing TrustyAI explainability services, LM evaluation jobs, and AI guardrails orchestration" {
            controller = container "Operator Controller" "Reconciles TrustyAI CRs and manages deployments" "Go Operator (Kubebuilder)" {
                reconciler = component "CR Reconciler" "Watches and reconciles TrustyAIService, LMEvalJob, GuardrailsOrchestrator CRs"
                kserveWatcher = component "KServe Watcher" "Watches InferenceServices for guardrails injection"
                resourceManager = component "Resource Manager" "Creates/updates Deployments, Services, Routes, VirtualServices"
            }

            trustyaiService = container "TrustyAI Service" "Provides explainability and bias detection for ML models" "Quarkus Java Service" {
                api = component "REST API" "Accepts inference data and explainability requests"
                explainability = component "Explainability Engine" "LIME, SHAP, counterfactuals"
                biasDetection = component "Bias Detector" "Fairness metrics and drift detection"
                storage = component "Storage Layer" "Persists data to PVC or database"
            }

            lmevalJob = container "LM Evaluation Job" "Executes language model evaluation tasks" "Python Batch Job" {
                driver = component "LMES Driver" "Manages job lifecycle and result collection"
                evaluator = component "LM Evaluator" "Runs evaluation tasks against models"
            }

            guardrailsOrchestrator = container "Guardrails Orchestrator" "Coordinates AI safety guardrails for inference services" "Python Service" {
                orchestration = component "Orchestration Engine" "Routes requests through detector pipeline"
                detectorManager = component "Detector Manager" "Manages detector InferenceServices"
                telemetry = component "Telemetry Exporter" "Exports OTLP traces and metrics"
            }
        }

        # External Systems - Platform
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with Routes and OAuth" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # External Systems - Optional
        kueue = softwareSystem "Kueue" "Job queue management for resource quotas and priorities" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"

        # Internal ODH/RHOAI Systems
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH/RHOAI"
        modelMesh = softwareSystem "Model Mesh" "Multi-model serving infrastructure" "Internal ODH/RHOAI"
        dsc = softwareSystem "Data Science Cluster" "Platform configuration management" "Internal ODH/RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifacts" "Internal ODH/RHOAI"

        # External Storage/Services
        database = softwareSystem "PostgreSQL/MySQL" "External database for TrustyAI data persistence" "External"
        s3Storage = softwareSystem "S3 Storage" "Model artifact and dataset storage" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Telemetry aggregation and export" "External"

        # User Interactions
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, GuardrailsOrchestrator CRs via kubectl/oc"
        mlEngineer -> trustyaiService "Monitors model performance and bias metrics via API"
        securityEngineer -> guardrailsOrchestrator "Configures guardrails policies and reviews telemetry"

        # TrustyAI Operator Interactions
        trustyaiOperator -> kubernetes "Deploys and manages Kubernetes resources" "kubectl API"
        trustyaiOperator -> openshift "Creates Routes for external access" "OpenShift API"
        trustyaiOperator -> istio "Creates VirtualServices and DestinationRules" "Istio CRDs"
        trustyaiOperator -> kserve "Watches and patches InferenceServices for guardrails injection" "KServe API"
        trustyaiOperator -> modelMesh "Injects payload processors into ModelMesh pods" "Label Watch/Patch"
        trustyaiOperator -> dsc "Reads platform configuration via ConfigMap" "ConfigMap Read"
        trustyaiOperator -> kueue "Creates Workload CRs for LMEvalJob scheduling" "Kueue API"
        trustyaiOperator -> prometheus "Exposes ServiceMonitors for metrics scraping" "Prometheus Operator"

        # TrustyAI Service Interactions
        trustyaiService -> database "Persists inference data and metrics" "JDBC/TLS"
        trustyaiService -> prometheus "Exposes /q/metrics endpoint" "HTTP Scraping"
        trustyaiService -> istio "Uses VirtualServices for traffic routing" "mTLS"

        # LMEval Job Interactions
        lmevalJob -> modelRegistry "Downloads models for evaluation" "HTTPS/443"
        lmevalJob -> s3Storage "Downloads datasets (if allowOnline=true)" "HTTPS/443"
        lmevalJob -> kserve "Calls InferenceServices for evaluation" "HTTPS/gRPC mTLS"
        lmevalJob -> kubernetes "Stores results in Secret" "kubectl API"

        # Guardrails Orchestrator Interactions
        guardrailsOrchestrator -> kserve "Calls detector and generator InferenceServices" "HTTPS/gRPC mTLS"
        guardrailsOrchestrator -> otlpCollector "Exports telemetry traces and metrics" "gRPC/HTTP TLS"
        guardrailsOrchestrator -> prometheus "Exposes metrics endpoint" "HTTP Scraping"
    }

    views {
        systemContext trustyaiOperator "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram showing TrustyAI Service Operator in the broader RHOAI/ODH ecosystem"
        }

        container trustyaiOperator "Containers" {
            include *
            autoLayout lr
            description "Container diagram showing the main components of TrustyAI Service Operator"
        }

        component controller "OperatorControllerComponents" {
            include *
            autoLayout lr
            description "Component diagram of the Operator Controller"
        }

        component trustyaiService "TrustyAIServiceComponents" {
            include *
            autoLayout lr
            description "Component diagram of the TrustyAI Service"
        }

        component guardrailsOrchestrator "GuardrailsOrchestratorComponents" {
            include *
            autoLayout lr
            description "Component diagram of the Guardrails Orchestrator"
        }

        styles {
            element "Software System" {
                background #1168bd
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH/RHOAI" {
                background #7ed321
                color #000000
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

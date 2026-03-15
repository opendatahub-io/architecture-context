workspace {
    model {
        dataScientist = person "Data Scientist" "Creates TrustyAI services, LM evaluation jobs, and guardrails orchestrators for AI governance"
        mlEngineer = person "ML Engineer" "Deploys and monitors AI models with explainability and safety controls"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Kubernetes operator managing TrustyAI explainability services, LM evaluation jobs, and AI guardrails orchestration" {
            controller = container "Operator Controller" "Reconciles TrustyAI CRs and manages lifecycle" "Go Operator" {
                reconciler = component "Reconciler" "Watches and reconciles custom resources" "Kubebuilder"
                serviceManager = component "Service Manager" "Manages TrustyAI service deployments" "Go"
                jobManager = component "Job Manager" "Manages LMEvalJob executions" "Go"
                guardrailsManager = component "Guardrails Manager" "Manages guardrails orchestrators and InferenceService injection" "Go"
            }

            trustyaiService = container "TrustyAI Service" "Provides ML explainability and bias detection" "Java/Quarkus" {
                apiEndpoint = component "REST API" "Exposes explainability endpoints" "Quarkus REST"
                metricsExporter = component "Metrics Exporter" "Prometheus metrics" "Quarkus"
                storageAdapter = component "Storage Adapter" "PVC or database persistence" "Hibernate"
            }

            lmesJob = container "LM Evaluation Job" "Executes language model evaluation tasks" "Python Batch Job" {
                lmesDriver = component "LMES Driver" "Manages job lifecycle" "Python"
                lmesExecutor = component "LMES Executor" "Runs evaluation tasks" "Python"
            }

            guardrailsOrch = container "Guardrails Orchestrator" "Coordinates AI safety guardrails" "Python Service" {
                orchestratorAPI = component "Orchestrator API" "Manages guardrails workflow" "Python FastAPI"
                detectorClient = component "Detector Client" "Calls detection InferenceServices" "gRPC/HTTP"
                telemetryExporter = component "Telemetry Exporter" "OTLP traces/metrics" "OpenTelemetry"
            }

            rbacProxy = container "Kube-RBAC-Proxy" "Authentication and authorization proxy" "Go Service"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration and resource management" "External Platform"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and mTLS" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        openshift = softwareSystem "OpenShift Router" "Ingress routing and TLS termination" "External Platform"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and artifact storage" "Internal RHOAI"
        postgresDB = softwareSystem "PostgreSQL/MySQL Database" "Persistent storage for TrustyAI data" "External Service"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Telemetry aggregation and export" "External Service"
        kueue = softwareSystem "Kueue" "Job queue and resource quota management" "External Platform"
        datasetRepos = softwareSystem "Dataset Repositories" "Public dataset hosting (HuggingFace, etc.)" "External Service"

        # User interactions
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, GuardrailsOrchestrator CRs via kubectl"
        mlEngineer -> trustyaiService "Queries explainability metrics and bias detection" "HTTPS/443"
        mlEngineer -> guardrailsOrch "Configures and monitors AI guardrails" "HTTPS/8432"

        # Operator interactions
        trustyaiOperator -> kubernetes "Watches CRs, creates Deployments, Services, Routes, Secrets" "HTTPS/6443"
        controller -> kubernetes "CRUD operations on cluster resources" "HTTPS/6443, Service Account Token"
        controller -> kserve "Watches and patches InferenceServices for guardrails injection" "HTTPS/6443"
        controller -> istio "Creates VirtualServices and DestinationRules" "HTTPS/6443"
        controller -> openshift "Creates Routes for external access" "HTTPS/6443"
        controller -> kueue "Creates Workloads for job scheduling" "HTTPS/6443"

        # TrustyAI Service interactions
        trustyaiService -> postgresDB "Stores explainability data and metrics" "JDBC, TLS 1.2+, DB Credentials"
        trustyaiService -> prometheus "Exposes Quarkus metrics" "HTTP/80, ServiceMonitor"
        openshift -> trustyaiService "Routes external requests" "HTTPS/443"
        rbacProxy -> trustyaiService "Proxies authenticated requests" "HTTP/8080"

        # Guardrails Orchestrator interactions
        guardrailsOrch -> kserve "Forwards requests to detector and generator InferenceServices" "HTTPS/443, mTLS"
        guardrailsOrch -> otlpCollector "Exports traces and metrics" "gRPC, TLS 1.2+"
        guardrailsOrch -> prometheus "Exposes detector metrics" "HTTP/8080, ServiceMonitor"
        openshift -> guardrailsOrch "Routes external requests" "HTTPS/443"
        rbacProxy -> guardrailsOrch "Proxies OAuth-protected requests" "HTTPS/8032"

        # LMEvalJob interactions
        lmesJob -> modelRegistry "Downloads model artifacts" "HTTPS/443, Token/Credentials"
        lmesJob -> datasetRepos "Downloads evaluation datasets" "HTTPS/443, API Key"
        lmesJob -> kserve "Evaluates InferenceServices" "HTTPS/443, mTLS"
        lmesJob -> kubernetes "Creates result Secrets" "HTTPS/6443, Service Account Token"
        kueue -> lmesJob "Schedules and queues jobs with quotas" "Workload CRD"

        # Istio mesh integration
        istio -> trustyaiService "Provides mTLS and traffic routing" "mTLS"
        istio -> guardrailsOrch "Provides mTLS for service mesh" "mTLS"
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

        component controller "OperatorComponents" {
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
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
        }

        theme default
    }
}

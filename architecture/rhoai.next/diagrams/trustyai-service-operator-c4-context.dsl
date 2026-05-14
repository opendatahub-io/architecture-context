workspace {
    model {
        datascientist = person "Data Scientist" "Creates ML models, runs evaluations, deploys inference services"
        mlops = person "MLOps Engineer" "Manages AI trustworthiness, guardrails, and evaluation infrastructure"
        securityteam = person "Security / Compliance" "Reviews model fairness, bias, and safety guardrails"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller Kubernetes operator managing AI trustworthiness, model evaluation, and guardrails infrastructure" {
            controllerManager = container "controller-manager" "Hosts all controllers and reconcile loops; selectable via --enable-services" "Go Operator (kubebuilder v4)"
            tasController = container "TAS Controller" "Manages TrustyAIService CRDs; deploys explainability/fairness service with KServe/ModelMesh integration" "Go controller-runtime"
            lmesController = container "LMES Controller" "Orchestrates LMEvalJob lifecycle; manages evaluation pods with ta-lmes-driver" "Go controller-runtime"
            gorchController = container "GORCH Controller" "Deploys FMS Guardrails orchestrator with InferenceService auto-discovery" "Go controller-runtime"
            nemoController = container "NeMo Controller" "Deploys NVIDIA NeMo Guardrails instances with CA bundle management" "Go controller-runtime"
            evalhubController = container "EvalHub Controller" "Deploys centralized evaluation hub with multi-tenant support" "Go controller-runtime"
            jobMgrController = container "JOB_MGR Controller" "Bridges LMEvalJobs to Kueue Workloads for queue-based scheduling" "Go controller-runtime"
            lmesDriver = container "ta-lmes-driver" "Sidecar binary executing lm-evaluation-harness with progress monitoring" "Go CLI"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh" "Multi-model serving platform" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queuing system" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access" "External"
        mlflow = softwareSystem "MLFlow" "ML experiment tracking and model registry" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for model artifacts and evaluation assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation results" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model and dataset repository" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics export" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent storage" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys and configures component operators" "Internal RHOAI"
        openshiftCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External"

        # User interactions
        datascientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, GuardrailsOrchestrator CRDs via kubectl/UI"
        mlops -> trustyaiOperator "Configures guardrails, evaluation pipelines, and EvalHub tenants"
        securityteam -> trustyaiOperator "Reviews bias/fairness metrics and guardrail policies"

        # Platform integration
        rhoaiOperator -> trustyaiOperator "Deploys operator and provides image configuration" "ConfigMap"
        trustyaiOperator -> kserve "Patches InferenceService specs for payload processing" "HTTPS/6443"
        trustyaiOperator -> modelmesh "Injects payload processors and logger URLs" "HTTPS/6443"
        trustyaiOperator -> kueue "Creates Workload CRs for LMEvalJob scheduling" "HTTPS/6443"
        trustyaiOperator -> istio "Creates DestinationRules/VirtualServices (conditional)" "HTTPS/6443"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics scraping" "HTTPS/6443"
        trustyaiOperator -> openshiftRouter "Creates Routes for external access" "HTTPS/6443"
        trustyaiOperator -> openshiftCA "Uses service CA for TLS cert provisioning" "Annotation"

        # External service egress
        trustyaiOperator -> mlflow "EvalHub experiment tracking" "HTTPS"
        trustyaiOperator -> s3 "LMES offline asset download" "HTTPS/443"
        trustyaiOperator -> ociRegistry "LMES result upload" "HTTPS/443"
        trustyaiOperator -> huggingFace "LMES model/dataset download (online mode)" "HTTPS/443"
        trustyaiOperator -> otel "GORCH/EvalHub trace and metrics export" "gRPC/HTTP"
        trustyaiOperator -> postgresql "EvalHub/TAS persistent storage" "5432/TCP"

        # Reverse integration
        modelmesh -> trustyaiOperator "Sends prediction payloads via MM_PAYLOAD_PROCESSORS" "HTTPS/8443"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

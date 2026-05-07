workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and evaluates them for fairness, bias, and safety"
        mlEngineer = person "ML Engineer" "Deploys and monitors ML models in production"
        securityReviewer = person "Security Reviewer" "Configures guardrails and content safety policies"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing AI trustworthiness, evaluation, and guardrails infrastructure" {
            controllerManager = container "Controller Manager" "Multi-controller operator binary hosting TAS, LMES, GORCH, NemoGuardrails, EvalHub, and JOB_MGR controllers" "Go Operator (controller-runtime)"
            tasController = container "TAS Controller" "Deploys TrustyAI explainability/fairness service with KServe/ModelMesh integration" "Go Controller"
            lmesController = container "LMES Controller" "Orchestrates language model evaluation jobs with lm-evaluation-harness" "Go Controller"
            gorchController = container "GORCH Controller" "Deploys FMS Guardrails orchestrator with auto-discovery of detectors" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Deploys NVIDIA NeMo Guardrails instances with CA bundle management" "Go Controller"
            evalhubController = container "EvalHub Controller" "Deploys centralized evaluation hub with multi-tenant support" "Go Controller"
            jobMgrController = container "JOB_MGR Controller" "Maps LMEvalJobs to Kueue Workloads for queue-based scheduling" "Go Controller"
            taLmesDriver = container "ta-lmes-driver" "Sidecar/init container that executes lm-evaluation-harness with progress monitoring" "Go CLI"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Standardized ML model serving platform" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system" "Internal Platform"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring and alerting toolkit" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External"
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator that deploys TrustyAI operator" "Internal RHOAI"
        mlflow = softwareSystem "MLFlow" "ML experiment tracking server" "Internal Platform"
        s3Storage = softwareSystem "S3 Storage" "Object storage for model artifacts and evaluation data" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation results" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model and dataset repository" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "External"
        gitRepos = softwareSystem "Git Repositories" "Source repositories for custom evaluation tasks" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates TrustyAIService and LMEvalJob CRs via kubectl/dashboard"
        mlEngineer -> trustyaiOperator "Creates EvalHub evaluations and monitors model fairness"
        securityReviewer -> trustyaiOperator "Creates GuardrailsOrchestrator and NemoGuardrails CRs"

        # Controller manager relationships
        controllerManager -> k8sAPI "Reconciles CRDs, manages resources" "HTTPS/6443"
        controllerManager -> tasController "Hosts controller"
        controllerManager -> lmesController "Hosts controller"
        controllerManager -> gorchController "Hosts controller"
        controllerManager -> nemoController "Hosts controller"
        controllerManager -> evalhubController "Hosts controller"
        controllerManager -> jobMgrController "Hosts controller"

        # TAS Controller relationships
        tasController -> kserve "Patches InferenceService specs for payload processing" "HTTPS/6443 via API"
        tasController -> istio "Creates DestinationRules and VirtualServices (conditional)" "HTTPS/6443 via API"
        tasController -> openshiftServiceCA "Provisions TLS certificates via annotation" "ConfigMap injection"
        tasController -> prometheusOp "Creates ServiceMonitors for metrics" "HTTPS/6443 via API"
        tasController -> openshiftRouter "Creates Routes for external access" "HTTPS/6443 via API"

        # LMES Controller relationships
        lmesController -> taLmesDriver "Injects driver binary via init container, polls status" "pod exec/18080"
        taLmesDriver -> s3Storage "Downloads offline evaluation assets" "HTTPS/443"
        taLmesDriver -> ociRegistry "Uploads evaluation results" "HTTPS/443"
        taLmesDriver -> huggingFace "Downloads models/datasets (if allowOnline)" "HTTPS/443"
        taLmesDriver -> gitRepos "Clones custom evaluation tasks" "HTTPS/443"
        jobMgrController -> kueue "Creates Workload CRs for scheduling" "HTTPS/6443 via API"

        # GORCH Controller relationships
        gorchController -> kserve "Auto-discovers InferenceServices and ServingRuntimes" "HTTPS/6443 via API"
        gorchController -> otelCollector "Exports traces and metrics" "gRPC/HTTP"
        gorchController -> openshiftRouter "Creates Routes for external access" "HTTPS/6443 via API"

        # NemoGuardrails Controller relationships
        nemoController -> openshiftRouter "Creates Routes for external access" "HTTPS/6443 via API"

        # EvalHub Controller relationships
        evalhubController -> mlflow "Sends experiment tracking data" "HTTPS (SA token)"
        evalhubController -> otelCollector "Exports traces and metrics" "gRPC/HTTP"
        evalhubController -> openshiftRouter "Creates Routes for external access" "HTTPS/6443 via API"

        # Platform relationships
        rhodsOperator -> trustyaiOperator "Deploys operator and provides image configuration"
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
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, configures guardrails"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform deployment and configuration"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-CRD operator managing AI trustworthiness, evaluation, guardrails, and evaluation hub" {
            manager = container "Operator Manager" "Multi-controller binary with pluggable controller registration (--enable-services)" "Go 1.23 / controller-runtime"
            tasController = container "TAS Controller" "Manages TrustyAIService CRDs for model explainability and fairness monitoring" "Go Controller"
            lmesController = container "LMES Controller" "Manages LMEvalJob CRDs for language model evaluation" "Go Controller"
            gorchController = container "GORCH Controller" "Manages GuardrailsOrchestrator CRDs with auto-discovery of InferenceServices" "Go Controller"
            nemoController = container "NEMO Controller" "Manages NemoGuardrails CRDs for NVIDIA NeMo guardrails" "Go Controller"
            evalHubController = container "EvalHub Controller" "Manages EvalHub CRDs for multi-tenant evaluation management" "Go Controller"
            jobManager = container "Job Manager" "Wraps LMEvalJobs as Kueue Workloads for queue-based scheduling" "Go Controller"
            jobFailureReconciler = container "Job Failure Reconciler" "Watches batch Jobs for infrastructure failures and reports to EvalHub" "Go Controller"
            lmesDriver = container "ta-lmes-driver" "Init container binary providing HTTP status API and S3/OCI upload" "Go Binary"
        }

        trustyaiService = softwareSystem "TrustyAI Service" "Explainability and fairness monitoring service" "Managed"
        guardrailsOrchestrator = softwareSystem "Guardrails Orchestrator" "Content safety guardrails with detector pipeline" "Managed"
        nemoGuardrailsServer = softwareSystem "NeMo Guardrails Server" "NVIDIA NeMo guardrails execution engine" "Managed"
        evalHubApi = softwareSystem "EvalHub API" "Multi-tenant evaluation management with provider/collection framework" "Managed"
        lmEvalPod = softwareSystem "LMEvalJob Pod" "Ephemeral evaluation pod with driver/worker architecture" "Managed"

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that enables TrustyAI controllers" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving with InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving with payload processing" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor CRDs" "Internal RHOAI"
        mlflow = softwareSystem "MLFlow" "Experiment tracking server for evaluation results" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar performing SAR against K8s API" "Internal RHOAI"

        istio = softwareSystem "Istio / Service Mesh" "mTLS, DestinationRules, VirtualServices (conditional)" "External"
        kueue = softwareSystem "Kueue" "Queue-based job scheduling for evaluation workloads" "External"
        certManager = softwareSystem "OpenShift Service CA" "TLS certificate provisioning via service serving certs" "External"
        s3 = softwareSystem "S3 Storage" "Model artifact and evaluation result storage" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation result storage as OCI artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset download" "External"
        gitRepos = softwareSystem "Git Repositories" "Custom evaluation task sources" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent data storage for TrustyAI and EvalHub" "External"

        # Platform admin interactions
        platformAdmin -> rhodsOperator "Configures TrustyAI via DSC" "kubectl/oc"
        rhodsOperator -> trustyaiOperator "Enables controllers, provides trustyai-dsc-config ConfigMap"

        # Data scientist interactions
        dataScientist -> trustyaiService "Queries explainability/fairness" "HTTPS/443 via Route, kube-rbac-proxy SAR"
        dataScientist -> guardrailsOrchestrator "Sends guardrailed inference requests" "HTTPS/443 via Route, kube-rbac-proxy SAR"
        dataScientist -> nemoGuardrailsServer "Sends NeMo guardrails requests" "HTTPS/443 via Route"
        dataScientist -> evalHubApi "Manages evaluations" "HTTPS/443 via Route, kube-rbac-proxy SAR + X-Tenant"
        dataScientist -> trustyaiOperator "Creates CRDs (TrustyAIService, LMEvalJob, GuardrailsOrchestrator, NemoGuardrails, EvalHub)" "kubectl/oc"

        # Operator manages services
        trustyaiOperator -> trustyaiService "Creates Deployment, Service, Route, ConfigMaps, RBAC"
        trustyaiOperator -> guardrailsOrchestrator "Creates Deployment, Service, Route, auto-generates config"
        trustyaiOperator -> nemoGuardrailsServer "Creates Deployment, Service, Route"
        trustyaiOperator -> evalHubApi "Creates Deployment, Service, Route, multi-tenant RBAC"
        trustyaiOperator -> lmEvalPod "Creates ephemeral evaluation Pods"

        # KServe integration
        trustyaiOperator -> kserve "TAS patches InferenceServices (inference loggers); GORCH auto-discovers ISVCs" "HTTPS/6443"
        guardrailsOrchestrator -> kserve "Generation and detection requests to InferenceServices" "HTTP/HTTPS"
        trustyaiService -> kserve "Receives inference logging data from predictors" "HTTPS/8443"

        # ModelMesh integration
        trustyaiOperator -> modelMesh "TAS injects MM_PAYLOAD_PROCESSORS env var" "Deployment patch"

        # Monitoring
        trustyaiOperator -> prometheus "Creates ServiceMonitor CRDs for TAS and GORCH"

        # Job scheduling
        trustyaiOperator -> kueue "Job Manager wraps LMEvalJobs as Kueue Workloads" "CRD"

        # Auth
        kubeRbacProxy -> trustyaiOperator "Sidecar in managed Deployments, SAR auth"

        # Istio (conditional)
        trustyaiOperator -> istio "Creates DestinationRules and VirtualServices when Istio CRD detected"

        # TLS
        trustyaiOperator -> certManager "Uses service serving cert annotations for auto-TLS"

        # External service integrations
        lmEvalPod -> s3 "Download models, upload results" "HTTPS/443, AWS IAM"
        lmEvalPod -> ociRegistry "Upload evaluation results" "HTTPS/443, Basic auth"
        lmEvalPod -> huggingface "Download models and datasets" "HTTPS/443"
        lmEvalPod -> gitRepos "Fetch custom evaluation tasks" "HTTPS/443"
        trustyaiService -> postgresql "Data storage" "TCP TLS, user/pass"
        evalHubApi -> postgresql "Data storage" "TCP TLS, user/pass"
        evalHubApi -> mlflow "Experiment tracking" "HTTPS, projected SA token 3600s TTL"
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
            }
            element "Managed" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
        }
    }
}

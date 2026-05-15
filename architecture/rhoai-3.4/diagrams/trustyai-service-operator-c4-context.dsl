workspace {
    model {
        user = person "Data Scientist" "Creates ML models, deploys inference services, runs evaluations, and configures guardrails"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller Kubernetes operator managing AI explainability, LLM evaluation, guardrails orchestration, NeMo guardrails, and evaluation hub services" {
            tasController = container "TAS Controller" "Manages TrustyAIService CRs; deploys explainability service with kube-rbac-proxy; patches KServe InferenceServices for prediction logging" "Go Controller"
            lmesController = container "LMES Controller" "Manages LMEvalJob CRs; creates evaluation pods with ta-lmes-driver sidecar; supports Kueue scheduling" "Go Controller"
            gorchController = container "GORCH Controller" "Manages GuardrailsOrchestrator CRs; deploys multi-container pods with orchestrator, gateway, detectors; auto-discovers KServe services" "Go Controller"
            nemoController = container "NeMo Controller" "Manages NemoGuardrails CRs; deploys NVIDIA NeMo server with CA bundle aggregation" "Go Controller"
            evalhubController = container "EvalHub Controller" "Manages EvalHub CRs; deploys centralized evaluation hub API with multi-tenant namespace support" "Go Controller"
            jobMgrController = container "Job Manager Controller" "Optional Kueue integration for LMEval workload scheduling" "Go Controller"
            failureReconciler = container "Eval Job Failure Reconciler" "Watches batch Jobs/Pods for evaluation failures; reports back to EvalHub API" "Go Controller"
            lmesDriver = container "ta-lmes-driver" "Init container binary for LMEval jobs; manages lm-eval subprocess, progress tracking, S3 download, OCI upload" "Go Binary"
        }

        kserve = softwareSystem "KServe" "ML model inference platform providing InferenceService and ServingRuntime CRDs" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, DestinationRules, VirtualServices" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing Route-based external access with TLS termination" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate generation for Services via annotations" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor CRDs for metrics scraping" "External"
        kueue = softwareSystem "Kueue" "Job scheduling and resource management via Workload CRDs" "External"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar enforcing SubjectAccessReview" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for offline HuggingFace assets and model artifacts" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation result upload" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for TrustyAI prediction data storage" "External"
        mlflow = softwareSystem "MLFlow" "Experiment tracking server for evaluation results" "Internal ODH"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics collection" "External"
        gitRepos = softwareSystem "Git Repositories" "Source repositories for custom evaluation tasks" "External"

        user -> trustyaiOperator "Creates CRs via kubectl/dashboard"
        trustyaiOperator -> kserve "Watches/patches InferenceServices, discovers ServingRuntimes" "Kubernetes API/TLS"
        trustyaiOperator -> istio "Creates DestinationRules and VirtualServices when mesh present" "Kubernetes API/TLS"
        trustyaiOperator -> openshiftRouter "Creates Routes for external access" "Kubernetes API/TLS"
        trustyaiOperator -> openshiftServiceCA "Triggers auto-cert generation via Service annotations" "Kubernetes API/TLS"
        trustyaiOperator -> prometheusOperator "Creates ServiceMonitors for metrics scraping" "Kubernetes API/TLS"
        trustyaiOperator -> kueue "Creates Workloads for LMEval job scheduling (optional)" "Kubernetes API/TLS"
        trustyaiOperator -> kubeRbacProxy "Deploys as sidecar for Bearer Token SAR auth" "TLS 1.2+ FIPS"
        trustyaiOperator -> s3Storage "Downloads offline assets for LMEval" "HTTPS/443"
        trustyaiOperator -> ociRegistry "Uploads evaluation result artifacts" "HTTPS/443"
        trustyaiOperator -> postgresql "Stores prediction data in database mode" "TCP/TLS"
        trustyaiOperator -> mlflow "Records experiment results from EvalHub" "HTTP/HTTPS"
        trustyaiOperator -> otlpCollector "Exports telemetry traces and metrics" "gRPC/HTTP"
        trustyaiOperator -> gitRepos "Clones custom evaluation tasks (HTTPS-only)" "HTTPS/443"

        tasController -> lmesController "Independent controllers in same binary"
        lmesController -> lmesDriver "Creates pods with driver init container"
        evalhubController -> failureReconciler "Failure events reported to EvalHub API"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

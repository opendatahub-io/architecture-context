workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, and uses AI services"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components and operator configuration"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing TrustyAI, LMEval, Guardrails, NemoGuardrails, and EvalHub services" {
            mainBinary = container "Operator Binary" "Main operator process with controller-runtime" "Go 1.23"
            tasController = container "TAS Controller" "Manages TrustyAIService lifecycle — deploys explainability service with kube-rbac-proxy, Istio, KServe integration" "Go Controller"
            lmesController = container "LMES Controller" "Manages LMEvalJob lifecycle — orchestrates Pod-based evaluation jobs with driver sidecar" "Go Controller"
            gorchController = container "GORCH Controller" "Manages GuardrailsOrchestrator — deploys guardrails with auto-config from InferenceServices" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Manages NemoGuardrails — deploys NVIDIA NeMo safety enforcement" "Go Controller"
            evalHubController = container "EvalHub Controller" "Manages EvalHub — deploys centralized evaluation results service" "Go Controller"
            jobMgrController = container "JobMgr Controller" "Wraps LMEvalJob as Kueue GenericJob for workload admission" "Go Controller"
        }

        trustyaiService = softwareSystem "TrustyAI Service" "Model explainability and monitoring service" "Managed"
        guardrailsOrchestrator = softwareSystem "Guardrails Orchestrator" "AI safety guardrails with detector and generation service orchestration" "Managed"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "NVIDIA NeMo AI safety enforcement" "Managed"
        evalHub = softwareSystem "EvalHub" "Centralized evaluation results management service" "Managed"
        lmesDriver = softwareSystem "ta-lmes-driver" "LM evaluation job execution engine (ephemeral Pods)" "Managed"

        kserve = softwareSystem "KServe" "Model serving with InferenceService and ServingRuntime CRDs" "External - Platform"
        istio = softwareSystem "Istio" "Service mesh for mTLS traffic management" "External - Platform"
        kueue = softwareSystem "Kueue" "Workload admission and resource quota management" "External - Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External - Platform"
        openshift = softwareSystem "OpenShift" "Container platform providing Routes, serving certs, RBAC" "External - Platform"
        rhodsOperator = softwareSystem "RHODS/ODH Operator" "Platform operator providing DSC config and trusted CA bundle" "Internal - Platform"

        postgresql = softwareSystem "PostgreSQL" "Database storage for TAS and EvalHub" "External"
        s3Storage = softwareSystem "S3 Storage" "Model artifacts and evaluation assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container registry for evaluation result upload" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model and dataset download" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry traces, metrics, and logs" "External"

        # User interactions
        dataScientist -> trustyaiService "Queries model explainability via Route" "HTTPS/443, Bearer Token"
        dataScientist -> guardrailsOrchestrator "Sends guarded inference requests via Route" "HTTPS/443, Bearer Token"
        dataScientist -> trustyaiOperator "Creates LMEvalJob CR via kubectl" "HTTPS/443, Bearer Token"
        dataScientist -> evalHub "Views evaluation results via Route" "HTTPS/443, Bearer Token"
        platformAdmin -> trustyaiOperator "Configures operator via CRDs and ConfigMap" "Kubernetes API"

        # Operator → managed services
        tasController -> trustyaiService "Creates Deployment, Service, Route, ServiceMonitor" "Kubernetes API"
        gorchController -> guardrailsOrchestrator "Creates Deployment, Service, Route, ConfigMap" "Kubernetes API"
        nemoController -> nemoGuardrails "Creates Deployment, Service, Route" "Kubernetes API"
        evalHubController -> evalHub "Creates Deployment, Service, Route, RBAC" "Kubernetes API"
        lmesController -> lmesDriver "Creates Pod with driver sidecar" "Kubernetes API"

        # Operator → platform dependencies
        tasController -> kserve "Watches/patches InferenceServices for payload processing" "Kubernetes API"
        gorchController -> kserve "Discovers generation and detector services" "Kubernetes API"
        tasController -> istio "Creates DestinationRule and VirtualService" "Kubernetes API"
        jobMgrController -> kueue "Creates Workloads for admission control" "Kubernetes API"
        tasController -> prometheus "Creates ServiceMonitors" "Kubernetes API"
        trustyaiOperator -> openshift "Creates Routes, uses serving certs" "Kubernetes API"
        trustyaiOperator -> rhodsOperator "Reads trustyai-dsc-config and odh-trusted-ca-bundle" "ConfigMap"

        # Managed service → external
        trustyaiService -> postgresql "Stores model data" "TCP, TLS optional, Username/Password"
        evalHub -> postgresql "Stores evaluation results" "TCP, TLS optional, Username/Password"
        lmesDriver -> s3Storage "Downloads offline assets" "HTTPS/443, AWS IAM"
        lmesDriver -> ociRegistry "Uploads evaluation results" "HTTPS/443, Username/Password"
        lmesDriver -> huggingFace "Downloads models and datasets" "HTTPS/443, API Token"
        guardrailsOrchestrator -> otlpCollector "Exports telemetry" "gRPC/HTTP, TLS configurable"
        evalHub -> otlpCollector "Exports telemetry" "gRPC/HTTP, TLS configurable"
        guardrailsOrchestrator -> kserve "Proxies to detector and generation services" "HTTP/HTTPS"
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
            element "External - Platform" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal - Platform" {
                background #82b366
                color #ffffff
            }
            element "Managed" {
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
        }
    }
}

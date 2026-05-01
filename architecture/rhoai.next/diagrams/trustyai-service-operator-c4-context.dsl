workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, and monitors model behavior"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator configuration"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing TrustyAI, LMEval, Guardrails, NemoGuardrails, and EvalHub services" {
            operatorBinary = container "Operator Binary" "Main controller-runtime process with 6 controllers" "Go 1.23"
            tasController = container "TAS Controller" "Manages TrustyAIService CRDs, deploys explainability service" "Go Controller"
            lmesController = container "LMES Controller" "Manages LMEvalJob CRDs, orchestrates evaluation jobs" "Go Controller"
            gorchController = container "GORCH Controller" "Manages GuardrailsOrchestrator CRDs, auto-configures from InferenceServices" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Manages NemoGuardrails CRDs" "Go Controller"
            evalhubController = container "EvalHub Controller" "Manages EvalHub CRDs, multi-tenant namespace support" "Go Controller"
            jobMgrController = container "JobMgr Controller" "Wraps LMEvalJobs as Kueue GenericJob workloads" "Go Controller"
            lmesDriver = container "ta-lmes-driver" "Sidecar binary coordinating LM evaluation execution" "Go CLI Binary"
        }

        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        kserve = softwareSystem "KServe" "Model serving with InferenceService CRDs" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Traffic management and mTLS" "External"
        kueue = softwareSystem "Kueue" "Workload admission and resource quota management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"
        openShiftRouter = softwareSystem "OpenShift Router" "Ingress via Routes with TLS termination" "External"
        certController = softwareSystem "OpenShift Serving Cert Controller" "Auto-provisions TLS certificates for Services" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Parent operator providing DSC config" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Database for TAS and EvalHub storage" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifacts and offline assets" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model and dataset downloads" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Evaluation result uploads" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics" "External"

        dataScientist -> trustyaiOperator "Creates CRDs via kubectl (TrustyAIService, LMEvalJob, GuardrailsOrchestrator)"
        platformAdmin -> rhoaiOperator "Configures DSC with TrustyAI component"

        trustyaiOperator -> kubeAPI "Watches CRDs, CRUD resources" "HTTPS/443"
        trustyaiOperator -> kserve "Watches InferenceServices, injects payload processors" "K8s API"
        trustyaiOperator -> istio "Creates DestinationRule and VirtualService for mTLS" "K8s API"
        trustyaiOperator -> kueue "Creates Workloads for admission control" "K8s API"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics scraping" "K8s API"
        trustyaiOperator -> openShiftRouter "Creates Routes for external access" "K8s API"
        trustyaiOperator -> certController "Annotates Services for TLS cert provisioning" "K8s API"
        trustyaiOperator -> postgresql "TAS and EvalHub database storage" "TCP/TLS"
        trustyaiOperator -> s3Storage "LMES offline asset download" "HTTPS/443"
        trustyaiOperator -> huggingFace "LMES model/dataset download" "HTTPS/443"
        trustyaiOperator -> ociRegistry "LMES result upload" "HTTPS/443"
        trustyaiOperator -> otlpCollector "GORCH and EvalHub telemetry export" "gRPC/HTTP"

        rhoaiOperator -> trustyaiOperator "Provides trustyai-dsc-config ConfigMap"
        kserve -> trustyaiOperator "Sends inference payloads to TAS" "HTTP/8080"
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
                color #333333
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #333333
            }
        }
    }
}

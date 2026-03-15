workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and monitors ML models for fairness and explainability"
        llmDeveloper = person "LLM Developer" "Evaluates and protects LLM applications with guardrails"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages AI trustworthiness, fairness monitoring, LLM evaluation, and guardrails" {
            operator = container "TrustyAI Operator" "Manages lifecycle of TrustyAI components" "Go Operator" {
                controller = component "Controller Manager" "Reconciles TrustyAI CRDs and manages resources" "Kubebuilder"
                tasReconciler = component "TrustyAI Service Reconciler" "Manages TrustyAI Service deployments" "Go"
                lmesReconciler = component "LMEval Reconciler" "Manages LMEval job lifecycle" "Go"
                gorchReconciler = component "Guardrails Orchestrator Reconciler" "Manages Guardrails Orchestrator deployments" "Go"
                nemoReconciler = component "NeMo Guardrails Reconciler" "Manages NeMo Guardrails deployments" "Go"
            }

            trustyaiService = container "TrustyAI Service" "Provides explainability, fairness, and drift detection" "Java/Quarkus" {
                apiEndpoint = component "REST API" "Exposes model monitoring endpoints" "Quarkus REST"
                payloadProcessor = component "Payload Processor" "Processes inference payloads from KServe" "Java"
                metricsEngine = component "Metrics Engine" "Calculates fairness and drift metrics" "Java"
            }

            lmevalJob = container "LMEval Job" "Evaluates LLM models using lm-evaluation-harness" "Python Batch Job" {
                evaluator = component "LM Evaluator" "Runs evaluation tasks on LLM models" "Python"
                driver = component "LMES Driver" "Coordinates job execution and communication" "Python/gRPC"
            }

            guardrailsOrchestrator = container "Guardrails Orchestrator" "Orchestrates guardrail detectors for LLM safety" "Java/Quarkus" {
                gateway = component "Gateway" "Routes LLM requests through guardrails" "Quarkus"
                orchestrator = component "Orchestrator" "Coordinates detector execution" "Java"
                detectors = component "Built-in Detectors" "Pre-configured safety detectors" "Java"
            }

            nemoGuardrails = container "NeMo Guardrails" "NVIDIA NeMo guardrails integration" "Python" {
                nemoServer = component "NeMo Server" "Runs NeMo guardrails logic" "Python"
            }

            rbacProxy = container "kube-rbac-proxy" "Secures service endpoints with Kubernetes RBAC" "Go Sidecar"
        }

        kserve = softwareSystem "KServe" "Model serving platform for inference services" "External ODH"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and mTLS" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with Routes" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External ODH"
        kueue = softwareSystem "Kueue" "Job queuing and resource management" "External"
        database = softwareSystem "PostgreSQL/MySQL" "Persistent database for TrustyAI data" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for LMEval outputs" "External"
        modelRegistry = softwareSystem "Model Registry" "LLM model metadata and download" "External"

        # Relationships
        dataScientist -> trustyai "Monitors model fairness and drift, creates TrustyAI services"
        llmDeveloper -> trustyai "Evaluates LLMs, deploys guardrails"

        # Operator relationships
        operator -> kubernetes "Watches and manages resources via API" "HTTPS/6443, TLS 1.3"
        operator -> kserve "Patches InferenceServices for payload logging" "Kubernetes API"
        operator -> istio "Creates VirtualService and DestinationRule" "Kubernetes API"
        operator -> openshift "Creates Routes for external access" "Kubernetes API"
        operator -> kueue "Integrates workload management" "Kubernetes API"

        # TrustyAI Service relationships
        kserve -> trustyaiService "Sends inference payloads for monitoring" "HTTPS/8443, mTLS"
        trustyaiService -> database "Stores metrics and payloads" "PostgreSQL/MySQL, TLS 1.2+"
        trustyaiService -> prometheus "Exports metrics" "HTTPS/9443, mTLS"
        dataScientist -> trustyaiService "Queries fairness metrics and explanations" "HTTPS/443 via Route"

        # LMEval relationships
        lmevalJob -> kserve "Evaluates LLM models" "HTTPS/443 or HTTP/8080"
        lmevalJob -> s3Storage "Stores evaluation results" "HTTPS/443, AWS Signature V4"
        lmevalJob -> modelRegistry "Downloads model metadata" "HTTPS/443"
        llmDeveloper -> lmevalJob "Submits evaluation jobs" "Kubernetes API"

        # Guardrails Orchestrator relationships
        guardrailsOrchestrator -> kserve "Routes LLM requests through detectors" "HTTPS/443, mTLS"
        guardrailsOrchestrator -> kserve "Calls external detector InferenceServices" "HTTPS/443, mTLS"
        llmDeveloper -> guardrailsOrchestrator "Configures guardrails" "HTTPS/443 via Route"

        # NeMo Guardrails relationships
        llmDeveloper -> nemoGuardrails "Configures NeMo guardrails" "HTTPS/443 via Route"
        nemoGuardrails -> kserve "Protects LLM applications" "HTTPS/443"

        # RBAC Proxy
        rbacProxy -> kubernetes "Validates bearer tokens via SubjectAccessReview" "Kubernetes API"
        rbacProxy -> trustyaiService "Secures API access" "HTTPS"
        rbacProxy -> guardrailsOrchestrator "Secures API access" "HTTPS"
        rbacProxy -> nemoGuardrails "Secures API access" "HTTPS"

        # Service Mesh
        istio -> trustyaiService "Enforces mTLS for service mesh" "mTLS"
        istio -> guardrailsOrchestrator "Enforces mTLS for service mesh" "mTLS"
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

        component lmevalJob "LMEvalJobComponents" {
            include *
            autoLayout
        }

        component guardrailsOrchestrator "GuardrailsOrchestratorComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External ODH" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #f5a623
                shape person
            }
        }
    }
}

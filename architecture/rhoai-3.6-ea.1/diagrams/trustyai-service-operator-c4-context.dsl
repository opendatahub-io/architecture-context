workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and needs explainability, bias monitoring, and evaluation"
        mlEngineer = person "ML Engineer" "Deploys models and configures guardrails and safety orchestration"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components and TrustyAI installation"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing AI trustworthiness, evaluation, and safety infrastructure" {
            manager = container "Operator Manager" "Hosts 7 reconciliation loops for TrustyAIService, EvalHub, GuardrailsOrchestrator, NemoGuardrails, LMEvalJob, Job, Workload" "Go controller-runtime"
            platformModule = container "trustyai-operator-module" "Manages platform-level TrustyAI component CRD using odh-platform-utilities" "Go controller-runtime"
            trustyaiService = container "TrustyAI Service" "Quarkus-based explainability and bias monitoring service" "Quarkus (Java)"
            kubeRbacProxy = container "kube-rbac-proxy" "Sidecar enforcing SubjectAccessReview-based authorization on port 8443" "Go"
            conversionWebhook = container "Conversion Webhook" "Handles CRD version conversion for EvalHub resources" "Go"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster-wide TLS security profile configuration" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService resources" "Internal RHOAI"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring infrastructure for ServiceMonitor management" "External"
        kueue = softwareSystem "Kueue" "Job queueing system for workload management" "External"
        odhOperator = softwareSystem "OpenDataHub Operator" "Provisions trustyai-dsc-config ConfigMap for evaluation policy" "Internal RHOAI"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, and deployment helpers" "Internal RHOAI"

        dataScientist -> trustyaiOperator "Creates TrustyAIService, EvalHub, LMEvalJob CRs" "kubectl / RHOAI Dashboard"
        mlEngineer -> trustyaiOperator "Creates GuardrailsOrchestrator, NemoGuardrails CRs" "kubectl / RHOAI Dashboard"
        platformAdmin -> trustyaiOperator "Manages TrustyAI platform component" "RHOAI operator"

        trustyaiOperator -> kubernetesAPI "Watches CRDs, manages owned resources" "HTTPS/6443, TLS 1.2+, SA token"
        trustyaiOperator -> openshiftAPIServer "Reads TLS security profile at startup" "Kubernetes API"
        trustyaiOperator -> kserve "Watches InferenceService for model serving state" "HTTPS, TLS 1.2+"
        trustyaiOperator -> prometheusOperator "Conditionally manages ServiceMonitor resources" "Kubernetes API"
        trustyaiOperator -> kueue "Conditionally reconciles Workload resources" "Kubernetes API"
        trustyaiOperator -> odhOperator "Reads trustyai-dsc-config ConfigMap" "Kubernetes API"
        platformModule -> odhPlatformUtils "Uses for platform detection and manifest rendering" "Go library"

        kubeRbacProxy -> kubernetesAPI "SubjectAccessReview authorization checks" "HTTPS/6443"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

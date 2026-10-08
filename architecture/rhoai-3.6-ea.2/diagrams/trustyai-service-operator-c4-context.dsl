workspace {
    model {
        user = person "Data Scientist" "Creates ML models, runs evaluations, and configures guardrails"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components and multi-tenant configurations"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-domain Kubernetes operator managing AI trustworthiness, evaluation, and guardrails services" {
            manager = container "Manager Binary" "Hosts all six controller domains with dynamic service registration" "Go Operator" "Primary"
            trustyaiModule = container "trustyai-operator-module" "DSC component module managing operator lifecycle within RHOAI" "Go Controller"
            lmesDriver = container "LMES Driver" "Kubernetes-native execution engine coordinating LM evaluation jobs" "Go Executable"

            tasController = component "TrustyAIService Controller" "Reconciles TrustyAIService CRs; deploys service with kube-rbac-proxy" "Controller" {
                tags "Controller"
            }
            evalHubController = component "EvalHub Controller" "Reconciles EvalHub CRs; manages multi-tenant evaluation infrastructure" "Controller" {
                tags "Controller"
            }
            lmEvalController = component "LMEvalJob Controller" "Reconciles LMEvalJob CRs; orchestrates batch evaluation jobs" "Controller" {
                tags "Controller"
            }
            gorchController = component "GuardrailsOrchestrator Controller" "Reconciles GuardrailsOrchestrator CRs" "Controller" {
                tags "Controller"
            }
            nemoController = component "NemoGuardrails Controller" "Reconciles NemoGuardrails CRs" "Controller" {
                tags "Controller"
            }
            profileWatcher = component "ProfileWatcher" "Watches OpenShift TLS profile changes and triggers restart" "Controller" {
                tags "Support"
            }
        }

        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing and scheduling for Kubernetes" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor CRDs" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking" "Internal RHOAI"
        openshift = softwareSystem "OpenShift Platform" "Container platform providing Routes, APIServer config, service-ca" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metric collection" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Network gateway configuration" "External"

        # User interactions
        user -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, GuardrailsOrchestrator, NemoGuardrails CRs" "kubectl / HTTPS"
        platformAdmin -> trustyaiOperator "Creates EvalHub CRs, manages TrustyAI DSC component" "kubectl / HTTPS"

        # Internal dependencies
        trustyaiOperator -> k8sAPI "Manages cluster resources" "HTTPS/6443"
        trustyaiOperator -> kserve "Watches InferenceService and ServingRuntime CRDs" "HTTPS/6443"
        trustyaiOperator -> kueue "Integrates evaluation job scheduling" "HTTPS/6443"
        trustyaiOperator -> istio "Creates VirtualServices, DestinationRules" "HTTPS/6443"
        trustyaiOperator -> prometheusOperator "Creates ServiceMonitors" "HTTPS/6443"
        trustyaiOperator -> mlflow "Creates MLflow experiments for EvalHub" "HTTPS/6443"
        trustyaiOperator -> openshift "Reads TLS profile, creates Routes" "HTTPS/6443"
        trustyaiOperator -> otel "Exports traces and metrics" "OTLP/gRPC"
        trustyaiOperator -> gatewayAPI "Reads gateway resources for NemoGuardrails" "HTTPS/6443"
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
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Support" {
                background #b8d4f0
                color #333333
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
        }
    }
}

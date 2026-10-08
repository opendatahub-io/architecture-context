workspace {
    model {
        datascientist = person "Data Scientist" "Creates TrustyAI services and evaluation jobs for ML model trustworthiness"
        platformadmin = person "Platform Admin" "Configures operator and manages platform components"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-service Kubernetes operator managing model explainability, LLM evaluation, and safety guardrails" {
            manager = container "Operator Manager" "Main operator binary; registers schemes, selectively enables controllers" "Go / controller-runtime"
            tasController = container "TrustyAIService Controller" "Reconciles TrustyAIService CRs; deploys explainability service with kube-rbac-proxy" "Go Controller"
            evalHubController = container "EvalHub Controller" "Reconciles EvalHub CRs; multi-tenant evaluation hub with tenant namespace provisioning" "Go Controller"
            lmevalController = container "LMEvalJob Controller" "Reconciles LMEvalJob CRs; manages evaluation job lifecycle with batch Jobs" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Reconciles NemoGuardrails CRs; deploys NVIDIA NeMo safety guardrails" "Go Controller"
            tlsWatcher = container "TLS Profile Watcher" "Watches OpenShift APIServer for TLS profile changes; triggers restart" "Go Controller"
            conversionWebhook = container "Conversion Webhook" "CRD version conversion for EvalHub and TrustyAIService" "Go Webhook / 9443"
            lmesDriver = container "LMES Driver" "Sidecar driver for evaluation jobs; coordinates execution with progress monitoring" "Go Executable"
            lmesJob = container "LMES Job" "Python evaluation environment running lm-evaluation-harness" "Python 3.11"
        }

        kserve = softwareSystem "KServe" "Model serving platform for inference services" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        kueue = softwareSystem "Kueue" "Workload queue management for evaluation jobs" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitors" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking for evaluation results" "External"
        openshiftAPI = softwareSystem "OpenShift Platform" "Routes, TLS profiles, service-ca certificates" "External"
        gatewayAPI = softwareSystem "Gateway API" "Ingress gateway configuration" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Per-request SubjectAccessReview enforcement" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "Target model for evaluation" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Platform management UI" "Internal RHOAI"
        dsc = softwareSystem "DataScienceCluster" "Platform component lifecycle management" "Internal RHOAI"

        # User interactions
        datascientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub CRs" "kubectl / HTTPS"
        platformadmin -> trustyaiOperator "Configures operator, manages TrustyAI component CR" "kubectl / HTTPS"

        # Internal container relationships
        manager -> tasController "Enables via --enable-services=TAS"
        manager -> evalHubController "Enables via --enable-services=EVALHUB"
        manager -> lmevalController "Enables via --enable-services=LMES"
        manager -> nemoController "Enables via --enable-services=NEMO_GUARDRAILS"
        manager -> tlsWatcher "Starts TLS profile watching"
        manager -> conversionWebhook "Serves CRD conversion"
        lmevalController -> lmesDriver "Injects into evaluation Job pods"
        lmevalController -> lmesJob "Injects into evaluation Job pods"

        # External dependencies
        trustyaiOperator -> kserve "Watches InferenceServices for model state correlation" "HTTPS/6443"
        trustyaiOperator -> istio "Creates VirtualServices and DestinationRules" "HTTPS/6443"
        trustyaiOperator -> kueue "Watches Workloads for evaluation job queue status" "HTTPS/6443"
        trustyaiOperator -> prometheusOperator "Creates ServiceMonitors for metrics scraping" "HTTPS/6443"
        trustyaiOperator -> mlflow "Creates experiments for evaluation result tracking" "HTTPS/6443"
        trustyaiOperator -> openshiftAPI "Creates Routes; reads TLS profile; uses service-ca" "HTTPS/6443"
        trustyaiOperator -> gatewayAPI "Reads Gateway resources for ingress config" "HTTPS/6443"
        trustyaiOperator -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        lmesJob -> modelEndpoint "Sends inference requests during evaluation" "HTTPS"
        tasController -> kubeRBACProxy "Deploys as sidecar for TrustyAI service pods"

        # Consumers
        dsc -> trustyaiOperator "Manages TrustyAI component lifecycle" "CRD"
        odhDashboard -> trustyaiOperator "Platform UI integration" "CRD"
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
        }
    }
}

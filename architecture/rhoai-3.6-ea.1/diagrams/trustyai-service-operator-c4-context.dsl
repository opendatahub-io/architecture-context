workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and needs explainability, evaluation, and guardrails"
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI platform components"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller Kubernetes operator managing AI trustworthiness workloads: explainability, evaluation, and guardrails" {
            controllerManager = container "Controller Manager" "Multi-controller operator binary with 8 controllers across 3 domains" "Go / controller-runtime"
            webhookServer = container "Webhook Server" "CRD version conversion (EvalHub, TrustyAIService v1 ↔ v1alpha1)" "Go / :9443 TLS"
            trustyaiService = container "TrustyAI Service Pod" "Two-container pod: kube-rbac-proxy + TrustyAI Quarkus service" "Quarkus + kube-rbac-proxy"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        openshiftConfig = softwareSystem "OpenShift Platform" "Provides TLS profiles, Routes, cluster configuration" "External"
        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator providing DSC ConfigMap for TrustyAI configuration" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService resources" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queuing system (optional)" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring stack providing ServiceMonitor CRDs" "External"
        storage = softwareSystem "Data Storage" "PVC or external database for TrustyAI data persistence" "External"

        dataScientist -> trustyaiOperator "Creates TrustyAIService, EvalHub, LMEvalJob, GuardrailsOrchestrator, NemoGuardrails CRs"
        platformAdmin -> trustyaiOperator "Configures TrustyAI module via DSC"
        dataScientist -> trustyaiService "Sends inference explainability requests" "HTTPS/443 → 8443"

        controllerManager -> kubernetesAPI "Watches CRDs and manages owned resources" "HTTPS/6443"
        controllerManager -> openshiftConfig "Reads TLS security profile" "Kubernetes API"
        controllerManager -> odhOperator "Reads trustyai-dsc-config ConfigMap" "Kubernetes API"
        controllerManager -> kserve "Watches InferenceService resources" "Kubernetes API"
        controllerManager -> kueue "Discovers and uses Workload API (optional)" "Kubernetes API"
        controllerManager -> prometheusOp "Creates ServiceMonitor resources (conditional)" "Kubernetes API"
        controllerManager -> trustyaiService "Creates and manages per-namespace service pods"

        trustyaiService -> kubernetesAPI "TokenReview + SubjectAccessReview for auth" "HTTPS/6443"
        trustyaiService -> storage "Reads/writes explainability data" "Storage protocol"

        kubernetesAPI -> webhookServer "CRD conversion requests" "HTTPS/9443"
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

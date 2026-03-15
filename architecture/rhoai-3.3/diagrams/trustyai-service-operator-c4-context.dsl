workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys ML models with explainability, fairness monitoring, and guardrails"
        admin = person "Platform Administrator" "Manages TrustyAI operator and services"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages deployment and lifecycle of TrustyAI explainability, monitoring, guardrails, and LLM evaluation services" {
            controller = container "Operator Controller" "Manages TrustyAI component lifecycle" "Go Operator (Kubebuilder v4)" {
                reconciler = component "Reconciler" "Watches CRs and reconciles desired state"
                webhook = component "Conversion Webhook" "Converts v1alpha1 to v1 CRs"
            }
            trustyaiService = container "TrustyAI Service" "Provides model explainability, fairness, and drift detection" "Quarkus Java Service"
            lmevalDriver = container "LM Evaluation Driver" "Orchestrates language model evaluation jobs" "Job Controller"
            guardrailsOrch = container "Guardrails Orchestrator" "Coordinates FMS guardrail detectors" "Deployment"
            nemoGuardrails = container "Nemo Guardrails" "NVIDIA NeMo guardrails integration" "Deployment"
            rbacProxy = container "kube-rbac-proxy" "Authenticates and authorizes metrics access" "Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        kserve = softwareSystem "KServe" "ML model serving platform" "Internal ODH"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"
        kueue = softwareSystem "Kueue" "Job queueing system for batch workloads" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with Routes and certificates" "External"
        database = softwareSystem "Database" "PostgreSQL or MySQL for persistent storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        modelmesh = softwareSystem "Model Mesh" "Alternative model serving platform" "Internal ODH"

        # User interactions
        user -> trustyai "Creates TrustyAIService, LMEvalJob, GuardrailsOrchestrator via kubectl"
        admin -> trustyai "Installs and configures operator"

        # TrustyAI component interactions
        controller -> kubernetes "Manages Deployments, Services, Routes, PVCs via API" "HTTPS/6443 TLS 1.2+"
        controller -> kserve "Patches InferenceServices, watches serving resources" "HTTPS/6443 TLS 1.2+"
        controller -> istio "Creates VirtualServices and DestinationRules" "HTTPS/6443 TLS 1.2+"
        controller -> prometheus "Creates ServiceMonitors for metrics collection" "HTTPS/6443 TLS 1.2+"
        controller -> kueue "Submits LMEvalJob workloads to queue" "HTTPS/6443 TLS 1.2+"
        controller -> openshift "Creates Routes for external access" "HTTPS/6443 TLS 1.2+"

        trustyaiService -> database "Stores inference data, metrics, and monitoring results" "JDBC TLS (optional)"
        trustyaiService -> kserve "Monitors InferenceService predictions" "HTTP/HTTPS 80/443 mTLS"
        trustyaiService -> modelmesh "Monitors ModelMesh serving via label selector" "HTTP/HTTPS mTLS"

        lmevalDriver -> huggingface "Downloads models and datasets for evaluation" "HTTPS/443 TLS 1.2+"
        lmevalDriver -> kserve "Queries models for evaluation tasks" "gRPC/HTTP TLS"

        guardrailsOrch -> kserve "Routes requests through detector services" "HTTP/HTTPS 80/443 mTLS"

        prometheus -> rbacProxy "Scrapes operator metrics" "HTTPS/8443 Bearer Token"
        prometheus -> trustyaiService "Scrapes TrustyAI service metrics" "HTTP/8080"
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

        component controller "Components" {
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
                color #000000
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

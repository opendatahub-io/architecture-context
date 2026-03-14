workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models with explainability, fairness monitoring, and guardrails"
        mlEngineer = person "ML Engineer" "Evaluates LLM performance and implements safety guardrails"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages deployment and lifecycle of TrustyAI explainability, monitoring, guardrails, and LLM evaluation services" {
            controller = container "Operator Controller" "Manages TrustyAI custom resources and reconciliation" "Go, Kubebuilder v4"
            conversionWebhook = container "Conversion Webhook" "Converts TrustyAIService CRs between v1alpha1 and v1" "Go"
            trustyaiService = container "TrustyAI Service" "Provides model explainability, fairness monitoring, and drift detection" "Quarkus, Java"
            lmEvalDriver = container "LM Evaluation Driver" "Orchestrates language model evaluation jobs" "Python"
            guardrailsOrchestrator = container "Guardrails Orchestrator" "Coordinates FMS guardrail detectors for LLM safety" "Python"
            nemoGuardrails = container "Nemo Guardrails" "NVIDIA NeMo guardrails integration" "Python"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        kserve = softwareSystem "KServe" "ML model serving platform for inference" "Internal ODH"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kueue = softwareSystem "Kueue" "Job queueing system for batch workloads" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with Routes and certificates" "External"
        database = softwareSystem "Database" "PostgreSQL or MySQL for inference data storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Repository for ML models and datasets" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates TrustyAIService and GuardrailsOrchestrator CRs via kubectl"
        mlEngineer -> trustyaiOperator "Creates LMEvalJob CRs for LLM evaluation"

        # TrustyAI Operator relationships
        trustyaiOperator -> kubernetes "Manages deployments, services, secrets, and PVCs" "Kubernetes API/6443 HTTPS"
        trustyaiOperator -> kserve "Monitors InferenceServices and patches for guardrails" "Kubernetes API/6443 HTTPS"
        trustyaiOperator -> istio "Creates VirtualServices and DestinationRules" "Kubernetes API/6443 HTTPS"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics" "Kubernetes API/6443 HTTPS"
        trustyaiOperator -> kueue "Submits LMEvalJob workloads to queue" "Kubernetes API/6443 HTTPS"
        trustyaiOperator -> openshift "Creates Routes for external access" "Kubernetes API/6443 HTTPS"

        # TrustyAI Service relationships
        controller -> trustyaiService "Deploys and configures"
        trustyaiService -> database "Stores inference data and metrics" "JDBC/TLS"
        trustyaiService -> kserve "Monitors model inference data" "HTTP/HTTPS mTLS"
        prometheus -> trustyaiService "Scrapes /q/metrics" "HTTP/8080"

        # LM Evaluation relationships
        controller -> lmEvalDriver "Creates evaluation jobs"
        lmEvalDriver -> huggingface "Downloads models and datasets" "HTTPS/443"
        lmEvalDriver -> kserve "Sends inference requests for evaluation" "gRPC/HTTP"

        # Guardrails relationships
        controller -> guardrailsOrchestrator "Deploys guardrails orchestrator"
        controller -> nemoGuardrails "Deploys NeMo guardrails"
        guardrailsOrchestrator -> kserve "Routes requests through detector InferenceServices" "HTTP/HTTPS mTLS"
        dataScientist -> guardrailsOrchestrator "Sends inference requests" "HTTPS/443"
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
                color #000000
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #000000
            }
        }

        theme default
    }
}

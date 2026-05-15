workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, configures guardrails"
        mlEngineer = person "ML Engineer" "Deploys and monitors ML models in production"
        securityTeam = person "Security Team" "Configures guardrails policies and reviews AI safety"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing AI trustworthiness, evaluation, and guardrails services on RHOAI" {
            operatorManager = container "Operator Manager" "Single-replica Deployment running all enabled controllers" "Go 1.24 / controller-runtime v0.17.0" {
                tasController = component "TAS Controller" "Manages TrustyAIService CR lifecycle, creates Deployments with kube-rbac-proxy, integrates KServe/ModelMesh" "Go Controller"
                lmesController = component "LMES Controller" "Manages LMEvalJob CR lifecycle, creates ephemeral evaluation Pods" "Go Controller"
                evalHubController = component "EvalHub Controller" "Manages EvalHub CR lifecycle with multi-tenant evaluation framework" "Go Controller"
                gorchController = component "GORCH Controller" "Manages GuardrailsOrchestrator CR lifecycle with auto-discovery" "Go Controller"
                nemoController = component "NeMo Controller" "Manages NemoGuardrails CR lifecycle with CA bundle management" "Go Controller"
                jobMgrController = component "JobManager Controller" "Optional Kueue integration wrapping LMEvalJob as Workload" "Go Controller"
            }
            lmesDriver = container "ta-lmes-driver" "Execution engine for LMEvalJob pods, handles device detection, progress, output upload" "Go CLI (init container)"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator deploying RHOAI components via kustomize" "Internal RHOAI"

        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService CRD" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Kubernetes-native job scheduling and resource management" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management (VirtualService, DestinationRule)" "External"
        openShiftServiceCA = softwareSystem "OpenShift service-ca-operator" "Automatic TLS certificate generation for Services" "Internal OpenShift"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar enforcing SubjectAccessReview authentication" "Internal OpenShift"

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes API for resource management" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for TAS and EvalHub data storage" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts and offline assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation result upload" "External"
        targetLLM = softwareSystem "Target LLM Endpoints" "Language model endpoints for evaluation and guardrails" "External"

        # User relationships
        dataScientist -> trustyaiOperator "Creates LMEvalJob, EvalHub evaluations via kubectl/API"
        mlEngineer -> trustyaiOperator "Creates TrustyAIService for bias monitoring"
        securityTeam -> trustyaiOperator "Configures GuardrailsOrchestrator, NemoGuardrails"

        # Platform deployment
        rhodsOperator -> trustyaiOperator "Deploys via kustomize overlays" "kustomize"

        # Internal integrations
        trustyaiOperator -> kserve "Watches InferenceService CRDs, sets inference loggers, auto-discovers detectors" "HTTPS/443 (K8s API)"
        trustyaiOperator -> modelMesh "Patches MM_PAYLOAD_PROCESSORS env on Deployments" "HTTPS/443 (K8s API)"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics scraping" "HTTPS/443 (K8s API)"
        trustyaiOperator -> kueue "Wraps LMEvalJob as Kueue Workload for scheduling" "HTTPS/443 (K8s API)"
        trustyaiOperator -> istio "Creates VirtualService/DestinationRule for TAS (conditional)" "HTTPS/443 (K8s API)"
        trustyaiOperator -> openShiftServiceCA "Annotates Services for auto TLS cert generation" "Service annotation"
        trustyaiOperator -> kubeRbacProxy "Injects as sidecar for TAS, GORCH, NeMo auth" "Pod sidecar"

        # External service calls
        trustyaiOperator -> kubernetesAPI "CR management, resource creation, pod/exec" "HTTPS/443 TLS 1.2+"
        trustyaiOperator -> postgresql "TAS/EvalHub data storage" "JDBC TLS optional"
        trustyaiOperator -> huggingfaceHub "LMES model/dataset downloads (online mode)" "HTTPS/443"
        trustyaiOperator -> s3Storage "LMES offline asset download" "HTTPS/443"
        trustyaiOperator -> ociRegistry "LMES evaluation result upload" "HTTPS/443"
        trustyaiOperator -> targetLLM "LMES evaluation queries, GORCH detector requests" "HTTP/HTTPS varies"
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

        component operatorManager "Components" {
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
            element "Internal OpenShift" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
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

workspace "trustyai-service-operator (RHOAI 3.7-ea.1)" "C4 context and containers for the TrustyAI service operator" {

    model {
        dataScientist = person "Data Scientist" "Creates TrustyAIService, LMEvalJob, EvalHub and NemoGuardrails CRs; calls operand APIs"
        platformAdmin = person "Platform Admin" "Enables TrustyAI via the DataScienceCluster / TrustyAI component CR"

        trustyai = softwareSystem "TrustyAI Service Operator" "Deploys and manages RHOAI AI trust, safety and evaluation workloads from namespaced CRs" {
            module = container "trustyai-operator-module" "Reconciles cluster TrustyAI (default-trustyai); renders and SSA-applies the bundled rhoai overlay. Metrics :8080 HTTP (no auth)" "Go, controller-runtime"
            manager = container "trustyai-service-operator manager" "Runs TAS, LMES, EVALHUB, NEMO_GUARDRAILS controllers, EvalHub failure reconcilers, ProfileWatcher. Metrics :8443 HTTPS (TokenReview+SAR)" "Go, controller-runtime v0.23.3"
            webhook = container "Conversion Webhook" "/convert for TrustyAIService and EvalHub v1alpha1/v1. 9443/TCP, Service 443" "Go, controller-runtime webhook"
            driver = container "LMES Driver" "Copied into LMEvalJob pods; launches lm-eval, answers --get-status / --shutdown via pods/exec" "Go binary"
            tasOperand = container "TrustyAI Service" "Explainability / fairness / drift service. kube-rbac-proxy 8443, internal-tls-proxy 4443, app 8081/8080" "Operand Deployment"
            evalhubOperand = container "EvalHub" "Multi-tenant evaluation orchestration REST API, optional MCP. kube-rbac-proxy 8443 to 127.0.0.1:8444" "Operand Deployment"
            nemoOperand = container "NeMo Guardrails" "Guardrails server 8000 with optional kube-rbac-proxy user 8443 / admin 8444" "Operand Deployment"
            lmesPod = container "LMEvalJob Pod" "lm-evaluation-harness / Unitxt evaluation runtime" "Python, Pod"
        }

        rhods = softwareSystem "rhods-operator" "RHOAI platform operator; manages the TrustyAI component CR" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "eval-hub-ui BFF proxies browser requests to EvalHub" "Internal RHOAI"
        kserve = softwareSystem "KServe / ModelMesh" "Model serving; InferenceServices patched to send payloads to TrustyAI" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking (mlflow.kubeflow.org)" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes / OpenShift API" "API server 6443/TCP, Routes, service-ca, APIServer TLS profile" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping; module precondition" "External"
        istio = softwareSystem "Istio" "DestinationRule / VirtualService for KServe Raw mode" "External"
        kueue = softwareSystem "Kueue" "Workload admission; EvalHub failure reporting" "External"
        postgres = softwareSystem "PostgreSQL" "EvalHub / TAS database storage (optional)" "External"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "Target model evaluated by LMEvalJob" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Optional OTLP trace/metric export" "External"

        platformAdmin -> rhods "Enables TrustyAI component"
        rhods -> module "Creates TrustyAI CR (via Kubernetes API)" "HTTPS/6443"
        module -> k8s "SSA applies CRDs, RBAC, operator Deployment" "HTTPS/6443"
        module -> prometheus "Checks Prometheus instance exists" "HTTPS/6443 (API read)"
        dataScientist -> k8s "Creates TrustyAI CRs" "HTTPS/6443"
        manager -> k8s "Watch/CRUD CRs and operands, pods/exec" "HTTPS/6443"
        k8s -> webhook "CRD conversion" "HTTPS/443 to 9443"
        manager -> tasOperand "Creates and configures"
        manager -> evalhubOperand "Creates; POSTs failure events" "HTTPS/8443"
        manager -> nemoOperand "Creates and configures"
        manager -> lmesPod "Creates; polls driver via pods/exec"
        manager -> kserve "Patches InferenceService logger / MM_PAYLOAD_PROCESSORS" "HTTPS/6443"
        manager -> istio "Creates DestinationRule / VirtualService" "HTTPS/6443"
        manager -> kueue "Watches Workloads" "HTTPS/6443"
        manager -> otel "Exports traces/metrics (opt-in)" "OTLP gRPC/HTTP"
        lmesPod -> driver "Runs"
        kserve -> tasOperand "Inference payload logging" "HTTPS/4443 or HTTP/8080"
        dataScientist -> tasOperand "TrustyAI API via Route" "HTTPS/443 reencrypt, Bearer"
        dataScientist -> evalhubOperand "EvalHub API via Route" "HTTPS/443 reencrypt, Bearer + X-Tenant"
        dataScientist -> nemoOperand "Guardrails API via Route" "HTTPS/443"
        dashboard -> evalhubOperand "Proxies EvalHub UI requests" "HTTPS/8443"
        evalhubOperand -> postgres "Stores evaluations" "DSN"
        evalhubOperand -> mlflow "Experiment tracking" "HTTPS/443, projected SA token"
        evalhubOperand -> k8s "Creates evaluation Jobs in tenant namespaces" "HTTPS/6443"
        tasOperand -> postgres "DATABASE storage mode (optional)" "DB credentials secret"
        lmesPod -> modelEndpoint "Evaluation requests" "HTTP/HTTPS"
        prometheus -> manager "Scrapes metrics" "HTTPS/8443 Bearer"
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

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6fa8dc
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}

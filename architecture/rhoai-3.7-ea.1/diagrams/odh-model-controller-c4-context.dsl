workspace "odh-model-controller" "RHOAI 3.7-ea.1 model serving platform controller" {
    model {
        user = person "Data Scientist" "Deploys InferenceServices, LLMInferenceServices and NIM Accounts"
        client = person "Inference Client" "Calls deployed model endpoints"

        omc = softwareSystem "odh-model-controller" "Extends KServe on OpenShift AI with Routes, RBAC, NetworkPolicies, monitoring, auth policies, certificates and RHOAI admission rules" {
            manager = container "odh-model-controller manager" "Reconcilers for ISVC, LLMISVC, Gateway, Grid, ServingRuntime, InferenceGraph, Secret, ConfigMap, Pod, NIM Account; ProfileWatcher; MaaS RBAC cleanup" "Go, controller-runtime v0.25.2"
            webhooks = container "Admission Webhook Server" "5 mutating + 5 validating webhooks, failurePolicy Fail (9443/TCP HTTPS)" "Go, controller-runtime"
            api = container "model-serving-api" "Gateway discovery (Bearer + SSAR as user) and llm-d samples (8443/TCP HTTPS)" "Go HTTPS service"
            runtimes = container "ClusterServingRuntimes / Templates" "30 runtimes: vLLM CUDA/ROCm/Gaudi/Spyre/CPU, vLLM-Omni, MLServer, OVMS" "Kustomize manifests"
        }

        k8s = softwareSystem "Kubernetes / OpenShift API" "kube-apiserver, APIServer TLS profile config" "External"
        kserve = softwareSystem "KServe" "Core serving lifecycle: ISVC, LLMISVC, ServingRuntime, InferenceGraph" "Internal ODH"
        operator = softwareSystem "RHOAI Operator" "Deploys manifests; DataScienceCluster, DSCInitialization, HardwareProfile" "Internal ODH"
        dashboard = softwareSystem "RHOAI Dashboard" "UI consuming model-serving-api" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Optional ISVC registration" "Internal ODH"
        grid = softwareSystem "Grid (grid.praxis.fast)" "InferenceProvider publication" "Internal ODH"
        istio = softwareSystem "Gateway API / Istio" "Gateways and EnvoyFilters for llm-d" "External"
        kuadrant = softwareSystem "Kuadrant / Authorino" "AuthPolicy-based token auth" "External"
        keda = softwareSystem "KEDA" "Prometheus-based autoscaling" "External"
        prometheus = softwareSystem "Prometheus / User Workload Monitoring" "Metrics scraping" "External"
        router = softwareSystem "OpenShift Router" "Exposes raw ISVC Routes" "External"
        serviceCA = softwareSystem "OpenShift service-ca" "Serving certificates (cert-manager in xKS)" "External"
        ngc = softwareSystem "NVIDIA NGC" "api.ngc.nvidia.com, authn.nvidia.com, nvcr.io" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Optional trace export" "External"

        user -> k8s "Creates ISVC / LLMISVC / Account" "HTTPS/6443"
        client -> router "Calls raw ISVC endpoints" "HTTPS/443, Bearer"
        client -> istio "Calls LLMISVC endpoints via Gateway" "HTTPS/443, Bearer"
        k8s -> webhooks "Admission requests" "HTTPS 443->9443"
        manager -> k8s "Watches and reconciles resources" "HTTPS/6443, SA token"
        api -> k8s "Lists Gateways; SSAR as user" "HTTPS/6443"
        dashboard -> api "Gateway discovery, llm-d samples" "HTTPS 443->8443, user Bearer"
        operator -> omc "Deploys and parameterizes"
        omc -> kserve "Extends KServe resources" "CRD watch/patch, admission"
        manager -> istio "Creates EnvoyFilters, watches Gateways"
        manager -> kuadrant "Creates AuthPolicies"
        manager -> keda "Creates TriggerAuthentications"
        manager -> prometheus "Creates ServiceMonitors/PodMonitors"
        prometheus -> manager "Scrapes metrics" "HTTPS/8443, TokenReview + SAR"
        manager -> router "Creates Routes"
        manager -> grid "Publishes InferenceProviders"
        manager -> modelRegistry "Registers ISVCs (optional)" "HTTPS, SA Bearer"
        manager -> ngc "Validates NGC key, fetches catalog" "HTTPS/443, NGC API key"
        serviceCA -> omc "Issues TLS serving certs"
        api -> otel "Exports traces (optional)" "OTLP/gRPC"
    }

    views {
        systemContext omc "SystemContext" {
            include *
            autoLayout
        }

        container omc "Containers" {
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
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

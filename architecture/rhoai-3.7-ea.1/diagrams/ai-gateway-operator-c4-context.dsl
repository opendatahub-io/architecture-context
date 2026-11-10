workspace "AI Gateway Operator" "RHOAI 3.7-ea.1 module operator for AI Gateway sub-components" {
    model {
        admin = person "Platform Administrator" "Enables AI Gateway sub-components via DataScienceCluster / AIGateway"
        prometheusUser = person "SRE" "Monitors operator health and metrics"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Module operator that reconciles the AIGateway singleton CR and lifecycles batch gateway, MaaS, ai-gateway-controller and Praxis AI Grid" {
            manager = container "manager" "Runs the AIGateway reconciler, probes (:8081) and HTTPS metrics (:8443)" "Go, controller-runtime, Cobra"
            initContainer = container "copy-manifests" "Copies vendored manifests into /opt/manifests emptyDir" "Init container"
            reconciler = container "AIGateway Reconciler" "Renders and SSA-deploys sub-component kustomize trees, GC, status aggregation" "Go, opendatahub-operator reconciler framework"
            tlsWatcher = container "TLS Profile Watcher" "Resolves OpenShift APIServer TLS profile and restarts on change" "Go, controller-runtime-common"
            manifests = container "Vendored Manifests" "Pinned kustomize trees for batchgateway, maascontroller, aigatewaycontroller, aigrid" "Kustomize / YAML"

            initContainer -> manifests "Copies"
            manager -> reconciler "Runs"
            manager -> tlsWatcher "Runs"
            reconciler -> manifests "Rewrites params.env and renders"
        }

        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator; deploys this module, injects RELATED_IMAGE_*, maintains odh-aigateway-config" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes / OpenShift API Server" "Cluster API; AIGateway CR, TLS profile, TokenReview/SAR" "External"
        maas = softwareSystem "Models-as-a-Service" "maas-controller, maas-api; MaaS CRDs and validating webhook" "Internal RHOAI"
        aiGatewayController = softwareSystem "ai-gateway-controller" "AIGuardrail controller with praxis-extproc and kube-auth-proxy" "Internal RHOAI"
        batchGateway = softwareSystem "llm-d Batch Gateway Operator" "Manages LLMBatchGateway instances" "Internal RHOAI"
        aiGrid = softwareSystem "Praxis AI Grid" "grid-operator and grid.praxis.fast CRDs (Tech Preview)" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant / Authorino (RHCL)" "AuthPolicy, RateLimitPolicy, TokenRateLimitPolicy" "External"
        istio = softwareSystem "Gateway API / OpenShift Service Mesh" "HTTPRoutes, EnvoyFilters, DestinationRules" "External"
        certManager = softwareSystem "cert-manager" "Certificates (xKS overlay)" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues metrics serving certificate" "External"
        monitoring = softwareSystem "OpenShift Monitoring (Prometheus)" "Scrapes metrics; ServiceMonitors/PrometheusRules" "External"
        kserve = softwareSystem "KServe" "LLMInferenceService read for MaaS discovery" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "NemoGuardrails read for guardrails" "Internal RHOAI"

        admin -> platformOperator "Enables components"
        prometheusUser -> monitoring "Views dashboards and alerts"
        platformOperator -> aiGatewayOperator "Deploys overlay, sets AIGateway toggles, injects env" "HTTPS/6443"
        aiGatewayOperator -> k8sApi "Watch, SSA apply, GC, status, TokenReview/SAR" "HTTPS/6443 TLS 1.2+"
        aiGatewayOperator -> maas "Deploys; teardown handshake; reads Config readiness/TenantsHealthy" "via API server"
        aiGatewayOperator -> aiGatewayController "Deploys (bound to MaaS toggle)" "via API server"
        aiGatewayOperator -> batchGateway "Deploys when batchGateway Managed" "via API server"
        aiGatewayOperator -> aiGrid "Installs CRDs, deploys grid-operator into redhat-ai-grid" "via API server"
        aiGatewayOperator -> kuadrant "Applies vendored policies (RBAC escalation)" "via API server"
        aiGatewayOperator -> istio "Applies vendored routing objects" "via API server"
        aiGatewayOperator -> certManager "Applies Certificates (xKS)" "via API server"
        serviceCa -> aiGatewayOperator "Issues ai-gateway-operator-metrics-tls"
        monitoring -> aiGatewayOperator "Scrapes /metrics" "HTTPS/8443 Bearer"
        maas -> kserve "Discovers LLMInferenceServices"
        aiGatewayController -> trustyai "Reads NemoGuardrails"
        aiGatewayOperator -> platformOperator "Reports AIGateway status and releases[platform]" "via API server"
    }

    views {
        systemContext aiGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container aiGatewayOperator "Containers" {
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

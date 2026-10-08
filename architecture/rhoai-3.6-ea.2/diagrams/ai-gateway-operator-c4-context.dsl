workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components and configuration"
        dataScientist = person "Data Scientist" "Consumes model inference endpoints via MaaS"

        aiGatewayOperator = softwareSystem "ai-gateway-operator" "Module operator that deploys and manages AI Gateway sub-components (MaaS, Batch Gateway, AI Gateway Controller) for RHOAI" {
            reconciler = container "Reconciler" "Reconciles AIGateway CR, manages sub-component lifecycle via declarative action chain" "Go / controller-runtime"
            tlsProfileWatcher = container "SecurityProfileWatcher" "Watches OpenShift TLS profile changes and triggers graceful restarts" "Go"
            metricsServer = container "Metrics Server" "Serves Prometheus metrics with cluster TLS profile and RBAC auth" "HTTPS 8443/TCP"
            healthServer = container "Health Server" "Liveness and readiness probes" "HTTP 8081/TCP"
        }

        maasController = softwareSystem "maas-controller" "Models as a Service controller - manages tenants, subscriptions, and API gateway routing for multi-tenant model inference" "Vendored Sub-Component"
        batchGatewayOperator = softwareSystem "batch-gateway-operator" "LLM-d batch gateway operator for batch LLM inference processing" "Vendored Sub-Component"
        aiGatewayController = softwareSystem "ai-gateway-controller" "Gateway routing controller with praxis-extproc for inference traffic" "Vendored Sub-Component"

        opendatahubOperator = softwareSystem "opendatahub-operator" "Platform operator that manages RHOAI module lifecycle" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML model serving platform (LLMInferenceService)" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for inference routing" "External"
        kuadrant = softwareSystem "Kuadrant" "API governance: auth policies and rate limiting" "External"
        authorino = softwareSystem "Authorino" "Authentication backend" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Observability stack for monitoring" "External"
        openTelemetry = softwareSystem "OpenTelemetry" "Distributed tracing" "External"
        perses = softwareSystem "Perses" "Observability dashboards" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource management" "Infrastructure"

        // Relationships
        platformAdmin -> opendatahubOperator "Configures RHOAI platform"
        opendatahubOperator -> aiGatewayOperator "Deploys via module handler, writes platformVersion ConfigMap" "Kubernetes API / HTTPS 6443"
        aiGatewayOperator -> kubernetesAPI "CRD reconciliation, resource management, RBAC operations" "HTTPS/6443 TLS 1.2+"
        aiGatewayOperator -> maasController "Deploys via kustomize when modelsAsAService=Managed" "Kubernetes API"
        aiGatewayOperator -> batchGatewayOperator "Deploys via kustomize when batchGateway=Managed" "Kubernetes API"
        aiGatewayOperator -> aiGatewayController "Deploys alongside maas-controller" "Kubernetes API"
        aiGatewayOperator -> certManager "Manages TLS certificates for sub-components" "Kubernetes API"
        aiGatewayOperator -> prometheusOperator "Creates ServiceMonitors, PodMonitors, PrometheusRules" "Kubernetes API"
        aiGatewayOperator -> istio "Manages DestinationRules, EnvoyFilters, ServiceEntries" "Kubernetes API"
        aiGatewayOperator -> openTelemetry "Creates OpenTelemetryCollectors" "Kubernetes API"
        aiGatewayOperator -> perses "Creates dashboards and datasources" "Kubernetes API"
        aiGatewayOperator -> kserve "Watches LLMInferenceService for MaaS routing" "Kubernetes API"

        maasController -> gatewayAPI "Creates HTTPRoutes for model routing" "Kubernetes API"
        maasController -> kuadrant "Manages AuthPolicies and RateLimitPolicies" "Kubernetes API"
        maasController -> authorino "Authentication backend" "Kubernetes API"
        aiGatewayController -> gatewayAPI "Gateway routing with praxis-extproc" "Kubernetes API"

        dataScientist -> maasController "Creates model subscriptions via MaaS CRs"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Vendored Sub-Component" {
                background #50c878
            }
            element "Infrastructure" {
                background #f5a623
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

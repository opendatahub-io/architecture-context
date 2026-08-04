workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures AI Gateway infrastructure via AIGateway CRs"
        tenant = person "MaaS Tenant" "Consumes model-as-a-service endpoints provisioned by the gateway"

        aiGatewayOperator = softwareSystem "ai-gateway-operator" "Kubernetes operator that reconciles AIGateway CRs to provision AI inference gateway infrastructure including routing, auth, rate-limiting, and multi-tenant MaaS" {
            cli = container "Cobra CLI" "CLI entrypoint with operator subcommand" "Go"
            manager = container "controller-runtime Manager" "Manages reconciler lifecycle, leader election, health probes, metrics server" "Go controller-runtime"
            reconciler = container "AIGateway Reconciler" "Watches AIGateway CR and reconciles networking, security, MaaS, batch, and observability resources" "Go"
            configLoader = container "Viper Config Loader" "Merges ConfigMap, env vars (ODH_MODULE_OPERATOR_ prefix), and defaults" "Go Viper"
            metricsServer = container "Metrics Server" "Serves Prometheus metrics on :8443/TCP HTTPS with TokenReview auth" "controller-runtime"
        }

        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based traffic routing" "External"
        istio = softwareSystem "Istio" "Service mesh providing DestinationRules, EnvoyFilters, ServiceEntries" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management" "External"
        kuadrant = softwareSystem "Kuadrant" "API gateway policy engine for auth, rate-limiting, and telemetry" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing LLMInferenceService CRs" "Internal ODH"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing runtime library and DSCInitialization CRs" "Internal ODH"
        llmdBatch = softwareSystem "llm-d Batch Gateway" "Batch inference gateway for LLM workloads" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Monitoring and alerting via ServiceMonitors, PodMonitors, PrometheusRules" "External"
        opentelemetry = softwareSystem "OpenTelemetry" "Distributed tracing and telemetry collection" "External"
        perses = softwareSystem "Perses" "Dashboard and datasource management" "External"

        platformAdmin -> aiGatewayOperator "Creates/updates AIGateway CR" "kubectl / API"
        tenant -> gatewayAPI "Sends inference requests through provisioned routes" "HTTPS"

        aiGatewayOperator -> kubeAPI "Watches CRs, creates/manages resources" "HTTPS/6443 TLS 1.2+ SA Token"
        aiGatewayOperator -> gatewayAPI "Creates/manages HTTPRoutes" "Kubernetes API"
        aiGatewayOperator -> istio "Creates DestinationRules, EnvoyFilters, ServiceEntries" "Kubernetes API"
        aiGatewayOperator -> certManager "Creates Certificate CRs for TLS provisioning" "Kubernetes API"
        aiGatewayOperator -> kuadrant "Creates AuthPolicies, RateLimitPolicies, TokenRateLimitPolicies" "Kubernetes API"
        aiGatewayOperator -> kserve "Watches LLMInferenceService CRs" "Kubernetes API"
        aiGatewayOperator -> odhOperator "Uses runtime library, reads DSCInitialization CRs" "Go library / Kubernetes API"
        aiGatewayOperator -> llmdBatch "Manages LLMBatchGateway lifecycle when spec.batchGateway=Managed" "Kubernetes API"
        aiGatewayOperator -> prometheus "Creates ServiceMonitors, PodMonitors, PrometheusRules" "Kubernetes API"
        aiGatewayOperator -> opentelemetry "Creates OpenTelemetryCollector CRs" "Kubernetes API"
        aiGatewayOperator -> perses "Creates PersesDashboards, PersesDatasources" "Kubernetes API"

        prometheus -> aiGatewayOperator "Scrapes /metrics endpoint" "HTTPS/8443 TokenReview+SAR"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

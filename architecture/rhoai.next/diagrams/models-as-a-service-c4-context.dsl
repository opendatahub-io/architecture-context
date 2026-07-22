workspace {
    model {
        dataScientist = person "Data Scientist" "Creates models, manages API keys, configures subscriptions"
        platformAdmin = person "Platform Admin" "Manages tenants, configures MaaS policies and infrastructure"
        application = person "Application" "Consumes model inference endpoints via API keys"

        maas = softwareSystem "Models as a Service (MaaS)" "Multi-tenant platform for managing access to LLM inference endpoints with auth, rate limiting, and policy enforcement" {
            maasController = container "maas-controller" "Manages CRDs for tenants, model references, subscriptions, auth policies; deploys infrastructure via kustomize reconciliation" "Go Operator (controller-runtime)"
            maasApi = container "maas-api" "REST API for model listing, API key CRUD, subscription management, tenant info" "Go Service (Gin HTTP)"
            payloadPreProcessing = container "payload-pre-processing" "Envoy ext_proc for model name extraction and provider resolution (pre-auth)" "gRPC Service (ext_proc)"
            payloadProcessing = container "payload-processing" "Envoy ext_proc for API translation, credential injection, usage enforcement (post-auth)" "gRPC Service (ext_proc)"
            webhookServer = container "Webhook Server" "Validates AITenant, MaaSAuthPolicy, MaaSSubscription CRs" "Go (embedded in controller)"
        }

        kuadrant = softwareSystem "Kuadrant / RHCL" "API gateway policy engine for authentication, authorization, and rate limiting" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes-native traffic routing via Gateway and HTTPRoute resources" "External"
        kserve = softwareSystem "KServe" "Model serving platform (LLMInferenceService)" "Internal Platform"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for mTLS, EnvoyFilter, ServiceEntry, traffic management" "External"
        postgresql = softwareSystem "PostgreSQL" "API key hash storage and management" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "TokenReview, SAR, CRD operations, informer watches" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks and Gateway" "External"
        openShiftAuth = softwareSystem "OpenShift Authentication" "OIDC issuer discovery for token validation" "External"
        externalProviders = softwareSystem "External Model Providers" "Third-party LLM APIs (OpenAI, Anthropic, etc.)" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "OTel Collector deployment for usage logging" "External"
        loki = softwareSystem "Loki" "Log aggregation for usage logs" "External"
        odhOperator = softwareSystem "ODH / RHODS Operator" "Platform operator that deploys maas-controller" "Internal Platform"
        coo = softwareSystem "Cluster Observability Operator" "Perses dashboards and datasources" "External"

        # User interactions
        dataScientist -> maas "Lists models, creates API keys, selects subscriptions" "HTTPS/443"
        platformAdmin -> maas "Creates AITenants, configures MaaSAuthPolicy, MaaSSubscription" "kubectl / HTTPS"
        application -> maas "Sends inference requests using API keys" "HTTPS/443"

        # Internal container interactions
        maasController -> maasApi "Deploys per-tenant via kustomize" "Kubernetes API"
        maasController -> webhookServer "Embedded webhook validation" "HTTPS/9443"

        # External system interactions
        maas -> kuadrant "Creates AuthPolicies and TokenRateLimitPolicies" "CRD"
        maas -> gatewayAPI "Creates/manages Gateway and HTTPRoutes" "CRD / HTTPS/443"
        maas -> kserve "Watches LLMInferenceService for model endpoints" "CRD Watch"
        maas -> istio "Creates EnvoyFilters, ServiceEntries, DestinationRules" "CRD"
        maasApi -> postgresql "Stores/queries API key hashes" "TCP/5432"
        maas -> k8sApi "TokenReview, SAR, CRD CRUD, informer watches" "HTTPS/6443"
        maas -> certManager "Provisions TLS certificates" "CRD (Certificate)"
        maas -> openShiftAuth "Discovers OIDC issuer" "API"
        maas -> externalProviders "Routes inference to external models" "HTTPS/443"
        maas -> otelOperator "Deploys OTel Collectors for usage logs" "CRD"
        maas -> loki "Exports usage logs" "HTTPS/8080"
        odhOperator -> maas "Deploys maas-controller" "CRD (DSCInitialization)"
        maas -> coo "Creates Perses dashboards" "CRD"

        kuadrant -> maasApi "Authorino callbacks for key validation" "HTTP/8080"
    }

    views {
        systemContext maas "SystemContext" {
            include *
            autoLayout
        }

        container maas "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
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
        }
    }
}

workspace {
    model {
        aiEngineer = person "AI Engineer" "Creates API keys, manages model access, sends inference requests"
        platformAdmin = person "Platform Admin" "Configures Tenants, MaaSAuthPolicies, MaaSSubscriptions, ExternalModels"

        maas = softwareSystem "Models as a Service (MaaS)" "Kubernetes-native platform for managed AI/ML model access with authentication, authorization, and rate limiting" {
            controller = container "maas-controller" "Manages CRD lifecycle, deploys platform infrastructure via kustomize, creates Kuadrant policies and Istio resources" "Go Operator (controller-runtime)"
            api = container "maas-api" "API key management, model discovery, Authorino authentication callbacks" "Go HTTP Service (Gin)"
            bbr = container "payload-processing (BBR)" "Envoy external processor for model routing, API translation, and credential injection" "Go gRPC Service (ext-proc)"
            cronJob = container "API Key Cleanup CronJob" "Periodically deletes expired ephemeral API keys" "Kubernetes CronJob"
        }

        kuadrant = softwareSystem "Kuadrant" "API gateway policy engine providing AuthPolicy and TokenRateLimitPolicy" "External"
        authorino = softwareSystem "Authorino" "Authentication and authorization service (API keys, OIDC, K8s tokens)" "External"
        limitador = softwareSystem "Limitador" "Distributed token-based rate limiting" "External"
        gatewayAPI = softwareSystem "Gateway API" "Traffic routing via Gateway and HTTPRoute resources" "External"
        istio = softwareSystem "Istio" "Service mesh for mTLS, ServiceEntry, DestinationRule, EnvoyFilter" "External"
        kserve = softwareSystem "KServe" "Model serving platform for LLMInferenceService" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "API key storage and management database" "External"
        openshift = softwareSystem "OpenShift" "Container platform providing Gateway controller, serving certs, Routes" "External"
        extLLM = softwareSystem "External LLM Providers" "Third-party model APIs (OpenAI, Anthropic, etc.)" "External"
        odhOperator = softwareSystem "ODH/RHODS Operator" "Platform operator that enables modelsAsService component via DataScienceCluster" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitors and PodMonitors" "External"
        perses = softwareSystem "Perses" "Dashboard deployment (optional)" "External"

        # User interactions
        aiEngineer -> maas "Sends inference requests, manages API keys" "HTTPS/443"
        platformAdmin -> maas "Configures Tenants, policies, subscriptions" "kubectl/oc"

        # Internal container interactions
        controller -> api "Deploys via kustomize SSA" "Kubernetes API/443"
        controller -> bbr "Deploys via kustomize SSA" "Kubernetes API/443"
        controller -> cronJob "Deploys via kustomize SSA" "Kubernetes API/443"
        cronJob -> api "Cleanup expired keys" "HTTP/8080"
        authorino -> api "Validate API key, select subscription" "HTTPS/8443"

        # MaaS to external systems
        maas -> kuadrant "Creates AuthPolicy, TokenRateLimitPolicy" "Kubernetes API"
        maas -> authorino "Relies on for auth enforcement" "AuthPolicy"
        maas -> limitador "Relies on for rate limiting" "TokenRateLimitPolicy"
        maas -> gatewayAPI "Creates Gateway, HTTPRoute resources" "Kubernetes API"
        maas -> istio "Creates ServiceEntry, DestinationRule, EnvoyFilter" "Kubernetes API"
        maas -> kserve "Watches LLMInferenceService, probes models" "Kubernetes API + HTTPS"
        maas -> postgresql "Stores hashed API keys" "PostgreSQL/5432"
        maas -> openshift "Uses Gateway controller, service-ca certs, auth config" "Kubernetes API"
        maas -> extLLM "Routes inference to external providers" "HTTPS/443"
        maas -> prometheus "Exposes metrics" "HTTP/8080,9005,15090"
        maas -> perses "Deploys dashboards (optional)" "Kubernetes API"

        # Platform integration
        odhOperator -> maas "Enables via DataScienceCluster CR"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
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
        }
    }
}

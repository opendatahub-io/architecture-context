workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Discovers models, creates API keys, and sends inference requests"
        platformAdmin = person "Platform Administrator" "Configures MaaS CRDs: MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, Tenant"

        maas = softwareSystem "Models as a Service (MaaS)" "Multi-tenant LLM inference gateway with model discovery, API key management, authentication, authorization, and token-based rate limiting" {
            maasController = container "maas-controller" "Reconciles MaaS CRDs into HTTPRoutes, AuthPolicies, TokenRateLimitPolicies, and Istio resources; manages Tenant lifecycle and platform deployment via kustomize" "Go Operator (controller-runtime)"
            maasAPI = container "maas-api" "OpenAI-compatible REST API for model listing, subscription management, and API key CRUD with PostgreSQL backend" "Go HTTP Service (Gin)" {
                tags "WebApp"
            }
            payloadProcessing = container "payload-processing (BBR)" "Envoy external processor for request/response transformation: model extraction, provider resolution, API translation, credential injection" "Go gRPC Service (Envoy ext_proc)"
        }

        kuadrant = softwareSystem "Kuadrant" "Authentication (Authorino), rate limiting (Limitador), AuthPolicy and TokenRateLimitPolicy CRDs" "External" {
            authorino = container "Authorino" "Authentication and authorization engine" "gRPC/5001"
            limitador = container "Limitador" "Token rate limit enforcement" "gRPC/8081"
        }

        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and Gateway CRDs for ingress routing" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "ServiceEntry, DestinationRule, EnvoyFilter for traffic management and mTLS" "External"
        kserve = softwareSystem "KServe" "LLMInferenceService CRD for internal model serving" "Internal ODH"
        postgresql = softwareSystem "PostgreSQL" "API key hash storage (SHA-256) and schema migrations" "External"
        externalProviders = softwareSystem "External Model Providers" "OpenAI, Anthropic, and other LLM providers" "External"
        odhOperator = softwareSystem "ODH / RHOAI Operator" "Enables MaaS component via DataScienceCluster CRD" "Internal ODH"
        prometheus = softwareSystem "Prometheus (User Workload Monitoring)" "Metrics collection via PodMonitor and ServiceMonitor" "External"
        openshiftIngress = softwareSystem "OpenShift Ingress" "Hosts maas-default-gateway for external traffic" "External"

        # User interactions
        dataScientist -> maas "Discovers models, creates API keys, sends inference requests" "HTTPS/443"
        platformAdmin -> maas "Configures model access, subscriptions, and tenant settings" "kubectl / CRDs"

        # MaaS internal flows
        maasController -> maasAPI "Deploys via Tenant reconciliation" "kustomize apply"
        maasController -> payloadProcessing "Deploys via Tenant reconciliation" "kustomize apply"

        # MaaS to external systems
        maas -> kuadrant "Authentication and rate limiting" "AuthPolicy, TokenRateLimitPolicy CRDs"
        maas -> gatewayAPI "Ingress routing" "HTTPRoute, Gateway CRDs"
        maas -> istio "Traffic management, mTLS, external model routing" "ServiceEntry, DestinationRule, EnvoyFilter"
        maas -> kserve "Internal model serving backend" "LLMInferenceService watch"
        maasAPI -> postgresql "API key hash CRUD, schema migrations" "TCP/5432"
        payloadProcessing -> externalProviders "Credential injection for external models" "HTTPS/443"

        # Auth flows
        authorino -> maasAPI "API key validation, subscription selection" "HTTP/8080 callbacks"
        limitador -> maas "Token rate limit enforcement" "gRPC/8081"

        # Platform integration
        odhOperator -> maas "Enables modelsasservice component, deploys maas-controller" "DataScienceCluster CRD"
        prometheus -> maas "Scrapes metrics" "HTTP/8080, HTTP/15090"
        openshiftIngress -> maas "Hosts Gateway for external traffic" "Gateway API"
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

        container kuadrant "KuadrantContainers" {
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
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

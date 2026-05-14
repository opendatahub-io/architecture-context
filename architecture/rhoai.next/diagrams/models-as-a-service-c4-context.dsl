workspace {
    model {
        user = person "Data Scientist / AI Engineer" "Creates models, manages API keys, invokes inference endpoints"
        platformAdmin = person "Platform Admin" "Configures Tenant, MaaSAuthPolicy, MaaSSubscription, ExternalModel CRs"

        maas = softwareSystem "Models as a Service (MaaS)" "Kubernetes-native platform for managed AI/ML model access with auth, rate limiting, and multi-provider routing" {
            controller = container "maas-controller" "Manages CRD lifecycle for Tenant, MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, ExternalModel; deploys platform infrastructure via kustomize; creates Kuadrant policies and Istio resources" "Go Operator (controller-runtime)"
            api = container "maas-api" "API key management, model discovery, subscription selection, Authorino callback endpoints; backed by PostgreSQL" "Go HTTP Service (Gin)" {
                tags "UserFacing"
            }
            bbr = container "payload-processing (BBR)" "Envoy external processor for model name extraction, provider resolution, API format translation, and credential injection" "Go gRPC Service (ext-proc)"
        }

        gateway = softwareSystem "Gateway API" "Traffic routing via Gateway and HTTPRoute resources" "External" {
            tags "External"
        }
        kuadrant = softwareSystem "Kuadrant" "API gateway policy engine providing AuthPolicy and TokenRateLimitPolicy" "External" {
            tags "External"
        }
        authorino = softwareSystem "Authorino" "Authentication and authorization: API keys, OIDC, K8s token review" "External" {
            tags "External"
        }
        limitador = softwareSystem "Limitador" "Distributed token-based rate limiting" "External" {
            tags "External"
        }
        istio = softwareSystem "Istio" "Service mesh: ServiceEntry, DestinationRule, EnvoyFilter for external provider routing" "External" {
            tags "External"
        }
        kserve = softwareSystem "KServe" "Serverless ML model serving (LLMInferenceService)" "Internal RHOAI" {
            tags "InternalPlatform"
        }
        postgresql = softwareSystem "PostgreSQL" "Relational database for API key storage and management" "External" {
            tags "External"
        }
        openshift = softwareSystem "OpenShift" "Container platform: Gateway controller, serving certs, Routes, authentication" "External" {
            tags "External"
        }
        externalLLM = softwareSystem "External LLM Providers" "Third-party model APIs: OpenAI, Anthropic, etc." "External" {
            tags "ExternalService"
        }
        odhOperator = softwareSystem "ODH / RHODS Operator" "Platform operator that enables modelsAsService component via DataScienceCluster CR" "Internal RHOAI" {
            tags "InternalPlatform"
        }
        monitoring = softwareSystem "User Workload Monitoring" "Prometheus metrics collection and Perses dashboards" "Internal RHOAI" {
            tags "InternalPlatform"
        }

        # User interactions
        user -> maas "Invokes model inference (HTTPS/443), manages API keys, lists models"
        platformAdmin -> maas "Creates Tenant, MaaSAuthPolicy, MaaSSubscription, ExternalModel CRs via kubectl"

        # MaaS internal
        controller -> api "Deploys via kustomize (Tenant reconciler)"
        controller -> bbr "Deploys via kustomize (Tenant reconciler)"
        authorino -> api "HTTP callbacks for API key validation and subscription selection" "HTTPS/8443"

        # MaaS → External dependencies
        maas -> gateway "Manages Gateway and HTTPRoute resources for model routing" "Kubernetes API/443"
        maas -> kuadrant "Creates aggregated AuthPolicy and TokenRateLimitPolicy per model" "Kubernetes API/443"
        maas -> authorino "Authentication enforcement (API key, OIDC, K8s token)" "AuthPolicy"
        maas -> limitador "Token-based rate limit enforcement" "TokenRateLimitPolicy"
        maas -> istio "Creates ServiceEntry, DestinationRule, EnvoyFilter for external providers" "Kubernetes API/443"
        maas -> kserve "Watches LLMInferenceService status, probes /v1/models" "HTTPS"
        maas -> postgresql "API key CRUD, migration, cleanup" "PostgreSQL/5432"
        maas -> openshift "Service-ca certs, authentication issuer discovery, Gateway controller" "HTTPS/443"
        maas -> externalLLM "Routes inference requests to external providers" "HTTPS/443"

        # Platform dependencies
        odhOperator -> maas "Enables modelsAsService component via DataScienceCluster CR"
        monitoring -> maas "Scrapes metrics from controller (8080), BBR (9005), gateway (15090)" "HTTP"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "ExternalService" {
                background #f39c12
                color #ffffff
            }
            element "InternalPlatform" {
                background #7ed321
                color #ffffff
            }
            element "UserFacing" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

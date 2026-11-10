workspace "ai-gateway-controller" "RHOAI 3.7-ea.1 AI Gateway control plane" {
    model {
        admin = person "Platform Admin / Model Owner" "Creates ExternalModel, ExternalProvider and AIGuardrail resources"
        client = person "API Consumer" "Sends inference requests and uses the MaaS consumer portal"

        agc = softwareSystem "ai-gateway-controller" "AI Gateway control plane: installs per-tenant Praxis ExtProc and reconciles ExternalModel/ExternalProvider/AIGuardrail into Gateway API, Istio and ExtProc config" {
            manager = container "Manager" "controller-runtime manager; metrics 8443/TCP HTTPS, health 8081/TCP" "Go"
            tenant = container "Tenant reconciler" "Renders and SSA-applies per-tenant praxis-extproc; IPP to Praxis handoff; compiles NeMo callouts" "Go, pkg/tenant"
            model = container "ExternalModel / ExternalProvider reconcilers" "HTTPRoutes, overlays, provider transport, credential projections, staged withdrawal" "Go, pkg/controller"
            portal = container "Consumer portal reconciler" "Deploys kube-auth-proxy, portal HTTPRoutes, AuthPolicies" "Go, pkg/consumerportal"
            guardrail = container "AIGuardrail reconciler" "Validates AIGuardrail against NemoGuardrails" "Go, pkg/guardrail"
            render = container "Render pipeline" "krusty build, placeholder post-render, SSA" "Go, pkg/render"
            extproc = container "praxis-extproc (managed)" "payload-pre-processing, payload-processing, payload-processing-external-model; gRPC 9004/TCP TLS" "Rust ExtProc" "Managed"
            authproxy = container "maas-consumer-portal-auth-proxy (managed)" "OIDC session proxy; HTTPS 4180/TCP" "kube-auth-proxy" "Managed"
        }

        k8s = softwareSystem "Kubernetes API" "Watches, SSA, pod logs, TokenReview/SAR" "External"
        gateway = softwareSystem "Istio Gateway (openshift-ingress)" "Envoy dataplane, EnvoyFilter/DestinationRule/ServiceEntry" "External"
        kuadrant = softwareSystem "Kuadrant / Authorino" "AuthPolicy enforcement, MaaS auth" "External"
        providers = softwareSystem "External LLM Providers" "openai, anthropic, azure, bedrock, vertex" "External"
        oidc = softwareSystem "OIDC Issuer" "Consumer portal login" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping" "External"

        operator = softwareSystem "ai-gateway-operator" "Deploys the controller under modelsAsAService.managementState" "Internal RHOAI"
        maas = softwareSystem "maas-controller (models-as-a-service)" "MaasTenantConfig, AITenant, MaaSSubscription, MaaSModelRef; installs inference CRDs" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI NeMo Guardrails" "Guardrail provider" "Internal RHOAI"
        dashboard = softwareSystem "odh-dashboard (maas-portal)" "Consumer portal UI" "Internal RHOAI"
        dsci = softwareSystem "rhods-operator (DSCInitialization)" "Applications namespace" "Internal RHOAI"

        admin -> agc "Creates ExternalModel / ExternalProvider / AIGuardrail CRs" "kubectl"
        client -> gateway "Inference requests, portal" "HTTPS/443"
        operator -> agc "Deploys"
        maas -> agc "Tenant model + payload-processing-status handshake" "CRD watch/patch"
        manager -> k8s "Watch / CRUD / SSA" "HTTPS/6443"
        manager -> tenant "Runs"
        manager -> model "Runs"
        manager -> portal "Runs"
        manager -> guardrail "Runs"
        tenant -> render "Uses"
        portal -> render "Uses"
        tenant -> extproc "Deploys (SSA)"
        portal -> authproxy "Deploys"
        model -> extproc "Reads pod logs for serving revision" "HTTPS/6443"
        guardrail -> trustyai "Validates NemoGuardrails refs" "CRD watch"
        portal -> dsci "Reads applicationsNamespace" "CRD watch"
        agc -> gateway "Configures EnvoyFilters, DestinationRules, ServiceEntries, HTTPRoutes" "via K8s API"
        agc -> kuadrant "Creates AuthPolicies" "via K8s API"
        gateway -> extproc "ExtProc" "gRPC/9004 TLS"
        gateway -> kuadrant "wasm auth" "gRPC"
        extproc -> trustyai "Guardrail callouts" "HTTP/8000 or HTTPS/8443"
        gateway -> providers "Inference with injected credential" "HTTPS/443 TLS SIMPLE"
        authproxy -> oidc "OIDC login" "HTTPS/443"
        gateway -> dashboard "Portal backend via ReferenceGrant" "HTTPS/8443"
        prometheus -> manager "Scrapes /metrics" "HTTPS/8443 Bearer"
    }

    views {
        systemContext agc "SystemContext" {
            include *
            autoLayout
        }

        container agc "Containers" {
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
            element "Managed" {
                background #f5a623
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

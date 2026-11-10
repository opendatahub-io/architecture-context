workspace {
    model {
        client = person "MaaS API Consumer" "Sends OpenAI/Anthropic-style inference requests to the MaaS Gateway"
        admin = person "Platform Admin / Model Owner" "Creates ExternalProvider, ExternalModel CRs and credential Secrets"

        ipp = softwareSystem "ai-gateway-payload-processing" "Envoy ext_proc service running IPP plugins (routing, API translation, credential injection) plus controllers reconciling ExternalProvider/ExternalModel into Istio and Gateway API resources" {
            extProc = container "ext-proc Server" "Envoy ExternalProcessor; runs IPP plugin chain; 9004/TCP TLS (self-signed)" "Go gRPC"
            healthSrv = container "gRPC Health Server" "grpc.health.v1.Health on 9005/TCP" "Go gRPC"
            plugins = container "IPP Plugin Chain" "maas-headers-guard, body-field-to-header, model-provider-resolver, stream-usage-enforcer, api-translation, apikey-injection (+ optional metering, NeMo guards)" "Go plugins"
            stores = container "In-memory Stores" "Informer-backed model, provider and labeled-Secret credential stores" "Go"
            providerCtrl = container "ExternalProvider Controller" "Creates ExternalName Service, ServiceEntry, DestinationRule; validates Secret" "controller-runtime"
            modelCtrl = container "ExternalModel Controller" "Creates HTTPRoute attached to maas-default-gateway" "controller-runtime"
            legacyCtrl = container "Legacy-migration Controller" "Converts maas.opendatahub.io ExternalModel to inference.opendatahub.io pairs" "controller-runtime"
            metricsSrv = container "Metrics Server" "/metrics and pprof on 9090/TCP with TokenReview/SAR filter" "controller-runtime"
        }

        gateway = softwareSystem "MaaS Gateway (maas-default-gateway)" "Istio/Envoy Gateway API gateway in openshift-ingress" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant" "Wasm plugin: AuthPolicy and rate limiting before IPP" "Internal RHOAI"
        maasController = softwareSystem "maas-controller" "Reads ExternalModel status; may own IPP Deployment" "Internal RHOAI"
        agc = softwareSystem "ai-gateway-controller (AGC / Praxis)" "Takes over AGC-managed models/providers via finalizers and gatewayRefs" "Internal RHOAI"
        epp = softwareSystem "llm-d EPP" "Endpoint picker using subset hints in hub mode" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API" "CRDs, Secrets, Services, HTTPRoutes, Istio resources" "External"
        istio = softwareSystem "Istio" "ServiceEntry / DestinationRule egress and TLS origination" "External"
        providers = softwareSystem "External LLM Providers" "OpenAI, Anthropic, Azure OpenAI, Bedrock, Vertex AI, remote MaaS" "External"
        googleOAuth = softwareSystem "Google OAuth2" "oauth2.googleapis.com token endpoint" "External"
        nemo = softwareSystem "NeMo Guardrails" "Optional guardrail checks" "External"
        metering = softwareSystem "External Metering" "Optional entitlement and usage service" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping" "External"

        client -> gateway "Inference requests" "HTTPS/443"
        admin -> k8s "Creates ExternalProvider, ExternalModel, labeled Secrets" "HTTPS/6443"
        gateway -> kuadrant "Auth / rate limit (filter chain)"
        gateway -> extProc "ext_proc callouts" "gRPC/9004 TLS"
        gateway -> providers "Routed inference via HTTPRoute + ServiceEntry" "HTTPS/443 TLS origination"
        extProc -> plugins "Runs"
        plugins -> stores "Reads models, providers, credentials"
        plugins -> googleOAuth "Mints Vertex AI tokens" "HTTPS/443"
        plugins -> nemo "Guardrail checks" "HTTPS"
        plugins -> metering "Entitlements / usage events" "HTTP/HTTPS"
        stores -> k8s "Watches CRs and labeled Secrets" "HTTPS/6443"
        providerCtrl -> k8s "Reconciles Services, ServiceEntries, DestinationRules" "HTTPS/6443"
        modelCtrl -> k8s "Reconciles HTTPRoutes" "HTTPS/6443"
        legacyCtrl -> k8s "Migrates legacy ExternalModels" "HTTPS/6443"
        providerCtrl -> istio "Configures egress"
        ipp -> epp "Subset hints via dynamic metadata (hub mode)"
        maasController -> ipp "Reads ExternalModel status; may own Deployment"
        agc -> ipp "Ownership hand-off via finalizers / gatewayRefs"
        prometheus -> metricsSrv "Scrapes" "HTTP/9090"
    }

    views {
        systemContext ipp "SystemContext" {
            include *
            autoLayout
        }

        container ipp "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape person
            }
        }
    }
}

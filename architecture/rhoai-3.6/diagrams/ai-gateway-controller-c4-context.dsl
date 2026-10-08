workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates ExternalModel and ExternalProvider CRs to expose external LLM endpoints"
        platformAdmin = person "Platform Admin" "Configures MaasTenantConfig and manages tenant lifecycle"

        aiGatewayController = softwareSystem "ai-gateway-controller" "Kubernetes controller reconciling ExternalModel/ExternalProvider CRDs and managing per-tenant Praxis ExtProc installations" {
            manager = container "Controller Manager" "Single controller-runtime manager process" "Go / controller-runtime v0.23.3"
            tenantReconciler = container "Tenant Reconciler" "Watches MaasTenantConfig, renders and SSA-applies per-tenant praxis-extproc manifests" "Go / pkg/tenant"
            externalModelReconciler = container "ExternalModel Reconciler" "Watches ExternalModel CRs, publishes transport resources and content-addressed routing overlay" "Go / pkg/controller"
            kustomizeBuild = container "Kustomize Build" "Renders vendored praxis-extproc manifests with per-tenant substitutions" "sigs.k8s.io/kustomize"
            envelopeEngine = container "Overlay Envelope" "JCS-canonicalized SHA-256 digest for content-addressed routing config" "gowebpki/jcs"
        }

        aiGatewayOperator = softwareSystem "ai-gateway-operator" "Deploys ai-gateway-controller alongside maas-controller" "Internal RHOAI"
        maasController = softwareSystem "maas-controller" "Sibling controller sharing MaasTenantConfig watch; coordinates Praxis/IPP handoff" "Internal RHOAI"
        praxisExtproc = softwareSystem "praxis-extproc" "ExtProc dataplane installed per-tenant; processes inference requests via Envoy filter chain" "Internal RHOAI"

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based traffic routing" "Platform"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter, DestinationRule, ServiceEntry" "Platform"
        kuadrant = softwareSystem "Kuadrant (RHCL)" "Auth enforcement via WasmPlugin filter in Envoy" "Platform"
        trustyAI = softwareSystem "TrustyAI NemoGuardrails" "Guardrail service referenced by AIGuardrail CRDs" "Platform"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches and resource CRUD" "External"
        llmProviders = softwareSystem "External LLM Providers" "OpenAI, Azure, and other inference endpoints" "External"

        # Relationships
        dataScientist -> aiGatewayController "Creates ExternalModel/ExternalProvider CRs" "kubectl / API"
        platformAdmin -> aiGatewayController "Configures MaasTenantConfig" "kubectl / API"

        aiGatewayOperator -> aiGatewayController "Deploys and manages lifecycle"
        aiGatewayController -> maasController "Coordinates via payload-processing-status CAS" "Kubernetes API / HTTPS 6443"
        aiGatewayController -> praxisExtproc "Vendors, renders, and SSA-applies manifests"
        aiGatewayController -> gatewayAPI "Creates per-model HTTPRoutes" "Kubernetes API / HTTPS 6443"
        aiGatewayController -> istio "Creates EnvoyFilters, DestinationRules, ServiceEntries" "Kubernetes API / HTTPS 6443"
        aiGatewayController -> kuadrant "Orders ExtProc filters relative to auth" "EnvoyFilter priority"
        aiGatewayController -> trustyAI "References NemoGuardrails via AIGuardrail CRD"
        aiGatewayController -> k8sAPI "CRD watches, resource CRUD, Secret reads" "HTTPS / 6443 / ServiceAccount token"
        praxisExtproc -> llmProviders "Forwards inference requests via Envoy" "HTTPS / 443 / API key"

        # Internal container relationships
        manager -> tenantReconciler "Hosts"
        manager -> externalModelReconciler "Hosts"
        tenantReconciler -> kustomizeBuild "Renders manifests"
        externalModelReconciler -> envelopeEngine "Computes content-addressed digests"
    }

    views {
        systemContext aiGatewayController "SystemContext" {
            include *
            autoLayout
        }

        container aiGatewayController "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
        }
    }
}

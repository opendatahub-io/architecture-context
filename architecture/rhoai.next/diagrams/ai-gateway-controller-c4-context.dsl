workspace {
    model {
        admin = person "Platform Admin" "Configures AI Gateway tenants and external model routing"
        datascientist = person "Data Scientist" "Creates ExternalModel/ExternalProvider CRs to route inference requests to external LLMs"

        aiGatewayController = softwareSystem "ai-gateway-controller" "Control-plane controller that reconciles ExternalModel and ExternalProvider CRDs into per-tenant Envoy ExtProc dataplane configurations and routing overlays" {
            manager = container "Controller Manager" "Single-binary controller-runtime manager with leader election" "Go Binary"
            tenantReconciler = container "Tenant Reconciler" "Watches MaasTenantConfig/AITenant; renders and SSA-applies per-tenant praxis-extproc manifests" "Go Controller (pkg/tenant)"
            modelReconciler = container "Model Reconciler" "Watches ExternalModel/ExternalProvider; resolves route sets, publishes routing overlays" "Go Controller (pkg/controller)"
            renderer = container "Render Package" "Kustomize build, placeholder post-rendering, and SSA apply primitives" "Go Package (pkg/render)"
            publisher = container "Publisher Package" "Content-addressed routing overlay publication to per-namespace ConfigMaps" "Go Package (pkg/publisher)"
            resolver = container "Resolver Package" "Multi-provider route resolution and weighted selection logic" "Go Package (pkg/resolver)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD watches, SSA apply, leader election" "Infrastructure"
        aiGatewayOperator = softwareSystem "ai-gateway-operator" "Deploys ai-gateway-controller as a sibling of maas-controller" "Internal RHOAI"
        maasController = softwareSystem "maas-controller" "Manages MaasTenantConfig and AITenant CRDs; coordinates backend swap handshake" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter, DestinationRule, ServiceEntry for traffic management" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute CRDs for per-model routing with provider backends and URL rewrites" "Infrastructure"
        praxisExtProc = softwareSystem "praxis-extproc" "ExtProc dataplane pods deployed per-tenant; handles LLM request translation" "Internal RHOAI"
        externalLLM = softwareSystem "External LLM Providers" "Third-party LLM API endpoints (e.g., OpenAI, Anthropic, Azure)" "External"

        datascientist -> aiGatewayController "Creates ExternalModel/ExternalProvider CRs" "kubectl / YAML"
        admin -> maasController "Configures tenant routing" "kubectl / YAML"

        aiGatewayOperator -> aiGatewayController "Deploys and manages lifecycle"
        aiGatewayController -> kubernetesAPI "CRD watches, SSA apply, leader election" "HTTPS/6443"
        aiGatewayController -> maasController "Reads MaasTenantConfig/AITenant; annotation CAS handshake" "via Kubernetes API"
        aiGatewayController -> istio "Creates EnvoyFilter, DestinationRule, ServiceEntry per-tenant" "via Kubernetes API"
        aiGatewayController -> gatewayAPI "Creates HTTPRoute per-model with provider backends" "via Kubernetes API"

        praxisExtProc -> externalLLM "Proxies inference requests via Envoy ExtProc" "HTTPS (per DestinationRule TLS policy)"

        manager -> tenantReconciler "Runs reconciliation loop"
        manager -> modelReconciler "Runs reconciliation loop"
        tenantReconciler -> renderer "Kustomize build + SSA apply"
        modelReconciler -> resolver "Resolve multi-provider routes"
        modelReconciler -> publisher "Publish routing overlays"
        modelReconciler -> renderer "SSA apply transport resources"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

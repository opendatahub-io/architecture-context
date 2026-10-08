workspace {
    model {
        admin = person "Platform Admin" "Configures ExternalModel/ExternalProvider CRDs and MaasTenantConfig"
        client = person "API Client" "Sends inference requests through the AI Gateway"

        aigc = softwareSystem "ai-gateway-controller" "Control-plane controller that reconciles ExternalModel/ExternalProvider CRDs and deploys per-tenant praxis-extproc dataplane resources" {
            manager = container "Manager" "controller-runtime manager with health probes and leader election" "Go"
            tenantReconciler = container "tenant.Reconciler" "Watches MaasTenantConfig/AITenant; renders and applies per-tenant praxis-extproc manifests via kustomize + SSA" "Go Controller"
            controllerReconciler = container "controller.Reconciler" "Watches ExternalModel/ExternalProvider; creates transport resources and publishes routing overlay" "Go Controller"
            envelope = container "pkg/envelope" "RFC 8785 JCS + SHA-256 content-addressed routing overlay envelope generation" "Go Library"
            resolver = container "pkg/resolver" "Merges ExternalModel/ExternalProvider pairs into resolved route set" "Go Library"
            publisher = container "pkg/publisher" "ConfigMap publish with tamper detection and SSA" "Go Library"
            render = container "pkg/render" "Kustomize build, placeholder post-render, and SSA apply" "Go Library"
        }

        aiGatewayOperator = softwareSystem "ai-gateway-operator" "Deploys ai-gateway-controller and maas-controller" "Internal RHOAI"
        maasController = softwareSystem "maas-controller" "Coordinates backend swap via annotation handshake on MaasTenantConfig" "Internal RHOAI"
        praxisExtproc = softwareSystem "praxis-extproc" "ExtProc dataplane; reads routing overlay ConfigMap" "Internal RHOAI"

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based traffic routing" "External"
        istio = softwareSystem "Istio" "Service mesh for ServiceEntry, DestinationRule, EnvoyFilter" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes API server for all resource operations" "External"
        llmProviders = softwareSystem "External LLM Providers" "External inference endpoints (e.g., api.openai.com)" "External"

        admin -> aigc "Creates ExternalModel/ExternalProvider CRDs via kubectl"
        aigc -> k8sAPI "CRUD operations, watches, SSA apply" "HTTPS/6443"
        aigc -> gatewayAPI "Creates per-model HTTPRoutes" "HTTPS/6443"
        aigc -> istio "Creates ServiceEntry, DestinationRule, EnvoyFilter" "HTTPS/6443"
        aigc -> praxisExtproc "Publishes routing overlay ConfigMap" "Projected volume"
        aiGatewayOperator -> aigc "Deploys controller, injects env vars"
        maasController -> k8sAPI "Annotation handshake on MaasTenantConfig" "HTTPS/6443"
        client -> praxisExtproc "Inference requests via Gateway" "HTTPS/443"
        praxisExtproc -> llmProviders "Forwards inference to provider" "HTTPS/443"

        manager -> tenantReconciler "Starts reconciler"
        manager -> controllerReconciler "Starts reconciler"
        tenantReconciler -> render "Kustomize build + SSA"
        controllerReconciler -> resolver "Resolve route set"
        controllerReconciler -> publisher "Publish overlay"
        publisher -> envelope "Build content-addressed envelope"
    }

    views {
        systemContext aigc "SystemContext" {
            include *
            autoLayout
        }

        container aigc "Containers" {
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

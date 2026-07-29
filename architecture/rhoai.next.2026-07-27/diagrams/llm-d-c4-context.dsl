workspace {
    model {
        user = person "ML Engineer / Client" "Sends inference requests to LLM models"

        llmd = softwareSystem "llm-d" "Disaggregated LLM inference platform with prefill/decode separation and intelligent routing" {
            gateway = container "Inference Gateway" "Gateway API listener accepting external inference requests" "Gateway API (gateway.networking.k8s.io)" "Port 80/HTTP"
            httproute = container "HTTPRoute" "Routes requests by model name header to InferencePool backends" "Gateway API Inference Extension (inference.networking.k8s.io)"
            routerEPP = container "Router EPP" "Endpoint Picker Plugin for intelligent model server selection" "Helm-deployed with Envoy sidecar"
            prefill = container "Prefill Deployment" "Processes prompt prefill phase, transfers KV-cache via NIXL" "Kubernetes Deployment" "Port 8000, 5600"
            decode = container "Decode Deployment" "Handles decode phase and generates tokens" "Kubernetes Deployment" "Port 8000"
        }

        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress and routing" "External"
        inferenceExtension = softwareSystem "Gateway API Inference Extension" "InferencePool CRD for model routing" "External"

        # User interactions
        user -> llmd "Sends inference requests" "HTTP/80"

        # Internal flows
        gateway -> httproute "Routes based on X-Gateway-Base-Model-Name header"
        httproute -> routerEPP "Selects via InferencePool backend"
        routerEPP -> prefill "Forwards inference request" "HTTP or gRPC/8000"
        routerEPP -> decode "Forwards inference request" "HTTP or gRPC/8000"
        prefill -> decode "NIXL KV-cache transfer" "TCP/5600"

        # External dependencies
        routerEPP -> otelCollector "Exports traces" "gRPC OTLP/4317"
        llmd -> gatewayAPI "Uses for ingress" "Gateway resource"
        llmd -> inferenceExtension "Uses for routing" "InferencePool CRD"
        llmd -> prometheus "Exposes metrics" "PodMonitor"
    }

    views {
        systemContext llmd "SystemContext" {
            include *
            autoLayout
        }

        container llmd "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
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

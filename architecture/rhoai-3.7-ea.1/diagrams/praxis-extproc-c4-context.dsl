workspace "praxis-extproc" "Envoy ExtProc server running Praxis filter pipelines for the MaaS AI gateway (RHOAI 3.7-ea.1)" {
    model {
        client = person "API Client" "Calls MaaS-served models with an API key or bearer token"

        praxis = softwareSystem "praxis-extproc" "Rust gRPC Envoy External Processor that inspects, changes or rejects HTTP headers and bodies using Praxis filter pipelines" {
            pre = container "payload-pre-processing" "Pre-auth (BBR) chain: derives X-Gateway-Model-Name from body /model, resolves model provider" "Rust, tonic gRPC, 9004/TCP TLS"
            post = container "payload-processing" "Post-auth (IPP) chain: strips credentials and x-maas-* headers, adds request ID, processes buffered responses" "Rust, tonic gRPC, 9004/TCP TLS"
            metrics = container "Metrics listener" "Prometheus /metrics behind TokenReview + SAR, /healthz open" "hyper HTTP/1, 9090/TCP"
            health = container "Health service" "grpc.health.v1 readiness" "tonic-health, 50052/TCP"
            config = container "payload-processing-plugins ConfigMap" "pre-extproc.yaml and extproc.yaml filter chains" "Kubernetes ConfigMap"
            envoyFilter = container "payload-processing EnvoyFilter" "Inserts fail-closed ext_proc filters and TLS clusters into the gateway" "Istio EnvoyFilter"
        }

        gateway = softwareSystem "MaaS Gateway (maas-default-gateway)" "Istio/OSSM 3 Envoy gateway in openshift-ingress" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant" "Authorino authentication and Limitador rate limiting via Wasm plugin" "Internal RHOAI"
        aiGatewayController = softwareSystem "ai-gateway-controller / MaaS" "Deploys and parameterises the odh overlay via PostRender and MaasTenantConfig" "Internal RHOAI"
        maasApi = softwareSystem "maas-api" "MaaS management API; ext_proc disabled on its routes" "Internal RHOAI"
        kserve = softwareSystem "KServe LLMInferenceService" "Model serving backends routed by X-Gateway-Model-Name" "Internal RHOAI"
        epp = softwareSystem "Gateway API Inference Extension EPP" "Endpoint picker ext_proc re-inserted by the EnvoyFilter" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues serving-cert TLS Secrets and CA bundle" "External"
        k8sApi = softwareSystem "Kubernetes API server" "TokenReview and SubjectAccessReview" "External"
        prometheus = softwareSystem "RHOAI Monitoring (Prometheus)" "prometheus-k8s in redhat-ods-monitoring" "Internal RHOAI"
        reloader = softwareSystem "Stakater Reloader" "Restarts pods on TLS Secret rotation (optional)" "External"

        client -> gateway "Sends inference requests" "HTTPS/443"
        gateway -> pre "ext_proc ipp-pre (before Kuadrant), fail-closed" "gRPC/HTTP2 TLS 9004"
        gateway -> kuadrant "Authenticates and rate limits" "in-process Wasm"
        gateway -> post "ext_proc ipp (after Kuadrant), fail-closed" "gRPC/HTTP2 TLS 9004"
        gateway -> epp "Endpoint picking ext_proc"
        gateway -> kserve "Routes sanitised requests" "HTTP/HTTPS"
        gateway -> maasApi "Routes management API (no ext_proc)"
        envoyFilter -> gateway "Configures filter chain and clusters"
        pre -> config "Loads pre-extproc.yaml"
        post -> config "Loads extproc.yaml"
        aiGatewayController -> praxis "Deploys odh overlay, tunes limits"
        serviceCa -> praxis "Provisions payload-processing-tls / payload-pre-processing-tls"
        reloader -> praxis "Restarts pods on cert rotation"
        prometheus -> metrics "Scrapes /metrics with bearer token" "HTTP/9090"
        metrics -> k8sApi "TokenReview + SubjectAccessReview" "HTTPS/443,6443"
    }

    views {
        systemContext praxis "SystemContext" {
            include *
            autoLayout
        }

        container praxis "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
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
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}

workspace {
    model {
        client = person "API Client" "Sends OpenAI-compatible inference requests"
        operator = person "Platform Engineer" "Installs the Helm chart and labels adapter ConfigMaps"

        ipp = softwareSystem "llm-d Inference Payload Processor" "Envoy ext_proc service that inspects and mutates inference payloads to inject routing headers" {
            extproc = container "ext-proc Server" "Envoy ExternalProcessor v3; buffers bodies and runs plugin pipeline" "Go, gRPC 9004/TCP TLS"
            health = container "Health Server" "grpc.health.v1; always SERVING" "Go, gRPC 9005/TCP plaintext"
            metrics = container "Metrics / pprof Server" "Prometheus /metrics and /debug/pprof" "controller-runtime, HTTP 9090/TCP"
            framework = container "Plugin Framework" "Profiles, request/response processors, ModelSelector filter/scorer/picker" "Go library"
            reconciler = container "ConfigMapReconciler" "Builds adapter to base-model store from ipp-managed ConfigMaps" "controller-runtime controller"
            datalayer = container "Datalayer / In-memory Datastore" "Request metadata, cost, models.json collectors" "Go"
        }

        gateway = softwareSystem "Inference Gateway" "Istio / Envoy / GKE Gateway L7 proxy" "External"
        istio = softwareSystem "Istio Control Plane" "EnvoyFilter + DestinationRule" "External"
        k8s = softwareSystem "Kubernetes API" "ConfigMaps, TokenReview, SubjectAccessReview" "External"
        otlp = softwareSystem "OpenTelemetry Collector" "Optional trace sink" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping" "External"
        router = softwareSystem "llm-d-router (EPP)" "Endpoint picker; shared plugin interfaces" "Internal RHOAI"
        pools = softwareSystem "InferencePools / Model Servers" "KServe / llm-d inference backends" "Internal RHOAI"
        aigw = softwareSystem "ai-gateway-payload-processing" "RHOAI MaaS AI Gateway built on IPP" "Internal RHOAI"

        client -> gateway "Inference requests" "HTTPS/HTTP 443/80"
        gateway -> extproc "Streams request/response events" "gRPC ext_proc 9004/TCP, TLS self-signed, unverified, no auth"
        extproc -> framework "Runs plugin pipeline"
        framework -> reconciler "Adapter to base-model lookups"
        framework -> datalayer "Scorer inputs"
        gateway -> pools "Routes by X-Gateway-Model-Name / X-Gateway-Base-Model-Name"
        pools -> router "Endpoint selection via EPP"
        istio -> gateway "Inserts ext_proc filter"
        reconciler -> k8s "Watches ConfigMaps" "HTTPS 6443/TCP, SA token"
        metrics -> k8s "TokenReview / SAR when metrics auth on" "HTTPS 6443/TCP"
        prometheus -> metrics "Scrapes" "HTTP 9090/TCP, Bearer token"
        gateway -> health "Health checks (GKE) / kubelet probe" "gRPC 9005/TCP plaintext"
        ipp -> otlp "Exports traces (optional)" "OTLP gRPC 4317/TCP plaintext"
        ipp -> router "Shares plugin interfaces" "Go library"
        aigw -> ipp "Imports runner, plugins, chart" "Go library + Helm subchart"
        operator -> ipp "Installs Helm chart, labels ConfigMaps" "helm / kubectl"
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
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

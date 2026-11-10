workspace "llm-d-router" "C4 model for llm-d Router (RHOAI 3.7-ea.1)" {
    model {
        client = person "Inference Client" "Sends OpenAI-compatible inference requests"
        platformOperator = person "Platform Operator" "Installs Helm charts and CRDs, configures InferencePools"

        router = softwareSystem "llm-d-router" "LLM inference entry point: Endpoint Picker plus P/D disaggregation sidecar and coordinator" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc service picking the target model-server endpoint per request via scheduling plugins; namespace-scoped reconcilers for Pod, InferencePool, InferenceObjective, InferenceModelRewrite" "Go, gRPC 9002/TCP, health 9003/TCP, metrics 9090/TCP"
            sidecar = container "pd-sidecar" "HTTP reverse proxy next to the decode model server; orchestrates P/D and E/P/D disaggregation" "Go, HTTPS 8000/TCP"
            coordinator = container "coordinator" "OpenAI-compatible pipeline server (async-broker/render/encode/prefill/decode)" "Go, HTTPS 8080/TCP"
            charts = container "Helm charts" "llm-d-router-gateway, llm-d-router-standalone, routerlib" "Helm"
        }

        gateway = softwareSystem "Gateway API Implementation" "Istio / OpenShift Service Mesh / AgentGateway / Envoy; L7 data plane" "Internal ODH"
        gie = softwareSystem "Gateway API Inference Extension" "Owns the InferencePool CRD and Endpoint Picker Protocol" "Internal ODH"
        kserve = softwareSystem "KServe (LLMInferenceService)" "Provisions EPP and sidecar for llm-d deployments" "Internal ODH"
        modelServers = softwareSystem "vLLM / SGLang Model Servers" "Inference backends in the InferencePool" "Internal ODH"
        llmdAsync = softwareSystem "llm-d-async" "Async request queuing" "Internal ODH"
        latencyPredictor = softwareSystem "llm-d Latency Predictor" "Training and prediction servers for predicted-latency scoring" "Internal ODH"
        k8s = softwareSystem "Kubernetes API" "Cluster API server" "External"
        redis = softwareSystem "Redis" "Async broker queues / KV index backend" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection" "External"

        client -> gateway "Sends inference requests" "HTTPS/443"
        client -> coordinator "Sends pipeline/async requests" "HTTPS/8080"
        platformOperator -> charts "Installs"
        gateway -> epp "ext-proc callout for endpoint selection" "gRPC/9002 TLS"
        gateway -> modelServers "Routes inference to selected endpoint" "HTTP(S)/8000"
        gateway -> sidecar "Routes disaggregated inference" "HTTPS/8000"
        sidecar -> modelServers "Prefill/encode remote, decode local" "HTTP(S), 8200 local"
        coordinator -> gateway "Encode/prefill/decode calls" "HTTP/80"
        coordinator -> redis "Async broker" "RESP/6379"
        coordinator -> llmdAsync "Uses producer library"
        epp -> k8s "Watches Pods, InferencePool, InferenceObjective, InferenceModelRewrite; Leases; TokenReview/SAR" "HTTPS/6443"
        epp -> modelServers "Scrapes vLLM metrics" "HTTP"
        modelServers -> epp "KV-cache events" "ZMQ/5557"
        epp -> latencyPredictor "Predicted-latency scoring (optional)" "HTTP"
        epp -> gie "Consumes InferencePool CRD"
        epp -> otel "Exports traces" "OTLP/4317"
        prometheus -> epp "Scrapes /metrics" "HTTP(S)/9090 Bearer"
        kserve -> router "Deploys EPP/sidecar (inferred)"
        sidecar -> k8s "InferencePool/pod allowlist (SSRF protection)" "HTTPS/6443"
    }

    views {
        systemContext router "SystemContext" {
            include *
            autoLayout
        }

        container router "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
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
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}

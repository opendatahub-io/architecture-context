workspace "FMS Guardrails Orchestrator" "C4 context for fms-guardrails-orchestrator (RHOAI 3.7-ea.1)" {
    model {
        client = person "Client Application / User" "Sends LLM prompts and text for guardrailed generation or detection"
        operations = person "Kubelet / Monitoring" "Probes liveness and downstream health"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Stateless Rust service that coordinates chunkers, detectors and LLMs to apply AI safety guardrails" {
            guardrailsServer = container "Guardrails Server" "v1 classification-with-generation, v2 detection, OpenAI-compatible completions-detection; optional TLS/mTLS" "Rust axum, 8033/TCP"
            healthServer = container "Health Server" "/health liveness and /info aggregated downstream health; unauthenticated" "Rust axum, 8034/TCP HTTP"
            core = container "Orchestrator Core" "Task handlers: chunking, detector fan-out, generation, streaming detection batcher" "Rust library"
            clientLayer = container "Client Layer" "gRPC (tonic + ginepro LB) and HTTP (hyper-rustls) clients built from OrchestratorConfig" "Rust"
            telemetry = container "Telemetry" "OTLP trace and metric export, structured logs" "OpenTelemetry SDK"
        }

        ingress = softwareSystem "Platform Ingress / Auth Proxy" "Route or Gateway plus OAuth/kube-auth proxy; sets X-Forwarded-Access-Token (deployer-provided)" "Internal ODH"
        deployer = softwareSystem "Deploying Operator (TrustyAI stack)" "Renders config.yaml and creates Deployment/Service/Route; not established for this release" "Internal ODH"
        detectors = softwareSystem "Guardrails Detector Services" "guardrails-detectors, regex detector, HF detector runtime (Detector API)" "Internal ODH"
        chunkers = softwareSystem "caikit Chunker Services" "Sentence/token chunking" "Internal ODH"
        tgis = softwareSystem "TGIS Generation Server" "fmaas.GenerationService text generation and tokenization" "Internal ODH"
        caikitNlp = softwareSystem "caikit-nlp" "Alternative generation provider" "Internal ODH"
        llm = softwareSystem "OpenAI-compatible LLM" "vLLM / KServe InferenceService" "Internal ODH"
        otel = softwareSystem "OpenTelemetry Collector" "Trace and metric sink" "External"

        client -> ingress "Calls guardrails API" "HTTPS/443"
        ingress -> guardrailsServer "Forwards requests with X-Forwarded-Access-Token" "HTTP(S)/8033, optional TLS/mTLS"
        operations -> healthServer "GET /health, /info" "HTTP/8034, no auth"
        deployer -> orchestrator "Deploys image and renders config" "Kubernetes"

        guardrailsServer -> core "Dispatches requests"
        core -> clientLayer "Invokes downstream clients"
        healthServer -> clientLayer "Fan-out health checks"
        core -> telemetry "Emits spans and metrics"

        clientLayer -> detectors "Detector API /api/v1/text/*" "HTTP(S)/8080, Bearer"
        clientLayer -> chunkers "ChunkersService" "gRPC/8085, optional mTLS"
        clientLayer -> tgis "GenerationService/Generate" "gRPC/8033, optional mTLS"
        clientLayer -> caikitNlp "NlpService" "gRPC/8085, optional mTLS"
        clientLayer -> llm "/v1/chat/completions, /v1/completions, /tokenize" "HTTP(S)/8080, Bearer"
        telemetry -> otel "OTLP traces and metrics" "gRPC/4317 or HTTP/4318"
    }

    views {
        systemContext orchestrator "SystemContext" {
            include *
            autoLayout
        }

        container orchestrator "Containers" {
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
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}

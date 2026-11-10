workspace {
    model {
        user = person "Application / End User" "Calls an OpenAI-compatible chat completions API with guardrails applied"

        gateway = softwareSystem "vLLM Orchestrator Gateway" "OpenAI-compatible gateway that pins detector policies per route and forwards to the FMS Guardrails Orchestrator" {
            routes = container "Route Handlers" "One POST /{route}/v1/chat/completions per configured route; injects detectors; applies fallback_message on detection (JSON and SSE)" "Rust axum, 8090/TCP HTTP"
            config = container "Config Loader/Validator" "Parses orchestrator, detectors and routes YAML from GATEWAY_CONFIG; panics on unknown or duplicate detector servers" "Rust serde_yml"
            client = container "Orchestrator Client" "Shared HTTP(S) client with optional custom CA and mTLS client identity from mounted files" "Rust reqwest + native-tls/OpenSSL"

            config -> routes "Defines routes at startup"
            routes -> client "Sends detector-wrapped requests"
        }

        proxy = softwareSystem "Fronting Auth Proxy" "Deployer-provided inbound TLS and authentication (not part of this repo)" "External"
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Runs input/output detectors and calls the generation model" "Internal RHOAI"
        detectors = softwareSystem "Guardrails Detector Servers" "Regex and guardrails-detectors servers" "Internal RHOAI"
        model = softwareSystem "vLLM Model Server" "OpenAI-compatible text generation" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues serving certs and CA bundle (inferred)" "External"
        trustyOp = softwareSystem "TrustyAI Service Operator" "Historically deployed the gateway via GuardrailsOrchestrator CR; no gorch controller in 3.7-ea.1" "Internal RHOAI"
        rhodsOp = softwareSystem "rhods-operator" "Maps RELATED_IMAGE to ODH image only; RHOAI image offboarded" "Internal RHOAI"

        user -> proxy "Chat completion requests" "HTTPS, Bearer"
        proxy -> routes "Forwards requests" "HTTP/8090, Bearer forwarded"
        client -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/mTLS, 8085 baked"
        orchestrator -> detectors "Runs detectors" "HTTP"
        orchestrator -> model "Generates completions" "HTTP"
        serviceCa -> gateway "Provides CA bundle / certs" "Mounted files"
        trustyOp -> gateway "Formerly deployed alongside orchestrator"
        rhodsOp -> gateway "Image reference (ODH only)"
    }

    views {
        systemContext gateway "SystemContext" {
            include *
            autoLayout
        }

        container gateway "Containers" {
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
        }
    }
}

workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Submits inference requests to deployed LLM models"

        llmd = softwareSystem "llm-d" "Disaggregated LLM inference platform running vLLM-based model servers with routing and optional P2P KV cache sharing" {
            decodeDeployment = container "decode Deployment" "Runs vLLM OpenAI-compatible API server for model inference" "Kubernetes Deployment (vLLM)" {
                tags "ModelServer"
            }
            modelExpressServer = container "ModelExpress Server" "Metadata broker coordinating peer-to-peer KV cache sharing over RDMA" "gRPC Service" {
                tags "Optional"
            }
        }

        llmdRouter = softwareSystem "llm-d-router" "Routing layer comprising EPP and Envoy/Agent Gateway proxy for model-aware request routing" {
            tags "Internal Platform"
            epp = container "EPP (Endpoint Picker Plugin)" "Selects backend decode pods via InferencePool" "Go Service"
            envoyProxy = container "Envoy / Agent Gateway" "Sidecar proxy forwarding inference requests to selected pods" "Envoy Proxy"
        }

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API providing InferencePool and InferenceModel CRDs for routing" {
            tags "Internal Platform"
        }

        istio = softwareSystem "Istio Service Mesh" "Provides mTLS STRICT and AuthorizationPolicy for gRPC control plane" {
            tags "Internal Platform"
        }

        huggingface = softwareSystem "HuggingFace Hub" "Model artifact repository for downloading pre-trained models" {
            tags "External"
        }

        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed tracing data via OTLP gRPC" {
            tags "External"
        }

        # Relationships
        user -> llmdRouter "Submits inference requests"
        llmdRouter -> llmd "Routes requests to decode pods" "HTTP/8000"
        llmd -> modelExpressServer "Registers/queries KV cache metadata" "gRPC/8001 (Istio mTLS)"
        llmd -> huggingface "Downloads model artifacts" "HTTPS/443 (HF_TOKEN)"
        llmd -> otelCollector "Exports traces" "gRPC OTLP/4317"
        llmd -> istio "Protected by mTLS STRICT on port 8001"
        llmdRouter -> gatewayAPI "Uses InferencePool/InferenceModel CRDs"
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

        container llmdRouter "RouterContainers" {
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "ModelServer" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

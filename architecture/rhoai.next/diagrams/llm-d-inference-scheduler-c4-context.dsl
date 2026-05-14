workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and queries ML models via inference endpoints"
        platformAdmin = person "Platform Admin" "Configures scheduling profiles, flow control policies, and InferencePool resources"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Optimized routing and scheduling for LLM inference workloads via Gateway API Inference Extension" {
            epp = container "EPP (Endpoint Picker)" "Main scheduling service: ext_proc gRPC server with pluggable filter/scorer/picker pipeline, controller-runtime reconcilers, flow control, and KV cache-aware scoring" "Go Service (controller-runtime)" "Primary"
            sidecar = container "P/D Routing Sidecar" "HTTP proxy sidecar orchestrating disaggregated Prefill/Decode and Encode/Prefill/Decode inference stages with KV cache transfer" "Go HTTP Proxy" "Sidecar"
            udsTokenizer = container "UDS Tokenizer" "Tokenization service for prompt analysis, communicates via Unix Domain Socket" "External Image (Sidecar Container)"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Kubernetes Gateway API implementation using Envoy proxy for traffic routing and ext_proc integration" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API for CRD watches and resource management" "External"
        gatewayAPIGIE = softwareSystem "Gateway API Inference Extension (GIE)" "Upstream K8s project defining InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM inference engine providing model serving, Prometheus metrics, and KV cache events" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system scraping EPP metrics via ServiceMonitor" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend receiving OTLP traces" "External"

        # User interactions
        dataScientist -> envoyGateway "Sends inference requests (POST /v1/chat/completions)" "HTTP/HTTPS"
        platformAdmin -> k8sAPI "Manages InferencePool, InferenceObjective, InferenceModelRewrite CRs" "kubectl / HTTPS"
        platformAdmin -> llmdScheduler "Configures scheduling via EndpointPickerConfig" "YAML config file"

        # EPP interactions
        envoyGateway -> epp "Sends ext_proc routing callbacks" "gRPC/9002 (Optional TLS)"
        epp -> envoyGateway "Returns endpoint selection decisions" "gRPC/9002"
        epp -> k8sAPI "Watches InferencePool, Pod, InferenceObjective, InferenceModelRewrite CRs" "HTTPS/443 (SA token)"
        epp -> vllm "Scrapes Prometheus metrics (queue depth, KV cache %, LoRA info)" "HTTP/HTTPS (configurable port)"
        epp -> vllm "Subscribes to real-time KV cache events" "ZMQ PUB/SUB/5556"
        udsTokenizer -> epp "Provides prompt tokenization" "gRPC over Unix Domain Socket"
        prometheus -> epp "Scrapes scheduling metrics" "HTTP/9090 (15s interval)"
        epp -> otelCollector "Exports distributed traces" "gRPC OTLP/4317 (Optional)"

        # Sidecar interactions
        envoyGateway -> sidecar "Routes inference requests (after EPP decision)" "HTTP/HTTPS/8000 (TLS 1.2+)"
        sidecar -> vllm "Forwards prefill/decode/encode requests" "HTTP/HTTPS (configurable ports)"
        sidecar -> k8sAPI "Watches InferencePool for SSRF pod allowlist" "HTTPS/443 (SA token)"

        # Gateway API flow
        envoyGateway -> vllm "Forwards routed requests to selected model server" "HTTP/8000"
    }

    views {
        systemContext llmdScheduler "SystemContext" {
            include *
            autoLayout
        }

        container llmdScheduler "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
            }
            element "Sidecar" {
                background #7ed321
            }
        }
    }
}

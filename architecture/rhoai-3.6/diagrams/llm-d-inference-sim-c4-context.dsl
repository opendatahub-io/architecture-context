workspace {
    model {
        developer = person "Developer / SRE" "Tests routing, scheduling, and infrastructure without GPUs"
        testHarness = person "Test Harness" "Automated integration test suite"

        inferSim = softwareSystem "llm-d-inference-sim" "GPU-free simulator mimicking vLLM inference API for testing routing and scheduling" {
            commLayer = container "Communication Layer" "cmux-based TCP multiplexer serving HTTP and gRPC on a single port" "Go (fasthttp + grpc-go)"
            vllmEngine = container "vLLM Engine" "Primary engine binding OpenAI-compatible and vLLM-native routes" "Go"
            simCore = container "Simulator Core" "Worker queue with latency simulation and token generation" "Go"
            kvCache = container "KV-Cache Subsystem" "In-memory block cache with ZMQ event publication" "Go (zmq4 + msgpack)"
            tlsManager = container "TLS Manager" "Optional TLS with certificate hot-reload via fsnotify" "Go (crypto/tls)"
        }

        vllmRender = softwareSystem "vllm-render" "Optional sidecar providing real HuggingFace tokenization" "Sidecar"
        zmqListener = softwareSystem "zmq-listener" "Python debugging utility for KV-cache event stream" "Debug Tool"
        datasetTool = softwareSystem "dataset-tool" "CLI to generate SQLite conversation corpora from HuggingFace datasets" "Offline CLI"

        llmdRouter = softwareSystem "llm-d-router" "LLM request router with EPP consuming KV-cache events" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset hosting" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "Infrastructure"

        developer -> inferSim "Sends inference requests for testing" "HTTP/gRPC on 8000/TCP"
        testHarness -> inferSim "Runs integration tests against" "HTTP/gRPC on 8000/TCP"

        commLayer -> vllmEngine "Routes parsed requests to"
        vllmEngine -> simCore "Submits requests for processing"
        simCore -> kvCache "Triggers cache operations"
        tlsManager -> commLayer "Provides TLS configuration"

        inferSim -> vllmRender "Tokenization requests" "HTTP/8082 (localhost)"
        inferSim -> llmdRouter "Publishes KV-cache events" "ZMQ TCP (msgpack)"
        zmqListener -> inferSim "Subscribes to KV-cache events" "ZMQ SUB"
        prometheus -> inferSim "Scrapes metrics" "HTTP /metrics on 8000/TCP"
        vllmRender -> huggingface "Downloads tokenizer models" "HTTPS/443 with HF_TOKEN"
        datasetTool -> huggingface "Downloads datasets" "HTTPS/443 with HF_TOKEN"
        kubernetes -> inferSim "Probes health endpoints" "HTTP /health, /health/ready"
    }

    views {
        systemContext inferSim "SystemContext" {
            include *
            autoLayout
        }

        container inferSim "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Sidecar" {
                background #f5a623
                color #ffffff
            }
            element "Debug Tool" {
                background #e8e8e8
                color #333333
            }
            element "Offline CLI" {
                background #e8e8e8
                color #333333
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

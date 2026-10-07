workspace {
    model {
        developer = person "Infrastructure Developer" "Tests routing, scheduling, and observability without GPU resources"
        sre = person "SRE / Platform Engineer" "Validates control-plane behavior using simulated inference"

        inferSim = softwareSystem "llm-d-inference-sim" "GPU-free inference simulator mimicking vLLM and SGLang behavior for infrastructure testing" {
            communication = container "Communication Layer" "cmux-based multiplexer serving HTTP and gRPC on a single port" "Go (fasthttp + grpc)"
            vllmEngine = container "vLLM Engine" "Engine backend simulating vLLM HTTP routes, gRPC service, metrics, and KV-event encoding" "Go Package"
            sglangEngine = container "SGLang Engine" "Engine backend simulating SGLang error framing, metrics, and KV-event encoding" "Go Package"
            simulatorCore = container "Simulator Core" "Worker queue with latency simulation (TTFT, ITL, jitter, load scaling) and response generation" "Go Package"
            kvCache = container "KV Cache Simulation" "Block-level cache tracking with batched ZMQ event publishing" "Go Package"
            datasetTool = container "dataset-tool" "Offline CLI for creating SQLite response datasets from HuggingFace" "Go CLI"
            zmqListener = container "zmq-listener" "Diagnostic ZMQ subscriber for observing KV cache events" "Python Service"
        }

        llmdRouter = softwareSystem "llm-d-router" "KV-cache-aware request router for LLM inference" "Internal Platform"
        vllmRender = softwareSystem "vLLM Render Sidecar" "Real-model tokenization service deployed as init container" "Sidecar"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset hosting platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        zmqSubscribers = softwareSystem "ZMQ Subscribers" "Downstream consumers of KV cache events" "External"

        developer -> inferSim "Sends inference requests via HTTP/gRPC"
        sre -> inferSim "Monitors metrics and validates routing behavior"

        communication -> vllmEngine "Delegates to active engine"
        communication -> sglangEngine "Delegates to active engine"
        vllmEngine -> simulatorCore "Enqueues simulation tasks"
        sglangEngine -> simulatorCore "Enqueues simulation tasks"
        simulatorCore -> kvCache "Generates KV cache events"

        inferSim -> llmdRouter "Uses KV event types and encoding" "Go library import"
        inferSim -> vllmRender "Delegates tokenization" "HTTP/8082"
        inferSim -> huggingface "Downloads tokenizers and datasets" "HTTPS/443"
        kvCache -> zmqSubscribers "Publishes KV cache block events" "ZMQ PUB/5557"
        prometheus -> inferSim "Scrapes /metrics endpoint" "HTTP/8000"
        zmqListener -> kvCache "Subscribes to cache events" "ZMQ SUB/5557"
        datasetTool -> huggingface "Downloads conversation datasets" "HTTPS/443"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

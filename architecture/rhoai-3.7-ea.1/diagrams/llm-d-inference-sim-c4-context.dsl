workspace "llm-d-inference-sim" "GPU-free vLLM/SGLang inference simulator (RHOAI 3.7 EA.1, test/dev utility)" {
    model {
        tester = person "llm-d Developer / CI" "Runs routing, scheduling and observability tests without GPUs"

        sim = softwareSystem "llm-d-inference-sim" "Imitates vLLM's OpenAI-compatible HTTP API, gRPC engine API, Prometheus metrics and KV-cache events" {
            simulator = container "llm-d-inference-sim" "Single-port HTTP + gRPC (cmux) simulator: latency model, LoRA, failure injection, simulated KV cache" "Go (fasthttp, grpc-go, zmq4)"
            render = container "vllm-render sidecar" "Real tokenization/rendering for the simulated model (localhost:8082)" "vllm/vllm-openai-cpu:v0.21.0" "External"
            datasetTool = container "dataset-tool" "Offline CLI building SQLite response datasets from HuggingFace" "Go CLI"
            zmqListener = container "zmq-listener" "Debug ZMQ SUB listener printing KV-cache events" "Python (pyzmq, msgpack)"
        }

        router = softwareSystem "llm-d router / EPP" "Scores, routes and schedules inference requests to model-server pods" "Internal RHOAI"
        kvIndexer = softwareSystem "llm-d KV-cache indexer" "Indexes KV-cache events for KV-cache-aware routing" "Internal RHOAI"
        pdSidecar = softwareSystem "llm-d P/D routing sidecar" "Disaggregated prefill/decode routing" "Internal RHOAI"
        routerLib = softwareSystem "llm-d-router Go library v0.11.0" "kvblock hashing and kvevents types" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics scraping" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Tokenizer files and datasets" "External"
        datasetHost = softwareSystem "Dataset URL host" "Optional SQLite dataset download" "External"

        tester -> simulator "Configures at runtime via /admin/config" "HTTP/8000, no auth"
        router -> simulator "Routes inference requests; scrapes metrics" "HTTP or gRPC h2c/8000, no auth"
        pdSidecar -> simulator "Mooncake bootstrap /query" "HTTP/8000"
        prometheus -> simulator "Scrapes /metrics" "HTTP/8000"
        simulator -> render "Tokenizes prompts (--render-url)" "HTTP/8082 localhost"
        simulator -> kvIndexer "Publishes KV-cache events" "ZMQ PUB/5557, msgpack, no CURVE"
        simulator -> zmqListener "Publishes KV-cache events (debug)" "ZMQ PUB/5557"
        simulator -> routerLib "Uses for KV block hashing and event types" "Go library"
        simulator -> datasetHost "Downloads dataset (optional)" "HTTPS/443"
        render -> huggingface "Downloads tokenizer files" "HTTPS/443, Bearer HF_TOKEN optional"
        datasetTool -> huggingface "Downloads datasets" "HTTPS/443, Bearer HF_TOKEN optional"
    }

    views {
        systemContext sim "SystemContext" {
            include *
            autoLayout
        }

        container sim "Containers" {
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
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}

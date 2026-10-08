workspace {
    model {
        developer = person "Developer / SRE" "Tests LLM infrastructure without GPUs"
        testHarness = person "Test Harness" "Automated integration test suite"

        inferSim = softwareSystem "llm-d-inference-sim" "Lightweight inference server simulator mimicking vLLM/SGLang APIs for GPU-free development and testing" {
            mainService = container "llm-d-inference-sim" "Primary simulator serving HTTP and gRPC on a single port via cmux" "Go Service"
            datasetTool = container "dataset-tool" "CLI for creating SQLite response datasets from HuggingFace or other sources" "Go CLI"
            vllmRender = container "vllm-render sidecar" "HuggingFace tokenization via vLLM render server" "Python Sidecar"
            zmqListener = container "zmq-listener" "Debugging tool for inspecting ZMQ KV cache events" "Python Script"
        }

        llmdRouter = softwareSystem "llm-d-router" "Cache-aware request scheduler for llm-d ecosystem" "Internal llm-d"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and tokenizer hosting platform" "External"

        # User interactions
        developer -> inferSim "Sends inference requests via curl/HTTP clients"
        testHarness -> inferSim "Automated integration testing"

        # Container interactions
        developer -> mainService "POST /v1/chat/completions, /v1/completions" "HTTP/gRPC :8000"
        mainService -> vllmRender "Tokenization requests" "HTTP :8082"
        vllmRender -> huggingFace "Downloads tokenizer models" "HTTPS :443, Bearer HF_TOKEN"
        mainService -> llmdRouter "Publishes KV cache events" "ZMQ PUB :5557, msgpack"
        prometheus -> mainService "Scrapes metrics" "HTTP :8000/metrics"
        datasetTool -> mainService "Creates SQLite datasets loaded at startup" "File"
        zmqListener -> mainService "Subscribes to KV cache events for debugging" "ZMQ SUB :5557"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
        }
    }
}

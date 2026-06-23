workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models on Intel Gaudi hardware"
        mlops = person "MLOps Engineer" "Configures ServingRuntime CRs for Gaudi inference"

        vllmGaudi = softwareSystem "vllm-gaudi" "HPU platform plugin enabling vLLM inference serving on Intel Gaudi accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible inference API (completions, chat, embeddings)" "Python / FastAPI" "Web Server"
            plugin = container "vllm-gaudi Plugin" "HPU platform, attention backends, custom ops, model overrides" "Python Plugin"
            modelRunner = container "HPUModelRunner" "Executes model inference on Gaudi HPU hardware" "Python / Habana Synapse"
            communicator = container "HpuCommunicator" "HCCL-based distributed communication for tensor/pipeline parallel" "Python / HCCL"
            nixlConnector = container "NixlConnectorWorker" "KV cache transfer for disaggregated prefill/decode serving" "Python / NIXL"
            configSystem = container "Config System" "Runtime feature detection, hardware detection, attention backend selection" "Python"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform — deploys vllm-gaudi as InferenceService runtime" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "References vllm-gaudi image in ServingRuntime CRs" "Internal RHOAI"
        vllmCore = softwareSystem "vLLM Core" "Upstream inference engine — scheduler, tokenizer, API framework" "External"
        synapseAI = softwareSystem "Habana Synapse AI" "Hardware driver stack for Intel Gaudi 2/3 accelerators" "External"
        pytorchHabana = softwareSystem "PyTorch for Habana" "PyTorch with HPU device support, lazy/eager mode, HCCL" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-worker inference" "External"
        s3 = softwareSystem "S3 / Model Storage" "Model artifact storage (S3, PVC, or local filesystem)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weights, tokenizer configs, model configs" "External"
        nixl = softwareSystem "NIXL" "KV cache transfer library for disaggregated inference" "External"

        datascientist -> vllmGaudi "Sends inference requests via OpenAI-compatible API"
        mlops -> rhoaiOperator "Configures ServingRuntime for Gaudi"
        rhoaiOperator -> vllmGaudi "Deploys container as InferenceService runtime"
        kserve -> vllmGaudi "Routes inference traffic to vLLM pods"
        vllmGaudi -> vllmCore "Extends via platform plugin entry points"
        vllmGaudi -> synapseAI "Executes model graphs on Gaudi hardware" "Habana Driver API"
        vllmGaudi -> pytorchHabana "HPU tensor operations, graph compilation" "Python API"
        vllmGaudi -> ray "Multi-worker orchestration" "Ray Protocol/6379"
        vllmGaudi -> s3 "Downloads model weights at startup" "HTTPS/443"
        vllmGaudi -> huggingface "Downloads model configs and weights" "HTTPS/443"
        vllmGaudi -> nixl "KV cache transfer between prefill/decode instances" "RDMA/TCP"
    }

    views {
        systemContext vllmGaudi "SystemContext" {
            include *
            autoLayout
        }

        container vllmGaudi "Containers" {
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Server" {
                shape WebBrowser
                background #438dd5
                color #ffffff
            }
        }
    }
}

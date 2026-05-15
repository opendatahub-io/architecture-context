workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys LLM inference endpoints via RHOAI"
        application = person "Application" "Sends inference requests to deployed models"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi hardware plugin for vLLM, providing optimized LLM inference on Gaudi 2/3 accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible REST API for completions, chat, embeddings" "Python (uvicorn/FastAPI)" "8000/TCP HTTP"
            hpuModelRunner = container "HPU Model Runner" "Executes model forward passes with bucketing and graph compilation" "Python"
            hpuWorker = container "HPU Worker" "Manages HPU device lifecycle, distributed initialization, memory profiling" "Python"
            attentionBackends = container "Attention Backends" "Four HPU-optimized attention implementations: Standard, MLA, Unified, UnifiedMLA" "Python"
            customOps = container "HPU Custom Ops" "FP8 quantization, fused MoE, rotary embedding, layer normalization" "Python"
            distComm = container "Distributed Communication" "HCCL all-reduce/all-gather, NIXL KV cache transfer" "Python + HCCL + NIXL"
            calibration = container "Calibration Pipeline" "Six-step FP8 calibration for model quantization" "Python Scripts"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform, deploys and manages InferenceService pods" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator managing ServingRuntime CR lifecycle" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API / OpenShift Route providing TLS termination and auth" "Internal RHOAI"

        gaudiHPU = softwareSystem "Intel Gaudi HPU" "Gaudi 2/3 accelerator hardware with Synapse AI 1.23.0 drivers" "External Hardware"
        pytorchHPU = softwareSystem "PyTorch (Habana)" "Deep learning framework v2.9.0 with HPU backend" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-card/multi-node orchestration" "External"
        transformers = softwareSystem "HuggingFace Transformers" "Model architectures, tokenizer loading, weight format handling" "External"
        modelStorage = softwareSystem "Model Storage" "PVC mount or S3 bucket for model weight artifacts" "External"
        vllmCore = softwareSystem "vLLM Core" "Core LLM inference engine v0.14.1 providing plugin framework" "External"

        # Relationships
        datascientist -> kserve "Creates InferenceService CR" "kubectl / RHOAI Dashboard"
        application -> platformIngress "POST /v1/chat/completions" "HTTPS/443 TLS 1.2+"
        platformIngress -> vllmGaudi "Forwards inference requests" "HTTP/8000 plaintext"

        kserve -> vllmGaudi "Deploys as predictor container" "Container Image"
        rhoaiOperator -> kserve "Manages ServingRuntime CR" "Kubernetes API"

        apiServer -> hpuModelRunner "Dispatches inference" "In-process"
        hpuModelRunner -> attentionBackends "Selects attention implementation" "In-process"
        hpuModelRunner -> customOps "Invokes HPU-optimized ops" "In-process"
        hpuWorker -> distComm "Coordinates multi-card/multi-node" "In-process"
        hpuModelRunner -> hpuWorker "Device management" "In-process"

        vllmGaudi -> vllmCore "Registers as platform plugin" "Python entry_points"
        vllmGaudi -> gaudiHPU "Executes on accelerator" "habana_frameworks API"
        vllmGaudi -> pytorchHPU "Tensor operations, torch.compile" "Python API"
        vllmGaudi -> ray "Multi-worker orchestration" "Ray internal protocol"
        vllmGaudi -> transformers "Model/tokenizer loading" "Python API"
        vllmGaudi -> modelStorage "Loads model weights at startup" "Filesystem / HTTPS"

        distComm -> gaudiHPU "HCCL collectives (all-reduce, all-gather)" "RDMA/TCP Dynamic"
        distComm -> distComm "NIXL KV cache transfer" "RDMA/TCP Dynamic"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Hardware" {
                background #82b366
                color #ffffff
            }
            element "Internal RHOAI" {
                background #6c8ebf
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #dae8fc
                color #333333
            }
            element "Container" {
                background #b3d7ff
                color #333333
            }
        }
    }
}

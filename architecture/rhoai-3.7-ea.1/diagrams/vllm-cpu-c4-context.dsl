workspace {
    model {
        user = person "Data Scientist / App Developer" "Deploys LLMs on CPU and calls the OpenAI-compatible API"
        ibmTeam = person "IBM CPU maintainers" "Own the vllm-cpu fork and its build scripts (overlay 0014)"

        vllmCpu = softwareSystem "vllm-cpu (odh-vllm-cpu-rhel9)" "CPU-only vLLM inference engine image for RHOAI, built for ppc64le and s390x" {
            apiServer = container "OpenAI-compatible API server" "vllm.entrypoints.openai.api_server; OpenAI/Anthropic/SageMaker/Cohere-v2/pooling/tokenization APIs on 8000/TCP; opt-in Bearer auth on /v1,/v2,/inference" "Python FastAPI/uvicorn"
            engine = container "vLLM engine core" "Continuous batching, KV cache, CPU model execution via torch 2.11 and csrc C++ kernels" "Python/C++"
            cli = container "vllm CLI" "vllm serve / bench console script" "Python"
            grpcServer = container "gRPC VllmEngine server" "Optional, 50051/TCP insecure with reflection; servicer extra NOT installed in image" "Python gRPC"
            dpSupervisor = container "DP supervisor" "Optional readiness aggregator /ready,/readyz on 9256/TCP" "Python HTTP"
            buildLayer = container "Build layer" "Dockerfile.konflux.cpu + build_vllm_ppc64le.sh / build_vllm_s390x.sh" "Dockerfile/Bash"
        }

        kserve = softwareSystem "KServe" "InferenceService/ServingRuntime controller that creates predictor pods" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "Ships vllm-cpu-runtime-template and vllm-cpu-x86-runtime-template" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Route / Gateway / auth proxy; owns TLS and auth" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "User workload monitoring" "Internal RHOAI"
        konflux = softwareSystem "konflux-central" "multi-arch-container-build pipeline (hermetic: false)" "Internal RHOAI"
        huggingface = softwareSystem "Hugging Face Hub" "Model and tokenizer downloads" "External"
        s3 = softwareSystem "S3-compatible storage" "Tensorizer model loading" "External"
        modelscope = softwareSystem "ModelScope" "Optional model source" "External"
        pkgIndexes = softwareSystem "Third-party package indexes" "IBM DevPI, PyPI, PyTorch CDN, GitHub, rustup, EPEL" "External"
        quay = softwareSystem "quay.io/rhoai" "Image registry for odh-vllm-cpu-rhel9" "External"

        user -> platformIngress "Calls /v1/chat/completions etc." "HTTPS/443"
        platformIngress -> apiServer "Forwards inference requests" "HTTP/8000 (optional TLS), opt-in Bearer"
        prometheus -> apiServer "Scrapes /metrics" "HTTP/8000, no auth"
        apiServer -> engine "Submits requests" "ZeroMQ local IPC"
        cli -> apiServer "Launches"
        engine -> huggingface "Downloads models" "HTTPS/443, HF_TOKEN"
        engine -> s3 "Loads tensorized models" "HTTPS/443, S3 keys"
        engine -> modelscope "Downloads models when VLLM_USE_MODELSCOPE" "HTTPS/443"

        odhModelController -> vllmCpu "References image in ServingRuntime templates"
        kserve -> vllmCpu "Runs as predictor pod"
        konflux -> buildLayer "Builds for linux/ppc64le, linux/s390x"
        buildLayer -> pkgIndexes "Resolves deps (unsafe-best-match)" "HTTPS/443"
        buildLayer -> quay "Publishes odh-vllm-cpu-rhel9:rhoai-3.7-ea.1"
        ibmTeam -> buildLayer "Maintains"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
        }

        container vllmCpu "Containers" {
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

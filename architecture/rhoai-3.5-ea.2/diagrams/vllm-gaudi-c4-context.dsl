workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates InferenceService resources to deploy LLMs on Intel Gaudi hardware"
        client = person "API Consumer" "Sends inference requests to deployed models via OpenAI-compatible API"

        vllmGaudi = softwareSystem "vLLM Gaudi" "High-throughput LLM inference server with Intel Gaudi HPU acceleration, deployed as a KServe ServingRuntime container" {
            apiServer = container "OpenAI-compatible API Server" "Serves /v1/completions, /v1/chat/completions, /v1/models, /v1/embeddings endpoints" "Python (vLLM entrypoints)" "Web Server"
            gaudiPlugin = container "vllm_gaudi Plugin" "HPU platform plugin providing Gaudi-optimized workers, attention backends, model overrides, bucketing, and custom ops" "Python Plugin Package"
            hpuWorker = container "HPU Worker" "Executes model inference on Intel Gaudi accelerators via Synapse AI runtime" "Python (habana_frameworks)"
            scheduler = container "Async Scheduler" "Schedules inference requests with bucketing for optimal graph cache utilization" "Python"
            modelRunner = container "HPU Model Runner" "Manages graph compilation, caching, and model execution lifecycle" "Python"
        }

        kserve = softwareSystem "KServe" "Manages ServingRuntime pod lifecycle, scaling, and routing" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway" "Gateway API / HTTPRoute with kube-rbac-proxy for TLS termination and auth" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-compatible object storage for model weights and tokenizer" "External"
        gaudiHardware = softwareSystem "Intel Gaudi Accelerators" "Gaudi 2/3 HPUs with Synapse AI 1.23.0 runtime, HCCL for distributed ops" "Hardware"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-card inference orchestration" "External"
        transformers = softwareSystem "Hugging Face Transformers" "Model architecture definitions, tokenizer loading, config parsing" "External"
        vllmCore = softwareSystem "vLLM Core" "Core inference engine providing plugin interface, scheduler, and API server" "External"

        # Relationships
        user -> kserve "Creates InferenceService targeting Gaudi hardware" "kubectl / RHOAI Dashboard"
        kserve -> vllmGaudi "Deploys and manages" "Container Runtime"
        client -> platformGateway "Sends inference requests" "HTTPS/443 TLS 1.2+ Bearer Token"
        platformGateway -> vllmGaudi "Proxies authenticated requests" "HTTP/8000 (via kube-rbac-proxy 8443)"

        apiServer -> scheduler "Routes requests"
        scheduler -> hpuWorker "Dispatches inference"
        gaudiPlugin -> apiServer "Registers HPU platform"
        gaudiPlugin -> modelRunner "Configures bucketing"
        modelRunner -> hpuWorker "Manages execution"

        vllmGaudi -> gaudiHardware "Executes inference" "Synapse AI device API"
        vllmGaudi -> modelStorage "Loads model weights" "HTTPS/443 AWS IAM"
        vllmGaudi -> ray "Distributed orchestration" "Ray internal / gRPC"
        vllmGaudi -> transformers "Model/tokenizer loading" "Python library"
        vllmCore -> vllmGaudi "Plugin interface" "Python entry_points"
        gaudiHardware -> gaudiHardware "Collective ops (TP/EP)" "HCCL libfabric/verbs"
    }

    views {
        systemContext vllmGaudi "SystemContext" {
            include *
            autoLayout
            description "vLLM Gaudi in the RHOAI platform ecosystem"
        }

        container vllmGaudi "Containers" {
            include *
            autoLayout
            description "Internal structure of the vLLM Gaudi inference server"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Hardware" {
                background #7b2d8e
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Server" {
                shape WebBrowser
            }
        }
    }
}

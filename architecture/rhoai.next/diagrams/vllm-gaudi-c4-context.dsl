workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference on Intel Gaudi accelerators"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and ServingRuntime configurations"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi hardware plugin for vLLM enabling high-performance LLM inference on HPU accelerators" {
            apiServer = container "vLLM OpenAI API Server" "Serves OpenAI-compatible inference endpoints (completions, chat, embeddings)" "Python / vLLM" "Application"
            gaudiPlugin = container "vllm_gaudi Plugin" "HPU platform plugin — attention backends, model overrides, custom ops, bucketing, speculative decode" "Python Plugin" "Plugin"
            hpuGraphEngine = container "HPU Graph Engine" "Compiles and caches HPU execution graphs for optimized inference" "Habana SynapseAI" "Runtime"
        }

        kserve = softwareSystem "KServe" "Kubernetes serverless ML inference platform — manages ServingRuntime and InferenceService CRs" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator — creates ServingRuntime CRs referencing vllm-gaudi image" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar — enforces Bearer Token auth via SubjectAccessReview" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API (Envoy)" "Ingress gateway — TLS termination and external traffic routing via HTTPRoute CRs" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed compute framework for multi-HPU worker orchestration" "External"
        vllm = softwareSystem "vLLM" "Core LLM inference engine — extended by vllm-gaudi plugin via entry points" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework with Habana HPU backend support" "External"
        synapseAI = softwareSystem "Habana SynapseAI" "Intel Gaudi hardware driver stack — device access, graph compilation, HCCL" "External"
        s3 = softwareSystem "Model Storage (S3/PVC)" "Object/block storage for model weight artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External"

        # Relationships
        dataScientist -> vllmGaudi "Sends inference requests (POST /v1/chat/completions)" "HTTPS/443"
        platformAdmin -> rhodsOperator "Configures ServingRuntime CRs" "kubectl"

        dataScientist -> gatewayAPI "Sends inference requests" "HTTPS/443, TLS 1.3, Bearer Token"
        gatewayAPI -> kubeRbacProxy "Forwards authenticated traffic" "HTTPS/8443, TLS"
        kubeRbacProxy -> vllmGaudi "Proxies to inference server" "HTTP/8000, localhost"

        vllmGaudi -> vllm "Extends via Python entry points (platform_plugins, general_plugins)" "In-process"
        vllmGaudi -> pytorch "Uses PyTorch HPU backend for tensor operations" "In-process"
        vllmGaudi -> synapseAI "Accesses Gaudi HPU via habanalabs kernel driver" "PCIe/HCCL"
        vllmGaudi -> ray "Coordinates multi-HPU distributed inference" "TCP/6379"
        vllmGaudi -> s3 "Downloads model weights at startup" "HTTPS/443, TLS 1.2+, AWS IAM"
        vllmGaudi -> huggingface "Downloads models and tokenizers" "HTTPS/443, TLS 1.2+, HF Token"

        kserve -> vllmGaudi "Manages as ServingRuntime container" "Container Image"
        rhodsOperator -> kserve "Creates ServingRuntime CRs" "Kubernetes API"

        # Container relationships
        apiServer -> gaudiPlugin "Loads via Python entry points"
        gaudiPlugin -> hpuGraphEngine "Compiles and executes HPU Graphs"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Application" {
                background #4a90e2
                color #ffffff
            }
            element "Plugin" {
                background #5b9bd5
                color #ffffff
            }
            element "Runtime" {
                background #7b2d8e
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

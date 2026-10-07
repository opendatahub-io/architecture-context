workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        mlops = person "MLOps Engineer" "Configures ServingRuntimes and model deployments"

        vllmRocm = softwareSystem "vLLM ROCm" "AMD GPU-accelerated LLM inference server with OpenAI REST and TGIS gRPC interfaces" {
            tgisAdapter = container "vllm_tgis_adapter" "Python entrypoint that bridges vLLM engine to TGIS gRPC protocol" "Python"
            vllmEngine = container "vLLM Engine" "High-performance LLM inference engine with AMD ROCm GPU acceleration" "Python/C++ (from RHAIIS base image)"
            restAPI = container "OpenAI REST API" "OpenAI-compatible completions and chat API" "HTTP/8000"
            grpcAPI = container "TGIS gRPC API" "Text Generation Inference Server protocol" "gRPC/8033"
        }

        rhaiis = softwareSystem "RHAIIS Base Image" "Red Hat AI Inference Server base image providing vLLM, ROCm, Python stack" "External"
        kserve = softwareSystem "KServe" "Manages predictor pod lifecycle, routing, and autoscaling" "Internal Platform"
        odhModelCtrl = softwareSystem "odh-model-controller" "Deploys vllm-rocm via ServingRuntime template with SHA256 digest" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh providing mTLS and traffic management" "Internal Platform"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API / kube-rbac-proxy for TLS termination and auth" "Internal Platform"
        modelStorage = softwareSystem "Model Storage" "S3, PVC, or OCI registry for model weight artifacts" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Public model repository" "External"
        amdGpu = softwareSystem "AMD ROCm GPU" "GPU compute hardware with ROCm driver" "External"
        konflux = softwareSystem "Konflux" "CI/CD build pipeline (Tekton PipelineRun)" "External"

        datascientist -> vllmRocm "Sends inference requests" "HTTPS/443"
        mlops -> odhModelCtrl "Configures InferenceService" "kubectl"

        odhModelCtrl -> vllmRocm "Deploys via ServingRuntime template" "SHA256 digest"
        kserve -> vllmRocm "Manages predictor lifecycle" "Kubernetes API"
        istio -> vllmRocm "Provides mTLS sidecar" "mTLS"
        platformIngress -> vllmRocm "Routes external traffic" "HTTP/8000"

        vllmRocm -> modelStorage "Downloads model weights" "HTTPS/443, NFS"
        vllmRocm -> huggingface "Downloads models (optional)" "HTTPS/443"
        vllmRocm -> amdGpu "GPU inference compute" "ROCm Device Driver"

        rhaiis -> vllmRocm "Provides base image with all runtime dependencies" "Container Layer"
        konflux -> vllmRocm "Builds container image" "Tekton Pipeline"
    }

    views {
        systemContext vllmRocm "SystemContext" {
            include *
            autoLayout
        }

        container vllmRocm "Containers" {
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

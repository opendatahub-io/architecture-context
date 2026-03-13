workspace {
    model {
        # External Users
        user = person "ML Engineer / Developer" "Deploys and uses Llama Stack LLM inference servers"

        # Llama Stack System
        llamaStack = softwareSystem "Llama Stack Kubernetes Operator" "Kubernetes operator for deploying and managing Llama Stack LLM inference servers" {
            controller = container "Llama Stack Operator Controller" "Go" "Reconciles LlamaStackDistribution CRs and manages server lifecycle"
            server = container "Llama Stack Server" "Python" "LLM inference server with chat/completion APIs"
            ollama = container "Ollama Backend" "Go" "Lightweight LLM inference backend (optional)"
            vllm = container "vLLM Backend" "Python" "GPU-accelerated LLM inference backend (optional)"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.24+)" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Model download and distribution" "External"
        storage = softwareSystem "Persistent Storage" "Model storage via PVC" "External"

        # Internal ODH Dependencies
        odhOperator = softwareSystem "ODH Operator" "Manages Llama Stack via DataScienceCluster" "ODH"
        kserve = softwareSystem "KServe" "Alternative LLM serving option" "ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and tracking (future)" "ODH"

        # Relationships - User Interactions
        user -> llamaStack "Deploys LLM servers and sends inference requests"

        # Relationships - External Dependencies
        llamaStack -> kubernetes "Orchestrates containers and manages resources"
        server -> huggingface "Downloads models"
        server -> storage "Stores models in PVC"

        # Relationships - Internal ODH
        odhOperator -> controller "Manages via DataScienceCluster CRD"
        kserve -> server "Alternative LLM serving option"
        modelRegistry -> server "Model tracking (future integration)"

        # Internal Llama Stack Relationships
        controller -> kubernetes "Creates Deployments, Services, Routes, PVCs, HPAs, NetworkPolicies"
        controller -> server "Provisions and configures"
        server -> ollama "Uses for inference (optional)"
        server -> vllm "Uses for GPU inference (optional)"
    }

    views {
        systemContext llamaStack "LlamaStackContext" {
            include *
            autoLayout lr
        }

        container llamaStack "LlamaStackContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH" {
                background #0066cc
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
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and fine-tunes ML models using notebooks or training jobs"

        trainingHub = softwareSystem "Training Hub" "Unified, algorithm-focused interface for LLM training techniques (SFT, LoRA, GRPO, GEPA)" {
            algorithmRegistry = container "AlgorithmRegistry" "Central dispatch for algorithm selection" "Python"
            sftAlgorithm = container "SFT Algorithm" "Supervised fine-tuning with InstructLab Training or Mini-Trainer backends" "Python"
            loraAlgorithm = container "LoRA Algorithm" "Parameter-efficient adaptation via Unsloth backend" "Python"
            grpoAlgorithm = container "GRPO Algorithm" "Reinforcement learning from verifiable rewards via ART or VeRL backends" "Python"
            gepaAlgorithm = container "GEPA Algorithm" "Gradient-free prompt optimization with optional MLflow tracking" "Python"
            callbackAdapters = container "TrainingHubCallback" "Unified lifecycle hook interface with backend-specific adapters" "Python"
        }

        instructlabTraining = softwareSystem "InstructLab Training" "Distributed SFT execution via torchrun" "Internal RHOAI"
        miniTrainer = softwareSystem "Mini-Trainer" "Optimized SFT execution" "Internal RHOAI"
        unsloth = softwareSystem "Unsloth" "Memory-efficient LoRA training" "External"
        art = softwareSystem "OpenPipe ART" "Co-located vLLM inference with time-shared GPU training for GRPO" "External"
        verl = softwareSystem "VeRL" "Multi-node distributed GRPO execution" "External"
        gepaPkg = softwareSystem "GEPA Package" "Gradient-free prompt optimization library" "External"
        litellm = softwareSystem "litellm" "OpenAI-compatible API client for multi-provider LLM inference" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and prompt registry" "External"
        llmEndpoint = softwareSystem "OpenAI-compatible LLM Endpoint" "LLM inference service for prompt optimization and reward evaluation" "External"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment tracking and prompt registry server" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework" "External"
        transformers = softwareSystem "Transformers" "Hugging Face model library" "External"

        dataScientist -> trainingHub "Calls sft(), lora_grpo(), gepa() from notebook or training job"
        trainingHub -> instructlabTraining "Delegates SFT execution" "Python API"
        trainingHub -> miniTrainer "Delegates OSFT execution" "Python API"
        trainingHub -> unsloth "Delegates LoRA training" "Python API"
        trainingHub -> art "Delegates GRPO training" "Python API"
        trainingHub -> verl "Delegates distributed GRPO" "Python API"
        trainingHub -> gepaPkg "Delegates prompt optimization" "Python API"
        trainingHub -> litellm "Routes LLM inference calls" "Python API"
        trainingHub -> mlflow "Logs experiments and prompts" "Python API"
        trainingHub -> llmEndpoint "Sends inference requests for GEPA/GRPO" "HTTPS"
        trainingHub -> mlflowServer "Tracks experiments and prompt registry" "HTTPS"
        trainingHub -> pytorch "Uses for model training" "Python API"
        trainingHub -> transformers "Uses for model loading and tokenization" "Python API"
    }

    views {
        systemContext trainingHub "SystemContext" {
            include *
            autoLayout
        }

        container trainingHub "Containers" {
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
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

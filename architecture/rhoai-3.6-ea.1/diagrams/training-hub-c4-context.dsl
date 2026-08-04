workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and fine-tunes LLMs using notebooks or training jobs"

        trainingHub = softwareSystem "Training Hub" "Unified algorithm-focused Python SDK for LLM training techniques (SFT, OSFT, LoRA, GRPO, GEPA)" {
            algorithmRegistry = container "AlgorithmRegistry" "Registry-based plugin system mapping algorithms to backends" "Python"
            sftAlgorithm = container "SFT Algorithm" "Supervised fine-tuning via instructlab-training" "Python"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal subspace fine-tuning via rhai-innovation-mini-trainer" "Python"
            loraAlgorithm = container "LoRA SFT Algorithm" "Low-rank adaptation fine-tuning via Unsloth" "Python"
            grpoAlgorithm = container "GRPO Algorithm" "Reinforcement learning from verifiable rewards via ART/OpenPipe with co-located vLLM" "Python"
            gepaAlgorithm = container "GEPA Algorithm" "Gradient-free evolutionary prompt optimization via gepa + litellm" "Python"
            callback = container "TrainingHubCallback" "Training lifecycle hooks for monitoring" "Python"
            profiler = container "Memory/Timing Profiler" "Pre-flight resource planning estimators" "Python"
        }

        instructlabTraining = softwareSystem "instructlab-training" "InstructLab training library for SFT execution" "Internal RHOAI"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "Mini-trainer for orthogonal subspace fine-tuning" "Internal RHOAI"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA fine-tuning library" "External"
        artFramework = softwareSystem "ART (OpenPipe)" "Reinforcement learning framework for GRPO training" "External"
        vllmEngine = softwareSystem "vLLM" "High-throughput LLM inference engine (co-located)" "External"
        gepaLib = softwareSystem "GEPA Library" "Evolutionary prompt search library" "External"
        litellm = softwareSystem "LiteLLM" "Unified LLM API client" "External"
        llmInferenceAPI = softwareSystem "LLM Inference API" "External LLM endpoint for prompt optimization" "External"
        mlflowServer = softwareSystem "MLflow" "Experiment tracking and prompt registry" "External"
        torch = softwareSystem "PyTorch" "Deep learning framework" "External"
        transformers = softwareSystem "Transformers" "HuggingFace model library" "External"
        localFilesystem = softwareSystem "Local Filesystem" "Checkpoint and artifact storage" "Infrastructure"

        dataScientist -> trainingHub "Calls training functions (sft, osft, lora_grpo, gepa)" "Python API"
        trainingHub -> instructlabTraining "Delegates SFT training execution" "Python import"
        trainingHub -> miniTrainer "Delegates OSFT training execution" "Python import"
        trainingHub -> unsloth "Delegates LoRA fine-tuning" "Python import"
        trainingHub -> artFramework "Delegates GRPO RL training" "Python import"
        trainingHub -> vllmEngine "Co-located inference for GRPO rollouts" "In-process"
        trainingHub -> gepaLib "Delegates prompt optimization" "Python import"
        trainingHub -> litellm "LLM API calls for GEPA" "Python import"
        trainingHub -> llmInferenceAPI "Prompt optimization inference" "HTTPS / API Key"
        trainingHub -> mlflowServer "Experiment tracking and prompt registry" "HTTP/HTTPS (optional)"
        trainingHub -> torch "Training computation" "Python import"
        trainingHub -> transformers "Model loading and tokenization" "Python import"
        trainingHub -> localFilesystem "Write model checkpoints" "Filesystem I/O"
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
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

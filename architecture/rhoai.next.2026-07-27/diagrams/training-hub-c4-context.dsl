workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Fine-tunes and trains language models using training_hub"

        trainingHub = softwareSystem "training_hub" "Algorithm-focused Python library providing a pluggable backend architecture for LM training, continual learning, and reinforcement learning" {
            apiLayer = container "Convenience API" "User-facing functions: sft(), osft(), lora_sft(), lora_grpo(), gepa()" "Python Module"
            algorithmLayer = container "Algorithm Layer" "Algorithm definitions: SFT, OSFT, LoRA SFT, LoRA GRPO, GEPA with parameter validation" "Python Module"
            registry = container "AlgorithmRegistry" "Runtime discovery and selection of algorithm-backend combinations" "Python Module"
            backendLayer = container "Backend Layer" "Pluggable backend implementations delegating to external training frameworks" "Python Module"
            gpuProfiler = container "GPU Memory Profiler" "GPU memory profiling and estimation utilities for resource planning" "Python Module"
            itsRollout = container "ITS Hub Rollout" "Integration with ITS Hub for GRPO training rollouts" "Python Module"
            rewardFunctions = container "Reward Functions" "Tool-call verification reward functions for RL training" "Python Module"
            lossViz = container "Loss Visualization" "Training loss visualization utilities" "Python Module"
        }

        instructlabTraining = softwareSystem "instructlab-training" "InstructLab training framework for SFT" "External Framework"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "Mini-trainer for SFT, OSFT, LoRA SFT" "External Framework"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA fine-tuning framework" "External Framework"
        openPipeArt = softwareSystem "OpenPipe ART" "Autonomous training with co-located vLLM engines" "External Framework"
        verl = softwareSystem "verl" "Distributed RL training via Ray/torchrun with FSDP sharding (70B+ models)" "External Framework"
        gepaPkg = softwareSystem "GEPA" "GEPA training framework with env management" "External Framework"

        llmApi = softwareSystem "LLM API" "Language model inference endpoint (via litellm)" "External Service"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and metrics server" "External Service"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking and visualization platform" "External Service"

        pytorch = softwareSystem "PyTorch" "Deep learning framework with CUDA GPU support" "External Framework"
        transformers = softwareSystem "Transformers" "Hugging Face model library" "External Framework"

        user -> trainingHub "Imports and calls training functions" "Python API"
        trainingHub -> instructlabTraining "Delegates SFT training" "In-process Python call"
        trainingHub -> miniTrainer "Delegates SFT/OSFT/LoRA SFT training" "In-process Python call"
        trainingHub -> unsloth "Delegates LoRA SFT training" "In-process Python call"
        trainingHub -> openPipeArt "Delegates LoRA GRPO training" "In-process + vLLM engines"
        trainingHub -> verl "Delegates LoRA GRPO training" "Subprocess: Ray/torchrun"
        trainingHub -> gepaPkg "Delegates GEPA training" "In-process Python call"
        trainingHub -> llmApi "Reward scoring / completions" "HTTPS (OPENAI_API_KEY)"
        trainingHub -> mlflow "Logs training metrics" "HTTPS (MLFLOW_TRACKING_URI)"
        trainingHub -> wandb "Logs experiments" "HTTPS (WANDB_API_KEY)"
        trainingHub -> pytorch "GPU compute and tensor ops" "In-process"
        trainingHub -> transformers "Model loading and tokenization" "In-process"

        apiLayer -> algorithmLayer "Delegates to algorithm"
        algorithmLayer -> registry "Looks up backend"
        registry -> backendLayer "Returns backend instance"
        backendLayer -> instructlabTraining "In-process call"
        backendLayer -> miniTrainer "In-process call"
        backendLayer -> unsloth "In-process call"
        backendLayer -> openPipeArt "In-process + engine mgmt"
        backendLayer -> verl "Subprocess launch"
        backendLayer -> gepaPkg "In-process call"
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
            element "External Framework" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
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

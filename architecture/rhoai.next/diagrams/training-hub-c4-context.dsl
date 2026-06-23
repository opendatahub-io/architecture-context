workspace {
    model {
        researcher = person "ML Researcher / Engineer" "Fine-tunes language models using training-hub SDK in Jupyter notebooks or CLI scripts"

        trainingHub = softwareSystem "training-hub" "Python SDK providing an algorithm-focused interface for LLM fine-tuning, continual learning, and reinforcement learning" {
            publicAPI = container "Public API" "Convenience functions: sft(), osft(), lora_sft(), lora_grpo(), grpo(), estimate()" "Python Module"
            algorithmLayer = container "Algorithm Layer" "Algorithm base class, AlgorithmRegistry, create_algorithm() factory" "Python Module"
            sftAlgorithm = container "SFTAlgorithm" "Full-parameter supervised fine-tuning with torchrun distribution" "Python Class"
            osftAlgorithm = container "OSFTAlgorithm" "Orthogonal Subspace Fine-Tuning (Nayak et al. 2025)" "Python Class"
            loraSFTAlgorithm = container "LoRASFTAlgorithm" "LoRA-based SFT with QLoRA, DoRA, RSLoRA support" "Python Class"
            loraGRPOAlgorithm = container "LoRAGRPOAlgorithm" "GRPO reinforcement learning with LoRA or full fine-tuning" "Python Class"
            ilabBackend = container "InstructLabTraining SFTBackend" "Delegates SFT to instructlab-training run_training()" "Python Class"
            miniTrainerBackend = container "MiniTrainer OSFTBackend" "Delegates OSFT to rhai-innovation-mini-trainer" "Python Class"
            unslothBackend = container "Unsloth LoRABackend" "Delegates LoRA training to Unsloth FastModel + TRL SFTTrainer" "Python Class"
            artBackend = container "ART LoRAGRPOBackend" "Single-GPU GRPO via OpenPipe ART with vLLM rollout" "Python Class"
            verlBackend = container "VeRL LoRAGRPOBackend" "Multi-GPU distributed GRPO via verl framework" "Python Class"
            profiling = container "Profiling Module" "GPU VRAM estimation (Basic, OSFT, LoRA, QLoRA estimators) and timing estimation" "Python Module"
            visualization = container "Visualization" "Training loss curve plotting with EMA smoothing" "Python Module"
            rewards = container "Reward Functions" "tool_call_reward() and binary_reward() for GRPO training" "Python Module"
        }

        instructlabTraining = softwareSystem "instructlab-training" "SFT training execution and data processing library" "External Library"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "OSFT training execution library" "External Library"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA model loading with FastModel/FastLanguageModel" "External Library"
        trl = softwareSystem "TRL" "Transformer Reinforcement Learning (SFTTrainer, GRPOTrainer)" "External Library"
        openPipeART = softwareSystem "OpenPipe ART" "Single-GPU GRPO framework with vLLM rollout generation" "External Library"
        verl = softwareSystem "verl" "Multi-GPU distributed GRPO framework (Volcano Engine RL)" "External Library"
        vllm = softwareSystem "vLLM" "LLM inference engine for GRPO rollout generation" "External Library"
        pytorch = softwareSystem "PyTorch" "Deep learning framework with torchrun distributed training" "External Library"
        huggingface = softwareSystem "HuggingFace Hub" "Model and tokenizer downloads, model config retrieval" "External Service"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking and metrics logging (optional)" "External Service"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry (optional)" "External Service"

        researcher -> trainingHub "Fine-tunes models using Python API"
        trainingHub -> instructlabTraining "Delegates SFT training" "Python import"
        trainingHub -> miniTrainer "Delegates OSFT training" "Python import"
        trainingHub -> unsloth "Loads models with LoRA optimization" "Python import"
        trainingHub -> trl "Runs LoRA SFT and GRPO training loops" "Python import"
        trainingHub -> openPipeART "Runs single-GPU GRPO" "Python import"
        trainingHub -> verl "Runs multi-GPU distributed GRPO" "Subprocess CLI"
        trainingHub -> vllm "Generates rollouts for GRPO" "Subprocess HTTP"
        trainingHub -> pytorch "Distributed training orchestration" "torchrun subprocess"
        trainingHub -> huggingface "Downloads models, tokenizers, configs" "HTTPS/443"
        trainingHub -> wandb "Logs experiment metrics" "HTTPS/443"
        trainingHub -> mlflow "Logs experiment metrics" "HTTP/HTTPS"
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
            element "External Library" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
